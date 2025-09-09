
# bloodstream

<!-- badges: start -->
<!-- badges: end -->

The goal of `bloodstream` is to provide a simplified and automated pipeline for processing BIDS blood data for PET. The `bloodstream` package is based on functions found in `kinfitr`, but strings them together into a blood processing pipeline, producing a parameterised report as well as processed blood derivatives.

`bloodstream` can be used in two ways:
- **Interactive Mode**: Define configuration files using a graphical user interface through a web browser
- **Non-Interactive Mode**: Automated pipeline execution using pre-defined configurations

For a short introduction to processing blood data for PET, as well as tutorial for how to use `bloodstream`, I've recorded an [explainer video](https://www.youtube.com/watch?v=Kud6MWYPKxg), which should help you get started.

## Installation

You can install the development version of bloodstream like so:

``` r
remotes::install_github("mathesong/bloodstream")
```

You can also use this package as a standalone dockerised BIDS app as described below.

## Usage

### R Package Usage

In order to call `bloodstream`, you need to specify a `studypath` and a `configpath`.  

* The `studypath` is the location of the BIDS data, e.g. `../ds004230`  (relative or full paths are allowed).  

* The `configpath` is the path to the `bloodstream` configuration file, which specifies the modelling choices which you will make as a user. If left blank, then the blood data will simply be combined using linear interpolation.

The pipeline can then be called as follows:

``` r
library(bloodstream)
bloodstream(studypath, configpath)
```

### Interactive Configuration

You can launch the interactive configuration interface directly from R:

``` r
library(bloodstream)
# Launch interactive config app (always interactive)
launch_bloodstream_app()

# Launch with existing config to modify
launch_bloodstream_app(config_file = "/path/to/existing/config.json")
```

The interactive app allows you to:
- Create and modify configuration files using a graphical interface
- Load existing configurations for editing
- Download configuration files
- Run the bloodstream pipeline directly from the app


It will generate the following outputs:

* A report showing all the code and functions used, as well as plots before and after modelling.

... and for all individual PET measurements, the following

* Tabular tsv output (`*_inputfunction.tsv`) containing the estimated interpolated data which can be used for modelling.
* JSON sidecar accompanying the tabular tsv data (`*_inputfunction.tsv`).
* Model configuration JSON files, containing the models used and the AIF fit parameters if applicable (`*_config.json`).

## Docker

The bloodstream Docker image is available on Docker Hub at `mathesong/bloodstream:latest`.

You can pull the pre-built image:

```bash
docker pull mathesong/bloodstream:latest
```

Alternatively, you can build the container locally using the file `docker/dockerfile`:

```bash
cd docker
docker build -t mathesong/bloodstream:latest . --platform linux/amd64
```

### Docker Usage

The Docker container supports both interactive and non-interactive modes:

#### Interactive Mode (Configuration Interface)

Launch the interactive configuration interface:

```bash
# Basic interactive mode
docker run -p 3838:3838 \
  --user $(id -u):$(id -g) \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir \
  mathesong/bloodstream:latest --mode interactive
```

Load an existing config file into the interface:

```bash
# Interactive mode with existing config (auto-detected)
docker run -p 3838:3838 \
  --user $(id -u):$(id -g) \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir \
  -v /path/to/my_config.json:/config.json:ro \
  mathesong/bloodstream:latest --mode interactive
```

Then open http://localhost:3838 in your browser to access the configuration interface.

#### Non-Interactive Mode (Direct Pipeline Execution)

Run the pipeline with default settings:

```bash
# Non-interactive with default config
docker run \
  --user $(id -u):$(id -g) \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir \
  mathesong/bloodstream:latest
```

Run with a custom configuration file:

```bash
# Non-interactive with custom config (auto-detected)
docker run \
  --user $(id -u):$(id -g) \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir \
  -v /path/to/my_config.json:/config.json:ro \
  mathesong/bloodstream:latest
```

Run with custom analysis folder name:

```bash
# Non-interactive with custom config and folder name
docker run \
  --user $(id -u):$(id -g) \
  -v /path/to/bids:/data/bids_dir:ro \
  -v /path/to/derivatives:/data/derivatives_dir \
  -v /path/to/my_config.json:/config.json:ro \
  mathesong/bloodstream:latest \
  --analysis_foldername "MyAnalysis"
```

### Docker Command Line Options

- `--mode`: Execution mode (`interactive` or `non-interactive` [default])
- `--analysis_foldername`: Custom name for analysis subfolder (overrides config filename)

### Docker Mount Points

- **BIDS Directory** (read-only): `/data/bids_dir` - Your BIDS dataset
- **Derivatives Directory** (read-write): `/data/derivatives_dir` - Output location  
- **Config File** (optional, read-only): `/config.json` - Auto-detected configuration file

### Analysis Folder Structure

Outputs are organized in analysis folders within `derivatives/bloodstream/`:

```
derivatives/bloodstream/
├── my_config/                     # Auto-named from config filename
├── MyAnalysis/                    # Custom named via --analysis_foldername  
└── default/                       # Default when no config specified
```

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
