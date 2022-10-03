#' @export
parse_config_subsets <- function(config) {

  # Remove whitespace
  sub <- stringr::str_remove_all(config$Subsets$sub, " ")
  ses <- stringr::str_remove_all(config$Subsets$ses, " ")
  rec <- stringr::str_remove_all(config$Subsets$rec, " ")
  task <- stringr::str_remove_all(config$Subsets$task, " ")
  run <- stringr::str_remove_all(config$Subsets$run, " ")
  TracerName <- stringr::str_remove_all(config$Subsets$TracerName, " ")
  ModeOfAdministration <- stringr::str_remove_all(config$Subsets$ModeOfAdministration, " ")
  InstitutionName <- stringr::str_remove_all(config$Subsets$InstitutionName, " ")
  PharmaceuticalName <- stringr::str_remove_all(config$Subsets$PharmaceuticalName, " ")

  sub <-  str_split(sub, ";")[[1]]
  ses <-  str_split(ses, ";")[[1]]
  rec <-  str_split(rec, ";")[[1]]
  task <- str_split(task, ";")[[1]]
  run <-  str_split(run, ";")[[1]]
  TracerName <- str_split(TracerName, ";")[[1]]
  ModeOfAdministration <- str_split(ModeOfAdministration, ";")[[1]]
  InstitutionName <- str_split(InstitutionName, ";")[[1]]
  PharmaceuticalName <- str_split(PharmaceuticalName, ";")[[1]]

  all_tibble <- tibble::as_tibble(
    expand.grid(sub = sub,
              ses = ses,
              rec = rec,
              task = task,
              run = run,
              TracerName = TracerName,
              ModeOfAdministration = ModeOfAdministration,
              InstitutionName = InstitutionName,
              PharmaceuticalName = PharmaceuticalName)) %>%
    dplyr::mutate(across(where(is.factor), as.character))

  clean_tibble <- all_tibble[,!apply(all_tibble, 2, function(x) (all(x=="")))]

}

#' @export
all_identifiers_to_character <- function(bidsdata) {

  cnames <- colnames(bidsdata)
  filedata_colno <- which(cnames=="filedata")

  bidsdata %>%
    mutate(across(1:(filedata_colno-1), as.character))

}
