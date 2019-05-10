

experimentToTable = function(experiment.output, parameters.file, sampling.names=NULL, R2=TRUE){

  #objects to store results
  df.list = list()
  df.list.index = 0

  #assessing the number of columns of experiment.input
  if(is.null(dim(experiment.output$output))){
    list.rows=length(experiment.output$output)
    list.columns=1
    species.names = names(experiment.output$output)
  } else {
    list.rows=dim(experiment.output$output)[1]
    list.columns=dim(experiment.output$output)[2]
    species.names = dimnames(experiment.output$output)[[1]]
  }

  #getting species names
  # species.names = dimnames(experiment.output$output)[[1]]
  # if(is.null(species.names))
  # if(length(species.names)!=list.rows){warning("There's something wrong with experiment.output dimensions")}
  #
  for (current.row in 1:list.rows){
    for (current.column in 1:list.columns){

      #getting experiment data
      if(list.columns > 1){

        #getting the memory output
        temp.data = experiment.output$output[[current.row,current.column]]$memory

        #adding R2 to name if required
        if(R2==TRUE){
          temp.data$name = paste(experiment.output$names[[current.row,current.column]], "; R2 ", round(mean(experiment.output$output[[current.row,current.column]]$R2), 2), "±", round(sd(experiment.output$output[[current.row,current.column]]$R2), 2), sep="")
        } else {
          temp.data$name = experiment.output$names[[current.row,current.column]]
        }

        #getting pseudo R squared
        temp.data$R2mean = mean(experiment.output$output[[current.row,current.column]]$R2)
        temp.data$R2sd = sd(experiment.output$output[[current.row,current.column]]$R2)

        #getting average multicollinearity
        temp.data$VIFmean = mean(experiment.output$output[[current.row,current.column]]$multicollinearity$vif)
        temp.data$VIFsd = sd(experiment.output$output[[current.row,current.column]]$multicollinearity$vif)

        #if only one column
      } else {

        #getting the memory output
        temp.data = experiment.output$output[[current.row]]$memory

        #getting R2
        if(R2==TRUE){
          temp.data$name = paste(experiment.output$names[[current.row]], "; R2 ", round(mean(experiment.output$output[[current.row]]$R2), 2), "±", round(sd(experiment.output$output[[current.row]]$R2), 2), sep="")
        } else {
          temp.data$name = experiment.output$names[[current.row]]
        }

        #getting pseudo R squared
        temp.data$R2mean = mean(experiment.output$output[[current.row]]$R2)
        temp.data$R2sd = sd(experiment.output$output[[current.row]]$R2)

        #getting average multicollinearity
        temp.data$VIFmean = mean(experiment.output$output[[current.row]]$multicollinearity$vif)
        temp.data$VIFsd = sd(experiment.output$output[[current.row]]$multicollinearity$vif)

      }

      #adding parameters
      temp.data = cbind(temp.data, as.data.frame(lapply(parameters.file[parameters.file$label == species.names[current.row], ], rep, nrow(temp.data))))

      #adding resampling (sampling.names)
      temp.data$sampling = sampling.names[current.column]

      #adding dataframe to list
      df.list.index = df.list.index + 1
      df.list[[df.list.index]] = temp.data
    }
  }

  #puttind dataframe together
  simulation.df = do.call("rbind", df.list)

  #abbreviate the name field
  simulation.df$name = gsub(pattern="maximum.age", replacement="ma", x=simulation.df$name)
  simulation.df$name = gsub(pattern="reproductive.age", replacement="sma", x=simulation.df$name)
  simulation.df$name = gsub(pattern="sampling", replacement="smp", x=simulation.df$name)
  simulation.df$name = gsub(pattern=":", replacement="", x=simulation.df$name)
  simulation.df$name = gsub(pattern="fecundity", replacement="f", x=simulation.df$name)
  simulation.df$name = gsub(pattern="growth.rate", replacement="gr", x=simulation.df$name)
  simulation.df$name = gsub(pattern="niche.", replacement="", x=simulation.df$name)
  simulation.df$name = gsub(pattern="driver.", replacement="", x=simulation.df$name)
  simulation.df$name = gsub(pattern=".weight", replacement="w", x=simulation.df$name)
  simulation.df$name = gsub(pattern="Annual", replacement="annual", x=simulation.df$name)
  simulation.df$name = gsub(pattern=".mean", replacement="m", x=simulation.df$name)
  simulation.df$name = gsub(pattern=".sd", replacement="sd", x=simulation.df$name)
  simulation.df$name = gsub(pattern="autocorrelation.length.A", replacement="Aac", x=simulation.df$name)
  simulation.df$name = gsub(pattern="autocorrelation.length.B", replacement="Bac", x=simulation.df$name)

  return(simulation.df)

}
