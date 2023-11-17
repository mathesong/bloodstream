
# bloodstream

<!-- badges: start -->
<!-- badges: end -->

The goal of `bloodstream` is to provide a simplified and automated pipeline for processing BIDS blood data for PET. The `bloodstream` package is based on functions found in `kinfitr`, but strings them together into a blood processing pipeline, producing a parameterised report as well as processed blood derivatives.

For a short introduction to processing blood data for PET, as well as tutorial for how to use `bloodstream`, I've recorded an [explainer video](https://www.youtube.com/watch?v=Kud6MWYPKxg), which should help you get started.

## Installation

You can install the development version of bloodstream like so:

``` r
remotes::install_github("mathesong/bloodstream")
```

You can also use this package as a standalone dockerised BIDS app as described below.

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

The file `docker/dockerfile` can be used to create a container that can run bloodstream.

To build the container, run: 

```
cd docker
docker build -t bloodstream . --platform linux/amd64
```

To run `bloodstream` using the Docker container, you need to mount the directory containing your BIDS dataset. Then you can run the container on your dataset as below.

```
docker run -v /path/to/bids_data/:/data/ bloodstream
```
Note, that we have not provided a config.json file, and so `bloodstream` will simply make use of a default procedure using linear interpolation only, and not make use of any more advanced modelling routines.


If you would like to make use of a config.json file (which can be created using the [web app](https://mathesong.shinyapps.io/bloodstream_config/)), then you should place the generated JSON file into a directory within the BIDS directory named `/path/to/bids_data/code/bloodstream/` and name it with a title beginning with `config_`.  Then you can direct `bloodstream` to this filename as an input argument as follows:

```
docker run -v /path/to/bids_data/:/data/ bloodstream config_pf_bpr.json
```

Once complete, all outputs from the bloodstream analysis will be located in the `/path/to/bids_data/derivatives` directory. 

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
