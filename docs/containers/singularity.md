# Singularity / Apptainer

Singularity (now [Apptainer](https://apptainer.org/)) is the standard container runtime on HPC clusters.

## Building the container

### Prerequisites

- Singularity or Apptainer installed
- `sudo` access for building (not for running)
- Internet access during the build

### Pull from the Docker image

```bash
apptainer pull bloodstream_latest.sif docker://mathesong/bloodstream:latest
```

This creates a `bloodstream_latest.sif` file.

## Interactive mode

Interactive mode launches a Shiny web app accessible in your browser.

```bash
apptainer run \
  --bind /path/to/bids:/data/bids_dir \
  --bind /path/to/derivatives:/data/derivatives_dir \
  bloodstream_latest.sif \
  --mode interactive
```

Then open `http://localhost:3838` in your browser.

## Automatic mode

```bash
# With config file (fits models)
apptainer run \
  --bind /path/to/bids:/data/bids_dir \
  --bind /path/to/derivatives:/data/derivatives_dir \
  --bind /path/to/config.json:/config.json \
  bloodstream_latest.sif

# Without config (linear interpolation)
apptainer run \
  --bind /path/to/bids:/data/bids_dir \
  --bind /path/to/derivatives:/data/derivatives_dir \
  bloodstream_latest.sif

# Custom analysis folder
apptainer run \
  --bind /path/to/bids:/data/bids_dir \
  --bind /path/to/derivatives:/data/derivatives_dir \
  --bind /path/to/config.json:/config.json \
  bloodstream_latest.sif \
  --analysis_foldername "Model_AIF"
```

## Volume mounting

Singularity uses `--bind` instead of Docker's `-v`:

```bash
--bind /host/path:/container/path

# Multiple mounts
--bind /data/bids:/data/bids_dir \
--bind /analysis:/data/derivatives_dir
```

## HPC integration

### SLURM

**Interactive job (for GUI usage):**

```bash
#!/bin/bash
#SBATCH --job-name=bloodstream-interactive
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2

module load singularity

apptainer run \
  --bind /scratch/project/bids_data:/data/bids_dir \
  --bind /scratch/project/derivatives:/data/derivatives_dir \
  bloodstream_latest.sif \
  --mode interactive
```

**Batch processing with job arrays:**

```bash
#!/bin/bash
#SBATCH --job-name=bloodstream-batch
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-3

module load singularity

ANALYSES=(Primary_Analysis GAM_ParentFraction Spline_AIF)
CURRENT=${ANALYSES[$SLURM_ARRAY_TASK_ID-1]}

apptainer run \
  --bind /scratch/project/bids:/data/bids_dir \
  --bind /scratch/project/derivatives:/data/derivatives_dir \
  --bind /scratch/project/configs/${CURRENT}.json:/config.json \
  bloodstream_latest.sif \
  --analysis_foldername "$CURRENT"
```

### PBS/Torque

```bash
#!/bin/bash
#PBS -N bloodstream-processing
#PBS -l walltime=02:00:00
#PBS -l mem=4gb
#PBS -l ncpus=1

cd $PBS_O_WORKDIR
module load singularity

apptainer run \
  --bind /data/bids:/data/bids_dir \
  --bind /data/derivatives:/data/derivatives_dir \
  --bind /data/config.json:/config.json \
  bloodstream_latest.sif \
  --analysis_foldername "Primary_Analysis"
```

### LSF

```bash
#!/bin/bash
#BSUB -J bloodstream-batch
#BSUB -W 02:00
#BSUB -M 4000
#BSUB -n 1

module load singularity

apptainer run \
  --bind /data/bids:/data/bids_dir \
  --bind /data/derivatives:/data/derivatives_dir \
  bloodstream_latest.sif
```

## Troubleshooting

### Writable tmp directory

If you encounter permission errors related to temporary files:

```bash
apptainer run --writable-tmpfs \
  --bind /path/to/bids:/data/bids_dir \
  --bind /path/to/derivatives:/data/derivatives_dir \
  bloodstream_latest.sif
```

### No internet on compute nodes

Build the container on a login node, then copy the `.sif` file to your project space.

### Home directory size limits

Build in a scratch directory and set `SINGULARITY_CACHEDIR`:

```bash
export SINGULARITY_CACHEDIR=/scratch/$USER/singularity_cache
apptainer pull bloodstream_latest.sif docker://mathesong/bloodstream:latest
```

### Module loading

Common module names across HPC systems:

```bash
module load singularity
module load apptainer
module load singularity-ce
```

## Performance considerations

| Resource | Interactive mode | Automatic mode |
|----------|-----------------|----------------|
| **RAM** | 4-8 GB recommended | 2-4 GB typically sufficient |
| **CPU** | Mostly single-threaded | Single-threaded |
| **Container size** | ~2-3 GB for `.sif` file | Same |
| **Working space** | 2-5x input data size | Same |

## Docker to Singularity migration

| Docker | Singularity |
|--------|-------------|
| `docker run -v /data:/data/bids_dir -p 3838:3838 mathesong/bloodstream --mode interactive` | `apptainer run --bind /data:/data/bids_dir bloodstream_latest.sif --mode interactive` |
| `docker run -v /data:/data/bids_dir mathesong/bloodstream` | `apptainer run --bind /data:/data/bids_dir bloodstream_latest.sif` |
| `docker pull mathesong/bloodstream:latest` | `apptainer pull bloodstream_latest.sif docker://mathesong/bloodstream:latest` |

The command-line arguments and functionality are identical between Docker and Singularity.
