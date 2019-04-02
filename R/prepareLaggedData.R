#' Plots main simulation parameters.
#'
#' @description Plots the normal function/s, fecundity, growth curve, and maturity age, of each virtual taxa in \code{parameters}.
#'
#' @usage parametersCheck(
#'   parameters,
#'   species="all",
#'   driver.A=NULL,
#'   driver.B=NULL,
#'   drivers=NULL,
#'   filename=NULL
#'   )
#'
#' @param parameters the parameters dataframe.
#' @param species if "all" or "ALL", all species in "parameters" are plotted. It also accepts a vector of numbers representing the rows of the selected species, or a vector of names of the selected species.
#' @param driver.A  numeric vector with driver values.
#' @param driver.B numeric vector with driver values.
#' @param drivers dataframe with drivers
#' @param filename character string, filename of the output pdf.
#'
#' @details The function prints the plot, can save it to a pdf file if \code{filename} is provided, and returns a \code{\link{ggplot2}} object.
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A \code{\link{ggplot2}} object.
#'
#' @seealso \code{\link{parametersDataframe}}, \code{\link{fixParametersTypes}}
#'
#' @examples
#'#generating driver
#'driver <- simulateDriver(
#'  random.seed = 10,
#'  time = 1:1000,
#'  autocorrelation.length = 200,
#'  output.min = 0,
#'  output.max = 100,
#'  rescale = TRUE
#'  )
#'
#'#preparing parameters
#'parameters <- parametersDataframe(rows=2)
#'parameters[1,] <- c("Species 1", 50, 20, 2, 0.2, 0, 100, 1000, 1, 0, 50, 10, 0, 0, NA, NA)
#'parameters[2,] <- c("Species 1", 500, 100, 10, 0.02, 0, 100, 1000, 1, 0, 50, 10, 0, 0, NA, NA)
#'parameters <- fixParametersTypes(x=parameters)
#'
#'#plotting parameters
#'parametersCheck(
#'  parameters=parameters,
#'  driver.A=driver,
#'  filename="Parameters.pdf"
#'  )
#'
#' @export
prepareLaggedData = function(simulation.data, response, drivers, time, lags, time.zoom=NULL, scale=FALSE){

  #computing data resolution to adjust lags for the annual resolution dataset
  temporal.resolution = simulation.data[2, time] - simulation.data[1, time]

  #converting lags from years to cases to be used as lags
  lags.to.rows = round(lags/temporal.resolution, 0)

  #adds 0 to lags if it's not
  if(!(0 %in% lags)){
    lags.to.rows = c(0, lags.to.rows)
    lags = c(0, lags)
  }

  #apply time.zoom if so
  if(!is.null(time.zoom) & is.vector(time.zoom) & is.numeric(time.zoom) & length(time.zoom) == 2){
    simulation.data = simulation.data[simulation.data[, time] >= time.zoom[1] & simulation.data[, time] <= time.zoom[2], ]
  }

  #response lags
  response.lags = do.call("merge", lapply(lags.to.rows, function(lag.to.row) lag(as.zoo(simulation.data[,response]), -lag.to.row)))

  #naming columns
  colnames(response.lags) = paste("Response", lags, sep = "_")

  #driver lags
  for(driver in drivers){

    driver.lags = do.call("merge", lapply(lags.to.rows, function(lag.to.row) lag(as.zoo(simulation.data[,driver]), -lag.to.row)))

    #naming columns
    colnames(driver.lags) = paste(driver, lags, sep = "_")

    #joining with response lags
    response.lags = cbind(response.lags, driver.lags)

  }

  #removing NA
  response.lags = as.data.frame(response.lags)
  response.lags$time = simulation.data[, time]
  response.lags = na.omit(response.lags)
  time = response.lags$time
  response.lags$time = NULL

  #scaling data
  if(scale==TRUE){
    response.lags = data.frame(scale(response.lags), time)
  } else {
    response.lags = data.frame(response.lags, time)
  }

  return(response.lags)

}
