#' Computes ecological memory patterns on simulated pollen curves produced by the \code{virtualPollen} package.
#'
#' @description Applies \code{\link{computeMemory}} to assess ecological memory on a large set of virtual pollen curves.
#'
#'
#' @param simulations.file List of dataframes produced by \code{virtualPollen::simulatePopulation}.
#'   Each list element is a time series dataframe for one virtual taxon. Can be a 1D list (one
#'   sampling scheme) or a 2D matrix-like list (rows = taxa, columns = sampling schemes).
#'   See \code{virtualPollen::simulation} for an example. Default: \code{NULL}.
#' @param selected.rows Numeric vector indicating which virtual taxa (list elements)
#'   from \code{simulations.file} to analyze. For example, \code{c(1, 3)} analyzes
#'   the 1st and 3rd taxa. Default: \code{NULL} (analyzes all taxa).
#' @param selected.columns Numeric vector indicating which sampling schemes (columns)
#'   from \code{simulations.file} to analyze. Only relevant when \code{simulations.file}
#'   has a 2D structure with multiple sampling schemes. Default: \code{NULL} (uses the
#'   first sampling scheme only).
#' @param parameters.file Dataframe of simulation parameters produced by
#'   \code{virtualPollen::parametersDataframe}, with one row per virtual taxon.
#'   Rows must align with \code{simulations.file}. See \code{virtualPollen::parameters}
#'   for an example. Default: \code{NULL}.
#' @param parameters.names Character vector of column names from \code{parameters.file}
#'   to include in output labels. These help identify which simulation settings produced
#'   each result. Example: \code{c("maximum.age", "fecundity")}. Default: \code{NULL}.
#' @param driver.column Character vector of column names representing environmental
#'   drivers in the simulation dataframes. Common choices: \code{"Driver.A"},
#'   \code{"Driver.B"}, or \code{"Suitability"}. Default: \code{NULL}.
#' @param response.column Character string naming the response variable column in the
#'   simulation dataframes. Use \code{"Pollen"} for pollen abundance from
#'   \code{virtualPollen::simulation}. Default: \code{"Pollen"}.
#' @param subset.response character string, one of "up", "down" or "none", triggers the subsetting of the input dataset. "up" only models ecological memory on cases where the response's trend is positive, "down" selects cases with negative trends, and "none" selects all cases. Default: \code{"none"}.
#' @param time.column character string, name of the time/age column. Usually, "Time". Default: \code{"Time"}.
#' @param time.zoom numeric vector with two numbers defining the time/age extremes of the time interval of interest. Default: \code{NULL}.
#' @param lags numeric vector, lags to be used in the equation, in the same units as \code{time}. The use of \code{\link{seq}} to define it is highly recommended. If 0 is absent from lags, it is added automatically to allow the consideration of a concurrent effect. Lags should be aligned to the temporal resolution of the data. For example, if the interval between consecutive samples is 100 years, lags should be something like \code{0, 100, 200, 300}. Lags can also be multiples of the time resolution, such as \code{0, 200, 400, 600} (when time resolution is 100 years). Default: \code{NULL}.
#' @param repetitions integer, number of random forest models to fit. Default: \code{10}.
#'
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A list with 2 slots:
#'  \itemize{
#'  \item \code{names} matrix of character strings, with as many rows and columns as \code{simulations.file}. Each cell holds a simulation name to be used afterwards, when plotting the results of the ecological memory analysis.
#'  \item \code{output} a list with as many rows and columns as \code{simulations.file}. Each slot holds a an output of \code{\link{computeMemory}}.
#'  \itemize{
#'  \item \code{memory} dataframe with five columns:
#'     \itemize{
#'       \item \code{Variable} character, names and lags of the different variables used to model ecological memory.
#'       \item \code{median} numeric, median importance across \code{repetitions} of the given \code{Variable} according to Random Forest.
#'       \item \code{sd} numeric, standard deviation of the importance values of the given \code{Variable} across \code{repetitions}.
#'       \item \code{min} and \code{max} numeric, percentiles 0.05 and 0.95 of importance values of the given \code{Variable} across \code{repetitions}.
#'     }
#'  \item \code{R2} vector, values of pseudo R-squared value obtained for the Random Forest model fitted on each repetition. Pseudo R-squared is the Pearson correlation between the observed and predicted data.
#'  \item \code{prediction} dataframe, with the same columns as the dataframe in the slot \code{memory}, with the median and confidence intervals of the predictions of all random forest models fitted.
#'  \item \code{multicollinearity} multicollinearity analysis on the input data performed with \code{\link[collinear]{vif_df}}. A vif value higher than 5 indicates that the given variable is highly correlated with other variables.
#' }
#' }
#'
#'
#' @seealso \code{\link{computeMemory}}
#' @family virtualPollen
#' @export
runExperiment <- function(
  simulations.file = NULL,
  selected.rows = NULL,
  selected.columns = NULL,
  parameters.file = NULL,
  parameters.names = NULL,
  driver.column = NULL,
  response.column = "Pollen",
  subset.response = "none",
  time.column = "Time",
  time.zoom = NULL,
  lags = NULL,
  repetitions = 10
) {
  # Handle NULL defaults
  if (is.null(selected.columns)) {
    selected.columns <- 1
  }

  if (is.null(selected.rows)) {
    if (is.null(dim(simulations.file))) {
      selected.rows <- seq_len(length(simulations.file))
    } else {
      selected.rows <- seq_len(dim(simulations.file)[1])
    }
  }

  #subsetting simulations file
  #checking if it has one column only
  if (length(selected.columns) == 1) {
    data.list <- simulations.file[selected.rows]
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
  if (length(parameters.names) == 1) {
    temp.parameters <- data.frame(parameters.list[, parameters.names])
    colnames(temp.parameters) <- parameters.names
  } else {
    temp.parameters <- parameters.list[, parameters.names]
  }

  #joining parameter name and parameter values
  for (current.column in seq_len(ncol(temp.parameters))) {
    temp.parameters[, current.column] <- paste(
      colnames(temp.parameters)[current.column],
      ": ",
      temp.parameters[, current.column],
      sep = ""
    )
  }

  #different parameters together
  if (length(parameters.names) > 1) {
    temp.parameters <- data.frame(
      parameters = apply(temp.parameters[,], 1, paste, collapse = "; ")
    )
  }

  #to matrix
  temp.parameters <- as.matrix(temp.parameters)

  #these are the simulation names
  simulation.names <- matrix(
    temp.parameters,
    nrow = length(selected.rows),
    ncol = length(selected.columns),
    byrow = FALSE
  )

  #RUNNING ANALYSIS FOR EACH CASE
  if (is.null(dim(data.list))) {
    list.rows <- length(data.list)
    list.columns <- 1
  } else {
    list.rows <- dim(data.list)[1]
    list.columns <- dim(data.list)[2]
  }

  for (data.list.row in 1:list.rows) {
    for (data.list.column in 1:list.columns) {
      #info
      #cat(paste("\n Row: ", data.list.row, "; Column: ", data.list.column, "; Model: ", simulation.names[data.list.row, data.list.column], "\n", sep = ""))

      #retrieves data
      if (list.columns > 1) {
        simulation.data <- data.list[[data.list.row, data.list.column]]
      } else {
        simulation.data <- data.list[[data.list.row]]
      }

      #adds lags
      simulation.data.lagged <- lagTimeSeries(
        input.data = simulation.data,
        response = response.column,
        drivers = driver.column,
        time = time.column,
        lags = lags,
        time.zoom = time.zoom
      )

      #fitting model
      simulation.data.memory <- computeMemory(
        lagged.data = simulation.data.lagged,
        drivers = driver.column,
        repetitions = repetitions,
        random.mode = "autocorrelated",
        response = "Response",
        subset.response = subset.response
      )

      #saves result
      if (list.columns > 1) {
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
}
