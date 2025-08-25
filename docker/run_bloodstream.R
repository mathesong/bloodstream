#!/usr/bin/env -S Rscript --vanilla
args <- commandArgs(trailingOnly = TRUE)

# Sort out config file
config_file <- NA

if (length(args) > 0){
  config_file <- paste0("code/bloodstream/", args[1])
}

# And BIDS directory
bids_dir <- file.path('/data')

# Load necessary libraries
library(bloodstream)

# Create a temporary directory for R Markdown processing
temp_dir <- file.path("/workdir", "temp_rmd")
dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)

# Copy the R Markdown template to the writable temp directory
template_source <- system.file("rmd", "template.rmd", package = "bloodstream")
template_dest <- file.path(temp_dir, "template.rmd")
file.copy(template_source, template_dest, overwrite = TRUE)

# Modify bloodstream function to use the copied template
bloodstream_with_temp <- function(studypath, configpath = NULL) {
  
  if( is.null(configpath) ) {
    configpath <- system.file("extdata", "config.json", package="bloodstream")
  }

  studypath <- normalizePath(studypath, winslash = "/")
  configpath <- normalizePath(configpath, winslash = "/")

  configname <- stringr::str_remove(basename(configpath), ".json")

  if( !stringr::str_detect(configname, "^config") ) {
    stop("The name of the config file is required to start with 'config'")
  }

  config_suffix <- stringr::str_match(configname, "^config_?-?(.*)")[,2]

  dir.create(paste0(studypath, "/derivatives"), showWarnings = FALSE)
  dir.create(paste0(studypath, "/derivatives/bloodstream", config_suffix),
             showWarnings = FALSE)

  # Use the temporary template location
  rmarkdown::render(
    input = template_dest,
    output_file = paste0(studypath,
                         "/derivatives/bloodstream",
                         config_suffix, "/",
                         "bloodstream_report_config",
                         ifelse(stringr::str_length(config_suffix) > 0,
                                yes = "-", no = ""),
                         config_suffix, ".html"),
    params = list(configpath = configpath,
                          studypath = studypath),
    knit_root_dir = studypath
  )
}

# Execute bloodstream
if( !is.na(config_file) ) {
  bloodstream_with_temp(bids_dir, config_file)
} else {
  bloodstream_with_temp(bids_dir)
}

