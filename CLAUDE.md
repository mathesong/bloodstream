# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`bloodstream` is an R package that provides a simplified and automated pipeline for processing BIDS blood data for PET imaging. It processes blood data and produces parameterised reports along with processed blood derivatives for pharmacokinetic modelling.

The package supports two execution modes:
- **Interactive Mode**: Shiny-based web interface for creating and modifying configuration files, with integrated pipeline execution
- **Non-Interactive Mode**: Direct pipeline execution using pre-defined configuration files

## Package Structure

This is a standard R package with the following key components:

- **Core Function**: `bloodstream()` in `R/run_bloodstream.R` is the main entry point
- **Interactive Apps**: 
  - `R/config_app.R` contains the Shiny configuration interface
  - `R/launch_apps.R` provides app launcher functionality
- **Modelling**: `R/modelling.R` contains model comparison functions for parent fraction analysis
- **Plotting**: `R/plotting.R` contains visualization functions for different blood components
- **Quality Control**: `R/qc.R` contains validation functions for blood processing results
- **Utilities**: `R/helper_funcs.R` and `R/subsetting.R` contain helper functions
- **Templates**: `inst/rmd/template.rmd` is the R Markdown template for generating reports
- **Configuration**: `inst/extdata/config.json` provides default configuration settings

## Key Dependencies

The package depends on several key R packages:
- `kinfitr` (>= 0.7.1) - Core PET pharmacokinetic modelling functions
- `tidyverse` - Data manipulation and visualization
- `shiny`, `shinythemes`, `bslib` - Interactive web interface
- `optparse` - Command-line argument parsing for Docker
- `mgcv` - GAM modelling for parent fraction analysis
- `gratia` - GAM visualization and analysis
- `rmarkdown`/`quarto` - Report generation

## Development Commands

### Package Development
```r
# Install development version
remotes::install_github("mathesong/kinfitr")  # Install dependency first
devtools::install()  # Install local package

# Build and check package
devtools::check()
devtools::build()

# Generate documentation
devtools::document()
```

### Docker Development
```bash
# Build Docker image
cd docker
docker build -t mathesong/bloodstream:latest . --platform linux/amd64

# Pull pre-built image
docker pull mathesong/bloodstream:latest

# Interactive mode (launches Shiny app on port 3838)
docker run -p 3838:3838 \
  --user $(id -u):$(id -g) \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir \
  mathesong/bloodstream:latest --mode interactive

# Non-interactive mode with config file
docker run \
  --user $(id -u):$(id -g) \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir \
  -v /path/to/config.json:/config.json:ro \
  mathesong/bloodstream:latest

# Non-interactive mode without config (uses defaults)
docker run \
  --user $(id -u):$(id -g) \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir \
  mathesong/bloodstream:latest
```

## Core Architecture

### Pipeline Flow
1. **Input Processing**: Takes BIDS study path and optional config file
2. **Configuration**: Uses JSON config to specify modelling choices for different blood components
3. **Blood Component Modelling**:
   - **Parent Fraction**: Hill, exponential, power, sigmoid, inverse gamma, gamma, or GAM models
   - **Blood-to-Plasma Ratio (BPR)**: Various modelling approaches
   - **Arterial Input Function (AIF)**: Spline-based or exponential decay modelling  
   - **Whole Blood**: Spline-based modelling with optional dispersion correction
4. **Report Generation**: R Markdown template generates comprehensive HTML report
5. **Output**: TSV files, JSON sidecars, and configuration files in BIDS derivatives format

### Configuration System
The package uses JSON configuration files to specify:
- Data subsets (subject, session, tracer, institution filters)
- Modelling methods for each blood component
- Time ranges and model parameters
- Model comparison criteria (AIC-based selection)

### Key Functions
- `bloodstream()`: Main pipeline function
- `bloodstream_config_app()`: Interactive Shiny configuration interface
- `launch_bloodstream_app()`: App launcher with parameter handling
- `compare_aic_metabmodels_*()`: Model comparison for parent fraction
- `plot_*_preds()`: Visualization functions for each blood component  
- `qc_*()`: Quality control validation functions
- `get_filterable_attributes()`: Extract metadata for filtering

## Report Template

The R Markdown template (`inst/rmd/template.rmd`) generates comprehensive reports including:
- Model fitting results and comparisons
- Before/after plots for each blood component
- Quality control metrics
- Processing configuration details

The template uses parameterized rendering with `studypath` and `configpath` parameters.

## Docker Integration

The Docker implementation (`docker/dockerfile`) creates a BIDS app that:
- Uses `rocker/shiny-verse` as base image for Shiny support
- Installs the package from source code with dependencies
- Supports dual directory mounting (BIDS read-only, derivatives read-write)
- Runs via enhanced `docker/run_bloodstream.R` with mode selection
- Supports both interactive (Shiny) and non-interactive (direct pipeline) execution
- Auto-detects config files mounted at `/config.json`
- Organizes outputs in analysis folders within `derivatives/bloodstream/`

### Docker Architecture Features
- **User Permission Handling**: Proper UID/GID mapping to avoid permission issues
- **Config Auto-Detection**: Automatically uses `/config.json` if mounted
- **Analysis Folder Management**: Auto-names folders from config files or allows custom naming
- **Port Exposure**: Exposes port 3838 for interactive Shiny interface
- **Flexible Mounting**: Supports various directory mounting patterns

## Data Processing

The package processes BIDS blood data by:
1. Reading blood sampling data from BIDS format
2. Applying quality control checks
3. Fitting specified models to different blood components
4. Comparing models using AIC when multiple options are provided
5. Interpolating final blood curves for PET modelling
6. Generating standardized outputs in BIDS derivatives format