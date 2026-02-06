#' Plots the output of  \code{\link{runExperiment}}.
#'
#' @description Takes the output of \code{\link{runExperiment}}, and generates plots of ecological memory patterns for a large number of simulated pollen curves.
#'
#'
#' @param experiment.output list, output of  \code{\link{runExperiment}}. Default: \code{NULL}.
#' @param parameters.file dataframe of simulation parameters. Default: \code{NULL}.
#' @param experiment.title character string, title of the plot. Default: \code{NULL}.
#'
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A ggplot2 object.
#'
#' @seealso \code{\link{plotMemory}}, \code{\link{runExperiment}}
#' @family virtualPollen
#' @export
plotExperiment <- function(
  experiment.output = NULL,
  parameters.file = NULL,
  experiment.title = NULL
) {
  strip.text.size <- 12
  axis.x.text.size <- 8
  axis.y.text.size <- 12
  axis.x.title.size <- 14
  axis.y.title.size <- 14
  title.size <- 18
  R2 <- TRUE
  legend.position <- "bottom"

  # Determine number of sampling columns
  if (is.null(dim(experiment.output$output))) {
    n.columns <- 1
  } else {
    n.columns <- dim(experiment.output$output)[2]
  }
  #output of experiment.output to long table
  simulation.df <- experimentToTable(
    experiment.output = experiment.output,
    parameters.file = parameters.file,
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
      x = lag,
      y = median,
      group = variable,
      color = variable,
      fill = variable
    )
  ) +
    geom_ribbon(aes(ymin = min, ymax = max), alpha = 0.3, colour = NA) +
    geom_line(alpha = 0.6, linewidth = 1.5) +
    scale_color_viridis_d() +
    scale_fill_viridis_d() +
    scale_x_continuous(breaks = unique(simulation.df$lag)) +
    facet_wrap(
      vars(name),
      ncol = n.columns,
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
    theme_classic() +
    theme(legend.position = legend.position)

  return(experiment.plot)
}
