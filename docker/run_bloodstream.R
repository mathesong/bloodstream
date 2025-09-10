#!/usr/bin/env Rscript

# Docker entry script for bloodstream apps
# Supports both interactive and non-interactive modes with flexible directory mounting

library(optparse)

# Define command line options
option_list <- list(
  make_option(c("--mode"), type="character", default="non-interactive", 
              help="Execution mode: 'interactive' or 'non-interactive' [default: non-interactive]"),
  make_option(c("--config"), type="character", default=NULL, 
              help="Path to config file [optional]"),
  make_option(c("--analysis_foldername"), type="character", default=NULL, 
              help="Name for analysis subfolder [optional - defaults to config filename]")
)

# Parse arguments
opt_parser <- OptionParser(option_list=option_list, 
                          description="Docker entry point for bloodstream apps")
opt <- parse_args(opt_parser)

# Validate arguments
if (!opt$mode %in% c("interactive", "non-interactive")) {
  stop("--mode must be 'interactive' or 'non-interactive'", call.=FALSE)
}

cat("=== bloodstream Docker Container ===\n")
cat("Mode:", opt$mode, "\n")
if (!is.null(opt$config)) {
  cat("Config file:", opt$config, "\n")
}
if (!is.null(opt$analysis_foldername)) {
  cat("Analysis folder:", opt$analysis_foldername, "\n")
}
cat("\n")

# Detect mounted directories
detect_mounted_directories <- function() {
  bids_available <- dir.exists("/data/bids_dir")
  derivatives_available <- dir.exists("/data/derivatives_dir")
  
  cat("=== Directory Detection ===\n")
  cat("BIDS directory mounted:", bids_available, "\n")
  cat("Derivatives directory mounted:", derivatives_available, "\n")
  cat("\n")
  
  # For interactive mode, we need at least derivatives_dir (for saving config files)
  # For non-interactive mode, we need at least bids_dir
  if (opt$mode == "interactive") {
    if (!derivatives_available) {
      stop("Interactive mode requires derivatives_dir to be mounted for saving configuration files", call.=FALSE)
    }
  } else {
    if (!bids_available) {
      stop("Non-interactive mode requires bids_dir to be mounted", call.=FALSE)
    }
  }
  
  # Set directory paths based on what's available
  bids_dir <- if(bids_available) "/data/bids_dir" else NULL
  derivatives_dir <- if(derivatives_available) "/data/derivatives_dir" else NULL
  
  return(list(
    bids_dir = bids_dir,
    derivatives_dir = derivatives_dir
  ))
}

# Load bloodstream package
library(bloodstream)

# Detect available directories
dirs <- detect_mounted_directories()

cat("=== Directory Configuration ===\n")
if (!is.null(dirs$bids_dir)) {
  cat("Using BIDS directory:", dirs$bids_dir, "\n")
}
if (!is.null(dirs$derivatives_dir)) {
  cat("Using derivatives directory:", dirs$derivatives_dir, "\n")
} else if (!is.null(dirs$bids_dir)) {
  cat("Derivatives directory will default to:", file.path(dirs$bids_dir, "derivatives"), "\n")
}
cat("\n")

# Determine analysis folder name
get_analysis_folder_name <- function(config_path, override_name = NULL) {
  if (!is.null(override_name)) {
    return(override_name)
  }
  
  # Use Primary_Analysis as default (like kinfitr_app)
  return("Primary_Analysis")
}

analysis_folder <- get_analysis_folder_name(opt$config, opt$analysis_foldername)
cat("Analysis folder name:", analysis_folder, "\n")
cat("\n")

# Execute based on mode
if (opt$mode == "interactive") {
  cat("=== Starting Interactive Mode ===\n")
  cat("Shiny app will be available at http://localhost:3838\n")
  cat("Container will exit when app is closed\n")
  cat("\n")
  
  # Determine config file for interactive mode
  config_for_app <- NULL
  if (!is.null(opt$config)) {
    config_for_app <- opt$config
  } else if (file.exists("/config.json")) {
    config_for_app <- "/config.json"
    cat("Auto-detected config file for app:", config_for_app, "\n")
  }
  
  # Launch bloodstream config app interactively
  launch_bloodstream_app(
    bids_dir = dirs$bids_dir,
    derivatives_dir = dirs$derivatives_dir,
    config_file = config_for_app,
    analysis_foldername = analysis_folder,
    host = "0.0.0.0",  # Important for Docker
    port = 3838
  )
  
  cat("App closed. Container exiting.\n")
  
} else if (opt$mode == "non-interactive") {
  cat("=== Starting Non-Interactive Mode ===\n")
  
  # Set up directory paths
  bids_path <- dirs$bids_dir
  derivatives_path <- dirs$derivatives_dir %||% file.path(dirs$bids_dir, "derivatives")
  bloodstream_dir <- file.path(derivatives_path, "bloodstream")
  analysis_path <- file.path(bloodstream_dir, analysis_folder)
  
  cat("BIDS path:", bids_path %||% "NULL", "\n")
  cat("Derivatives path:", derivatives_path, "\n")
  cat("Analysis path:", analysis_path, "\n")
  
  # Create analysis directory if it doesn't exist
  if (!dir.exists(analysis_path)) {
    dir.create(analysis_path, recursive = TRUE)
    cat("Created analysis directory:", analysis_path, "\n")
  }
  
  # Handle config file
  config_to_use <- NULL
  
  # Check for config file: command line argument takes precedence, then auto-detect /config.json
  config_source <- NULL
  if (!is.null(opt$config)) {
    config_source <- opt$config
    cat("Using config from command line:", config_source, "\n")
  } else if (file.exists("/config.json")) {
    config_source <- "/config.json"
    cat("Auto-detected config file:", config_source, "\n")
  }
  
  if (!is.null(config_source)) {
    # Copy config file to analysis directory for reproducibility
    config_dest <- file.path(analysis_path, basename(config_source))
    file.copy(config_source, config_dest, overwrite = TRUE)
    config_to_use <- config_dest
    cat("Copied config file to:", config_dest, "\n")
  } else {
    cat("Using default config from package\n")
  }
  
  # Execute bloodstream pipeline
  tryCatch({
    
    # Create a temporary directory for R Markdown processing
    # This is crucial for Docker permission handling
    temp_dir <- file.path("/app", "temp_rmd")
    dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)
    
    # Copy the R Markdown template to the writable temp directory
    template_source <- system.file("rmd", "template.rmd", package = "bloodstream")
    template_dest <- file.path(temp_dir, "template.rmd")
    file.copy(template_source, template_dest, overwrite = TRUE)
    
    # Run bloodstream using the updated function with custom template location
    result <- bloodstream(
      studypath = bids_path, 
      configpath = config_to_use,
      derivatives_dir = derivatives_path,
      analysis_foldername = analysis_folder,
      template_path = template_dest  # Use the copied template
    )
    
    cat("\nBloodstream pipeline completed successfully.\n")
    quit(status = 0)
    
  }, error = function(e) {
    cat("Error executing bloodstream pipeline:", e$message, "\n")
    quit(status = 3)
  })
}

# Clean exit
quit(status = 0)