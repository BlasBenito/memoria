% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotInteraction.R
\name{plotInteraction}
\alias{plotInteraction}
\title{Plots response surfaces for tree-based models.}
\usage{
plotInteraction(
  model = NULL,
  data = NULL,
  x = NULL,
  y = NULL,
  z = NULL,
  grid = 100,
  point.size.range = c(0.1, 1)
  )
}
\arguments{
\item{model}{a model object produced by the functions \code{\link[ranger]{ranger}}, \code{\link[randomForest]{randomForest}}, or \code{\link[rpart]{rpart}}.}

\item{data}{dataframe used to fit the model.}

\item{x}{character string, name of column in \code{data} to be plotted in the x axis.}

\item{y}{character string, name of column in \code{data} to be plotted in the y axis.}

\item{z}{character string, name of column in \code{data} to be plotted as a surface. Generally, the name of the response variable in \code{model}.}

\item{grid}{numeric, resolution of the x and y axes.}

\item{point.size.range}{numeric vector with two values defining the range size of the points representing the observed data.}
}
\value{
A ggplot object.
}
\description{
Plots a response surface plot or interaction plot (2 predictors and a model response) for models of the functions \code{\link[ranger]{ranger}}, \code{\link[randomForest]{randomForest}}, and \code{\link[rpart]{rpart}}. It also plots the observed data on top of the predicted surface.
}
\author{
Blas M. Benito  <blasbenito@gmail.com>
}
