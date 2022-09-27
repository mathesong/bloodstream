#' @export
qc_parentFraction <- function(blooddata, title) {

  pf <- bd_extract(blooddata, "parentFraction")

  dup_times <- sum(duplicated(pf$time))
  over_1 <- sum(pf$parentFraction > 1)
  below_0 <- sum(pf$parentFraction < 0)
  few_points <- nrow(pf) < 4
  all_1 <- all(pf$parentFraction == 1)

  max_pf <- round(max(pf$parentFraction),2)
  min_pf <- round(min(pf$parentFraction),2)

  warnings <- c("")

  if( dup_times > 0 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has duplicated parentFraction time points.\n\n")
  }

  if( over_1 > 0 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has parentFraction values greater than 1: max {max_pf}.\n\n")
  }

  if( below_0 > 0 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has parentFraction values less than 0: min {min_pf}.\n\n")
  }

  if( few_points ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has fewer than 4 parentFraction values, limiting the possible modelling options.\n\n")
  }

  if( all_1 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has parentFraction values all equal to 1, usually caused by a lack of metabolite data. Metabolite models cannot be fitted.\n\n")
  }

  if(warnings=="") {
    warnings <- NA
  }

  return(warnings)

}

#' @export
qc_bpr <- function(blooddata, title) {

  bpr <- bd_extract(blooddata, "BPR")
  mean_bpr <- round(mean(bpr$bpr), 2)
  min_bpr <- round(min(bpr$bpr),2)

  dup_times <- sum(duplicated(bpr$time))
  below_0 <- sum(bpr$bpr < 0)
  few_points <- nrow(bpr) < 4
  low_mean <- mean_bpr < 0.25
  high_mean <- mean_bpr > 4
  all_1 <- all(bpr$bpr == 1)

  warnings <- c("")

  if( dup_times > 0 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has duplicated BPR time points.\n\n")
  }

  if( below_0 > 0 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has BPR values less than 0: min {min_bpr}.\n\n")
  }

  if( few_points ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has fewer than 4 BPR values, limiting the possible modelling options.\n\n")
  }

  if( low_mean ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has an unusually low mean BPR value: {mean_bpr}. This could be tracer-dependent.\n\n")
  }

  if( high_mean ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has an unusually high mean BPR value: {mean_bpr}. This could be tracer-dependent.\n\n")
  }

  if( all_1 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has BPR values all equal to 1, usually caused by a lack of whole blood or plasma data. Care should be taken with both both blood modelling and TAC kinetic modelling.\n\n")
  }

  if(warnings=="") {
    warnings <- NA
  }

  return(warnings)

}



#' @export
qc_wb <- function(blooddata, title) {

  wb <- bd_extract(blooddata, "Blood")

  min_wb <- round(min(wb$activity),2)
  max_wb <- round(max(wb$activity),2)

  dup_times <- sum(duplicated(wb$time))
  lowest_peak <- min_wb / max_wb
  few_points <- nrow(wb) < 8

  lowest_peak_perc <- round(100*lowest_peak, 2)


  warnings <- c("")

  if( dup_times > 0 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has duplicated whole blood time points. This is possible with manual and automatic time points, but this could be caused by manual samples in the auto data.\n\n")
  }

  if( lowest_peak < -0.1 ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has negative whole blood values lower than 10% of the peak value: {lowest_peak_perc}%.\n\n")
  }

  if( few_points ) {
    warnings <- stringr::str_glue(warnings, "*   **{title}** has fewer than 8 whole blood values, limiting the possible modelling options.\n\n")
  }

  if(warnings=="") {
    warnings <- NA
  }

  return(warnings)

}
