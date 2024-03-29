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
source("../utils/utils.R")
# the file with the extracted 'real' analysis function
source("analysis.R")

PROJECT_NAME <- "VHF"

#########################
# Directories and Files #
#########################

# Directory for intermediate results / debug
OUTPUT_DIR_LOCAL <- paste0(OUTPUT_DIR_BASE, "/outputLocal/", PROJECT_NAME)
# Directory for final results
OUTPUT_DIR_GLOBAL <- paste0(OUTPUT_DIR_BASE, "/outputGlobal/", PROJECT_NAME)
retrieve_dir = ifelse(DECENTRAL_ANALYSIS, OUTPUT_DIR_LOCAL, OUTPUT_DIR_GLOBAL)

# Result files from retrieve -> here the input files
retrieve_file_cohort <- paste0(retrieve_dir, "/Cohort.csv")
retrieve_file_diagnoses <- paste0(retrieve_dir, "/Diagnoses.csv")

analysis_file_log <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis.log")

# Result files base names
analysis_file_plot_basename <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis-Plot")
analysis_file_text_basename <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis")
results_file_baseName <- paste0(retrieve_dir, "/Retrieve")

# files needed in data-quality/report.Rmd
output_local_errors <- paste0(OUTPUT_DIR_LOCAL, "/Errors")
error_file <- paste0(output_local_errors, "/ErrorMessage.txt")
data_quality_report_file <- paste0(OUTPUT_DIR_GLOBAL, "/DQ-Report.html")

# Backs up the OUTPUT_DIR_GLOBAL. On Central Analysis we must copy the
# old content to preserve the Retrieval results in this directory
if (file.exists(analysis_file_log)) {
  createDirWithBackup(OUTPUT_DIR_GLOBAL, copy = TRUE)
} else {
  createDirsRecursive(OUTPUT_DIR_GLOBAL)
}


################
# Log Function #
################

#'
#' Logs the given arguments via cat() and message()
#'
log <- function(...) {
  logText <- paste0(...)
  cat(logText)
  message(logText)
}

#'
#' Logs the given arguments to the global log file and via message()
#'
logGlobal <- function(..., append = TRUE) {
  logText <- paste0(...)
  write(logText, file = analysis_file_log, append = append)
  message(logText)
}

#######################
# File Name Functions #
#######################

#'
#' @param baseNameSuffix a string that will be appended to the
#' analysis_file_plot_basename
#' @return the full name of an analysis plot file inclusive the suffix
#'
getAnalysisPlotFileName <- function(baseNameSuffix) {
  paste0(analysis_file_plot_basename, baseNameSuffix, ".pdf")
}

#'
#' @param baseNameSuffix a string that will be appended to the
#' analysis_file_text_basename.
#' @return the full name of an analysis text file inclusive the suffix
#'
getAnalysisTextFileName <- function(baseNameSuffix) {
  paste0(analysis_file_text_basename, baseNameSuffix, ".txt")
}

#'
#' @param baseNameSuffix a string that will be appended to the
#' results_file_baseName.
#' @param hasNoComparator if TRUE then the suffix will be extended
#' by "_noComparator" at the beginning.
#' @return the full name of an results file inclusive the suffix
#'
getResultsFileName <- function(baseNameSuffix, hasComparator) {
  if (!hasComparator) baseNameSuffix <- paste0("_noComparator", baseNameSuffix)
  paste0(results_file_baseName, baseNameSuffix, ".csv")
}

###########################
# Simple Filter Functions #
###########################
# All these reatain()/remove() functions remove Observation rows from a table
# regarding a special value of one column.

retainMales <- function(table) {
  return(table[gender == "male"])
}

retainFemales <- function(table) {
  return(table[gender == "female"])
}

retainAge <- function(table, inclusiveMinAge, exclusiveMaxAge = Inf) {
  table[age >= inclusiveMinAge & age < exclusiveMaxAge]
}

removeMyocardialInfarction <- function(table) {
  return(table[MyocardialInfarction != 1])
}

removeStroke <- function(table) {
  return(table[Stroke != 1])
}

removeHeartFailure <- function(table) {
  return(table[HeartFailure != 1])
}

#######################################################
# Functions for all subanalyses for a specific cohort #
#######################################################

#'
#' @param cohort
#' @return List of one or two strings. First option string describes the
#' run option with all values inclusive comparator values and the second
#' option describes the run option without values with a comparator. The
#' second option indicates that the cohort is filtered.
#'
getComparatorOptions <- function(cohort) {
  if (nrow(cohort) > 0) {
    # check the data if there are values with and/or without comparators
    comparators <- unique(cohort$NTproBNP.valueQuantity.comparator)
    comparatorsCount <- length(comparators)
    hasExactValues <- anyNA(comparators)
    hasComparators <- comparatorsCount > 1 || !hasExactValues
    if (comparatorsCount == 1) {
      if (hasComparators) { # the only value is a comparator
        comparatorOptions <- c(paste0("all NTproBNP values have the same comparator ", comparators[1]))
      } else { # the only value is N.A. -> means there are no comparators
        comparatorOptions <- c("all NTproBNP values have no comparator")
      }
    } else if (hasComparators && !hasExactValues) { # there are only values with different comparators
      comparatorOptions <- c(paste0("all NTproBNP values have a comparator of ", paste(comparators, collapse = ', ')))
    } else { # there are values with and values witthout a comparator -> the only case with 2 run options
      comparatorOptions <- c("incl. comparator values", "excl. comparator values")
    }
  } else {
    comparatorOptions <- c("Cohort is empty")
  }
  return(comparatorOptions)
}

#'
#' @param cohort the cohort with NTproBNP values which can have comparators
#' @return String of a table with all unique values with comparators and
#' its frequencies in this cohort
#'
getComparatorFrequenciesText <- function(cohort) {

  comparatorFrequencies <- ""
  value <- cohort$NTproBNP.valueQuantity.value
  comparator <- cohort$NTproBNP.valueQuantity.comparator

  # we must restore the original values here
  value <-
    ifelse(is.na(comparator), value, ifelse(comparator == ">", value - 1, ifelse(comparator == "<", value + 1, value)))

  # construct a string with the frequencies for all unique comparator values
  comparatorFrequencies <- paste(comparator, value) # paste every value and its comparator in one string
  comparatorFrequencies <- comparatorFrequencies[!startsWith(comparatorFrequencies, 'NA')] # remove values without comparator
  if (length(comparatorFrequencies) > 0) {
    comparatorFrequencies <- sort(comparatorFrequencies) # sort the values with comparator alphabetical
    comparatorFrequencies <- capture.output(table(comparatorFrequencies)) # create frequencies string for the logging file
    comparatorFrequencies[1] <- "Comparator Frequencies:" # replace the first line with the variable name by a better one
  }
  comparatorFrequencies <- paste(comparatorFrequencies, collapse = "\n")
  return(comparatorFrequencies)
}

###############
# Unify Units #
###############

#'
#' Unify units in cohort.
#'
#' @param cohort the conhort with maybe different units for NTproNP
#' @return cohort with unified units and removed observations, if they have
#' an invalid unit
#'
unifyUnits <- function(cohort) {

  # Some DIZ write the SI unit not in the "valueQuantity/code" which was imported
  # in the field "NTproBNP.unit" but in the "valueQuantity/unit" which was
  # imported in the "NTproBNP.unitLabel". This label should only be used in FHIR
  # as a human readable unit description. So we fix this error here.
  # It is not clear why the else case does not work when all values are NA and
  # so we need the if case :(
  if (all(is.na(cohort$NTproBNP.unit))) { # all unit values are NA -> copy the full unitLabel column to unit
    cohort[, NTproBNP.unit := NTproBNP.unitLabel]
  } else { # some unit vales are NA -> replace the NA values in unit by unitLabel
    cohort[is.na(NTproBNP.unit), NTproBNP.unit := NTproBNP.unitLabel]
  }
  # remove all rows where the NTproBNP.unit is still NA
  cohort <- cohort[!is.na(NTproBNP.unit)]

  # All valid NTproBNP units taken from http://www.unitslab.com/node/163
  # All units are checked case insensitive, so for example the correct
  # UCUM unit "pg/mL" includes the invalid unit "pg/ml".
  # The first value describes the code and the number value the conversion
  # factor regarding the reference value in the first line of the table.
  # If necessary then append other (invalid) units at the end of the list.
  units <- c(
    "pg/mL", 1, # Reference Unit as first value. Must always have conversion value 1.
    "ng/L", 1,
    "pg/dL", 100,
    "pg/100mL", 100,
    "pg%", 100,
    "pg/L", 1000,
    "pmol/L", 0.1182
  )
  # extract unit strings and conversion factors from the table list
  units <- matrix(units, length(units) / 2, 2, byrow = TRUE)
  unitNames <- units[, 1]
  unitFactors <- as.numeric(units[, 2])

  # remove data rows with invalid units
  unitsPattern <- paste(unitNames, collapse = "|")
  cohort <- cohort[
    grepl(unitsPattern, NTproBNP.unit, ignore.case = TRUE)
  ]

  # now really unify
  for (i in 2 : length(unitNames)) {
    # Convert value
    cohort[
      tolower(NTproBNP.unit) == tolower(unitNames[i]),
      NTproBNP.valueQuantity.value := NTproBNP.valueQuantity.value * unitFactors[i]
    ]
    # Convert unit
    cohort[
      tolower(NTproBNP.unit) == tolower(unitNames[i]),
      NTproBNP.unit := unitNames[1]
    ]
  }

  # overwrite the unit label with the unified one
  cohort[, NTproBNP.unitLabel := "picogram per milliliter"]

  return(cohort)
}

#'
#' Builds the merged result table from the input tables.
#'
#' @param cohort the (sub)cohort table that should be analyzed
#' @param conditions the conditions table from he retrieval (should be unchanged)
#'
#' @return the cohort table merged with the diagnoses table
#'
mergeRetrievalResults <- function(cohort, conditions) {

    result <- cohort[, .(
    subject,
    # fill the date (=timestamp) column with the timestamp of the max NTproBNP
    # value for every encounter. If there is more than 1 maximum value, then take
    # the lowest (min) date
    age = min(age[NTproBNP.valueQuantity.value == max(NTproBNP.valueQuantity.value)]),
    # fill the NTproBNP value for every encounter with the maximum value
    NTproBNP.valueQuantity.value = max(NTproBNP.valueQuantity.value),
    NTproBNP.unit,
    gender
  ), by = encounter.id]

  # remove equal columns which are now present if there were multiple NTproBNP
  # values for the same encounter with different timestamps (now these NTproBNP
  # values have all the same timestamp and so the whole row is equals)
  result <- unique(result)

  # for each encounter, extract the Boolean information whether certain diagnoses
  # were present
  conditionsReduced <- conditions[, .(
    AtrialFibrillation = as.numeric(any(grepl("I48.0|I48.1|I48.2|I48.9", code))),
    MyocardialInfarction = as.numeric(any(grepl("I21|I22|I25.2", code))),
    HeartFailure = as.numeric(any(grepl("I50", code))),
    Stroke = as.numeric(any(grepl("I60|I61|I62|I63|I64|I69", code)))
  ), by = encounter.id]

  # merge the result encounters with the diagnoses information
  result <- merge.data.table(
    x = result,
    y = conditionsReduced,
    by = "encounter.id",
    all.x = TRUE
  )

  # fill missing diagnosis values with 0
  result[is.na(AtrialFibrillation), AtrialFibrillation := 0]
  result[is.na(MyocardialInfarction), MyocardialInfarction := 0]
  result[is.na(HeartFailure), HeartFailure := 0]
  result[is.na(Stroke), Stroke := 0]

  # bring the subject column to the front again
  setcolorder(result, neworder = "subject")

  return(result)
}

#'
#' Runs all analysis options for a (sub)cohort.
#'
#' @param result the data table
#' @param cohortDescription String with a description of the current cohort in
#' the result table (e.g. "Full cohort", "Males", "Females, Age > 50", ' ...)
#' @param comparatorOptionDisplay String that describes the data regarding
#' containing NTproBNP values with or without comparators
#' @param comparatorFrequenciesText String of a table with all unique values with
#' comparators and its frequencies in this analysis
#' @param removedObservationsCount number of NTproBNP values removed with comparator
#'
cohortAnalysis <- function(result, cohortDescription, comparatorOptionDisplay, comparatorFrequenciesText, removedObservationsCount) {

  analysisOption <- "AtrialFibrillation"
  analysisOptionDisplay <- "Atrial Fibrillation incl. all other diagnoses"
  analyze(result, cohortDescription, analysisOption, analysisOptionDisplay, comparatorOptionDisplay, comparatorFrequenciesText, removedObservationsCount)

  analysisOption <- "HeartFailure"
  analysisOptionDisplay <- "Heart Failure incl. all other diagnoses"
  analyze(result, cohortDescription, analysisOption, analysisOptionDisplay, comparatorOptionDisplay, comparatorFrequenciesText, removedObservationsCount)

  result <- removeMyocardialInfarction(result)
  result <- removeStroke(result)

  analysisOption <- "AtrialFibrillation"
  analysisOptionDisplay <- "Atrial Fibrillation incl. Heart Failure, excl. Myocardial Infarction and Stroke"
  analyze(result, cohortDescription, analysisOption, analysisOptionDisplay, comparatorOptionDisplay, comparatorFrequenciesText, removedObservationsCount)

  analysisOption <- "HeartFailure"
  analysisOptionDisplay <- "Heart Failure incl. Atrial Fibrillation, excl. Myocardial Infarction and Stroke"
  analyze(result, cohortDescription, analysisOption, analysisOptionDisplay, comparatorOptionDisplay, comparatorFrequenciesText, removedObservationsCount)

  result <- removeHeartFailure(result)

  analysisOption <- "AtrialFibrillation"
  analysisOptionDisplay <- "Atrial Fibrillation excl. Myocardial Infarction, Stroke and Heart Failure"
  analyze(result, cohortDescription, analysisOption, analysisOptionDisplay, comparatorOptionDisplay, comparatorFrequenciesText, removedObservationsCount)
}

#'
#' Starts the cohortAnalysis for every cohort option (with or without comparator values)
#'
#' @param cohort the cohort table
#' @param conditions the conditions table
#' @param cohortDescription String with a description of the current cohort in
#' the result table (e.g. "Full cohort", "Males", "Females, Age > 50", ' ...)
#' @param resultsFileNameSuffix suffix for the result table csv file that will be written
#' in DEBUG mode
#'
analyzeCohort <- function(cohort, conditions, cohortDescription, resultsFileNameSuffix) {

  comparatorOptions <- getComparatorOptions(cohort)

  # run the same analysis with the first run option with all values and with
  # a possibly existing second run option without all values with comparators

  for (comparatorOption in comparatorOptions) {

    isFirstOption <- comparatorOption == comparatorOptions[1]

    comparatorFrequenciesText <- ifelse(isFirstOption, getComparatorFrequenciesText(cohort), "")

    sizeBeforeRemove <- nrow(cohort)
    # remove columns with comparator if they should be exluded
    if (!isFirstOption) { # the 1. run option is with all values and the 2. with filtered
      cohort <- cohort[is.na(NTproBNP.valueQuantity.comparator)]
    }
    removedObservationsCount <- sizeBeforeRemove - nrow(cohort)

    result <- mergeRetrievalResults(cohort, conditions)

    # Debug? -> Write result table as csv to localOutput
    #           (full data or without comparator values)
    if (DEBUG) {
      resultsFileName <- getResultsFileName(resultsFileNameSuffix, isFirstOption)
      write.csv2(result, resultsFileName, row.names = FALSE)
    }
    cohortAnalysis(result, cohortDescription, comparatorOption, comparatorFrequenciesText, removedObservationsCount)
  }
}

#'
#' Frame around the analysis function which opens and closes the result text and plot file.
#'
#' @param cohort the cohort table
#' @param conditions the conditions table
#' @param cohortDescription String with a description of the current cohort in
#' the result table (e.g. "Full cohort", "Males", "Females, Age > 50", ' ...)
#' @param cohortFileNameSuffix suffix for all result files for the specific cohort
#'
writeCohortAnalysisFiles <- function(cohort, conditions, cohortDescription, cohortFileNameSuffix) {

  analysisPlotFileName <- getAnalysisPlotFileName(cohortFileNameSuffix)
  analysisTextFileName <- getAnalysisTextFileName(cohortFileNameSuffix)

  # create pdf plot file and results text file
  pdf(analysisPlotFileName)
  sink(analysisTextFileName)

  start <- Sys.time()
  logGlobal("Start Cohort Analysis: ", start)
  logGlobal("Cohort: ", cohortDescription)
  analyzeCohort(cohort, conditions, cohortDescription, cohortFileNameSuffix)
  end <- Sys.time()
  runtime <- end - start
  logGlobal("Finished Analysis: ", end, " -> Duration: ", round(runtime, 2), " ", attr(runtime, "units"),  "\n")

  sink()
  dev.off()
  closeAllConnections()
}

#'
#' Loads the condition table and removes invalid(ated) conditions.
#'
loadAndCleanDiagnoses <- function() {
  conditions <- fread(retrieve_file_diagnoses)
  # Clean diagnoses table from invalid(ated) Conditions
  allConditionsCount <- nrow(conditions)
  # remove invalid(ated) diagnoses
  # https://www.hl7.org/fhir/codesystem-condition-clinical.html#condition-clinical-inactive
  conditions <- conditions[!(clinicalStatus.code  %in%  c("inactive", "remission", "resolved"))]
  removedByClinicalStatusConditionsCount <- allConditionsCount - nrow(conditions)
  # https://www.hl7.org/fhir/valueset-condition-ver-status.html
  conditions <- conditions[!(verificationStatus.code  %in%  c("refuted", "entered-in-error"))]
  removedByVerificationStatusConditionsCount <- allConditionsCount - removedByClinicalStatusConditionsCount - nrow(conditions)
  removedConditionsCount <- removedByClinicalStatusConditionsCount + removedByVerificationStatusConditionsCount
  if (removedConditionsCount > 0) {
    logGlobal("Removed Observations:")
    logGlobal("     1. with clinical status 'inactive', 'remission' or 'resolved': ", removedByClinicalStatusConditionsCount)
    logGlobal("        (see https://www.hl7.org/fhir/codesystem-condition-clinical.html#condition-clinical-inactive)")
    logGlobal("     2. with verification status 'refuted' or 'entered-in-error': ", removedByVerificationStatusConditionsCount)
    logGlobal("        (see https://www.hl7.org/fhir/valueset-condition-ver-status.html)")
    logGlobal("Remaining Observations ", nrow(conditions) ," of ",  allConditionsCount, " (removed ", removedConditionsCount, ")\n")
  }
  return (conditions)
}

########
# MAIN #
########
# first log -> delete old log content with append = FALSE
logGlobal("Start Analysis at ", start, "\n", append = FALSE)
# log loaded package versions
logGlobal("SessionInfo:")
logGlobal(capture.output(sessionInfo()))

#################################
# Start the Data Quality Report #
#################################
if (DATA_QUALITY_REPORT) {
  startDQ <- Sys.time()
  tryCatch(                       # Applying tryCatch
    rmarkdown::render(
      "data-quality/report.Rmd",
      output_format = "html_document",
      output_file = data_quality_report_file,
      output_dir = OUTPUT_DIR_GLOBAL,
      intermediates_dir = OUTPUT_DIR_LOCAL
    ),
    error = function(e) {         # Specifying error message
      logGlobal("An error occurs in Data Quality Report:")
      logGlobal(e)
    }
  )
  runtimeDQ <- Sys.time() - startDQ
  logGlobal("data-quality/report.Rmd finished at ", Sys.time(), ".")
  logGlobal("Rmd script execution took ", round(runtimeDQ, 2), " ", attr(runtimeDQ, "units"), ".\n")
}

####################################
# Load and Clean Retrieval Results #
####################################

################
# Cohort Table #
################
fullCohort <- fread(retrieve_file_cohort)

fullCohortCountUncleaned <- nrow(fullCohort)

# remove NA values
removedNACount <- nrow(fullCohort)
fullCohort <- fullCohort[!is.na(NTproBNP.valueQuantity.value)]
removedNACount <- removedNACount - nrow(fullCohort)

# Replace all values by value + 1 if the comparator
# is ">" or with value - 1 if the comparator is "<".
value <- fullCohort$NTproBNP.valueQuantity.value
comparator <- fullCohort$NTproBNP.valueQuantity.comparator
# You must check N.A. seperately in R!? It is not covered by the very
# last else case :(
fullCohort$NTproBNP.valueQuantity.value <-
  ifelse(is.na(comparator), value, ifelse(comparator == ">", value + 1, ifelse(comparator == "<", value - 1, value)))

# remove values < 0
removedLowerZeroCount <- nrow(fullCohort)
fullCohort <- fullCohort[NTproBNP.valueQuantity.value >= 0]
removedLowerZeroCount <- removedLowerZeroCount - nrow(fullCohort)

# unify the NTproBNP value units
fullCohort <- unifyUnits(fullCohort)

# check NTproBNP value is in valid range (but count and log only)
# values > 0 and < 1
lowerOneCount <- length(which(fullCohort$NTproBNP.valueQuantity.value < 1))

fullCohortCountCleaned <- nrow(fullCohort)

# cuts to log how many value are above a cut value
valueCuts <- c(0 : 10) * 10000

logGlobal("Full Cohort NTProBNP values:")
logGlobal("    total before cleanup: ", fullCohortCountUncleaned)
logGlobal("                      NA: ", removedNACount, " (removed)")
logGlobal("                     < 0: ", removedLowerZeroCount, " (removed)")
logGlobal("                     < 1: ", lowerOneCount)
for (i in 1 : length(valueCuts)) {
  cut <- valueCuts[i]
  nextCut <- ifelse(i < length(valueCuts), valueCuts[i + 1], Inf)
  greaterCutCount <-
    length(which(fullCohort$NTproBNP.valueQuantity.value > cut & fullCohort$NTproBNP.valueQuantity.value <= nextCut))
  cut <- paste0("> ", cut, ": ")
  whitespaces <- "                          "
  whitespaces <- substring(whitespaces, 1, nchar(whitespaces) - nchar(cut))
  logGlobal(whitespaces, cut, greaterCutCount)
}
logGlobal("     total after cleanup: ", fullCohortCountCleaned, "\n")

###################
# Diagnoses Table #
###################
conditions <- loadAndCleanDiagnoses()

#############################################
# Create subcohorts from cohort and analyze #
#############################################

# 1 cohort = all
writeCohortAnalysisFiles(fullCohort, conditions, "Full Cohort", "_01_FullCohort")

# 2 cohort = male
writeCohortAnalysisFiles(retainMales(fullCohort), conditions, "Males", "_02_Males")
# 3 cohort = female
writeCohortAnalysisFiles(retainFemales(fullCohort), conditions, "Females", "_03_Females")

# 4 cohort = 18 <= age <= 50
writeCohortAnalysisFiles(retainAge(fullCohort, 18,51), conditions, "18 <= Age <= 50", "_04_Age_18_50")
# 5 cohort = 51 <= age <= 80
writeCohortAnalysisFiles(retainAge(fullCohort, 51, 81), conditions, "51 <= Age <= 80", "_05_Age_51_80")
# 6 cohort = age > 80
writeCohortAnalysisFiles(retainAge(fullCohort, 81), conditions, "Age > 80", "_06_Age_81_Inf")

# 7 cohort = male 18 <= age <= 50
writeCohortAnalysisFiles(retainMales(retainAge(fullCohort, 18, 51)), conditions, "Males, 18 <= Age <= 50", "_07_Males_Age_18_50")
# 8 cohort = male 51 <= age <= 80
writeCohortAnalysisFiles(retainMales(retainAge(fullCohort, 51, 81)), conditions, "Males, 51 <= Age <= 80", "_08_Males_Age_51_80")
# 9 cohort = male age > 80
writeCohortAnalysisFiles(retainMales(retainAge(fullCohort, 81)), conditions, "Males, Age > 80", "_09_Males_Age_81_Inf")

# 10 cohort = female 18 <= age <= 50
writeCohortAnalysisFiles(retainFemales(retainAge(fullCohort, 18, 51)), conditions, "Females, 18 <= Age <= 50", "_10_Females_Age_18_50")
# 11 cohort = female 51 <= age <= 80
writeCohortAnalysisFiles(retainFemales(retainAge(fullCohort, 51, 81)), conditions, "Females, 51 <= Age <= 80", "_11_Females_Age_51_80")
# 12 cohort = female age > 80
writeCohortAnalysisFiles(retainFemales(retainAge(fullCohort, 81)), conditions, "Females, Age > 80", "_12_Females_Age_81_Inf")

runtime <- Sys.time() - start
logGlobal("main.R finished at ", Sys.time(), ".")
logGlobal("R script execution took ", round(runtime, 2), " ", attr(runtime, "units"), ".")
