#'
#' The real analysis function that produces the text output and the plots.
#'
#' @param result the data table
#' @param cohortDescription String with a description of the current cohort in
#' the result table (e.g. "Full cohort", "Males", "Females, Age > 50", ' ...)
#' @param analysisOption String with one of the the diagnoses column names in
#' the result table (e.g. "AtrialFibrillation")
#' @param analysisOptionDisplay String with a specific text for the
#' analysisOption that will be used as plot and logging title (e.g."Atrial
#' Fibrillation without Myocardial Infarction and Stroke")
#' @param comparatorOptionDisplay String that describes the data regarding
#' containing NTproBNP values with or without comparators
#' @param comparatorFrequenciesText String of a table with all unique values
#' with comparators and its frequencies in this analysis
#' @param removedObservationsCount number of NTproBNP values removed with
#' comparator
#' 
analyze <- function(result, cohortDescription, analysisOption, analysisOptionDisplay, comparatorOptionDisplay, comparatorFrequenciesText, removedObservationsCount) {
  
  message(analysisOptionDisplay, " (", comparatorOptionDisplay, "):")
  
  resultRows <- nrow(result)
  
  # check possible data problems
  errorMessage <- NA
  # not enough data rows
  if (resultRows < 2) {
    errorMessage <- paste0("Result table has ", resultRows, " rows -> abort analysis\n")
  }
  if (all(result[[analysisOption]] == result[[analysisOption]][1])) { # only 0 or only 1 in this diagnosis column
    errorMessage <- paste0("All ", analysisOption, " diagnoses have the same value ", result[[analysisOption]][1], " -> abort analysis\n")
  }
  hasError <- !is.na(errorMessage)
  
  # plot roc curve to pdf
  # Explanation of the graph:
  # Sens = Sensitivity
  # Spec = Specificity
  #  PV+ = Percentage of false negatives for VHF among all test negatives
  #  PV- = Proportion of false positives among all test positives
  if (!hasError) {
    rocTitle <- paste0("NTproBNP(Full) for ", cohortDescription, "\n", analysisOptionDisplay, "\n(", comparatorOptionDisplay, ")")
    roc <- ROC(test = result$NTproBNP.valueQuantity.value, stat = result[[analysisOption]], plot = "ROC", main = rocTitle, AUC = TRUE)
  }
  
  # start text file logging
  cat("###########################\n")
  cat("# Results of VHF Analysis #\n")
  cat("###########################\n\n")
  cat(paste0("Date: ", Sys.time(), "\n\n"))
  
  cat(paste0("    Cohort: ", cohortDescription, "\n"))
  cat(paste0("  Analysis: ", analysisOptionDisplay, "\n"))
  cat(paste0("Run Option: ", comparatorOptionDisplay, ifelse(removedObservationsCount > 0 , paste0(" (", removedObservationsCount, " Observations with comparator removed)"), "")), "\n\n")
  
  if (nchar(comparatorFrequenciesText) > 0) {
    cat(comparatorFrequenciesText, "\n\n")
  }
  
  # run analysis if the result table has not only 0 or 1 row and not all diagnoses values are the same
  if (!hasError) {
    
    # print AUC to the text file
    cat(paste0("ROC Area Under Curve NTproBNP(Full): "), roc$AUC, "\n\n")
    
    # create different CUT points for NTproBNP
    thresholds <- c(1 : 60) * 50
    
    cat("NtProBNP Threshold Values Analysis\n")
    cat("----------------------------------\n\n")
    
    for (i in c(1 : length(thresholds))) {
      cutsColumnlName <- "NTproBNP.valueQuantity.value_cut"
      cuts <- result[[cutsColumnlName]] <- ifelse(result$NTproBNP.valueQuantity.value < thresholds[i], 0, 1)
      cat(paste0("\nThreshold Value: ", thresholds[i], "\n"))
      cat("---------------------\n")
      cat(analysisOptionDisplay, "\n")
      CrossTable(result[[analysisOption]],
                 cuts,
                 prop.c = TRUE,
                 digits = 2,
                 prop.chisq = FALSE,
                 format = "SPSS")
      
      if (all(cuts == cuts[1])) { # all cuts have the same value (all 0 or all 1) -> no further calculations
        # log information in the output file
        cat(paste0("All NTproBNP values are greater than ", thresholds[i], " -> sensitivity, specifity, PV+ and PV- not available.\n\n\n"))
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
        rocTitle <- paste0(
          "NtproBNP_cut", thresholds[i], " for ", cohortDescription, "\n",
          analysisOptionDisplay, "\n",
          "(", comparatorOptionDisplay, ")")
        roc <- ROC(test = cuts, stat = result[[analysisOption]], plot = "ROC", main = rocTitle)
        cat(paste0("ROC Area Under Curve (Cut ", thresholds[i], "): "), roc$AUC, "\n\n\n")
      }
    }
    
    #Multivarite Analyse, VHF in Abhängigkeit von NTproBNP, adjustiert mit Alter und Geschlecht
    
    cat("GLM Analysis\n")
    cat("------------")
    
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
        contrasts <- contrasts[-i]
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
    message("done\n")
  } else {
    log(errorMessage)
  }
  cat("\n")
}
