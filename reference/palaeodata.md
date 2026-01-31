# Dataframe with pollen and climate data.

A dataframe with a regular time grid of 0.2 ky resolution resulting from
applying
[`mergePalaeoData`](https://blasbenito.github.io/memoria/reference/mergePalaeoData.md)
to the datasets
[`climate`](https://blasbenito.github.io/memoria/reference/climate.md)
and
[`pollen`](https://blasbenito.github.io/memoria/reference/pollen.md):

## Usage

``` r
data(palaeodata)
```

## Format

dataframe with 10 columns and 7986 rows.

## Details

- *age* in ky before present (ky BP).

- *pollen.pinus* pollen percentages of Pinus.

- *pollen.quercus* pollen percentages of Quercus.

- *pollen.poaceae* pollen percentages of Poaceae.

- *pollen.artemisia* pollen percentages of Artemisia.

- *climate.temperatureAverage* average annual temperature in degrees
  Celsius.

- *climate.rainfallAverage* average annual precipitation in millimetres
  per day (mm/day).

- *climate.temperatureWarmestMonth* average temperature of the warmest
  month, in degrees Celsius.

- *climate.temperatureColdestMonth* average temperature of the coldest
  month, in degrees Celsius.

- *climate.oxigenIsotope* delta O18, global ratio of stable isotopes in
  the sea floor, see
  [http://lorraine-lisiecki.com/stack.html](http://lorraine-lisiecki.com/stack.md)
  for further details.

## Author

Blas M. Benito \<blasbenito@gmail.com\>
