# Changelog

## memoria 1.1.0 (2025-01-27)

### Bug fixes

- Fixed off-by-one indexing error in
  [`computeMemory()`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
  when labeling subset rows for trend direction (“up”/“down”/“stable”).
- Fixed
  [`computeMemory()`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
  to apply `addRandomColumn()` to the subsetted data
  (`lagged.data.model`) rather than the full dataset.
- Fixed
  [`plotExperiment()`](https://blasbenito.github.io/memoria/reference/plotExperiment.md)
  referencing wrong variable name (`parameters` instead of
  `parameters.file`).
- Fixed
  [`prepareLaggedData()`](https://blasbenito.github.io/memoria/reference/lagTimeSeries.md)
  using hardcoded `"age"` instead of the user-supplied `time` column
  name in `time.zoom` validation.
- Fixed
  [`runExperiment()`](https://blasbenito.github.io/memoria/reference/runExperiment.md)
  operator precedence bug: `length(parameters.names == 1)` changed to
  `length(parameters.names) == 1`.

### Dependency changes

- Removed irrelevant dependencies.
- Bumped minimum R version from 2.10 to 4.1.0.
- Updated RoxygenNote from 6.1.1 to 7.3.3.

### Code improvements

- Expanded compact `importFrom` directives into individual entries in
  NAMESPACE.
- Added argument `num.threads` to
  [`computeMemory()`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
  to allow multithreading in
  [`ranger::ranger()`](http://imbs-hl.github.io/ranger/reference/ranger.md).
- Removed argument `add.random` from
  [`computeMemory()`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
  and replaced it with the option “none” in argument `random.mode`.
- Arguments `response` and `drivers` are no longer required in
  [`computeMemory()`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
  if argument `lagged.data` was generated with
  [`prepareLaggedData()`](https://blasbenito.github.io/memoria/reference/lagTimeSeries.md).
- Added argument `ribbon` to
  [`plotMemory()`](https://blasbenito.github.io/memoria/reference/plotMemory.md)
  and removed other useless arguments to simplify the usage.
- Removed argument `sampling.names` from
  [`runExperiment()`](https://blasbenito.github.io/memoria/reference/runExperiment.md),
  [`plotExperiment()`](https://blasbenito.github.io/memoria/reference/plotExperiment.md),
  and
  [`experimentToTable()`](https://blasbenito.github.io/memoria/reference/experimentToTable.md)
  as it provided minimal value while adding complexity.
- Removed argument `sampling.subset` from
  [`extractMemoryFeatures()`](https://blasbenito.github.io/memoria/reference/extractMemoryFeatures.md)
  as it provided minimal value while adding complexity. Users can filter
  input data directly (e.g., `data[data$sampling == 25, ]`).
- Renamed
  [`mergePalaeoData()`](https://blasbenito.github.io/memoria/reference/alignTimeSeries.md)
  to
  [`alignTimeSeries()`](https://blasbenito.github.io/memoria/reference/alignTimeSeries.md)
  for domain-agnostic naming. The old name remains as a deprecated
  alias.
- Renamed
  [`prepareLaggedData()`](https://blasbenito.github.io/memoria/reference/lagTimeSeries.md)
  to
  [`lagTimeSeries()`](https://blasbenito.github.io/memoria/reference/lagTimeSeries.md)
  for consistency with
  [`alignTimeSeries()`](https://blasbenito.github.io/memoria/reference/alignTimeSeries.md).
  The old name remains as a deprecated alias.

### Documentation

- Fixed typos and improved clarity across roxygen2 documentation for
  [`computeMemory()`](https://blasbenito.github.io/memoria/reference/computeMemory.md),
  [`extractMemoryFeatures()`](https://blasbenito.github.io/memoria/reference/extractMemoryFeatures.md),
  [`mergePalaeoData()`](https://blasbenito.github.io/memoria/reference/alignTimeSeries.md),
  [`plotMemory()`](https://blasbenito.github.io/memoria/reference/plotMemory.md),
  [`prepareLaggedData()`](https://blasbenito.github.io/memoria/reference/lagTimeSeries.md),
  [`runExperiment()`](https://blasbenito.github.io/memoria/reference/runExperiment.md),
  and dataset help pages.
- Fixed NEWS.md header to comply with CRAN policy.

### Other changes

- Removed the function `plotInteraction()`, as it is available in
  `spatialRF::plot_response_surface()` and the package `pdp`.

## memoria 1.0.0 (2019-05-17)

CRAN release: 2019-05-17

Initial CRAN release.
