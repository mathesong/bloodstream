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

# Execute bloodstream
if( !is.na(config_file) ) {
  bloodstream(bids_dir, config_file)
} else {
  bloodstream(bids_dir)
}

