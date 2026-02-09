#' Plots output of \code{\link{computeMemory}}
#'
#' @description Plots the ecological memory pattern yielded by \code{\link{computeMemory}}.
#'
#' @param memory.output list, output of \code{\link{computeMemory}}. Default: \code{NULL}.
#' @param ribbon logical, switches plotting of confidence intervals on (TRUE) and off (FALSE). Default: \code{FALSE}.
#' @param ... additional arguments for internal use.
#' @param legend.position character, position of the legend. Default: \code{"right"}.
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A ggplot object.
#'
#' @seealso \code{\link{computeMemory}}
#'
#' @examples
#'#loading data
#'data(palaeodataMemory)
#'
#'#plotting memory pattern
#'plotMemory(memory.output = palaeodataMemory)
#'
#'#with confidence ribbon
#'plotMemory(memory.output = palaeodataMemory, ribbon = TRUE)
#'
#'@family memoria
#'@export
plotMemory <- function(
  memory.output = NULL,
  ribbon = FALSE,
  legend.position = "right",
  ...
) {
  xlab = "Lag"
  ylab = "Permutation Importance"
  ribbon.alpha = 0.25

  # Extract data from ... if provided, otherwise use memory.output
  dots <- list(...)
  data <- dots$data

  if (is.null(data)) {
    data <- memory.output$memory
  }

  line.alpha <- ifelse(
    test = ribbon,
    yes = 0.6,
    no = 1
  )

  # Build base plot
  plot.memory <- ggplot(
    data = data,
    aes(
      x = lag,
      y = median,
      group = variable,
      color = variable,
      fill = variable
    )
  )

  # Add ribbon if requested
  if (ribbon) {
    plot.memory <- plot.memory +
      geom_ribbon(
        aes(ymin = min, ymax = max),
        alpha = ribbon.alpha,
        colour = NA
      )
  }

  # Add line
  plot.memory <- plot.memory +
    geom_line(alpha = line.alpha, linewidth = 1.5)

  # Add scales and labels
  plot.memory <- plot.memory +
    scale_color_viridis_d() +
    scale_fill_viridis_d() +
    scale_x_continuous(
      breaks = pretty(unique(data$lag)),
      expand = c(0, 0)
    ) +
    scale_y_continuous(expand = c(0, 0)) +
    xlab(xlab) +
    ylab(ylab) +
    theme(
      strip.text.x = element_text(size = 12),
      legend.position = legend.position,
      axis.text.x = element_text(size = 12)
    )

  return(plot.memory)
}
