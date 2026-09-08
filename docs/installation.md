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

### The bloodstream-docker wrapper

The easiest way to drive the container is the [`bloodstream-docker`](https://pypi.org/project/bloodstream-docker/) command-line wrapper. It turns a simple BIDS-App-style command into the matching `docker run` invocation, mapping your directories into the container for you:

```bash
pip install bloodstream-docker
bloodstream-docker --help   # see all options
```

See [Docker usage](containers/docker.md) for full details on running the container.

## Apptainer

[Apptainer](https://apptainer.org/) (formerly Singularity) is the standard container runtime on HPC clusters.

### Build from the Docker image

```bash
apptainer build bloodstream_latest.sif docker://mathesong/bloodstream:latest
```

### Prerequisites

- Apptainer installed (or Singularity, which uses the same commands)
- Internet access during the build

`bloodstream-docker --apptainer` generates Apptainer commands too. See [Apptainer usage](containers/apptainer.md) for full details, including HPC integration.

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
