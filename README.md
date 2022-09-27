
# bloodstream

<!-- badges: start -->
<!-- badges: end -->

The goal of `bloodstream` is to provide a simplified and automated pipeline for processing BIDS blood data for PET. The `bloodstream` package is based on functions found in `kinfitr`, but strings them together into a blood processing pipeline, producing a parameterised report as well as processed blood derivatives.

## Installation

You can install the development version of bloodstream like so:

``` r
remotes::install_package("mathesong/bloodstream")
```

I hope to turn this package into a Dockerised BIDS app soon for doing the processing as a standalone app, but for now it can only be called through R.

## Usage

In order to call `bloodstream`, you need to specify a `studypath` and a `configpath`.  

* The `studypath` is the location of the BIDS data relative to the current working directory, e.g. `../ds004230`.  

* The `configpath` is the path to the `bloodstream` configuration file, which specifies the modelling choices which you will make as a user.  To create a configuration file, go to the [bloodstream configuration web app](https://mathesong.shinyapps.io/bloodstream_config/), fill in the fields as required, and download the JSON configuration file.  The `configpath` specifies the location of the downloaded config file, e.g. `../config_test_analysis.json`.

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

## Citation

Until there is a preprint or publication about `bloodstream`, please just specify that "`bloodstream` was used for blood analysis, which is a blood processing pipeline built around `kinfitr` [REF]".  

To cite `kinfitr`, please cite at least one of the following:

An introduction to the package:

> Matheson, G. J. (2019). *Kinfitr: Reproducible PET Pharmacokinetic Modelling in R*. bioRxiv: 755751. https://doi.org/10.1101/755751


A validation study compared against commercial software:

> Tjerkaski, J., Cervenka, S., Farde, L., & Matheson, G. J. (2020). *Kinfitr – an open source tool for reproducible PET modelling: Validation and evaluation of test-retest reliability*. EJNMMI Res 10, 77 (2020). https://doi.org/10.1186/s13550-020-00664-8
