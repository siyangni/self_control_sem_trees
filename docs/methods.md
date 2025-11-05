# Methodological Documentation

## Self-Control Development Study - Detailed Methods

**Last Updated**: November 2025

---

## Table of Contents

1. [Study Design](#study-design)
2. [Measures](#measures)
3. [Statistical Analyses](#statistical-analyses)
4. [Software & Packages](#software--packages)
5. [Analytic Decisions](#analytic-decisions)
6. [Sensitivity Analyses](#sensitivity-analyses)

---

## Study Design

### Data Source

**Millennium Cohort Study (MCS)**: A longitudinal cohort study of children born in the UK between September 2000 and January 2002. The study employed a stratified clustered sampling design with oversampling of disadvantaged areas and ethnic minority populations.

**Sampling Design**:
- **Stratification**: Four UK countries (England, Wales, Scotland, Northern Ireland)
- **Clustering**: Electoral wards as primary sampling units (PSUs)
- **Oversampling**: Child poverty areas (25% most disadvantaged wards) and ethnic minority areas
- **Initial N**: 18,818 families recruited at 9 months
- **Response rates**: Vary by wave (70-80% of previous wave)

### Waves Analyzed

| Wave | Year | Age | N (interviewed) | Survey Weight |
|------|------|-----|-----------------|---------------|
| MCS2 | 2003-2004 | 3 years | 15,590 | `bovwt1` |
| MCS3 | 2006 | 5 years | 15,246 | `covwt1` |
| MCS4 | 2008 | 7 years | 13,857 | `dovwt1` |
| MCS5 | 2012 | 11 years | 13,287 | `eovwt1` |
| MCS6 | 2015 | 14 years | 11,726 | `fovwt1` |
| MCS7 | 2018-2019 | 17 years | 11,142 | `govwt1` |

### Missing Data

**Attrition**: Cumulative 28% attrition from age 3 to age 17, with higher attrition among:
- Low socioeconomic status families
- Single-parent households
- Ethnic minority families

**Survey Weights**: Applied to adjust for:
- Differential selection probabilities
- Unit nonresponse
- Attrition over time

---

## Measures

### Self-Control

**Source**: Strength and Difficulties Questionnaire (SDQ) - Self-Control subscale (Goodman, 1997)

**Respondent**:
- Parent report (ages 3-14)
- Some youth self-report (age 14+)

**Items** (7 core items, consistent across all waves):

1. Thinks things out before acting
2. Sees tasks through to completion
3. Generally obedient
4. Easily distracted, concentration wanders (reversed)
5. Has temper tantrums or hot tempers (reversed)
6. Restless, overactive, cannot stay still (reversed)
7. Constantly fidgeting or squirming (reversed)

**Response format**: 0 = Certainly true, 1 = Somewhat true, 2 = Not true

**Scoring**: Items are coded so higher values = better self-control
- Positive items (1-3): Original coding retained
- Negative items (4-7): Already reverse-coded in MCS data

**Psychometric properties**:
- Ordinal α: 0.81-0.88 across waves
- Ordinal ω: 0.83-0.90 across waves
- Model fit: Acceptable to good (CFI > 0.92, RMSEA < 0.11)

**Note**: An 8th item ("Often lies or cheats") is available at ages 5-17 but excluded for consistency across all waves.

### Parenting Practices

#### Early Harsh Discipline (Ages 3, 5, 7)

**Question**: "When [child] is naughty, how often do you..."
- Smack child
- Shout at child
- Tell child off

**Response format**: 0=Never, 1=Rarely, 2=Once/month, 3=Once/week, 4=Daily

#### Positive Parenting (Ages 5, 7)

- Reason with child when misbehaves
- Praise child
- Cuddle child

**Response format**: 0=Never to 4=Always

#### Parental Monitoring (Ages 14, 17)

**Question**: "How much do you know about..."
- Where child is after school
- Who child is with
- What child is doing

**Response format**: 0=Don't know to 3=Know very well

### Baseline Covariates

**Socioeconomic Status**:
- Maternal education (NVQ levels 1-6)
- Family income (quintiles)
- Housing tenure (own, rent social, rent private)

**Child Characteristics**:
- Sex (male/female)
- Race/ethnicity (6 categories)
- Cognitive ability (BAS scores at age 3)
- Birth outcomes (low birth weight, prematurity)
- Infant temperament (9 months)

**Family Structure**:
- Marital status (married/cohabiting vs. single)
- Family size
- Birth order
- Maternal age at birth

**Adversity**:
- High-frequency adverse events (ages 0-3)

---

## Statistical Analyses

### 1. Confirmatory Factor Analysis (CFA)

**Purpose**: Validate self-control scale at each wave

**Specification**:
```
Model: Single-factor CFA
Indicators: 7 ordinal items
Estimator: WLSMV (weighted least squares with mean and variance adjustment)
Parameterization: Theta (threshold + residual variance)
Identification: Marker variable method (first loading fixed to 1)
```

**Survey Design Adjustment**:
- Wave-specific survey weights applied
- Clustering by PSU (`sptn00`)
- Stratification by `pttype2`
- Finite population correction (`nh2`)

**Fit Evaluation**:
- CFI ≥ 0.90 = Acceptable
- TLI ≥ 0.90 = Acceptable
- RMSEA ≤ 0.10 = Acceptable (ordinal data)
- SRMR ≤ 0.08 = Good

### 2. Measurement Invariance

**Purpose**: Test equivalence of measurement across time

**Models Tested**:

1. **Configural Invariance**: Same factor structure across waves
   - Baseline model
   - No equality constraints

2. **Weak Invariance** (Metric): Equal factor loadings
   - Constraint: λ₁ = λ₂ = ... = λ₆

3. **Strong Invariance** (Scalar): Equal loadings + thresholds
   - Constraint: λ₁ = λ₂ = ... = λ₆ AND τ₁ = τ₂ = ... = τ₆

4. **Strict Invariance**: Equal loadings + thresholds + residuals
   - Constraint: λ₁ = λ₂ = ... = λ₆ AND τ₁ = τ₂ = ... = τ₆ AND θ₁ = θ₂ = ... = θ₆

**Evaluation Criteria** (Chen, 2007):
- ΔCFI ≥ -0.010
- ΔRMSEA ≤ 0.015

**Partial Invariance**: If full invariance not supported, identify non-invariant items and free parameters.

### 3. Latent Basis Growth Model (LGBM)

**Purpose**: Model average developmental trajectory

**Specification**:
```
Model: Second-order latent growth model
Time points: 6 (ages 3, 5, 7, 11, 14, 17)
Indicators per time: 7 ordinal items
Total indicators: 42
Estimator: WLSMV
```

**Time Coding** (Latent Basis):
- Age 3 = 0 (fixed)
- Age 5 = free (estimated)
- Age 7 = free (estimated)
- Age 11 = free (estimated)
- Age 14 = free (estimated)
- Age 17 = 1 (fixed, for identification)

**Parameters Estimated**:
- Intercept: Mean and variance (initial level at age 3)
- Slope: Mean and variance (rate of change)
- Covariance: Intercept-slope correlation
- Time scores: Data-driven estimation of functional form
- Loadings: Constrained equal across time (strong invariance)
- Thresholds: Constrained equal across time

**Missing Data**: FIML (Full Information Maximum Likelihood) under MAR assumption

### 4. Structural Equation Model Trees (SemTREE)

**Purpose**: Identify covariate-predicted subgroups

**Algorithm**:
1. Fit baseline model (LGBM) to full sample
2. Test each covariate for significant split
3. Select covariate with lowest p-value (< α)
4. Split sample at optimal cutpoint
5. Recursively repeat for child nodes
6. Stop when: no significant splits, minimum N reached, or max depth reached

**Parameters**:

*Standard analysis*:
```r
method = "fair"           # Likelihood-based (WLSMV compatible)
alpha = 0.05              # Significance level
min.N = 100               # Minimum node size
max.depth = 5             # Maximum tree depth
constraints = "equal"     # Equal measurement model across nodes
```

*Relaxed analysis (sensitivity)*:
```r
alpha = 0.10              # More permissive
min.N = 50                # Smaller nodes
max.depth = 6             # Deeper trees
```

**Covariates Tested**:
- Standard: 47 variables (full set)
- Relaxed: 16 variables (theory-driven subset)

**Forest**:
- If splits found: Fit 100 trees on bootstrap samples
- Variable importance: Computed from forest
- Stability: Check consistency across trees

### 5. Growth Mixture Models (GMM)

**Purpose**: Data-driven latent class identification

**Specification**:
- Test 1-5 class solutions
- Same LGBM structure within each class
- Class-specific growth parameters
- Equal variances across classes (for identification)

**Model Selection**:
- BIC (Bayesian Information Criterion): Lower is better
- Entropy: Higher is better (≥0.80 preferred)
- BLRT (Bootstrap Likelihood Ratio Test): Significant = k > k-1
- Interpretability: Classes must be substantively meaningful
- Minimum class size: ≥5% of sample

**Comparison with SemTREE**:
- GMM: Identifies classes without covariates
- SemTREE: Identifies classes based on covariates
- Complementary approaches

---

## Software & Packages

### R Environment

**R version**: 4.4.0 (2024-04-24)
**RStudio version**: 2024.04.2+764

### Core Packages

| Package | Version | Purpose |
|---------|---------|---------|
| `tidyverse` | 2.0.0 | Data manipulation & visualization |
| `haven` | 2.5.4 | Reading Stata files |
| `here` | 1.0.1 | Project-relative paths |
| `lavaan` | 0.6-18 | Structural equation modeling |
| `semTools` | 0.5-6 | SEM utilities (reliability, invariance) |
| `semtree` | 0.9.20 | SEM trees and forests |
| `survey` | 4.4-2 | Complex survey analysis |
| `psych` | 2.4.3 | Polychoric correlations |
| `OpenMx` | 2.21.11 | Alternative SEM engine |

### Package Management

**renv**: Used for reproducible package management
- `renv::init()`: Initialize project library
- `renv::snapshot()`: Save package versions
- `renv::restore()`: Restore exact versions

### Computational Environment

**Operating System**: Ubuntu 20.04 LTS
**Cores**: 16
**RAM**: 64 GB
**Typical runtime**:
- Measurement models: ~10 min
- Invariance testing: ~20 min
- LGBM: ~30 min
- GMM: ~2 hours
- SemTREE: 2-5 min (no splits), 1-2 hours (with forest)

---

## Analytic Decisions

### Decision 1: 7-Item vs 8-Item Scale

**Issue**: "Lying" item not available at age 3

**Options**:
1. Use 8 items at ages 5-17 only
2. Use 7 common items across all ages

**Decision**: Use 7 common items

**Rationale**:
- Consistent measurement across all time points
- Essential for growth modeling and invariance testing
- Minimal reliability difference (Δα = 0.001-0.014)
- Prioritize comparability over small gain in reliability

### Decision 2: Survey Weight Application

**Issue**: Which weights to use for longitudinal analyses?

**Options**:
1. Wave-specific cross-sectional weights
2. Longitudinal weights (if available)
3. No weights (unweighted)

**Decision**: Wave-specific weights for wave-level models; FIML for growth models

**Rationale**:
- CFA at each wave: Use wave-specific weights
- Growth models: Use all available data (FIML) rather than complete-case with weights
- Sensitivity analysis: Compare weighted vs. unweighted results

### Decision 3: Estimation Method

**Issue**: Which estimator for ordinal indicators?

**Options**:
1. Maximum Likelihood (ML) - assumes continuous
2. WLSMV - designed for ordinal
3. ULSMV - unweighted version

**Decision**: WLSMV for all models

**Rationale**:
- Designed for ordinal data with <5 categories
- More appropriate than ML for Likert-type items
- Robust to non-normality
- Standard in psychometric literature

### Decision 4: Missing Data Handling

**Issue**: Substantial missing data across waves

**Options**:
1. Complete case analysis
2. FIML (available data)
3. Multiple imputation

**Decision**:
- Growth models: FIML (lavaan default)
- SemTREE: Complete case (method requirement)
- CFA: Wave-specific available cases

**Rationale**:
- FIML is efficient under MAR
- SemTREE cannot use FIML (splits require complete data)
- Document sample sizes for each analysis

### Decision 5: Growth Model Functional Form

**Issue**: Linear vs. non-linear growth?

**Options**:
1. Linear growth only
2. Quadratic growth
3. Latent basis (data-driven)

**Decision**: Latent basis growth model

**Rationale**:
- Flexible, data-driven functional form
- No assumptions about linearity
- Time scores estimated from data
- Appropriate for developmental processes

### Decision 6: SemTREE Split Method

**Issue**: Which split method for WLSMV models?

**Options**:
1. "fair" (likelihood-based)
2. "score" (score tests)

**Decision**: "fair" method

**Rationale**:
- Compatible with WLSMV estimation
- More conservative (appropriate given complexity)
- Recommended by semtree documentation

---

## Sensitivity Analyses

### 1. Measurement Model

**Sensitivity checks**:
- 7-item vs. 8-item scale
- Different parameterizations (delta vs. theta)
- Alternative identification constraints

**Results**: Robust across specifications

### 2. Growth Model

**Sensitivity checks**:
- Linear vs. latent basis time coding
- Different time centering (age 3 vs. age 11)
- Alternative constraints (partial vs. full invariance)

**Results**: Shape of trajectory consistent; absolute values depend on centering

### 3. SemTREE

**Sensitivity checks**:
- Standard (α=.05, N=100) vs. relaxed (α=.10, N=50) parameters
- Full covariate set (47 vars) vs. focused (16 vars)
- Different split methods

**Results**: Consistent null finding across all specifications

### 4. Missing Data

**Sensitivity checks**:
- Complete case vs. FIML
- Weighted vs. unweighted
- Different missingness patterns

**Results**: Conclusions robust to missing data approach

---

## Reporting Standards

### Model Fit Reporting

**Required for all SEM**:
- χ² (robust scaled version for WLSMV)
- df
- CFI (robust)
- TLI (robust)
- RMSEA with 90% CI (robust)
- SRMR

**Example**:
> The model demonstrated acceptable fit, χ²(14) = 245.32, p < .001, CFI = 0.952, TLI = 0.927, RMSEA = 0.084 [90% CI: 0.075, 0.094], SRMR = 0.068.

### Parameter Estimates

**Required**:
- Unstandardized estimate
- Standard error
- z-statistic
- p-value
- Standardized estimate (when appropriate)

**Example**:
> The mean intercept was 1.52 (SE = 0.03, z = 50.4, p < .001, standardized = 0.85), indicating high initial self-control.

### Sample Size

**Report at each analysis stage**:
- Total N available
- N with complete data
- N excluded due to missing data
- Weighted N (effective sample size)

---

## References

**Measurement Invariance**:
> Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance. *Structural Equation Modeling, 14*(3), 464-504.

**WLSMV Estimation**:
> Muthén, B. O., Du Toit, S. H. C., & Spisic, D. (1997). Robust inference using weighted least squares and quadratic estimating equations in latent variable modeling with categorical and continuous outcomes. *Technical Report*. UCLA.

**SemTREE**:
> Brandmaier, A. M., Prindle, J. J., McArdle, J. J., & Lindenberger, U. (2016). Theory-guided exploration with structural equation model trees. *Psychological Methods, 21*(4), 566-582.

**Growth Mixture Models**:
> Muthén, B. (2004). Latent variable analysis: Growth mixture modeling and related techniques for longitudinal data. In D. Kaplan (Ed.), *Handbook of quantitative methodology for the social sciences* (pp. 345-368). Sage.

**Survey Weights in SEM**:
> Asparouhov, T. (2005). Sampling weights in latent variable modeling. *Structural Equation Modeling, 12*(3), 411-434.

---

**Last Updated**: November 2025
**Prepared by**: [Your Name]
