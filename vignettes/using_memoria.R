## ---- echo = FALSE, warning = FALSE, message = FALSE---------------------

#setting working folder to the one where this file is
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#checking if required packages are installed, and installing them if not
#checking if required packages are installed, and installing them if not
list.of.packages <- c("ggplot2", "cowplot", "knitr", "viridis", "tidyr", "formatR", "grid", "zoo", "ranger", "rpart", "rpart.plot", "partykit", "HH", "pdp", "kableExtra", "magrittr", "stringr", "dplyr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, dep = TRUE)

source("ecological_memory_functions.R")
library(ggplot2) #plotting library
library(cowplot) #plotting library
library(knitr)   #report generation in R
library(viridis) #pretty plotting colors
library(grid)    #plotting 
library(tidyr)
library(formatR)
library(zoo)     #time series analysis
library(HH)      #variance inflation factor (multicollinearity analysis)
library(kableExtra) #to fit tables to pdf page size
library(magrittr) #kableExtra requires pipes
library(pdp)     #partial dependence plots
library(ranger)  #fast Random Forest implementation
library(rpart)   #recursive partitions trees
library(rpart.plot) #fancy plotting of rpart models
library(stringr) #to parse variable names

options(scipen = 999)

# setting code font size in output pdf, from https://stackoverflow.com/a/46526740
def.chunk.hook  <- knitr::knit_hooks$get("chunk")
knitr::knit_hooks$set(chunk = function(x, options) {
  x <- def.chunk.hook(x, options)
  ifelse(options$size != "normalsize", paste0("\\", options$size,"\n\n", x, "\n\n \\normalsize"), x)
})

#trying to line-wrap code in pdf output
#from https://github.com/yihui/knitr-examples/blob/master/077-wrap-output.Rmd
knitr::opts_chunk$set(echo = TRUE, fig.pos = "h")
  opts_chunk$set(tidy.opts = list(width.cutoff = 80), tidy = FALSE)

#loading output of the previous appendix
load("Appendix_I_output.RData")

rm(list.of.packages, new.packages)

#colors
colorexo <- viridis(3)[2]
colorendo <- viridis(3)[1]



## ---- size = "small"-----------------------------------------------------
#generating vector of lags (same as in paper)
lags <- seq(20, 240, by = 20)

#organizing data in lags
sim.lags <- prepareLaggedData(simulation.data = sim,
                            response = "Pollen",
                            drivers = c("Driver", "Suitability"),
                            time = "Time",
                            lags = lags,
                            scale = FALSE)


## ----table2, echo = FALSE------------------------------------------------
#copy to be modified for the table
sim.lags.table <- sim.lags

#printing table
row.names(sim.lags.table)<-NULL
sim.lags.table$time<-NULL
sim.lags.table <- round(sim.lags.table, 1)
kable(round(sim.lags.table[1:25, 1:26], 2), col.names = c(paste("p", c(0, lags), sep = ""), paste("d", c(0, lags), sep = "")), caption="First rows of the lagged data. Numbers represent lag in years, letter p represents pollen, and letter d represents driver. Column p0 (in bold) indicates the response variable", booktabs = T) %>% kable_styling(latex_options = c("scale_down", "hold_position", "striped")) %>% column_spec(1, bold=T) %>% 
  column_spec(2:12, color="colorendo")  %>% 
  column_spec(13:26, color="colorexo")
 #fits table to page width

rm(sim.lags.table)


## ---- fig.height = 3, echo = FALSE, fig.cap = "Temporal autocorrelation of the variables in the example data."----

#plotting autocorrelation of the driver
p.driver <- ggplot(data = acfToDf(sim.lags[,"Driver_0"], 200, 50), aes(x = lag, y = acf)) +
  geom_hline(aes(yintercept = 0)) + 
  geom_hline(aes(yintercept = ci.max), color = "red", linetype = "dashed") +
  geom_hline(aes(yintercept = ci.min), color = "red", linetype = "dashed") +
  geom_segment(mapping = aes(xend = lag, yend = 0)) +
  ggtitle("Driver") +
  xlab("") +
  ylab("Pearson correlation") +
  scale_y_continuous(limits = c(-0.25, 1))

#plotting autocorrelation of the suitability
p.suitability <- ggplot(data = acfToDf(sim.lags[,"Suitability_0"], 200, 50), aes(x = lag, y = acf)) +
  geom_hline(aes(yintercept = 0)) + 
  geom_hline(aes(yintercept = ci.max), color = "red", linetype = "dashed") +
  geom_hline(aes(yintercept = ci.min), color = "red", linetype = "dashed") +
  geom_segment(mapping = aes(xend = lag, yend = 0)) +
  ggtitle("Suitability") +
  xlab("Lag (years)") +
  ylab("") +
  theme(axis.title.y = element_blank(), 
        axis.line.y = element_blank(), 
        axis.ticks.y = element_blank(), 
        axis.text.y = element_blank())+
  scale_y_continuous(limits = c(-0.25, 1))

#plotting autocorrelation of the response
p.response <- ggplot(data = acfToDf(sim.lags[,"Response_0"], 200, 50), aes(x = lag, y = acf)) +
  geom_hline(aes(yintercept = 0)) + 
  geom_hline(aes(yintercept = ci.max), color = "red", linetype = "dashed") +
  geom_hline(aes(yintercept = ci.min), color = "red", linetype = "dashed") +
  geom_segment(mapping = aes(xend = lag, yend = 0)) +
  ggtitle("Response") +
  xlab("") +
  ylab("")+
  scale_y_continuous(limits = c(-0.25, 1)) +
  theme(axis.title.y = element_blank(), 
        axis.line.y = element_blank(), 
        axis.ticks.y = element_blank(), 
        axis.text.y = element_blank())


plot_grid(p.driver, p.suitability, p.response, ncol = 3, rel_widths = c(1.2, 1, 1)) + theme(plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"))

rm(p.driver, p.response, p.suitability)



## ---- echo = FALSE, cache=FALSE, message=FALSE, warning=FALSE, error=FALSE----

#generates a list to save vif results
vif.list <- list()

#iterates through datasets Annual, 1cm, 2cm, 6cm, and 10cm
for(i in 1:5){
  
  #getting simulation output
  sim.temp <- simulation[[6, i]]
  
  

  #generating lags
  sim.temp.lags <- prepareLaggedData(simulation.data = sim.temp,
                            response = "Pollen",
                            drivers = "Driver.A",
                            time = "Time",
                            lags = lags)
  
  #removing time
  sim.temp.lags$time <- NULL

  #computing varianca inflation factor (vif function from HH library)
  vif.list[[i]] <- data.frame(HH::vif(sim.temp.lags[,2:ncol(sim.temp.lags)]))
  
}

#list results into dataframe
vif.df <- do.call(cbind, vif.list)

#colnames
colnames(vif.df) <- c("Annual", "1cm", "2cm", "6cm", "10cm")

#rownames
rownames(vif.df) <- c(paste("p", lags, sep = ""), paste("d", c(0, lags), sep = ""))

#rounding
vif.df <- round(vif.df, 1)


## ---- echo = FALSE, cache=FALSE, message=FALSE, warning=FALSE, error=FALSE----
kable(vif.df, caption = "Variance inflation factor (VIF) of the predictors across datasets available for a virtual taxa with 1000 years life-span, and wide and central niche. VIF values higher than 5 indicate that the given predictor is a linear combination of other predictors.", booktabs = T)  %>% kable_styling(latex_options = c("hold_position", "striped")) %>% 
  row_spec(1:12, color="colorendo")  %>% 
  row_spec(13:25, color="colorexo")



## ---- echo = FALSE, cache=FALSE, message=FALSE, warning=FALSE, error=FALSE----
rm(vif.df, vif.list, sim.temp, sim.temp.lags)


## ---- fig.height = 9, echo = FALSE, fig.cap = "Linear and non-linear relationships arising from lagged data in the annual dataset."----

#creating copy of sim.lags
sim.lags.plot <- sim.lags

#shorter colnames for sim.lags to simplify header of output table
colnames(sim.lags.plot) <- c(paste("Pollen_", c(0, lags), sep = ""), paste("Driver_", c(0, lags), sep = ""), paste("Suitability_", c(0, lags), sep = ""), "time")

#getting a few lags only for simpler plotting
sim.lags.plot <- sim.lags.plot[, c("Pollen_0", "Pollen_20", "Pollen_120", "Pollen_220", "Driver_20", "Driver_120", "Driver_220", "Suitability_20", "Suitability_120", "Suitability_220", "time")]

#to long format for easier plotting
sim.lags.plot.long <- gather(sim.lags.plot, variable, value, 2:10)

#keeping levels in order
sim.lags.plot.long$variable = factor(sim.lags.plot.long$variable, levels = c("Pollen_20", "Pollen_120", "Pollen_220", "Driver_20", "Driver_120", "Driver_220", "Suitability_20", "Suitability_120", "Suitability_220"))

#plot
ggplot(data = sim.lags.plot.long, aes(y = Pollen_0, x = value, group = variable, color = time)) + 
  geom_point(alpha = 0.4, shape = 16, size = 2) +
  facet_wrap("variable", scales = "free_x", ncol = 3) +
  scale_color_viridis() +
  theme(legend.position = "bottom", 
        legend.key.width = unit(2.5,"cm"), 
        panel.spacing = unit(1, "lines"),
        plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm")) +
  ylab("Response (Pollen_0)") +
  labs(color = "Time (years)")

rm(sim.lags.plot, sim.lags.plot.long)


## ---- fig.height = 3, fig.cap = "Recursive partition tree (also regression tree) of pollen abundance (noted as Response_0 in the model) as a function of Response_20 (antecedent pollen abundance at lag 20) and Driver_20 (antecedent driver values at lag 20). Numbers in branches represent split values, while numbers in terminal nodes represent the predicted average for that particular node. Percentages represent the relative number of cases included in each terminal node.", message = FALSE, error = FALSE, warning = FALSE, size="small"----

#fitting model (only two predictors)
rpart.model <- rpart(formula = Response_0 ~ Response_20 + Driver_20, 
                     data = sim.lags, 
                     control = rpart.control(minbucket = 5))

#plotting tree
rpart.plot(rpart.model, type = 0, box.palette = viridis(10, alpha = 0.2))


## ---- fig.height = 5, size = "footnotesize", fig.cap = "Recursive partition surface generated by the model fitted above. Dots represent observed data, and colours identify partitions shown in the recursive partition tree. Note that this partition surface can be generalized to any number of predictors/dimensions.", message = FALSE, error = FALSE, warning = FALSE, echo=FALSE----

#plotting binary partition
plotInteraction(model = rpart.model, 
                data = sim.lags, 
                x = "Driver_20", 
                y = "Response_20", 
                z = "Response_0", 
                point.size.range = c(0.1, 5),
                print = TRUE) 


## ---- echo=FALSE---------------------------------------------------------
rm(rpart.model)


## ---- fig.height = 4, fig.cap = "Random Forest output for the interaction between Pollen_20 and Driver_20, to allow the comparison with the recursive partition tree shown in Figure 4. To compute this interaction surface, all other variables in the model are centered in their mean.", message = FALSE, error = FALSE, warning = FALSE, size="small", results="hide"----
#getting columns containing "Response" or "Driver"
sim.lags.rf <- sim.lags[, grepl("Driver|Response", colnames(sim.lags))]

#fitting a Random Forest model
rf.model <- ranger(
  data = sim.lags.rf,
  dependent.variable.name = "Response_0",
  num.trees = 500,
  min.node.size = 5, 
  mtry = 2,
  importance = "permutation", 
  scale.permutation.importance = TRUE)

#model summary
print(rf.model)

#R-squared (computed on out-of-bag data)
rf.model$r.squared

#variable importance
rf.model$variable.importance

#obtain case predictions
rf.model$predictions

#getting information of the first tree
treeInfo(rf.model, tree=1)


## ---- fig.height = 3.5, size = "footnotesize", fig.cap = "Partial dependence plots of the lags 20, of Pollen (A) and Driver (B), and the concurrent effect (Driver_0, panel C).", message = FALSE, error = FALSE, warning = FALSE, echo = FALSE----
#partial dependence plots

#some things for the plots
gg.scale <- scale_y_continuous(limits = c(1500, 2100))
no.y.axis <- theme(axis.line.y = element_blank(), 
                   axis.ticks.y = element_blank(), 
                   axis.text.y = element_blank(),
                   axis.title.y = element_blank())

#plotting several partial dependence plots (with "pdp" library)
plot.Response_20 <- autoplot(partial(rf.model, pred.var = "Response_20"), ylab = "Response_0", col = colorendo, size = 2) + gg.scale

plot.Driver_20 <- autoplot(partial(rf.model, pred.var = "Driver_20"), ylab = "Response_0", col = colorexo, size = 2) + gg.scale + no.y.axis

plot.Driver_0 <- autoplot(partial(rf.model, pred.var = "Driver_0"), ylab = "Response_0", col = colorexo, size = 2) + gg.scale + no.y.axis


plot_grid(plot.Response_20,plot.Driver_20, plot.Driver_0, ncol = 3, labels = c("A", "B", "C"), rel_widths = c(1.2, 1, 1))

rm(plot.Driver_20, plot.Response_20, plot.Driver_0, no.y.axis, gg.scale)


## ---- fig.height=5, size = "footnotesize" , fig.cap = "Interaction between Pollen_20 (first lag of the endogenous memory) and Suitability_0 (concurrent effect).", message = FALSE, error = FALSE, warning = FALSE, echo = FALSE----
plotInteraction(model = rf.model,
                data = sim.lags.rf,
                x = "Driver_20",
                y = "Response_20",
                z = "Response_0",
                point.size.range = c(0.1, 5),
                print = TRUE)


## ---- eval = FALSE, size="small"-----------------------------------------
## importance(rf.model)


## ---- cache = FALSE, message = FALSE, error = FALSE, warning = FALSE, size="small"----

#number of repetitions
repetitions <- 30

#list to save importance results
importance.list <- list()

#repetitions
for(i in 1:repetitions){
  #fitting a Random Forest model
  rf.model <- ranger(
    data = sim.lags.rf,
    dependent.variable.name = "Response_0",
    mtry = 2,
    importance = "permutation", 
    scale.permutation.importance = TRUE)

  #extracting importance
  importance.list[[i]] <- data.frame(t(importance(rf.model)))
}

#into a single dataframe
importance.df <- do.call("rbind", importance.list)


## ----table4, echo = FALSE------------------------------------------------

#importance to dataframe
rf.importance <- data.frame(importance(rf.model))

#name for the main column
colnames(rf.importance) <- "Importance"

#rownames as variable
rf.importance$Variable <- rownames(rf.importance)

#ordering by importance
rf.importance <- rf.importance[order(rf.importance[,1], decreasing = TRUE), c("Variable", "Importance")]

#rounding
rf.importance$Importance <- round(rf.importance$Importance, 2)

#removing rownames
rownames(rf.importance)<-NULL

#to kable
kable(rf.importance, caption = "Importance scores of a Random Forest model ordered from higher to lower importance. Importance scores are interpreted as increase in model error when the given variable is removed from the model.", booktabs = T)  %>%
  kableExtra::kable_styling(latex_options = c("hold_position", "striped"))


## ---- fig.height = 10, size = "footnotesize", fig.cap = "Importance scores of predictors in Random Forest model after 100 repetitions. Note that Response_X predictor refers to the endogenous memory, and Driver_X predictors from lag 20 refer to exogenous memory. Driver_0 represents the concurrent effect.", message = FALSE, error = FALSE, warning = FALSE, echo = FALSE----
#boxplot
par(mar = c(5, 10, 4, 2) + 0.1)
boxplot(importance.df, 
        horizontal = TRUE, 
        las = 1, 
        cex.axis = 1, 
        cex.lab = 1.2,
        xlab = "Importance (% increment in mse)", 
        notch = TRUE, 
        col = c(rep(colorendo, 12), rep(colorexo, 13)))


## ---- size = "small", cache = FALSE, message = FALSE, error = FALSE, warning = FALSE----

#number of repetitions
repetitions <- 100

#list to save importance results
importance.list <- list()

#rows of the input dataset
n.rows <- nrow(sim.lags.rf)

#repetitions
for(i in 1:repetitions){
  
  #adding/replacing random.white column
  sim.lags.rf$random.white <- rnorm(n.rows)
  
  #adding/replacing random.autocor column
  #different filter length on each run = different temporal structure
  sim.lags.rf$random.autocor <- as.vector(filter(rnorm(n.rows), 
                      filter = rep(1, sample(1:floor(n.rows/4), 1)), 
                      method = "convolution", 
                      circular = TRUE))

  #fitting a Random Forest model
  rf.model <- ranger(
    data = sim.lags.rf,
    dependent.variable.name = "Response_0",
    mtry = 2,
    importance = "permutation", 
    scale.permutation.importance = TRUE)

  #extracting importance
  importance.list[[i]] <- data.frame(t(importance(rf.model)))
  
}

#into a single dataframe
importance.df <- do.call("rbind", importance.list)


## ---- fig.height = 10, size = "footnotesize", cache = FALSE, fig.cap = "Importance of predictors in relation to the importance of a white noise variable (gray), and a temporally structured random variable (yellow). Solid lines represent the medians of the random variables, while dashed lines represent their maximum importance across 100 model runs.", message = FALSE, error = FALSE, warning = FALSE, echo=FALSE----

#boxplot
par(mar = c(5, 10, 4, 2) + 0.1)
boxplot(importance.df, 
        horizontal = TRUE, 
        las = 1, 
        cex.axis = 1, 
        cex.lab = 1.2,
        xlab = "Importance (% increment in mse)", 
        notch = TRUE, 
        col = c(rep(colorendo, 12), rep(colorexo, 13), "gray80", "#FEEE62"))
abline(v = quantile(importance.df$random.autocor, probs = c(0.5, 1)), col = "#FEEE62", lwd = c(3,2), lty = c(1,2))
abline(v = quantile(importance.df$random.white, probs = c(0.5, 1)), col = "gray80", lwd = c(3,3), lty = c(1,2))



## ---- echo=FALSE, message=FALSE, warning=FALSE, error=FALSE, results="hide"----
rm(importance.df, importance.list, rf.importance, rf.model, i, n.rows, repetitions, sim.lags.rf)
# gc()


## ---- fig.height = 4, fig.width=9, size = "small", cache = FALSE, fig.cap = "Ecological memory pattern of taxon 6, 1cm dataset. The variable Response represents the endogenous memory, the first lag of the variable Suitability represents the concurrent effect of environmental conditions, and the rest of the lags of Suitability represent the exogenous memory component. Relative importance values below the yellow line are considered non-significant.", message = FALSE, error = FALSE, warning = FALSE, results="asis"----

#computes ecological memory pattern
memory.pattern <- computeMemory(lagged.data = sim.lags, 
                               drivers = "Driver", 
                               random.mode="autocorrelated", 
                               repetitions=30, 
                               response="Response")

#computing memory features
memory.features <- extractMemoryFeatures(analysis.output=memory.pattern,
                                         exogenous.component="Driver",
                                         endogenous.component="Response")

#plotting the ecological memory pattern
plotMemory(memory.pattern)


## ---- echo=FALSE---------------------------------------------------------
#Table of memory features
memory.features.t <- round(t(memory.features[, 2:8]), 2)
kable(memory.features.t, caption = "Features of the ecological memory pattern shown in Figure 10 by using the extractMemoryFeatures function.", booktabs = T)  %>%
  kableExtra::kable_styling(latex_options = c("hold_position", "striped"))


## ---- results="hide", cache=FALSE, size="small", warning=FALSE, message=FALSE, error=FALSE----
#running experiment
E1 <- runExperiment(simulations.file = simulation,
              selected.rows = c(1, 6), #2 species only
              selected.columns = c(2, 5), #1cm dataset only
              parameters.file = parameters,
              parameters.names = c("maximum.age", 
                                   "fecundity", 
                                   "niche.A.mean", 
                                   "niche.A.sd"),
              sampling.names = c("1cm", "10cm"),
              driver.column = "Driver.A",
              response.column = "Pollen",
              time.column = "Time",
              lags = lags,
              repetitions = 30)

#E1 is a list of lists
#first list: names of experiment output
E1$names 

#second list, first element
i <- 1 #change to see other elements
#ecological memory pattern
E1$output[[i]]$memory
#pseudo R-squared across repetitions
E1$output[[i]]$R2
#predicted pollen across repetitions
E1$output[[i]]$prediction
#variance inflation factor of input data
E1$output[[i]]$multicollinearity



## ---- fig.height = 6, cache = FALSE, fig.cap = "Ecological memory patterns of 2 virtual taxa (one per row, taxa 1 and 6) at two different sampling resolutions (one per column: 1cm and 10cm). Abbreviations in plot title: ma - maximum age, f - fecundity, Am - niche mean, Asd - niche breadth, smp - sampling resolution, R2 - pseudo R-squared.", message = FALSE, error = FALSE, warning = FALSE----
plotExperiment(experiment.output=E1, 
               parameters.file=parameters, 
               experiment.title="Toy experiment", 
               sampling.names=c("1cm", "10cm"), 
               legend.position="bottom", 
               R2=TRUE)


## ---- size="small"-------------------------------------------------------
E1.df <- experimentToTable(experiment.output=E1, 
                           parameters.file=parameters, 
                           sampling.names=c("1cm", "10cm"), 
                           R2=TRUE)


## ---- echo = FALSE-------------------------------------------------------
#removing a useless column
E1.df$name <- NULL
E1.df$autocorrelation.length.A <- NULL
E1.df$autocorrelation.length.B <- NULL
E1.df$pollen.control <- NULL
E1.df$maximum.biomass <- NULL
E1.df$carrying.capacity <- NULL

#rounding some columns
E1.df$R2mean <- round(E1.df$R2mean, 2)
E1.df$R2sd <- round(E1.df$R2sd, 3)
E1.df$median <- round(E1.df$median, 1)
E1.df$sd <- round(E1.df$sd, 2)
E1.df$min <- round(E1.df$R2sd, 1)
E1.df$max <- round(E1.df$R2sd, 1)

rownames(E1.df) <- NULL

#printing table

kable(E1.df[1:40, ], caption="First rows of the experiments table.", booktabs = T) %>% 
  kable_styling(latex_options = c("scale_down", "hold_position", "striped"))  %>%  
  column_spec(1:ncol(E1.df), color="#38598C") %>%
  row_spec(0, col="#585858")



## ---- size="small"-------------------------------------------------------
E1.features <- extractMemoryFeatures(analysis.output=E1.df,
                                     exogenous.component="Driver.A",
                                     endogenous.component="Response")


## ---- echo=FALSE---------------------------------------------------------
#rounding some columns
E1.features$length.endogenous <- round(E1.features$length.endogenous, 3)
E1.features$length.exogenous <- round(E1.features$length.exogenous, 3)
E1.features$dominance.endogenous <- round(E1.features$dominance.endogenous, 3)
E1.features$dominance.exogenous <- round(E1.features$dominance.exogenous, 3)
  
  
E1.features.t <- t(E1.features)
kable(E1.features.t, caption = "Features of the ecological memory patterns produced by the example experiment.", booktabs = T)  %>%
  kableExtra::kable_styling(latex_options = c("hold_position", "striped")) %>%  
  column_spec(1:(ncol(E1.features.t)+1), color="#38598C") %>%
  row_spec(1, col="#585858")


## ---- echo=FALSE---------------------------------------------------------
#EXECUTE EVERYTHING FROM HERE

