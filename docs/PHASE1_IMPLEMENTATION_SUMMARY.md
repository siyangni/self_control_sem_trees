# Phase 1: Enhanced Analyses - Implementation Summary

## Overview

Phase 1 implements **multiple complementary SEMTree approaches** to address the robust null finding from the original analysis (no splits found in N=917 complete cases). These enhanced analyses provide:

1. **Increased statistical power** through larger sample sizes and simpler models
2. **Multiple perspectives** on the same research question
3. **Theory-driven hypothesis testing** alongside exploratory analysis
4. **Cross-method validation** of findings

---

## Key Innovations

### 1. Two-Stage SEMTree Approach
**Problem:** Original SEMTree split on full LGBM (42 ordinal indicators simultaneously)
**Solution:** Extract growth parameters first, then split on simpler models

**Advantages:**
- Simpler outcome (1 continuous variable vs 42 ordinal indicators)
- Can use ML estimator (faster, more standard)
- More power to detect subgroups
- Clearer interpretation

### 2. Time-Specific Cross-Sectional Analysis
**Problem:** Growth models require complete data on all 6 waves (limits N)
**Solution:** Analyze self-control at each age separately

**Advantages:**
- Can include participants with missing waves (larger N)
- Reveals age-specific moderator effects
- Identifies critical developmental periods
- No need to fit complex growth model first

### 3. Theory-Driven Moderation Testing
**Problem:** Exploratory SEMTree tests many covariates (multiple testing burden)
**Solution:** Focus on specific theoretical interaction hypotheses

**Advantages:**
- More power (fewer tests = less correction needed)
- Directly tests criminological theories
- Clearer interpretation (a priori hypotheses)
- Facilitates theory building/testing

### 4. Regression Benchmarking
**Problem:** SEMTree may miss small effects (needs larger effects to split)
**Solution:** Run parallel regression analysis

**Advantages:**
- More power for small linear effects
- Provides effect size estimates
- Can explicitly test interactions
- Complements tree-based findings

---

## Scripts Created

### R/enhanced_analyses/01_extract_growth_parameters.R
**Purpose:** Extract individual-level intercept and slope from LGBM

**What it does:**
1. Fits second-order latent growth basis model (6 waves, 42 indicators)
2. Extracts factor scores for all latent variables:
   - `SC_3, SC_5, SC_7, SC_11, SC_14, SC_17` (wave-specific SC)
   - `i` (intercept - initial level at age 3)
   - `s` (slope - rate of change from 3 to 17)
3. Computes standard errors and confidence intervals
4. Merges with covariates

**Key outputs:**
- `data/processed/growth_parameters.RData`
- `data/processed/growth_parameters_with_covariates.RData`
- `results/models/lgbm_fitted_model.RData`

**Runtime:** 5-10 minutes

---

### R/enhanced_analyses/02_regression_growth_params.R
**Purpose:** Regression analysis predicting intercept and slope

**What it does:**
1. **Model 1a/1b (Intercept):** Baseline → Baseline + Parenting
2. **Model 2a/2b (Slope):** Baseline → Baseline + Parenting
3. **Interaction models:** SES × harsh, sex × positive
4. Incremental R² tests
5. Coefficient plots

**Key outputs:**
- `results/tables/regression_summary.csv`
- `results/tables/regression_incremental_r2.csv`
- `results/figures/regression_coef_intercept.pdf`
- `results/figures/regression_coef_slope.pdf`

**Runtime:** 1-2 minutes

**Interpretation:**
- Provides effect sizes (regression doesn't need large effects to detect)
- Tests whether parenting adds predictive power beyond baseline
- Complements SEMTree findings (linear vs non-linear effects)

---

### R/enhanced_analyses/03_semtree_intercept.R
**Purpose:** Two-stage SEMTree focusing on intercept (initial SC level)

**What it does:**
1. Loads extracted intercept scores
2. Creates simple SEM model: `i ~ 1; i ~~ i` (mean and variance only)
3. Runs SEMTree with:
   - **Standard parameters:** α=.05, min.N=100
   - **Relaxed parameters:** α=.10, min.N=50 (sensitivity analysis)
4. If splits found, runs SEMForest for variable importance

**Key outputs:**
- `results/models/semtree_intercept_standard.RData`
- `results/models/semtree_intercept_relaxed.RData`
- `results/figures/semtree_intercept_standard.pdf`

**Runtime:** 3-5 minutes

**Research question:** Do covariates predict who starts with HIGH vs LOW self-control at age 3?

---

### R/enhanced_analyses/04_semtree_slope.R
**Purpose:** Two-stage SEMTree focusing on slope (rate of change)

**What it does:**
1. Loads extracted slope scores
2. Creates simple SEM model: `s ~ 1; s ~~ s`
3. Runs SEMTree (standard and relaxed parameters)
4. If splits found, runs SEMForest

**Key outputs:**
- `results/models/semtree_slope_standard.RData`
- `results/models/semtree_slope_relaxed.RData`
- `results/figures/semtree_slope_standard.pdf`

**Runtime:** 3-5 minutes

**Research question:** Do covariates predict who IMPROVES vs DECLINES faster?

---

### R/enhanced_analyses/05_semtree_timespecific.R
**Purpose:** Cross-sectional SEMTree at each developmental stage

**What it does:**
1. Loops through 6 ages (3, 5, 7, 11, 14, 17)
2. For each age:
   - Uses wave-specific SC factor score (`SC_3`, `SC_5`, etc.)
   - Runs SEMTree with theory-driven covariates
   - Checks for subgroups at that specific age
3. Creates summary table across ages
4. Identifies developmental patterns

**Key outputs:**
- `results/models/semtree_age3.RData` through `semtree_age17.RData`
- `results/models/semtree_timespecific_all.RData`
- `results/tables/timespecific_semtree_summary.csv`
- Individual PDFs for each age

**Runtime:** 10-15 minutes

**Research questions:**
- Do different covariates matter at different ages?
- Are there critical periods where subgroups emerge?
- Do developmental stage-specific effects exist?

**Interpretation:**
- Splits at all ages → Persistent subgroup differences
- Splits at specific ages → Critical period effects
- No splits at any age → Robust homogeneity

---

### R/enhanced_analyses/06_semtree_moderation.R
**Purpose:** Theory-driven moderation hypothesis testing

**What it does:**
Tests 5 specific theoretical hypotheses:

1. **H1: SES × Harsh Parenting** (differential susceptibility)
2. **H2: Sex × Positive Parenting** (differential effectiveness)
3. **H3: Cognitive Ability × SES** (compensatory effects)
4. **H4: Difficult Temperament × Harsh Parenting** (diathesis-stress)
5. **H5: Cognitive Ability × Harsh Parenting** (protective factor)

For each hypothesis:
- Tests moderation of intercept (initial level)
- Tests moderation of slope (change rate)
- Uses focused covariate sets (not all 47)

**Key outputs:**
- Individual model files: `semtree_h1_ses_harsh_intercept.RData`, etc.
- `results/models/semtree_moderation_all.RData`
- `results/tables/moderation_semtree_summary.csv`
- Individual PDFs for each hypothesis × outcome

**Runtime:** 15-20 minutes

**Interpretation:**
- Splits found → Evidence for theoretical moderation
- No splits → Null hypothesis supported (homogeneous effects)
- Compare intercept vs slope moderation (different intervention timing)

---

### R/enhanced_analyses/07_compare_results.R
**Purpose:** Synthesize findings across all approaches

**What it does:**
1. Loads results from all previous scripts
2. Creates comprehensive comparison table
3. Generates cross-method visualizations:
   - Detection rate by method
   - Time-specific trajectory with splits marked
   - Moderation hypothesis heatmap
4. Identifies convergent/divergent findings
5. Provides synthesis narrative and recommendations

**Key outputs:**
- `results/synthesis/methods_comparison_summary.csv`
- `results/synthesis/table_methods_comparison_formatted.csv` (manuscript-ready)
- `results/synthesis/fig_methods_comparison.pdf`
- `results/synthesis/fig_timespecific_trajectory.pdf`
- `results/synthesis/fig_moderation_heatmap.pdf`

**Runtime:** 1-2 minutes

**Key interpretations:**
- **Convergent null:** Strong evidence for homogeneity
- **Convergent effects:** Robust subgroup differences
- **Divergent:** Method-specific insights (e.g., non-linear vs linear)

---

## Running Phase 1

### Option 1: Run All Scripts Sequentially

```r
# Navigate to project directory
setwd("~/self_control_sem_trees")

# Run in order
source("R/enhanced_analyses/01_extract_growth_parameters.R")
source("R/enhanced_analyses/02_regression_growth_params.R")
source("R/enhanced_analyses/03_semtree_intercept.R")
source("R/enhanced_analyses/04_semtree_slope.R")
source("R/enhanced_analyses/05_semtree_timespecific.R")
source("R/enhanced_analyses/06_semtree_moderation.R")
source("R/enhanced_analyses/07_compare_results.R")
```

**Total runtime:** ~40-50 minutes

### Option 2: Run Individual Scripts

Each script is self-contained and can be run independently after script 01 has been completed.

**Dependencies:**
- Script 01 must run first (creates growth parameters)
- Scripts 02-06 can run in any order after 01
- Script 07 should run last (synthesizes all results)

### Option 3: Master Script (Coming in Phase 2)

A master orchestration script similar to `00_master_data_prep.R` will be created to run all enhanced analyses with error handling.

---

## Interpreting Results

### If Splits Found (Subgroups Detected)

**Implications:**
1. Heterogeneous self-control development across subgroups
2. Targeted interventions may be warranted
3. Examine terminal nodes to characterize subgroups
4. Quantify effect sizes (differences between subgroups)

**Next steps:**
1. Replicate in independent sample
2. Investigate mechanisms driving differences
3. Develop screening tools for subgroup identification
4. Design tailored interventions

### If No Splits Found (Null Finding)

**Implications:**
1. Homogeneous self-control development
2. Universal prevention approaches supported
3. No need for complex risk stratification
4. Simpler interventions likely to benefit all

**Next steps:**
1. Check regression for small linear effects
2. Consider alternative explanations:
   - True homogeneity (theoretical value!)
   - Insufficient power (check sample sizes)
   - Measurement issues
   - Alternative moderators not tested
3. Document robust null finding (negative results matter!)

### Cross-Method Interpretation

| SEMTree | Regression | Interpretation |
|---------|-----------|----------------|
| Splits found | Significant | **Strong convergence:** Robust effects |
| No splits | No effects | **Strong convergence:** Robust null |
| Splits found | No effects | Non-linear or complex interactions |
| No splits | Significant | Small linear effects (SEMTree threshold not met) |

---

## Output Structure

```
results/
├── models/
│   ├── lgbm_fitted_model.RData
│   ├── semtree_intercept_standard.RData
│   ├── semtree_intercept_relaxed.RData
│   ├── semtree_slope_standard.RData
│   ├── semtree_slope_relaxed.RData
│   ├── semtree_age3.RData ... semtree_age17.RData
│   ├── semtree_timespecific_all.RData
│   ├── semtree_h1_ses_harsh_intercept.RData
│   ├── ... (other moderation models)
│   └── semtree_moderation_all.RData
│
├── figures/
│   ├── regression_coef_intercept.pdf
│   ├── regression_coef_slope.pdf
│   ├── semtree_intercept_standard.pdf
│   ├── semtree_slope_standard.pdf
│   ├── semtree_age3.pdf ... semtree_age17.pdf
│   └── semtree_h1_ses_harsh_intercept.pdf ... (etc.)
│
├── tables/
│   ├── regression_summary.csv
│   ├── regression_incremental_r2.csv
│   ├── timespecific_semtree_summary.csv
│   └── moderation_semtree_summary.csv
│
└── synthesis/
    ├── methods_comparison_summary.csv
    ├── table_methods_comparison_formatted.csv
    ├── fig_methods_comparison.pdf
    ├── fig_timespecific_trajectory.pdf
    └── fig_moderation_heatmap.pdf
```

---

## Theoretical Contributions

Phase 1 analyses address key theoretical questions in criminology and developmental science:

### 1. General vs Differential Development
**Question:** Does self-control develop the same way for everyone?
**Tests:** All SEMTree approaches + regression
**Implications:** Universal vs targeted prevention

### 2. Initial Level vs Change
**Question:** Are subgroups defined by where they START or how they CHANGE?
**Tests:** Intercept vs slope trees
**Implications:** Timing of intervention (early vs continuous)

### 3. Stable vs Age-Specific Effects
**Question:** Do the same factors matter across development?
**Tests:** Time-specific cross-sectional trees
**Implications:** Critical periods, developmental stage-specificity

### 4. Main Effects vs Interactions
**Question:** Do effects depend on context/characteristics?
**Tests:** Theory-driven moderation hypotheses
**Implications:** Differential susceptibility, compensatory effects

### 5. Linear vs Non-Linear Effects
**Question:** Are effects simple additive or complex interactive?
**Tests:** Regression vs SEMTree comparison
**Implications:** Model complexity needed for prediction

---

## Methodological Advantages Over Original Analysis

| Aspect | Original | Phase 1 Enhanced |
|--------|----------|------------------|
| **Sample size** | N=917 | N~3,000 (minimal covariates) |
| **Model complexity** | 42 ordinal indicators | 1 continuous outcome |
| **Estimation** | WLSMV (slower) | ML (faster) |
| **Missing data** | Complete cases only | Can include partial data |
| **Perspective** | Single approach | Multiple complementary |
| **Power** | Limited | Substantially increased |
| **Interpretation** | Complex growth model | Simpler, clearer |

---

## Frequently Asked Questions

### Q1: Why run multiple SEMTree approaches?
**A:** Different approaches have different strengths:
- Two-stage: Maximum power, simplest interpretation
- Time-specific: Reveals developmental timing
- Moderation: Tests specific theories
- Convergence across methods = robust findings

### Q2: What if all approaches find null results?
**A:** This is valuable! Robust null findings:
- Rule out heterogeneity explanations
- Support universal prevention
- Have strong theoretical implications
- Should be published (negative results matter)

### Q3: What if results conflict across methods?
**A:** This reveals complexity:
- Regression finds linear, SEMTree finds non-linear
- Some ages show subgroups, others don't
- Different theories supported by different approaches
- Report all findings transparently

### Q4: How do I choose which covariates to test?
**A:** Multiple strategies provided:
- `covariate_lists$theory`: Theory-driven (8 variables)
- `covariate_lists$minimal`: Maximum power (7 variables)
- `covariate_lists$all_full`: Comprehensive (47 variables)
- Moderation scripts: Hypothesis-specific sets

### Q5: How much power do these analyses have?
**A:** Increased substantially:
- Original: N=917, 47 covariates
- Minimal: N~3,000, 7 covariates (3.3x more participants)
- Simpler models also increase effective power
- Still may not detect very small effects (check regression)

### Q6: Should I run Phase 1 if Phase 0 hasn't been run?
**A:** No. Dependencies:
1. Phase 0 must complete first (creates analysis datasets)
2. Script 01 must run before 02-06
3. Script 07 should run last

---

## Troubleshooting

### Error: "Cannot find growth_parameters_with_covariates.RData"
**Solution:** Run `01_extract_growth_parameters.R` first

### Error: "SEMTree did not converge"
**Solution:**
- Check for categorical variables with too many levels
- Ensure continuous variables are numeric (not character)
- Try relaxed parameters (larger α, smaller min.N)

### Warning: "No splits found"
**Solution:** This is not an error! It's a finding:
- Document it in results
- Check regression for small effects
- Consider theoretical implications

### Long runtime (>1 hour)
**Solution:**
- Expected for forest analyses (100 trees)
- Consider reducing num.trees in forest
- Run on faster machine if available
- Scripts 01, 05, 06 are slowest

### Memory issues
**Solution:**
- Close other R sessions
- Reduce number of trees in forest
- Run scripts sequentially (not in parallel)
- Check available RAM (recommend 8GB minimum)

---

## Next Steps

After completing Phase 1:

1. **Review all output files** (figures, tables, models)
2. **Draft manuscript** using synthesis results
3. **Consider Phase 2** (if additional analyses needed):
   - Multiple imputation for missing data
   - Simplified growth models (parcels, manifest)
   - Piecewise growth models
4. **Consider Phase 3** (advanced methods):
   - Random forest variable importance
   - Machine learning (XGBoost, LightGBM)
   - Latent class growth analysis

---

## Citation

If using these Phase 1 analyses in publications:

- **SEMTree method:** Brandmaier et al. (2013). *Structural Equation Model Trees*. Psychological Methods.
- **UK MCS data:** University of London, Institute of Education, Centre for Longitudinal Studies. (2017). *Millennium Cohort Study*.
- **Two-stage approach:** Novel contribution (cite your paper)
- **lavaan package:** Rosseel, Y. (2012). lavaan: An R package for structural equation modeling. *Journal of Statistical Software*, 48(2), 1-36.

---

## Contact & Support

For questions about this implementation:
- Review documentation in `docs/`
- Check variable reference: `docs/variable_reference.md`
- See original methods: `docs/methods.md`
- Consult workflow: `docs/workflow.md`

---

**Phase 1 Implementation Complete:** 7 analysis scripts, 6 complementary approaches, substantially increased power and interpretability.
