#' Merges palaeoecological datasets with different time resolution.
#'
#' @description It merges palaeoecological datasets with different time intervals between consecutive samples into a single dataset with samples separated by regular time intervals defined by the user
#'
#'
#' @usage mergePalaeoData<-function(
#' datasets.list = NULL,
#'   time.column = NULL,
#'  interpolation.interval = NULL
#'  )
#'
#' @param datasets.list list of dataframes, as in \code{datasets.list = list(climate = climate.dataframe, pollen = pollen.dataframe)}. The provided dataframes must have an age/time column with the same column name and the same units of time. Non-numeric columns in these dataframes are ignored.
#' @param time.column character string, name of the time/age column of the datasets provided in \code{datasets.list}.
#' @param interpolation.interval temporal resolution of the output data, in the same units as the age/time columns of the input data
#'
#' @details This function fits a \code{\link{loess}} model of the form \code{y ~ x}, where \code{y} is any column given by \code{columns.to.interpolate} and \code{x} is the column given by the \code{time.column} argument. The model is used to interpolate column \code{y} on a regular time series of intervals equal to \code{interpolation.interval}. All columns in every provided dataset go through this process to generate the final data with samples separated by regular time intervals. This function follows the same principles as \code{\link{toRegularTime}}. Non-numeric columns are ignored, and absent from the output dataframe.
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A dataframe with every column of the initial dataset interpolated to a regular time grid of resolution defined by \code{interpolation.interval}. Column names follow the form datasetName.columnName, so the origin of columns can be tracked.
#'
#' @seealso \code{\link{toRegularTime}}
#'
#' @examples
#'#loading data
#'data(pollen)
#'data(climate)
#'
#'x <- mergePalaeoData(
#'  datasets.list = list(
#'    pollen=pollen,
#'    climate=climate
#'  ),
#'  time.column = "age",
#'  interpolation.interval = 0.2
#'  )
#'
#'@export
mergePalaeoData<-function(datasets.list = NULL,
                          time.column = NULL,
                          interpolation.interval = NULL){

  #CHECKING datasets.list
  #######################
  if(inherits(datasets.list, "list") == FALSE){stop("The argument dataset.list must be a list. Try something like: datasets.list = list(climate = climate.dataframe, pollen = pollen.dataframe).")
  } else {
    if(length(datasets.list) < 2){stop("The argument dataset.list only has one object, there is nothing to merge here!")}
  }

  #checking each element in the list
  for(i.list in 1:length(datasets.list)){
    if(inherits(datasets.list[[i.list]], "data.frame") == FALSE){
      stop(paste("Element ", i.list, " in datasets.list is not a dataframe.", sep=""))
    } else {
      if(!(time.column %in% colnames(datasets.list[[i.list]]))){
        stop(paste("Element ", i.list, " in datasets.list does not have a column named ", time.column, sep=""))
      }
    }
  }

  #computing average temporal resolution of the datasets
  message(paste("Argument interpolation.interval is set to ", interpolation.interval, sep=""))
  for(i.list in 1:length(datasets.list)){
     #getting time column
     temp.time <- datasets.list[[i.list]][, time.column]

     temp.diff <- vector()
     for(i.time in 2:length(temp.time)){
       temp.diff <- c(temp.diff, temp.time[i.time] - temp.time[i.time - 1])
     }
     temporal.resolution <- round(mean(temp.diff), 2)
     resolution.increase.factor <- round(temporal.resolution / interpolation.interval, 2)
     message(paste("The average temporal resolution of ", names(datasets.list)[i.list], " is ",temporal.resolution, "; resolution increase factor is ",resolution.increase.factor, sep=""))
     if(resolution.increase.factor > 10){
       message("The resolution increase factor is higher than 10, please consider incrementing the value of the argument interpolation.interval.")
     }
  }

  #computing age ranges
  time.ranges<-sapply(datasets.list, FUN=function(x) range(x[, time.column]))

  #min of maximum times
  min.time<-round(max(time.ranges[1,]), 1)

  #max of minimum times
  max.time<-round(min(time.ranges[2,]), 1)

  #subsetting dataframes in list
  datasets.list<-lapply(datasets.list, function(x) x[x[, time.column] >= min.time & x[, time.column] <= max.time, ])

  #reference data
  reference.time <- seq(min.time, max.time, by=interpolation.interval)

  #looping through datasets to interpolate
  for (dataset.to.interpolate in names(datasets.list)){

    #getting the dataset
    temp <- datasets.list[[dataset.to.interpolate]]

    #removing time/age from the colnames list
    colnames.temp <- colnames(temp)
    colnames.temp <- colnames.temp[which(colnames.temp != time.column)]

    #empty dataset to store interpolation
    temp.interpolated <- data.frame(time=reference.time)

    #iterating through columns
    for (column.to.interpolate in colnames.temp){

      #do not interpolate non-numeric columns
      if (is.numeric(temp[, column.to.interpolate]) == FALSE | column.to.interpolate == time.column){
        next
      }

      #interpolation formula
      interpolation.formula <- as.formula(paste(column.to.interpolate, "~", time.column, sep=" "))

      #iteration through span values untill R-squared equals 0.9985 (R-squared equal to 1 may throw errors)
      span.values <- seq(50/nrow(temp), 5/nrow(temp), by = -0.0005)
      for(span in span.values){

        interpolation.function <- loess(interpolation.formula, data = temp, span = span, control = loess.control(surface = "direct"))

        #check fit
        if(cor(interpolation.function$fitted, temp[, column.to.interpolate]) >=  0.99){break}

      }

      interpolation.result <- predict(interpolation.function, newdata=reference.time, se=FALSE)

      #constraining the range of the interpolation result to the range of the reference data
      interpolation.range<-range(temp[, column.to.interpolate])
      interpolation.result[interpolation.result < interpolation.range[1]] <- interpolation.range[1]
      interpolation.result[interpolation.result > interpolation.range[2]] <- interpolation.range[2]

      #putting the interpolated data back in place
      temp.interpolated[, column.to.interpolate]<-interpolation.result

    }#end of iteration through columns

    #removing the time column
    temp.interpolated[, time.column]=NULL

    #putting the data back in the list
    datasets.list[[dataset.to.interpolate]] <- temp.interpolated

  }#end of iterations through datasets

  #same rows?
  nrow.datasets <- sapply(datasets.list, FUN=function(x) nrow(x))
  if(length(unique(nrow.datasets)) == 1){

    #remove time from all dataframes
    datasets.list<-lapply(datasets.list, function(x) { x[, "time"] <- NULL; x })

    #put dataframes together
    output.dataframe <- do.call("cbind", datasets.list) #changes names

  } else {
    stop("Resulting datasets don't have the same number of rows, there's something wrong with something.")
  }

  #add reference.age
  output.dataframe <- data.frame(age=reference.time, output.dataframe)

  return(output.dataframe)

}
