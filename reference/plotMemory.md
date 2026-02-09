# Plots output of [`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)

Plots the ecological memory pattern yielded by
[`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md).

## Usage

``` r
plotMemory(
  memory.output = NULL,
  ribbon = FALSE,
  legend.position = "right",
  ...
)
```

## Arguments

- memory.output:

  list, output of
  [`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md).
  Default: `NULL`.

- ribbon:

  logical, switches plotting of confidence intervals on (TRUE) and off
  (FALSE). Default: `FALSE`.

- legend.position:

  character, position of the legend. Default: `"right"`.

- ...:

  additional arguments for internal use.

## Value

A ggplot object.

## See also

[`computeMemory`](https://blasbenito.github.io/memoria/reference/computeMemory.md)

Other memoria:
[`computeMemory()`](https://blasbenito.github.io/memoria/reference/computeMemory.md),
[`extractMemoryFeatures()`](https://blasbenito.github.io/memoria/reference/extractMemoryFeatures.md)

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
