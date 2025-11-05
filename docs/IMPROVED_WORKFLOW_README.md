# Improved SEMTree Workflow for MCS Self-Control Analysis

**Created:** 2025-11-05
**Purpose:** Comprehensive multi-method analysis of self-control development trajectories

---

## Overview

This improved workflow addresses the original study's limitation (no splits found in SEMTree) by implementing a **multi-strategy approach** that combines three complementary methods:

1. **SEMTree** - Identifies subgroups (interactions/heterogeneity)
2. **Regression** - Identifies main effects (uniform associations)
3. **Machine Learning** - Variable importance + prediction

**Key Innovation:** Two-stage approach using factor scores for increased power and clearer interpretation.

---

## Workflow Structure

```
COMPLETE ANALYSIS PIPELINE
│
├── Phase 0: Data Preparation (NEW!)
│   └── R/data_prep/00_master_data_prep.R → Run ONCE to create all datasets
│
├── Phase 1: Measurement & Factor Scores
│   ├── 06a_semtree_factor_scores.R → Extract factor scores with SE
│   └── Output: mcs_twostage_dataset.RData
│
├── Phase 2: SEMTree Analyses (Multiple Strategies)
│   ├── 06b_semtree_intercept.R → Intercept tree (initial SC)
│   ├── 06c_semtree_slope.R → Slope tree (rate of change)
│   ├── 06d_semtree_timespecific.R → Age-specific cross-sectional trees
│   └── 06e_semtree_theory_driven.R → Theory-driven moderation tests
│
├── Phase 3: Complementary Analyses
│   ├── 07a_regression_analysis.R → Traditional regression (main effects)
│   └── 07b_machine_learning.R → RF/GBM variable importance
│
├── Phase 4: Synthesis & Reporting
│   ├── 08a_compare_methods.R → Compare all three methods
│   └── 08b_visualizations.R → Publication-ready figures
│
└── Output: Comprehensive results + visualizations
```

---

## Quick Start Guide

### Step 1: Data Preparation (Run Once)

```r
# This creates all analysis-ready datasets from raw MCS data
source("R/data_prep/00_master_data_prep.R")

# Runtime: ~10-20 minutes
# Output: 6 analysis-ready datasets + quality reports
```

**What this does:**
- Extracts data from MCS Waves 1-7 (ages 9 months to 17 years)
- Harmonizes variable names across waves
- Creates derived composites (parenting, SES, risk indices)
- Generates multiple datasets optimized for different analyses
- Runs quality checks and creates documentation

**Datasets created:**
- `mcs_semtree_complete_minimal.RData` - N~3,000, 7 covariates (⭐ RECOMMENDED)
- `mcs_lavaan_fiml.RData` - N~10,000, FIML-ready for growth models
- `mcs_long_format.RData` - Long format for mixed models
- `mcs_merged_wide.RData` - Full dataset for exploration

### Step 2: Extract Factor Scores

```r
source("R/06a_semtree_factor_scores.R")

# Runtime: ~5-10 minutes
# Output: Factor scores for all waves + growth parameters
```

**What this does:**
- Extracts wave-specific self-control factor scores (ages 3-17)
- Extracts growth parameters (intercept, slope) from LGBM
- Includes standard errors for measurement error propagation
- Creates two-stage analysis dataset

### Step 3: Run SEMTree Analyses

```r
# Intercept tree (what predicts initial SC?)
source("R/06b_semtree_intercept.R")

# Slope tree (what predicts change?)
source("R/06c_semtree_slope.R")

# Time-specific trees (age-specific patterns)
source("R/06d_semtree_timespecific.R")

# Theory-driven tests (specific hypotheses)
source("R/06e_semtree_theory_driven.R")
```

**What these do:**
- Test multiple alpha levels (0.05, 0.10, 0.15, 0.20)
- Report individual covariate tests even if no tree splits
- Compare effect sizes across predictors
- Generate visualizations for each analysis

### Step 4: Run Complementary Analyses

```r
# Traditional regression (detect small main effects)
source("R/07a_regression_analysis.R")

# Machine learning (variable importance)
source("R/07b_machine_learning.R")
```

**Why these matter:**
- SEMTree finds SUBGROUPS (interactions)
- Regression finds MAIN EFFECTS (uniform associations)
- ML maximizes PREDICTION and handles complex interactions
- Together: Comprehensive picture of what predicts self-control

### Step 5: Compare Methods & Visualize

```r
# Cross-method comparison
source("R/08a_compare_methods.R")

# Publication figures
source("R/08b_visualizations.R")
```

**Final outputs:**
- Method comparison report
- 6 publication-ready figures
- Convergence metrics across methods

---

## Key Improvements Over Original Workflow

| Issue | Original Approach | Improved Approach |
|-------|------------------|------------------|
| **Sample Size** | N=917 (complete case, 47 covariates) | N~3,000 (7 focused covariates) = **3.3x increase!** |
| **Model Complexity** | Full LGBM (42 indicators) | Two-stage with factor scores (simpler, more power) |
| **Null Findings** | "No splits found" → Dead end | Multiple methods → Interpretable regardless of splits |
| **Alpha Testing** | Single α=0.05 | Progressive relaxation (0.05, 0.10, 0.15, 0.20) |
| **Predictors** | All baseline covariates | Intercept vs. Slope specific + time-varying parenting |
| **Analysis Depth** | SEMTree only | SEMTree + Regression + ML = Triangulation |
| **Effect Sizes** | No effect sizes reported | Cohen's d for all tests |
| **Validation** | None | Cross-validation + test set performance |

---

## Understanding the Results

### Scenario 1: Still No Splits in SEMTree

**This is NOT a failure!** It means:
- Self-control development is **homogeneous** across tested covariates
- Effects are **too small** for subgroup detection (but may exist!)
- Look to **regression** for small uniform effects
- Check **ML variable importance** for predictive relationships
- **Publishable:** "Absence of heterogeneity as substantive finding"

### Scenario 2: Weak Effects Detected

- **Regression:** Small but significant β (uniform effects)
- **ML:** Variable importance rankings (what matters most)
- **SEMTree:** May still find no splits (correct - effects too small for subgroups)
- **Interpretation:** Small effects across population, not subgroup-specific

### Scenario 3: Subgroups Found!

- **Intercept tree:** Different groups start at different levels
- **Slope tree:** Different groups show different developmental trajectories
- **Theory-driven:** Specific moderation hypotheses confirmed
- **Interpretation:** Developmental heterogeneity exists!

---

## Output Files Reference

### Results Directory Structure

```
results/
├── semtrees/
│   ├── intercept_tree.RData
│   ├── slope_tree.RData
│   ├── timespecific_trees.RData
│   └── theory_driven_trees.RData
│
├── regression/
│   └── intercept_slope_regression.RData
│
├── machine_learning/
│   └── ml_results.RData
│
├── method_comparison/
│   └── comparison_summary.RData
│
├── reports/
│   ├── intercept_tree_summary.md
│   ├── slope_tree_summary.md
│   └── method_comparison_report.md
│
└── plots/
    ├── semtrees/
    │   ├── intercept_tree.pdf
    │   ├── intercept_covariate_effects.pdf
    │   ├── slope_tree.pdf
    │   └── slope_parenting_effects.pdf
    │
    ├── regression/
    │   ├── intercept_coefficients.pdf
    │   └── slope_coefficients.pdf
    │
    ├── machine_learning/
    │   ├── intercept_variable_importance.pdf
    │   └── prediction_performance.pdf
    │
    ├── method_comparison/
    │   └── intercept_method_comparison.pdf
    │
    └── publication/
        ├── fig1_trajectories.pdf
        ├── fig2_trajectories_by_parenting.pdf
        ├── fig3_growth_parameters.pdf
        ├── fig4_correlations.pdf
        ├── fig5_effect_size_dashboard.pdf
        └── fig6_summary.pdf
```

---

## Key Research Questions Addressed

### 1. Do covariates predict INITIAL self-control (intercept)?

**Methods:**
- `06b_semtree_intercept.R` - Tests for subgroups
- `07a_regression_analysis.R` - Tests for main effects
- `07b_machine_learning.R` - Ranks variable importance

**Predictors:** Baseline characteristics (SES, cognition, sex, birth outcomes, early parenting)

### 2. Do covariates predict CHANGE in self-control (slope)?

**Methods:**
- `06c_semtree_slope.R` - Tests for subgroups
- `07a_regression_analysis.R` - Tests for main effects
- `07b_machine_learning.R` - Ranks variable importance

**Predictors:** Time-varying parenting (early harsh, positive, adolescent monitoring) + baseline

**Key Hypothesis:** Parenting may predict CHANGE even if not initial levels!

### 3. Are there age-specific effects?

**Method:** `06d_semtree_timespecific.R`

**Analysis:** Separate trees for ages 3, 5, 7, 11, 14, 17

**Question:** Do different covariates matter at different developmental stages?

### 4. Do specific moderation hypotheses hold?

**Method:** `06e_semtree_theory_driven.R`

**Tests:**
- SES × Parenting: Does harsh parenting matter more in low-SES contexts?
- Sex × Parenting: Do boys and girls respond differently?
- Cognition × Parenting: Differential sensitivity by ability?

---

## Interpretation Guidelines

### Effect Size Benchmarks

| Cohen's d | Interpretation |
|-----------|----------------|
| 0.0 - 0.2 | Negligible/Small |
| 0.2 - 0.5 | Small/Medium |
| 0.5 - 0.8 | Medium/Large |
| > 0.8 | Large |

### R² Interpretation

| R² | Variance Explained |
|----|-------------------|
| < 0.02 | Negligible |
| 0.02 - 0.13 | Small |
| 0.13 - 0.26 | Medium |
| > 0.26 | Large |

### Method Convergence

| Correlation | Interpretation |
|------------|----------------|
| r > 0.7 | High convergence (methods agree) |
| 0.4 < r < 0.7 | Moderate (different aspects) |
| r < 0.4 | Low (different phenomena) |

---

## Troubleshooting

### Problem: Data prep script fails

**Solution:**
- Check that raw MCS data is in `data/raw/MCS [1-7]/stata*/`
- Verify Stata file names match script expectations
- Check R packages installed: `tidyverse`, `haven`, `here`

### Problem: Factor score extraction fails

**Solution:**
- Ensure `06a` is run AFTER data prep (Phase 0)
- Check that `mcs_semtree_complete_minimal.RData` exists
- Verify `lavaan` package is installed

### Problem: SEMTree runs forever

**Solution:**
- Reduce sample size in control settings
- Increase `min.N` parameter (default: 100)
- Reduce `max.depth` (default: 5)

### Problem: No splits found at any alpha level

**This is OK!** See "Understanding the Results" section above. Proceed to regression and ML analyses for complementary insights.

---

## Citation & Acknowledgments

If you use this workflow, please cite:

```bibtex
@software{mcs_semtree_workflow,
  title = {Improved SEMTree Workflow for Longitudinal Developmental Analysis},
  author = {Your Name},
  year = {2025},
  note = {Multi-method approach combining SEMTree, regression, and machine learning}
}
```

**Data Source:** UK Millennium Cohort Study (MCS)

---

## Contact & Support

For questions about:
- **Data preparation:** See `docs/variable_reference.md`
- **SEMTree methods:** See `results/reports/*_summary.md` files
- **Interpretation:** See "Understanding the Results" section above
- **Technical issues:** Check `docs/workflow.md` troubleshooting section

---

## Next Steps for Publication

1. **Run all analyses** using this workflow
2. **Review method comparison** report (`results/reports/method_comparison_report.md`)
3. **Identify key findings** across all three methods
4. **Use publication figures** from `results/plots/publication/`
5. **Write up results** emphasizing complementarity of methods
6. **Report effect sizes** (not just p-values!)
7. **Discuss implications** of convergence (or divergence) across methods

**Key Message:** Even if SEMTree finds no splits, you have a comprehensive analysis showing:
- Whether effects are uniform or heterogeneous
- Which predictors matter most
- Relative predictive accuracy
- Developmental patterns across ages

**This is publishable regardless of whether splits are found!**

---

## Summary

This improved workflow provides:

✅ **3.3x larger sample size**
✅ **Multiple analysis strategies** (not just SEMTree)
✅ **Interpretable results** regardless of whether splits found
✅ **Effect sizes** for all tests
✅ **Publication-ready figures**
✅ **Comprehensive documentation**
✅ **Reproducible pipeline** (fully scripted)

**Time investment:** ~1 hour to run all analyses
**Scientific payoff:** Robust, triangulated findings about self-control development

Good luck with your research!
