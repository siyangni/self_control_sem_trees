# Merge Self-Control Complete and Parenting Factor Scores for Mplus
# Author: Created for dissertation analysis
# Date: 2025-11-02

# Set working directory
setwd("/home/siyang/dissertation")

# Define column names for sc_wave_fscores_complete.dat
sc_colnames <- c(
  "SC3THAC", "SC3TCOM", "SC3OBEY", "SC3DIST", "SC3TEMP", "SC3REST", "SC3FIDG",
  "SC5THAC", "SC5TCOM", "SC5OBEY", "SC5DIST", "SC5TEMP", "SC5REST", "SC5FIDG",
  "SC7THAC", "SC7TCOM", "SC7OBEY", "SC7DIST", "SC7TEMP", "SC7REST", "SC7FIDG",
  "SC11THAC", "SC11TCOM", "SC11OBEY", "SC11DIST", "SC11TEMP", "SC11REST", "SC11FIDG",
  "SC14THAC", "SC14TCOM", "SC14OBEY", "SC14DIST", "SC14TEMP", "SC14REST", "SC14FIDG",
  "SC17THAC", "SC17TCOM", "SC17OBEY", "SC17DIST", "SC17TEMP", "SC17REST", "SC17FIDG",
  "IGNORE3", "SMACK3", "SHOUT3", "BEDROOM3", "TREATS3", "TELLOFF3", "BRIBE3",
  "IGNORE5", "SMACK5", "SHOUT5", "BEDROOM5", "TREATS5", "TELLOFF5", "BRIBE5", "REASON5",
  "RINDOOR5", "DINNER5", "CLOSE5", "READ5", "STORY5", "MUSIC5", "PAINT5", "ACTIVE5", "GAMES5", "PARK5",
  "IGNORE7", "SMACK7", "SHOUT7", "BEDROOM7", "TREATS7", "TELLOFF7", "BRIBE7", "REASON7",
  "RINDOOR7", "DINNER7", "CLOSE7", "READ7", "STORY7", "MUSIC7", "PAINT7", "ACTIVE7", "GAMES7", "PARK7", "TVRULES7",
  "BEDROOM11", "TREATS11", "REASON11", "CLOSE11", "ACTIVE11", "GAMES11",
  "PWHERE14", "PWHO14", "PWHAT14", "CMWHERE14", "CMWHO14", "CMWHAT14",
  "CMWHERE17", "CMTBACK17", "PWHERE17", "PTBACK17", "LIVEWP17",
  "PEDU", "BPEDU", "SEX", "RACE", "BRACE", "BMARRIED", "INCOMEC", "INCOMEL", "INCOMEF", "LBW",
  "NAMHAPNA", "NAMUNFAA", "NAMBRUSA", "NAMFEEDA", "NAMINJUA", "NAMBATHA", "NAMWARYA",
  "NAMBSHYA", "NAMFRETA", "NAMSLEEA", "NAMMILKA", "NAMSLTIA", "NAMNAPSA", "NAMSOFOA",
  "INFTEMPR", "INFTEMP", "DFPW", "DUPD", "DUPW", "HFAE", "COGA", "SCOGA", "AGE3",
  "AGE5", "AGE7", "AGE11", "AGE14", "AGE17",
  "SC_3", "SC_3_SE", "SC_5", "SC_5_SE", "SC_7", "SC_7_SE", "SC_11", "SC_11_SE",
  "SC_14", "SC_14_SE", "SC_17", "SC_17_SE",
  "GOVWT1", "MCSID", "PTTYPE2", "SPTN00"
)

# Define column names for Parenting_FS_all.dat
pa_colnames <- c(
  "IGNORE3", "SMACK3", "SHOUT3", "BEDROOM3", "TREATS3", "TELLOFF3", "BRIBE3",
  "IGNORE5", "SMACK5", "SHOUT5", "BEDROOM5", "TREATS5", "TELLOFF5", "BRIBE5", "REASON5",
  "IGNORE7", "SMACK7", "SHOUT7", "BEDROOM7", "TREATS7", "TELLOFF7", "BRIBE7", "REASON7",
  "BEDROOM11", "TREATS11", "REASON11",
  "PWHERE14", "PWHO14", "PWHAT14", "CMWHERE14", "CMWHO14", "CMWHAT14",
  "PWHERE17", "CMWHERE17", "PTBACK17", "CMTBACK17",
  "H3", "H3_SE", "H5", "H5_SE", "H7", "H7_SE", "H11", "H11_SE",
  "MON14", "MON14_SE", "MON17_K", "MON17_K_SE", "CURFEW17", "CURFEW17_SE",
  "GOVWT1", "MCSID", "PTTYPE2", "SPTN00"
)

# Read the self-control complete data
cat("Reading sc_wave_fscores_complete.dat...\n")
sc_data <- read.table("/home/siyang/dissertation/sc_wave_fscores_complete.dat", 
                      header = FALSE,
                      col.names = sc_colnames,
                      na.strings = "*",
                      stringsAsFactors = FALSE)

# Read the parenting data
cat("Reading Parenting_FS_all.dat...\n")
pa_data <- read.table("Parenting_FS_all.dat", 
                      header = FALSE,
                      col.names = pa_colnames,
                      na.strings = "*",
                      stringsAsFactors = FALSE)

# Check dimensions
cat("\nDimensions of sc_wave_fscores_complete.dat:", dim(sc_data), "\n")
cat("Dimensions of Parenting_FS_all.dat:", dim(pa_data), "\n")

# Remove cases with missing values in key Mplus design variables
# These are critical for complex survey design analysis
cat("\nRemoving cases with missing values in key design variables...\n")

# Check for missing values before filtering
cat("Missing in sc_data - GOVWT1:", sum(is.na(sc_data$GOVWT1)), 
    ", MCSID:", sum(is.na(sc_data$MCSID)),
    ", PTTYPE2:", sum(is.na(sc_data$PTTYPE2)),
    ", SPTN00:", sum(is.na(sc_data$SPTN00)), "\n")

cat("Missing in pa_data - GOVWT1:", sum(is.na(pa_data$GOVWT1)), 
    ", MCSID:", sum(is.na(pa_data$MCSID)),
    ", PTTYPE2:", sum(is.na(pa_data$PTTYPE2)),
    ", SPTN00:", sum(is.na(pa_data$SPTN00)), "\n")

# Filter out cases with missing design variables
sc_data_clean <- sc_data[!is.na(sc_data$GOVWT1) & 
                         !is.na(sc_data$MCSID) & 
                         !is.na(sc_data$PTTYPE2) & 
                         !is.na(sc_data$SPTN00), ]

pa_data_clean <- pa_data[!is.na(pa_data$GOVWT1) & 
                         !is.na(pa_data$MCSID) & 
                         !is.na(pa_data$PTTYPE2) & 
                         !is.na(pa_data$SPTN00), ]

cat("After removing missing design variables:\n")
cat("  sc_wave_fscores_complete.dat:", nrow(sc_data_clean), 
    "cases (removed", nrow(sc_data) - nrow(sc_data_clean), ")\n")
cat("  Parenting_FS_all.dat:", nrow(pa_data_clean), 
    "cases (removed", nrow(pa_data) - nrow(pa_data_clean), ")\n")

# Merge datasets by common ID variables
# The key ID variable is MCSID (Millennium Cohort Study ID)
# Other variables (GOVWT1, PTTYPE2, SPTN00) are also present in both datasets
cat("\nMerging datasets by MCSID...\n")

merged_data <- merge(sc_data_clean, pa_data_clean, 
                     by = c("MCSID"),
                     all = FALSE,  # inner join - only keep matching cases
                     suffixes = c(".sc", ".pa"))

# Check merged dimensions before dropping duplicates
cat("Dimensions of merged dataset (before dropping duplicates):", dim(merged_data), "\n")

# Identify and drop duplicate columns
# Keep the .sc versions (from sc_wave_fscores_complete.dat), drop the .pa versions
duplicate_vars_pa <- grep("\\.pa$", names(merged_data), value = TRUE)
cat("Number of duplicate columns to drop:", length(duplicate_vars_pa), "\n")
cat("Duplicate columns:", paste(duplicate_vars_pa, collapse = ", "), "\n\n")

# Drop the .pa versions
merged_data <- merged_data[, !(names(merged_data) %in% duplicate_vars_pa)]

# Rename the .sc versions back to original names (remove .sc suffix)
sc_suffixed <- grep("\\.sc$", names(merged_data), value = TRUE)
for (var in sc_suffixed) {
  original_name <- sub("\\.sc$", "", var)
  names(merged_data)[names(merged_data) == var] <- original_name
}

cat("Dimensions of merged dataset (after dropping duplicates):", dim(merged_data), "\n")
cat("Number of cases successfully merged:", nrow(merged_data), "\n")

# Calculate and report cases lost during merge
cat("\n=== MERGE DIAGNOSTICS ===\n")
cat("Original cases in sc_wave_fscores_complete.dat:", nrow(sc_data), "\n")
cat("Original cases in Parenting_FS_all.dat:", nrow(pa_data), "\n")
cat("Cases after filtering for complete design variables:\n")
cat("  sc_wave_fscores_complete.dat:", nrow(sc_data_clean), "\n")
cat("  Parenting_FS_all.dat:", nrow(pa_data_clean), "\n")
cat("Cases in final merged dataset:", nrow(merged_data), "\n")
cat("\nTotal cases lost from original sc_wave_fscores_complete.dat:", 
    nrow(sc_data) - nrow(merged_data), 
    "(", round((nrow(sc_data) - nrow(merged_data)) / nrow(sc_data) * 100, 2), "%)\n")
cat("Total cases lost from original Parenting_FS_all.dat:", 
    nrow(pa_data) - nrow(merged_data), 
    "(", round((nrow(pa_data) - nrow(merged_data)) / nrow(pa_data) * 100, 2), "%)\n")

# Identify which MCSIDs are in cleaned datasets but not in merged
sc_only <- setdiff(sc_data_clean$MCSID, merged_data$MCSID)
pa_only <- setdiff(pa_data_clean$MCSID, merged_data$MCSID)
cat("\nAfter filtering, MCSIDs only in sc (not in parenting):", length(sc_only), "\n")
cat("After filtering, MCSIDs only in parenting (not in sc):", length(pa_only), "\n")

# Reorder columns: put ID variables at the end (Mplus convention)
# First get all variable names except the merge keys
other_vars <- setdiff(names(merged_data), c("MCSID", "GOVWT1", "PTTYPE2", "SPTN00"))

# Reorder so ID variables are at the end
merged_data <- merged_data[, c(other_vars, "GOVWT1", "MCSID", "PTTYPE2", "SPTN00")]

# Save merged dataset for Mplus
output_file <- "merged_sc_pa_fscores.dat"
cat("\nSaving merged dataset to", output_file, "...\n")

write.table(merged_data,
            file = output_file,
            row.names = FALSE,
            col.names = FALSE,  # Mplus doesn't use column headers in .dat files
            sep = " ",          # Space-delimited
            na = "*",           # Use asterisk for missing values (Mplus convention)
            quote = FALSE)

# Also save variable names to a separate text file for reference
varnames_file <- "merged_sc_pa_fscores_varnames.txt"
cat("Saving variable names to", varnames_file, "...\n")
writeLines(names(merged_data), varnames_file)

# Verify no missing values in key design variables
cat("\n=== VERIFICATION ===\n")
cat("Checking for missing values in key design variables in final dataset:\n")
cat("  GOVWT1:", sum(is.na(merged_data$GOVWT1)), "missing\n")
cat("  MCSID:", sum(is.na(merged_data$MCSID)), "missing\n")
cat("  PTTYPE2:", sum(is.na(merged_data$PTTYPE2)), "missing\n")
cat("  SPTN00:", sum(is.na(merged_data$SPTN00)), "missing\n")

if(sum(is.na(merged_data$GOVWT1)) + sum(is.na(merged_data$MCSID)) + 
   sum(is.na(merged_data$PTTYPE2)) + sum(is.na(merged_data$SPTN00)) == 0) {
  cat("✓ All key design variables are complete - ready for Mplus!\n")
} else {
  cat("✗ WARNING: Some design variables still have missing values!\n")
}

# Print summary
cat("\n=== MERGE COMPLETED SUCCESSFULLY ===\n")
cat("Output file:", output_file, "\n")
cat("Variable names file:", varnames_file, "\n")
cat("Total variables:", ncol(merged_data), "\n")
cat("Total observations:", nrow(merged_data), "\n")
cat("\nFirst few variable names:\n")
print(head(names(merged_data), 20))
cat("\nLast few variable names:\n")
print(tail(names(merged_data), 10))

