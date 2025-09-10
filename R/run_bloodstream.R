#' Run the bloodstream pipeline
#'
#' @param studypath The path to the BIDS study folder.
#' @param configpath The path to the config file.
#' @param derivatives_dir The path to the derivatives directory. If NULL, uses studypath/derivatives.
#' @param analysis_foldername The name for the analysis subfolder (default: "Primary_Analysis").
#' @param template_path The path to the R Markdown template. If NULL, uses package default.
#'
#' @return The derivatives files, and report will be produced in the study folder.
#' @export
#'
#' @examples
#' \dontrun{
#' bloodstream(studypath, configpath)
#' bloodstream(studypath, configpath, analysis_foldername = "my_analysis")
#' }
bloodstream <- function(studypath, configpath = NULL, derivatives_dir = NULL, analysis_foldername = "Primary_Analysis", template_path = NULL) {

  # Validation
  if( is.null(studypath) || !dir.exists(studypath) ) {
    stop("studypath must be provided and must exist", call. = FALSE)
  }
  
  if( is.null(configpath) ) {
    configpath <- system.file("extdata", "config.json", package="bloodstream")
  }
  
  if( !file.exists(configpath) ) {
    stop("Config file does not exist: ", configpath, call. = FALSE)
  }

  studypath <- normalizePath(studypath, winslash = "/")
  configpath <- normalizePath(configpath, winslash = "/")

  # Set up derivatives directory
  if( is.null(derivatives_dir) ) {
    derivatives_dir <- file.path(studypath, "derivatives")
  }
  derivatives_dir <- normalizePath(derivatives_dir, winslash = "/", mustWork = FALSE)

  # Create directories
  dir.create(derivatives_dir, showWarnings = FALSE, recursive = TRUE)
  bloodstream_dir <- file.path(derivatives_dir, "bloodstream")
  dir.create(bloodstream_dir, showWarnings = FALSE)
  
  # Create analysis folder
  analysis_path <- file.path(bloodstream_dir, analysis_foldername)
  dir.create(analysis_path, showWarnings = FALSE)

  # quarto::quarto_render(
  #   input = paste0(system.file(package = "bloodstream"),
  #                  "/qmd/template.qmd"),
  #   output_file = paste0(studypath,
  #                        "/derivatives/bloodstream",
  #                        config_suffix, "/",
  #                        "bloodstream_report_config-",
  #                        configname, ".html"),
  #   execute_params = list(configpath = configpath,
  #                         studypath = studypath),
  #   execute_dir = studypath
  # )


  # Determine template path
  if( is.null(template_path) ) {
    template_path <- paste0(system.file(package = "bloodstream"), "/rmd/template.rmd")
  }
  
  rmarkdown::render(
    input = template_path,
    output_file = file.path(analysis_path, 
                           paste0("bloodstream_report_", analysis_foldername, ".html")),
    params = list(configpath = configpath,
                          studypath = studypath),
    knit_root_dir = studypath
  )


}
