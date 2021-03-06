% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mergePalaeoData.R
\name{mergePalaeoData}
\alias{mergePalaeoData}
\title{Merges palaeoecological datasets with different time resolution.}
\usage{
mergePalaeoData(
 datasets.list = NULL,
 time.column = NULL,
 interpolation.interval = NULL
 )
}
\arguments{
\item{datasets.list}{list of dataframes, as in \code{datasets.list = list(climate = climate.dataframe, pollen = pollen.dataframe)}. The provided dataframes must have an age/time column with the same column name and the same units of time. Non-numeric columns in these dataframes are ignored.}

\item{time.column}{character string, name of the time/age column of the datasets provided in \code{datasets.list}.}

\item{interpolation.interval}{temporal resolution of the output data, in the same units as the age/time columns of the input data}
}
\value{
A dataframe with every column of the initial dataset interpolated to a regular time grid of resolution defined by \code{interpolation.interval}. Column names follow the form datasetName.columnName, so the origin of columns can be tracked.
}
\description{
It merges palaeoecological datasets with different time intervals between consecutive samples into a single dataset with samples separated by regular time intervals defined by the user
}
\details{
This function fits a \code{\link{loess}} model of the form \code{y ~ x}, where \code{y} is any column given by \code{columns.to.interpolate} and \code{x} is the column given by the \code{time.column} argument. The model is used to interpolate column \code{y} on a regular time series of intervals equal to \code{interpolation.interval}. All columns in every provided dataset go through this process to generate the final data with samples separated by regular time intervals. Non-numeric columns are ignored, and absent from the output dataframe.
}
\examples{

\donttest{
#loading data
data(pollen)
data(climate)

x <- mergePalaeoData(
 datasets.list = list(
   pollen=pollen,
   climate=climate
 ),
 time.column = "age",
 interpolation.interval = 0.2
 )

 }

}
\author{
Blas M. Benito  <blasbenito@gmail.com>
}
