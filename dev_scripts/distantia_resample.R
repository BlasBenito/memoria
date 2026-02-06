# =============================================================================
# Draft: Robust Time Series Resampling
# =============================================================================
#
# This script explores a more robust implementation for time series resampling
# that addresses limitations in distantia::tsl_resample():
#
# Issues with current distantia::tsl_resample():
#
#   1. Requires at least 2 numeric columns (tsl_init limitation)
#   2. spline and loess methods fail with certain datasets (bug in 2.0.2)
#   3. No quality control on interpolation fit
#   4. No value range constraining (can produce values outside original range)
#
# This draft implements resampling directly using base R functions,
# incorporating the quality control from mergePalaeoData().
#
# =============================================================================

library(memoria)
library(zoo)

#' Robust time series resampling with quality control
#'
#' Resamples a dataframe to a new regular time grid with adaptive fitting
#' and value range constraining.
#'
#' @param x A dataframe with a time column and one or more numeric columns.
#' @param time_column Character, name of the time column.
#' @param new_time Numeric vector, the new time points to interpolate to.
#' @param method Character, interpolation method: "linear", "spline", or "loess".
#' @param constrain_range Logical, whether to constrain interpolated values
#'   to the original data range. Default TRUE.
#' @param min_r2 Numeric, minimum R-squared for loess/spline fit. Default 0.99.
#'   Only used when method is "loess" or "spline".
#'
#' @return A dataframe with interpolated values at new_time points.
#'
resample_robust <- function(
    x,
    time_column,
    new_time,
    method = c("linear", "spline", "loess"),
    constrain_range = TRUE,
    min_r2 = 0.99
) {


method <- match.arg(method)

  # Input validation

if (!inherits(x, "data.frame")) {
    stop("x must be a dataframe")
  }

  if (!time_column %in% colnames(x)) {
    stop("time_column '", time_column, "' not found in x")
  }

  if (!is.numeric(x[[time_column]])) {
    stop("time_column must be numeric")
  }

  if (!is.numeric(new_time) || length(new_time) < 2) {
    stop("new_time must be a numeric vector with at least 2 elements
")
  }

  # Get time values
  original_time <- x[[time_column]]

  # Identify numeric columns (excluding time)
  numeric_cols <- sapply(x, is.numeric)
  numeric_cols[time_column] <- FALSE
  var_names <- names(which(numeric_cols))

  if (length(var_names) == 0) {
    stop("No numeric columns found (excluding time column)")
  }

  # Subset new_time to be within original range
  time_range <- range(original_time, na.rm = TRUE)
  new_time_valid <- new_time[new_time >= time_range[1] & new_time <= time_range[2]]

  if (length(new_time_valid) == 0) {
    stop("new_time has no overlap with original time range")
  }

  # Initialize output dataframe
  result <- data.frame(time = new_time_valid)
  names(result) <- time_column

  # Resample each variable
  for (var_name in var_names) {
    y <- x[[var_name]]

    # Skip if all NA
    if (all(is.na(y))) {
      result[[var_name]] <- NA_real_
      next
    }

    # Get original range for constraining
    original_range <- range(y, na.rm = TRUE)

    # Interpolate based on method
    interpolated <- switch(
      method,
      "linear" = resample_linear(original_time, y, new_time_valid),
      "spline" = resample_spline(original_time, y, new_time_valid, min_r2),
      "loess"  = resample_loess(original_time, y, new_time_valid, min_r2)
    )

    # Constrain to original range if requested
    if (constrain_range) {
      interpolated <- pmax(interpolated, original_range[1])
      interpolated <- pmin(interpolated, original_range[2])
    }

    result[[var_name]] <- interpolated
  }

  return(result)
}


#' Linear interpolation using zoo::na.approx
#'
#' @param time Original time points.
#' @param y Original values.
#' @param new_time New time points.
#'
#' @return Interpolated values at new_time.
#'
resample_linear <- function(time, y, new_time) {
  # Create zoo object
  z <- zoo::zoo(y, order.by = time)

  # Merge with new time points
  new_z <- zoo::zoo(NA_real_, order.by = new_time)
  merged <- merge(z, new_z)

  # Interpolate
  interpolated <- zoo::na.approx(merged[, 1], xout = new_time, na.rm = FALSE)

  return(as.numeric(interpolated))
}


#' Spline interpolation with adaptive smoothing
#'
#' Uses stats::smooth.spline with adaptive smoothing parameter selection.
#'
#' @param time Original time points.
#' @param y Original values.
#' @param new_time New time points.
#' @param min_r2 Minimum R-squared threshold.
#'
#' @return Interpolated values at new_time.
#'
resample_spline <- function(time, y, new_time, min_r2 = 0.99) {
  # Remove NAs
  valid <- !is.na(y) & !is.na(time)
  time_clean <- time[valid]
  y_clean <- y[valid]

  if (length(y_clean) < 4) {
    warning("Too few points for spline, falling back to linear")
    return(resample_linear(time, y, new_time))
  }

  # Try smooth.spline with cross-validation first
  fit <- tryCatch(
    {
      # Let smooth.spline choose optimal smoothing via CV
      stats::smooth.spline(x = time_clean, y = y_clean, cv = TRUE)
    },
    error = function(e) {
      # Fall back to default smoothing
      stats::smooth.spline(x = time_clean, y = y_clean)
    }
  )

  # Check fit quality
  fitted_values <- predict(fit, time_clean)$y
  r2 <- cor(fitted_values, y_clean)^2

  # If fit quality is poor, try with less smoothing
  if (r2 < min_r2) {
    # Try range of spar values to find one meeting min_r2
    spar_values <- seq(0.1, 1.0, by = 0.05)

    for (spar in spar_values) {
      fit_try <- tryCatch(
        stats::smooth.spline(x = time_clean, y = y_clean, spar = spar),
        error = function(e) NULL
      )

      if (!is.null(fit_try)) {
        fitted_try <- predict(fit_try, time_clean)$y
        r2_try <- cor(fitted_try, y_clean)^2

        if (r2_try >= min_r2) {
          fit <- fit_try
          r2 <- r2_try
          break
        }
      }
    }

    if (r2 < min_r2) {
      warning(
        "Could not achieve min_r2 = ", min_r2, " for spline. ",
        "Best R2 = ", round(r2, 4), ". Consider using linear method."
      )
    }
  }

  # Predict at new time points
  interpolated <- predict(fit, new_time)$y

  return(interpolated)
}


#' LOESS interpolation with adaptive span selection
#'
#' Implements the adaptive span selection from mergePalaeoData().
#'
#' @param time Original time points.
#' @param y Original values.
#' @param new_time New time points.
#' @param min_r2 Minimum R-squared threshold.
#'
#' @return Interpolated values at new_time.
#'
resample_loess <- function(time, y, new_time, min_r2 = 0.99) {
  # Remove NAs
  valid <- !is.na(y) & !is.na(time)
  time_clean <- time[valid]
  y_clean <- y[valid]
  n <- length(y_clean)

  if (n < 4) {
    warning("Too few points for loess, falling back to linear")
    return(resample_linear(time, y, new_time))
  }

  # Adaptive span selection (from mergePalaeoData)
  # Start with larger span (smoother) and decrease until R2 threshold is met
  span_values <- seq(50 / n, 5 / n, by = -0.0005)
  span_values <- span_values[span_values > 0 & span_values <= 1]

  if (length(span_values) == 0) {
    span_values <- seq(0.75, 0.1, by = -0.05)
  }

  fit <- NULL
  best_r2 <- 0

  for (span in span_values) {
    fit_try <- tryCatch(
      stats::loess(
        y_clean ~ time_clean,
        span = span,
        control = stats::loess.control(surface = "direct")
      ),
      error = function(e) NULL
    )

    if (!is.null(fit_try)) {
      r2_try <- cor(fit_try$fitted, y_clean)^2

      if (r2_try >= min_r2) {
        fit <- fit_try
        best_r2 <- r2_try
        break
      }

      # Keep track of best fit so far
      if (r2_try > best_r2) {
        fit <- fit_try
        best_r2 <- r2_try
      }
    }
  }

  if (is.null(fit)) {
    warning("LOESS fitting failed, falling back to linear")
    return(resample_linear(time, y, new_time))
  }

  if (best_r2 < min_r2) {
    warning(
      "Could not achieve min_r2 = ", min_r2, " for loess. ",
      "Best R2 = ", round(best_r2, 4)
    )
  }

  # Predict at new time points
  interpolated <- predict(fit, newdata = new_time)

  return(as.numeric(interpolated))
}


# =============================================================================
# Wrapper function matching alignTimeSeries interface
# =============================================================================

#' Align time series with different resolutions (robust version)
#'
#' This version uses direct resampling instead of distantia::tsl_resample(),
#' addressing the limitations of that function.
#'
#' @param datasets.list List of named dataframes.
#' @param time.column Character, name of the time column.
#' @param interpolation.interval Numeric, target time resolution.
#' @param method Character, interpolation method.
#' @param constrain_range Logical, constrain to original value range.
#' @param min_r2 Numeric, minimum R-squared for loess/spline.
#'
#' @return A dataframe with aligned time series.
#'
alignTimeSeries_robust <- function(
    datasets.list = NULL,
    time.column = NULL,
    interpolation.interval = NULL,
    method = "loess",
    constrain_range = TRUE,
    min_r2 = 0.99
) {

  # --- Input validation (same as alignTimeSeries) ---

  if (!inherits(datasets.list, "list")) {
    stop("datasets.list must be a list")
  }

  if (length(datasets.list) < 2) {
    stop("datasets.list must have at least 2 elements")
  }

  if (is.null(names(datasets.list)) || any(names(datasets.list) == "")) {
    stop("All elements of datasets.list must be named")
  }

  if (is.null(time.column) || !is.character(time.column)) {
    stop("time.column must be a character string")
  }

  if (is.null(interpolation.interval) || interpolation.interval <= 0) {
    stop("interpolation.interval must be a positive number")
  }

  # Validate each dataset
  for (name in names(datasets.list)) {
    df <- datasets.list[[name]]

    if (!inherits(df, "data.frame")) {
      stop("Element '", name, "' is not a dataframe")
    }

    if (!time.column %in% colnames(df)) {
      stop("Element '", name, "' does not have column '", time.column, "'")
    }
  }

  # --- Compute time intersection ---

  time_ranges <- lapply(datasets.list, function(df) {
    range(df[[time.column]], na.rm = TRUE)
  })

  # Intersection: max of mins, min of maxs
  time_from <- max(sapply(time_ranges, `[`, 1))
  time_to <- min(sapply(time_ranges, `[`, 2))

  if (time_from >= time_to) {
    stop("Time series do not overlap")
  }

  # Create regular time grid
  new_time <- seq(from = time_from, to = time_to, by = interpolation.interval)

  message(
    "Output time range: ", round(time_from, 2), " to ", round(time_to, 2),
    " with ", length(new_time), " samples"
  )

  # --- Resample each dataset ---

  resampled_list <- list()

  for (name in names(datasets.list)) {
    df <- datasets.list[[name]]

    # Keep only numeric columns
    numeric_cols <- sapply(df, is.numeric)
    df <- df[, numeric_cols, drop = FALSE]

    # Resample
    resampled <- resample_robust(
      x = df,
      time_column = time.column,
      new_time = new_time,
      method = method,
      constrain_range = constrain_range,
      min_r2 = min_r2
    )

    # Rename columns with dataset prefix (except time)
    col_names <- colnames(resampled)
    col_names[col_names != time.column] <- paste0(
      name, ".", col_names[col_names != time.column]
    )
    colnames(resampled) <- col_names

    # Remove time column for merging
    resampled[[time.column]] <- NULL

    resampled_list[[name]] <- resampled
  }

  # --- Combine results ---

  output <- data.frame(stats::setNames(list(new_time), time.column))
  output <- cbind(output, do.call(cbind, unname(resampled_list)))

  # Remove rows with NAs
  output <- stats::na.omit(output)
  rownames(output) <- NULL

  return(output)
}


# =============================================================================
# Testing
# =============================================================================

if (FALSE) {  # Set to TRUE to run tests

  # Load test data
  data(pollen, climate, package = "memoria")

  # --- Test 1: Basic functionality ---
  cat("\n=== Test 1: Basic functionality ===\n")

  result <- alignTimeSeries_robust(
    datasets.list = list(pollen = pollen, climate = climate),
    time.column = "age",
    interpolation.interval = 0.5,
    method = "loess"
  )

  cat("Dimensions:", dim(result), "\n")
  cat("Columns:", paste(colnames(result), collapse = ", "), "\n")
  cat("Time range:", range(result$age), "\n")
  cat("Time intervals unique:", unique(diff(result$age)), "\n")

  # --- Test 2: Single variable dataset (works with robust version!) ---
  cat("\n=== Test 2: Single variable dataset ===\n")

  pollen_single <- pollen[, c("age", "pinus")]
  climate_single <- climate[, c("age", "temperatureAverage")]

  result_single <- alignTimeSeries_robust(
    datasets.list = list(pollen = pollen_single, climate = climate_single),
    time.column = "age",
    interpolation.interval = 0.5,
    method = "linear"
  )

  cat("Dimensions:", dim(result_single), "\n")
  cat("Columns:", paste(colnames(result_single), collapse = ", "), "\n")

  # --- Test 3: Compare methods ---
  cat("\n=== Test 3: Compare interpolation methods ===\n")

  for (method in c("linear", "spline", "loess")) {
    cat("\nMethod:", method, "\n")

    result_method <- tryCatch(
      alignTimeSeries_robust(
        datasets.list = list(pollen = pollen, climate = climate),
        time.column = "age",
        interpolation.interval = 1,
        method = method
      ),
      error = function(e) {
        cat("  Error:", e$message, "\n")
        NULL
      }
    )

    if (!is.null(result_method)) {
      cat("  Success! Rows:", nrow(result_method), "\n")
    }
  }

  # --- Test 4: Compare with mergePalaeoData ---
  cat("\n=== Test 4: Compare with mergePalaeoData ===\n")

  result_robust <- alignTimeSeries_robust(
    datasets.list = list(pollen = pollen, climate = climate),
    time.column = "age",
    interpolation.interval = 0.5,
    method = "loess"
  )

  result_original <- mergePalaeoData(
    datasets.list = list(pollen = pollen, climate = climate),
    time.column = "age",
    interpolation.interval = 0.5
  )

  # Compare a column
  col_name <- "pollen.pinus"
  correlation <- cor(
    result_robust[[col_name]],
    result_original[[col_name]],
    use = "complete.obs"
  )

  cat("Correlation of", col_name, "values:", round(correlation, 4), "\n")
  cat("(Should be very high if both use loess with similar parameters)\n")

  # --- Test 5: Value range constraining ---
  cat("\n=== Test 5: Value range constraining ===\n")

  original_range <- range(pollen$pinus)
  result_constrained <- alignTimeSeries_robust(
    datasets.list = list(pollen = pollen, climate = climate),
    time.column = "age",
    interpolation.interval = 0.5,
    method = "linear",
    constrain_range = TRUE
  )

  interpolated_range <- range(result_constrained$pollen.pinus, na.rm = TRUE)

  cat("Original pinus range:", original_range, "\n")
  cat("Interpolated pinus range:", interpolated_range, "\n")
  cat("Within bounds:", all(interpolated_range >= original_range[1] &
                             interpolated_range <= original_range[2]), "\n")
}
