# Values in a subsetting field are separated by ";". A comma is always a
# mistyped separator, and treating "A, B" as one value silently narrows an
# analysis to whatever else matched -- which looks like a successful run on
# less data. Caught before anything is consulted.
check_no_commas <- function(values, field = NULL) {

  values <- as.character(values)
  values <- values[!is.na(values)]

  offenders <- values[stringr::str_detect(values, stringr::fixed(","))]
  if (length(offenders) == 0) {
    return(invisible(TRUE))
  }

  suggestions <- vapply(offenders, function(v) {
    parts <- stringr::str_trim(stringr::str_split(v, ",")[[1]])
    paste(parts[nzchar(parts)], collapse = "; ")
  }, character(1), USE.NAMES = FALSE)

  stop(field, ": subsetting values are separated by \";\" and may not contain ",
       "commas.\n",
       paste0("  Offending value: \"", offenders, "\"\n",
              "  Did you mean:    \"", suggestions, "\"?",
              collapse = "\n"),
       call. = FALSE)
}

# Split one subsetting field into its values, reading a leading "-" as
# "everything except these". The prefix applies to the whole field, so a field
# is either an inclusion or an exclusion and never a mixture; each field reads
# its own prefix.
parse_subset_field <- function(raw, field) {

  value <- stringr::str_remove_all(as.character(raw), " ")
  if (length(value) == 0 || is.na(value[1]) || !nzchar(value[1])) {
    return(list(values = character(0), negate = FALSE))
  }
  value <- value[1]

  negate <- stringr::str_starts(value, stringr::fixed("-"))
  if (negate) {
    value <- stringr::str_sub(value, 2)
  }

  values <- stringr::str_split(value, ";")[[1]]
  values <- values[nzchar(values)]

  if (length(values) == 0) {
    if (negate) {
      warning(field, ": \"-\" on its own excludes nothing; no filter applied.",
              call. = FALSE)
    }
    return(list(values = character(0), negate = FALSE))
  }

  check_no_commas(values, field)

  list(values = values, negate = negate)
}

#' Parse the subsetting fields of a bloodstream configuration
#'
#' @description Reads the `Subsets` block of a configuration into the grid of
#'   attribute combinations to keep.
#'
#'   Values within a field are separated by `;`. A field whose value begins
#'   with `-` **excludes** those values rather than selecting them, so
#'   `-test;retest` keeps every session except those two. The prefix applies to
#'   the whole field. Exclusions are returned separately, on the `exclusions`
#'   attribute of the result, since they cannot be expressed as rows to join
#'   against.
#'
#' @param config A parsed bloodstream configuration.
#'
#' @return A tibble of attribute combinations to keep, one column per field
#'   that was specified positively. Fields specified as exclusions are carried
#'   on the `exclusions` attribute as a named list of character vectors.
#'
#' @export
parse_config_subsets <- function(config) {

  fields <- c("sub", "ses", "rec", "task", "run", "TracerName",
              "ModeOfAdministration", "InstitutionName", "PharmaceuticalName")

  parsed <- lapply(fields, function(f) parse_subset_field(config$Subsets[[f]], f))
  names(parsed) <- fields

  negated <- vapply(parsed, function(p) p$negate, logical(1))

  # Positive fields become the grid of combinations to join against, exactly as
  # before. A field with nothing specified contributes "" so that it drops out
  # below, preserving the original behaviour.
  included <- lapply(parsed[!negated], function(p) {
    if (length(p$values) == 0) "" else p$values
  })

  all_tibble <- tibble::as_tibble(expand.grid(included,
                                              stringsAsFactors = FALSE))

  clean_tibble <- all_tibble[, !apply(all_tibble, 2,
                                      function(x) all(x == "")), drop = FALSE]

  # Exclusions cannot be rows in that grid -- "not this value" is not a value --
  # so they travel alongside it and are applied as a filter.
  exclusions <- lapply(parsed[negated], function(p) p$values)
  exclusions <- exclusions[lengths(exclusions) > 0]
  attr(clean_tibble, "exclusions") <- exclusions

  clean_tibble
}

#' Apply parsed subsetting to a table of measurements
#'
#' @description Keeps the measurements matching the inclusion grid and drops
#'   those matching any exclusion.
#'
#'   Note the asymmetry around absent attributes: including `ses = "test"`
#'   drops measurements with no session at all, whereas excluding
#'   `ses = "-test"` keeps them, since a measurement with no session is indeed
#'   not `ses-test`.
#'
#' @param measurements A tibble of measurements.
#' @param config_subset The result of [parse_config_subsets()].
#'
#' @return `measurements`, filtered.
#'
#' @export
apply_config_subsets <- function(measurements, config_subset) {

  exclusions <- attr(config_subset, "exclusions") %||% list()

  # An attribute named in the configuration but absent from the data must say
  # so here: the parser no longer invents entities, so the join below would
  # otherwise fail with nothing useful to say.
  named <- c(colnames(config_subset), names(exclusions))
  missing <- setdiff(named, colnames(measurements))
  if (length(missing) > 0) {
    stop("The config subsets on attributes not present in this dataset: ",
         paste(missing, collapse = ", "),
         ". No filename carries the entity, or no PET sidecar carries the field.",
         call. = FALSE)
  }

  if (ncol(config_subset) > 0) {
    measurements <- dplyr::inner_join(measurements, config_subset,
                                      by = colnames(config_subset))
  }

  for (field in names(exclusions)) {

    values <- exclusions[[field]]
    present <- as.character(measurements[[field]])

    unmatched <- setdiff(values, stats::na.omit(unique(present)))
    if (length(unmatched) > 0) {
      # A warning, not an error: nothing was removed that should have been, so
      # the analysis is complete rather than wrong -- but you did not exclude
      # what you thought you had.
      warning(field, ": excluded value matches nothing in the data, so ",
              "nothing was excluded for it:\n    ",
              paste0("\"", unmatched, "\"", collapse = ", "),
              call. = FALSE)
    }

    # NA is kept: a measurement with no session is not "ses-test"
    measurements <- measurements[!(present %in% values), , drop = FALSE]
  }

  measurements
}

#' @export
all_identifiers_to_character <- function(bidsdata) {

  cnames <- colnames(bidsdata)
  filedata_colno <- which(cnames=="filedata")

  bidsdata %>%
    mutate(across(1:(filedata_colno-1), as.character))

}
