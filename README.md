
# bloodstream

<!-- badges: start -->
<!-- badges: end -->

The goal of `bloodstream` is to provide a simplified and automated pipeline for processing BIDS blood data for PET. The `bloodstream` package is based on functions found in `kinfitr`, but strings them together into a blood processing pipeline, producing a parameterised report as well as processed blood derivatives.

## Installation

You can install the development version of bloodstream like so:

``` r
remotes::install_github("mathesong/bloodstream")
```

I hope to turn this package into a Dockerised BIDS app soon for doing the processing as a standalone app, but for now it can only be called through R or by building the docker container described below.

## Usage

In order to call `bloodstream`, you need to specify a `studypath` and a `configpath`.  

* The `studypath` is the location of the BIDS data, e.g. `../ds004230`  (relative or full paths are allowed).  

* The `configpath` is the path to the `bloodstream` configuration file, which specifies the modelling choices which you will make as a user.  To create a configuration file, go to the [bloodstream configuration web app](https://mathesong.shinyapps.io/bloodstream_config/), fill in the fields as required, and download the JSON configuration file.  The `configpath` specifies the location of the downloaded config file, e.g. `../config_test_analysis.json`. If left blank, then the blood data will simply be combined using linear interpolation.

The pipeline can then be called as follows:

``` r
library(bloodstream)
bloodstream(studypath, configpath)
```


It will generate the following outputs:

* A report showing all the code and functions used, as well as plots before and after modelling.

... and for all individual PET measurements, the following

* Tabular tsv output (`*_inputfunction.tsv`) containing the estimated interpolated data which can be used for modelling.
* JSON sidecar accompanying the tabular tsv data (`*_inputfunction.tsv`).
* Model configuration JSON files, containing the models used and the AIF fit parameters if applicable (`*_config.json`).

## Docker

The file `docker/dockerfile` can be used to create a container that can run bloodstream either interactively in a Jupyter notebook or directly in a terminal (many thanks to @pwighton for this addition!).

To build the container, run: 

```
cd docker
docker build -t bloodstream:ubuntu-22.04 .
```

The container derives from [`jupyter/r-notebook:ubuntu-22.04`](https://hub.docker.com/r/jupyter/r-notebook) (parent dockerfile lives [here](https://raw.githubusercontent.com/jupyter/docker-stacks/main/images/r-notebook/Dockerfile)) and can be invoked using:

```
docker run -it --rm \
  -p 8888:8888  \
  -v ${HOME}:/home/jovyan/work \
  bloodstream:ubuntu-22.04
```

Then navigate to http://127.0.0.1:8888 (Look in the terminal output for the URL with the session token)

At some point in the future, the docker functionality will be expanded to include a non-interactive mode as well as a fully dockerised BIDS App.  But for now, this approach allows users to run `bloodstream` without needing to install R.


## Citation

Until there is a preprint or publication about `bloodstream`, please just specify that "`bloodstream` was used for blood analysis, which is a blood processing pipeline built around `kinfitr` [REF]".  

To cite `kinfitr`, please cite at least one of the following:

An introduction to the package:

> Matheson, G. J. (2019). *Kinfitr: Reproducible PET Pharmacokinetic Modelling in R*. bioRxiv: 755751. https://doi.org/10.1101/755751


A validation study compared against commercial software:

> Tjerkaski, J., Cervenka, S., Farde, L., & Matheson, G. J. (2020). *Kinfitr – an open source tool for reproducible PET modelling: Validation and evaluation of test-retest reliability*. EJNMMI Res 10, 77 (2020). https://doi.org/10.1186/s13550-020-00664-8
