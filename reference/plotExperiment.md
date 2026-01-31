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
 experiment.title = NULL,
 sampling.names = NULL,
 legend.position = "bottom",
 R2 = NULL,
 filename = NULL,
 strip.text.size = 12,
 axis.x.text.size = 8,
 axis.y.text.size = 12,
 axis.x.title.size = 14,
 axis.y.title.size = 14,
 title.size = 18,
 caption = ""
 )
```

## Arguments

- experiment.output:

  list, output of
  [`runExperiment`](https://blasbenito.github.io/memoria/reference/runExperiment.md).

- parameters.file:

  dataframe of simulation parameters.

- experiment.title:

  character string, title of the plot.

- sampling.names:

  vector of character strings with the names of the columns used in the
  argument `simulations.file` of
  [`runExperiment`](https://blasbenito.github.io/memoria/reference/runExperiment.md).

- legend.position:

  legend position in ggplot object. One of "bottom", "right", "none".

- R2:

  boolean. If `TRUE`, pseudo R-squared values are printed along with the
  traits of the virtual taxa.

- filename:

  character string, path and name (without extension) of the output pdf
  file.

- strip.text.size:

  size of the facet's labels.

- axis.x.text.size:

  size of the labels in x axis.

- axis.y.text.size:

  size of the labels in y axis.

- axis.x.title.size:

  size of the title of the x axis.

- axis.y.title.size:

  size of the title of the y axis.

- title.size:

  size of the plot title.

- caption:

  character string, caption of the output figure.

## Value

A ggplot2 object.

## See also

[`plotMemory`](https://blasbenito.github.io/memoria/reference/plotMemory.md),
[`runExperiment`](https://blasbenito.github.io/memoria/reference/runExperiment.md)

## Author

Blas M. Benito \<blasbenito@gmail.com\>
