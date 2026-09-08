# Apptainer

[Apptainer](https://apptainer.org/) (formerly Singularity) is the standard container runtime on HPC clusters. bloodstream's Apptainer definition file lives in the `apptainer/` directory of the repository.

## Building the container

### Prerequisites

- Apptainer installed (or Singularity, which uses the same commands)
- Internet access during the build

### Quickest path: convert the Docker image

```bash
apptainer build bloodstream_latest.sif docker://mathesong/bloodstream:latest
```

This converts the published Docker image into a `bloodstream_latest.sif` file. No local definition file is needed.

### Build from the definition file

If you need to customise the build (e.g. specific user/group IDs, work offline, modify dependencies):

```bash
apptainer build bloodstream_latest.sif apptainer/bloodstream.def
```

To pass build arguments such as a non-default user ID:

```bash
apptainer build \
  --build-arg USER_ID=1001 \
  --build-arg GROUP_ID=1001 \
  bloodstream_latest.sif apptainer/bloodstream.def
```

## The bloodstream-docker wrapper

The [`bloodstream-docker`](docker.md#the-bloodstream-docker-wrapper) wrapper generates Apptainer commands as well as Docker ones — pass `--apptainer`:

```bash
pip install bloodstream-docker

bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --apptainer \
  --config /path/to/config.json \
  --automatic
```

It uses `bloodstream_latest.sif` in the working directory by default; point `--image` at another SIF file, or at a `docker://` URI to let Apptainer pull it. On clusters where the runtime is still called `singularity`, use `--container singularity` instead of `--apptainer`.

## Simplified workflow: the `bloodstream` alias

Apptainer auto-mounts your `$HOME`, `$PWD`, and `/tmp`, and runs as your own user. So for data under your home directory you need no bind flags at all. Define an alias once (in `~/.bashrc`):

```bash
alias bloodstream='apptainer run bloodstream_latest.sif'
```

then run with bare host paths:

```bash
bloodstream --bids_dir ~/data/bids --derivatives_dir ~/data/derivatives
```

For data outside `$HOME` (e.g. `/scratch`), add an explicit `-B /scratch:/scratch`, or ask your admin to add `bind path = /scratch` to `/etc/apptainer/apptainer.conf`. Otherwise, the explicit `-B` examples below work everywhere.

## Interactive mode

Interactive mode launches a Shiny web app accessible in your browser.

```bash
apptainer run --cleanenv \
  -B /path/to/bids:/data/bids_dir:ro \
  -B /path/to/derivatives:/data/derivatives_dir:rw \
  -B /tmp:/tmp \
  bloodstream_latest.sif \
  --mode interactive
```

Then open the address the container prints in your browser — `http://localhost:3838` by default. Because Apptainer shares the host network, if port 3838 is already in use on the node the container automatically scans upward for the next free port (3838–3858) and prints a line such as:

```text
Requested Shiny port 3838 is in use. Using 3839 instead.
```

On a remote HPC, use SSH port forwarding first in order to be able to access the browser interface on your local machine. Forward whichever port the container reports:

```bash
ssh -L 3838:localhost:3838 username@servername
```

To request a specific starting port instead of 3838, set `SHINY_PORT` (with `--cleanenv` you must pass it explicitly):

```bash
apptainer run --cleanenv --env SHINY_PORT=8080 \
  -B /path/to/derivatives:/data/derivatives_dir:rw \
  -B /tmp:/tmp \
  bloodstream_latest.sif \
  --mode interactive
```

## Automatic mode

```bash
# With config file (fits models)
apptainer run --cleanenv \
  -B /path/to/bids:/data/bids_dir:ro \
  -B /path/to/derivatives:/data/derivatives_dir:rw \
  -B /path/to/config.json:/config.json:ro \
  -B /tmp:/tmp \
  bloodstream_latest.sif

# Without config (linear interpolation)
apptainer run --cleanenv \
  -B /path/to/bids:/data/bids_dir:ro \
  -B /path/to/derivatives:/data/derivatives_dir:rw \
  -B /tmp:/tmp \
  bloodstream_latest.sif

# Custom analysis folder
apptainer run --cleanenv \
  -B /path/to/bids:/data/bids_dir:ro \
  -B /path/to/derivatives:/data/derivatives_dir:rw \
  -B /path/to/config.json:/config.json:ro \
  -B /tmp:/tmp \
  bloodstream_latest.sif \
  --analysis_foldername "Model_AIF"
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

apptainer run --cleanenv \
  -B /scratch/project/bids:/data/bids_dir:ro \
  -B /scratch/project/derivatives:/data/derivatives_dir:rw \
  -B /tmp:/tmp \
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

module load apptainer

ANALYSES=(Primary_Analysis GAM_ParentFraction Spline_AIF)
CURRENT=${ANALYSES[$SLURM_ARRAY_TASK_ID-1]}

apptainer run --cleanenv \
  -B /scratch/project/bids:/data/bids_dir:ro \
  -B /scratch/project/derivatives:/data/derivatives_dir:rw \
  -B /scratch/project/configs/${CURRENT}.json:/config.json:ro \
  -B /tmp:/tmp \
  bloodstream_latest.sif \
  --analysis_foldername "$CURRENT"
```

## Volume mounting

Apptainer uses `--bind` (or `-B`) instead of Docker's `-v`:

```bash
--bind /host/path:/container/path

# Multiple mounts
--bind /data/bids:/data/bids_dir \
--bind /analysis:/data/derivatives_dir
```

## Troubleshooting

### Directory not found

```bash
# Verify bind mount paths exist
ls -la /host/path/to/data

# Check inside the container
apptainer exec bloodstream_latest.sif ls -la /data/bids_dir
```

### Port already in use

Apptainer shares the host network, so a busy port 3838 on the node would otherwise clash. The container detects this automatically and binds the next free port in the range 3838–3858, printing the address to use. Set up SSH forwarding to whichever port it reports (`ssh -L <port>:localhost:<port>`). To choose the starting port yourself, pass `--env SHINY_PORT=<port>`.

### Writable tmp directory

Report rendering writes to `/tmp`, so bind it (`-B /tmp:/tmp`) as the examples above do. If you still encounter permission errors related to temporary files:

```bash
apptainer run --writable-tmpfs --cleanenv \
  -B /path/to/bids:/data/bids_dir:ro \
  -B /path/to/derivatives:/data/derivatives_dir:rw \
  bloodstream_latest.sif
```

### No internet on compute nodes

Build the SIF on a login node, then copy the `.sif` file to your project space.

### Home directory size limits

Build in a scratch directory and set the cache location:

```bash
export APPTAINER_CACHEDIR=/scratch/$USER/apptainer_cache
apptainer build bloodstream_latest.sif docker://mathesong/bloodstream:latest
```

### Module loading

Common module names across HPC systems:

```bash
module load apptainer
module load singularity
module load singularity-ce
```
