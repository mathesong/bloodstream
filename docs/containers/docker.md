# Docker

For a quick introduction, see the [Quick start](../quickstart.md). This page covers advanced options and detailed reference.

## Getting the image

```bash
# Pull pre-built image
docker pull mathesong/bloodstream:latest

# Or build from source
git clone https://github.com/mathesong/bloodstream.git
cd bloodstream
docker build -f docker/dockerfile -t mathesong/bloodstream:latest . --platform linux/amd64
```

## The bloodstream-docker wrapper

bloodstream includes a lightweight Python wrapper, `bloodstream-docker`, inspired by the PETPrep Docker wrapper. It accepts a BIDS-App-like command line, maps host directories into the container, checks whether the image exists locally, and then runs the bloodstream image. Interactive mode is the default; use `--automatic` (or `--mode non-interactive`) to run the pipeline.

Install it from PyPI:

```bash
pip install bloodstream-docker
```

Run `bloodstream-docker --help` to see all available options.

Create a config file interactively, with no data at all:

```bash
bloodstream-docker
```

Launch the app with data, so it can also run the pipeline:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant
```

The wrapper follows the BIDS App positional argument convention:

```text
bloodstream-docker <bids_dir> <output_dir> participant
```

The positional `output_dir` may be the derivatives root or the final bloodstream output folder: `/path/to/derivatives` and `/path/to/derivatives/bloodstream` both map to the container's derivatives root.

Run the pipeline with a config file, in its own analysis folder:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --config /path/to/config.json \
  --automatic \
  --analysis-foldername Model_AIF
```

Print the generated command without executing it:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant --dry-run
```

Pass `--apptainer` to generate an `apptainer run` command instead — see [Apptainer](apptainer.md).

The published bloodstream images are currently `linux/amd64` only. The wrapper requests `--platform linux/amd64` by default so Docker does not emit a platform mismatch warning on Apple Silicon. Override this with `--platform` if a native or multi-architecture image is available.

Test a local bloodstream checkout without rebuilding the image with `--patch` (or `-f`). The wrapper bind-mounts the source into the container, where bloodstream is reinstalled from it at startup so it overrides the version baked into the image:

```bash
bloodstream-docker /path/to/bids /path/to/derivatives participant \
  --patch /path/to/your/bloodstream/checkout
```

## Interactive mode

Interactive mode launches a Shiny web app accessible in your browser at `http://localhost:3838`.

The examples below show the raw `docker run` commands; each has a shorter `bloodstream-docker` equivalent above.

**Standalone config creation** (no BIDS data needed):

```bash
docker run -it --rm \
  -p 3838:3838 \
  mathesong/bloodstream:latest --mode interactive
```

**With BIDS data** (enables pipeline execution from the app):

```bash
docker run -it --rm \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -p 3838:3838 \
  mathesong/bloodstream:latest --mode interactive
```

**Load existing config** (auto-detected when mounted at `/config.json`):

```bash
docker run -it --rm \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -v /path/to/my_config.json:/config.json:ro \
  -p 3838:3838 \
  mathesong/bloodstream:latest --mode interactive
```

The container exits cleanly when you close the app.

## Non-interactive mode

Non-interactive mode runs the pipeline directly. The container exits when processing is complete.

**Default (linear interpolation):**

```bash
docker run --rm \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  mathesong/bloodstream:latest
```

**With config file (fits models):**

```bash
docker run --rm \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -v /path/to/my_config.json:/config.json:ro \
  mathesong/bloodstream:latest
```

**Custom analysis folder name:**

```bash
docker run --rm \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -v /path/to/my_config.json:/config.json:ro \
  mathesong/bloodstream:latest \
  --analysis_foldername "Model_AIF"
```

## Command-line options

| Option | Description |
|--------|-------------|
| `--mode` | `interactive` or `non-interactive` (default) |
| `--config` | Path to config file (auto-detected at `/config.json` if mounted) |
| `--analysis_foldername` | Analysis subfolder name (default: `Primary_Analysis`) |
| `--bids_dir` | Explicit BIDS path inside the container, instead of the `/data/bids_dir` mount point |
| `--derivatives_dir` | Explicit derivatives path inside the container, instead of the `/data/derivatives_dir` mount point |

These are the options of the container itself. The `bloodstream-docker` wrapper takes the same choices in BIDS App form (`--mode`, `--config`, `--analysis-foldername`) and translates them.

## Mount points

| Mount point | Access | Purpose |
|-------------|--------|---------|
| `/data/bids_dir` | Read-only | Your BIDS dataset |
| `/data/derivatives_dir` | Read-write | Output location for derivatives |
| `/config.json` | Read-only (optional) | Configuration file (auto-detected) |

## Port configuration

The container exposes port 3838 internally. Map it to any host port:

```bash
-p 3838:3838    # Standard
-p 8080:3838    # Custom port for server usage
-p 3839:3838    # Run multiple instances
```

The port you browse to is always the **host** port — the left-hand side of `-p`. To run several instances at once, give each a different host port; the container side can stay `3838`.

The entrypoint also checks that its internal port is free and, if not, scans upward to the next available one (printing the final `http://localhost:<port>` address). Within Docker's isolated network this rarely changes anything, but if you want to move the internal port — for example to match a custom `-p` target — set `SHINY_PORT`:

```bash
-e SHINY_PORT=8080 ... -p 8080:8080
```

With the wrapper, `--port 8080` sets both sides at once.

## File permissions on Linux

On Linux, Docker containers run as root by default, which can cause permission issues with output files. Two solutions:

**Option 1 (recommended): Run as your user:**

```bash
docker run --user $(id -u):$(id -g) \
  # ... rest of your command
```

**Option 2: Fix permissions afterwards:**

```bash
sudo chown -R $(id -u):$(id -g) /path/to/derivatives
```

## Batch processing

```bash
for analysis in Analysis1 Analysis2 Analysis3; do
  docker run --rm \
    --user $(id -u):$(id -g) \
    -v /path/to/bids:/data/bids_dir:ro \
    -v /path/to/derivatives:/data/derivatives_dir:rw \
    -v /path/to/configs/${analysis}_config.json:/config.json:ro \
    mathesong/bloodstream:latest \
    --analysis_foldername "$analysis"
done
```

## Analysis folder structure

Outputs are organised in analysis folders within `derivatives/bloodstream/`:

```
derivatives/bloodstream/
├── Primary_Analysis/              # Default analysis folder name
├── pf_bpr_mod/                    # Custom named via --analysis_foldername
└── another_analysis/              # Another custom analysis
```

## Error codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 3 | Processing error |
