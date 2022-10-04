############################################################
# Note for manual execution: Working Directory must be the #
#                            directory of this Script!     #
############################################################


###############
# Preparation #
###############

start <- Sys.time()

# load/install a packages
source("install-dependencies.R")

# source config
source("config.R")

PROJECT_NAME <- "VHF"


#########################
# Directories and Files #
#########################

# Directory for intermediate results / debug
OUTPUT_DIR_LOCAL <- paste0(OUTPUT_DIR_BASE, "/outputLocal/", PROJECT_NAME)
# Directory for final results
OUTPUT_DIR_GLOBAL <- paste0(OUTPUT_DIR_BASE, "/outputGlobal/", PROJECT_NAME)
retrieve_dir = ifelse(DECENTRAL_ANALYIS, OUTPUT_DIR_LOCAL, OUTPUT_DIR_GLOBAL)

# Result files
retrieve_result_file_cohort <- paste0(OUTPUT_DIR_LOCAL, "/Kohorte.csv")
retrieve_result_file_diagnoses <- paste0(OUTPUT_DIR_LOCAL, "/Diagnosen.csv")
result_file_log <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis.log")
result_file_retrieve <- paste0(retrieve_dir, "/Retrieve.csv")
analysisResultPlotFile <- paste0(OUTPUT_DIR_GLOBAL, "/Analyis-Plot.pdf")
analysisResultTextFile <- paste0(OUTPUT_DIR_GLOBAL, "/Analyis.txt")
data_quality_report_file <- paste0(OUTPUT_DIR_GLOBAL, "/DQ-Report.html")

####################################
# Load and Clean Retrieval Results #
####################################

# Load retrieval result files
cohort <- fread(retrieve_result_file_cohort)
conditions <- fread(retrieve_result_file_diagnoses)

# remove invalid data rows
cohort <- cohort[
   is.na(NTproBNP.valueQuantity.comparator) & # has comparator -> invalid
  !is.na(NTproBNP.valueQuantity.value) &      # missing value -> invalid
   NTproBNP.valueQuantity.value >= 0          # ignore NTproBNP values < 0
]

# Some DIZ write the SI unit not in the "valueQuantity/code" which was imported
# in the field "NTproBNP.unit" but in the "valueQuantity/unit" which was
# imported in the "NTproBNP.unitLabel". This label should only be used in FHIR
# as a human readable unit description. So we fix this error here.
cohort[is.na(NTproBNP.unit), NTproBNP.unit := NTproBNP.unitLabel]

###############
# Unify Units #
###############

# all valid NTproBNP units taken from http://www.unitslab.com/node/163
units <- c(
  "pg/mL", 1, #(Reference Unit as first value)
  "ng/L", 1,
  "pg/dL", 100,
  "pg/100mL", 100,
  "pg%", 100,
  "pg/L", 1000,
  "pmol/L", 0.1182
)
units <- matrix(units, length(units) / 2, 2, byrow = TRUE)
unitNames <- units[, 1] 
unitFactors <- as.numeric(units[, 2]) 

# remove data rows with invalid units
unitsPattern <- paste(unitNames, collapse = "|")
cohort <- cohort[ 
  grepl(unitsPattern, NTproBNP.unit, ignore.case = TRUE)
]

# now really unify
for (i in 2:length(unitNames)) {
  # Convert value
  cohort[
    NTproBNP.unit == unitNames[i], 
    NTproBNP.valueQuantity.value := NTproBNP.valueQuantity.value * unitFactors[i]
  ]
  # Convert unit
  cohort[
    NTproBNP.unit == unitNames[i], 
    NTproBNP.unit := unitNames[1]
  ]
}


##########################
# Build the Result Table #
##########################

result <- cohort[, .(
  subject,
  # fill the date (=timestamp) column with the timestamp of the max NTproBNP
  # value for every encounter
  NTproBNP.date = NTproBNP.date[NTproBNP.valueQuantity.value == max(NTproBNP.valueQuantity.value)],
  # fill the NTproBNP value for every encounter with the maximum value
  NTproBNP.valueQuantity.value = max(NTproBNP.valueQuantity.value),
  NTproBNP.unit,
  birthdate,
  gender
), by = encounter.id]

# remove equal columns which are now present if there were multiple NTproBNP
# values for the same encounter with different timestamps (now these NTproBNP
# values have all the same timestamp and so the whole row is equals)
result <- unique(result)

# for each encounter, extract the Boolean information whether certain diagnoses
# were present
conditionsReduced <- conditions[, .(
  Vorhofflimmern = as.numeric(any(grepl("I48.0|I48.1|I48.2|I48.9", code))),
  Myokardinfarkt = as.numeric(any(grepl("I21|I22|I25.2", code))),
  Herzinsuffizienz = as.numeric(any(grepl("I50", code))),
  Schlaganfall = as.numeric(any(grepl("I60|I61|I62|I63|I64|I69", code)))
), by = encounter.id]

# merge the result encounters with the diagnoses information
result <- merge.data.table(
  x = result,
  y = conditionsReduced,
  by = "encounter.id",
  all.x = TRUE
)

# fill missing diagnosis values with 0
result[is.na(Vorhofflimmern), Vorhofflimmern := 0]
result[is.na(Myokardinfarkt), Myokardinfarkt := 0]
result[is.na(Herzinsuffizienz), Herzinsuffizienz := 0]
result[is.na(Schlaganfall), Schlaganfall := 0]

# bring the subject column to the front again
setcolorder(result, neworder = "subject")


# Write result files
if (DEBUG) {
  write.csv2(result, result_file_retrieve, row.names = FALSE)
}

# Runs the Data Quality Report
if (DATA_QUALITY_REPORT) {
  rmarkdown::render("data-quality/report.Rmd", output_format = "html_document", output_file = data_quality_report_file)
}

####################################
# Start Analysis from S. Zeynalova #
####################################

# create roc curve
# Explanation of the graph:
# Sens - Sensitivity
# Spec - Specificity
# PV+  - Percentage of false negatives for VHF among all test negatives
# PV- - Proportion of false positives among all test positives
pdf(analysisResultPlotFile)
roc <- ROC(test = result$NTproBNP.valueQuantity.value, stat = result$Vorhofflimmern, plot = "ROC", main = "NTproBNP(Gesamt)", AUC = TRUE)
dev.off()

sink(analysisResultTextFile)

cat("###########################\n")
cat("# Results of VHF Analysis #\n")
cat("###########################\n\n")

cat(paste0("Date: ", Sys.time(), "\n\n"))

cat(paste0("ROC Area Under Curve: "), roc$AUC, "\n\n")

# create different CUT points for NTproBNP
cuts <- c(500, 900, 1000, 1200, 2000)

cat("NtProBNP Threshold Values Analysis\n")
cat("----------------------------------\n\n")

for (k in c(1 : length(cuts))) {
  colName <- "NTproBNP.valueQuantity.value_cut"
  result[[colName]] <- ifelse(result$NTproBNP.valueQuantity.value < cuts[k], 0, 1)

  cat(paste0("Threshold Value: ", cuts[k], "\n"))

  CrossTable(result$Vorhofflimmern, 
             result[[colName]], 
             prop.c = TRUE, 
             digits = 2, 
             prop.chisq = FALSE, 
             format = "SPSS")
  
  table <- xtabs(~result[[colName]] + result$Vorhofflimmern)
  test <- rowSums(table)
  sick <- colSums(table)
  
  # sensitivity
  sensitivity <- table[2, 2] / sick[2]
  cat(paste0("Sensitivity: ", sensitivity, "\n"))
  
  # specifity
  specifity <- table[1, 1] / sick[1]
  cat(paste0("Specifity:   ", specifity, "\n"))
  
  # npw - the positive predictive value
  ppv <- table[2, 2] / test[2]
  cat(paste0("PV+:         ", ppv, "\n"))

  # npw - Der negativepredictive value
  npv <- table[1, 1] / test[1]
  cat(paste0("PV-:         ", npv, "\n\n\n"))
}

#Multivarite Analyse, VHF in Abhängigkeit von NTproBNP, adjustiert mit Alter und Geschlecht


result$NTproBNP.date <- as.POSIXct(result$NTproBNP.date, format = "%Y")
result$birthdate <- as.POSIXct(result$birthdate, format = "%Y")
result$age <- year(result$NTproBNP.date) - year(result$birthdate)

logit <- glm(Vorhofflimmern ~ NTproBNP.valueQuantity.value + age + gender,
             family = binomial,
             data = result
)

summary(logit)

sink()

