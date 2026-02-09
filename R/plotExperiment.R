#' Plots the output of  \code{\link{runExperiment}}.
#'
#' @description Takes the output of \code{\link{runExperiment}}, and generates plots of ecological memory patterns for a large number of simulated pollen curves.
#'
#'
#' @param experiment.output list, output of  \code{\link{runExperiment}}. Default: \code{NULL}.
#' @param parameters.file dataframe of simulation parameters. Default: \code{NULL}.
#' @inheritParams plotMemory
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
  ribbon = FALSE
) {
  # Determine number of sampling columns
  if (is.null(dim(experiment.output$output))) {
    n.columns <- 1
  } else {
    n.columns <- dim(experiment.output$output)[2]
  }

  # Convert experiment output to long table
  simulation.df <- experimentToTable(
    experiment.output = experiment.output,
    parameters.file = parameters.file
  )

  # Order of name as it comes in the dataset
  simulation.df$name <- factor(
    simulation.df$name,
    levels = unique(simulation.df$name)
  )

  # Build plot using plotMemory
  experiment.plot <- plotMemory(
    data = simulation.df,
    ribbon = ribbon,
    legend.position = "bottom",
    base.theme = "classic",
    xlab = "Lag (years)",
    ylab = "Relative importance",
    ribbon.alpha = 0.3
  ) +
    facet_wrap(
      vars(name),
      ncol = n.columns,
      scales = "free_y"
    )

  return(experiment.plot)
}
