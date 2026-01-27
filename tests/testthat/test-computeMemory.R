# Load test data once for all tests
data(palaeodataLagged, package = "memoria")

# Small subset to keep tests fast
lagged_small <- palaeodataLagged[1:200, ]

# Minimal shared arguments
base_args <- list(
  lagged.data = lagged_small,
  drivers = c("climate.temperatureAverage", "climate.rainfallAverage"),
  response = "Response",
  repetitions = 3,
  num.trees = 500
)

# --- Input validation ---

test_that("computeMemory rejects invalid inputs", {

  expect_error(
    computeMemory(lagged.data = "not a dataframe", drivers = "x", response = "y"),
    "dataframe"
  )

  expect_error(
    computeMemory(lagged.data = lagged_small, drivers = 123, response = "Response"),
    "character"
  )

  expect_error(
    computeMemory(lagged.data = lagged_small, drivers = "climate.temperatureAverage",
                  response = 42),
    "character"
  )

  expect_error(
    computeMemory(lagged.data = lagged_small,
                  drivers = "climate.temperatureAverage",
                  response = "NonExistent"),
    "not found"
  )

})

# --- Output structure ---

test_that("computeMemory returns correct output structure", {

  result <- do.call(computeMemory, base_args)

  expect_type(result, "list")
  expect_named(result, c("memory", "R2", "prediction", "multicollinearity"))

  # memory slot
  expect_s3_class(result$memory, "data.frame")
  expect_true(all(c("median", "sd", "min", "max", "Variable", "Lag") %in%
                    names(result$memory)))

  # R2 slot
  expect_type(result$R2, "double")
  expect_length(result$R2, base_args$repetitions)

  # prediction slot
  expect_s3_class(result$prediction, "data.frame")
  expect_true(all(c("median", "sd", "min", "max") %in% names(result$prediction)))

  # multicollinearity slot
  expect_s3_class(result$multicollinearity, "data.frame")
  expect_true(all(c("variable", "vif") %in% names(result$multicollinearity)))

})

# --- Variable levels and random term ---

test_that("memory output contains expected variables including Random", {

  result <- do.call(computeMemory, base_args)

  var_levels <- levels(result$memory$Variable)
  expect_true("Response" %in% var_levels)
  expect_true("climate.temperatureAverage" %in% var_levels)
  expect_true("climate.rainfallAverage" %in% var_levels)
  expect_true("Random" %in% var_levels)

})

test_that("add.random = FALSE excludes Random variable", {

  args <- base_args
  args$add.random <- FALSE
  result <- do.call(computeMemory, args)

  var_levels <- levels(result$memory$Variable)
  expect_false("Random" %in% var_levels)

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
    paste("Response", "climate.temperatureAverage", "climate.rainfallAverage",
          sep = "|"),
    colnames(lagged_small)
  )])
  expect_equal(nrow(result$prediction), nrow(model_data))

})

# --- Lag column is numeric ---

test_that("Lag column is numeric", {

  result <- do.call(computeMemory, base_args)
  expect_type(result$memory$Lag, "double")

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
  expect_true("Random" %in% levels(result_wn$memory$Variable))

  args_ac <- base_args
  args_ac$random.mode <- "autocorrelated"
  result_ac <- do.call(computeMemory, args_ac)

  expect_type(result_ac, "list")
  expect_true("Random" %in% levels(result_ac$memory$Variable))

})

# --- Single driver works ---

test_that("computeMemory works with a single driver", {

  result <- computeMemory(
    lagged.data = lagged_small,
    drivers = "climate.temperatureAverage",
    response = "Response",
    repetitions = 3,
    num.trees = 500
  )

  expect_type(result, "list")
  var_levels <- levels(result$memory$Variable)
  expect_true("climate.temperatureAverage" %in% var_levels)
  expect_false("climate.rainfallAverage" %in% var_levels)

})

# --- Response name handling (with and without _0 suffix) ---

test_that("response works with or without _0 suffix", {

  result1 <- do.call(computeMemory, base_args)

  args2 <- base_args
  args2$response <- "Response_0"
  result2 <- do.call(computeMemory, args2)

  # Both should produce the same output slots
  expect_equal(names(result1), names(result2))
  # Both should have matching Variable levels
  expect_equal(levels(result1$memory$Variable), levels(result2$memory$Variable))

})
