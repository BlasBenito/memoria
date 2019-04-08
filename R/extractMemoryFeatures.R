#' Extracts ecological memory features on the output of \code{\link{computeMemory}}.
#'
#' @description It computes the following features of the ecological memory patterns returned by \code{\link{computeMemory}}:
#' \itemize{
#'    \item \code{memory strength} maximum difference in relative importance between each component (endogenous, exogenous, and concurrent) and the median of the random component. This is computed for exogenous, endogenous, and concurrent effect.
#'     \item \code{memory length} proportion of lags over which the importance of a memory component is above the median of the random component. This is only computed for endogenous and exogenous memory.
#' \item \code{dominance} proportion of the lags above the median of the random term over which a memory component has a higher importance than the other component. This is only computed for endogenous and exogenous memory.
#' }
#'
#'
#'@usage extractMemoryFeatures(
#'  analysis.output = NULL,
#'  exogenous.component = NULL,
#'  endogenous.component = NULL,
#'  sampling.subset = NULL
#'  )
#'
#' @param analysis.output dataframe, output of \code{\link{computeMemory}}.
#' @param exogenous.component character string, name of the variable defining the exogenous component.
#' @param endogenous.component character string, string, name of the variable defining the endogenous component.
#' @param sampling.subset only used when analysis.output is the result of runExperiment(). String with the dataset type, one of: "Annual", "1cm", "2cm", "6cm", "10cm".
#'
#' @details
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A list with three 4 slots:
#'
#' @seealso \code{\link{computeMemory}}
#'
#' @examples
#'
#' @export
extractMemoryFeatures <- function(analysis.output,
                                  exogenous.component,
                                  endogenous.component,
                                  sampling.subset=NULL){

  #entry point
  x <- analysis.output

  #checking if it is a memory object or not
  if(is.null(x$memory)){

    #factors to character
    x$label = as.character(x$label)
    x$Variable = as.character(x$Variable)

    #subsetting by sampling
    if(!is.null(sampling.subset)){
      x=x[x$sampling==sampling.subset, ]
    }

    #identifying available groups
    taxa=unique(x$label)
    sampling=unique(x$sampling)

    #memory object switch to false
    is.memory.object=FALSE

  } else {
    #if it is a memory object
    taxa=1
    is.memory.object=TRUE

    #if there is no sampling column, we add it
    if(is.null(x$sampling)){
      x$sampling <- "this"
      sampling.subset <- "this"

      #identifying available groups (repeated code because I am sick of this shit)
      taxa=unique(x$label)
      sampling=unique(x$sampling)
    }

  }

  #dataframe to store results
  nas=rep(NA, (length(taxa) * length(sampling)))
  output.df=data.frame(label=nas, strength.endogenous=nas, strength.exogenous=nas, strength.concurrent=nas, length.endogenous=nas, length.exogenous=nas, dominance.endogenous=nas, dominance.exogenous=nas, maximum.age=nas, fecundity=nas, niche.mean=nas, niche.sd=nas, sampling=nas, stringsAsFactors = FALSE)

  #row counter
  row.counter = 0

  #iterating through taxa and sampling
  for(taxon in taxa){
    for(samp in sampling){

      #+1 to the row counter
      row.counter = row.counter + 1

      #subsetting the taxon
      if(is.memory.object==FALSE){
        x.temp=x[x$label==taxon, ]
        x.temp=x.temp[x.temp$sampling==samp, ]
      } else {
        x.temp=x$memory
      }

      #random median
      random.median = round(x.temp[x.temp$Variable=="Random", "median"][1], 2)

      #number of lags
      lags = unique(x.temp$Lag)
      lags = lags[lags!=0]

      #computing memory strength (difference betweenn component and median of the random term)
      strength.concurrent = x.temp[x.temp$Variable==exogenous.component & x.temp$Lag==0, "median"] - random.median
      x.temp=x.temp[x.temp$Lag!=0,] #removing lag 0
      strength.endogenous = max(x.temp[x.temp$Variable==endogenous.component, "median"]) - random.median
      strength.exogenous = max(x.temp[x.temp$Variable==exogenous.component, "median"]) - random.median

      #computing memory length: number of lags above the median of the random component
      length.endogenous = sum(x.temp[x.temp$Variable==endogenous.component, "median"] > random.median) / length(lags)
      length.exogenous = sum(x.temp[x.temp$Variable==exogenous.component, "median"] > random.median) / length(lags)

      #computing component dominance
      endogenous=x.temp[x.temp$Variable==endogenous.component & x.temp$Lag %in% lags, "median"]
      exogenous=x.temp[x.temp$Variable==exogenous.component & x.temp$Lag %in% lags, "median"]
      #values below random.median to zero
      endogenous[endogenous < random.median] = 0
      exogenous[exogenous < random.median] = 0
      #values
      dominance.endogenous = sum(endogenous > exogenous) / length(lags)
      dominance.exogenous =  sum(exogenous > endogenous) / length(lags)

      #params
      if(is.memory.object==FALSE){
        maximum.age = x.temp$maximum.age[1]
        fecundity = x.temp$fecundity[1]
        niche.mean = x.temp$niche.A.mean[1]
        niche.sd = x.temp$niche.A.sd[1]
      } else {
        maximum.age = fecundity = niche.mean = niche.sd = NA
      }

      #filling dataframe
      output.df[row.counter, ] = c(taxon, strength.endogenous, strength.exogenous, strength.concurrent, length.endogenous, length.exogenous, dominance.endogenous, dominance.exogenous, maximum.age, fecundity, niche.mean, niche.sd, samp)

    } #end of iteration through sampling
  } #end of iteration through taxa

  #to numeric
  output.df[, 2:(ncol(output.df)-1)] = sapply(output.df[, 2:(ncol(output.df)-1)], as.numeric)

  return(output.df)

}
