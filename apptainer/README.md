# Apptainer image for bloodstream

This directory holds the [Apptainer](https://apptainer.org/) definition file for
running bloodstream on HPC clusters and other shared systems.

## Getting the image

The quickest path converts the published Docker image, and needs no definition
file:

```bash
apptainer build bloodstream_latest.sif docker://mathesong/bloodstream:latest
```

Build from the definition file instead if you need to customise it (for
instance, different user/group IDs):

```bash
apptainer build bloodstream_latest.sif apptainer/bloodstream.def

apptainer build --build-arg USER_ID=1001 --build-arg GROUP_ID=1001 \
  bloodstream_latest.sif apptainer/bloodstream.def
```

## Running

The `bloodstream-docker` wrapper generates Apptainer commands as well as Docker
ones:

```bash
pip install bloodstream-docker

bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --apptainer --config /path/to/config.json --automatic
```

For raw `apptainer run` invocations, port forwarding for the interactive app,
and HPC job scripts, see the
[Apptainer documentation](https://bloodstream.readthedocs.io/en/latest/containers/apptainer.html).
