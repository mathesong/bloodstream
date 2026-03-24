# Installation

bloodstream can be installed and run in three ways. Docker is the recommended approach for most users.

## Docker

Docker is the recommended approach for most users. It bundles all dependencies and avoids package installation issues.

### Pull the pre-built image

```bash
docker pull mathesong/bloodstream:latest
```

### Build from source

If you prefer to build locally:

```bash
git clone https://github.com/mathesong/bloodstream.git
cd bloodstream
docker build -f docker/dockerfile -t mathesong/bloodstream:latest . --platform linux/amd64
```

See [Docker usage](containers/docker.md) for full details on running the container.

## Singularity / Apptainer

Singularity (now called [Apptainer](https://apptainer.org/)) is the standard container runtime on HPC clusters.

### Pull from the Docker image

```bash
apptainer pull bloodstream_latest.sif docker://mathesong/bloodstream:latest
```

### Prerequisites

- Singularity or Apptainer installed on your system
- `sudo` access for building (not required for running)
- Internet access during the build

See [Singularity usage](containers/singularity.md) for full details, including HPC integration with SLURM, PBS, and LSF.

## R package (for development)

If you need to run bloodstream outside a container — for example, during development or debugging — you can install the R package directly.

```r
# Install remotes if needed
install.packages("remotes")

# Install bloodstream
remotes::install_github("mathesong/bloodstream")
```

### Prerequisites

- **R** >= 4.0
- The [kinfitr](https://github.com/mathesong/kinfitr) package (installed automatically as a dependency)
- Standard R package build tools (`Rtools` on Windows, `r-base-dev` on Linux)

### Verifying the installation

```r
library(bloodstream)
?bloodstream_interactive
```
