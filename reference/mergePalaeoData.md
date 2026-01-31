# Merges palaeoecological datasets with different time resolution.

Merges palaeoecological datasets with different time intervals between
consecutive samples into a single dataset with samples separated by
regular time intervals defined by the user.

## Usage

``` r
mergePalaeoData(
 datasets.list = NULL,
 time.column = NULL,
 interpolation.interval = NULL
 )
```

## Arguments

- datasets.list:

  list of dataframes, as in
  `datasets.list = list(climate = climate.dataframe, pollen = pollen.dataframe)`.
  The provided dataframes must have an age/time column with the same
  column name and the same units of time. Non-numeric columns in these
  dataframes are ignored.

- time.column:

  character string, name of the time/age column of the datasets provided
  in `datasets.list`.

- interpolation.interval:

  numeric, temporal resolution of the output data, in the same units as
  the age/time columns of the input data.

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

## Author

Blas M. Benito \<blasbenito@gmail.com\>

## Examples

``` r
# \donttest{
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
#> Argument interpolation.interval is set to 0.2
#> The average temporal resolution of pollen is 1.27; you are incrementing data resolution by a factor of 6.35
#> The average temporal resolution of climate is 1; you are incrementing data resolution by a factor of 5

 # }
```
