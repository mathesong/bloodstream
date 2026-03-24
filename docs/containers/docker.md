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

## Interactive mode

Interactive mode launches a Shiny web app accessible in your browser at `http://localhost:3838`.

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
