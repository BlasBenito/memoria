# memoria 1.0.1 (2025-01-27)

## Bug fixes

- Fixed off-by-one indexing error in `computeMemory()` when labeling subset rows for trend direction ("up"/"down"/"stable").
- Fixed `computeMemory()` to apply `addRandomColumn()` to the subsetted data (`lagged.data.model`) rather than the full dataset.
- Fixed `plotExperiment()` referencing wrong variable name (`parameters` instead of `parameters.file`).
- Fixed `prepareLaggedData()` using hardcoded `"age"` instead of the user-supplied `time` column name in `time.zoom` validation.
- Fixed `runExperiment()` operator precedence bug: `length(parameters.names == 1)` changed to `length(parameters.names) == 1`.
- Fixed `plotMemory()` theme order so that `cowplot::theme_cowplot()` is applied before custom theme overrides (legend position, axis text).

## Dependency changes

- Replaced `HH` package with `collinear` for multicollinearity analysis (VIF), using `collinear::vif_df()` instead of `HH::vif()`.
- Removed `cowplot` from Imports (now accessed via `cowplot::theme_cowplot()`).
- Added `testthat (>= 3.0.0)` to Suggests.
- Bumped minimum R version from 2.10 to 4.1.0.
- Updated RoxygenNote from 6.1.1 to 7.3.3.

## Code improvements

- Replaced `class(x) == "foo"` with `inherits(x, "foo")` in `plotInteraction()` for safer class checking.
- Expanded compact `importFrom` directives into individual entries in NAMESPACE.

## Documentation

- Fixed typos and improved clarity across roxygen2 documentation for `computeMemory()`, `extractMemoryFeatures()`, `mergePalaeoData()`, `plotMemory()`, `prepareLaggedData()`, `runExperiment()`, and dataset help pages.
- Fixed NEWS.md header to comply with CRAN policy.

# memoria 1.0.0 (2019-05-17)

Initial CRAN release.
