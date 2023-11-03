# run_bloodstream.R
bids_dir <- file.path('/data')
config_file <- file.path(bids_dir, 'code/bloodstream', 'config.json')

# Load necessary libraries
library(bloodstream)

# Execute bloodstream
bloodstream(bids_dir, config_file)
