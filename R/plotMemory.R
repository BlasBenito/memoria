#' Plots output of \code{\link{computeMemory}}
#'
#' @description Plots the ecological memory pattern yielded by \code{\link{computeMemory}}.
#'
#' @usage plotMemory(
#'   memory.output = NULL,
#'   title = "Ecological memory pattern",
#'   legend.position = "right",
#'   filename = NULL
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
#'data(palaeodataMemory)
#'
#'#plotting memory pattern
#'plotMemory(memory.output = palaeodataMemory)
#'
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
  library(viridis)

  #to dataframe
  memory.output.df <- memory.output$memory

  #guessing units of Lags
  if((memory.output.df[2, "Lag"] - memory.output.df[1, "Lag"]) < 1){
    lag.units <- "ky"
  } else {
    lag.units <- "years"
  }


  #plot
  plot.memory <- ggplot(data=memory.output.df, aes(x=Lag, y=median, group=Variable, color=Variable, fill=Variable)) +
    geom_ribbon(aes(ymin=min, ymax=max), alpha=0.3, colour=NA) +
    geom_line(alpha=0.6, size=1.5) +
    scale_color_viridis(discrete=TRUE) +
    scale_fill_viridis(discrete=TRUE) +
    scale_x_continuous(breaks=unique(memory.output.df$Lag), expand=c(0,0)) +
    scale_y_continuous(expand=c(0,0)) +
    xlab(paste("Lag (", lag.units, ")", sep="")) +
    ylab("Relative importance") +
    theme(strip.text.x = element_text(size = 12),
          legend.position = legend.position,
          axis.text.x = element_text(size=12)) +
    ggtitle(title) +
    cowplot::theme_cowplot()

  print(plot.memory)

  #plots to pdf
  if(!is.null(filename)){ggsave(filename = paste(filename, ".pdf", sep = ""))}

}
