#' Select Optimal Number of Trajectory Groups
#'
#' Fits trajectory models with varying numbers of groups and compares them using
#' information criteria (BIC, AIC) and/or cross-validation to help determine the
#' optimal number of groups.
#'
#' @param data A data frame containing the longitudinal data in long format.
#' @param id Character string specifying the name of the individual identifier variable.
#' @param time Character string specifying the name of the time variable.
#' @param outcome Character string specifying the name of the outcome variable.
#' @param max_groups Maximum number of groups to consider (default = 6). Models with
#'   1 to \code{max_groups} will be fitted.
#' @param criteria Character vector specifying which criteria to use for model selection.
#'   Options are \code{"BIC"} (default), \code{"AIC"}, and \code{"CVE"} (cross-validation error).
#' @param dist Character string specifying the outcome distribution (default = "poisson").
#'   See \code{\link{fitTrajectory}} for options.
#' @param degree Integer specifying the polynomial degree for trajectories (default = 3).
#' @param zero_inflated Logical indicating whether to use zero-inflated models
#'   (default = TRUE).
#' @param cv_folds Number of folds for cross-validation if \code{"CVE"} is in criteria
#'   (default = 5). Individuals are randomly assigned to folds.
#' @param parallel Logical indicating whether to use parallel processing for fitting
#'   multiple models (default = FALSE). If TRUE, uses \code{parallel::mclapply}.
#' @param n_cores Number of cores to use for parallel processing (default = 2).
#'   Only used if \code{parallel = TRUE}.
#' @param verbose Logical indicating whether to print progress messages (default = TRUE).
#' @param ... Additional arguments passed to \code{\link{fitTrajectory}}.
#'
#' @return A list of class \code{"groupSelection"} containing:
#'   \describe{
#'     \item{results}{Data frame with model fit statistics for each number of groups}
#'     \item{best_model}{List with recommended number of groups for each criterion}
#'     \item{models}{List of fitted \code{crimeTrajec} objects (one for each number of groups)}
#'     \item{criteria_used}{Character vector of criteria that were computed}
#'     \item{call}{The matched call}
#'   }
#'
#' @details
#' This function systematically fits trajectory models with 1 to \code{max_groups}
#' and evaluates them using specified criteria:
#'
#' \strong{Bayesian Information Criterion (BIC):}
#' \deqn{BIC = -2 \log L + k \log n}
#' where \eqn{\log L} is the log-likelihood, \eqn{k} is the number of parameters,
#' and \eqn{n} is the sample size. Lower BIC indicates better fit. BIC penalizes
#' model complexity more heavily than AIC and is the recommended criterion for
#' trajectory models (Nagin, 2005).
#'
#' \strong{Akaike Information Criterion (AIC):}
#' \deqn{AIC = -2 \log L + 2k}
#' Lower AIC indicates better fit. AIC is more liberal than BIC.
#'
#' \strong{Cross-Validation Error (CVE):}
#' The data is split into \code{cv_folds} folds by individual (preserving
#' longitudinal structure). For each fold, the model is trained on the remaining
#' folds and the log-likelihood is computed on the held-out fold. The CVE is the
#' negative average test log-likelihood across folds. Lower CVE indicates better
#' predictive performance. This approach follows Nielsen et al. (2012).
#'
#' Cross-validation is computationally intensive and may take considerable time for
#' large datasets or many groups. Consider using \code{parallel = TRUE} to speed up
#' computation.
#'
#' The function also checks for model convergence and warns if any models failed to
#' converge. Models that fail to converge are still included in the results but
#' should be interpreted with caution.
#'
#' @references
#' Nagin, D. S. (2005). \emph{Group-based modeling of development}. Harvard University Press.
#'
#' Nielsen, J. D., Rosenthal, J. S., Sun, Y., Day, D. M., Bevc, I., & Duchesne, T. (2012).
#'   Group-based criminal trajectory analysis using cross-validation criteria.
#'   \emph{Communications in Statistics-Theory and Methods}, 43(20), 4337-4356.
#'
#' Schwarz, G. (1978). Estimating the dimension of a model. \emph{The Annals of
#'   Statistics}, 6(2), 461-464.
#'
#' @examples
#' \dontrun{
#' data(crime_data)
#'
#' # Compare models using BIC only (fast)
#' selection <- selectNumGroups(
#'   data = crime_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "offenses",
#'   max_groups = 5,
#'   criteria = "BIC"
#' )
#' print(selection)
#' plot(selection)
#'
#' # Compare using both BIC and cross-validation (slower)
#' selection_cv <- selectNumGroups(
#'   data = crime_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "offenses",
#'   max_groups = 4,
#'   criteria = c("BIC", "CVE"),
#'   cv_folds = 5
#' )
#' print(selection_cv)
#' }
#'
#' @export
selectNumGroups <- function(data, id, time, outcome,
                           max_groups = 6,
                           criteria = c("BIC", "AIC"),
                           dist = "poisson",
                           degree = 3,
                           zero_inflated = TRUE,
                           cv_folds = 5,
                           parallel = FALSE,
                           n_cores = 2,
                           verbose = TRUE,
                           ...) {

  # Input validation
  criteria <- match.arg(criteria, c("BIC", "AIC", "CVE"), several.ok = TRUE)

  if (max_groups < 1) {
    stop("'max_groups' must be at least 1")
  }

  # Store call
  call <- match.call()

  # Initialize results storage
  results_df <- data.frame(
    n_groups = 1:max_groups,
    log_likelihood = NA,
    AIC = NA,
    BIC = NA,
    CVE = NA,
    n_params = NA,
    converged = NA,
    n_iter = NA
  )

  models <- vector("list", max_groups)

  # Fit models for each number of groups
  if (verbose) {
    cat(sprintf("\nFitting trajectory models with 1 to %d groups...\n", max_groups))
    cat("================================================\n\n")
  }

  for (k in 1:max_groups) {
    if (verbose) {
      cat(sprintf("Fitting model with %d group(s)...\n", k))
    }

    tryCatch({
      # Fit model
      model <- fitTrajectory(
        data = data,
        id = id,
        time = time,
        outcome = outcome,
        dist = dist,
        groups = k,
        degree = degree,
        zero_inflated = zero_inflated,
        verbose = FALSE,
        ...
      )

      # Store model
      models[[k]] <- model

      # Store results
      results_df$log_likelihood[k] <- model$log_likelihood
      results_df$AIC[k] <- model$AIC
      results_df$BIC[k] <- model$BIC
      results_df$n_params[k] <- model$model$n_params
      results_df$converged[k] <- model$converged
      results_df$n_iter[k] <- model$n_iter

      if (verbose) {
        cat(sprintf("  Log-likelihood: %.2f, BIC: %.2f\n",
                   model$log_likelihood, model$BIC))
        if (!model$converged) {
          cat("  WARNING: Model did not converge!\n")
        }
      }

    }, error = function(e) {
      if (verbose) {
        cat(sprintf("  ERROR: Model fitting failed - %s\n", e$message))
      }
      models[[k]] <- NULL
      results_df$converged[k] <- FALSE
    })
  }

  # Compute cross-validation error if requested
  if ("CVE" %in% criteria) {
    if (verbose) {
      cat("\nComputing cross-validation errors...\n")
      cat("=====================================\n\n")
    }

    for (k in 1:max_groups) {
      if (verbose) {
        cat(sprintf("CV for %d group(s)...\n", k))
      }

      cve <- compute_cross_validation(
        data = data,
        id = id,
        time = time,
        outcome = outcome,
        groups = k,
        degree = degree,
        dist = dist,
        zero_inflated = zero_inflated,
        cv_folds = cv_folds,
        parallel = parallel,
        n_cores = n_cores,
        verbose = FALSE,
        ...
      )

      results_df$CVE[k] <- cve

      if (verbose) {
        cat(sprintf("  CVE: %.2f\n", cve))
      }
    }
  }

  # Remove unused columns
  if (!"AIC" %in% criteria) {
    results_df$AIC <- NULL
  }
  if (!"BIC" %in% criteria) {
    results_df$BIC <- NULL
  }
  if (!"CVE" %in% criteria) {
    results_df$CVE <- NULL
  }

  # Determine best model for each criterion
  best_model <- list()

  if ("BIC" %in% criteria) {
    best_bic <- which.min(results_df$BIC)
    best_model$BIC <- best_bic
    if (verbose) {
      cat(sprintf("\nBest model by BIC: %d groups (BIC = %.2f)\n",
                 best_bic, results_df$BIC[best_bic]))
    }
  }

  if ("AIC" %in% criteria) {
    best_aic <- which.min(results_df$AIC)
    best_model$AIC <- best_aic
    if (verbose) {
      cat(sprintf("Best model by AIC: %d groups (AIC = %.2f)\n",
                 best_aic, results_df$AIC[best_aic]))
    }
  }

  if ("CVE" %in% criteria) {
    best_cve <- which.min(results_df$CVE)
    best_model$CVE <- best_cve
    if (verbose) {
      cat(sprintf("Best model by CVE: %d groups (CVE = %.2f)\n",
                 best_cve, results_df$CVE[best_cve]))
    }
  }

  # Create return object
  result <- list(
    results = results_df,
    best_model = best_model,
    models = models,
    criteria_used = criteria,
    call = call
  )

  class(result) <- "groupSelection"

  if (verbose) {
    cat("\n")
  }

  return(result)
}


# Helper function: Compute cross-validation error
compute_cross_validation <- function(data, id, time, outcome, groups, degree,
                                    dist, zero_inflated, cv_folds,
                                    parallel, n_cores, verbose, ...) {

  # Get unique IDs
  ids <- unique(data[[id]])
  n_individuals <- length(ids)

  # Create folds (stratified by individual)
  fold_assignments <- sample(rep(1:cv_folds, length.out = n_individuals))

  # Function to compute fold error
  compute_fold_error <- function(fold) {
    # Split data
    test_ids <- ids[fold_assignments == fold]
    train_ids <- ids[fold_assignments != fold]

    train_data <- data[data[[id]] %in% train_ids, ]
    test_data <- data[data[[id]] %in% test_ids, ]

    # Fit model on training data
    tryCatch({
      model <- fitTrajectory(
        data = train_data,
        id = id,
        time = time,
        outcome = outcome,
        dist = dist,
        groups = groups,
        degree = degree,
        zero_inflated = zero_inflated,
        verbose = FALSE,
        n_starts = 1,  # Reduce computational burden
        ...
      )

      # Calculate log-likelihood on test data
      test_ids_unique <- unique(test_data[[id]])
      test_loglik <- 0

      # Standardize time
      test_data$time_std <- (test_data[[time]] - model$model$time_mean) /
                           model$model$time_sd

      for (test_id in test_ids_unique) {
        ind_data <- test_data[test_data[[id]] == test_id, ]

        ind_lik <- 0
        for (k in 1:groups) {
          group_lik <- calculate_individual_likelihood(
            ind_data$time_std,
            ind_data[[outcome]],
            model$coefficients_std[k, ],
            ifelse(is.null(model$zero_inflation_probs), 0,
                  model$zero_inflation_probs[k]),
            degree,
            dist,
            zero_inflated
          )

          ind_lik <- ind_lik + model$group_probs[k] * group_lik
        }

        test_loglik <- test_loglik + log(ind_lik + 1e-10)
      }

      return(-test_loglik / length(test_ids_unique))  # Negative average log-likelihood

    }, error = function(e) {
      return(NA)
    })
  }

  # Compute fold errors (optionally in parallel)
  if (parallel && requireNamespace("parallel", quietly = TRUE)) {
    fold_errors <- parallel::mclapply(1:cv_folds, compute_fold_error,
                                     mc.cores = n_cores)
    fold_errors <- unlist(fold_errors)
  } else {
    fold_errors <- sapply(1:cv_folds, compute_fold_error)
  }

  # Return mean error
  return(mean(fold_errors, na.rm = TRUE))
}


#' Print Method for groupSelection Objects
#'
#' @param x An object of class \code{"groupSelection"}.
#' @param ... Additional arguments (not currently used).
#'
#' @export
print.groupSelection <- function(x, ...) {
  cat("\n")
  cat("Group-Based Trajectory Model Selection\n")
  cat("=======================================\n\n")

  cat("Call:\n")
  print(x$call)
  cat("\n")

  cat("Model Comparison Results:\n")
  print(x$results, row.names = FALSE, digits = 2)
  cat("\n")

  cat("Recommended Number of Groups:\n")
  for (crit in names(x$best_model)) {
    cat(sprintf("  %s: %d groups\n", crit, x$best_model[[crit]]))
  }
  cat("\n")

  # Check for convergence issues
  non_converged <- sum(!x$results$converged, na.rm = TRUE)
  if (non_converged > 0) {
    cat(sprintf("WARNING: %d model(s) did not converge.\n", non_converged))
    cat("Consider increasing max_iter or adjusting starting values.\n\n")
  }

  invisible(x)
}


#' Plot Method for groupSelection Objects
#'
#' Creates diagnostic plots for model selection showing how fit criteria
#' vary across different numbers of groups.
#'
#' @param x An object of class \code{"groupSelection"}.
#' @param criterion Character string specifying which criterion to plot.
#'   Options are \code{"BIC"} (default), \code{"AIC"}, \code{"CVE"}, or
#'   \code{"all"} to create a multi-panel plot.
#' @param mark_best Logical indicating whether to mark the best model
#'   (default = TRUE).
#' @param ... Additional graphical parameters.
#'
#' @importFrom graphics plot points abline
#' @export
plot.groupSelection <- function(x, criterion = "BIC", mark_best = TRUE, ...) {

  if (criterion == "all") {
    # Multi-panel plot
    n_criteria <- length(x$criteria_used)
    par(mfrow = c(ceiling(n_criteria / 2), 2))

    for (crit in x$criteria_used) {
      plot_single_criterion(x, crit, mark_best)
    }

    par(mfrow = c(1, 1))

  } else {
    # Single plot
    criterion <- match.arg(criterion, c("BIC", "AIC", "CVE", "loglik"))
    plot_single_criterion(x, criterion, mark_best)
  }

  invisible(NULL)
}


# Helper function: Plot single criterion
plot_single_criterion <- function(x, criterion, mark_best) {
  if (!criterion %in% names(x$results)) {
    stop(sprintf("Criterion '%s' was not computed", criterion))
  }

  values <- x$results[[criterion]]
  n_groups <- x$results$n_groups

  # Determine y-label
  ylab <- switch(criterion,
                "BIC" = "BIC (lower is better)",
                "AIC" = "AIC (lower is better)",
                "CVE" = "Cross-Validation Error (lower is better)",
                "log_likelihood" = "Log-Likelihood (higher is better)")

  # Create plot
  plot(n_groups, values,
      type = "b", pch = 19, col = "blue",
      xlab = "Number of Groups",
      ylab = ylab,
      main = paste("Model Selection:", criterion),
      xaxt = "n")

  axis(1, at = n_groups, labels = n_groups)

  # Mark best model
  if (mark_best && criterion %in% names(x$best_model)) {
    best_k <- x$best_model[[criterion]]
    points(best_k, values[best_k], pch = 19, col = "red", cex = 1.5)
    text(best_k, values[best_k], labels = "Best", pos = 3, col = "red")
  }

  # Add grid
  grid()
}
