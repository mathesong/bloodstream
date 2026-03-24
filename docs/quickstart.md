# Quick start

bloodstream processes BIDS blood data for PET imaging. You can run it interactively (to configure and preview) or automatically (using a pre-defined config file or linear interpolation).

You will need a BIDS dataset containing blood sampling data.

## Interactive mode — create a configuration

The interactive app launches a Shiny web interface where you can configure modelling choices for each blood component and optionally run the pipeline.

`````{tab-set}

````{tab-item} Docker
```bash
docker run -it --rm \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -p 3838:3838 \
  mathesong/bloodstream:latest --mode interactive
# Then open http://localhost:3838
```
````

````{tab-item} Apptainer
```bash
apptainer run \
  --bind /path/to/bids:/data/bids_dir \
  --bind /path/to/derivatives:/data/derivatives_dir \
  bloodstream_latest.sif \
  --mode interactive
# Then open http://localhost:3838
```
````

````{tab-item} R
```r
library(bloodstream)
bloodstream_interactive(
  bids_dir = "/path/to/bids",
  derivatives_dir = "/path/to/derivatives"
)
```
````

`````

## Automatic mode — run pipeline with config

If you already have a configuration file (e.g. from the interactive app), you can run the pipeline non-interactively. The config file specifies which models to fit to each blood component.

`````{tab-set}

````{tab-item} Docker
```bash
docker run --rm \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -v /path/to/config.json:/config.json:ro \
  mathesong/bloodstream:latest
```
````

````{tab-item} Apptainer
```bash
apptainer run \
  --bind /path/to/bids:/data/bids_dir \
  --bind /path/to/derivatives:/data/derivatives_dir \
  --bind /path/to/config.json:/config.json \
  bloodstream_latest.sif
```
````

````{tab-item} R
```r
bloodstream(
  bids_dir = "/path/to/bids",
  configpath = "/path/to/config.json"
)
```
````

`````

## Automatic mode — without config (linear interpolation)

Running without a config file applies linear interpolation to all blood components. This is useful as a quick first pass or when no modelling is needed.

`````{tab-set}

````{tab-item} Docker
```bash
docker run --rm \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  mathesong/bloodstream:latest
```
````

````{tab-item} Apptainer
```bash
apptainer run \
  --bind /path/to/bids:/data/bids_dir \
  --bind /path/to/derivatives:/data/derivatives_dir \
  bloodstream_latest.sif
```
````

````{tab-item} R
```r
bloodstream(bids_dir = "/path/to/bids")
```
````

`````

## Review reports

bloodstream generates an HTML report at `derivatives/bloodstream/<analysis_foldername>/bloodstream_report.html`. Open it in your browser to review model fits, quality control plots, and processing details.

## Key arguments

These arguments are shared across `bloodstream()`, `bloodstream_interactive()`, and the container CLI:

| Argument | Purpose | Default |
|----------|---------|---------|
| `bids_dir` | Path to BIDS dataset | — |
| `derivatives_dir` | Path to derivatives directory | `bids_dir/derivatives` |
| `configpath` | Path to config JSON | `NULL` (linear interpolation) |
| `analysis_foldername` | Name for analysis subfolder | `"Primary_Analysis"` |

See the [API reference](api.md) for full details, or the [configuration guide](usage/configuration.md) for in-depth documentation of the config file.
