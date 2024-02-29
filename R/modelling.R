#' @export
compare_aic_metabmodels_indiv <- function(blooddata, fit_ppf0 = FALSE,
                                          starttime = 0, endtime = Inf,
                                          gam_k) {

  pfdat <- kinfitr::bd_extract(blooddata, "parentFraction", what = "raw") %>%
    dplyr::filter(time >= (starttime * 60)) %>%
    dplyr::filter(time <= (endtime * 60))

  tryAIC <- purrr::possibly(.f = ~suppressWarnings(AIC(.x)), otherwise = NA)


  hill     <- tryAIC(kinfitr::metab_hill(pfdat$time, pfdat$parentFraction,
                                         fit_ppf0 = fit_ppf0))
  exp      <- tryAIC(kinfitr::metab_exponential(pfdat$time, pfdat$parentFraction,
                                                fit_ppf0 = fit_ppf0))
  power    <- tryAIC(kinfitr::metab_power(pfdat$time, pfdat$parentFraction,
                                          fit_ppf0 = fit_ppf0))
  sig      <- tryAIC(kinfitr::metab_sigmoid(pfdat$time, pfdat$parentFraction,
                                            fit_ppf0 = fit_ppf0))
  power    <- tryAIC(kinfitr::metab_power(pfdat$time, pfdat$parentFraction,
                                          fit_ppf0 = fit_ppf0))
  invgamma <- tryAIC(kinfitr::metab_invgamma(pfdat$time, pfdat$parentFraction,
                                             fit_ppf0 = fit_ppf0))
  gamma    <- tryAIC(kinfitr::metab_gamma(pfdat$time, pfdat$parentFraction,
                                             fit_ppf0 = fit_ppf0))
  gam      <- tryAIC(mgcv::gam(parentFraction ~ s(time, k=as.numeric(gam_k)),
                               data=pfdat,
                               method = "REML"))


  tibble(
    Hill = hill,
    Exponential = exp,
    Power = power,
    Sigmoid = sig,
    `Inverse Gamma` = invgamma,
    Gamma = gamma,
    GAM = gam) %>%
    tidyr::gather("Model", "AIC")

}

#' @export
compare_aic_metabmodels_group <- function(bidsdata, fit_ppf0 = FALSE,
                                          starttime = 0, endtime = Inf,
                                          gam_k) {

  metab_comparison_aic <- purrr::map(bidsdata$blooddata,
                                     ~compare_aic_metabmodels_indiv(.x, fit_ppf0 = fit_ppf0,
                                                                    starttime = starttime, endtime = endtime,
                                                                    gam_k = gam_k))

  metab_comparisons <- bidsdata %>%
    dplyr::select(pet) %>%
    dplyr::mutate(AICs = metab_comparison_aic) %>%
    dplyr::mutate(n = 1:n()) %>%
    tidyr::unnest(AICs)

  metab_aicsum_comparisons <- metab_comparisons %>%
    mutate(AIC = ifelse(is.na(AIC), yes = max(AIC, na.rm=T), no=AIC)) %>%
    group_by(Model) %>%
    summarise(Total_AIC = sum(AIC)) %>%
    arrange(Total_AIC)

  aicplot <- ggplot2::ggplot(metab_comparisons, aes(x=pet, y=AIC,
                                                    colour=Model, group=Model)) +
    geom_line() +
    geom_point(size=3, colour="black", alpha=0.5) +
    geom_point(size=2, alpha=0.5) +
    theme(axis.text.x = element_blank()) +
    labs(x = "Measurement")





  list(plot = aicplot, scores = metab_aicsum_comparisons)

}
