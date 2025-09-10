#' Run the bloodstream pipeline
#'
#' @param bids_dir The path to the BIDS study folder.
#' @param configpath The path to the config file.
#' @param derivatives_dir The path to the derivatives directory. If NULL, uses bids_dir/derivatives.
#' @param analysis_foldername The name for the analysis subfolder (default: "Primary_Analysis").
#' @param template_path The path to the R Markdown template. If NULL, uses package default.
#'
#' @return The derivatives files, and report will be produced in the study folder.
#' @export
#'
#' @examples
#' \dontrun{
#' bloodstream(bids_dir, configpath)
#' bloodstream(bids_dir, configpath, analysis_foldername = "my_analysis")
#' }
bloodstream <- function(bids_dir, configpath = NULL, derivatives_dir = NULL, analysis_foldername = "Primary_Analysis", template_path = NULL) {


  # Validation
  if( is.null(bids_dir) || !dir.exists(bids_dir) ) {
    stop("bids_dir must be provided and must exist", call. = FALSE)
  }
  
  if( is.null(configpath) ) {
    configpath <- system.file("extdata", "config.json", package="bloodstream")
  }
  
  if( !file.exists(configpath) ) {
    stop("Config file does not exist: ", configpath, call. = FALSE)
  }

  bids_dir <- normalizePath(bids_dir, winslash = "/")
  configpath <- normalizePath(configpath, winslash = "/")

  # Set up derivatives directory
  if( is.null(derivatives_dir) ) {
    derivatives_dir <- file.path(bids_dir, "derivatives")
  }
  derivatives_dir <- normalizePath(derivatives_dir, winslash = "/", mustWork = FALSE)

  # Create directories
  dir.create(derivatives_dir, showWarnings = FALSE, recursive = TRUE)
  bloodstream_dir <- file.path(derivatives_dir, "bloodstream")
  dir.create(bloodstream_dir, showWarnings = FALSE)
  
  # Create analysis folder
  analysis_path <- file.path(bloodstream_dir, analysis_foldername)
  dir.create(analysis_path, showWarnings = FALSE)

  # Clean up all existing files in analysis folder (except config JSON files)
  if (dir.exists(analysis_path)) {
    existing_files <- list.files(analysis_path, full.names = TRUE, recursive = FALSE)
    # Keep only files ending with _config.json
    files_to_remove <- existing_files[!grepl("_config\\.json$", existing_files, ignore.case = TRUE)]
    
    if (length(files_to_remove) > 0) {
      cat("Cleaning up", length(files_to_remove), "files from analysis folder before starting...\n")
      for (temp_file in files_to_remove) {
        if (file.exists(temp_file)) {
          if (file.info(temp_file)$isdir) {
            unlink(temp_file, recursive = TRUE)
          } else {
            file.remove(temp_file)
          }
        }
      }
    }
  }

  # Copy config file to analysis directory for reproducibility (before processing starts)
  config_dest <- file.path(analysis_path, "bloodstream_config.json")
  file.copy(configpath, config_dest, overwrite = TRUE)

  # Determine template path
  if( is.null(template_path) ) {
    template_path <- paste0(system.file(package = "bloodstream"), "/qmd/template.qmd")
  }
  
  # Copy template to analysis directory and render there
  template_dest <- file.path(analysis_path, "bloodstream_report.qmd")
  file.copy(template_path, template_dest, overwrite = TRUE)
  
  output_filename <- "bloodstream_report.html"
  
  tryCatch({
    quarto::quarto_render(
      input = template_dest,
      output_file = output_filename,
      execute_params = list(configpath = configpath,
                           studypath = bids_dir,
                           derivatives_dir = derivatives_dir,
                           analysis_foldername = analysis_foldername),
      execute_dir = analysis_path
    )
    
    # Clean up temporary files after successful completion
    temp_files_to_remove <- c(
      template_dest,  # This is now bloodstream_report.qmd
      file.path(analysis_path, "bloodstream_report.rmarkdown")
    )
    
    for (temp_file in temp_files_to_remove) {
      if (file.exists(temp_file)) {
        cat("Removing temporary file:", temp_file, "\n")
        file.remove(temp_file)
      }
    }
    
  }, error = function(e) {
    # Clean up temporary files even on error
    temp_files_to_remove <- c(
      template_dest,  # This is now bloodstream_report.qmd
      file.path(analysis_path, "bloodstream_report.rmarkdown")
    )
    
    for (temp_file in temp_files_to_remove) {
      if (file.exists(temp_file)) {
        file.remove(temp_file)
      }
    }
    stop(e)
  })


}
