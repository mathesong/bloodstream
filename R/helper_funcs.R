#' Extract filterable attributes from a BIDS list
#'
#' This function extracts the attributes which could be used for filtering. By
#' this, it extracts all parts of the list which are either character or numeric
#' which also have a length of 1. This allows us to filter our data for a
#' specific tracer, or injection type.
#'
#' @param list The list of PET data or blood data
#'
#' @return A data.frame containing the filterable attributes
#' @export
get_filterable_attributes <- function(list) {

  lengths <- purrr::map_dbl(list, length) == 1
  types <- purrr::map_dbl(list, ~is.character(.x)  || is.numeric(.x))
  keep <- lengths * types

  outlist <- list[which(keep==1)]

  outlist <- outlist[which(names(outlist) %in% c("TracerName",
                        "ModeOfAdministration",
                        "InstitutionName",
                        "PharmaceuticalName"))]

  tibble::as_tibble(outlist)


}

#' @export
extract_extra_attributes <- function(bidsdata) {

  petinfoextract <- function(petinfo, detail) petinfo[[detail]]

  safely_extract <- purrr::possibly(.f = petinfoextract, otherwise = "")

  bidsdata$TracerName = purrr::map_chr(bidsdata$petinfo,
                                       safely_extract,
                                       detail="TracerName")
  bidsdata$ModeOfAdministration = purrr::map_chr(bidsdata$petinfo,
                                                 safely_extract,
                                                 detail="ModeOfAdministration")
  bidsdata$InstitutionName = purrr::map_chr(bidsdata$petinfo,
                                            safely_extract,
                                            detail="InstitutionName")
  bidsdata$PharmaceuticalName = purrr::map_chr(bidsdata$petinfo,
                                               safely_extract,
                                               detail="PharmaceuticalName")

}

#' @export
get_petname <- function(filedata) {

  petname <- filedata %>%
    dplyr::filter(measurement == "blood") %>%
    dplyr::slice(1)

  petname <- basename(petname$path)
  stringr::str_remove(petname,
                                 "_recording.*")

}

#' @export
attributes_to_title <- function(bidsdata, all_attributes = FALSE) {


  if( !all_attributes ) {
    if(nrow(bidsdata) > 1) {
      # More than one PET measurement
      bidsdata <- bidsdata[,which(!apply(bidsdata, 2,
                                         FUN = function(x) length(unique(x))==1))]
    } else {
      # Situation if only one PET
      bidsdata <- dplyr::select(bidsdata, sub, ses, task, filedata)
    }
  }

  cnames <- colnames(bidsdata)

  filedata_colno <- which(cnames=="filedata")

  cname_attributes <- cnames[1:(filedata_colno-1)]
  attributes <- bidsdata[1:(filedata_colno-1)]

  # i for rows --> attributes
  # j for columns --> measurements

  title <- rep("", times=nrow(attributes))

  for(j in 1:nrow(attributes)) {
    for(i in 1:length(cname_attributes)) {
      title[j] <- paste0(title[j], cname_attributes[i], "-", attributes[j,i], "_")
    }
  }

  stringr::str_remove(title, "_$")

}

#' @export
fitted_values_nonzerotime <- function(gamfit, data, zeroval = 1) {

  data_zero <- data %>%
    dplyr::filter(time == 0)

  data_nonzero <- data %>%
    dplyr::filter(time > 0)

  nonzero_preds <- gratia::fitted_values(gamfit, data_nonzero)

  zero_preds <- nonzero_preds %>%
    dplyr::filter(time == min(time)) %>%
    dplyr::mutate(time = 0) %>%
    dplyr::mutate(.row = 0)

  preds <- dplyr::bind_rows(zero_preds, nonzero_preds) %>%
    dplyr::arrange(time)

  return(preds)

}

