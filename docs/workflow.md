# Analysis Workflow

## Self-Control Development Study - Step-by-Step Guide

**Purpose**: This document provides a complete, reproducible workflow for all analyses in the self-control development project.

**Last Updated**: November 2025

---

## Table of Contents

1. [Setup & Prerequisites](#setup--prerequisites)
2. [Phase 0: Data Ingestion & Harmonization](#phase-0-data-ingestion--harmonization) **(NEW)**
3. [Data Preparation](#data-preparation)
4. [Analysis Pipeline](#analysis-pipeline)
5. [Quality Checks](#quality-checks)
6. [Troubleshooting](#troubleshooting)

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

## Phase 0: Data Ingestion & Harmonization

**NEW WORKFLOW COMPONENT**: This phase creates analysis-ready datasets from raw MCS data files.

### Overview

Phase 0 transforms raw MCS Stata files into clean, harmonized datasets optimized for SEMTree and growth modeling analyses. This phase runs **once** before any statistical analyses.

**Runtime**: ~10-20 minutes
**Input**: Raw MCS data files (Waves 1-7)
**Output**: Multiple analysis-ready datasets

### Quick Start

```r
# Run complete data preparation pipeline
source("R/data_prep/00_master_data_prep.R")
```

This single command executes all 11 steps of data preparation.

### What Phase 0 Does

1. **Extracts variables** from 7 waves of raw MCS data
2. **Harmonizes variable names** across waves (consistent naming)
3. **Merges all waves** by cohort member ID
4. **Runs quality checks** (duplicates, ranges, temporal consistency)
5. **Creates derived variables** (composites, risk indices, trajectory summaries)
6. **Generates multiple datasets** optimized for different analyses

### Output Datasets

| Dataset | N | Purpose | Use For |
|---------|---|---------|---------|
| `mcs_merged_wide.RData` | ~18,000 | Full merged data | Exploration, descriptives |
| `mcs_semtree_complete_full.RData` | ~900 | Complete case, all covariates | SEMTree (conservative) |
| `mcs_semtree_complete_minimal.RData` | ~3,000 | Complete case, minimal covariates | SEMTree (max power) |
| `mcs_semtree_complete_theory.RData` | ~2,000 | Complete case, theory covariates | SEMTree (focused) |
| `mcs_lavaan_fiml.RData` | ~10,000 | ≥3 waves SC, complete baseline | LGBM with FIML |
| `mcs_long_format.RData` | ~60,000 obs | Person-period format | Mixed models |

### Step-by-Step Process

If you prefer to run steps individually:

```r
# Step 1: Extract baseline covariates (Wave 1, 9 months)
source("R/data_prep/00a_wave1_baseline.R")

# Steps 2-7: Extract wave-specific data (ages 3-17)
source("R/data_prep/00b_wave2_age3.R")   # Age 3
source("R/data_prep/00c_wave3_age5.R")   # Age 5
source("R/data_prep/00d_wave4_age7.R")   # Age 7
source("R/data_prep/00e_wave5_age11.R")  # Age 11
source("R/data_prep/00f_wave6_age14.R")  # Age 14
source("R/data_prep/00g_wave7_age17.R")  # Age 17

# Step 8: Merge all waves
source("R/data_prep/00h_merge_all_waves.R")

# Step 9: Quality checks
source("R/data_prep/00i_quality_checks.R")

# Step 10: Derived variables
source("R/data_prep/00j_derive_composites.R")

# Step 11: Create analysis datasets
source("R/data_prep/00l_create_analysis_datasets.R")
```

### Variables Extracted

**Self-Control (SDQ)**:
- 7 core items consistent across all waves (ages 3-17)
- 1 additional item "lying" (ages 5-17, not used for consistency)
- Total scores, mean scores, item counts

**Parenting**:
- Harsh discipline (ages 3, 5, 7): smack, shout, tell off, etc.
- Positive parenting (ages 5, 7): reason, praise, cuddle
- Parental monitoring (ages 14, 17): parent and child reports

**Baseline Covariates**:
- Demographics: sex, ethnicity, birth outcomes
- SES: maternal education, income, housing
- Child: cognitive ability, temperament

**Derived Variables**:
- Time-averaged parenting composites
- Parenting stability measures
- Categorical groupings (tertiles)
- Cumulative risk index
- SC trajectory summaries

See `docs/variable_reference.md` for complete variable list.

### Quality Checks

Phase 0 includes automated quality checks:

- ✓ Duplicate ID detection
- ✓ Value range validation (SC items 0-2)
- ✓ Temporal consistency checks
- ✓ Missing data patterns
- ✓ Survey weight distributions

**Check results**: `results/quality_checks/`

### Covariate Sets

Predefined covariate sets for different analyses:

```r
load("data/processed/covariate_lists.RData")

# Available sets:
# - covariate_lists$baseline      # Time-invariant covariates
# - covariate_lists$parenting     # Parenting variables
# - covariate_lists$all_full      # All covariates (47 variables)
# - covariate_lists$minimal       # Minimal set (7 variables)
# - covariate_lists$theory        # Theory-driven (8 variables)
```

### Choosing the Right Dataset

**For SEMTree Analysis:**

```r
# Maximum sample size (recommended for initial analysis)
load("data/processed/mcs_semtree_complete_minimal.RData")
# N ~ 3,000, 7 covariates

# Theory-driven covariates
load("data/processed/mcs_semtree_complete_theory.RData")
# N ~ 2,000, 8 covariates

# All covariates (most complete information)
load("data/processed/mcs_semtree_complete_full.RData")
# N ~ 900, 47 covariates
```

**For Latent Growth Models:**

```r
# Lavaan with FIML (allows missing SC waves)
load("data/processed/mcs_lavaan_fiml.RData")
# N ~ 10,000, requires ≥3 waves of SC data
```

**For Mixed Models:**

```r
# Long format with time-varying structure
load("data/processed/mcs_long_format.RData")
# ~60,000 person-period observations
```

### Troubleshooting Phase 0

**Error: "Cannot find raw data files"**
```
Solution: Ensure MCS data is in data/raw/MCS [1-7]/stata*/
Check that you have downloaded all required waves
```

**Error: "Package not installed"**
```r
# Install required packages
install.packages(c("tidyverse", "haven", "here", "naniar"))
```

**Warning: "Many missing values"**
```
This is expected due to attrition across waves
Phase 0 handles missing data appropriately
Multiple datasets created for different missingness patterns
```

**Want to re-run Phase 0?**
```r
# Safe - will overwrite previous output
source("R/data_prep/00_master_data_prep.R")
```

### What's Next?

After Phase 0 completes:

1. **Review quality checks**: `results/quality_checks/`
2. **Check dataset summary**: `data/processed/dataset_summary.csv`
3. **Choose appropriate dataset** for your analysis
4. **Proceed to Phase 1**: Enhanced Analyses (NEW) or Original Pipeline

```r
# Option A: Run Phase 1 enhanced analyses (RECOMMENDED)
source("R/enhanced_analyses/01_extract_growth_parameters.R")

# Option B: Run original pipeline
source("R/01_measurement.R")
```

---

## Phase 1: Enhanced Analyses (NEW)

**RECOMMENDED APPROACH**: This phase implements multiple complementary strategies to address the robust null finding from the original analysis.

### Overview

Phase 1 provides **increased statistical power** through:
- Larger sample sizes (N~3,000 vs N=917)
- Simpler models (1 outcome vs 42 indicators)
- Multiple analytical perspectives
- Theory-driven hypothesis testing

**Runtime**: ~40-50 minutes total
**Input**: Phase 0 output datasets
**Output**: Multiple SEMTree results + synthesis

### Why Phase 1?

**Original Finding**: No splits found across 151 SEMTree analyses (N=917)

**Phase 1 Innovations**:
1. **Two-stage approach**: Extract growth parameters first, then split on simpler models
2. **Time-specific analysis**: Cross-sectional trees at each age (larger N per analysis)
3. **Theory-driven moderation**: Test specific theoretical hypotheses
4. **Regression benchmarking**: Detect small effects SEMTree may miss
5. **Cross-method validation**: Convergent findings = robust conclusions

### Quick Start

**Run all Phase 1 analyses**:
```r
# Extract growth parameters first (required for all subsequent analyses)
source("R/enhanced_analyses/01_extract_growth_parameters.R")

# Regression analysis (baseline for comparison)
source("R/enhanced_analyses/02_regression_growth_params.R")

# Two-stage SEMTree
source("R/enhanced_analyses/03_semtree_intercept.R")
source("R/enhanced_analyses/04_semtree_slope.R")

# Time-specific cross-sectional analysis
source("R/enhanced_analyses/05_semtree_timespecific.R")

# Theory-driven moderation
source("R/enhanced_analyses/06_semtree_moderation.R")

# Synthesis and comparison
source("R/enhanced_analyses/07_compare_results.R")
```

### Script Descriptions

#### 01_extract_growth_parameters.R
**Purpose**: Extract individual-level intercept (i) and slope (s) from LGBM

**What it does**:
- Fits second-order latent growth basis model (6 waves, 42 indicators)
- Extracts factor scores for growth parameters
- Computes standard errors and confidence intervals
- Merges with covariates

**Key output**: `data/processed/growth_parameters_with_covariates.RData`

**Runtime**: 5-10 minutes

**Why this matters**: Simplifies outcome from 42 ordinal indicators → 2 continuous growth parameters = more power

---

#### 02_regression_growth_params.R
**Purpose**: Regression analysis predicting intercept and slope

**What it does**:
- Tests baseline covariates
- Adds parenting variables incrementally
- Tests interactions (SES × harsh, sex × positive)
- Creates coefficient plots

**Key outputs**:
- `results/tables/regression_summary.csv`
- `results/figures/regression_coef_intercept.pdf`

**Runtime**: 1-2 minutes

**Why this matters**: Regression has more power for small linear effects than SEMTree

---

#### 03_semtree_intercept.R
**Purpose**: Two-stage SEMTree on intercept (initial SC level)

**What it does**:
- Simple SEM model: `i ~ 1; i ~~ i` (mean and variance)
- Standard parameters (α=.05, min.N=100)
- Relaxed parameters (α=.10, min.N=50) for sensitivity
- If splits found: runs SEMForest for variable importance

**Key outputs**:
- `results/models/semtree_intercept_standard.RData`
- `results/figures/semtree_intercept_standard.pdf`

**Runtime**: 3-5 minutes

**Research question**: Do covariates predict who starts HIGH vs LOW?

---

#### 04_semtree_slope.R
**Purpose**: Two-stage SEMTree on slope (rate of change)

**What it does**:
- Simple SEM model: `s ~ 1; s ~~ s`
- Standard and relaxed parameters
- If splits found: runs SEMForest

**Key outputs**:
- `results/models/semtree_slope_standard.RData`
- `results/figures/semtree_slope_standard.pdf`

**Runtime**: 3-5 minutes

**Research question**: Do covariates predict who IMPROVES vs DECLINES faster?

---

#### 05_semtree_timespecific.R
**Purpose**: Cross-sectional SEMTree at each developmental stage

**What it does**:
- Loops through ages 3, 5, 7, 11, 14, 17
- Uses wave-specific SC factor scores
- Identifies age-specific subgroups
- Creates developmental summary

**Key outputs**:
- Individual trees: `results/models/semtree_age3.RData` ... `semtree_age17.RData`
- Summary: `results/tables/timespecific_semtree_summary.csv`
- Trajectory plot with splits marked

**Runtime**: 10-15 minutes

**Research questions**:
- Do different covariates matter at different ages?
- Are there critical developmental periods?
- Do subgroups emerge at certain stages?

---

#### 06_semtree_moderation.R
**Purpose**: Theory-driven moderation hypothesis testing

**Tests 5 theoretical hypotheses**:
1. **H1**: SES × Harsh Parenting (differential susceptibility)
2. **H2**: Sex × Positive Parenting (differential effectiveness)
3. **H3**: Cognitive × SES (compensatory effects)
4. **H4**: Temperament × Harsh Parenting (diathesis-stress)
5. **H5**: Cognitive × Harsh Parenting (protective factor)

**What it does**:
- For each hypothesis: tests moderation of intercept AND slope
- Uses focused covariate sets (not all 47 covariates)
- More power through hypothesis-driven approach

**Key outputs**:
- Individual models: `results/models/semtree_h1_ses_harsh_intercept.RData` etc.
- Summary: `results/tables/moderation_semtree_summary.csv`
- Heatmap visualization

**Runtime**: 15-20 minutes

**Why this matters**: Theory-driven approach has more power than exploratory

---

#### 07_compare_results.R
**Purpose**: Synthesize findings across all Phase 1 approaches

**What it does**:
- Loads results from all previous scripts
- Creates comprehensive comparison tables
- Generates cross-method visualizations
- Identifies convergent/divergent findings
- Provides interpretation guide and recommendations

**Key outputs**:
- `results/synthesis/methods_comparison_summary.csv`
- `results/synthesis/fig_methods_comparison.pdf`
- `results/synthesis/fig_timespecific_trajectory.pdf`
- `results/synthesis/fig_moderation_heatmap.pdf`

**Runtime**: 1-2 minutes

**Why this matters**: Cross-method convergence = robust conclusions

---

### Interpreting Phase 1 Results

#### If ALL methods find NO effects (convergent null):
**Interpretation**: Strong evidence for homogeneous self-control development
- Universal prevention approaches supported
- No need for complex risk stratification
- Document as robust null finding (valuable!)

**Next steps**:
- Manuscript emphasizing homogeneity
- Theoretical implications
- Consider alternative unmeasured moderators

---

#### If SOME methods find effects (mixed):
**Interpretation**: Method-specific insights
- Regression finds small linear effects
- SEMTree detects non-linear/interactions
- Time-specific reveals critical periods

**Next steps**:
- Report all findings transparently
- Discuss method differences
- Consider replication in independent sample

---

#### If ALL methods find effects (convergent positive):
**Interpretation**: Strong evidence for heterogeneous development
- Targeted interventions justified
- Identify key moderators
- Characterize subgroups

**Next steps**:
- Quantify subgroup differences
- Replicate findings
- Develop screening tools
- Design tailored interventions

---

### Comparison with Original Pipeline

| Aspect | Original Pipeline | Phase 1 Enhanced |
|--------|------------------|------------------|
| Sample size | N=917 | N~3,000 |
| Outcome complexity | 42 ordinal indicators | 1-2 continuous parameters |
| Approaches | Single SEMTree | 6 complementary methods |
| Power | Limited | Substantially increased |
| Interpretation | Complex | Clearer, multiple angles |
| Hypothesis testing | Exploratory | Theory-driven + exploratory |

**Recommendation**: Run Phase 1 for comprehensive analysis. Original pipeline still valuable for comparison and specific needs.

---

### Phase 1 Complete Documentation

For detailed implementation guide, see:
- `docs/PHASE1_IMPLEMENTATION_SUMMARY.md`

---

## Data Preparation (Original Pipeline)

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
