#' Organizes time series data into lags.
#'
#' @description Takes a multivariate time series, where at least one variable is meant to be used as a response while the others are meant to be used as predictors in a model, and organizes it in to quantify ecological memory through models of the form:
#'  \eqn{p_{t} ~ p_{t-1} +...+ p_{t-n} + d_{t} + d_{t-1} +...+ d_{t-n}}
#'
#'  where:
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
#'   oldest.sample = "first",
#'   lags = seq(0, 200, by=20),
#'   time.zoom=NULL,
#'   scale=FALSE
#'   )
#'
#' @param input.data a dataframe with one time series per column.
#' @param response character string, name of the numeric column to be used as response in the model.
#' @param drivers  character vector, names of the numeric columns to be used as predictors in the model.
#' @param time character vector, name of the numeric column with the time/age.
#' @param oldest.sample character string, either "first" or "last". When "first", the first row taken as the oldest case of the time series and the last row is taken as the newest case, so ecological memory flows from the first to the last row of \code{input.data}. When "last", the last row is taken as the oldest sample, and this is the mode that should be used when \code{input.data} represents a palaeoecological dataset. Default behavior is "first".
#' @param lags numeric vector of positive integers, lags to be used in the equation. Generally, a regular sequence of numbers, in the same units as \code{time}. The use \code{\link{seq}} to define it is highly recommended. If 0 is absent from lags, it is added automatically to allow the consideration of a concurrent effect. Lags should take into account the temporal resolution of the data, and be aligned to it. For example, if the interval between consecutive samples is 100 years, lags should be something like \code{0, 100, 200, 300}. Lags can also be multiples of the time resolution, such as \code{0, 200, 400, 600} (in the case time resolution is 100 years).
#' @param time.zoom numeric vector of two numbers of the \code{time} column used to subset the data if desired.
#' @param scale boolean, if TRUE, applies the \code{\link{scale}} function to normalize the data. Required if the lagged data is going to be used to fit linear models.
#'
#' @details The function interprets the \code{time} column as an index representing the
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A dataframe with columns representing time-delayed values of the drivers and the response. Column names have the lag number as a suffix. The response variable is identified in the output as "Response_0".
#'
#' @seealso \code{\link{computeMemory}}
#'
#' @examples
#'#loading data
#'data(palaeodata)
#'
#'#adding lags
#'lagged.data <- prepareLaggedData(
#'  input.data = palaeodata,
#'  response = "pollen.pinus",
#'  drivers = c("climate.temperatureAverage", "climate.rainfallAverage"),
#'  time = "age",
#'  oldest.sample = "last",
#'  lags = seq(0.2, 1, by=0.2),
#'  time.zoom=NULL,
#'  scale=FALSE
#')
#
#'str(lagged.data)
#'
#' @export
prepareLaggedData = function(input.data = NULL,
                             response = NULL,
                             drivers = NULL,
                             time = NULL,
                             oldest.sample = "first",
                             lags = NULL,
                             time.zoom = NULL,
                             scale = FALSE){

  #testing input data
  if(inherits(input.data, "data.frame") == FALSE){stop("Argument input.data must be a dataframe.")}
  if(is.character(response) == FALSE){
    stop("Argument response must be a character string.")
  } else {
      if(!(response %in% colnames(input.data))){stop("The response column does not exist in input.data.")}
  }

  if(is.character(drivers) == FALSE){
    stop("Argument drivers must be a character string or character vector.")
  } else {
    for(driver in drivers){
    if(!(driver %in% colnames(input.data))){stop(paste("The driver ", driver,  " column does not exist in input.data.", sep=""))}
    }
  }

  if(is.character(time) == FALSE){
    stop("Argument time must be a character string.")
  } else {
    if(!(time %in% colnames(input.data))){stop("The time column do not exist in input.data.")}
  }

  if(!(oldest.sample %in% c("first", "FIRST", "First", "last", "LAST", "Last"))){
    oldest.sample <- "first"
    message("Argument oldest.sample was not defined, I am setting it up to 'first'. Check the help file for more details.")
  }

  if(is.null(time.zoom) == FALSE){
    if(max(time.zoom) > max(input.data[, "age"])){stop("Maximum of time.zoom should be lower or equal than the maximum of the time/age column.")}
    if(min(time.zoom) < min(input.data[, "age"])){stop("Minimum of time.zoom should be higher or equal than the minimum of the time/age column.")}
  }

  #testing if lags are regular
  diff.lags <- vector()
  for(i in length(lags):2){
    diff.lags <- c(diff.lags, lags[i] - lags[i-1])
  }
  if(round(sd(diff.lags), 2) != 0){stop("Numeric sequence provided in argument lags is not regular.")}

  #computing data resolution to adjust lags for the annual resolution dataset
  temporal.resolution = input.data[2, time] - input.data[1, time]

  #converting lags from years to cases to be used as lags
  lags.to.rows <- round(lags/temporal.resolution, 0)

  #testing lags.to.rows
  if(length(unique(lags.to.rows)) != length(lags.to.rows)){stop("There is something wrong with the lags argument, I cannot translate lags into row indexes without repeating indexes. Probably lags are not defined in the same units as time/age. Take in mind that lags must be in the same units as the time/age column, and must be multiples of the time resolution (i.e. if time resolution is 100, valid lags are 0, 100, 200, 300, etc)")}

  #adds 0 to lags if it's not
  if(!(0 %in% lags)){
    lags.to.rows <- c(0, lags.to.rows)
    lags <- c(0, lags)
  }

  #if the first sample is the oldest one, lags have to be negative
  if(oldest.sample == "first" | oldest.sample == "First" | oldest.sample == "FIRST"){
    lags.to.rows <- -lags.to.rows
  }

  #if the last sample is the oldest one, lags have to be positive
  if(oldest.sample == "last" | oldest.sample == "Last" | oldest.sample == "LAST"){
    lags.to.rows <- abs(lags.to.rows)
  }

  #apply time.zoom if so
  if(!is.null(time.zoom) & is.vector(time.zoom) & is.numeric(time.zoom) & length(time.zoom) == 2){
    input.data <- input.data[input.data[, time] >= time.zoom[1] & input.data[, time] <= time.zoom[2], ]
  }

  #computing lags of the response
  response.lags <- do.call("merge", lapply(lags.to.rows, function(lag.to.row) lag(zoo::as.zoo(input.data[,response]), lag.to.row)))

  #naming columns
  colnames(response.lags) <- paste("Response", lags, sep = "_")

  #driver lags
  for(driver in drivers){

    driver.lags <- do.call("merge", lapply(lags.to.rows, function(lag.to.row) lag(zoo::as.zoo(input.data[,driver]), lag.to.row)))

    #naming columns
    colnames(driver.lags) <- paste(driver, lags, sep = "_")

    #joining with response lags
    response.lags <- cbind(response.lags, driver.lags)

  }

  #removing NA
  response.lags <- as.data.frame(response.lags)
  response.lags$time <- input.data[, time]
  response.lags <- na.omit(response.lags)
  time <- response.lags$time
  response.lags$time <- NULL

  #scaling data
  if(scale == TRUE){
    response.lags <- data.frame(scale(response.lags), time)
  } else {
    response.lags <- data.frame(response.lags, time)
  }

  return(response.lags)

}
