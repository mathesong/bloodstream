# Some tracers are scanned in two blocks from a single injection: an early
# run-01 and a late run-02, or run-early and run-late. Those two runs share one
# blood curve, and so belong in one bloodstream output which is fitted to the
# samples from both. Other studies use runs for separate injections, where
# combining them would be wrong. Nothing in the data distinguishes the two
# cases reliably, so it is a configuration choice: MergeRuns.
#
# BIDS gives blood sample times relative to the TimeZero of their own
# acquisition. Runs which share a TimeZero are therefore already on one clock,
# and runs which each define their own start again from zero. The offset
# between two runs is the difference between their TimeZero clock times, and
# that is what is applied to the later run's samples here.

# Seconds since midnight for a BIDS TimeZero, or NA when the field carries no
# clock time. A dataset which sets TimeZero to "0" is timing from its own scan
# start rather than from the clock, and so cannot be aligned this way.
bids_clocktime_seconds <- function(x) {

  if (is.null(x) || length(x) == 0) {
    return(NA_real_)
  }

  x <- stringr::str_trim(as.character(x)[1])
  if (is.na(x)) {
    return(NA_real_)
  }

  parts <- stringr::str_match(x, "^(\\d{1,2}):(\\d{2})(?::(\\d{2}(?:\\.\\d+)?))?$")
  if (is.na(parts[1, 1])) {
    return(NA_real_)
  }

  hours <- as.numeric(parts[1, 2])
  minutes <- as.numeric(parts[1, 3])
  seconds <- if (is.na(parts[1, 4])) 0 else as.numeric(parts[1, 4])

  if (hours > 23 || minutes > 59 || seconds >= 60) {
    return(NA_real_)
  }

  hours * 3600 + minutes * 60 + seconds
}

# The offset to add to each run's sample times, in seconds, so that they all
# refer to the first run's TimeZero. NULL when any run lacks a usable
# TimeZero: the caller then treats the times as already sharing a clock, which
# is what a dataset timing every run from one injection looks like.
run_time_offsets <- function(petinfo) {

  clock <- vapply(petinfo, function(p) {
    if (!is.list(p)) return(NA_real_)
    bids_clocktime_seconds(p$TimeZero)
  }, numeric(1))

  if (length(clock) == 0 || any(is.na(clock))) {
    return(NULL)
  }

  # Runs are taken in the order they appear, which is the order of their run
  # labels. A session running past midnight gives a later run the smaller
  # clock time, so the sequence is unwrapped here rather than read as the
  # later run having come first.
  for (i in seq_along(clock)[-1]) {
    while (clock[i] < clock[i - 1]) {
      clock[i] <- clock[i] + 86400
    }
  }

  clock - clock[1]
}

# Name a measurement by its attributes, for use in messages: the BIDS
# entities it carries, in the style of the filenames they came from.
describe_attributes <- function(attributes) {

  attributes <- as.list(attributes)
  attributes <- attributes[!vapply(attributes, function(x) {
    length(x) == 0 || is.na(x[1]) || !nzchar(as.character(x[1]))
  }, logical(1))]

  if (length(attributes) == 0) {
    return("this measurement")
  }

  paste(paste0(names(attributes), "-", unlist(attributes)), collapse = "_")
}

# Shift one set of sample values in time, and keep them in time order.
shift_blood_values <- function(values, offset) {

  if (is.null(values) || nrow(values) == 0) {
    return(values)
  }

  values$time <- values$time + offset
  values[order(values$time), , drop = FALSE]
}

# Combine one node of the Data section -- the discrete samples, the plasma, the
# metabolite -- across runs. The first run supplies the descriptions and units,
# which the parser has already normalised, so only the Values need combining.
merge_blood_node <- function(nodes, offsets, what) {

  values <- purrr::map2(purrr::map(nodes, "Values"), offsets, shift_blood_values)
  values <- dplyr::bind_rows(values)
  values <- values[order(values$time), , drop = FALSE]

  duplicates <- duplicated(values$time)
  if (any(duplicates)) {
    # Two samples at one time make an unusable curve: interpolation refuses
    # tied times outright. This happens when the runs were not separated in
    # time, i.e. when the offsets are all zero because no TimeZero was
    # available to separate them.
    warning("The merged runs have ", sum(duplicates), " ", what,
            " sample", if (sum(duplicates) > 1) "s" else "",
            " at a time already taken by another run. The later ",
            if (sum(duplicates) > 1) "ones have" else "one has",
            " been dropped. Check that TimeZero distinguishes the runs.",
            call. = FALSE)
    values <- values[!duplicates, , drop = FALSE]
  }

  out <- nodes[[1]]
  out$Values <- values
  out$Avail <- any(vapply(nodes, function(n) isTRUE(n$Avail), logical(1)))

  out
}

#' Merge the blooddata of several runs into one
#'
#' @description Combines the blood samples of several runs of a single
#'   injection into one blooddata object, so that a curve can be fitted to all
#'   of them together.
#'
#'   Each run's samples are shifted by `offsets` before being combined, since
#'   BIDS times each run's samples from its own `TimeZero`. The descriptions,
#'   units and dispersion constant are taken from the first run, whose
#'   `TimeZero` the merged times then refer to.
#'
#' @param blooddata A list of blooddata objects, in time order.
#' @param offsets The number of seconds to add to each object's sample times.
#'   Defaults to no shift, i.e. to the runs already sharing a clock.
#'
#' @return A single blooddata object.
#'
#' @export
merge_blooddata <- function(blooddata, offsets = rep(0, length(blooddata))) {

  if (length(blooddata) != length(offsets)) {
    stop("One offset is needed for each of the ", length(blooddata),
         " runs being merged, but ", length(offsets), " were given.",
         call. = FALSE)
  }

  if (length(blooddata) == 1) {
    return(blooddata[[1]])
  }

  merged <- blooddata[[1]]

  merged$Data$Blood$Discrete <- merge_blood_node(
    purrr::map(blooddata, ~.x$Data$Blood$Discrete), offsets, "whole blood")

  merged$Data$Plasma <- merge_blood_node(
    purrr::map(blooddata, ~.x$Data$Plasma), offsets, "plasma")

  merged$Data$Metabolite <- merge_blood_node(
    purrr::map(blooddata, ~.x$Data$Metabolite), offsets, "parent fraction")

  # Autosampler data is commonly collected for the first run only, so the runs
  # without any are left out of the merge entirely rather than contributing an
  # empty node: their Continuous section holds nothing but Avail = FALSE, and
  # so has no descriptions or dispersion constant to take.
  continuous <- purrr::map(blooddata, ~.x$Data$Blood$Continuous)
  has_continuous <- vapply(continuous, function(n) isTRUE(n$Avail), logical(1))

  if (any(has_continuous)) {
    merged$Data$Blood$Continuous <- merge_blood_node(
      continuous[has_continuous], offsets[has_continuous], "autosampler")
  } else {
    merged$Data$Blood$Continuous <- list(Avail = FALSE)
  }

  merged
}

#' Combine the runs of each measurement
#'
#' @description Combines runs which belong to a single injection into one
#'   measurement per injection, so that one blood curve is fitted to the
#'   samples of all of them and one set of derivatives is written out.
#'
#'   Runs are grouped by every identifying attribute except `run` itself, and
#'   each run's sample times are shifted onto the first run's `TimeZero` (see
#'   [merge_blooddata()]). A measurement with only one run is left untouched,
#'   `run` entity and output filenames included; a merged measurement carries
#'   no `run`, since its curve belongs to all of them.
#'
#'   Whether to do this at all is a property of the study rather than of the
#'   data: two runs may be one injection scanned in an early and a late block,
#'   or two separate injections. Only the former should be merged, which is why
#'   this is driven by the `MergeRuns` configuration field.
#'
#' @param bidsdata A table of measurements, as assembled by the report
#'   template: identifying attributes, then `filedata`, then `blooddata` and
#'   `petinfo`.
#'
#' @return `bidsdata`, with merged measurements collapsed to one row each and a
#'   `merged_runs` column naming the runs each row was built from (`NA` for the
#'   rows which were left alone). The frame times in `tactimes` are those of
#'   the first run: bloodstream models blood, and does not use them.
#'
#' @export
merge_runs <- function(bidsdata) {

  bidsdata <- dplyr::ungroup(bidsdata)
  bidsdata$merged_runs <- NA_character_

  if (!("run" %in% colnames(bidsdata)) || nrow(bidsdata) < 2) {
    return(bidsdata)
  }

  # The attributes identifying a measurement are the columns ahead of
  # filedata, as everywhere else in the pipeline. Grouping by all of them but
  # run keeps runs of different subjects, sessions, tasks and tracers apart.
  attribute_cols <- colnames(bidsdata)[seq_len(which(colnames(bidsdata) == "filedata") - 1)]
  group_cols <- setdiff(attribute_cols, "run")

  if (length(group_cols) == 0) {
    key <- rep("1", nrow(bidsdata))
  } else {
    key <- do.call(paste, c(lapply(bidsdata[group_cols], function(x) {
      ifelse(is.na(x), "<NA>", as.character(x))
    }), sep = "\r"))
  }

  merged <- purrr::map(unique(key), function(k) {

    group <- bidsdata[key == k, , drop = FALSE]

    if (nrow(group) == 1) {
      return(group)
    }

    # Runs are combined in the order of their labels, which for run-01/run-02
    # and run-early/run-late is the order they were collected in. Ordering
    # them here rather than taking them as they came keeps the result
    # independent of the order the files happened to be listed in, which the
    # midnight unwrapping in run_time_offsets() depends on.
    group <- group[order(group$run, method = "radix"), , drop = FALSE]

    offsets <- run_time_offsets(group$petinfo)

    if (is.null(offsets)) {
      warning("The runs of ", describe_attributes(group[1, group_cols]),
              " could not be placed on a common clock, because at least one ",
              "of them has no TimeZero of the form hh:mm:ss. Their sample ",
              "times have been combined as they are, on the assumption that ",
              "they already share a time zero.", call. = FALSE)
      offsets <- rep(0, nrow(group))
    }

    row <- group[1, , drop = FALSE]
    row$run <- NA_character_
    row$merged_runs <- paste(group$run, collapse = " + ")

    # The files of every run, so that the report can name what went in. The
    # first run's attributes carry the study root and its own directory, which
    # is where the merged output is written.
    files <- dplyr::bind_rows(group$filedata)
    for (a in c("pet_key", "study_root", "pet_dir")) {
      attr(files, a) <- attr(group$filedata[[1]], a)
    }
    row$filedata <- list(files)

    row$blooddata <- list(merge_blooddata(group$blooddata, offsets))

    row
  })

  dplyr::bind_rows(merged)
}

#' Remove a BIDS entity from a filename
#'
#' @description Drops a `key-label` pair, and its separator, from a BIDS
#'   filename. Used to name the output of merged runs, whose curve belongs to
#'   every run rather than to the one whose filename it was derived from.
#'
#' @param filename A BIDS filename or path.
#' @param entity The entity key to remove, e.g. `"run"`.
#'
#' @return `filename`, without that entity.
#'
#' @export
bids_drop_entity <- function(filename, entity) {
  stringr::str_remove(filename, paste0("_", entity, "-[a-zA-Z0-9+]+"))
}
