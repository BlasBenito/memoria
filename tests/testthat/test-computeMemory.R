# Load test data once for all tests
data(palaeodataLagged, package = "memoria")

# Small subset to keep tests fast
lagged_small <- palaeodataLagged[1:200, ]

# Create a plain dataframe without attributes for testing explicit parameters
lagged_no_attrs <- as.data.frame(lagged_small)
attr(lagged_no_attrs, "response") <- NULL
attr(lagged_no_attrs, "drivers") <- NULL

# Minimal shared arguments (response and drivers auto-detected from attributes)
base_args <- list(
  lagged.data = lagged_small,
  repetitions = 3,
  num.trees = 500
)

# --- Input validation ---

test_that("computeMemory rejects invalid inputs", {
  expect_error(
    computeMemory(
      lagged.data = "not a dataframe",
      drivers = "x",
      response = "y"
    ),
    "dataframe"
  )

  # Test with dataframe without attributes to force explicit parameter checking
  expect_error(
    computeMemory(
      lagged.data = lagged_no_attrs,
      drivers = NULL,
      response = NULL
    ),
    "cannot be NULL"
  )

  expect_error(
    computeMemory(
      lagged.data = lagged_no_attrs,
      drivers = "climate.temperatureAverage",
      response = "NonExistent"
    ),
    "not found"
  )
})

# --- Output structure ---

test_that("computeMemory returns correct output structure", {
  result <- do.call(computeMemory, base_args)

  expect_type(result, "list")
  expect_named(result, c("response", "drivers", "memory", "R2", "prediction"))

  # memory slot
  expect_s3_class(result$memory, "data.frame")
  expect_true(all(
    c("median", "sd", "min", "max", "variable", "lag") %in%
      names(result$memory)
  ))

  # R2 slot
  expect_type(result$R2, "double")
  expect_length(result$R2, base_args$repetitions)

  # prediction slot
  expect_s3_class(result$prediction, "data.frame")
  expect_true(all(
    c("median", "sd", "min", "max") %in% names(result$prediction)
  ))
})

# --- Variable levels and random term ---

test_that("memory output contains expected variables including random", {
  result <- do.call(computeMemory, base_args)

  var_levels <- levels(result$memory$variable)
  expect_true("pollen.pinus" %in% var_levels)
  expect_true("climate.temperatureAverage" %in% var_levels)
  expect_true("climate.rainfallAverage" %in% var_levels)
  expect_true("random" %in% var_levels)
})

# --- R2 values are reasonable ---

test_that("pseudo R-squared values are between 0 and 1", {
  result <- do.call(computeMemory, base_args)
  expect_true(all(result$R2 >= 0 & result$R2 <= 1))
})

# --- Predictions have correct dimensions ---

test_that("predictions have correct number of rows", {
  result <- do.call(computeMemory, base_args)

  # Prediction rows should match number of non-NA rows used in modeling
  model_data <- na.omit(lagged_small[, grep(
    paste(
      "pollen.pinus",
      "climate.temperatureAverage",
      "climate.rainfallAverage",
      sep = "|"
    ),
    colnames(lagged_small)
  )])
  expect_equal(nrow(result$prediction), nrow(model_data))
})

# --- lag column is numeric ---

test_that("lag column is numeric", {
  result <- do.call(computeMemory, base_args)
  expect_type(result$memory$lag, "double")
})

# --- subset.response options ---

test_that("subset.response 'up' and 'down' produce fewer predictions than 'none'", {
  result_none <- do.call(computeMemory, base_args)

  args_up <- base_args
  args_up$subset.response <- "up"
  result_up <- do.call(computeMemory, args_up)

  args_down <- base_args
  args_down$subset.response <- "down"
  result_down <- do.call(computeMemory, args_down)

  expect_lt(nrow(result_up$prediction), nrow(result_none$prediction))
  expect_lt(nrow(result_down$prediction), nrow(result_none$prediction))
})

# --- random.mode options ---

test_that("both random.mode options produce valid output", {
  args_wn <- base_args
  args_wn$random.mode <- "white.noise"
  result_wn <- do.call(computeMemory, args_wn)

  expect_type(result_wn, "list")
  expect_true("random" %in% levels(result_wn$memory$variable))

  args_ac <- base_args
  args_ac$random.mode <- "autocorrelated"
  result_ac <- do.call(computeMemory, args_ac)

  expect_type(result_ac, "list")
  expect_true("random" %in% levels(result_ac$memory$variable))
})

# --- Single driver works ---

test_that("computeMemory works with a single driver", {
  # Create lagged data with only one driver
  data(palaeodata, package = "memoria")
  lagged_single <- lagTimeSeries(
    input.data = palaeodata[1:200, ],
    response = "pollen.pinus",
    drivers = "climate.temperatureAverage",
    time = "age",
    oldest.sample = "last",
    lags = seq(0.2, 1, by = 0.2)
  )

  result <- computeMemory(
    lagged.data = lagged_single,
    repetitions = 3,
    num.trees = 500
  )

  expect_type(result, "list")
  var_levels <- levels(result$memory$variable)
  expect_true("climate.temperatureAverage" %in% var_levels)
  expect_false("climate.rainfallAverage" %in% var_levels)
})

# --- Response name handling (with and without __0 suffix) ---

test_that("response works with or without __0 suffix", {
  result1 <- do.call(computeMemory, base_args)

  args2 <- base_args
  args2$response <- "pollen.pinus__0"
  result2 <- do.call(computeMemory, args2)

  # Both should produce the same output slots
  expect_equal(names(result1), names(result2))
  # Both should have matching variable levels
  expect_equal(levels(result1$memory$variable), levels(result2$memory$variable))
})
