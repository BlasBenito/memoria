#' Plots output of \code{\link{computeMemory}}
#'
#' @description
#'
#' @usage plotMemory(
#'   memory.output = NULL,
#'   title = "Ecological memory pattern",
#'   legend.position = "right"
#' )
#'
#' @param memory.output a dataframe with one time series per column.
#' @param title character string, name of the numeric column to be used as response in the model.
#' @param legend.position  character vector, names of the numeric columns to be used as predictors in the model.
#' @param filename  character string, name of output pdf file. If NULL or empty, no pdf is produced. It shouldn't include the extension of the output file.
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A ggplot object.
#'
#' @seealso \code{\link{computeMemory}}
#'
#' @examples
#'#loading data
#'data(laggedSimData)
#'
#'mem.output <- computeMemory(
#'  lagged.data = laggedSimData,
#'  drivers = "Driver.A",
#'  response = "Response"
#')
#'
#'mem.output.plot <- plotMemory(
#'  memory.output = mem.output
#'  )
#'
#'@export
plotMemory <- function(
  memory.output = NULL,
  title = "Ecological memory pattern",
  legend.position = "right",
  filename = NULL
  ){

  #loading cowplot
  library(cowplot)

  #to dataframe
  memory.output.df <- memory.output$memory

  #plot
  plot.memory <- ggplot(data=memory.output.df, aes(x=Lag, y=median, group=Variable, color=Variable, fill=Variable)) +
    geom_ribbon(aes(ymin=min, ymax=max), alpha=0.3, colour=NA) +
    geom_line(alpha=0.6, size=1.5) +
    scale_color_viridis(discrete=TRUE) +
    scale_fill_viridis(discrete=TRUE) +
    scale_x_continuous(breaks=unique(memory.output.df$Lag)) +
    xlab("Lag (years)") +
    ylab("Relative importance") +
    theme(strip.text.x = element_text(size = 12),
          legend.position = legend.position,
          axis.text.x = element_text(size=12)) +
    ggtitle(title)

  print(plot.memory)

  #plots to pdf
  if(!is.null(filename)){ggsave(filename = paste(filename, ".pdf", sep = ""))}

  return(plot.memory)
}
