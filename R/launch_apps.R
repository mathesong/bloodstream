#' Launch bloodstream configuration app
#'
#' @description Launch the bloodstream configuration interface
#'
#' @param bids_dir Character string path to the BIDS directory (default: NULL)
#' @param derivatives_dir Character string path to the derivatives directory (default: NULL)
#' @param config_file Character string path to existing config file to load (default: NULL)
#' @param analysis_folder Character string name for analysis subfolder (default: "default")
#' @param host Character string host address for the Shiny server (default: "127.0.0.1")  
#' @param port Integer port number for the Shiny server (default: 3838)
#' 
#' @details 
#' This function launches the bloodstream configuration app, which allows users to:
#' - Create configuration files for bloodstream analysis
#' - Define data subsets and modelling approaches
#' - Load existing configurations from file
#' - Optionally run the bloodstream pipeline directly from the interface
#' 
#' @export
launch_bloodstream_app <- function(bids_dir = NULL, derivatives_dir = NULL, config_file = NULL, analysis_folder = "default", host = "127.0.0.1", port = 3838) {
  
  # Print configuration
  cat("Launching bloodstream app with configuration:\n")
  if (!is.null(bids_dir)) {
    cat("  BIDS directory:", bids_dir, "\n")
  }
  if (!is.null(derivatives_dir)) {
    cat("  Derivatives directory:", derivatives_dir, "\n")
  }
  if (!is.null(config_file)) {
    cat("  Config file:", config_file, "\n")
  }
  cat("  Analysis folder:", analysis_folder, "\n")
  cat("  Host:", host, "\n")
  cat("  Port:", port, "\n")
  cat("\n")
  
  # Launch the config app
  bloodstream_config_app(
    bids_dir = bids_dir, 
    derivatives_dir = derivatives_dir,
    config_file = config_file,
    analysis_folder = analysis_folder,
    host = host, 
    port = port
  )
}