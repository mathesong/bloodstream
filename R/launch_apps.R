#' Launch bloodstream configuration app
#'
#' @description Launch the bloodstream configuration interface
#'
#' @param studypath Character string path to the BIDS study directory (default: NULL). If provided without derivatives_dir, derivatives will be set to studypath/derivatives.
#' @param bids_dir Character string path to the BIDS directory (default: NULL). Alternative to studypath for Docker compatibility.
#' @param derivatives_dir Character string path to the derivatives directory (default: NULL)
#' @param config_file Character string path to existing config file to load (default: NULL)
#' @param analysis_foldername Character string name for analysis subfolder (default: "Primary_Analysis")
#' @param host Character string host address for the Shiny server (default: "127.0.0.1")  
#' @param port Integer port number for the Shiny server (default: 3838)
#' 
#' @details 
#' This function launches the bloodstream configuration app, which allows users to:
#' - Create configuration files for bloodstream analysis (can run standalone without any directories)
#' - Define data subsets and modelling approaches
#' - Load existing configurations from file
#' - Run the bloodstream pipeline directly from the interface (when BIDS directory is available)
#' 
#' Usage modes:
#' - Standalone config creation: launch_bloodstream_app()
#' - With study directory: launch_bloodstream_app(studypath = "/path/to/study")
#' - With separate directories: launch_bloodstream_app(bids_dir = "/path/to/bids", derivatives_dir = "/path/to/derivatives")
#' 
#' @export
launch_bloodstream_app <- function(studypath = NULL, bids_dir = NULL, derivatives_dir = NULL, config_file = NULL, analysis_foldername = "Primary_Analysis", host = "127.0.0.1", port = 3838) {
  
  # Handle parameter compatibility and derive paths
  if (!is.null(studypath)) {
    if (is.null(bids_dir)) {
      bids_dir <- studypath
    }
    if (is.null(derivatives_dir)) {
      derivatives_dir <- file.path(studypath, "derivatives")
    }
  }
  
  # Print configuration
  cat("Launching bloodstream app with configuration:\n")
  if (!is.null(bids_dir)) {
    cat("  BIDS directory:", bids_dir, "\n")
  } else {
    cat("  BIDS directory: NULL (standalone config mode)\n")
  }
  if (!is.null(derivatives_dir)) {
    cat("  Derivatives directory:", derivatives_dir, "\n")
  }
  if (!is.null(config_file)) {
    cat("  Config file:", config_file, "\n")
  }
  cat("  Analysis foldername:", analysis_foldername, "\n")
  cat("  Host:", host, "\n")
  cat("  Port:", port, "\n")
  cat("\n")
  
  # Launch the config app
  bloodstream_config_app(
    bids_dir = bids_dir, 
    derivatives_dir = derivatives_dir,
    config_file = config_file,
    analysis_folder = analysis_foldername,
    host = host, 
    port = port
  )
}