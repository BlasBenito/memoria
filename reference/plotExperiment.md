# Plots the output of [`runExperiment`](https://blasbenito.github.io/memoria/reference/runExperiment.md).

Takes the output of
[`runExperiment`](https://blasbenito.github.io/memoria/reference/runExperiment.md),
and generates plots of ecological memory patterns for a large number of
simulated pollen curves.

## Usage

``` r
plotExperiment(
  experiment.output = NULL,
  parameters.file = NULL,
  ribbon = FALSE
)
```

## Arguments

- experiment.output:

  list, output of
  [`runExperiment`](https://blasbenito.github.io/memoria/reference/runExperiment.md).
  Default: `NULL`.

- parameters.file:

  dataframe of simulation parameters. Default: `NULL`.

- ribbon:

  logical, switches plotting of confidence intervals on (TRUE) and off
  (FALSE). Default: `FALSE`.

## Value

A ggplot2 object.

## See also

[`plotMemory`](https://blasbenito.github.io/memoria/reference/plotMemory.md),
[`runExperiment`](https://blasbenito.github.io/memoria/reference/runExperiment.md)

Other virtualPollen:
[`experimentToTable()`](https://blasbenito.github.io/memoria/reference/experimentToTable.md),
[`runExperiment()`](https://blasbenito.github.io/memoria/reference/runExperiment.md)

## Author

Blas M. Benito \<blasbenito@gmail.com\>
