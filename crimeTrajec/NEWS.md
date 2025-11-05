# crimeTrajec 0.1.0

## Initial Release (2025-11-05)

### New Features

* **Core functionality**:
  - `fitTrajectory()`: Fit group-based trajectory models with EM algorithm
  - `selectNumGroups()`: Automated model selection using BIC, AIC, and cross-validation
  - S3 methods: `print()`, `plot()`, `predict()`, `summary()` for trajectory models

* **Outcome distributions**:
  - Poisson
  - Zero-inflated Poisson (ZIP)
  - Gaussian
  - Negative binomial

* **Model features**:
  - Polynomial trajectories (any degree)
  - Group membership covariates
  - Trajectory shape covariates
  - Multiple random starts for global optimization
  - Parallel processing for cross-validation

* **Diagnostics and validation**:
  - Posterior probability assessment
  - Convergence diagnostics
  - Model fit statistics (log-likelihood, AIC, BIC)
  - Cross-validation error estimation

* **Visualization**:
  - Trajectory plots with confidence bands
  - Option to overlay individual data
  - Model comparison plots

* **Documentation**:
  - Comprehensive function documentation via Roxygen2
  - Package vignette with tutorials and examples
  - Academic paper manuscript
  - Simulated example dataset

### Known Limitations

* Standard errors for trajectory parameters not yet implemented (planned for v0.2.0)
* Missing data handled via listwise deletion only
* Single outcome models only (multivariate trajectories planned for future release)

### Future Development Plans

* Bootstrap standard errors and confidence intervals
* Enhanced missing data handling
* Multivariate trajectory models
* Multilevel trajectory models
* Additional outcome distributions
* Computational optimization with Rcpp
* Shiny web interface

---

For more information, see the package documentation and vignette.
