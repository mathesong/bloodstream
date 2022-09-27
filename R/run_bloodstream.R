#' Run the bloodstream pipeline
#'
#' @param studypath The path to the BIDS study folder.
#' @param configpath The path to the config file.
#'
#' @return The derivatives files, and report will be produced in the study folder.
#' @export
#'
#' @examples
#' \dontrun{
#' bloodstream(studypath, configpath)
#' }
bloodstream <- function(studypath, configpath = NULL) {

  if( is.null(configpath) ) {
    configpath <- system.file("extdata", "config_default.json", package="bloodstream")
  }

  studypath <- normalizePath(studypath, winslash = "/")
  configpath <- normalizePath(configpath, winslash = "/")

  configname <- stringr::str_remove(basename(configpath), ".json")

  if(stringr::str_detect(configname, pattern = "^config_")) {
    configname <- stringr::str_remove(configname, "^config_")
  }

  templatepath <- system.file("extdata", "config_default.json", package="bloodstream")

  # quarto::quarto_render(
  #   input = paste0(system.file(package = "bloodstream"),
  #                  "/qmd/template.qmd"),
  #   output_file = paste0(studypath,
  #                        "/derivatives/bloodstream/",
  #                        "bloodstream_report_config-",
  #                        configname, ".html"),
  #   execute_params = list(configpath = configpath,
  #                         studypath = studypath),
  #   execute_dir = studypath
  # )


  rmarkdown::render(
    input = paste0(system.file(package = "bloodstream"),
                   "/rmd/template.Rmd"),
    output_file = paste0(studypath,
                         "/derivatives/bloodstream/",
                         "bloodstream_report_config-",
                         configname, ".html"),
    params = list(configpath = configpath,
                          studypath = studypath),
    knit_root_dir = studypath
  )


}
