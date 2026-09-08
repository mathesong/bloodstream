# A configuration file is written by one version of bloodstream and read by
# another, so reading one means filling in the fields it does not carry and
# translating the names it uses. Doing that in one place keeps the report, the
# configuration app and the saved output config reading a configuration the
# same way.

# The name the triexponential AIF model went by when its rise was always a
# straight line.
TRIEXP_LEGACY_NAME <- "Fit Individually: Linear Rise, Triexponential Decay"
TRIEXP_NAME <- "Fit Individually: Triexponential Decay"

#' Resolve a bloodstream configuration
#'
#' @description Fills in the fields a configuration does not carry, and
#'   translates the names of those which have been renamed, so that everything
#'   downstream reads one set of names and defaults.
#'
#'   * `MergeRuns` becomes a single `TRUE`/`FALSE`, defaulting to `TRUE`.
#'   * The triexponential AIF model was once named for its linear rise, since
#'     that was the only rise it had. It now chooses, so a configuration
#'     written under the old name selects the model and keeps the straight line
#'     it asked for. Anything else defaults to the interpolated rise.
#'
#' @param config A parsed bloodstream configuration.
#'
#' @return `config`, resolved.
#'
#' @export
resolve_config <- function(config) {

  config$MergeRuns <- isTRUE(as.logical(config$MergeRuns %||% TRUE)[1])

  if (identical(as.character(config$Model$AIF$Method), TRIEXP_LEGACY_NAME)) {
    config$Model$AIF$Method <- TRIEXP_NAME
    config$Model$AIF$rise <- config$Model$AIF$rise %||% "linear"
  }

  if (identical(as.character(config$Model$AIF$Method), TRIEXP_NAME)) {
    config$Model$AIF$rise <- match.arg(
      as.character(config$Model$AIF$rise %||% "interp")[1],
      c("interp", "linear"))
  }

  config
}
