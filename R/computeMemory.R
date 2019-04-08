#' Quantifies ecological memory with Random Forest
#'
#' @description Takes the oputput of \code{\link{prepareLaggedData}} to fit the following model with Random Forest:
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
#'
#'@usage computeMemory(
#'  lagged.data = NULL,
#'  drivers = NULL,
#'  response = "Response",
#'  add.random = TRUE,
#'  random.mode = "autocorrelated",
#'  repetitions = 10,
#'  subset.response = "none"
#')
#'
#' @param lagged.data a lagged dataset resulting from \code{\link{prepareLaggedData}}. See \code{\link{laggedSimData}} as example.
#' @param drivers a string or vector of strings with variables to be used as predictors in the model (i.e. c("Suitability", "Driver.A"))
#' @param drivers  character vector, names of the numeric columns to be used as predictors in the model.
#' @param add.random if TRUE, adds a random term to the model, useful to assess the significance of the variable importance scores
#' @param random.mode either "white.noise" or "autocorrelated". See details.
#' @param repetitions integer, number of random forest models to fit
#' @param response character string, name of the response variable (typically, "Response_0")
#' @param subset.response character string with values "up", "down" or "none", triggers the subsetting of the input dataset. "up" only models memory on cases where the response's trend is positive, "down" selectes cases with negative trends, and "none" selects all cases.
#' @param min.node.size integer, argument of the \link[ranger]{ranger} function. Minimal number of samples to be allocated in a terminal node. Default is 5.
#' @param num.trees integer, argument of the \link[ranger]{ranger} function. Number of regression trees to be fitted (size of the forest). Default is 2000.
#' @param mtry  integer, argument of the \link[ranger]{ranger} function. Number of variables to possibly split at in each node. Default is 2.
#'
#' @details This function uses the \link[ranger]{ranger} package to fit Random Forest models. It fits the model explained above as many times as defined in the argument \code{repetitions}. To test the statistical significance of the variable importance scores returned by random forest, on each repetition the model is fitted with a different \code{r} (random) term. If \code{random.mode} equals "autocorrelated", the random term will have a temporal autocorrelation, and if it equals "white.noise", it will be a pseudo-random sequence of numbers generated with \code{\link{rnorm}}, with no temporal autocorrelation. The importance of the random sequence (as computed by random forest) is stored for each model run, and used as a benchmark to assess the importance of the other predictors used in the models. Importance values of other predictors that are above the median of the importance of the random term should be interpreted as non-random, and therefore, significant.
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A list with three 4 slots:
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
#'  \item \code{multicollinearity} multicollinearity analysis on the input data performed with \link[HH]{vif}. A vif value higher than 5 indicates that the given variable is highly correlated with other variables.
#' }
#'
#'
#' @seealso \code{\link{computeMemory}}
#'
#' @examples
#'#loading data
#'data(laggedSimData)
#'
#'mem.output <- computeMemory(
#'  lagged.data = laggedSimData,
#'  drivers = "Driver.A,
#'  response = "Response",
#'  add.random = TRUE,
#'  random.mode = "autocorrelated",
#'  repetitions = 10,
#'  subset.response = "none")
#'
#' @export
computeMemory <- function(lagged.data = NULL,
                         drivers = NULL,
                         response = "Response",
                         add.random = TRUE,
                         random.mode = "autocorrelated",
                         repetitions = 10,
                         subset.response = "none",
                         min.node.size = 5,
                         num.trees = 2000,
                         mtry = 2
                         ){

  #function to add random columns to a dataframe for testing purposes
  addRandomColumn <- function(x, random.mode = "autocorrelated"){

    if(random.mode=="autocorrelated"){

      #generating the data
      x$Random = as.vector(rescaleVector(filter(rnorm(nrow(x)),
                                                filter=rep(1, sample(1:floor(nrow(x)/4), 1)),
                                                method="convolution",
                                                circular=TRUE), new.max = 1, new.min=0))
    }

    if(random.mode=="white.noise"){
      x$Random = rnorm(nrow(x))
    }

    return(x)
  }

  #function to rescale vectors between given bounds
  rescaleVector <- function(x = rnorm(100),
                            new.min = 0,
                            new.max = 100,
                            integer = FALSE){


    #data extremes
    old.min = min(x)
    old.max = max(x)


    #SCALING VECTOR
    #----------------------

    x = ((x - old.min) / (old.max - old.min)) * (new.max - new.min) + new.min


    #FORCES VECTOR INTO INTEGER
    #----------------------

    if(integer == TRUE){
      x = floor(x)
    }

    return(x)

  }

  #removing age column
  lagged.data$time = NULL

  #removing variables not in drivers
  if(length(drivers)>1){driver.string <- paste(drivers, collapse="|")} else {driver.string <- drivers}
  string.pattern <- paste(response, "|", driver.string, sep="")
  lagged.data <- lagged.data[, grepl(string.pattern, colnames(lagged.data))]

  #multicollinearity
  multicollinearity <- data.frame(vif(lagged.data[, 2:ncol(lagged.data)]))
  multicollinearity <- data.frame(variable=rownames(multicollinearity), vif=multicollinearity[,1])

  #object to store outputs
  importance.list <- list()
  pseudo.R2 <- vector()
  predictions.list <- list()

  #selects cases where the response goes up or down
  lagged.data$subset.column <- NA

  #response string (checking if there is a 0 or not in the response)
  if(stringr::str_detect(response, "_0")==FALSE){response <- paste(response, "_0", sep="")}
  if(!(response %in% colnames(lagged.data))){stop("Response variable not found in the input data.")}

  #adding labels
  for(i in 1:(nrow(lagged.data)-1)){
    if(lagged.data[i+1, response] > lagged.data[i, response]){lagged.data[i-1, "subset.column"] <- "up"}
    if(lagged.data[i+1, response] < lagged.data[i, response]){lagged.data[i-1, "subset.column"] <- "down"}
    if(lagged.data[i+1, response] == lagged.data[i, response]){lagged.data[i-1, "subset.column"] <- "stable"}
  }

  subset.vector <- lagged.data$subset.column
  lagged.data$subset.column <- NULL

  # cat("Repetition: ")

  #iterating through repetitions
  for(i in 1:repetitions){

    # cat(i, " ")

    #subsetting according to user choice
    if(subset.response == "up"){lagged.data.model <- lagged.data[subset.vector=="up", ]}
    if(subset.response == "down"){lagged.data.model <- lagged.data[subset.vector=="down", ]}
    if(subset.response == "none" | is.null(subset.response)){lagged.data.model <- lagged.data}
    lagged.data.model <- na.omit(lagged.data.model)

    #adding random column
    if(add.random == TRUE){
      lagged.data.model <- addRandomColumn(x=lagged.data)
    }#end of adding random column

    #fitting random forest
    model.output <- ranger::ranger(
      dependent.variable.name = response,
      data = lagged.data.model,
      importance = "permutation",
      scale.permutation.importance = TRUE,
      replace = FALSE,
      splitrule = "variance",
      min.node.size = min.node.size,
      num.trees = num.trees,
      verbose = FALSE,
      mtry = mtry
    )

    #importance
    importance.list[[i]] <- data.frame(t(importance(model.output)))

    #prediction
    prediction <- predict(object=model.output, data=lagged.data.model, type="response")$predictions
    predictions.list[[i]] <- data.frame(t(prediction))

    #pseudo R.squared
    pseudo.R2[i] <- cor(lagged.data.model[, response], prediction)^2

  } #end of repetitions

  #computing stats of repetitions
  #put results together
  importance.df <- do.call("rbind", importance.list)

  #processing output for plotting
  importance.df <- data.frame(Variable=colnames(importance.df),
                              median=apply(importance.df, 2, median),
                              sd=apply(importance.df, 2, sd),
                              min=apply(importance.df, 2, quantile, probs=0.05),
                              max=apply(importance.df, 2, quantile, probs=0.95))

  #separating variable name from lag
  importance.df <- transform(importance.df, test=do.call(rbind, strsplit(as.character(importance.df$Variable),'_',fixed=TRUE)), stringsAsFactors=F)
  importance.df$Variable=NULL
  names(importance.df)[5:6] <- c("Variable", "Lag")

  #removing the word "Random" fromt he lag column
  importance.df[importance.df$Variable == importance.df$Lag, "Lag"] <- 0

  #repeating the random variable
  if(add.random == TRUE){
    importance.df <- rbind(importance.df, importance.df[rep(which(importance.df$Variable=="Random"), each=length(na.omit(unique(importance.df$Lag)))-1),])
    importance.df[importance.df$Variable=="Random", "Lag"] <- na.omit(unique(importance.df$Lag))
  }

  #setting the floor of random at 0
  importance.df[importance.df$Variable=="Random", "min"] <- 0

  #setting the median of random to 0 if it is negative (only important when white.noise is selected)
  if(random.mode=="white.noise" & importance.df[importance.df$Variable=="Random", "median"][1] < 0){importance.df[importance.df$Variable=="Random", "median"] <- 0}

  #variable as factor
  if(add.random==TRUE){
    importance.df$Variable <- factor(importance.df$Variable, levels=c("Response", drivers, "Random"))
  } else {
    importance.df$Variable <- factor(importance.df$Variable, levels=c("Response", drivers))
  }

  #lag to numeric
  importance.df$Lag <- as.numeric(importance.df$Lag)

  #aggregating predictions
  predictions.aggregated <- do.call("rbind", predictions.list)
  predictions.aggregated <- data.frame(variable=colnames(predictions.aggregated),
                                       median=apply(predictions.aggregated, 2, median),
                                       sd=apply(predictions.aggregated, 2, sd),
                                       min=apply(predictions.aggregated, 2, quantile, probs=0.05),
                                       max=apply(predictions.aggregated, 2, quantile, probs=0.95))
  predictions.aggregated$variable <- NULL

  #output
  output.list <- list()
  output.list$memory <- importance.df
  output.list$R2 <- pseudo.R2
  output.list$prediction <- predictions.aggregated
  output.list$multicollinearity <- multicollinearity

  return(output.list)
}
