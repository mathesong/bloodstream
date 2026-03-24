# API reference

This page documents bloodstream's main R functions and container CLI options.

## Automatic pipeline

### `bloodstream()`

Run the bloodstream pipeline non-interactively.

```r
bloodstream(
  bids_dir,
  configpath = NULL,
  derivatives_dir = NULL,
  analysis_foldername = "Primary_Analysis",
  template_path = NULL
)
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `bids_dir` | Path to the BIDS directory containing blood data |
| `configpath` | Path to a JSON configuration file. If `NULL`, linear interpolation is applied to all components |
| `derivatives_dir` | Path to derivatives directory. If `NULL`, defaults to `bids_dir/derivatives` |
| `analysis_foldername` | Name of the analysis subfolder within `derivatives/bloodstream/` (default: `"Primary_Analysis"`) |
| `template_path` | Path to a custom Quarto report template. If `NULL`, uses the built-in template |

## Interactive app

### `bloodstream_interactive()`

Launch the bloodstream Shiny configuration app in your browser.

```r
bloodstream_interactive(
  bids_dir = NULL,
  derivatives_dir = NULL,
  configpath = NULL,
  analysis_foldername = "Primary_Analysis",
  host = "127.0.0.1",
  port = 3838
)
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `bids_dir` | Path to the BIDS directory. If `NULL`, runs in standalone config creation mode |
| `derivatives_dir` | Path to derivatives directory. If `NULL` and `bids_dir` is provided, defaults to `bids_dir/derivatives` |
| `configpath` | Path to an existing config file to load into the app |
| `analysis_foldername` | Name of the analysis subfolder (default: `"Primary_Analysis"`) |
| `host` | Host address for the Shiny server (default: `"127.0.0.1"`) |
| `port` | Port number for the Shiny server (default: `3838`) |

**Usage modes:**

- **Standalone**: `bloodstream_interactive()` — create and download config files without any data
- **With BIDS data**: `bloodstream_interactive(bids_dir = "/path/to/bids")` — create configs and optionally run the pipeline
- **Load existing config**: `bloodstream_interactive(bids_dir = "/path/to/bids", configpath = "/path/to/config.json")` — edit an existing configuration

## Container CLI options

When running bloodstream in Docker or Singularity/Apptainer, the container accepts these flags:

| Flag | Description |
|------|-------------|
| `--mode` | `interactive` or `non-interactive` (default) |
| `--config` | Path to config file (auto-detected at `/config.json` if mounted) |
| `--analysis_foldername` | Analysis subfolder name (default: `Primary_Analysis`) |
