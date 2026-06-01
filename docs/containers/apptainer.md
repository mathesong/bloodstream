# Apptainer

[Apptainer](https://apptainer.org/) (formerly Singularity) is the standard container runtime on HPC clusters.

## Building the container

### Prerequisites

- Apptainer installed (or Singularity, which uses the same commands)
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

Apptainer uses `--bind` instead of Docker's `-v`:

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

module load apptainer

apptainer run \
  --bind /scratch/project/bids_data:/data/bids_dir \
  --bind /scratch/project/derivatives:/data/derivatives_dir \
  bloodstream_latest.sif \
  --mode interactive
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

Build in a scratch directory and set `APPTAINER_CACHEDIR`:

```bash
export APPTAINER_CACHEDIR=/scratch/$USER/apptainer_cache
apptainer pull bloodstream_latest.sif docker://mathesong/bloodstream:latest
```

### Module loading

Common module names across HPC systems:

```bash
module load apptainer
module load singularity
module load singularity-ce
```
