#!/usr/bin/env Rscript

library(tidyverse)
library(optparse)
library(bloodstream)
library(kinfitr)

# PW: new to R.  Following along here:
#   - https://www.r-bloggers.com/2015/09/passing-arguments-to-an-r-script-from-command-lines/
option_list = list(
  make_option(c("-s", "--studypath"), type="character", default=NULL, 
              help="path to BIDS dataset", metavar="character"),
  make_option(c("-c", "--config"), type="character", default=NULL, 
              help="location of config file (https://mathesong.shinyapps.io/bloodstream_config/)", 
              metavar="character")
); 
 
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$studypath)){
  print_help(opt_parser)
  stop("--studypath is a required argument", call.=FALSE)
}

bloodstream(studypath = opt$studypath, configpath = opt$config)
