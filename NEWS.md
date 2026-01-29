# memoria 1.1.0 (2025-01-27)

## Bug fixes

- Fixed off-by-one indexing error in `computeMemory()` when labeling subset rows for trend direction ("up"/"down"/"stable").
- Fixed `computeMemory()` to apply `addRandomColumn()` to the subsetted data (`lagged.data.model`) rather than the full dataset.
- Fixed `plotExperiment()` referencing wrong variable name (`parameters` instead of `parameters.file`).
- Fixed `prepareLaggedData()` using hardcoded `"age"` instead of the user-supplied `time` column name in `time.zoom` validation.
- Fixed `runExperiment()` operator precedence bug: `length(parameters.names == 1)` changed to `length(parameters.names) == 1`.

## Dependency changes

- Removed irrelevant dependencies.
- Bumped minimum R version from 2.10 to 4.1.0.
- Updated RoxygenNote from 6.1.1 to 7.3.3.

## Code improvements

- Replaced `class(x) == "foo"` with `inherits(x, "foo")` in `plotInteraction()` for safer class checking.
- Expanded compact `importFrom` directives into individual entries in NAMESPACE.
- Added argument `num.threads` to `computeMemory()` to allow multithreading in `ranger::ranger()`.
- Removed argument `add.random` from `computeMemory()` and replaced it with the option "none" in argument `random.mode`.
- Arguments `response` and `drivers` are no longer required in `computeMemory()` if argument `lagged.data` was generated with `prepareLaggedData()`.
- Added argument `ribbon` to `plotMemory()` and removed other useless arguments to simplify the usage.

## Documentation

- Fixed typos and improved clarity across roxygen2 documentation for `computeMemory()`, `extractMemoryFeatures()`, `mergePalaeoData()`, `plotMemory()`, `prepareLaggedData()`, `runExperiment()`, and dataset help pages.
- Fixed NEWS.md header to comply with CRAN policy.

# memoria 1.0.0 (2019-05-17)

Initial CRAN release.
