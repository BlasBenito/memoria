#' Plots output of \code{\link{computeMemory}}
#'
#' @description Plots the ecological memory pattern yielded by \code{\link{computeMemory}}.
#'
#' @usage plotMemory(
#'   memory.output = NULL,
#'   ribbon = FALSE,
#'   legend.position = "right",
#'   filename = NULL
#' )
#'
#' @param memory.output list, output of \code{\link{computeMemory}}.
#' @param ribbon logical, switches plotting of confidence intervals on (TRUE) and off (FALSE). Default: FALSE
#' @param legend.position character string, legend position (e.g., "right", "bottom", "none").
#' @param filename deprecated, not used. Kept for backwards compatibility.
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
#'
#'@export
plotMemory <- function(
  memory.output = NULL,
  ribbon = FALSE,
  legend.position = "right",
  filename = NULL
) {
  line.alpha <- ifelse(
    test = ribbon,
    yes = 0.6,
    no = 1
  )

  #plot
  if (ribbon) {
    plot.memory <- ggplot(
      data = memory.output$memory,
      aes(
        x = lag,
        y = median,
        group = variable,
        color = variable,
        fill = variable
      )
    ) +
      geom_ribbon(aes(ymin = min, ymax = max), alpha = 0.25, colour = NA) +
      geom_line(alpha = line.alpha, linewidth = 1.5)
  } else {
    plot.memory <- ggplot(
      data = memory.output$memory,
      aes(
        x = lag,
        y = median,
        group = variable,
        color = variable,
        fill = variable
      )
    ) +
      geom_line(alpha = line.alpha, linewidth = 1.5)
  }

  plot.memory <- plot.memory +
    scale_color_viridis_d() +
    scale_fill_viridis_d() +
    scale_x_continuous(
      breaks = pretty(unique(memory.output$memory$lag)),
      expand = c(0, 0)
    ) +
    scale_y_continuous(expand = c(0, 0)) +
    xlab("Lag") +
    ylab("Permutation Importance") +
    theme_bw() +
    theme(
      strip.text.x = element_text(size = 12),
      legend.position = legend.position,
      axis.text.x = element_text(size = 12)
    )

  return(plot.memory)
}
