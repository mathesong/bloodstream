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

#' Generate methods boilerplate text for manuscript reporting
#'
#' @param config The bloodstream configuration list
#' @param package_version The version of bloodstream used
#' @param selected_models A named list indicating which components used AIC-based model selection,
#'   with the selected model as the value (e.g., list(ParentFraction = "Hill"))
#' @return A character string containing the formatted methods text
#' @export
generate_methods_boilerplate <- function(config, package_version = NULL, selected_models = NULL) {

  # Get package version if not provided
  if (is.null(package_version)) {
    package_version <- utils::packageVersion("bloodstream")
  }

  # Helper function to describe models (without "Fit Individually:" prefix)
  describe_model_short <- function(method, component_config = NULL) {
    # Remove "Fit Individually: " or "Fit Hierarchically: " prefix if present
    method_clean <- sub("^Fit Individually: ", "", method)
    method_clean <- sub("^Fit Hierarchically: ", "", method_clean)

    switch(method_clean,
      "Interpolation" = "linear interpolation",
      "Choose the best-fitting model" = "best-fitting parametric model selection among Hill, exponential, power, sigmoid, inverse gamma, and gamma functions",
      "Hill" = "Hill model",
      "Exponential" = "exponential decay model",
      "Power" = "power function model",
      "Sigmoid" = "sigmoid model",
      "Inverse Gamma" = "inverse gamma model",
      "Gamma" = "gamma model",
      "GAM" = {
        k_val <- if (!is.null(component_config$gam_k)) paste0("k=", component_config$gam_k) else "k=6"
        paste0("generalized additive model (GAM) with ", k_val, " basis functions")
      },
      "HGAM" = "hierarchical generalized additive model (HGAM)",
      "Constant" = "constant model",
      "Linear" = "linear model",
      "Linear Rise, Triexponential Decay" = "triexponential decay with linear rise",
      "Feng" = "Feng model",
      "FengConv" = "Feng model with convolution",
      "Splines" = "spline-based modeling",
      method_clean  # fallback to cleaned method name
    )
  }

  # Helper function to check if method is interpolation
  is_interpolation <- function(method) {
    grepl("Interpolation", method, ignore.case = TRUE)
  }

  # Component names for readable output
  component_names <- list(
    ParentFraction = "parent fraction",
    BPR = "blood-to-plasma ratio",
    AIF = "arterial input function",
    WholeBlood = "whole blood"
  )

  # Build component descriptions
  components <- list(
    ParentFraction = list(
      config = config$Model$ParentFraction,
      method = config$Model$ParentFraction$Method,
      name = component_names$ParentFraction,
      selected = !is.null(selected_models$ParentFraction)
    ),
    BPR = list(
      config = config$Model$BPR,
      method = config$Model$BPR$Method,
      name = component_names$BPR,
      selected = !is.null(selected_models$BPR)
    ),
    AIF = list(
      config = config$Model$AIF,
      method = config$Model$AIF$Method,
      name = component_names$AIF,
      selected = !is.null(selected_models$AIF)
    ),
    WholeBlood = list(
      config = config$Model$WholeBlood,
      method = config$Model$WholeBlood$Method,
      name = component_names$WholeBlood,
      selected = !is.null(selected_models$WholeBlood)
    )
  )

  # Categorize components
  selected_comps <- list()
  modeled_comps <- list()
  interpolated_comps <- list()

  for (comp_name in names(components)) {
    comp <- components[[comp_name]]

    if (comp$selected) {
      selected_comps[[comp_name]] <- comp
    } else if (is_interpolation(comp$method)) {
      interpolated_comps[[comp_name]] <- comp
    } else {
      modeled_comps[[comp_name]] <- comp
    }
  }

  # Build the methods text
  processing_sentences <- c()

  # 1. Model selection components
  if (length(selected_comps) > 0) {
    for (comp_name in names(selected_comps)) {
      comp <- selected_comps[[comp_name]]
      selected_model <- selected_models[[comp_name]]
      model_desc <- describe_model_short(selected_model, comp$config)

      # Add special constraints/notes
      extra_note <- ""
      if (comp_name == "ParentFraction") {
        if (!is.null(comp$config$set_ppf0) && comp$config$set_ppf0) {
          extra_note <- " with the constraint that the parent fraction is equal to 1 at t=0"
        }
      } else if (comp_name == "WholeBlood") {
        if (!is.null(comp$config$dispcor) && comp$config$dispcor) {
          extra_note <- " with dispersion correction"
        }
      }

      sentence <- paste0("Model selection based on AIC was performed for ", comp$name,
                        ", and the ", model_desc, " was selected", extra_note, ".")
      processing_sentences <- c(processing_sentences, sentence)
    }
  }

  # 2. Directly modeled components
  if (length(modeled_comps) > 0) {
    for (comp_name in names(modeled_comps)) {
      comp <- modeled_comps[[comp_name]]
      model_desc <- describe_model_short(comp$method, comp$config)

      # Add special constraints/notes
      extra_note <- ""
      if (comp_name == "ParentFraction") {
        if (!is.null(comp$config$set_ppf0) && comp$config$set_ppf0) {
          extra_note <- " with the constraint that the parent fraction is equal to 1 at t=0"
        }
      } else if (comp_name == "WholeBlood") {
        if (!is.null(comp$config$dispcor) && comp$config$dispcor) {
          extra_note <- " with dispersion correction"
        }
      }

      # Use appropriate verb based on component
      verb <- if (comp_name == "BPR") "was estimated" else "was modeled"

      sentence <- paste0(stringr::str_to_sentence(comp$name), " ", verb,
                        " using ",
                        ifelse(grepl("^[aeiou]", model_desc), "an ", "a "),
                        model_desc, extra_note, ".")
      processing_sentences <- c(processing_sentences, sentence)
    }
  }

  # 3. Interpolated components
  if (length(interpolated_comps) > 0) {
    interp_names <- sapply(interpolated_comps, function(x) x$name)

    if (length(interp_names) == 1) {
      interp_text <- interp_names[1]
    } else if (length(interp_names) == 2) {
      interp_text <- paste(interp_names, collapse = " and ")
    } else {
      interp_text <- paste(paste(interp_names[-length(interp_names)], collapse = ", "),
                          "and", interp_names[length(interp_names)])
    }

    sentence <- paste0("Linear interpolation was used for the ", interp_text, ".")
    processing_sentences <- c(processing_sentences, sentence)
  }

  # Combine all sentences
  processing_text <- paste(processing_sentences, collapse = " ")

  # Generate the final boilerplate text
  methods_text <- paste0(
    "You can use the following text to describe the results of this analysis.\n\n",
    "**Blood data processing:** ",
    "Blood data preprocessing was performed using *bloodstream* ", package_version, ", ",
    "which is based on *kinfitr* (Matheson, 2019; Tjerkaski et al., 2020). ",
    processing_text, "\n\n",
    "### Copyright Waiver\n\n",
    "The above boilerplate text was automatically generated by bloodstream so that users can copy and paste this text into their manuscripts if they wish. It is released under the [CC0](https://creativecommons.org/publicdomain/zero/1.0/) license."
  )

  return(methods_text)
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

