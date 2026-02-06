#' Quantifies ecological memory with Random Forest.
#'
#' @description Takes the output of \code{\link{prepareLaggedData}} to fit the following model with Random Forest:
#'
#'  \eqn{p_{t} = p_{t-1} +...+ p_{t-n} + d_{t} + d_{t-1} +...+ d_{t-n} + r}
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
#'  \item \eqn{r} represents a column of random values, used to test the significance of the variable importance scores returned by Random Forest.
#' }
#'
#' @param lagged.data a lagged dataset resulting from \code{\link{prepareLaggedData}}. See \code{\link{palaeodataLagged}} as example. Default: \code{NULL}.
#' @param response character string, name of the response variable. Not required if `lagged.data` was generated with [prepareLaggedData]. Default: \code{NULL}.
#' @param drivers  a character string or character vector with variables to be used as predictors in the model. Not required if `lagged.data` was generated with [prepareLaggedData]. \strong{Important:} \code{drivers} names must not have the character "__" (double underscore). Default: \code{NULL}.
#' @param random.mode either "none", "white.noise" or "autocorrelated". See details. Default: \code{"autocorrelated"}.
#' @param repetitions integer, number of random forest models to fit. Default: \code{10}.
#' @param subset.response character string with values "up", "down" or "none", triggers the subsetting of the input dataset. "up" only models memory on cases where the response's trend is positive, "down" selects cases with negative trends, and "none" selects all cases. Default: \code{"none"}.
#' @param num.threads integer, number of cores \link[ranger]{ranger} can use for multithreading. Default: \code{2}.
#'
#' @details This function uses the \link[ranger]{ranger} package to fit Random Forest models. Please, check the help of the \link[ranger]{ranger} function to better understand how Random Forest is parameterized in this package. This function fits the model explained above as many times as defined in the argument \code{repetitions}.
#'
#' To test the statistical significance of the variable importance scores returned by random forest, on each repetition the model is fitted with a different \code{r} (random) term, unless \code{random.mode = "none"}. If \code{random.mode} equals "autocorrelated", the random term will have a temporal autocorrelation, and if it equals "white.noise", it will be a pseudo-random sequence of numbers generated with \code{\link{rnorm}}, with no temporal autocorrelation. The importance of the random sequence in predicting the response is stored for each model run, and used as a benchmark to assess the importance of the other predictors.
#'
#' Importance values of other predictors that are above the median of the importance of the random term should be interpreted as non-random, and therefore, significant.
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A list with 5 slots:
#'  \itemize{
#'  \item \code{response} character, response variable name.
#'  \item \code{drivers} character vector, driver variable names.
#'  \item \code{memory} dataframe with six columns:
#'     \itemize{
#'       \item \code{median} numeric, median importance across \code{repetitions} of the given \code{variable} according to Random Forest.
#'       \item \code{sd} numeric, standard deviation of the importance values of the given \code{variable} across \code{repetitions}.
#'       \item \code{min} and \code{max} numeric, percentiles 0.05 and 0.95 of importance values of the given \code{variable} across \code{repetitions}.
#'       \item \code{variable} character, names of the different variables used to model ecological memory.
#'       \item \code{lag} numeric, time lag values.
#'     }
#'  \item \code{R2} vector, values of pseudo R-squared value obtained for the Random Forest model fitted on each repetition. Pseudo R-squared is the Pearson correlation between the observed and predicted data.
#'  \item \code{prediction} dataframe, with the same columns as the dataframe in the slot \code{memory}, with the median and confidence intervals of the predictions of all random forest models fitted.
#' }
#'
#'
#' @seealso \code{\link{plotMemory}}, \code{\link{extractMemoryFeatures}}
#'
#' @references
#' \itemize{
#'   \item Wright, M. N. & Ziegler, A. (2017). ranger: A fast implementation of random forests for high dimensional data in C++ and R. J Stat Softw 77:1-17. \url{https://doi.org/10.18637/jss.v077.i01}.
#'   \item Breiman, L. (2001). Random forests. Mach Learn, 45:5-32. \url{https://doi.org/10.1023/A:1010933404324}.
#'   \item Hastie, T., Tibshirani, R., Friedman, J. (2009). The Elements of Statistical Learning. Springer, New York. 2nd edition.
#'   }
#'
#' @examples
#' \donttest{
#'#loading data
#'data(palaeodataLagged)
#'
#'# Simplified call - response and drivers auto-detected from attributes
#'memory.output <- computeMemory(
#'  lagged.data = palaeodataLagged,
#'  random.mode = "autocorrelated",
#'  repetitions = 10
#')
#'
#'str(memory.output)
#'str(memory.output$memory)
#'
#'#plotting output
#'plotMemory(memory.output = memory.output)
#'}
#' @family memoria
#' @export
computeMemory <- function(
  lagged.data = NULL,
  response = NULL,
  drivers = NULL,
  random.mode = "autocorrelated",
  repetitions = 10,
  subset.response = "none",
  num.threads = 2
) {
  #checking data
  if (!inherits(lagged.data, "data.frame")) {
    stop("The input data must be a dataframe produced by prepareLaggedData.")
  }

  if (!is.null(attributes(lagged.data)$response)) {
    response <- attributes(lagged.data)$response
  } else if (is.null(response)) {
    stop("Argument 'response' cannot be NULL.")
  }

  if (!is.null(attributes(lagged.data)$drivers)) {
    drivers <- attributes(lagged.data)$drivers
  } else if (is.null(drivers)) {
    stop("Argument 'drivers' cannot be NULL.")
  }

  # Validate that variable names do not contain '__' (double underscore)
  # as this would corrupt the strsplit() parsing later

  all_vars <- c(response, drivers)
  invalid_vars <- all_vars[grepl("__", all_vars, fixed = TRUE)]
  if (length(invalid_vars) > 0) {
    stop(
      "Variable names cannot contain '__' (double underscore): ",
      paste(invalid_vars, collapse = ", ")
    )
  }

  random.mode <- match.arg(
    arg = random.mode,
    choices = c(
      "autocorrelated",
      "white.noise",
      "none"
    ),
    several.ok = FALSE
  )

  #checking repetitions
  if (!is.numeric(repetitions)) {
    repetitions <- 10
  }
  if (!is.integer(repetitions)) {
    repetitions <- as.integer(repetitions)
  }

  #function to add random columns to a dataframe for testing purposes
  addRandomColumn <- function(x, random.mode = "autocorrelated") {
    if (random.mode == "autocorrelated") {
      #generating the data
      x$random <- as.vector(rescaleVector(
        stats::filter(
          rnorm(nrow(x)),
          filter = rep(1, sample.int(floor(nrow(x) / 4), 1)),
          method = "convolution",
          circular = TRUE
        ),
        new.max = 1,
        new.min = 0
      ))
    }

    if (random.mode == "white.noise") {
      x$random <- rnorm(nrow(x))
    }

    return(x)
  }

  #function to rescale vectors between given bounds
  rescaleVector <- function(
    x = rnorm(100),
    new.min = 0,
    new.max = 100
  ) {
    #data extremes
    old.min <- min(x)
    old.max <- max(x)

    ((x - old.min) / (old.max - old.min)) * (new.max - new.min) + new.min
  }

  #removing time column
  lagged.data$time <- NULL

  #removing variables not in drivers
  if (length(drivers) > 1) {
    driver.string <- paste(drivers, collapse = "|")
  } else {
    driver.string <- drivers
  }
  string.pattern <- paste(response, "|", driver.string, sep = "")
  lagged.data <- lagged.data[, grepl(string.pattern, colnames(lagged.data))]

  #object to store outputs
  importance.list <- list()
  pseudo.R2 <- vector()
  predictions.list <- list()

  #selects cases where the response goes up or down
  lagged.data$subset.column <- NA

  #response string (checking if there is a 0 or not in the response)
  if (!grepl("__0", response, fixed = TRUE)) {
    response <- paste(response, "__0", sep = "")
  }
  if (!(response %in% colnames(lagged.data))) {
    stop("Variable '", response, "' not found in the input data.")
  }

  #adding labels
  for (i in 1:(nrow(lagged.data) - 1)) {
    if (lagged.data[i + 1, response] > lagged.data[i, response]) {
      lagged.data[i, "subset.column"] <- "up"
    }
    if (lagged.data[i + 1, response] < lagged.data[i, response]) {
      lagged.data[i, "subset.column"] <- "down"
    }
    if (lagged.data[i + 1, response] == lagged.data[i, response]) {
      lagged.data[i, "subset.column"] <- "stable"
    }
  }

  subset.vector <- lagged.data$subset.column
  lagged.data$subset.column <- NULL

  #iterating through repetitions
  for (i in 1:repetitions) {
    set.seed(i)

    #subsetting according to user choice
    if (subset.response == "up") {
      lagged.data.model <- lagged.data[subset.vector == "up", ]
    } else if (subset.response == "down") {
      lagged.data.model <- lagged.data[subset.vector == "down", ]
    } else if (subset.response == "none" || is.null(subset.response)) {
      lagged.data.model <- lagged.data
    }
    lagged.data.model <- na.omit(lagged.data.model)

    #adding random column
    if (random.mode != "none") {
      lagged.data.model <- addRandomColumn(
        x = lagged.data.model,
        random.mode = random.mode
      )
    }

    #fitting random forest
    model.output <- ranger::ranger(
      dependent.variable.name = response,
      data = lagged.data.model,
      importance = "permutation",
      scale.permutation.importance = TRUE,
      replace = FALSE,
      splitrule = "variance",
      min.node.size = 5,
      num.trees = 500,
      verbose = FALSE,
      seed = i,
      num.threads = num.threads
    )

    #importance
    importance.list[[i]] <- data.frame(t(ranger::importance(model.output)))

    #prediction
    prediction <- predict(
      object = model.output,
      data = lagged.data.model,
      type = "response"
    )$predictions
    predictions.list[[i]] <- data.frame(t(prediction))

    #pseudo R.squared
    pseudo.R2[i] <- cor(lagged.data.model[, response], prediction)^2
  } #end of repetitions

  #computing stats of repetitions
  #put results together
  importance.df <- do.call("rbind", importance.list)

  #processing output for plotting
  importance.df <- data.frame(
    variable = colnames(importance.df),
    median = apply(importance.df, 2, median),
    sd = apply(importance.df, 2, sd),
    min = apply(importance.df, 2, quantile, probs = 0.05),
    max = apply(importance.df, 2, quantile, probs = 0.95)
  )

  #separating variable name from lag
  importance.df <- transform(
    importance.df,
    test = do.call(
      rbind,
      strsplit(as.character(importance.df$variable), "__", fixed = TRUE)
    ),
    stringsAsFactors = FALSE
  )
  importance.df$variable <- NULL
  names(importance.df)[5:6] <- c("variable", "lag")
  rownames(importance.df) <- NULL

  #removing the word "random" from the lag column
  importance.df[importance.df$lag == "random", "lag"] <- 0

  #repeating the random variable
  if (random.mode != "none") {
    importance.df <- rbind(
      importance.df,
      importance.df[
        rep(
          which(importance.df$variable == "random"),
          each = length(na.omit(unique(importance.df$lag))) - 1
        ),
      ]
    )
    importance.df[importance.df$variable == "random", "lag"] <- na.omit(unique(
      importance.df$lag
    ))
  }

  #setting the median of random to 0 if it is negative (only important when white.noise is selected)
  if (
    random.mode == "white.noise" &&
      importance.df[importance.df$variable == "random", "median"][1] < 0
  ) {
    importance.df[importance.df$variable == "random", "median"] <- 0
  }

  #variable as factor
  response <- gsub(
    pattern = "__0",
    replacement = "",
    x = response,
    fixed = TRUE
  )
  if (random.mode != "none") {
    importance.df$variable <- factor(
      importance.df$variable,
      levels = c(response, drivers, "random")
    )
  } else {
    importance.df$variable <- factor(
      importance.df$variable,
      levels = c(response, drivers)
    )
  }

  #lag to numeric
  importance.df$lag <- as.numeric(importance.df$lag)

  #aggregating predictions
  predictions.aggregated <- do.call("rbind", predictions.list)
  predictions.aggregated <- data.frame(
    variable = colnames(predictions.aggregated),
    median = apply(predictions.aggregated, 2, median),
    sd = apply(predictions.aggregated, 2, sd),
    min = apply(predictions.aggregated, 2, quantile, probs = 0.05),
    max = apply(predictions.aggregated, 2, quantile, probs = 0.95)
  )
  predictions.aggregated$variable <- NULL

  #output
  output.list <- list()
  output.list$response <- response
  output.list$drivers <- drivers
  output.list$memory <- importance.df
  output.list$R2 <- pseudo.R2
  output.list$prediction <- predictions.aggregated

  return(output.list)
}
