#' Print Method for crimeTrajec Objects
#'
#' Prints a summary of a fitted group-based trajectory model.
#'
#' @param x An object of class \code{"crimeTrajec"}.
#' @param ... Additional arguments (not currently used).
#'
#' @return Invisibly returns the input object.
#'
#' @examples
#' \dontrun{
#' data(crime_data)
#' model <- fitTrajectory(crime_data, id = "id", time = "time",
#'                        outcome = "offenses", groups = 3)
#' print(model)
#' }
#'
#' @export
print.crimeTrajec <- function(x, ...) {
  cat("\n")
  cat("Group-Based Trajectory Model\n")
  cat("=============================\n\n")

  cat("Call:\n")
  print(x$call)
  cat("\n")

  cat("Model Specification:\n")
  cat(sprintf("  Number of groups: %d\n", x$model$groups))
  cat(sprintf("  Polynomial degree: %d\n", x$model$degree))
  cat(sprintf("  Distribution: %s\n", x$model$dist))
  if (x$model$zero_inflated && x$model$dist %in% c("poisson", "zip")) {
    cat("  Zero-inflation: Yes\n")
  }
  cat(sprintf("  Sample size: %d individuals, %d observations\n",
              x$model$n_individuals, x$model$n_obs))
  cat("\n")

  cat("Group Membership Probabilities:\n")
  for (k in 1:x$model$groups) {
    cat(sprintf("  Group %d: %.3f (%.1f%%)\n", k, x$group_probs[k],
                x$group_probs[k] * 100))
  }
  cat("\n")

  cat("Trajectory Coefficients:\n")
  coef_df <- as.data.frame(x$coefficients)
  colnames(coef_df) <- paste0("t^", 0:x$model$degree)
  rownames(coef_df) <- paste("Group", 1:x$model$groups)
  print(round(coef_df, 4))
  cat("\n")

  if (!is.null(x$zero_inflation_probs)) {
    cat("Zero-Inflation Probabilities:\n")
    for (k in 1:x$model$groups) {
      cat(sprintf("  Group %d: %.3f\n", k, x$zero_inflation_probs[k]))
    }
    cat("\n")
  }

  cat("Model Fit:\n")
  cat(sprintf("  Log-likelihood: %.2f\n", x$log_likelihood))
  cat(sprintf("  AIC: %.2f\n", x$AIC))
  cat(sprintf("  BIC: %.2f\n", x$BIC))
  cat(sprintf("  Converged: %s\n", ifelse(x$converged, "Yes", "No")))
  cat(sprintf("  Iterations: %d\n", x$n_iter))
  cat("\n")

  invisible(x)
}


#' Plot Method for crimeTrajec Objects
#'
#' Plots the estimated trajectories for each group in a fitted trajectory model.
#'
#' @param x An object of class \code{"crimeTrajec"}.
#' @param include_ci Logical indicating whether to include confidence bands
#'   (default = TRUE). Currently uses simple approximations based on group
#'   membership uncertainty.
#' @param include_data Logical indicating whether to overlay individual trajectories
#'   (default = FALSE). If TRUE, plots trajectories for a random sample of individuals.
#' @param n_sample If \code{include_data = TRUE}, the number of individuals to plot
#'   (default = 20).
#' @param colors Optional vector of colors for each group. If NULL, uses a default
#'   color palette.
#' @param xlab Label for x-axis (default = "Time").
#' @param ylab Label for y-axis (default = "Outcome").
#' @param main Title for the plot (default = "Estimated Trajectory Groups").
#' @param legend_pos Position for legend (default = "topright").
#' @param ... Additional graphical parameters passed to \code{plot()}.
#'
#' @return Invisibly returns NULL. Creates a plot as a side effect.
#'
#' @examples
#' \dontrun{
#' data(crime_data)
#' model <- fitTrajectory(crime_data, id = "id", time = "time",
#'                        outcome = "offenses", groups = 3)
#' plot(model)
#' plot(model, include_ci = FALSE, include_data = TRUE)
#' }
#'
#' @importFrom graphics plot lines legend polygon
#' @importFrom grDevices rainbow
#' @export
plot.crimeTrajec <- function(x, include_ci = TRUE, include_data = FALSE,
                            n_sample = 20, colors = NULL,
                            xlab = "Time", ylab = "Outcome",
                            main = "Estimated Trajectory Groups",
                            legend_pos = "topright", ...) {

  # Extract fitted values
  fitted_df <- x$fitted_values

  # Set colors
  if (is.null(colors)) {
    colors <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFFF33")[1:x$model$groups]
  }

  # Determine plot range
  y_range <- range(fitted_df$fitted)
  if (include_data) {
    y_range <- range(c(y_range, x$data[[names(x$call$outcome)]]))
  }

  # Create empty plot
  plot(range(fitted_df$time), y_range,
       type = "n", xlab = xlab, ylab = ylab, main = main, ...)

  # Add individual trajectories if requested
  if (include_data) {
    ids <- unique(x$data[[as.character(x$call$id)]])
    if (length(ids) > n_sample) {
      sampled_ids <- sample(ids, n_sample)
    } else {
      sampled_ids <- ids
    }

    for (ind_id in sampled_ids) {
      ind_data <- x$data[x$data[[as.character(x$call$id)]] == ind_id, ]
      lines(ind_data[[as.character(x$call$time)]],
            ind_data[[as.character(x$call$outcome)]],
            col = rgb(0.7, 0.7, 0.7, 0.3), lwd = 0.5)
    }
  }

  # Plot trajectories for each group
  for (k in 1:x$model$groups) {
    group_data <- fitted_df[fitted_df$group == k, ]

    # Sort by time
    group_data <- group_data[order(group_data$time), ]

    # Add confidence interval if requested
    if (include_ci) {
      # Simple approximation: use group probability as uncertainty measure
      se <- sqrt(group_data$fitted * (1 - x$group_probs[k]))
      ci_lower <- pmax(0, group_data$fitted - 1.96 * se)
      ci_upper <- group_data$fitted + 1.96 * se

      # Draw polygon for CI
      polygon(c(group_data$time, rev(group_data$time)),
             c(ci_lower, rev(ci_upper)),
             col = adjustcolor(colors[k], alpha.f = 0.2),
             border = NA)
    }

    # Draw trajectory line
    lines(group_data$time, group_data$fitted,
         col = colors[k], lwd = 2.5)
  }

  # Add legend
  legend_text <- paste0("Group ", 1:x$model$groups, " (",
                       sprintf("%.1f%%", x$group_probs * 100), ")")
  legend(legend_pos, legend = legend_text,
        col = colors[1:x$model$groups], lwd = 2.5, bty = "n")

  invisible(NULL)
}


#' Predict Method for crimeTrajec Objects
#'
#' Predicts group membership probabilities or trajectory values for new or existing data.
#'
#' @param object An object of class \code{"crimeTrajec"}.
#' @param newdata Optional data frame containing new data for prediction. Must have
#'   the same structure as the original data (same variable names for id, time, outcome).
#'   If NULL (default), returns predictions for the original data.
#' @param type Character string specifying the type of prediction. Options are:
#'   \code{"posterior"} (default) for posterior group membership probabilities,
#'   \code{"class"} for predicted group assignments, or
#'   \code{"trajectory"} for predicted trajectory values.
#' @param ... Additional arguments (not currently used).
#'
#' @return Depends on \code{type}:
#'   \itemize{
#'     \item If \code{type = "posterior"}: A matrix of posterior probabilities
#'       (rows = individuals, columns = groups)
#'     \item If \code{type = "class"}: A vector of group assignments (integers 1 to K)
#'     \item If \code{type = "trajectory"}: A data frame with columns: id, time,
#'       group, predicted
#'   }
#'
#' @details
#' For new data, the function calculates the likelihood of each individual's observed
#' trajectory under each group's trajectory model, then applies Bayes' rule using the
#' estimated group membership probabilities to obtain posterior probabilities.
#'
#' When \code{type = "trajectory"}, the function returns the expected trajectory for
#' each individual based on their posterior group membership probabilities (i.e., a
#' weighted average of all group trajectories).
#'
#' @examples
#' \dontrun{
#' data(crime_data)
#' model <- fitTrajectory(crime_data, id = "id", time = "time",
#'                        outcome = "offenses", groups = 3)
#'
#' # Get posterior probabilities for original data
#' post_probs <- predict(model, type = "posterior")
#' head(post_probs)
#'
#' # Get group assignments
#' groups <- predict(model, type = "class")
#' table(groups)
#'
#' # Get predicted trajectories
#' pred_traj <- predict(model, type = "trajectory")
#' head(pred_traj)
#' }
#'
#' @export
predict.crimeTrajec <- function(object, newdata = NULL, type = "posterior", ...) {

  type <- match.arg(type, c("posterior", "class", "trajectory"))

  # If no new data, use original data
  if (is.null(newdata)) {
    if (type == "posterior") {
      return(object$posterior)
    } else if (type == "class") {
      return(object$group_assignments)
    } else if (type == "trajectory") {
      return(predict_trajectory_original(object))
    }
  }

  # Validate new data
  required_vars <- c(as.character(object$call$id),
                    as.character(object$call$time),
                    as.character(object$call$outcome))
  if (!all(required_vars %in% names(newdata))) {
    stop("newdata must contain the same variables as the original data")
  }

  # Standardize time
  newdata$time_std <- (newdata[[as.character(object$call$time)]] -
                      object$model$time_mean) / object$model$time_sd

  # Calculate posterior probabilities for new data
  ids <- unique(newdata[[as.character(object$call$id)]])
  n_individuals <- length(ids)
  posterior <- matrix(0, nrow = n_individuals, ncol = object$model$groups)

  for (i in 1:n_individuals) {
    ind_id <- ids[i]
    ind_data <- newdata[newdata[[as.character(object$call$id)]] == ind_id, ]

    for (k in 1:object$model$groups) {
      # Calculate likelihood
      likelihood <- calculate_individual_likelihood(
        ind_data$time_std,
        ind_data[[as.character(object$call$outcome)]],
        object$coefficients_std[k, ],
        ifelse(is.null(object$zero_inflation_probs), 0, object$zero_inflation_probs[k]),
        object$model$degree,
        object$model$dist,
        object$model$zero_inflated
      )

      posterior[i, k] <- object$group_probs[k] * likelihood
    }
  }

  # Normalize
  posterior <- posterior / rowSums(posterior)
  posterior[is.na(posterior)] <- 1/object$model$groups

  # Return based on type
  if (type == "posterior") {
    rownames(posterior) <- ids
    colnames(posterior) <- paste0("Group", 1:object$model$groups)
    return(posterior)

  } else if (type == "class") {
    class_assignments <- apply(posterior, 1, which.max)
    names(class_assignments) <- ids
    return(class_assignments)

  } else if (type == "trajectory") {
    # Predict trajectories for each individual
    pred_list <- list()

    for (i in 1:n_individuals) {
      ind_id <- ids[i]
      ind_data <- newdata[newdata[[as.character(object$call$id)]] == ind_id, ]

      ind_pred <- data.frame(
        id = ind_id,
        time = ind_data[[as.character(object$call$time)]],
        predicted = 0
      )

      # Weighted average of group trajectories
      for (k in 1:object$model$groups) {
        lambda <- calculate_trajectory(ind_data$time_std,
                                      object$coefficients_std[k, ],
                                      object$model$degree)

        if (object$model$dist %in% c("poisson", "zip", "negbin")) {
          fitted_vals <- exp(lambda)
        } else {
          fitted_vals <- lambda
        }

        ind_pred$predicted <- ind_pred$predicted + posterior[i, k] * fitted_vals
      }

      pred_list[[i]] <- ind_pred
    }

    return(do.call(rbind, pred_list))
  }
}


# Helper function to predict trajectories for original data
predict_trajectory_original <- function(object) {
  ids <- unique(object$data[[as.character(object$call$id)]])
  n_individuals <- length(ids)

  pred_list <- list()

  for (i in 1:n_individuals) {
    ind_id <- ids[i]
    ind_data <- object$data[object$data[[as.character(object$call$id)]] == ind_id, ]

    ind_pred <- data.frame(
      id = ind_id,
      time = ind_data[[as.character(object$call$time)]],
      predicted = 0
    )

    # Weighted average of group trajectories
    for (k in 1:object$model$groups) {
      lambda <- calculate_trajectory(ind_data$time_std,
                                    object$coefficients_std[k, ],
                                    object$model$degree)

      if (object$model$dist %in% c("poisson", "zip", "negbin")) {
        fitted_vals <- exp(lambda)
      } else {
        fitted_vals <- lambda
      }

      ind_pred$predicted <- ind_pred$predicted + object$posterior[i, k] * fitted_vals
    }

    pred_list[[i]] <- ind_pred
  }

  return(do.call(rbind, pred_list))
}


#' Summary Method for crimeTrajec Objects
#'
#' Provides a detailed summary of a fitted group-based trajectory model.
#'
#' @param object An object of class \code{"crimeTrajec"}.
#' @param ... Additional arguments (not currently used).
#'
#' @return A list of class \code{"summary.crimeTrajec"} containing:
#'   \describe{
#'     \item{call}{The model call}
#'     \item{model}{Model specifications}
#'     \item{group_summary}{Data frame with group sizes and proportions}
#'     \item{coefficients}{Trajectory coefficients matrix}
#'     \item{fit_statistics}{Model fit statistics (log-likelihood, AIC, BIC)}
#'   }
#'
#' @export
summary.crimeTrajec <- function(object, ...) {
  # Create group summary table
  group_counts <- table(object$group_assignments)
  group_summary <- data.frame(
    Group = 1:object$model$groups,
    N = as.vector(group_counts),
    Proportion = as.vector(group_counts) / sum(group_counts),
    Posterior_Prob = object$group_probs
  )

  # Fit statistics
  fit_stats <- data.frame(
    Statistic = c("Log-Likelihood", "AIC", "BIC", "N Observations", "N Individuals", "N Parameters"),
    Value = c(object$log_likelihood, object$AIC, object$BIC,
             object$model$n_obs, object$model$n_individuals, object$model$n_params)
  )

  summary_obj <- list(
    call = object$call,
    model = object$model,
    group_summary = group_summary,
    coefficients = object$coefficients,
    fit_statistics = fit_stats,
    converged = object$converged,
    n_iter = object$n_iter
  )

  class(summary_obj) <- "summary.crimeTrajec"
  return(summary_obj)
}


#' @export
print.summary.crimeTrajec <- function(x, ...) {
  cat("\n")
  cat("Summary of Group-Based Trajectory Model\n")
  cat("========================================\n\n")

  cat("Call:\n")
  print(x$call)
  cat("\n")

  cat("Model Specification:\n")
  cat(sprintf("  Groups: %d, Degree: %d, Distribution: %s\n",
              x$model$groups, x$model$degree, x$model$dist))
  cat(sprintf("  Converged: %s (Iterations: %d)\n", x$converged, x$n_iter))
  cat("\n")

  cat("Group Summary:\n")
  print(x$group_summary, row.names = FALSE, digits = 3)
  cat("\n")

  cat("Trajectory Coefficients:\n")
  print(round(x$coefficients, 4))
  cat("\n")

  cat("Model Fit Statistics:\n")
  print(x$fit_statistics, row.names = FALSE, digits = 2)
  cat("\n")

  invisible(x)
}
