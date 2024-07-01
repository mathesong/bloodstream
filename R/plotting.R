#' Plot blooddata with an extra log time plot
#'
#' @param blooddata blooddata object
#' @param titletext text of the title
#'
#' @return plots
#' @export
#'
#' @import ggplot2
#'
#' @examples
#' \dontrun{
#' plot_blooddata_extra(blooddata, titletext)
#' }
plot_blooddata_extra <- function(blooddata, titletext) {

  orig_time <- kinfitr::plot_blooddata(blooddata) +
    ggplot2::labs(x="Time (min)")

  bd_legend <- cowplot::get_legend(orig_time)

  orig_time <- orig_time +
    ggplot2::guides(colour="none", shape="none")

  log_time <- kinfitr::plot_blooddata(blooddata) +
    ggplot2::scale_x_log10() +
    ggplot2::labs(x = "Time (min, log-scaled axis)") +
    ggplot2::guides(colour="none", shape="none")

  blooddata_plots <- cowplot::plot_grid(orig_time, log_time, bd_legend,
                                        ncol=3, rel_widths = c(3,3,1))

  label <- cowplot::ggdraw() +
    cowplot::draw_label(titletext)

  cowplot::plot_grid(label, blooddata_plots, rel_heights = c(0.1, 1),
                     nrow = 2)

}

#' Plot parent fraction predictions
#'
#' @param data parent fraction data
#' @param preds predictions dataframe
#' @param title plot title
#'
#' @return plots
#' @export
#'
#' @import ggplot2
#'
#' @examples
#' \dontrun{
#' plot_pf_preds(blooddata, preds, titletext)
#' }
plot_pf_preds <- function(data, preds, title) {


  outplot <- ggplot(data, aes(x=time, y=parentFraction)) +
    geom_line(data=preds, colour="red") +
    geom_point() +
    labs(title = title)

  if( ".upper_ci" %in% colnames(preds) && ".lower_ci" %in% colnames(preds) ) {
    outplot <- outplot +
      geom_ribbon(data=preds, fill="red", alpha=0.1,
                  aes(ymin=.lower_ci, ymax=.upper_ci))
  }

  return(outplot)

}

#' Plot blood-to-plasma ratio predictions
#'
#' @param data BPR data
#' @param preds predictions dataframe
#' @param title plot title
#'
#' @return plots
#' @export
#'
#' @import ggplot2
#'
#' @examples
#' \dontrun{
#' plot_bpr_preds(blooddata, preds, titletext)
#' }
plot_bpr_preds <- function(data, preds, title) {


  outplot <- ggplot(data, aes(x=time, y=bpr)) +
    geom_line(data=preds, colour="red") +
    geom_point() +
    labs(title = title, y = "Blood-to-Plasma Ratio")

  if( "upper" %in% colnames(preds) && "lower" %in% colnames(preds) ) {
    outplot <- outplot +
      geom_ribbon(data=preds, fill="red", alpha=0.1,
                  aes(ymin=lower, ymax=upper))
  }

  return(outplot)

}

#' Plot arterial input function predictions
#'
#' @param data AIF data
#' @param preds predictions dataframe
#' @param title plot title
#'
#' @return plots
#' @export
#'
#' @import ggplot2
#'
#' @examples
#' \dontrun{
#' plot_aif_preds(blooddata, preds, titletext)
#' }
plot_aif_preds <- function(data, preds, title) {


  if( length(unique(data$Method)) == 1) {
    outplot <- ggplot(data, aes(x=time, y=aif)) +
      geom_point() +
      geom_line(data=preds, colour="red") +
      labs(y="AIF")
  } else {
    outplot <- ggplot(data, aes(x=time, y=aif)) +
      geom_point(data = data %>%
                   dplyr::filter(Method == "Continuous"),
                 size = 1, shape = 1) +
      geom_point(data = data %>%
                   dplyr::filter(Method == "Discrete"),
                 size = 2) +
      geom_line(data=preds, colour="red") +
      labs(y="AIF")
  }

  if( "upper" %in% colnames(preds) && "lower" %in% colnames(preds) ) {
    outplot <- outplot +
      geom_ribbon(data=preds, fill="red", alpha=0.1,
                  aes(ymin=lower, ymax=upper))
  }

  outplot_log <- outplot +
    scale_x_log10() +
    ggplot2::labs(x = "Time (min, log-scaled axis)")

  aif_plots <- cowplot::plot_grid(outplot, outplot_log,
                                  ncol=2)

  label <- cowplot::ggdraw() +
    cowplot::draw_label(title)

  total_outplot <- cowplot::plot_grid(label, aif_plots, rel_heights = c(0.1, 1),
                                      nrow = 2)

  return(total_outplot)

}




#' Plot whole-blood predictions
#'
#' @param data whole blood data
#' @param preds predictions dataframe
#' @param title plot title
#'
#' @return plots
#' @export
#'
#' @import ggplot2
#'
#' @examples
#' \dontrun{
#' plot_aif_preds(blooddata, preds, titletext)
#' }
plot_wb_preds <- function(data, preds, title) {


  if( length(unique(data$Method)) == 1) {
    outplot <- ggplot(data, aes(x=time, y=activity)) +
      geom_point() +
      geom_line(data=preds, colour="red") +
      labs(y="Whole Blood")
  } else {
    outplot <- ggplot(data, aes(x=time, y=activity)) +
      geom_point(data = data %>%
                   dplyr::filter(Method == "Continuous"),
                 size = 1, shape = 1) +
      geom_point(data = data %>%
                   dplyr::filter(Method == "Discrete"),
                 size = 2) +
      geom_line(data=preds, colour="red") +
      labs(y="AIF")
  }

  if( "upper" %in% colnames(preds) && "lower" %in% colnames(preds) ) {
    outplot <- outplot +
      geom_ribbon(data=preds, fill="red", alpha=0.1,
                  aes(ymin=lower, ymax=upper))
  }

  outplot_log <- outplot +
    scale_x_log10() +
    ggplot2::labs(x = "Time (min, log-scaled axis)")

  wb_plots <- cowplot::plot_grid(outplot, outplot_log,
                                 ncol=2)

  label <- cowplot::ggdraw() +
    cowplot::draw_label(title)

  total_outplot <- cowplot::plot_grid(label, wb_plots, rel_heights = c(0.1, 1),
                                      nrow = 2)

  return(total_outplot)

}

