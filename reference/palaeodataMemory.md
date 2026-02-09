# Output of [`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)

List containing the output of
[`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
applied to
[`palaeodataLagged`](https://blasbenito.github.io/memoria/reference/palaeodataLagged.md).
Its slots are:

## Usage

``` r
data(palaeodataMemory)
```

## Format

List with five slots.

## Details

- `response` character, response variable name.

- `drivers` character vector, driver variable names.

- `memory` dataframe with five columns:

  - `variable` character, names of the different variables used to model
    ecological memory.

  - `lag` numeric, time lag values.

  - `median` numeric, median importance across `repetitions` of the
    given `variable` according to Random Forest.

  - `sd` numeric, standard deviation of the importance values of the
    given `variable` across `repetitions`.

  - `min` and `max` numeric, percentiles 0.05 and 0.95 of importance
    values of the given `variable` across `repetitions`.

- `R2` vector, values of pseudo R-squared value obtained for the Random
  Forest model fitted on each repetition. Pseudo R-squared is the
  Pearson correlation between the observed and predicted data.

- `prediction` dataframe, with the same columns as the dataframe in the
  slot `memory`, with the median and confidence intervals of the
  predictions of all random forest models fitted.

## See also

Other example_data:
[`climate`](https://blasbenito.github.io/memoria/reference/climate.md),
[`palaeodata`](https://blasbenito.github.io/memoria/reference/palaeodata.md),
[`palaeodataLagged`](https://blasbenito.github.io/memoria/reference/palaeodataLagged.md),
[`pollen`](https://blasbenito.github.io/memoria/reference/pollen.md)

## Author

Blas M. Benito \<blasbenito@gmail.com\>
