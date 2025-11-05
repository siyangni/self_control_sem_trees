# crimeTrajec: Group-Based Trajectory Modeling for Criminology

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0.0-blue)](https://www.r-project.org/)

## Overview

**crimeTrajec** is an R package for group-based trajectory modeling (GBTM) of longitudinal criminology data. It provides a comprehensive, open-source implementation of semi-parametric mixture models for identifying distinct developmental trajectories in offending behavior and other longitudinal outcomes.

## Features

- **Multiple outcome distributions**: Poisson, zero-inflated Poisson, Gaussian, negative binomial
- **Flexible trajectory specifications**: Polynomial trajectories of any degree
- **Covariate effects**: Model how individual characteristics predict group membership and trajectory shapes
- **Advanced model selection**: BIC, AIC, and k-fold cross-validation
- **Rich diagnostics**: Posterior probabilities, classification accuracy, convergence checks
- **Publication-ready visualizations**: Plot trajectory groups with confidence bands
- **User-friendly interface**: Intuitive functions following R conventions
- **Comprehensive documentation**: Detailed help files, vignettes, and examples

## Installation

### From source (current)

```r
# Install dependencies first
install.packages(c("stats", "graphics", "grDevices", "flexmix", "MASS", "parallel"))

# Install from local source
install.packages("path/to/crimeTrajec", repos = NULL, type = "source")
```

### From GitHub (once published)

```r
# Install devtools if needed
install.packages("devtools")

# Install crimeTrajec
devtools::install_github("username/crimeTrajec", build_vignettes = TRUE)
```

### From CRAN (future)

```r
install.packages("crimeTrajec")
```

## Quick Start

```r
library(crimeTrajec)

# Load example data
data(crime_data)

# Fit a 3-group trajectory model
model <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "time",
  outcome = "offenses",
  dist = "zip",              # Zero-inflated Poisson
  groups = 3,
  degree = 3                 # Cubic polynomials
)

# View results
print(model)

# Plot trajectories
plot(model, main = "Estimated Trajectory Groups")

# Get predictions
predictions <- predict(model, type = "posterior")
```

## Model Selection

Compare models with different numbers of groups:

```r
# Compare 1-5 group models using BIC
selection <- selectNumGroups(
  data = crime_data,
  id = "id",
  time = "time",
  outcome = "offenses",
  max_groups = 5,
  criteria = "BIC"
)

print(selection)
plot(selection)
```

With cross-validation (more rigorous but slower):

```r
selection_cv <- selectNumGroups(
  data = crime_data,
  id = "id",
  time = "time",
  outcome = "offenses",
  max_groups = 4,
  criteria = c("BIC", "CVE"),  # Both BIC and cross-validation
  cv_folds = 5,
  parallel = TRUE              # Use parallel processing
)
```

## Documentation

Comprehensive documentation is available:

```r
# Function help
?fitTrajectory
?selectNumGroups

# Package vignette
vignette("crimeTrajec-vignette")

# View all available documentation
help(package = "crimeTrajec")
```

## Key References

- Nagin, D. S. (2005). *Group-based modeling of development*. Harvard University Press.
- Nagin, D. S., & Land, K. C. (1993). Age, criminal careers, and population heterogeneity: Specification and estimation of a nonparametric, mixed Poisson model. *Criminology*, 31(3), 327-362.
- Jones, B. L., Nagin, D. S., & Roeder, K. (2001). A SAS procedure based on mixture models for estimating developmental trajectories. *Sociological Methods & Research*, 29(3), 374-393.

## Contributing

Contributions are welcome! Please feel free to:

- Report bugs or request features via [GitHub Issues](https://github.com/username/crimeTrajec/issues)
- Submit pull requests with bug fixes or enhancements
- Suggest improvements to documentation

## Citation

If you use crimeTrajec in your research, please cite:

```
[Citation to be added after publication]
```

## License

This package is licensed under the GNU General Public License v3.0 (GPL-3). See the [LICENSE](LICENSE) file for details.

## Authors

- [Author names to be added]

## Acknowledgments

Development of this package was supported by [funding information to be added].

---

**Note**: This package is under active development. We welcome feedback and contributions from the research community.
