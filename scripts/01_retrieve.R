# ###
# # Rscript zum Download von FHIR-Daten zum Vorhofflimmern VHF
# ###
# 
# tryProcess <- function(process, message) {
#   cat(paste0(message, " "))
#   err <- polar_clock$measure_process_time(
#     message = message,
#     process = process
#   )
#   check_error(err, {cat_ok()}, {cat_error(); stop(err)})
# }

#MAX_BUNDLES     = 10
VERBOSE         = 2
SAVE_LABOR_DATA = TRUE
SAVE_DIAG_DATA  = TRUE

STYLE = fhir_style(
  sep           = "|",
  brackets      = NULL,
  rm_empty_cols = TRUE
)

###
# Check FHIR ENDPOINT for Response
###
polar_run(
  message = "0 Check FHIR ENDPOINT for response",
  process = {
    if(FHIR_ENDPOINT == "") {
      stop("FHIR_ENDPOINT is an empty string.")
    }
    if(!check_response(FHIR_ENDPOINT)) {
      stop(paste0("The Server ", FHIR_ENDPOINT, " does not response. "))
    }
  }
)
MAX_BUNDLES <- 198
###
# Erste FHIR search Abfrage
# http://localhost:8080/baseR4/Observation?code=33762-6&_include=Observation:patient&_include=Observation:encounter
###
polar_run("1 Create first FHIR Search request", {  
  request <- fhir_url(
    url = FHIR_ENDPOINT,
    resource = "Observation",
    parameters = c(
      "code"     = "33762-6",
#      "code"     = "15074-8",
      "_include" = "Observation:patient",
      #"_include" = "Observation:encounter",
      "_count"   = "50"
    )
  )
})

polar_run("2 Execute the FHIR Search and Save Revieved Bundles", {
  polar_run("2.1 Execute the FHIR Search", {
    obs_bundles <- polar_fhir_search(
      request = request, 
      verbose = VERBOSE
    )
  }, single_line = FALSE)
  polar_run("2.2 Save Bundles", {
    polar_save_bundles(obs_bundles)
  })
},single_line = FALSE)

polar_run("3 Create laborData table descriptions and design", {
  
  Observations <- fhir_table_description(
    resource = "Observation",
    cols     = c(
      Obs.Obs.ID   = "id",
      Obs.Pat.ID   = "subject/reference",
      Obs.Enc.ID   = "encounter/reference",
      NTproBNP     = "valueQuantity/value",
      NTproBNPUnit = "valueQuantity/unit",
      datum_labor  = "effectiveDateTime",
      code         = "code/coding/code",
      system       = "code/coding/system"
    ),
    style = STYLE
  )
  
  Patients <- fhir_table_description(
    resource = "Patient",
    cols = c(
      Pat.Pat.ID = "id",
      NName = "name/family",
      VName = "name/given",
      DOB   = "birthDate",
      Sex   = "gender"
    ),
    style = STYLE
  )
  
  # Encounters <- fhir_table_description(
  #   resource = "Encounter",
  #   cols = c(
  #     Enc.Enc.ID = "id",
  #     Enc.Pat.ID = "subject/reference",
  #     Enc.Con.ID = "diagnosis/condition/reference",
  #     StartTime  = "period/start",
  #     EndTime    = "period/end"
  #   ),
  #   style = STYLE
  # )
  
  obs_design <- fhir_design(
    Observations, Patients#, Encounters
  )
})

polar_run("4 Crack laborData tables", {  
  laborData <- fhir_crack(obs_bundles, obs_design, verbose = VERBOSE, data.table = T)
}, single_line = VERBOSE == 0)


polar_run("5 Remove ID prefixes in laborData tables", {
  for(n in names(laborData)) {
    names_ <- names(laborData[[n]])
    id_names <- names_[grep(".ID", names_)]
    for(idn in id_names) {
      laborData[[n]][[idn]] <- gsub("^[A-Za-z]+/", "", laborData[[n]][[idn]])
    }
  }
})

polar_run("6 Remove multiple Patients from laborData table", {
  polar_run("6.1 Remove multiple Patients from laborData table", {
    laborData$Patients <- distinct(laborData$Patients, Pat.Pat.ID, .keep_all = T)
  })
  # polar_run("6.2 Remove multiple Encounters from laborData table",
  #   process = {  
  #     laborData$Encounters <- distinct(laborData$Encounters, Enc.Enc.ID, .keep_all = T)
  #   })
}, single_line = FALSE)

polar_run("7 Join labaorData tables Observations and Patients", {  
  laborData$ALL <- left_join(
      laborData$Observations,
      laborData$Patients,
      by = c("Obs.Pat.ID" = "Pat.Pat.ID")
    )
})

polar_run("8 Save Completed Labor Data", {
  if (SAVE_LABOR_DATA) polar_save_table_as_csv(laborData$ALL, "labor_data")
})


###
# Zweite FHIR search Abfrage
# http://localhost:8080/baseR4/Condition?code=I48.0,I48.1,I48.9&_include=Condition:patient&_include=Condition:encounter
###

polar_run("9 Create second FHIR Search request for Conditions", {
  request <- fhir_url(
    url = FHIR_ENDPOINT,
    resource = "Condition",
    parameters = c(
      "code" = "I48.0,I48.1,I48.9",
      "_include" = "Condition:patient"#,
#      "_include" = "Condition:encounter"
    )
  )
})

MAX_BUNDLES <- 21
polar_run("10 Execute the FHIR Search and Save Revieved Bundles", {
  polar_run("10.1 Execute the FHIR Search", {  
    con_bundles <- polar_fhir_search(
      request     = request,
      max_bundles = MAX_BUNDLES, 
      verbose     = VERBOSE
    )
  }, single_line = VERBOSE < 1)
  polar_run("10.2 Save Bundles", {
    polar_save_bundles(con_bundles)
  })
})

polar_run("11 Create diagData table descriptions and design", {  
  Conditions <- fhir_table_description(
    resource = "Condition",
    cols = c(
      Con.Con.ID = "id",
      Con.Pat.ID = "subject/reference",
      #Con.Enc.ID = "encounter/reference",
      Diagnosis    = "code/coding/code",
      recordedDate = "recordedDate"
    ),
    style = STYLE
  )

  con_design <- fhir_design(
    Conditions, Patients#, Encounters
  )
})

polar_run("12 Crack diagData tables", {
  diagData <- fhir_crack(con_bundles, con_design, verbose = VERBOSE, data.table = T)
}, single_line = VERBOSE < 1)

polar_run("13 Remove ID prefixes in diagData tables", {
  for(n in names(diagData)) {
    names_ <- names(diagData[[n]])
    id_names <- names_[grep(".ID", names_)]
    for(idn in id_names) {
      diagData[[n]][[idn]] <- gsub("^[A-Za-z]+/", "", diagData[[n]][[idn]])
    }
  }
})


polar_run("14 Remove multiple Patients from diagData table", {
  
  polar_run("14.1 Remove multiple Patients from diagData table", {
    diagData$Patients <- distinct(diagData$Patients, Pat.Pat.ID,.keep_all = T)
  })
  
  # polar_run("14.2 Remove multiple Encounters from diagData table", {
  #   diagData$Encounters <- distinct(diagData$Encounters, Enc.Enc.ID,.keep_all = T)
  # })
}, single_line = FALSE)

polar_run("15 Join labaorData tables Observations and Patients", {  
  diagData$ALL <- left_join(
    diagData$Conditions,
    diagData$Patients,
    by = c("Con.Pat.ID" = "Pat.Pat.ID")
  )
})

polar_run("16 Save Completed Diag Data", {  
  if (SAVE_DIAG_DATA) polar_save_table_as_tsv(diagData$ALL, "request_2")
})

polar_run("17 Merge tables diagData and laborData", {
  fullData <- merge(
    laborData$ALL,
    diagData$ALL,
    by.x = c("Obs.Pat.ID", "DOB", "Sex"),
    by.y = c("Con.Pat.ID", "DOB", "Sex"),
    all  = FALSE
  )
})

polar_run("18 Reformat Dates in all Tables", {
  polar_run("18.1 Reformat datum_labor", {
    fullData$datum_labor <- as.POSIXct(fullData$datum_labor, tz = Sys.timezone())
  })

  polar_run("18.2 Reformat recordedDate", {
    fullData$recordedDate <- as.POSIXct(fullData$recordedDate, tz = Sys.timezone())
  })
})

polar_run("19 Check Dates", {  
  #fullData$datumDiff <- fullData$datum_labor - fullData$recordedDate
  fullData$datumDiff_days <- difftime(fullData$datum_labor, fullData$recordedDate, units = "d")
  
  #datumDiff muss => 0 sein, sonst muss die Diagnose auf NA gesetzt werden.
  # fullData_tmp <- filter(fullData, fullData$datumDiff < 0)
  # d <- dim(fullData_tmp)
  # if (0 < d[1]) {
  #   fullData_tmp$Diagnose <- NA
  # }
  # better:
  fullData <- fullData[0 <= datumDiff_days,]
})

polar_run("20 Calculate Patients' Ages", {  
  fullDate[,Alter:=as.numeric(difftime(result$datum_labor, result$DOB, units = "days") / 365.25)]
})

polar_run("21 Factorize Geschlecht", {  
  fullDate[,Geschlech:=]
})

# result$Geschlecht <- factor(
#   result$Sex,
#   levels = c("male", "female"),
#   labels = c(1, 2)
# )
# 
# result$NTproBNP <- as.numeric(result$NTproBNP)
# result$Station <- "kardiologie"
# 
# result = result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")]




# # ab hier ist das Script noch nicht umgebaut, da bisher keine funktionierenden
# # Testdaten für die 2. Abfrage vorlagen.
# 
# 
# # ###################################################
# # # Dritte FHIR search Abfrage
# # ###################################################
# # 
# # fsq <- paste0(FHIR_ENDPOINT, "Patient?_count=100")
# # bundles <- fhircrackr::fhir_search(fsq, max_bundles = MAX_BUNDLES, verbose = verbose, username = FHIR_USERNAME, password = FHIR_PASSWORD)
# # design <- list(Patient = list(
# #   resource = "//Patient",
# #   cols = list(
# #     pid = "id",
# #     birthday = "birthDate",
# #     Geschlecht = "gender"
# #   ),
# #   style = list(
# #     sep = "|",
# #     brackets = NULL,
# #     rm_empty_cols = TRUE
# #   )
# # ))
# # 
# # patientData <- fhircrackr::fhir_crack(bundles, design, verbose = verbose)
# # 
# # if (verbose > 0) writeCsv(patientData, 3)
# 
# ###################################################
# # Cleanup 
# ###################################################
# 
# 
# # library(stringr)
# # library(utils)
# # #library(writexl)
# # library(WriteXLS)
# 
# 
# #result <- left_join(fullData, patientData[[1]], by = "pid")
# result <- fullData
# 
# result$Alter <- as.numeric(difftime(result$datum_labor, result$DOB, units = "days") / 365.25)
# 
# result$Geschlecht <- factor(
#   result$Sex,
#   levels = c("male", "female"),
#   labels = c(1, 2)
# )
# 
# result$NTproBNP <- as.numeric(result$NTproBNP)
# result$Station <- "kardiologie"
# 
# result = result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")]
# save(result, file = 'DATEINAME.rdata' )
# 
# load('DATEINAME.rdata')
# 
# #WriteXLS(result, ExcelFileName = "FILENAME.xlsx")
# 
# 
# xlsx::write.xlsx(
#   result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")],
#   outputLocalDataFile,
#   row.names = FALSE
# )
# 
# #writeCsv(list(result = result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")]))
# 
# # write.table(
# #   x = result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")],
# #   file = paste0(targetDirectory, table_name, ".csv"),
# #   na = "",
# #   sep = "\t",
# #   dec = ",",
# #   row.names = F,
# #   quote = F
# # )
