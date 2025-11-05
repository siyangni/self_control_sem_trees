#' Simulated Longitudinal Crime Data
#'
#' A simulated dataset of offending behavior trajectories for 200 individuals
#' measured over 10 time points (ages 10-19). The data contains three distinct
#' trajectory groups: low-rate desistors, adolescence-peaked offenders, and
#' chronic high-rate offenders.
#'
#' @format A data frame with 2000 rows and 5 variables:
#' \describe{
#'   \item{id}{Individual identifier (1-200)}
#'   \item{age}{Age at measurement (10-19)}
#'   \item{time}{Time index (0-9, centered for polynomial fitting)}
#'   \item{offenses}{Count of offenses committed (non-negative integer)}
#'   \item{sex}{Biological sex (1 = Male, 0 = Female)}
#'   \item{ses}{Socioeconomic status (standardized, continuous)}
#' }
#'
#' @details
#' The data was generated using a three-group trajectory model with the following
#' characteristics:
#'
#' \strong{Group 1: Low-rate desistors (50% of sample)}
#' - Start with low offending rates at age 10
#' - Slight increase during early adolescence
#' - Gradual decline to near-zero by age 19
#'
#' \strong{Group 2: Adolescence-peaked (30% of sample)}
#' - Low offending at age 10
#' - Sharp increase peaking around ages 15-16
#' - Rapid decline after peak
#'
#' \strong{Group 3: Chronic high-rate (20% of sample)}
#' - High offending starting at age 10
#' - Relatively stable or slight increase through adolescence
#' - Persistently high rates through age 19
#'
#' The offense counts follow a zero-inflated Poisson distribution. Males have
#' higher baseline offending rates across all groups. Lower SES is associated
#' with higher probability of membership in the chronic high-rate group.
#'
#' @source Simulated data based on empirical patterns documented in developmental
#'   criminology literature (Moffitt, 1993; Nagin & Land, 1993).
#'
#' @references
#' Moffitt, T. E. (1993). Adolescence-limited and life-course-persistent
#'   antisocial behavior: A developmental taxonomy. \emph{Psychological Review},
#'   100(4), 674-701.
#'
#' Nagin, D. S., & Land, K. C. (1993). Age, criminal careers, and population
#'   heterogeneity: Specification and estimation of a nonparametric, mixed Poisson
#'   model. \emph{Criminology}, 31(3), 327-362.
#'
#' @examples
#' data(crime_data)
#' head(crime_data)
#'
#' # Check data structure
#' str(crime_data)
#'
#' # Number of unique individuals
#' length(unique(crime_data$id))
#'
#' # Plot raw trajectories for first 20 individuals
#' subset_data <- crime_data[crime_data$id <= 20, ]
#' plot(subset_data$age, subset_data$offenses, type = "n",
#'      xlab = "Age", ylab = "Number of Offenses",
#'      main = "Individual Offense Trajectories")
#' for(i in 1:20) {
#'   ind_data <- subset_data[subset_data$id == i, ]
#'   lines(ind_data$age, ind_data$offenses, col = rgb(0, 0, 0, 0.3))
#' }
#'
"crime_data"
