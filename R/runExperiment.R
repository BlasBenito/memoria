#' Computes ecological memory patterns on simulated pollen curves produced by the \code{virtualPollen} library.
#'
#' @description Applies \code{\link{computeMemory}} to assess ecological memory on a large set of virtual pollen curves.
#'
#'
#'@usage runExperiment(
#'  simulations.file = NULL,
#'  selected.rows = 1,
#'  selected.columns = 1,
#'  parameters.file = NULL,
#'  parameters.names = NULL,
#'  sampling.names = NULL,
#'  driver.column = NULL,
#'  response.column = "Response_0",
#'  subset.response = "none",
#'  time.column = "Time",
#'  time.zoom = NULL,
#'  lags = NULL,
#'  repetitions = 10
#'  )
#'
#' @param simulations.file list of dataframes, output of  the function \code{simulatePopulation} of the \code{virtualPollen} library.
#' @param selected.rows numeric vector, rows (virtual taxa) of \code{simulations.file} to be analyzed.
#' @param selected.columns numeric.vector, columns (experiment treatments) of \code{simulations.file} to be analyzed.
#' @param parameters.file dataframe of simulation parameters.
#' @param parameters.names vector of character strings with names of traits and niche features from \code{parameters.file} to be included in the analysis (i.e. c("maximum.age", "fecundity", "niche.A.mean", "niche.A.sd"))
#' @param sampling.names vector of character strings with the names of the columns of \code{simulations.file}.
#' @param driver.column vector of character strings, names of the columns to be considered as drivers (generally, one of "Suitability", "Driver.A", "Driver.B).
#' @param response.column character string defining the response variable, typically "Response_0".
#' @param subset.response character string, one of "up", "down" or "none", triggers the subsetting of the input dataset. "up" only models ecological memory on cases where the response's trend is positive, "down" selectes cases with negative trends, and "none" selects all cases.
#' @param time.column character string, name of the time/age column. Usually, "Time".
#' @param time.zoom numeric vector with two numbers defining the time/age extremes of the time interval of interest.
#' @param lags ags numeric vector of positive integers, lags to be used in the equation. Generally, a regular sequence of numbers, in the same units as \code{time}. The use \code{\link{seq}} to define it is highly recommended. If 0 is absent from lags, it is added automatically to allow the consideration of a concurrent effect. Lags should take into account the temporal resolution of the data, and be aligned to it. For example, if the interval between consecutive samples is 100 years, lags should be something like \code{0, 100, 200, 300}. Lags can also be multiples of the time resolution, such as \code{0, 200, 400, 600} (in the case time resolution is 100 years).
#' @param repetitions integer, number of random forest models to fit.
#'
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A list with 2 slots:
#'  \itemize{
#'  \item \code{names} matrix of character strings, with as many rows and columns as \code{simulations.file}. Each cell holds a simulation name to be used afterwards, when plotting the results of the ecological memory analysis.
#'  \item \code{output} a list with as many columns and columns as \code{simulations.file}. Each slot holds a an output of \code{\link{computeMemory}}.
#'  \itemize{
#'  \item \code{memory} dataframe with five columns:
#'     \itemize{
#'       \item \code{Variable} character, names and lags of the different variables used to model ecological memory.
#'       \item \code{median} numeric, median importance across \code{repetitions} of the given \code{Variable} according to Random Forest.
#'       \item \code{sd} numeric, standard deviation of the importance values of the given \code{Variable} across \code{repetitions}.
#'       \item \code{min} and \code{max} numeric, percentiles 0.05 and 0.95 of importance values of the given \code{Variable} across \code{repetitions}.
#'     }
#'  \item \code{R2} vector, values of pseudo R-squared value obtained for the Random Forest model fitted on each repetition. Pseudo R-squared is the Pearson correlation beteween the observed and predicted data.
#'  \item \code{prediction} dataframe, with the same columns as the dataframe in the slot \code{memory}, with the median and confidence intervals of the predictions of all random forest models fitted.
#'  \item \code{multicollinearity} multicollinearity analysis on the input data performed with \code{\link[HH]{vif}}. A vif value higher than 5 indicates that the given variable is highly correlated with other variables.
#' }
#' }
#'
#'
#' @seealso \code{\link{computeMemory}}
#'
#' @export
runExperiment <- function(simulations.file = NULL,
                         selected.rows = 1,
                         selected.columns = 1,
                         parameters.file = NULL,
                         parameters.names = NULL,
                         sampling.names = NULL,
                         driver.column = NULL,
                         response.column = "Response_0",
                         subset.response="none",
                         time.column = "Time",
                         time.zoom = NULL,
                         lags = NULL,
                         repetitions = 10){

  #subsetting simulations file
  #checking if it has one column only
  if(selected.columns == 1){
    data.list <- simulations.file[selected.rows]
    if(length(sampling.names) > 1){
      sampling.names <- sampling.names[1]
    }
  } else {
    data.list <- simulations.file[selected.rows, selected.columns]
  }

  #template for the output list
  output.list <- data.list

  #subsetting parameters file
  parameters.list <- parameters.file[selected.rows, ]

  #generating names matrix
  #-----------------------
  #getting parameter names and values
  if(length(parameters.names == 1)){

    temp.parameters <- data.frame(parameters.list[, parameters.names])
    colnames(temp.parameters) <- parameters.names

  } else {

    temp.parameters <- parameters.list[, parameters.names]

  }

  #joining parameter name and parameter values
  for(current.column in 1:ncol(temp.parameters)){

    temp.parameters[,current.column] <- paste(colnames(temp.parameters)[current.column], ": ", temp.parameters[,current.column], sep = "")

  }

  #different parameters together
  if(length(parameters.names) > 1){
    temp.parameters <- data.frame(parameters = apply(temp.parameters[ , ] , 1 , paste , collapse = "; " ))
  }

  #to matrix
  temp.parameters <- as.matrix(temp.parameters)

  #parameters with sampling names
  sampling.names.matrix <- matrix(rep(sampling.names, length(selected.rows)), nrow = length(selected.rows), ncol = length(selected.columns), byrow = TRUE)

  #these are the simulation names
  simulation.names <- matrix(paste(temp.parameters, sampling.names.matrix, sep = "; sampling: "), nrow = length(selected.rows), ncol = length(selected.columns), byrow = FALSE)

  #RUNNING ANALYSIS FOR EACH CASE
  if(is.null(dim(data.list))){
    list.rows<-length(data.list)
    list.columns<-1
  } else {
    list.rows<-dim(data.list)[1]
    list.columns<-dim(data.list)[2]
  }

  for(data.list.row in 1:list.rows){
    for(data.list.column in 1:list.columns){

      #info
      #cat(paste("\n Row: ", data.list.row, "; Column: ", data.list.column, "; Model: ", simulation.names[data.list.row, data.list.column], "\n", sep = ""))

      #retrieves data
      if(list.columns > 1){
        simulation.data <- data.list[[data.list.row, data.list.column]]

      } else {

        simulation.data <- data.list[[data.list.row]]
      }

      #adds lags
      simulation.data.lagged <- prepareLaggedData(input.data = simulation.data,
                                                 response = response.column,
                                                 drivers = driver.column,
                                                 time = time.column,
                                                 lags = lags,
                                                 time.zoom = time.zoom)

      #fitting model
      simulation.data.memory <- computeMemory(lagged.data = simulation.data.lagged,
                                             drivers = driver.column,
                                             repetitions = repetitions,
                                             add.random = TRUE,
                                             random.mode = "autocorrelated",
                                             response = "Response",
                                             subset.response = subset.response)

      #saves result
      if(list.columns > 1){
        output.list[[data.list.row, data.list.column]] <- simulation.data.memory
      } else {
        output.list[[data.list.row]] <- simulation.data.memory
      }

      #clears RAM space
      gc()

    } #end of iterations through rows
  } #end of iterations through columns

  list.to.return <- list()
  list.to.return$names <- simulation.names
  list.to.return$output <- output.list
  return(list.to.return)

} #end of function
