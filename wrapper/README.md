# bloodstream-docker

`bloodstream-docker` is a lightweight Python wrapper that turns a BIDS-App-like
command line into the matching `docker run` — or `apptainer run` — invocation
for bloodstream. Interactive Shiny mode is the default; use `--automatic` (or
`--mode non-interactive`) to run the processing pipeline.

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --config /path/to/config.json \
  --analysis-foldername Model_AIF \
  --automatic
```

The command above runs:

```bash
docker run --rm --platform linux/amd64 -it \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -v /path/to/config.json:/config.json:ro \
  mathesong/bloodstream:latest \
  --mode non-interactive --analysis_foldername Model_AIF --config /config.json
```

## Installation

```bash
pip install bloodstream-docker
```

Run `bloodstream-docker --help` at any time to see all available options:

```bash
bloodstream-docker --help
```

## Examples

Create a config file interactively, with no data at all — then open
`http://localhost:3838`:

```bash
bloodstream-docker
```

Launch the app with data, so it can also run the pipeline:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant
```

The three positional arguments follow the BIDS App convention:

```text
bloodstream-docker <bids_dir> <output_dir> participant
```

The positional `output_dir` can be either the derivatives root or the final
bloodstream output directory — these are equivalent:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant
bloodstream-docker /path/to/bids /path/to/derivatives/bloodstream participant
```

Run the pipeline with a config file:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --config /path/to/config.json \
  --automatic
```

Run the pipeline without one, which linearly interpolates the measured data:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant --automatic
```

Give the analysis its own output folder, so several can sit side by side in
`derivatives/bloodstream/`:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --config /path/to/config.json \
  --automatic \
  --analysis-foldername Model_AIF
```

Print the command without running it:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant --dry-run
```

Open a shell in the image:

```bash
bloodstream-docker --shell -i mathesong/bloodstream:latest
```

## Apptainer

Pass `--apptainer` (or `--container apptainer`) to generate an `apptainer run`
command instead, using `bloodstream_latest.sif` in the working directory by
default:

```bash
apptainer build bloodstream_latest.sif docker://mathesong/bloodstream:latest

bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --apptainer \
  --config /path/to/config.json \
  --automatic
```

which runs:

```bash
apptainer run --cleanenv \
  -B /path/to/bids:/data/bids_dir:ro \
  -B /path/to/derivatives:/data/derivatives_dir:rw \
  -B /path/to/config.json:/config.json:ro \
  -B /tmp:/tmp \
  bloodstream_latest.sif \
  --mode non-interactive --analysis_foldername Primary_Analysis --config /config.json
```

Point `--image` at another SIF file, or at a `docker://` URI to let Apptainer
pull it. On clusters where the runtime is still called `singularity`, use
`--container singularity`.

Apptainer shares the host network, so there is no port to publish: the
interactive app is reached on the port it reports (3838 by default, scanning
upward if that one is taken). On a remote cluster, forward that port first:

```bash
ssh -L 3838:localhost:3838 username@servername
```

## Patching a local bloodstream

Use `--patch` (or `-f`) to point the wrapper at a local bloodstream checkout and
test your changes without rebuilding the image. The wrapper bind-mounts the
source into the container, where it is reinstalled from source at startup so it
overrides the bloodstream baked into the image:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --patch /path/to/your/bloodstream/checkout
```

Because bloodstream is an R package it is reinstalled (not run directly from
source), so the first few seconds of startup are spent installing the patched
package. The patch works with every mode, including `--shell`.

## Apple Silicon

The published bloodstream Docker images are currently `linux/amd64` only. The
wrapper therefore requests `--platform linux/amd64` by default, which avoids
Docker's platform-mismatch warning on Apple Silicon while running under
emulation. If a native or multi-architecture image is published later, override
the platform with `--platform linux/arm64` or disable the explicit platform with
`--platform ""`.
