# TODO

All previously identified issues have been resolved.

------------------------------------------------------------------------

## Resolved Issues

### ~~1. Division by zero in `extractMemoryFeatures.R`~~ ✓ FIXED

Added validation that throws an error if no lags beyond lag 0 are found,
since ecological memory analysis is meaningless without non-zero lags.

### ~~2. Variable name `__` restriction not enforced at runtime in `computeMemory.R`~~ ✓ FIXED

Added runtime validation at the start of
[`computeMemory()`](https://blasbenito.github.io/memoria/reference/computeMemory.md)
that checks all driver and response variable names for `__` and throws a
clear error message.

### ~~4. Fragile type coercion via `c()` in `extractMemoryFeatures.R`~~ ✓ FIXED

Replaced [`c()`](https://rdrr.io/r/base/c.html) row assignment with
direct column-by-column assignment to preserve numeric types.

### ~~5. `selected.columns == 1` scalar check in `runExperiment.R`~~ ✓ FIXED

Changed `if(selected.columns == 1)` to
`if(length(selected.columns) == 1)` to properly check vector length.

### ~~6. Dead code in `mergePalaeoData.R`~~ ✓ NOT FOUND

Code path no longer exists in current version.
