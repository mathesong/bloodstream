#!/usr/bin/env Rscript

# Container entry script for bloodstream apps (Docker and Apptainer)
# Supports both interactive and non-interactive modes with flexible directory mounting

library(optparse)

# Define command line options
option_list <- list(
  make_option(c("--mode"), type="character", default="non-interactive",
              help="Execution mode: 'interactive' or 'non-interactive' [default: non-interactive]"),
  make_option(c("--config"), type="character", default=NULL,
              help="Path to config file [optional]"),
  make_option(c("--analysis_foldername"), type="character", default=NULL,
              help="Name for analysis subfolder [optional - defaults to config filename]"),
  make_option(c("--bids_dir"), type="character", default=NULL,
              help="Explicit BIDS directory path inside container (optional; useful with Apptainer home auto-mounts)"),
  make_option(c("--derivatives_dir"), type="character", default=NULL,
              help="Explicit derivatives directory path inside container (optional; useful with Apptainer home auto-mounts)")
)

# Parse arguments
opt_parser <- OptionParser(option_list=option_list, 
                          description="Container entry point for bloodstream apps")
opt <- parse_args(opt_parser)

# Validate arguments
if (!opt$mode %in% c("interactive", "non-interactive")) {
  stop("--mode must be 'interactive' or 'non-interactive'", call.=FALSE)
}

cat("=== bloodstream Container ===\n")
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
  # Prefer explicit paths when provided, otherwise fall back to the conventional
  # bind mount locations used by the wrapper and the documented container calls.
  bids_candidate <- if (is.null(opt$bids_dir)) "/data/bids_dir" else opt$bids_dir
  derivatives_candidate <- if (is.null(opt$derivatives_dir)) "/data/derivatives_dir" else opt$derivatives_dir

  bids_available <- dir.exists(bids_candidate)
  derivatives_available <- dir.exists(derivatives_candidate)

  cat("=== Directory Detection ===\n")
  cat("BIDS directory available:", bids_available, "\n")
  cat("Derivatives directory available:", derivatives_available, "\n")
  if (!is.null(opt$bids_dir)) {
    cat("BIDS explicit path:", bids_candidate, "\n")
  }
  if (!is.null(opt$derivatives_dir)) {
    cat("Derivatives explicit path:", derivatives_candidate, "\n")
  }
  cat("\n")

  # For interactive mode:
  #   - Standalone config creation: no directories required
  #   - With pipeline execution: both bids_dir and derivatives_dir required
  # For non-interactive mode: both bids_dir and derivatives_dir required
  if (opt$mode == "interactive") {
    # If bids_dir is provided, derivatives_dir is required for pipeline execution
    if (bids_available && !derivatives_available) {
      stop(paste0("Interactive mode with BIDS directory requires derivatives_dir for pipeline execution. Mount at ", derivatives_candidate, " with read-write access."), call.=FALSE)
    }
  } else {
    if (!bids_available) {
      stop(paste0("Non-interactive mode requires bids_dir to be available at ", bids_candidate), call.=FALSE)
    }
    if (!derivatives_available) {
      stop(paste0("Non-interactive mode requires derivatives_dir to be available with read-write access at ", derivatives_candidate), call.=FALSE)
    }
  }

  # Check that derivatives_dir is writable (Docker creates root-owned dirs for
  # non-existent host paths, which causes permission errors later)
  if (derivatives_available && file.access(derivatives_candidate, mode = 2) != 0) {
    stop(paste0(
      "The derivatives directory at ", derivatives_candidate, " is not writable.\n",
      "This usually happens when the host directory does not exist before mounting.\n",
      "Docker creates missing mount paths as root, making them unwritable.\n\n",
      "To fix this, create the directory on the host before running the container:\n\n",
      "  mkdir -p /path/to/derivatives\n",
      "  docker run ... -v /path/to/derivatives:/data/derivatives_dir:rw ...\n"
    ), call.=FALSE)
  }

  # Set directory paths based on what's available
  bids_dir <- if(bids_available) bids_candidate else NULL
  derivatives_dir <- if(derivatives_available) derivatives_candidate else NULL

  return(list(
    bids_dir = bids_dir,
    derivatives_dir = derivatives_dir
  ))
}

# Determine an available localhost port near the preferred one.
is_port_available <- function(port) {
  con <- suppressWarnings(
    tryCatch(
      socketConnection(host = "127.0.0.1", port = port, open = "r+", blocking = TRUE, timeout = 0.2),
      error = function(e) NULL
    )
  )

  if (is.null(con)) {
    return(TRUE)
  }

  close(con)
  FALSE
}

find_open_port <- function(start_port = 3838L, max_offset = 20L) {
  for (offset in seq.int(0L, max_offset)) {
    candidate <- start_port + offset
    if (is_port_available(candidate)) {
      return(candidate)
    }
  }

  stop(
    "Could not find an open port between ", start_port, " and ", start_port + max_offset,
    call. = FALSE
  )
}

# Patch: reinstall bloodstream from a mounted local checkout, if present.
# The wrapper's --patch option bind-mounts a host bloodstream source tree to
# /patch/bloodstream. We reinstall it into a user-writable library (prepended to
# .libPaths) so the non-root container user can overwrite the baked-in package
# and library(bloodstream) below loads the patched copy.
patch_dir <- "/patch/bloodstream"
if (dir.exists(patch_dir)) {
  cat("=== Patch detected ===\n")
  cat("Reinstalling bloodstream from mounted source:", patch_dir, "\n")
  patch_lib <- file.path(tempdir(), "bloodstream_patchlib")
  dir.create(patch_lib, showWarnings = FALSE, recursive = TRUE)
  .libPaths(c(patch_lib, .libPaths()))
  devtools::install(
    patch_dir,
    dependencies = FALSE,   # dependencies are already installed in the image
    upgrade = FALSE,        # never upgrade deps
    quick = TRUE,           # skip vignette/manual rebuild for faster startup
    quiet = FALSE
  )
  cat("\n")
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
  # rocker/shiny images can carry Shiny Server environment variables. When
  # launched through runApp(), Shiny may try to parse these and fail if the
  # value is not a plain version string.
  Sys.unsetenv("SHINY_SERVER_VERSION")

  requested_port_value <- Sys.getenv("BLOODSTREAM_SHINY_PORT", unset = NA_character_)
  if (is.na(requested_port_value) || requested_port_value == "") {
    requested_port_value <- Sys.getenv("SHINY_PORT", unset = "3838")
  }
  Sys.unsetenv("SHINY_PORT")

  requested_port <- suppressWarnings(as.integer(requested_port_value))
  if (is.na(requested_port) || requested_port < 1L || requested_port > 65535L) {
    requested_port <- 3838L
  }
  selected_port <- find_open_port(requested_port)
  if (selected_port != requested_port) {
    cat("Requested Shiny port", requested_port, "is in use. Using", selected_port, "instead.\n")
  }
  Sys.setenv(BLOODSTREAM_SHINY_PORT = as.character(selected_port))

  cat("=== Starting Interactive Mode ===\n")
  cat("Shiny app will be available at http://localhost:", selected_port, "\n", sep = "")
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
  cat("Attempting to launch Shiny app...\n")
  tryCatch({
    bloodstream_interactive(
      bids_dir = dirs$bids_dir,
      derivatives_dir = dirs$derivatives_dir,
      configpath = config_for_app,
      analysis_foldername = analysis_folder,
      host = "0.0.0.0",  # Important for Docker
      port = selected_port
    )
  }, error = function(e) {
    cat("ERROR launching Shiny app:", e$message, "\n")
    cat("Full error:\n")
    print(e)
    stop("Shiny app failed to launch")
  })
  
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
    config_archive <- file.path(analysis_path, basename(config_source))
    file.copy(config_source, config_archive, overwrite = TRUE)
    cat("Saved config file to:", config_archive, "\n")
    
    # Also copy to a short path for execution (avoids path truncation issue)
    config_to_use <- "/tmp/config.json"
    file.copy(config_source, config_to_use, overwrite = TRUE)
  } else {
    cat("Using default config from package\n")
  }
  
  # Execute bloodstream pipeline
  tryCatch({
    
    # Create a temporary directory for Quarto template processing
    # This is crucial for Docker permission handling
    temp_dir <- file.path(tempdir(), "temp_qmd")
    dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)
    
    # Copy the Quarto template to the writable temp directory
    template_source <- system.file("qmd", "template.qmd", package = "bloodstream")
    template_dest <- file.path(temp_dir, "template.qmd")
    file.copy(template_source, template_dest, overwrite = TRUE)
    
    # Run bloodstream using the updated function with custom template location
    result <- bloodstream(
      bids_dir = bids_path, 
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
