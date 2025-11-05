# Analysis Workflow

## Self-Control Development Study - Step-by-Step Guide

**Purpose**: This document provides a complete, reproducible workflow for all analyses in the self-control development project.

**Last Updated**: November 2025

---

## Table of Contents

1. [Setup & Prerequisites](#setup--prerequisites)
2. [Data Preparation](#data-preparation)
3. [Analysis Pipeline](#analysis-pipeline)
4. [Quality Checks](#quality-checks)
5. [Troubleshooting](#troubleshooting)

---

## Setup & Prerequisites

### 1. Software Requirements

**R Environment**:
```r
R.version.string
# Should be ≥ "R version 4.2.0"
```

**Required Packages**:
```r
# Check if key packages are installed
required_packages <- c(
  "tidyverse", "haven", "here",
  "lavaan", "semTools", "semtree",
  "survey", "psych", "OpenMx"
)

# Install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

# Verify installation
sapply(required_packages, require, character.only = TRUE)
```

### 2. Data Access

1. Obtain MCS data from [UK Data Service](https://ukdataservice.ac.uk/)
2. Download Stata (.dta) files for waves 2-7
3. Place in `data/raw/` directory
4. Verify files:

```bash
ls data/raw/*.dta
# Should show: mcs2_*.dta, mcs3_*.dta, ..., mcs7_*.dta
```

### 3. Project Setup

**Clone and navigate**:
```bash
git clone https://github.com/yourusername/self_control_sem_trees.git
cd self_control_sem_trees
```

**Restore R environment** (using renv):
```r
# In R console
renv::restore()
```

**Set working directory**:
```r
library(here)
setwd(here::here())  # Sets to project root
```

---

## Data Preparation

### Initial Data Processing

The first script (`01_measurement.R`) handles data preparation:

1. **Load raw MCS data**
2. **Merge waves** by cohort member ID
3. **Recode variables**:
   - Reverse-code negative items
   - Create consistent coding (higher = better self-control)
   - Handle missing values
4. **Apply survey weights**
5. **Save**: `data/processed/merged_waves_recoded.RData`

**Run**:
```r
source("R/01_measurement.R")
```

**Expected output**:
- Console: Reliability statistics, model fit indices
- `results/models/`: Wave-specific CFA model objects
- `results/tables/`: Reliability summary table
- `data/processed/merged_waves_recoded.RData`: Main analysis dataset

**Runtime**: ~10 minutes

---

## Analysis Pipeline

### Overview

```
01_measurement → 02_invariance → 03_merge_factor_scores
                                          ↓
                     ┌────────────────────┼────────────────────┐
                     ↓                    ↓                    ↓
               04_lgbm             05_gmm_lgbm         06_sem_trees
                                                              ↓
                                                    07_sem_trees_relaxed
```

### Step 1: Measurement Models (`01_measurement.R`)

**Purpose**: Validate self-control scale at each wave

**Methods**:
- Single-factor CFA (6 separate models)
- Ordinal indicators (WLSMV estimation)
- Survey-weighted estimation
- Reliability: Ordinal α and ω

**Key Parameters**:
```r
# CFA model
cfa_model <- 'SC =~ sc*thac + sc*tcom + sc*obey + sc*dist + sc*temp + sc*rest + sc*fidg'

# Estimation
estimator = "WLSMV"  # For ordinal data
ordered = TRUE       # Treat as ordinal
```

**Interpretation Guidelines**:
- CFI ≥ 0.90 = Acceptable fit
- RMSEA ≤ 0.10 = Acceptable fit
- α, ω ≥ 0.80 = Good reliability

**Decisions**:
- ✓ Use 7-item version (exclude "lying" for consistency across waves)
- ✓ All waves show acceptable fit
- ✓ Proceed to invariance testing

---

### Step 2: Measurement Invariance (`02_invariance.R`)

**Purpose**: Test if self-control is measured equivalently across time

**Methods**:
- Longitudinal measurement invariance
- Sequential model comparison:
  1. **Configural**: Same factor structure
  2. **Weak**: Equal loadings
  3. **Strong**: Equal loadings + thresholds
  4. **Strict**: Equal loadings + thresholds + residuals

**Key Parameters**:
```r
# Model comparison criteria
ΔCFI < 0.010  # Chen (2007) guideline
ΔRMSEA < 0.015
```

**Run**:
```r
source("R/02_invariance.R")
```

**Expected output**:
- `results/models/invariance_models.RData`: Nested models
- `results/tables/invariance_fit.csv`: Fit comparison table
- Console: Invariance test results

**Runtime**: ~20 minutes

**Interpretation**:
- **Full invariance**: Can compare means across time
- **Partial invariance**: Some parameters differ; use constraints for comparable items
- **Non-invariance**: Measurement properties change with development

**Decisions**:
- Document which level of invariance is supported
- Identify non-invariant items (if any)
- Decide on partial invariance strategy

---

### Step 3: Merge Factor Scores (`03_merge_factor_scores.R`)

**Purpose**: Create integrated dataset with self-control and parenting factor scores

**Methods**:
- Extract factor scores from CFAs
- Merge self-control (6 waves) + parenting (4 waves)
- Add baseline covariates
- Create complete case indicators

**Run**:
```r
source("R/03_merge_factor_scores.R")
```

**Expected output**:
- `data/processed/merged_sc_pa_fscores.RData`: Integrated dataset
- `data/processed/merged_sc_pa_fscores_varnames.txt`: Variable list
- Console: Sample sizes, missingness summary

**Runtime**: ~5 minutes

**Quality checks**:
```r
load("data/processed/merged_sc_pa_fscores.RData")

# Check dimensions
dim(merged_data)  # Should be ~16,877 rows

# Check variable names
names(merged_data)

# Check missingness
summary(merged_data)
```

---

### Step 4: Latent Basis Growth Model (`04_lgbm.R`)

**Purpose**: Model average developmental trajectory of self-control

**Methods**:
- Second-order latent growth model
- Latent basis (freely estimated time scores)
- 42 ordinal indicators (7 items × 6 waves)
- WLSMV estimation

**Model Structure**:
```
         Intercept
             ↓
    ┌────────┼────────┐
   SC3     SC5  ...  SC17  ← Growth factors
    ↓        ↓         ↓
 7 items  7 items  7 items  ← Indicators
```

**Key Parameters**:
```r
# Time scores (latent basis)
# Age 3 = 0 (fixed)
# Age 17 = 1 (fixed)
# Ages 5, 7, 11, 14 = freely estimated

# Constraints
# All loadings constrained equal across time (strong invariance)
```

**Run**:
```r
source("R/04_lgbm.R")
```

**Expected output**:
- `results/models/lgbm_results.RData`: Model object
- `results/figures/growth_trajectory.pdf`: Trajectory plot
- `results/tables/growth_parameters.csv`: Parameter estimates
- Console: Model fit, growth parameters

**Runtime**: ~30 minutes (complex model with many parameters)

**Interpretation**:
- **Intercept**: Average self-control at age 3
- **Slope**: Average rate of change
- **Variance in intercept**: Individual differences in starting point
- **Variance in slope**: Individual differences in change
- **Covariance**: Relationship between starting point and change

**Quality checks**:
```r
load("results/models/lgbm_results.RData")

# Model fit
fitMeasures(lgbm_fit, c("cfi", "tli", "rmsea", "srmr"))

# Growth parameters
summary(lgbm_fit)

# Check convergence
lavInspect(lgbm_fit, "converged")  # Should be TRUE
```

---

### Step 5: Growth Mixture Model (`05_gmm_lgbm.R`)

**Purpose**: Identify data-driven latent classes with distinct trajectories

**Methods**:
- Growth mixture modeling (GMM)
- Test 1-5 class solutions
- Model selection: BIC, entropy, BLRT
- Class-specific growth parameters

**Run**:
```r
source("R/05_gmm_lgbm.R")
```

**Expected output**:
- `results/models/gmm_*.RData`: Class-specific models (1-5 classes)
- `results/tables/gmm_fit_comparison.csv`: Fit indices
- `results/figures/gmm_trajectories.pdf`: Class-specific plots
- Console: Fit statistics, class sizes

**Runtime**: ~2 hours (multiple models)

**Model Selection Criteria**:
- **BIC**: Lower is better (parsimony-adjusted fit)
- **Entropy**: Higher is better (≥0.80 = good classification)
- **BLRT**: Significant = k classes better than k-1
- **Class size**: All classes ≥5% of sample

**Interpretation**:
- **1 class**: Homogeneous trajectories (null)
- **2+ classes**: Distinct subgroups exist
- **Compare with SemTREE**: GMM = data-driven, SemTREE = covariate-driven

---

### Step 6: SEM Trees - Standard (`06_sem_trees.R`)

**Purpose**: Identify covariate-predicted subgroups (theory-driven)

**Methods**:
- Structural equation model trees
- Split LGBM by covariates
- 47 parenting + child characteristic predictors

**Key Parameters**:
```r
ctrl <- semtree_control(
  method = "fair",          # Likelihood-based (WLSMV compatible)
  alpha = 0.05,             # Standard significance level
  min.N = 100,              # Conservative minimum node size
  max.depth = 5,            # Tree complexity limit
  verbose = TRUE
)
```

**Covariates Tested**:
- Parenting (ages 3, 5, 7, 11, 14, 17): 26 variables
- Parental monitoring (ages 14, 17): 10 variables
- Baseline characteristics: 9 variables (SES, cognition, temperament)

**Run**:
```r
source("R/06_sem_trees.R")
```

**Expected output**:
- `results/models/semtree_results.RData`: Tree object
- `results/figures/semtree_plot.pdf`: Tree visualization
- `results/reports/SEMTREE_FINAL_SUMMARY.md`: Detailed summary
- Console: Tree structure, split variables (if any)

**Runtime**:
- If splits found: ~1-2 hours (includes forest)
- If no splits: ~2 minutes (skips forest)

**Interpretation**:

**Scenario A: Splits Found**
```
Example tree structure:
├─[1] smack3 ≤ 1
│  ├─[2] TERMINAL [N=450] (Low harsh discipline)
│  └─[3] incomef ≤ 2
│     ├─[4] TERMINAL [N=200] (Low harsh + Low SES)
│     └─[5] TERMINAL [N=267] (Low harsh + High SES)
└─[6] TERMINAL [N=467] (High harsh discipline)
```

Interpretation:
- **Split 1**: Harsh discipline (smack3) differentiates trajectories
- **Split 2**: Within low harsh group, SES matters
- **Terminal nodes**: Distinct subgroup trajectories
- **Follow-up**: Run forest for variable importance, stability

**Scenario B: No Splits Found** *(Actual result in this project)*
```
├─[1] TERMINAL [N=917]
```

Interpretation:
- No covariates significantly differentiate growth trajectories
- Self-control development may be relatively uniform
- Suggests small effect sizes or unmeasured moderators

---

### Step 7: SEM Trees - Relaxed (`07_sem_trees_relaxed.R`)

**Purpose**: Sensitivity analysis with more permissive parameters

**Methods**:
- Same as standard SEM trees
- Relaxed splitting criteria
- Focused covariate set (theory-driven)

**Key Parameters**:
```r
ctrl <- semtree_control(
  method = "fair",
  alpha = 0.10,             # More permissive
  min.N = 50,               # Smaller nodes allowed
  max.depth = 6,            # Deeper trees allowed
  verbose = TRUE
)
```

**Covariates** (16 focused variables):
- Baseline: sex, SES, cognition, temperament, birth outcomes
- Early parenting: smack3, shout3, telloff3, reason5, telloff5, reason7, telloff7

**Run**:
```r
source("R/07_sem_trees_relaxed.R")
```

**Expected output**:
- `results/models/semtree_relaxed_results.RData`
- `results/figures/semtree_relaxed_plot.pdf`
- Console: Tree structure

**Runtime**: ~3 minutes (no splits expected based on standard analysis)

**Interpretation**:
- **Consistent with standard**: Robust null finding
- **Finds splits when standard doesn't**: Effect exists but small
- **Different splits**: Parameter-sensitive effects

---

## Quality Checks

### After Each Script

1. **Check console output**:
   - No errors or warnings
   - Expected sample sizes
   - Reasonable parameter estimates

2. **Verify output files**:
```bash
# List results
ls results/models/
ls results/figures/
ls results/tables/
```

3. **Inspect key objects**:
```r
# Example for LGBM
load("results/models/lgbm_results.RData")
summary(lgbm_fit)
fitMeasures(lgbm_fit, c("cfi", "rmsea"))
```

### End-to-End Checks

**Data consistency**:
```r
# Load all processed data
load("data/processed/merged_waves_recoded.RData")
load("data/processed/merged_sc_pa_fscores.RData")

# Check sample sizes
nrow(merged_waves_recoded)      # Should be ~16,877
nrow(merged_sc_pa_fscores)      # Varies by analysis

# Check variable alignment
table(merged_data$sex)
summary(merged_data$sc_fs_3)
```

**Model convergence**:
```r
# All SEM models should converge
model_files <- list.files("results/models/", pattern = ".RData", full.names = TRUE)

check_convergence <- function(file) {
  load(file)
  # Check for model object (name varies)
  # Return TRUE/FALSE
}

# Manual check recommended for each model
```

**Reproducibility**:
```r
# Session info
sessionInfo()
# Save to file
sink("results/sessionInfo.txt")
sessionInfo()
sink()
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Package Installation Errors

**Symptom**: `install.packages("semtree")` fails

**Solutions**:
```r
# Try different repository
install.packages("semtree", repos = "https://cloud.r-project.org")

# Install dependencies first
install.packages(c("OpenMx", "lavaan"))

# Install from GitHub (if needed)
remotes::install_github("brandmaier/semtree")
```

#### Issue 2: Memory Errors

**Symptom**: "Cannot allocate vector of size..."

**Solutions**:
1. Increase R memory limit:
```r
memory.limit(size = 32000)  # Windows only
```

2. Use fewer cores:
```r
# In SEM tree script
control$num_threads <- 2  # Reduce from default
```

3. Close other applications

#### Issue 3: WLSMV Estimation Issues

**Symptom**: "Model did not converge"

**Solutions**:
```r
# Increase iterations
fit <- cfa(model, data,
           estimator = "WLSMV",
           control = list(iter.max = 10000))

# Check starting values
lavInspect(fit, "start")

# Simplify model (if needed)
```

#### Issue 4: SEM Tree No Splits

**Symptom**: Tree has only 1 terminal node

**This is NOT an error!** This is a substantive finding (null result).

**Next steps**:
1. ✓ Run relaxed parameters (`07_sem_trees_relaxed.R`)
2. ✓ Check GMM for consistency
3. ✓ Try alternative approaches (regression, group comparisons)
4. ✓ Document as null finding

#### Issue 5: Missing Data Patterns

**Symptom**: Small N in some analyses

**Solutions**:
```r
# Check missingness
merged_data %>%
  select(sc_fs_3, sc_fs_5, ..., harsh_fs_3) %>%
  summarise(across(everything(), ~sum(is.na(.))))

# Options:
# 1. Use available data (FIML in lavaan)
# 2. Multiple imputation (advanced)
# 3. Accept reduced N for complete case analyses
```

---

## Workflow Tips

### Efficient Workflow

**Sequential run** (full pipeline):
```r
# Run all scripts in order
source("R/00_master.R")  # Once created
```

**Iterative development**:
```r
# Work on one script at a time
source("R/01_measurement.R")

# Make changes, re-run
# ...

# When satisfied, move to next script
source("R/02_invariance.R")
```

**Partial re-runs**:
```r
# If you only need to re-run SEM trees:
load("data/processed/merged_sc_pa_fscores.RData")  # Load prepared data
source("R/06_sem_trees.R")  # Re-run analysis
```

### Version Control

**Commit after major milestones**:
```bash
git add .
git commit -m "Complete measurement models (script 01)"
git push
```

**Tag releases**:
```bash
git tag -a v1.0 -m "Final analyses for dissertation"
git push --tags
```

### Documentation

**Keep notes**:
- Document decisions in `docs/methods.md`
- Update `CHANGELOG.md` with major changes
- Comment code extensively

---

## Expected Timeline

| Phase | Scripts | Time | Notes |
|-------|---------|------|-------|
| Setup | Environment | 1 hour | One-time |
| Data prep | 01-03 | 30 min | Reusable data |
| Core models | 04 | 30 min | LGBM |
| Advanced | 05-07 | 3 hours | GMM + Trees |
| **Total** | | **~5 hours** | First run |

**Subsequent runs**: ~30 minutes (using saved data)

---

## Next Steps After Workflow Completion

1. **Review results**: Read `results/reports/*.md` files
2. **Compare approaches**: GMM vs. SEM trees
3. **Additional analyses**: Regression, group comparisons
4. **Manuscript preparation**: Use results for writing
5. **Share code**: Push to GitHub, add documentation

---

## References

**Workflow best practices**:
> Wilson, G., et al. (2017). Good enough practices in scientific computing. *PLOS Computational Biology, 13*(6), e1005510.

**Reproducible research**:
> Gentleman, R., & Temple Lang, D. (2007). Statistical analyses and reproducible research. *Journal of Computational and Graphical Statistics, 16*(1), 1-23.

---

**Questions or issues?** Open an issue on GitHub or consult `docs/methods.md` for methodological details.

**Last Updated**: November 2025
