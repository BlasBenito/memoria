#' Plots output of \code{\link{computeMemory}}
#'
#' @description Plots the ecological memory pattern yielded by \code{\link{computeMemory}}.
#'
#' @param memory.output list, output of \code{\link{computeMemory}}. Default: \code{NULL}.
#' @param ribbon logical, switches plotting of confidence intervals on (TRUE) and off (FALSE). Default: \code{FALSE}.
#' @param data data.frame, for internal use by \code{\link{plotExperiment}}. When provided, used instead of \code{memory.output$memory}. Default: \code{NULL}.
#' @param legend.position character, position of the legend. Default: \code{"right"}.
#' @param base.theme character, base theme to use: \code{"bw"} for \code{theme_bw()} or \code{"classic"} for \code{theme_classic()}. Default: \code{"bw"}.
#' @param xlab character, x-axis label. Default: \code{"Lag"}.
#' @param ylab character, y-axis label. Default: \code{"Permutation Importance"}.
#' @param title character, plot title. Default: \code{NULL}.
#' @param ribbon.alpha numeric, alpha transparency for the ribbon. Default: \code{0.25}.
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
  data = NULL,
  legend.position = "right",

  base.theme = "bw",
  xlab = "Lag",
  ylab = "Permutation Importance",
  title = NULL,
  ribbon.alpha = 0.25
) {

  # Use data parameter if provided, otherwise extract from memory.output

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
      geom_ribbon(aes(ymin = min, ymax = max), alpha = ribbon.alpha, colour = NA)
  }

  # Add line
  plot.memory <- plot.memory +
    geom_line(alpha = line.alpha, linewidth = 1.5)

  # Apply base theme
 if (base.theme == "classic") {
    plot.memory <- plot.memory + theme_classic()
  } else {
    plot.memory <- plot.memory + theme_bw()
  }

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

  # Add title if provided
  if (!is.null(title)) {
    plot.memory <- plot.memory + ggtitle(title)
  }

  return(plot.memory)
}
