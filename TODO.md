# TODO — Issues Needing Decisions

## 1. Division by zero in `extractMemoryFeatures.R`
When all memory strengths are 0, the dominance calculation divides by zero. A guard clause is needed, but the desired return value (NA, 0, or NaN) should be decided by the maintainer.

## 2. Variable name `_` restriction not enforced at runtime in `computeMemory.R`
The documentation warns that driver names must not contain `_`, but this is never validated. Adding a runtime check would prevent silent column-name parsing errors downstream.

## 3. `aes_string()` and `guide=FALSE` deprecation in `plotInteraction.R`
`aes_string()` is deprecated in favor of `aes()` with `.data[[...]]` (ggplot2 >= 3.0.0). `guide=FALSE` should be `guide="none"`. These produce deprecation warnings.

## 4. Fragile type coercion via `c()` in `extractMemoryFeatures.R:215`
`c()` is used to combine values that may be of mixed types, silently coercing to character. Using `list()` or explicit type handling would be safer.

## 5. `selected.columns == 1` scalar check in `runExperiment.R:77`
`if(selected.columns == 1)` tests the first element, not the length. If `selected.columns` is a vector of length > 1, this gives a warning and uses only the first element. Likely should be `length(selected.columns) == 1`.

## 6. Dead code in `mergePalaeoData.R:145`
Unreachable or unused code path that could be cleaned up.
