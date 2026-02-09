# Computes ecological memory patterns on simulated pollen curves produced by the `virtualPollen` package.

Applies
[`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
to assess ecological memory on a large set of virtual pollen curves.

## Usage

``` r
runExperiment(
  simulations.file = NULL,
  selected.rows = NULL,
  selected.columns = NULL,
  parameters.file = NULL,
  parameters.names = NULL,
  driver.column = NULL,
  response.column = "Pollen",
  subset.response = "none",
  time.column = "Time",
  time.zoom = NULL,
  lags = NULL,
  repetitions = 10
)
```

## Arguments

- simulations.file:

  List of dataframes produced by `virtualPollen::simulatePopulation`.
  Each list element is a time series dataframe for one virtual taxon.
  Can be a 1D list (one sampling scheme) or a 2D matrix-like list (rows
  = taxa, columns = sampling schemes). See `virtualPollen::simulation`
  for an example. Default: `NULL`.

- selected.rows:

  Numeric vector indicating which virtual taxa (list elements) from
  `simulations.file` to analyze. For example, `c(1, 3)` analyzes the 1st
  and 3rd taxa. Default: `NULL` (analyzes all taxa).

- selected.columns:

  Numeric vector indicating which sampling schemes (columns) from
  `simulations.file` to analyze. Only relevant when `simulations.file`
  has a 2D structure with multiple sampling schemes. Default: `NULL`
  (uses the first sampling scheme only).

- parameters.file:

  Dataframe of simulation parameters produced by
  `virtualPollen::parametersDataframe`, with one row per virtual taxon.
  Rows must align with `simulations.file`. See
  `virtualPollen::parameters` for an example. Default: `NULL`.

- parameters.names:

  Character vector of column names from `parameters.file` to include in
  output labels. These help identify which simulation settings produced
  each result. Example: `c("maximum.age", "fecundity")`. Default:
  `NULL`.

- driver.column:

  Character vector of column names representing environmental drivers in
  the simulation dataframes. Common choices: `"Driver.A"`, `"Driver.B"`,
  or `"Suitability"`. Default: `NULL`.

- response.column:

  Character string naming the response variable column in the simulation
  dataframes. Use `"Pollen"` for pollen abundance from
  `virtualPollen::simulation`. Default: `"Pollen"`.

- subset.response:

  character string, one of "up", "down" or "none", triggers the
  subsetting of the input dataset. "up" only models ecological memory on
  cases where the response's trend is positive, "down" selects cases
  with negative trends, and "none" selects all cases. Default: `"none"`.

- time.column:

  character string, name of the time/age column. Usually, "Time".
  Default: `"Time"`.

- time.zoom:

  numeric vector with two numbers defining the time/age extremes of the
  time interval of interest. Default: `NULL`.

- lags:

  numeric vector, lags to be used in the equation, in the same units as
  `time`. The use of [`seq`](https://rdrr.io/r/base/seq.html) to define
  it is highly recommended. If 0 is absent from lags, it is added
  automatically to allow the consideration of a concurrent effect. Lags
  should be aligned to the temporal resolution of the data. For example,
  if the interval between consecutive samples is 100 years, lags should
  be something like `0, 100, 200, 300`. Lags can also be multiples of
  the time resolution, such as `0, 200, 400, 600` (when time resolution
  is 100 years). Default: `NULL`.

- repetitions:

  integer, number of random forest models to fit. Default: `10`.

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

Other virtualPollen:
[`experimentToTable()`](https://blasbenito.github.io/memoria/reference/experimentToTable.md),
[`plotExperiment()`](https://blasbenito.github.io/memoria/reference/plotExperiment.md)

## Author

Blas M. Benito \<blasbenito@gmail.com\>
