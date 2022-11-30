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
    configpath <- system.file("extdata", "config.json", package="bloodstream")
  }

  studypath <- normalizePath(studypath, winslash = "/")
  configpath <- normalizePath(configpath, winslash = "/")

  configname <- stringr::str_remove(basename(configpath), ".json")

  if( !str_detect(configname, "^config") ) {
    stop("The name of the config file is required to start with 'config'")
  }

  config_suffix <- str_match(configname, "^config_?-?(.*)")[,2]

  dir.create(paste0(studypath, "/derivatives"))
  dir.create(paste0(studypath, "/derivatives/bloodstream", config_suffix))

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


  rmarkdown::render(
    input = paste0(system.file(package = "bloodstream"),
                   "/rmd/template.rmd"),
    output_file = paste0(studypath,
                         "/derivatives/bloodstream",
                         config_suffix, "/",
                         "bloodstream_report_config",
                         ifelse(stringr::str_length(config_suffix) > 0,
                                yes = "-", no = ""),
                         config_suffix, ".html"),
    params = list(configpath = configpath,
                          studypath = studypath),
    knit_root_dir = studypath
  )


}
