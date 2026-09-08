# Container usage

For a quick introduction to running bloodstream with Docker or Apptainer, see the [Quick start](../quickstart.md). This section covers advanced container options, CLI reference, and HPC integration.

bloodstream provides Docker and Apptainer container images that bundle all dependencies. Both use the same command-line arguments and produce identical results, and the [`bloodstream-docker`](docker.md#the-bloodstream-docker-wrapper) wrapper can generate the commands for either.

- **Docker** — best for desktops and cloud servers. See [Docker](docker.md).
- **Apptainer** (formerly Singularity) — best for HPC clusters and shared systems. See [Apptainer](apptainer.md).

```{toctree}
:maxdepth: 2

docker
apptainer
```
