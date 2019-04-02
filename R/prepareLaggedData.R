#' Organizes time series data into lags.
#'
#' @description Takes a multivariate time series, where at least one variable is meant to be used as a response in a model while the others are meant to be used as predictors, and organizes it in to quantify ecological memory through models of the form \eqn{p_{t} = p_{t-1} +...+ p_{t-n} + d_{t} + d_{t-1} +...+ d_{t-n}}, where:
#'
#' \itemize{
#'  \item \eqn{d} is a driver (several drivers can be added).
#'  \item \eqn{t} is the time of any given value of the response \emph{p}.
#'  \item \eqn{t-1} is the lag number 1 (in time units).
#'  \item \eqn{p_{t-1} +...+ p_{t-n}}  represents the endogenous component of ecological memory.
#'  \item \eqn{d_{t-1} +...+ d_{t-n}}  represents the exogenous component of ecological memory.
#'  \item \eqn{d_{t}} represents the concurrent effect of the driver over the response.
#' }
#'
#'
#' @usage prepareLaggedData(
#'   input.data = NULL,
#'   response = NULL,
#'   drivers = NULL,
#'   time = NULL,
#'   lags = seq(0, 200, by=20),
#'   time.zoom=NULL,
#'   scale=FALSE
#'   )
#'
#' @param input.data a dataframe with one time series per column.
#' @param response character string, name of the numeric column to be used as response in the model.
#' @param drivers  character vector, names of the numeric columns to be used as predictors in the model.
#' @param time character vector, name of the numeric column with the time/age.
#' @param lags numeric vector, lags to be used in the equation. Generally, a regular sequence of numbers. The use \code{\link{seq}} to define it is highly recommended. If 0 is absent from lags, it is added automatically to allow the consideration of a concurrent effect.
#' @param time.zoom numeric vector of two numbers of the \code{time} column used to subset the data if desired.
#' @param scale boolean, if TRUE, applies the \code{\link{scale}} function to normalize the data. Required if the lagged data is going to be used to fit linear models.
#'
#' @details The function returns a dataframe. Column names have the lag number as a suffix. The response variable is identified by changing its name to "Response".
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A dataframe.
#'
#' @seealso \code{\link{computeMemory}}
#'
#' @examples
#'#loading data
#'data(simulation)
#'
#'#adding lags
#'sim.lags <- prepareLaggedData(
#'   input.data = simulation[[1]],
#'   response = "Pollen",
#'   drivers = "Driver",
#'   time = "Time",
#'   lags = seq(0, 200, by=20),
#'   time.zoom=NULL,
#'   scale=FALSE
#'   )
#'
#' @export
prepareLaggedData = function(input.data, response, drivers, time, lags, time.zoom=NULL, scale=FALSE){

  simulation.data <- input.data

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
