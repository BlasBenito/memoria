#' Plots response surfaces for tree-based models.
#'
#' @description Plots a response surface plot or interaction plot (2 predictors and a model response) for models of the functions \code{\link[ranger]{ranger}}, \code{\link[randomForest]{randomForest}}, and \code{\link[rpart]{rpart}}. It also plots the observed data on top of the predicted surface.
#'
#' @usage plotInteraction(
#'   model = NULL,
#'   data = NULL,
#'   x = NULL,
#'   y = NULL,
#'   z = NULL,
#'   grid = 100,
#'   point.size.range = c(0.1, 1)
#'   )
#'
#' @param model a model object produced by the functions \code{\link[ranger]{ranger}}, \code{\link[randomForest]{randomForest}}, or \code{\link[rpart]{rpart}}.
#' @param data dataframe used to fit the model.
#' @param x character string, name of column in \code{data} to be plotted in the x axis.
#' @param y character string, name of column in \code{data} to be plotted in the y axis.
#' @param z character string, name of the response variable column in \code{data}, plotted as the surface.
#' @param grid numeric, resolution of the x and y axes.
#' @param point.size.range numeric vector with two values defining the range size of the points representing the observed data.
#'
#' @author Blas M. Benito  <blasbenito@gmail.com>
#'
#' @return A ggplot object.
#'
#'@export
plotInteraction <- function(
  model = NULL,
  data = NULL,
  x = NULL,
  y = NULL,
  z = NULL,
  grid = 100,
  point.size.range = c(0.1, 1)
) {
  #from https://stackoverflow.com/a/49167211
  #to ensure that scale_fill_viridis returns a transparent color scale
  vir_lite <- function(cols, ds = 0.4, dv = 0.7) {
    cols <- rgb2hsv(col2rgb(cols))
    cols["v", ] <- cols["v", ] + dv * (1 - cols["v", ])
    cols["s", ] <- ds * cols["s", ]
    apply(cols, 2, function(x) hsv(x[1], x[2], x[3]))
  }

  #generating grid
  newdata <- expand.grid(
    seq(min(data[[x]]), max(data[[x]]), length.out = grid),
    seq(min(data[[y]]), max(data[[y]]), length.out = grid)
  )
  colnames(newdata) <- c(x, y)

  #setting the other variables to their mean
  other_vars <- setdiff(names(data), c(x, y))
  n <- nrow(data)
  for (i in other_vars) {
    # newdata[, i] <- data[, i][sample(n, n)]
    newdata[, i] <- mean(data[, i])
  }

  #predicting different types of models
  if (inherits(model, "ranger")) {
    newdata$prediction <- predict(model, newdata)$predictions
  }
  if (inherits(model, "rpart")) {
    newdata$prediction <- predict(model, newdata, type = "vector")
  }
  if (!inherits(model, c("ranger", "rpart"))) {
    newdata$prediction <- predict(model, newdata, type = "response")
  }

  #if more than 15 unique predictions,
  if (length(unique(newdata$prediction)) < 15) {
    newdata$prediction <- round(newdata$prediction, 0)
    newdata$prediction <- as.factor(newdata$prediction)

    p1 <- ggplot(newdata, aes_string(x = x, y = y)) +
      geom_raster(aes(fill = prediction), alpha = 0.3) +
      scale_fill_viridis(discrete = TRUE) +
      guides(fill = guide_legend(override.aes = list(alpha = 0.2))) +
      geom_point(
        data = data,
        aes_string(x = x, y = y, color = z, size = z, alpha = z),
        shape = 16
      ) +
      scale_color_gradient(low = "white", high = "black", guide = FALSE) +
      scale_size_continuous(range = point.size.range) +
      scale_alpha_continuous(guide = FALSE) +
      labs(fill = "Predicted", size = "Observed")
  } else {
    p1 <- ggplot(newdata, aes_string(x = x, y = y)) +
      geom_raster(aes(fill = prediction), alpha = 0.8) +
      scale_fill_gradientn(colors = vir_lite(viridis(10))) +
      geom_point(
        data = data,
        aes_string(x = x, y = y, color = z, size = z, alpha = z),
        shape = 16
      ) +
      scale_color_gradient(low = "white", high = "black", guide = FALSE) +
      scale_size_continuous(range = point.size.range) +
      scale_alpha_continuous(guide = FALSE) +
      labs(fill = "Predicted", size = "Observed")
  }

  return(p1)
}
