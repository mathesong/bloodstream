
# bloodstream

<!-- badges: start -->
<!-- badges: end -->

The goal of `bloodstream` is to provide a simplified and automated pipeline for processing BIDS blood data for PET. The `bloodstream` package is based on functions found in `kinfitr`, but strings them together into a blood processing pipeline, producing a parameterised report as well as processed blood derivatives.

`bloodstream` can be used in two ways:
- **Interactive Mode**: Define configuration files using a graphical user interface through a web browser
- **Non-Interactive Mode**: Automated pipeline execution using pre-defined configurations

For a short introduction to processing blood data for PET, as well as tutorial for how to use `bloodstream`, I've recorded an [explainer video](https://www.youtube.com/watch?v=Kud6MWYPKxg), which should help you get started.

**NOTE**: The previous web-based bloodstream configuration file definition tool has been deprecated in favour of running the configuration file definition locally using the package itself.

## Installation

`bloodstream` can be used in two ways:

- **[R Package Usage](#r-package-usage)**: Install and use directly in R
- **[Docker Usage](#docker-usage)**: Use as a standalone containerized BIDS app without installing R or the package dependencies locally

## Usage

## Pipeline Workflow Summary

| Step | R Usage | Docker Usage |
|------|---------|--------------|
| Run without config | `bloodstream(bids_dir)` → linear interpolation | `docker run ...` → linear interpolation |
| Run with config | `bloodstream(bids_dir, configpath)` → fits models | `docker run -v my_config.json:/config.json ...` → fits models |
| Launch config app (standalone) | `launch_bloodstream_app()` → design and save config | `docker run -p 3838:3838 -v /path/to/derivatives:/data/derivatives_dir:rw ... --mode interactive` → design and save config |
| Launch config app (with data) | `launch_bloodstream_app(bids_dir = "/path/to/study")` → design, run, or linear interpolation | `docker run -p 3838:3838 -v /path/to/bids:/data/bids_dir:ro -v /path/to/derivatives:/data/derivatives_dir:rw ... --mode interactive` → design, run, or linear interpolation |
| Run pipeline after config | Use saved config with `bloodstream()` | Use saved config with Docker run |


### R Package Usage

#### Installation

You can install the development version of bloodstream like so:

``` r
remotes::install_github("mathesong/bloodstream")
```

#### Function Parameters

The `bloodstream` function accepts several parameters:

* **`bids_dir`**: The location of the BIDS data, e.g. `../ds004230` (relative or full paths are allowed).
* **`configpath`**: The path to the `bloodstream` configuration file, which specifies the modelling choices. If left blank or NULL, the blood data will be combined using linear interpolation only.
* **`derivatives_dir`**: Path to derivatives directory. If NULL, uses `bids_dir/derivatives`.
* **`analysis_foldername`**: Name for the analysis subfolder (default: "Primary_Analysis").

#### Pipeline Execution

The pipeline can be called as follows:

``` r
library(bloodstream)

# Basic usage with default config (linear interpolation)
bloodstream(bids_dir)

# With custom config
bloodstream(bids_dir, configpath)

# With custom analysis folder name
bloodstream(bids_dir, configpath, analysis_foldername = "my_analysis")

# With separate derivatives directory
bloodstream(bids_dir, configpath, derivatives_dir = "/path/to/derivatives")
```

#### Interactive Configuration

You can launch the interactive configuration interface directly from R:

``` r
library(bloodstream)

# Standalone config creation (no BIDS data needed)
launch_bloodstream_app()

# With BIDS directory (enables pipeline execution, auto-derives derivatives)
launch_bloodstream_app(bids_dir = "/path/to/study")

# With separate BIDS and derivatives directories
launch_bloodstream_app(bids_dir = "/path/to/study", derivatives_dir = "/path/to/derivatives")

# Load existing config for modification
launch_bloodstream_app(bids_dir = "/path/to/study", config_file = "/path/to/config.json")

# Custom analysis folder name
launch_bloodstream_app(bids_dir = "/path/to/study", analysis_foldername = "my_analysis")
```

The interactive app allows you to:
- Create and modify configuration files using a graphical interface
- Load existing configurations for editing  
- Download configuration files
- Run the bloodstream pipeline with custom configurations OR with linear interpolation (when BIDS directory is provided)
- Work in standalone mode for config creation only (when no BIDS directory is provided)


It will generate the following outputs:

* A report showing all the code and functions used, as well as plots before and after processing (either modeling or linear interpolation).

... and for all individual PET measurements, the following

* Tabular tsv output (`*_inputfunction.tsv`) containing the estimated data (either model-fitted or linearly interpolated) which can be used for pharmacokinetic modelling.
* JSON sidecar accompanying the tabular tsv data (`*_inputfunction.json`).
* Model configuration JSON files, containing the models used and fit parameters if applicable (`*_config.json`).

## Docker

The bloodstream Docker image is available on Docker Hub at `mathesong/bloodstream:latest`.

You can pull the pre-built image:

```bash
docker pull mathesong/bloodstream:latest
```

Alternatively, you can build the container locally using the file `docker/dockerfile`:

```bash
docker build -f docker/dockerfile -t mathesong/bloodstream:latest . --platform linux/amd64
```

### Docker Usage

The Docker container supports both interactive and non-interactive modes:

#### Interactive Mode (Configuration Interface)

**Standalone Config Creation** (no BIDS data needed):
```bash
# Create configs without BIDS data (requires derivatives directory for saving)
docker run -p 3838:3838 \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  mathesong/bloodstream:latest --mode interactive
```

**Interactive Mode with BIDS Data** (enables pipeline execution):
```bash
# Full interactive mode with BIDS data (enables config creation, pipeline with config, or linear interpolation)
docker run -p 3838:3838 \
  -v /path/to/bids/dir:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  mathesong/bloodstream:latest --mode interactive
```

**Load Existing Config**:
```bash
# Interactive mode with existing config (auto-detected)
docker run -p 3838:3838 \
  -v /path/to/bids/dir:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -v /path/to/my_config.json:/config.json:ro \
  mathesong/bloodstream:latest --mode interactive
```

Then open http://localhost:3838 in your browser to access the configuration interface.

#### Non-Interactive Mode (Direct Pipeline Execution)

Run the pipeline with default settings (linear interpolation):

```bash
# Non-interactive with default config (linear interpolation)
docker run \
  -v /path/to/bids/dir:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  mathesong/bloodstream:latest
```

Run with a custom configuration file (fits models):

```bash
# Non-interactive with custom config (fits models, auto-detected)
docker run \
  -v /path/to/bids/dir:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -v /path/to/my_config.json:/config.json:ro \
  mathesong/bloodstream:latest
```

Run with custom analysis folder name:

```bash
# Non-interactive with custom config and folder name (fits models)
docker run \
  -v /path/to/bids/dir:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir:rw \
  -v /path/to/my_config.json:/config.json:ro \
  mathesong/bloodstream:latest \
  --analysis_foldername "Model_AIF"
```

Below are two examples of running the app for a real folder:

```bash
# Interactive mode with real paths and custom analysis folder
docker run -p 3838:3838 \
  -v /home/granville/Repositories/OpenNeuro/ds004869/:/data/bids_dir:ro \
  -v /home/granville/Repositories/OpenNeuro/ds004869/derivatives/:/data/derivatives_dir:rw \
  mathesong/bloodstream:latest --mode interactive --analysis_foldername Secondary_Analysis
  

docker run \
  -v /home/granville/Repositories/OpenNeuro/ds004869/:/data/bids_dir:ro \
  -v /home/granville/Repositories/OpenNeuro/ds004869/derivatives/:/data/derivatives_dir:rw \
  -v /home/granville/Downloads/config_test.json:/config.json:ro \
  mathesong/bloodstream:latest --analysis_foldername Tertiary_Analysis
```

### Docker Command Line Options

- `--mode`: Execution mode (`interactive` or `non-interactive` [default])
- `--analysis_foldername`: Custom name for analysis subfolder (overrides config filename)

### Docker File Permissions Note

On Linux systems, if you encounter permission issues where output files are owned by root, you have two options:

1. **Add the user flag** to run the container with your user ID:
   ```bash
   docker run --user $(id -u):$(id -g) \
     # ... rest of your docker command
   ```

2. **Fix permissions afterward** using chown:
   ```bash
   sudo chown -R $(id -u):$(id -g) /path/to/derivatives
   ```


### Docker Mount Points

- **BIDS Directory** (read-only): `/data/bids_dir:ro` - Your BIDS dataset
- **Derivatives Directory** (read-write): `/data/derivatives_dir:rw` - Output location  
- **Config File** (optional, read-only): `/config.json:ro` - Auto-detected configuration file

### Analysis Folder Structure

Outputs are organised in analysis folders within `derivatives/bloodstream/`:

```
derivatives/bloodstream/
├── Primary_Analysis/              # Default analysis folder name
├── pf_bpr_mod/                    # Custom named via --analysis_foldername  
└── another_analysis/              # Another custom analysis
```

The default analysis folder name is "Primary_Analysis". You can customise this using the `--analysis_foldername` parameter in Docker or the `analysis_foldername` parameter in R functions.

Once complete, all outputs from the bloodstream analysis will be located in the `derivatives/bloodstream/<analysis_folder>/` directory. 

<!---
## Docker example

If your BIDS dataset is located at `/Users/mn/my_study`. Then you create the directories `/Users/mn/my_study/code/bloodstream` and add the `config.json` to this directory. After that you can run

```
docker run -v /Users/mn/mystudy:/data/ bloodstream
```

and all your outputs will be in `/Users/mn/my_study/derivatives/bloodstream`.
-->



## Citation

Until there is a preprint or publication about `bloodstream`, please just specify that "`bloodstream` was used for blood analysis, which is a blood processing pipeline built around `kinfitr` [REF]".  

To cite `kinfitr`, please cite at least one of the following:

An introduction to the package:

> Matheson, G. J. (2019). *Kinfitr: Reproducible PET Pharmacokinetic Modelling in R*. bioRxiv: 755751. https://doi.org/10.1101/755751


A validation study compared against commercial software:

> Tjerkaski, J., Cervenka, S., Farde, L., & Matheson, G. J. (2020). *Kinfitr – an open source tool for reproducible PET modelling: Validation and evaluation of test-retest reliability*. EJNMMI Res 10, 77 (2020). https://doi.org/10.1186/s13550-020-00664-8
