############################################################
# Note for manual execution: Working Directory must be the #
#                            directory of this Script!     #
############################################################

log <- function(...) {
  logText <- paste0(...)
  cat(logText)
  message(logText)
}

###############
# Preparation #
###############

start <- Sys.time()

# load/install a packages
source("install-dependencies.R")

# source config
source("config.R")
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
retrieve_dir = ifelse(DECENTRAL_ANALYIS, OUTPUT_DIR_LOCAL, OUTPUT_DIR_GLOBAL)

# Result files from retrieve -> here the input files
retrieve_result_file_cohort <- paste0(retrieve_dir, "/Cohort.csv")
retrieve_result_file_diagnoses <- paste0(retrieve_dir, "/Diagnoses.csv")
# Result files
merged_retrieve_results_file <- paste0(retrieve_dir, "/Retrieve.csv")
merged_retrieve_results_file_filtered <- paste0(retrieve_dir, "/Retrieve_filtered.csv")
result_file_log <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis.log")
analysis_result_plot_file <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis-Plot.pdf")
analysis_result_text_file <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis.txt")

# files needed in data-quality/report.Rmd
output_local_errors <- paste0(OUTPUT_DIR_LOCAL, "/Errors")
error_file <- paste0(output_local_errors, "/ErrorMessage.txt")
data_quality_report_file <- paste0(OUTPUT_DIR_GLOBAL, "/DQ-Report.html")

###########################
# Simple Filter Functions #
###########################
# all this remove() functions remove Observation
# rows from the result table regarding a special
# value of one column

removeMyocardialInfarction <- function() {
  result <<- result[MyocardialInfarction != 1]
}

removeStroke <- function() {
  result <<- result[Stroke != 1]
}

removeHeartFailure <- function() {
  result <<- result[HeartFailure != 1]
}

#################################
# Start the Data Quality Report #
#################################

  # Runs the Data Quality Report
  if (DATA_QUALITY_REPORT) {
    rmarkdown::render("data-quality/report.Rmd", output_format = "html_document", output_file = data_quality_report_file)
  }

# create pdf plot file and results text file 
pdf(analysis_result_plot_file)
sink(analysis_result_text_file)

log("Start Analysis: ", start, "\n")

####################################
# Load and Clean Retrieval Results #
####################################

cohort <- fread(retrieve_result_file_cohort)
conditions <- fread(retrieve_result_file_diagnoses)

# check the data if there are values with and/or without comparators
comparators <- unique(cohort$NTproBNP.valueQuantity.comparator)
comparatorsCount <- length(comparators)
hasExactValues <- anyNA(comparators)
hasComparators <- comparatorsCount > 1 || !hasExactValues
if (comparatorsCount == 1) {
  if (hasComparators) { # the only value is a comparator
    comparatorOptions <- c(paste0("All NTproBNP values have the same comparator ", comparators[1]))
  } else { # the only value is N.A. -> means there are no comparators
    comparatorOptions <- c("All NTproBNP values have no comparator")
  }
} else if (hasComparators && !hasExactValues) { # there are only values with different comparators
  comparatorOptions <- c(paste0("All NTproBNP values have a comparator of ", paste(comparators, collapse = ', ')))
} else { # there are values with and values witthout a comparator -> the only case with 2 run options
  comparatorOptions <- c("Incl. Comparators", "Excl. Comparators")
}

comparatorFrequencies <- ""
if (hasComparators) {
  # store the orinal unmodified value and comparator columns
  value <- cohort$NTproBNP.valueQuantity.value
  comp <- cohort$NTproBNP.valueQuantity.comparator

  # construct a string with the frequencies for all unique comparator values
  comparatorFrequencies <- paste(comp, value) # paste every value and its comparator in one string
  comparatorFrequencies <- comparatorFrequencies[!startsWith(comparatorFrequencies, 'NA')] # remove values without comparator
  comparatorFrequencies <- sort(comparatorFrequencies) # sort the values with comparator alphabetical
  comparatorFrequencies <- capture.output(table(comparatorFrequencies)) # create frequencies string for the logging file
  comparatorFrequencies[1] <- "Comparator Frequencies:" # replace the first line with the variable name by a better one
}

# Replace all values by value + 1 if the comparator
# is ">" or with value - 1 if the comparator is "<".
# You must check N.A. seperately in R!? It is not 
# covered by the very last else case :(
cohort$NTproBNP.valueQuantity.value <- ifelse(is.na(comp), value, ifelse(comp == ">", value + 1, ifelse(comp == "<", value - 1, value)))

# run the same analysis with the first run option with all values and with
# a possibly existing second run option without all values with comparators

for (comparatorOption in comparatorOptions) {
  # Reload cohort file for the second run option because
  # the data were filtered during the first run.
  if (comparatorOption == comparatorOptions[2]) {
    cohort <- fread(retrieve_result_file_cohort)
  }

  # remove invalid data rows
  cohort <- cohort[
    !is.na(NTproBNP.valueQuantity.value) & # missing value -> invalid
      NTproBNP.valueQuantity.value >= 0      # NTproBNP value < 0 -> invalid
  ]

  sizeBeforeRemove <- nrow(cohort)
  # remove columns with comparator if they should be exluded
  if (comparatorOption != comparatorOptions[1]) { # the 1. run option is with all values and the 2. with filtered
    cohort <- cohort[is.na(NTproBNP.valueQuantity.comparator)]
  }
  removedObservationsCount <- sizeBeforeRemove - nrow(cohort)

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
  for (i in 2 : length(unitNames)) {
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
    # value for every encounter. If there is more than 1 maximum value, then take
    # the lowest (min) date
    NTproBNP.date = min(NTproBNP.date[NTproBNP.valueQuantity.value == max(NTproBNP.valueQuantity.value)]),
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

  # Debug? -> Write result table as csv to localOutput
  #           (full data or without comparator values)
  if (DEBUG) {
    fileName <- ifelse(comparatorOption == comparatorOptions[1], merged_retrieve_results_file, merged_retrieve_results_file_filtered)
    write.csv2(result, fileName, row.names = FALSE)
  }

  # calculate age by birthdate and NTproBNP date (after write result as file)
  result$NTproBNP.date <- as.POSIXct(result$NTproBNP.date, format = "%Y")
  result$birthdate <- as.POSIXct(result$birthdate, format = "%Y")
  result$age <- year(result$NTproBNP.date) - year(result$birthdate)
  
  analyze(result, "AtrialFibrillation", "Atrial Fibrillation with all other diagnoses", comparatorOption, removedObservationsCount)
  analyze(result, "HeartFailure", "Heart Failure with all other diagnoses", comparatorOption, removedObservationsCount)
  removeMyocardialInfarction()
  removeStroke()
  analyze(result, "AtrialFibrillation", "Atrial Fibrillation without Myocardial Infarction and Stroke", comparatorOption, removedObservationsCount)
  analyze(result, "HeartFailure", "Heart Failure without Myocardial Infarction and Stroke", comparatorOption, removedObservationsCount)
  removeHeartFailure()
  analyze(result, "AtrialFibrillation", "Atrial Fibrillation without Myocardial Infarction, Stroke and Heart Failure", comparatorOption, removedObservationsCount)

}

log("Finished Analysis: ", Sys.time(), "\n")

sink()
dev.off()
closeAllConnections()

