#' Plots the output of  \code{\link{runExperiment}}.
#'
#' @description Takes the output of \code{\link{runExperiment}}, and generates plots of ecological memory patterns for a large number of simulated pollen curves.
#'
#'
#'@usage plotExperiment(
#'  experiment.output = NULL,
#'  parameters.file = NULL,
#'  experiment.title = NULL,
#'  sampling.names = NULL,
#'  legend.position = "bottom",
#'  R2 = NULL,
#'  filename = NULL,
#'  strip.text.size = 12,
#'  axis.x.text.size = 8,
#'  axis.y.text.size = 12,
#'  axis.x.title.size = 14,
#'  axis.y.title.size = 14,
#'  title.size = 18,
#'  caption = ""
#'  )
#'
#' @param experiment.output list, output of  \code{\link{runExperiment}}.
#' @param parameters.file dataframe of simulation parameters.
#' @param experiment.title character string, title of the plot.
#' @param sampling.names vector of character strings with the names of the columns used in the argument \code{simulations.file} of \code{\link{runExperiment}}.
#' @param filename character string, path and name (without extension) of the output pdf file.
#' @param legend.position legend position in ggplot object. One of "bottom", "right", "none".
#' @param R2 boolean. If \code{TRUE}, pseudo R-squared values are printed along with the traits of the virtual taxa.
#' @param strip.text.size size of the facet's labels.
#' @param axis.x.text.size size of the labels in x axis.
#' @param axis.y.text.size size of the labels in y axis.
#' @param axis.x.title.size size of the title of the x axis.
#' @param axis.y.title.size size of the title of the y axis.
#' @param title.size size of the plot title.
#' @param caption character string, caption of the output figure.
#'
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A ggplot2 object.
#'
#' @seealso \code{\link{plotMemory}}, \code{\link{runExperiment}}
#'
#' @export
plotExperiment <- function(
  experiment.output = NULL,
  parameters.file = NULL,
  experiment.title = NULL,
  sampling.names = NULL,
  legend.position = "bottom",
  R2 = NULL,
  filename = NULL,
  strip.text.size = 12,
  axis.x.text.size = 8,
  axis.y.text.size = 12,
  axis.x.title.size = 14,
  axis.y.title.size = 14,
  title.size = 18,
  caption = ""
) {
  #output of experiment.output to long table
  simulation.df <- experimentToTable(
    experiment.output = experiment.output,
    parameters.file = parameters.file,
    sampling.names = sampling.names,
    R2 = R2
  )

  #order of name as it comes in the dataset
  simulation.df$name <- factor(
    simulation.df$name,
    levels = unique(simulation.df$name)
  )

  #plot
  experiment.plot <- ggplot(
    data = simulation.df,
    aes(
      x = Lag,
      y = median,
      group = Variable,
      color = Variable,
      fill = Variable
    )
  ) +
    geom_ribbon(aes(ymin = min, ymax = max), alpha = 0.3, colour = NA) +
    geom_line(alpha = 0.6, size = 1.5) +
    scale_color_viridis(discrete = TRUE) +
    scale_fill_viridis(discrete = TRUE) +
    scale_x_continuous(breaks = unique(simulation.df$Lag)) +
    facet_wrap(
      "name",
      ncol = length(unique(simulation.df$sampling)),
      scales = "free_y"
    ) +
    xlab("Lag (years)") +
    ylab("Relative importance") +
    theme(
      strip.text.x = element_text(size = strip.text.size),
      axis.text.x = element_text(size = axis.x.text.size),
      axis.text.y = element_text(size = axis.y.text.size),
      axis.title.x = element_text(size = axis.x.title.size),
      axis.title.y = element_text(size = axis.y.title.size),
      plot.title = element_text(size = title.size)
    ) +
    ggtitle(experiment.title) +
    cowplot::theme_cowplot() +
    theme(legend.position = legend.position) +
    labs(caption = caption)

  if (!is.null(filename) & is.character(filename)) {
    ggsave(
      filename = paste(filename, ".pdf", sep = ""),
      width = length(unique(simulation.df$sampling)) * 4,
      height = 1.5 * nrow(experiment.output$output)
    )
  }

  return(experiment.plot)
}
