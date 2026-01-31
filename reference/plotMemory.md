# Plots output of [`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)

Plots the ecological memory pattern yielded by
[`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md).

## Usage

``` r
plotMemory(
  memory.output = NULL,
  ribbon = FALSE,
  legend.position = "right",
  filename = NULL
)
```

## Arguments

- memory.output:

  list, output of
  [`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md).

- ribbon:

  logical, switches plotting of confidence intervals on (TRUE) and off
  (FALSE). Default: FALSE

- legend.position:

  character string, legend position (e.g., "right", "bottom", "none").

- filename:

  deprecated, not used. Kept for backwards compatibility.

## Value

A ggplot object.

## See also

[`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)

## Author

Blas M. Benito \<blasbenito@gmail.com\>

## Examples

``` r
#loading data
data(palaeodataMemory)

#plotting memory pattern
plotMemory(memory.output = palaeodataMemory)


#with confidence ribbon
plotMemory(memory.output = palaeodataMemory, ribbon = TRUE)


```
