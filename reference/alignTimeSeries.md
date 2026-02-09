# Align and join multiple time series to a common temporal resolution

Aligns multiple time series datasets to a common temporal resolution
using LOESS interpolation and joins them into a single dataframe. This
is useful when combining datasets with different sampling intervals.

## Usage

``` r
alignTimeSeries(
  datasets.list = NULL,
  time.column = NULL,
  interpolation.interval = NULL
)

mergePalaeoData(
  datasets.list = NULL,
  time.column = NULL,
  interpolation.interval = NULL
)
```

## Arguments

- datasets.list:

  list of dataframes, as in
  `datasets.list = list(dataset1 = df1, dataset2 = df2)`. The provided
  dataframes must have a time column with the same column name and the
  same units of time. Non-numeric columns in these dataframes are
  ignored. Default: `NULL`.

- time.column:

  character string, name of the time column of the datasets provided in
  `datasets.list`. Default: `NULL`.

- interpolation.interval:

  numeric, temporal resolution of the output data, in the same units as
  the time columns of the input data. Default: `NULL`.

## Value

A dataframe with every column of the initial dataset interpolated to a
regular time grid of resolution defined by `interpolation.interval`.
Column names follow the form datasetName.columnName, so the origin of
columns can be tracked.

## Details

This function fits a [`loess`](https://rdrr.io/r/stats/loess.html) model
of the form `y ~ x`, where `y` is any numeric column in the input
datasets and `x` is the column given by the `time.column` argument. The
model is used to interpolate column `y` on a regular time series of
intervals equal to `interpolation.interval`. All numeric columns in
every provided dataset go through this process to generate the final
data with samples separated by regular time intervals. Non-numeric
columns are ignored and absent from the output dataframe.

## See also

Other data_preparation:
[`lagTimeSeries()`](https://blasbenito.github.io/memoria/reference/lagTimeSeries.md)

## Author

Blas M. Benito \<blasbenito@gmail.com\>

## Examples

``` r
# \donttest{
#loading data
data(pollen)
data(climate)

x <- alignTimeSeries(
 datasets.list = list(
   pollen=pollen,
   climate=climate
 ),
 time.column = "age",
 interpolation.interval = 0.2
 )

 # }
```
