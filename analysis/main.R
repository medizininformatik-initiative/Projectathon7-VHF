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

# Result files from retrieve -> here the input files
retrieve_result_file_cohort <- paste0(retrieve_dir, "/Kohorte.csv")
retrieve_result_file_diagnoses <- paste0(retrieve_dir, "/Diagnosen.csv")
# Result files
merged_retrieve_results_file <- paste0(retrieve_dir, "/Retrieve.csv")
result_file_log <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis.log")
analysis_result_plot_file <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis-Plot.pdf")
analysis_result_text_file <- paste0(OUTPUT_DIR_GLOBAL, "/Analysis.txt")
data_quality_report_file <- paste0(OUTPUT_DIR_GLOBAL, "/DQ-Report.html")

# create pdf plot file and results text file 
pdf(analysis_result_plot_file)
sink(analysis_result_text_file)

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
    runOptions <- c(paste0("All NTproBNP values have the same comparator ", comparators[1]))
  } else { # the only value is N.A. -> means there are no comparators
    runOptions <- c("All NTproBNP values have no comparator")
  }
} else if (hasComparators && !hasExactValues) { # there are only values with different comparators
  runOptions <- c(paste0("All NTproBNP values have a comparator of ", paste(comparators, collapse = ', ')))  
} else { # there are values with and values witthout a comparator -> the only case with 2 run options
  runOptions <- c("Incl. Comparators", "Excl. Comparators")  
}

# replace all values by value + 1 if the comparator
# is ">" or with value - 1 if the comparator is "<"
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

# run the same analysis with the first run option with all values and with
# a possibly existing second run option without all values with comparators
for (runOption in runOptions) {

  # Reload cohort file for the second run option because
  # the data were filtered during the first run.
  if (runOption == runOptions[2]) {
    cohort <- fread(retrieve_result_file_cohort)
  }
  
  # We have to modify the comparator values with > to value + 1 and with < to value - 1
  # You must check N.A. seperately in R!? It is not covered by the last else case :(
  cohort$NTproBNP.valueQuantity.value <- ifelse(is.na(comp), value, ifelse(comp == ">", value + 1, ifelse(comp == "<", value - 1, value)))

  # remove invalid data rows
  cohort <- cohort[
      !is.na(NTproBNP.valueQuantity.value) & # missing value -> invalid
      NTproBNP.valueQuantity.value >= 0      # NTproBNP value < 0 -> invalid
  ]

  filterComparatorValues <- runOption != runOptions[1] # the 1. run option is with all values and the 2. with filtered
  sizeBeforeRemove <- nrow(cohort)
  # remove columns with comparator if they should be exluded
  if (filterComparatorValues) { 
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
    write.csv2(result, merged_retrieve_results_file, row.names = FALSE)
  }
  
  # Runs the Data Quality Report
  if (DATA_QUALITY_REPORT) {
    rmarkdown::render("data-quality/report.Rmd", output_format = "html_document", output_file = data_quality_report_file)
  }
  
  ####################################
  # Start Analysis from S. Zeynalova #
  ####################################

  # Order to run the anlaysis and filter the data.
  # The syntax means the following:
  #
  #   If the column name (first word of the option)
  #   does *not* start with a minus sign '-', then
  #   the analysis should beperformed for this value.
  #
  #   If the column name (first word of the option)
  #   starts with a minus sign '-', then the data
  #   should be filtered for all rows, where this
  #   value is 1. Filtere means that this rows with
  #   a 1 value are removed.
  analysisOrder <- c("Vorhofflimmern with all other diagnoses",
                     "Herzinsuffizienz with all other diagnoses",
                     "-Myokardinfarkt",
                     "-Schlaganfall",
                     "Vorhofflimmern without Myokardinfarkt and Schlaganfall",
                     "Herzinsuffizienz without Myokardinfarkt and Schlaganfall",
                     "-Herzinsuffizienz",
                     "Vorhofflimmern without Myokardinfarkt, Schlaganfall and Herzinsuffizienz")
  
  for (fullAnalysisOption in analysisOrder) {
    
    # extract first word of the full analysis option -> current column name
    analysisOption <- unlist(strsplit(fullAnalysisOption, split = "\\s+"))[1]

    # filter data on analysisOptions that starts with '-'
    if (startsWith(analysisOption, '-')) {
      analysisOption <- substr(analysisOption, 2, nchar(analysisOption))
      result <- result[result[[analysisOption]] != 1]
      next
    }
    
    resultRows <- nrow(result)
  
    # check possible data problems
    errorMessage <- ""
    # not enough data rows 
    if (resultRows < 2) {
      errorMessage <- paste0("Result table has ", resultRows, " rows -> abort analysis\n")
    }
    if (all(result[[analysisOption]] == result[[analysisOption]][1])) { # only 0 or only 1 in this diagnosis column
      errorMessage <- paste0("All ", analysisOption ," diagnoses have the same value ", result[[analysisOption]][1], " -> abort analysis\n")
    }
    hasError <- nchar(errorMessage) > 0
    
    # plot roc curve to pdf
    # Explanation of the graph:
    # Sens - Sensitivity
    # Spec - Specificity
    # PV+  - Percentage of false negatives for VHF among all test negatives
    # PV- - Proportion of false positives among all test positives
    if (!hasError) {
      roc <- ROC(test = result$NTproBNP.valueQuantity.value, stat = result[[analysisOption]], plot = "ROC", main = "NTproBNP(Gesamt)", AUC = TRUE)
    }
    
    # start text file logging
    cat("###########################\n")
    cat("# Results of VHF Analysis #\n")
    cat("###########################\n\n")
    cat(paste0("Date: ", Sys.time(), "\n\n"))

    cat(paste0("Current Analysis: ", fullAnalysisOption, "\n"))
    cat(paste0("Run Option: ", runOption, ifelse(filterComparatorValues, paste0(" (", removedObservationsCount, " Observations with comparator removed)"), "")), "\n\n")
  
    cat(comparatorFrequencies, "\n", sep = "\n")
    
    # run analysis if the result table has not only 0 or 1 row and not all diagnoses values are the same
    if (!hasError) {
      
      # print AUC to the text file
      cat(paste0("ROC Area Under Curve NTproBNP(Gesamt): "), roc$AUC, "\n\n")
      
      # create different CUT points for NTproBNP
      thresholds <- c(1 : 60) * 50
      
      cat("NtProBNP Threshold Values Analysis\n")
      cat("----------------------------------\n\n")
      
      for (i in c(1 : length(thresholds))) {
      
        cutsColumnlName <- "NTproBNP.valueQuantity.value_cut"
        cuts <- result[[cutsColumnlName]] <- ifelse(result$NTproBNP.valueQuantity.value < thresholds[i], 0, 1)
      
        cat(paste0("Threshold Value: ", thresholds[i], "\n"))
        cat("---------------------\n")
        cat(fullAnalysisOption, "\n")
        CrossTable(result[[analysisOption]], 
                   cuts, 
                   prop.c = TRUE, 
                   digits = 2, 
                   prop.chisq = FALSE, 
                   format = "SPSS")
        
        if (all(cuts == cuts[1])) { # all cuts have the same value (all 0 or all 1) -> no further calculations 
          # log information in the output file
          cat(paste0("All NTproBNP values are greater than ", thresholds[i]," -> sensitivity, specifity, PV+ and PV- not available.\n\n\n"))
        } else {
          table <- xtabs(~cuts + result[[analysisOption]])
          test <- rowSums(table)
          sick <- colSums(table)
          
          # sensitivity
          sensitivity <- table[2, 2] / sick[2]
          cat(paste0("Sensitivity: ", sensitivity, "\n"))
          
          # specifity
          specifity <- table[1, 1] / sick[1]
          cat(paste0("  Specifity: ", specifity, "\n"))
          
          # npw - the positive predictive value
          ppv <- table[2, 2] / test[2]
          cat(paste0("        PV+: ", ppv, "\n"))
        
          # npw - Der negativepredictive value
          npv <- table[1, 1] / test[1]
          cat(paste0("        PV-: ", npv, "\n\n"))
      
          # add the ROC plot to the pdf and the AUC value to the text file
          rocTitle <- paste0("NtproBNP_cut", thresholds[i],  " BY VHF")
          roc <- ROC(test = cuts, stat = result[[analysisOption]], plot = "ROC", main = rocTitle)
          cat(paste0("ROC Area Under Curve (Threshold ", thresholds[i], "): "), roc$AUC, "\n\n\n")
        }
      }
      
      #Multivarite Analyse, VHF in Abhängigkeit von NTproBNP, adjustiert mit Alter und Geschlecht
      
      cat("GLM Analysis\n")
      cat("------------")
      
      # calculate age by birthdate and NTproBNP date
      result$NTproBNP.date <- as.POSIXct(result$NTproBNP.date, format = "%Y")
      result$birthdate <- as.POSIXct(result$birthdate, format = "%Y")
      result$age <- year(result$NTproBNP.date) - year(result$birthdate)
      
      # glm(...) throws an error if one of the so called contrast values (vector)
      # has always the same value -> we must identify these contrast values and
      # remove them from our analysis
      
      # all contrast values we want to consider
      contrast_names = c("NTproBNP.valueQuantity.value", "age", "gender")
      # list for all contratst we want to use in glm(...) is filled
      # by the given contrast column names
      contrasts <- list()
      for (i in 1 : length(contrast_names)) {
        colName <- contrast_names[i] # get column name i
        con <- result[[colName]]     # get result column with colum name i
        contrasts[i] <- list(con)    # add result column as list item to contrasts
      }
      
      # now remove all invalid constrast (= contrast
      # vectors where all values are equal)
      for (i in length(contrasts) : 1) {
        con <- contrasts[i][[1]] # get the contrast vector i
        first_con <- con[1]      # get th first element of contrast vector i
        # if all values are equal in the contrast vector
        if (all(con == first_con)) {
          # log information in the output file
          cat(paste0("All values of '", contrast_names[i], "' have the same value '", first_con, "' -> '", contrast_names[i], "' is ignored.\n"))
          # remove the invalid contrast vector
          contrasts <- contrasts[- i]
        } else {
          # The values are not all the same -> replace
          # contrast vector by its column name in the
          # result table. We only need the names to
          # construct the glm(...) formula.
          contrasts[i] <- contrast_names[i]
        }
      }
      
      cat("\n")
      
      # construct the formula for glm(...) 
      logit_formula <- as.formula(paste(analysisOption, " ~ ", paste(contrasts, collapse = "+")))
      logit <- glm(logit_formula, family = binomial, data = result)
      summaryText <- capture.output(summary(logit)) # https://www.r-bloggers.com/2015/02/export-r-output-to-a-file/
      cat(summaryText, sep = "\n") # summaryText is a list -> print list with line breaks
    } else {
      cat(errorMessage, "\n")
      message(errorMessage)
    }
    cat("\n")
  }
}
  
logText <- paste0("\nFinished: ", Sys.time(), "\n")
cat(logText)
message(logText)

sink()
dev.off()
closeAllConnections()
