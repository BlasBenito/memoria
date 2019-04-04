#' Organizes time series data into lags.
#'
#' @description Takes an oputput of \code{\link{prepareLaggedData}} to fit the following model with Random Forest:
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
#'@usage computeMemory = function(lagged.data,
#'  drivers = NULL,
#'  response = "Response",
#'  add.random = TRUE,
#'  random.mode = "autocorrelated",
#'  repetitions = 10,
#'  subset.response = "none"
#')
#'
#' @param lagged.data a lagged dataset resulting from \code{\link{prepareLaggedData}}.
#' @param drivers a string or vector of strings with variables to be used as predictors in the model (i.e. c("Suitability", "Driver.A"))
#' @param drivers  character vector, names of the numeric columns to be used as predictors in the model.
#' @param add.random if TRUE, adds a random term to the model, useful to assess the significance of the variable importance scores
#' @param random.mode: either "white.noise" or "autocorrelated". See details and \code{\link{addRandomColumn}}.
#' @param repetitions: integer, number of random forest models to fit
#' @param response: character string, name of the response variable (typically, "Response_0")
#' @param subset.response: character string with values "up", "down" or "none", triggers the subsetting of the input dataset. "up" only models memory on cases where the response's trend is positive, "down" selectes cases with negative trends, and "none" selects all cases.
#'
#' @details The function returns a dataframe. Column names have the lag number as a suffix. The response variable is identified by changing its name to "Response".
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A dataframe with columns representing time-delayed values of the drivers and the response.
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
computeMemory = function(lagged.data,
                         drivers = NULL,
                         response = "Response",
                         add.random = TRUE,
                         random.mode = "autocorrelated",
                         repetitions = 10,
                         subset.response = "none"
                         ){

  #required libraries
  require(ranger)
  require(stringr)

  #removing age column
  lagged.data$time = NULL

  #removing variables not in drivers
  if(length(drivers)>1){driver.string=paste(drivers, collapse="|")} else {driver.string=drivers}
  string.pattern = paste(response, "|", driver.string, sep="")
  lagged.data = lagged.data[, grepl(string.pattern, colnames(lagged.data))]

  #multicollinearity
  multicollinearity = data.frame(vif(lagged.data[, 2:ncol(lagged.data)]))
  multicollinearity = data.frame(variable=rownames(multicollinearity), vif=multicollinearity[,1])

  #object to store outputs
  importance.list = list()
  pseudo.R2 = vector()
  predictions.list = list()

  #selects cases where the response goes up or down
  lagged.data$subset.column = NA

  #response string (checking if there is a 0 or not in the response)
  if(str_detect(response, "_0")==FALSE){response = paste(response, "_0", sep="")}
  if(!(response %in% colnames(lagged.data))){stop("Response variable not found in the input data.")}

  #adding labels
  for(i in 1:(nrow(lagged.data)-1)){
    if(lagged.data[i+1, response] > lagged.data[i, response]){lagged.data[i-1, "subset.column"] = "up"}
    if(lagged.data[i+1, response] < lagged.data[i, response]){lagged.data[i-1, "subset.column"] = "down"}
    if(lagged.data[i+1, response] == lagged.data[i, response]){lagged.data[i-1, "subset.column"] = "stable"}
  }

  subset.vector = lagged.data$subset.column
  lagged.data$subset.column = NULL

  # cat("Repetition: ")

  #iterating through repetitions
  for(i in 1:repetitions){

    # cat(i, " ")

    #subsetting according to user choice
    if(subset.response == "up"){lagged.data.model = lagged.data[subset.vector=="up", ]}
    if(subset.response == "down"){lagged.data.model = lagged.data[subset.vector=="down", ]}
    if(subset.response == "none" | is.null(subset.response)){lagged.data.model = lagged.data}
    lagged.data.model = na.omit(lagged.data.model)

    #adding random column
    if(add.random == TRUE){
      lagged.data.model = addRandomColumn(x=lagged.data)
    }#end of adding random column

    #fitting random forest
    model.output = ranger(
      dependent.variable.name = response,
      data = lagged.data.model,
      importance = "permutation",
      scale.permutation.importance = TRUE,
      replace=FALSE,
      splitrule = "variance",
      min.node.size = 5,
      num.trees = 2000,
      num.threads = 8,
      verbose = FALSE,
      mtry = 2
    )

    #importance
    importance.list[[i]] = data.frame(t(importance(model.output)))

    #prediction
    prediction = predict(object=model.output, data=lagged.data.model, type="response")$predictions
    predictions.list[[i]] = data.frame(t(prediction))

    #pseudo R.squared
    pseudo.R2[i] = cor(lagged.data.model[, response], prediction)^2

  } #end of repetitions

  #computing stats of repetitions
  #put results together
  importance.df = do.call("rbind", importance.list)

  #processing output for plotting
  importance.df = data.frame(Variable=colnames(importance.df), median=apply(importance.df, 2, median), sd=apply(importance.df, 2, sd), min=apply(importance.df, 2, quantile, probs=0.05), max=apply(importance.df, 2, quantile, probs=0.95))

  #separating variable name from lag
  importance.df = transform(importance.df, test=do.call(rbind, strsplit(as.character(importance.df$Variable),'_',fixed=TRUE)), stringsAsFactors=F)
  importance.df$Variable=NULL
  names(importance.df)[5:6] = c("Variable", "Lag")

  #removing the word "Random" fromt he lag column
  importance.df[importance.df$Variable == importance.df$Lag, "Lag"] = 0

  #repeating the random variable
  if(add.random == TRUE){
    importance.df = rbind(importance.df, importance.df[rep(which(importance.df$Variable=="Random"), each=length(na.omit(unique(importance.df$Lag)))-1),])
    importance.df[importance.df$Variable=="Random", "Lag"] = na.omit(unique(importance.df$Lag))
  }

  #setting the floor of random at 0
  importance.df[importance.df$Variable=="Random", "min"] = 0

  #setting the median of random to 0 if it is negative (only important when white.noise is selected)
  if(random.mode=="white.noise" & importance.df[importance.df$Variable=="Random", "median"][1] < 0){importance.df[importance.df$Variable=="Random", "median"] = 0}

  #variable as factor
  if(add.random==TRUE){
    importance.df$Variable = factor(importance.df$Variable, levels=c("Response", drivers, "Random"))
  } else {
    importance.df$Variable = factor(importance.df$Variable, levels=c("Response", drivers))
  }

  #lag to numeric
  importance.df$Lag = as.numeric(importance.df$Lag)

  #aggregating predictions
  predictions.aggregated = do.call("rbind", predictions.list)
  predictions.aggregated = data.frame(variable=colnames(predictions.aggregated), median=apply(predictions.aggregated, 2, median), sd=apply(predictions.aggregated, 2, sd), min=apply(predictions.aggregated, 2, quantile, probs=0.05), max=apply(predictions.aggregated, 2, quantile, probs=0.95))
  predictions.aggregated$variable = NULL

  #output
  output.list = list()
  output.list$memory = importance.df
  output.list$R2 = pseudo.R2
  output.list$prediction = predictions.aggregated
  output.list$multicollinearity = multicollinearity

  return(output.list)
}
