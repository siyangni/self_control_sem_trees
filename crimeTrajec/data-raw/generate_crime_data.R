# Generate simulated crime trajectory data
# This script creates the crime_data dataset for the crimeTrajec package

set.seed(12345)

# Parameters
n_individuals <- 200
n_timepoints <- 10
ages <- 10:19
time <- 0:9  # Centered time for polynomial fitting

# Generate individual characteristics
id <- 1:n_individuals
sex <- rbinom(n_individuals, 1, 0.5)  # 0 = Female, 1 = Male
ses <- rnorm(n_individuals, 0, 1)     # Standardized SES

# Assign individuals to trajectory groups
# Group membership influenced by sex and SES
group_probs <- matrix(c(0.6, 0.3, 0.1,   # Female, high SES
                        0.5, 0.3, 0.2,   # Female, low SES
                        0.4, 0.3, 0.3,   # Male, high SES
                        0.3, 0.3, 0.4),  # Male, low SES
                      nrow = 4, byrow = TRUE)

true_group <- numeric(n_individuals)
for(i in 1:n_individuals) {
  group_idx <- 1 + sex[i] + (ses[i] < 0)
  true_group[i] <- sample(1:3, 1, prob = group_probs[group_idx, ])
}

# Trajectory parameters (polynomial coefficients: intercept, linear, quadratic, cubic)
# Group 1: Low-rate desistors
beta1 <- c(0.5, 0.3, -0.15, 0.01)

# Group 2: Adolescence-peaked
beta2 <- c(0.3, 1.2, -0.25, 0.02)

# Group 3: Chronic high-rate
beta3 <- c(2.5, 0.2, 0.05, -0.005)

# Generate offense counts
crime_data <- data.frame()

for(i in 1:n_individuals) {
  # Get trajectory parameters based on group
  if(true_group[i] == 1) {
    beta <- beta1
  } else if(true_group[i] == 2) {
    beta <- beta2
  } else {
    beta <- beta3
  }

  # Generate counts for each time point
  for(t in 1:n_timepoints) {
    # Polynomial trajectory (on log scale)
    time_centered <- (time[t] - mean(time)) / sd(time)
    log_lambda <- beta[1] + beta[2]*time_centered +
                  beta[3]*time_centered^2 + beta[4]*time_centered^3

    # Add sex effect (males have higher rates)
    log_lambda <- log_lambda + 0.5 * sex[i]

    # Add random individual effect
    log_lambda <- log_lambda + rnorm(1, 0, 0.3)

    lambda <- exp(log_lambda)

    # Zero-inflation: some observations are structural zeros
    zero_prob <- 0.1 + 0.05 * (true_group[i] == 1)
    is_zero <- rbinom(1, 1, zero_prob)

    if(is_zero == 1) {
      offenses <- 0
    } else {
      offenses <- rpois(1, lambda)
    }

    # Create row
    crime_data <- rbind(crime_data, data.frame(
      id = i,
      age = ages[t],
      time = time[t],
      offenses = offenses,
      sex = sex[i],
      ses = ses[i]
    ))
  }
}

# Ensure correct data types
crime_data$id <- as.integer(crime_data$id)
crime_data$age <- as.integer(crime_data$age)
crime_data$time <- as.numeric(crime_data$time)
crime_data$offenses <- as.integer(crime_data$offenses)
crime_data$sex <- as.integer(crime_data$sex)
crime_data$ses <- as.numeric(crime_data$ses)

# Save the dataset
usethis::use_data(crime_data, overwrite = TRUE)

# Also save to a simple RData file for manual loading if needed
save(crime_data, file = "crimeTrajec/data/crime_data.rda", compress = "xz")

cat("Dataset generated successfully!\n")
cat("Rows:", nrow(crime_data), "\n")
cat("Individuals:", length(unique(crime_data$id)), "\n")
cat("Time points:", length(unique(crime_data$time)), "\n")
