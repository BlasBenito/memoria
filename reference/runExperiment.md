# Computes ecological memory patterns on simulated pollen curves produced by the `virtualPollen` package.

Applies
[`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
to assess ecological memory on a large set of virtual pollen curves.

## Usage

``` r
runExperiment(
 simulations.file = NULL,
 selected.rows = 1,
 selected.columns = 1,
 parameters.file = NULL,
 parameters.names = NULL,
 sampling.names = NULL,
 driver.column = NULL,
 response.column = "Response_0",
 subset.response = "none",
 time.column = "Time",
 time.zoom = NULL,
 lags = NULL,
 repetitions = 10
 )
```

## Arguments

- simulations.file:

  list of dataframes, output of the function `simulatePopulation` of the
  `virtualPollen` package.

- selected.rows:

  numeric vector, rows (virtual taxa) of `simulations.file` to be
  analyzed.

- selected.columns:

  numeric vector, columns (experiment treatments) of `simulations.file`
  to be analyzed.

- parameters.file:

  dataframe of simulation parameters.

- parameters.names:

  vector of character strings with names of traits and niche features
  from `parameters.file` to be included in the analysis (i.e.
  c("maximum.age", "fecundity", "niche.A.mean", "niche.A.sd"))

- sampling.names:

  vector of character strings with the names of the columns of
  `simulations.file`.

- driver.column:

  vector of character strings, names of the columns to be considered as
  drivers (generally, one of "Suitability", "Driver.A", "Driver.B").

- response.column:

  character string defining the response variable, typically
  "Response_0".

- subset.response:

  character string, one of "up", "down" or "none", triggers the
  subsetting of the input dataset. "up" only models ecological memory on
  cases where the response's trend is positive, "down" selects cases
  with negative trends, and "none" selects all cases.

- time.column:

  character string, name of the time/age column. Usually, "Time".

- time.zoom:

  numeric vector with two numbers defining the time/age extremes of the
  time interval of interest.

- lags:

  numeric vector, lags to be used in the equation, in the same units as
  `time`. The use of [`seq`](https://rdrr.io/r/base/seq.html) to define
  it is highly recommended. If 0 is absent from lags, it is added
  automatically to allow the consideration of a concurrent effect. Lags
  should be aligned to the temporal resolution of the data. For example,
  if the interval between consecutive samples is 100 years, lags should
  be something like `0, 100, 200, 300`. Lags can also be multiples of
  the time resolution, such as `0, 200, 400, 600` (when time resolution
  is 100 years).

- repetitions:

  integer, number of random forest models to fit.

## Value

A list with 2 slots:

- `names` matrix of character strings, with as many rows and columns as
  `simulations.file`. Each cell holds a simulation name to be used
  afterwards, when plotting the results of the ecological memory
  analysis.

- `output` a list with as many rows and columns as `simulations.file`.
  Each slot holds a an output of
  [`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md).

  - `memory` dataframe with five columns:

    - `Variable` character, names and lags of the different variables
      used to model ecological memory.

    - `median` numeric, median importance across `repetitions` of the
      given `Variable` according to Random Forest.

    - `sd` numeric, standard deviation of the importance values of the
      given `Variable` across `repetitions`.

    - `min` and `max` numeric, percentiles 0.05 and 0.95 of importance
      values of the given `Variable` across `repetitions`.

  - `R2` vector, values of pseudo R-squared value obtained for the
    Random Forest model fitted on each repetition. Pseudo R-squared is
    the Pearson correlation between the observed and predicted data.

  - `prediction` dataframe, with the same columns as the dataframe in
    the slot `memory`, with the median and confidence intervals of the
    predictions of all random forest models fitted.

  - `multicollinearity` multicollinearity analysis on the input data
    performed with
    [`vif_df`](https://blasbenito.github.io/collinear/reference/vif_df.html).
    A vif value higher than 5 indicates that the given variable is
    highly correlated with other variables.

## See also

[`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)

## Author

Blas M. Benito \<blasbenito@gmail.com\>
