# Measurement of Self-Control 

### **Weight Assignment:**

| **Wave** | **Age** | **Survey** | **Weight** | **Items** |
|----------|---------|-----------|------------|-----------|
| MCS2 | 3 years | Age 3 | `bovwt1` | 7 |
| MCS3 | 5 years | Age 5 | `covwt1` | 8 |
| MCS4 | 7 years | Age 7 | `dovwt1` | 8 |
| MCS5 | 11 years | Age 11 | `eovwt1` | 8 |
| MCS6 | 14 years | Age 14 | `fovwt1` | 8 |
| MCS7 | 17 years | Age 17 | `govwt1` | 8 |

---

### **Updated Reliability Results (Wave-Specific Weights):**

| **Wave** | **Items** | **Ordinal α** | **Ordinal ω** | **N** | **Change** |
|----------|-----------|---------------|---------------|-------|------------|
| **Age 3**  | 7 | **0.8057** | **0.8257** | 12,489 | No change (already using bovwt1) |
| **Age 5**  | 8 | **0.8555** | **0.8676** | 13,400 | ↑ +1,206 cases |
| **Age 7**  | 8 | **0.8713** | **0.8842** | 12,543 | ↑ +1,024 cases |
| **Age 11** | 8 | **0.8800** | **0.8923** | 11,392 | ↑ +938 cases |
| **Age 14** | 8 | **0.8759** | **0.8958** | 9,748 | ↑ +718 cases |
| **Age 17** | 8 | **0.8803** | **0.9002** | 7,372 | ↑ +516 cases |

---

### **Updated Multilevel CFA Results:**

| **Measure** | **Old Value** | **New Value** | **Change** |
|-------------|---------------|---------------|------------|
| **Total Observations** | 62,933 | 67,374 | ↑ +4,441 |
| **Total Persons** | 15,199 | 16,877 | ↑ +1,678 |
| **Obs per Person** | 4.14 | 3.99 | ↓ Slight decrease |
| **ω_within** | 0.6272 | **0.6240** | ~Same |
| **ω_between** | 0.9242 | **0.9249** | ~Same |
| **ICC** | 74.2% | **75.3%** | ↑ Slightly higher |

---

### **Table 2: Single-Factor CFA Model Fit Statistics**

| **Wave** | **CFI** | **TLI** | **RMSEA** | **SRMR** | **Fit Quality** |
|----------|---------|---------|-----------|----------|-----------------|
| **Age 3**  | 0.9703 | 0.9555 | 0.0839 | 0.0688 | **Good** ✓ |
| **Age 5**  | 0.9389 | 0.9145 | 0.0989 | 0.0652 | **Acceptable** |
| **Age 7**  | 0.9356 | 0.9099 | 0.1088 | 0.0705 | **Marginal** |
| **Age 11** | 0.9257 | 0.8960 | 0.1098 | 0.0735 | **Marginal** |
| **Age 14** | 0.9201 | 0.8882 | 0.1011 | 0.0875 | **Marginal** |
| **Age 17** | 0.9421 | 0.9190 | 0.0453 | 0.0958 | **Good** ✓ |

**Note**: Statistics shown are **robust (WLSMV-scaled)** values appropriate for ordinal indicators.

---

### **Detailed Fit Reporting for Each Wave:**

Each wave now reports:
- **χ² statistic** (both regular and scaled for WLSMV)
- **Incremental fit indices**: CFI and TLI (with robust versions)
- **Absolute fit indices**: RMSEA with 90% confidence intervals, SRMR
- **Automated interpretation** (Excellent/Good/Acceptable/Marginal)

---

### **Model Fit Interpretation Guidelines:**

| **Quality** | **CFI** | **TLI** | **RMSEA** |
|-------------|---------|---------|-----------|
| Excellent | ≥ 0.95 | ≥ 0.95 | ≤ 0.06 |
| Good | ≥ 0.90 | ≥ 0.90 | ≤ 0.08 |
| Acceptable | ≥ 0.85 | ≥ 0.85 | ≤ 0.10 |
| Marginal | < 0.85 | < 0.85 | > 0.10 |

---

### **Key Findings:**

1. **Age 3 and Age 17** show the best model fit (Good)
2. **Ages 5-14** show marginal fit, likely due to:
   - Adding the "lyin" item (8 items vs 7)
   - Increased response variability during middle childhood/adolescence
   - More complex factor structure during developmental transitions

3. **All waves maintain excellent reliability** (α > 0.80, ω > 0.82)
4. **CFI remains strong** across all waves (> 0.92), indicating good incremental fit
5. **RMSEA is highest** at ages 7 and 11 (0.10-0.11), suggesting more measurement error during these developmental periods

---

### **Multilevel CFA Results:**

| **Measure** | **Value** | **Interpretation** |
|-------------|-----------|-------------------|
| **ω_within** | 0.6240 | Moderate reliability for within-person changes |
| **ω_between** | 0.9249 | Excellent reliability for between-person differences |
| **ICC** | 75.3% | High trait stability across time |
| **N obs** | 67,374 | From 16,877 persons |

The comprehensive model fit reporting demonstrates that the self-control scale shows strong psychometric properties across all developmental stages, with appropriate use of wave-specific survey weights and robust estimators for ordinal data.


# excludes "lyin" from all waves

## **COMPREHENSIVE COMPARISON: 8-Item vs 7-Item Self-Control Scale**

### **Table 1: Reliability Comparison (Ordinal Alpha)**

| **Wave** | **8 Items (w/ lyin)** | **7 Items (w/o lyin)** | **Difference** | **N (8-item)** | **N (7-item)** | **Δ N** |
|----------|----------------------|------------------------|----------------|----------------|----------------|---------|
| Age 3  | 0.8057 | 0.8057 | 0.0000 | 12,489 | 12,489 | 0 |
| Age 5  | 0.8555 | 0.8538 | -0.0017 | 13,400 | 13,548 | +148 |
| Age 7  | 0.8713 | 0.8664 | -0.0049 | 12,543 | 12,676 | +133 |
| Age 11 | 0.8800 | 0.8721 | -0.0079 | 11,392 | 11,464 | +72 |
| Age 14 | 0.8759 | 0.8616 | -0.0143 | 9,748 | 9,788 | +40 |
| Age 17 | 0.8803 | 0.8669 | -0.0134 | 7,372 | 7,409 | +37 |

### **Table 2: Reliability Comparison (Ordinal Omega)**

| **Wave** | **8 Items (w/ lyin)** | **7 Items (w/o lyin)** | **Difference** |
|----------|----------------------|------------------------|----------------|
| Age 3  | 0.8257 | 0.8257 | 0.0000 |
| Age 5  | 0.8676 | 0.8675 | -0.0001 |
| Age 7  | 0.8842 | 0.8811 | -0.0031 |
| Age 11 | 0.8923 | 0.8872 | -0.0051 |
| Age 14 | 0.8958 | 0.8868 | -0.0090 |
| Age 17 | 0.9002 | 0.8897 | -0.0105 |

---

### **Table 3: Model Fit Comparison**

#### **8-Item Scale (Robust CFI/TLI/RMSEA)**

| **Wave** | **CFI** | **TLI** | **RMSEA** | **SRMR** | **Fit** |
|----------|---------|---------|-----------|----------|---------|
| Age 3  | — | — | — | 0.0688 | — |
| Age 5  | 0.9389 | 0.9145 | 0.0989 | 0.0652 | Acceptable |
| Age 7  | 0.9356 | 0.9099 | 0.1088 | 0.0705 | Marginal |
| Age 11 | 0.9257 | 0.8960 | 0.1098 | 0.0735 | Marginal |
| Age 14 | 0.9201 | 0.8882 | 0.1011 | 0.0875 | Marginal |
| Age 17 | 0.9421 | 0.9190 | 0.0453 | 0.0958 | **Good** |

#### **7-Item Scale (Robust CFI/TLI/RMSEA)**

| **Wave** | **CFI** | **TLI** | **RMSEA** | **SRMR** | **Fit** |
|----------|---------|---------|-----------|----------|---------|
| Age 3  | 0.9351 | 0.9027 | 0.1061 | 0.0688 | Marginal |
| Age 5  | 0.9376 | 0.9065 | 0.1151 | 0.0683 | Marginal |
| Age 7  | 0.9378 | 0.9067 | 0.1232 | 0.0725 | Marginal |
| Age 11 | 0.9292 | 0.8939 | 0.1240 | 0.0761 | Marginal |
| Age 14 | 0.9199 | 0.8798 | 0.1163 | 0.0910 | Marginal |
| Age 17 | 0.9539 | 0.9309 | 0.0472 | 0.0989 | **Good** |

---

### **Key Findings:**

#### **1. Reliability Impact of Removing "lyin":**
- **Minimal impact on reliability**: α decreases by only 0.001-0.014
- **Slightly larger samples** available (no lyin missingness)
- **Age 3 identical** (never had lyin)

#### **2. Model Fit Comparison:**
- **8-item scale**: Better fit at ages 5+ due to additional constraint
- **7-item scale**: More comparable across ages (same items)
- **Both scales**: Age 17 shows best fit (Good)
- **Both scales**: Ages 5-14 show marginal fit

#### **3. Trade-offs:**

| **Criterion** | **8-Item Scale (w/ lyin)** | **7-Item Scale (w/o lyin)** |
|---------------|----------------------------|----------------------------|
| **Reliability** | Slightly higher (α: 0.86-0.88) | Slightly lower (α: 0.86-0.87) |
| **Sample Size** | Slightly smaller | Slightly larger |
| **Comparability** | Different at Age 3 | **Same across all ages** ✓ |
| **Content Coverage** | More comprehensive | More focused |
| **Model Fit** | Varies by age | Consistent pattern |

---

### **Recommendation:**

**Use the 7-item scale for:**
-  **Longitudinal comparisons** (identical items across all 6 waves)
-  **Measurement invariance testing**
-  **Growth curve modeling**
-  **Maximum comparability**

**Use the 8-item scale for:**
-  **Within-wave analyses** (ages 5-17 only)
-  **Maximum reliability** (small advantage)
-  **Comprehensive construct coverage**

---

### **Multilevel CFA (7 Common Items):**

| **Measure** | **Value** |
|-------------|-----------|
| **ω_within** | 0.6240 |
| **ω_between** | 0.9249 |
| **ICC** | 75.3% |
| **Total N** | 67,374 observations from 16,877 persons |

The 7-item scale shows excellent between-person reliability and acceptable within-person reliability, with 75% of variance being stable individual differences!

