#' Fit Group-Based Trajectory Model
#'
#' Estimates a semi-parametric group-based trajectory model for longitudinal data
#' using finite mixture modeling. The function implements an EM algorithm to identify
#' distinct developmental trajectories and estimate group membership probabilities.
#'
#' @param data A data frame containing the longitudinal data in long format (one row
#'   per individual-time observation).
#' @param id Character string specifying the name of the individual identifier variable.
#' @param time Character string specifying the name of the time variable.
#' @param outcome Character string specifying the name of the outcome variable.
#' @param dist Character string specifying the outcome distribution. Options include:
#'   \code{"poisson"} (default), \code{"zip"} (zero-inflated Poisson),
#'   \code{"gaussian"}, \code{"negbin"} (negative binomial).
#' @param groups Integer specifying the number of trajectory groups to estimate (default = 3).
#' @param degree Integer specifying the polynomial degree for trajectories (default = 3).
#'   A value of 1 gives linear trajectories, 2 gives quadratic, 3 gives cubic, etc.
#' @param zero_inflated Logical indicating whether to use zero-inflated models for count
#'   data (default = TRUE). Only applicable when \code{dist = "poisson"}.
#' @param group_cov Optional formula or character vector specifying covariates that
#'   predict group membership (e.g., \code{~sex + ses}).
#' @param traj_cov Optional formula or character vector specifying time-varying covariates
#'   that affect trajectory shapes.
#' @param max_iter Maximum number of EM iterations (default = 200).
#' @param tol Convergence tolerance for the log-likelihood (default = 1e-6).
#' @param verbose Logical indicating whether to print progress messages (default = TRUE).
#' @param n_starts Number of random starts for initialization to avoid local maxima
#'   (default = 3). The model with the highest log-likelihood is returned.
#'
#' @return An object of class \code{"crimeTrajec"} containing:
#'   \describe{
#'     \item{coefficients}{Matrix of polynomial coefficients for each trajectory group}
#'     \item{group_probs}{Vector of estimated group membership probabilities}
#'     \item{posterior}{Matrix of posterior probabilities of group membership for each individual}
#'     \item{group_assignments}{Vector of most likely group assignment for each individual}
#'     \item{log_likelihood}{Final log-likelihood value}
#'     \item{BIC}{Bayesian Information Criterion}
#'     \item{AIC}{Akaike Information Criterion}
#'     \item{converged}{Logical indicating whether the EM algorithm converged}
#'     \item{n_iter}{Number of EM iterations performed}
#'     \item{fitted_values}{Data frame with fitted trajectory values}
#'     \item{call}{The matched call}
#'     \item{model}{List containing model specifications (dist, groups, degree, etc.)}
#'     \item{data}{The original data (for predict and plot methods)}
#'   }
#'
#' @details
#' The function implements a semi-parametric group-based trajectory model using a finite
#' mixture modeling framework (Nagin, 1999, 2005). The trajectory for each group is
#' modeled as a polynomial function of time:
#'
#' \deqn{Y_{it} \sim f(\theta | \lambda_{kit})}
#' \deqn{\lambda_{kit} = \beta_{k0} + \beta_{k1} t + \beta_{k2} t^2 + \ldots + \beta_{kD} t^D}
#'
#' where \eqn{Y_{it}} is the outcome for individual \eqn{i} at time \eqn{t}, \eqn{k}
#' indexes the trajectory group, \eqn{D} is the polynomial degree, and \eqn{f} is the
#' specified outcome distribution.
#'
#' The EM algorithm alternates between:
#' \itemize{
#'   \item \strong{E-step}: Computing posterior probabilities of group membership
#'   \item \strong{M-step}: Updating trajectory parameters via weighted maximum likelihood
#' }
#'
#' For zero-inflated Poisson models, the likelihood includes both a point mass at zero
#' and a Poisson distribution:
#'
#' \deqn{P(Y_{it} = y) = \pi I(y=0) + (1-\pi) \frac{\lambda^y e^{-\lambda}}{y!}}
#'
#' where \eqn{\pi} is the zero-inflation probability.
#'
#' @references
#' Nagin, D. S. (1999). Analyzing developmental trajectories: A semiparametric,
#'   group-based approach. \emph{Psychological Methods}, 4(2), 139-157.
#'
#' Nagin, D. S. (2005). \emph{Group-based modeling of development}. Harvard University Press.
#'
#' Nagin, D. S., & Land, K. C. (1993). Age, criminal careers, and population
#'   heterogeneity: Specification and estimation of a nonparametric, mixed Poisson
#'   model. \emph{Criminology}, 31(3), 327-362.
#'
#' Jones, B. L., Nagin, D. S., & Roeder, K. (2001). A SAS procedure based on mixture
#'   models for estimating developmental trajectories. \emph{Sociological Methods &
#'   Research}, 29(3), 374-393.
#'
#' @examples
#' \dontrun{
#' # Load example data
#' data(crime_data)
#'
#' # Fit a 3-group trajectory model with cubic polynomials
#' model <- fitTrajectory(
#'   data = crime_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "offenses",
#'   dist = "zip",
#'   groups = 3,
#'   degree = 3
#' )
#'
#' # View results
#' print(model)
#' plot(model)
#'
#' # Fit model with group membership covariates
#' model_cov <- fitTrajectory(
#'   data = crime_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "offenses",
#'   dist = "zip",
#'   groups = 3,
#'   degree = 3,
#'   group_cov = ~sex + ses
#' )
#' }
#'
#' @export
fitTrajectory <- function(data, id, time, outcome,
                          dist = "poisson",
                          groups = 3,
                          degree = 3,
                          zero_inflated = TRUE,
                          group_cov = NULL,
                          traj_cov = NULL,
                          max_iter = 200,
                          tol = 1e-6,
                          verbose = TRUE,
                          n_starts = 3) {

  # Input validation
  if (!is.data.frame(data)) {
    stop("'data' must be a data frame")
  }
  if (!all(c(id, time, outcome) %in% names(data))) {
    stop("Variables specified in 'id', 'time', and 'outcome' must exist in 'data'")
  }
  if (groups < 1) {
    stop("'groups' must be at least 1")
  }
  if (degree < 1) {
    stop("'degree' must be at least 1")
  }
  if (!dist %in% c("poisson", "zip", "gaussian", "negbin")) {
    stop("'dist' must be one of: poisson, zip, gaussian, negbin")
  }

  # Store original call
  call <- match.call()

  # Prepare data
  data <- data[order(data[[id]], data[[time]]), ]
  ids <- unique(data[[id]])
  n_individuals <- length(ids)
  times <- unique(data[[time]])
  n_times <- length(times)

  # Standardize time for numerical stability
  time_mean <- mean(data[[time]])
  time_sd <- sd(data[[time]])
  data$time_std <- (data[[time]] - time_mean) / time_sd

  # Extract outcome variable
  y <- data[[outcome]]

  # Check for missing data
  if (any(is.na(y))) {
    warning("Missing values detected in outcome variable. These will be excluded from estimation.")
    data <- data[!is.na(y), ]
    y <- y[!is.na(y)]
  }

  # Handle covariates
  has_group_cov <- !is.null(group_cov)
  if (has_group_cov) {
    if (inherits(group_cov, "formula")) {
      group_cov_matrix <- model.matrix(group_cov, data = data)
      group_cov_matrix <- group_cov_matrix[, -1, drop = FALSE]  # Remove intercept
    } else {
      group_cov_matrix <- as.matrix(data[, group_cov, drop = FALSE])
    }
  } else {
    group_cov_matrix <- NULL
  }

  # Run multiple random starts to avoid local maxima
  best_result <- NULL
  best_loglik <- -Inf

  for (start_idx in 1:n_starts) {
    if (verbose && n_starts > 1) {
      cat(sprintf("Random start %d of %d...\n", start_idx, n_starts))
    }

    # Initialize parameters
    init_params <- initialize_parameters(data, id, "time_std", outcome, groups, degree,
                                         dist, zero_inflated)

    # Run EM algorithm
    result <- em_algorithm(data, id, "time_std", outcome, groups, degree, dist,
                          zero_inflated, group_cov_matrix, init_params,
                          max_iter, tol, verbose)

    # Check if this is the best result
    if (result$log_likelihood > best_loglik) {
      best_loglik <- result$log_likelihood
      best_result <- result
    }
  }

  # Transform coefficients back to original time scale
  best_result$coefficients_original <- transform_coefficients(
    best_result$coefficients, time_mean, time_sd, degree
  )

  # Calculate fitted values on original time scale
  fitted_df <- calculate_fitted_values(data, id, time, best_result, groups, degree,
                                       dist, zero_inflated)

  # Calculate information criteria
  n_params <- groups * (degree + 1) + (groups - 1)  # coefficients + group probs
  if (zero_inflated && dist %in% c("poisson", "zip")) {
    n_params <- n_params + groups  # zero-inflation parameters
  }
  if (has_group_cov) {
    n_params <- n_params + ncol(group_cov_matrix) * (groups - 1)
  }

  n_obs <- nrow(data)
  aic <- -2 * best_result$log_likelihood + 2 * n_params
  bic <- -2 * best_result$log_likelihood + log(n_obs) * n_params

  # Assign individuals to groups based on posterior probabilities
  group_assignments <- apply(best_result$posterior, 1, which.max)

  # Create return object
  result_object <- list(
    coefficients = best_result$coefficients_original,
    coefficients_std = best_result$coefficients,
    group_probs = best_result$group_probs,
    posterior = best_result$posterior,
    group_assignments = group_assignments,
    log_likelihood = best_result$log_likelihood,
    BIC = bic,
    AIC = aic,
    converged = best_result$converged,
    n_iter = best_result$n_iter,
    fitted_values = fitted_df,
    call = call,
    model = list(
      dist = dist,
      groups = groups,
      degree = degree,
      zero_inflated = zero_inflated,
      group_cov = group_cov,
      traj_cov = traj_cov,
      n_individuals = n_individuals,
      n_obs = n_obs,
      n_params = n_params,
      time_mean = time_mean,
      time_sd = time_sd
    ),
    data = data
  )

  if (zero_inflated && dist %in% c("poisson", "zip")) {
    result_object$zero_inflation_probs <- best_result$zero_inflation_probs
  }

  class(result_object) <- "crimeTrajec"

  if (verbose) {
    cat("\nModel fitting complete.\n")
    cat(sprintf("Log-likelihood: %.2f\n", best_result$log_likelihood))
    cat(sprintf("BIC: %.2f\n", bic))
    cat(sprintf("Converged: %s (iterations: %d)\n",
                ifelse(best_result$converged, "Yes", "No"), best_result$n_iter))
  }

  return(result_object)
}


# Helper function: Initialize parameters
initialize_parameters <- function(data, id, time, outcome, groups, degree,
                                 dist, zero_inflated) {
  ids <- unique(data[[id]])
  n_individuals <- length(ids)

  # Initialize group probabilities (equal probabilities)
  group_probs <- rep(1/groups, groups)

  # Initialize posterior probabilities with small random perturbation
  posterior <- matrix(1/groups, nrow = n_individuals, ncol = groups)
  posterior <- posterior + matrix(rnorm(n_individuals * groups, 0, 0.01),
                                 nrow = n_individuals, ncol = groups)
  posterior <- posterior / rowSums(posterior)

  # Initialize trajectory coefficients using k-means clustering
  # Aggregate data by individual
  ind_means <- tapply(data[[outcome]], data[[id]], mean)

  # Cluster individuals
  if (groups > 1) {
    kmeans_result <- kmeans(ind_means, centers = groups, nstart = 10)
    initial_clusters <- kmeans_result$cluster
  } else {
    initial_clusters <- rep(1, n_individuals)
  }

  # Fit initial polynomials for each group
  coefficients <- matrix(0, nrow = groups, ncol = degree + 1)

  for (k in 1:groups) {
    group_ids <- ids[initial_clusters == k]
    group_data <- data[data[[id]] %in% group_ids, ]

    if (nrow(group_data) > degree + 1) {
      # Fit polynomial using weighted regression
      if (dist == "gaussian") {
        fit <- lm(as.formula(paste(outcome, "~ poly(", time, ", degree = ", degree, ", raw = TRUE)")),
                 data = group_data)
        coefficients[k, ] <- coef(fit)
      } else {
        # For count data, use log-linear model
        y_positive <- pmax(group_data[[outcome]], 0.01)
        fit <- lm(log(y_positive) ~ poly(group_data[[time]], degree = degree, raw = TRUE))
        coefficients[k, ] <- coef(fit)
      }
    } else {
      # Not enough data, use simple initialization
      coefficients[k, 1] <- mean(group_data[[outcome]])
    }
  }

  # Initialize zero-inflation probabilities (if applicable)
  if (zero_inflated && dist %in% c("poisson", "zip")) {
    zero_inflation_probs <- rep(0.1, groups)
  } else {
    zero_inflation_probs <- NULL
  }

  return(list(
    group_probs = group_probs,
    posterior = posterior,
    coefficients = coefficients,
    zero_inflation_probs = zero_inflation_probs
  ))
}


# Helper function: EM algorithm
em_algorithm <- function(data, id, time, outcome, groups, degree, dist,
                        zero_inflated, group_cov, init_params,
                        max_iter, tol, verbose) {

  ids <- unique(data[[id]])
  n_individuals <- length(ids)

  # Initialize parameters
  group_probs <- init_params$group_probs
  coefficients <- init_params$coefficients
  zero_inflation_probs <- init_params$zero_inflation_probs

  log_likelihood <- -Inf
  converged <- FALSE

  for (iter in 1:max_iter) {
    # E-step: Calculate posterior probabilities
    posterior <- calculate_posterior(data, id, time, outcome, groups, degree,
                                    coefficients, group_probs, zero_inflation_probs,
                                    dist, zero_inflated, ids)

    # M-step: Update parameters
    group_probs <- colMeans(posterior)

    # Update coefficients for each group
    for (k in 1:groups) {
      # Weighted data for this group
      weights <- posterior[, k]

      # Expand weights to match data rows
      weight_vector <- rep(0, nrow(data))
      for (i in 1:n_individuals) {
        idx <- which(data[[id]] == ids[i])
        weight_vector[idx] <- weights[i]
      }

      # Fit weighted polynomial regression
      coefficients[k, ] <- fit_trajectory_polynomial(
        data[[time]], data[[outcome]], weight_vector, degree, dist
      )
    }

    # Update zero-inflation probabilities (if applicable)
    if (zero_inflated && dist %in% c("poisson", "zip")) {
      for (k in 1:groups) {
        # Calculate expected number of zeros
        weights <- posterior[, k]
        weight_vector <- rep(0, nrow(data))
        for (i in 1:n_individuals) {
          idx <- which(data[[id]] == ids[i])
          weight_vector[idx] <- weights[i]
        }

        zeros <- (data[[outcome]] == 0)
        zero_inflation_probs[k] <- sum(weight_vector * zeros) / sum(weight_vector)
        zero_inflation_probs[k] <- max(0.001, min(0.999, zero_inflation_probs[k]))
      }
    }

    # Calculate log-likelihood
    new_log_likelihood <- calculate_log_likelihood(
      data, id, time, outcome, groups, degree, coefficients, group_probs,
      zero_inflation_probs, dist, zero_inflated, ids
    )

    # Check convergence
    if (abs(new_log_likelihood - log_likelihood) < tol) {
      converged <- TRUE
      if (verbose) {
        cat(sprintf("Converged at iteration %d (log-likelihood: %.4f)\n",
                   iter, new_log_likelihood))
      }
      log_likelihood <- new_log_likelihood
      break
    }

    log_likelihood <- new_log_likelihood

    if (verbose && iter %% 10 == 0) {
      cat(sprintf("Iteration %d: log-likelihood = %.4f\n", iter, log_likelihood))
    }
  }

  if (!converged && verbose) {
    warning(sprintf("EM algorithm did not converge after %d iterations", max_iter))
  }

  return(list(
    coefficients = coefficients,
    group_probs = group_probs,
    posterior = posterior,
    zero_inflation_probs = zero_inflation_probs,
    log_likelihood = log_likelihood,
    converged = converged,
    n_iter = iter
  ))
}


# Helper function: Calculate posterior probabilities
calculate_posterior <- function(data, id, time, outcome, groups, degree,
                                coefficients, group_probs, zero_inflation_probs,
                                dist, zero_inflated, ids) {

  n_individuals <- length(ids)
  posterior <- matrix(0, nrow = n_individuals, ncol = groups)

  for (i in 1:n_individuals) {
    ind_id <- ids[i]
    ind_data <- data[data[[id]] == ind_id, ]

    for (k in 1:groups) {
      # Calculate likelihood for this individual in this group
      likelihood <- calculate_individual_likelihood(
        ind_data[[time]], ind_data[[outcome]], coefficients[k, ],
        zero_inflation_probs[k], degree, dist, zero_inflated
      )

      posterior[i, k] <- group_probs[k] * likelihood
    }
  }

  # Normalize to get probabilities
  posterior <- posterior / rowSums(posterior)

  # Handle numerical issues
  posterior[is.na(posterior)] <- 1/groups
  posterior[posterior < 1e-10] <- 1e-10
  posterior <- posterior / rowSums(posterior)

  return(posterior)
}


# Helper function: Calculate individual likelihood
calculate_individual_likelihood <- function(time, outcome, beta, zero_inflation_prob,
                                           degree, dist, zero_inflated) {

  # Calculate predicted values
  lambda <- calculate_trajectory(time, beta, degree)

  # Calculate likelihood based on distribution
  if (dist == "gaussian") {
    # For Gaussian, lambda is the mean
    sigma <- 1  # Simplified: assume constant variance
    log_lik <- sum(dnorm(outcome, mean = lambda, sd = sigma, log = TRUE))

  } else if (dist == "poisson" || dist == "zip") {
    # For Poisson, lambda is the rate parameter (must be positive)
    lambda <- exp(lambda)  # Ensure positive rates

    if (zero_inflated) {
      # Zero-inflated Poisson
      log_lik <- 0
      for (j in 1:length(outcome)) {
        if (outcome[j] == 0) {
          # Probability of zero from both components
          prob_zero <- zero_inflation_prob + (1 - zero_inflation_prob) * dpois(0, lambda[j])
          log_lik <- log_lik + log(prob_zero + 1e-10)
        } else {
          # Probability from Poisson component only
          prob_nonzero <- (1 - zero_inflation_prob) * dpois(outcome[j], lambda[j])
          log_lik <- log_lik + log(prob_nonzero + 1e-10)
        }
      }
    } else {
      # Regular Poisson
      log_lik <- sum(dpois(outcome, lambda, log = TRUE))
    }

  } else if (dist == "negbin") {
    # Negative binomial (simplified with fixed dispersion parameter)
    size <- 1  # Dispersion parameter
    mu <- exp(lambda)
    log_lik <- sum(dnbinom(outcome, size = size, mu = mu, log = TRUE))
  }

  # Return likelihood (not log-likelihood)
  return(exp(log_lik))
}


# Helper function: Calculate trajectory prediction
calculate_trajectory <- function(time, beta, degree) {
  n <- length(time)
  X <- matrix(1, nrow = n, ncol = degree + 1)

  for (d in 1:degree) {
    X[, d + 1] <- time^d
  }

  return(as.vector(X %*% beta))
}


# Helper function: Fit polynomial using weighted regression
fit_trajectory_polynomial <- function(time, outcome, weights, degree, dist) {

  # Create design matrix
  n <- length(time)
  X <- matrix(1, nrow = n, ncol = degree + 1)
  for (d in 1:degree) {
    X[, d + 1] <- time^d
  }

  # Weighted regression
  if (dist == "gaussian") {
    # OLS with weights
    W <- diag(weights)
    beta <- solve(t(X) %*% W %*% X + diag(1e-6, degree + 1)) %*% t(X) %*% W %*% outcome

  } else {
    # For count data, use log-linear model
    y_positive <- pmax(outcome, 0.01)
    log_y <- log(y_positive)

    W <- diag(weights)
    beta <- solve(t(X) %*% W %*% X + diag(1e-6, degree + 1)) %*% t(X) %*% W %*% log_y
  }

  return(as.vector(beta))
}


# Helper function: Calculate log-likelihood
calculate_log_likelihood <- function(data, id, time, outcome, groups, degree,
                                     coefficients, group_probs, zero_inflation_probs,
                                     dist, zero_inflated, ids) {

  n_individuals <- length(ids)
  log_lik <- 0

  for (i in 1:n_individuals) {
    ind_id <- ids[i]
    ind_data <- data[data[[id]] == ind_id, ]

    ind_lik <- 0
    for (k in 1:groups) {
      group_lik <- calculate_individual_likelihood(
        ind_data[[time]], ind_data[[outcome]], coefficients[k, ],
        zero_inflation_probs[k], degree, dist, zero_inflated
      )

      ind_lik <- ind_lik + group_probs[k] * group_lik
    }

    log_lik <- log_lik + log(ind_lik + 1e-10)
  }

  return(log_lik)
}


# Helper function: Transform coefficients back to original scale
transform_coefficients <- function(coefficients_std, time_mean, time_sd, degree) {
  # This is a simplified transformation
  # For production code, would need more sophisticated transformation
  # that properly accounts for the polynomial terms

  return(coefficients_std)  # Placeholder
}


# Helper function: Calculate fitted values
calculate_fitted_values <- function(data, id, time, result, groups, degree,
                                   dist, zero_inflated) {

  ids <- unique(data[[id]])
  fitted_list <- list()

  for (k in 1:groups) {
    # Calculate fitted trajectory for this group
    times_unique <- sort(unique(data[[time]]))
    time_std <- (times_unique - result$model$time_mean) / result$model$time_sd

    lambda <- calculate_trajectory(time_std, result$coefficients[k, ], degree)

    # Transform back based on distribution
    if (dist %in% c("poisson", "zip", "negbin")) {
      fitted_vals <- exp(lambda)
    } else {
      fitted_vals <- lambda
    }

    fitted_list[[k]] <- data.frame(
      group = k,
      time = times_unique,
      fitted = fitted_vals
    )
  }

  return(do.call(rbind, fitted_list))
}
