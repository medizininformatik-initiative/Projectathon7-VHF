###
# Rscript zum Download von FHIR-Daten zum Vorhofflimmern VHF
###

tryProcess <- function(process, message) {
  cat(paste0(message, " "))
  err <- polar_clock$measure_process_time(
    message = message,
    process = process
  )
  check_error(err, {cat_ok()}, {cat_error(); stop(err)})
}


###
# Check FHIR ENDPOINT for Response
###
tryProcess(
  message = "Check FHIR ENDPOINT for response",
  process = {
    if(FHIR_ENDPOINT == "") {
      stop("No FHIR Endpoint present.")
    }
    if(!check_response(FHIR_ENDPOINT)) stop(paste0("FHIR Endpoint ", FHIR_ENDPOINT, " does not response. "))
  }
)

MAX_BUNDLES     = 10
VERBOSE         = 2
SAVE_LABOR_DATA = TRUE
SAVE_DIAG_DATA  = TRUE

STYLE = fhir_style(
  sep           = "|",
  brackets      = NULL,
  rm_empty_cols = TRUE
)

###
# Erste FHIR search Abfrage
# http://localhost:8080/baseR4/Observation?code=33762-6&_include=Observation:patient&_include=Observation:encounter
###
tryProcess(
  message = "Create first FHIR Search request",
  process = {  
    request <- fhir_url(
      url = FHIR_ENDPOINT,
      resource = "Observation",
      parameters = c(
        "code" = "33762-6",
        "_include" = "Observation:patient",
        "_include" = "Observation:encounter",
        "_count" = "100"
      )
    )
  }
)

tryProcess(
  message = paste0("FHIR Search ", request),
  process = {  
    obs_bundles <- fhircrackr::fhir_search(
      request = request, 
      max_bundles = MAX_BUNDLES, 
      verbose = VERBOSE, 
      username = FHIR_USERNAME, 
      password = FHIR_PASSWORD,
    )
  }
)

polar_save_bundles(obs_bundles)

tryProcess(
  message = "Create laborData table descriptions and design",
  process = {  
    Observations <- fhir_table_description(
      resource = "Observation",
      cols     = c(
        Obs.Obs.ID  = "id",
        Obs.Pat.ID  = "subject/reference",
        Obs.Enc.ID  = "encounter/reference",
        NTproBNP    = "valueQuantity/value",
        NTproBNPUnit = "valueQuantity/unit",
        datum_labor = "effectiveDateTime",
        code        = "code/coding/code",
        system      = "code/coding/system"
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
    
    Encounters <- fhir_table_description(
      resource = "Encounter",
      cols = c(
        Enc.Enc.ID = "id",
        Enc.Pat.ID = "subject/reference",
        Enc.Con.ID = "diagnosis/condition/reference",
        StartTime  = "period/start",
        EndTime    = "period/end"
      ),
      style = STYLE
    )
    
    obs_design <- fhir_design(
      Observations, Patients, Encounters
    )
  }
)

tryProcess(
  message = "Crack laborData tables",
  process = {  
    laborData <- fhircrackr::fhir_crack(obs_bundles, obs_design, verbose = VERBOSE, data.table = T)
  }
)

# Remove .meta-columns (will be done by fhircrackr automatically in future) 
# for(i in seq_len(length(laborData))) {
#   meta_names <- names(laborData[[i]])[grepl("meta.", names(laborData[[i]]))]
#   laborData[[i]][,(meta_names):=NULL]
# }

stop()

tryProcess(
  message = "Remove ID prefixes in laborData tables",
  process = {  
    for(n in names(laborData)) {
      names_ <- names(laborData[[n]])
      id_names <- names_[grep(".ID", names_)]
      for(idn in id_names) {
        laborData[[n]][[idn]] <- gsub("^[A-Za-z]+/", "", laborData[[n]][[idn]])
      }
    }
  }
)

tryProcess(
  message = "Remove multiple Patients from laborData table",
  process = {  
    laborData$Patients <- distinct(laborData$Patients, Pat.Pat.ID, .keep_all = T)
  }
)

tryProcess(
  message = "Remove multiple Encounters from laborData table",
  process = {  
    laborData$Encounters <- distinct(laborData$Encounters, Enc.Enc.ID, .keep_all = T)
  }
)

tryProcess(
  message = "Join labaorData tables Observations and Patients",
  process = {  
    laborData$ALL <- left_join(
      left_join(
        laborData$Observations,
        laborData$Patients,
        by = c("Obs.Pat.ID" = "Pat.Pat.ID")
      ),
      laborData$Encounters,
      by = c("Obs.Enc.ID" = "Enc.Enc.ID")
    )
  }
)

if (SAVE_LABOR_DATA) polar_save_table_as_csv(laborData, "request_1")


###
# Zweite FHIR search Abfrage
# http://localhost:8080/baseR4/Condition?code=I48.0,I48.1,I48.9&_include=Condition:patient&_include=Condition:encounter
###

tryProcess(
  message = "Create second FHIR Search request",
  process = {  
    request <- fhir_url(
      url = FHIR_ENDPOINT,
      resource = "Condition",
      parameters = c(
        "code" = "I48.0,I48.1,I48.9",
        "_include" = "Condition:patient",
        "_include" = "Condition:encounter"
      )
    )
  }
)

tryProcess(
  message = paste0("FHIR Search ", request),
  process = {  
    con_bundles <- fhircrackr::fhir_search(
      request = request,
      max_bundles = MAX_BUNDLES, 
      verbose = VERBOSE,
      username = FHIR_USERNAME,
      password = FHIR_PASSWORD
    )
  }
)

tryProcess(
  message = "Create diagData table descriptions and design",
  process = {  
    Conditions <- fhir_table_description(
      resource = "Condition",
      cols = c(
        Con.Con.ID = "id",
        Con.Pat.ID = "subject/reference",
        Con.Enc.ID = "encounter/reference",
        Diagnose     = "code/coding/code",
        recordedDate = "recordedDate"
      ),
      style = STYLE
    )
    # res <- "Condition"
    # d <- fhir_crack(fhir_search(paste_paths(FHIR_ENDPOINT, res), max_bundles = 1), fhir_table_description(res))
    # d[1:3,]
    # names(d)[grep("reference",names(d))]
    
    con_design <- fhir_design(
      Conditions, Patients, Encounters
    )
  }
)

tryProcess(
  message = "Crack diagData tables",
  process = {  
    diagData <- fhircrackr::fhir_crack(con_bundles, con_design, verbose = VERBOSE, data.table = T)
  }
)

tryProcess(
  message = "Remove ID prefixes in diagData tables",
  process = {  
    for(n in names(diagData)) {
      names_ <- names(diagData[[n]])
      id_names <- names_[grep(".ID", names_)]
      for(idn in id_names) {
        diagData[[n]][[idn]] <- gsub("^[A-Za-z]+/", "", diagData[[n]][[idn]])
      }
    }
  }
)


tryProcess(
  message = "Remove multiple Patients from diagData table",
  process = {  
    diagData$Patients <- distinct(diagData$Patients, Pat.Pat.ID,.keep_all = T)
  }
)

tryProcess(
  message = "Remove multiple Encounters from diagData table",
  process = {  
    diagData$Encounters <- distinct(diagData$Encounters, Enc.Enc.ID,.keep_all = T)
  }
)

tryProcess(
  message = "Join labaorData tables Observations and Patients",
  process = {  
    laborData$ALL <- left_join(
      diagData$ALL <- left_join(
        left_join(
          diagData$Conditions,
          diagData$Patients,
          by = c("Con.Pat.ID" = "Pat.Pat.ID")
        ),
        diagData$Encounters,
        by = c("Con.Enc.ID" = "Enc.Enc.ID")
      )
    )
  }
)

if (SAVE_DIAG_DATA) write.csv(diagData, "request_2")

tryProcess(
  message = "Merge tables diagData and laborData",
  process = {  
    fullData <- merge(
      diagData$ALL, 
      laborData$ALL,
      by.x = c("Con.Pat.ID", "NName", "VName", "DOB", "Sex", "Enc.Pat.ID", "Enc.Con.ID", "StartTime", "EndTime"),
      by.y = c("Obs.Pat.ID", "NName", "VName", "DOB", "Sex", "Enc.Pat.ID", "Enc.Con.ID", "StartTime", "EndTime")
    )
  }
)

tryProcess(
  message = "Reformat datum_labor",
  process = {  
    fullData$datum_labor <- as.POSIXct(fullData$datum_labor, tz = Sys.timezone())
  }
)

tryProcess(
  message = "Reformat recordedDate",
  process = {  
    fullData$recordedDate <- as.POSIXct(fullData$recordedDate, tz = Sys.timezone())
  }
)

tryProcess(
  message = "Calculate patients age",
  process = {  
    #fullData$datumDiff <- fullData$datum_labor - fullData$recordedDate
    # better:
    fullData$datumDiff_days <- difftime(fullData$datum_labor, fullData$recordedDate, units = "d")
    
    #datumDiff muss => 0 sein, sonst muss die Diagnose auf NA gesetzt werden.
    # fullData_tmp <- filter(fullData, fullData$datumDiff < 0)
    # d <- dim(fullData_tmp)
    # if (0 < d[1]) {
    #   fullData_tmp$Diagnose <- NA
    # }
    # better:
    fullData <- fullData[0 <= datumDiff_days,]
  }
)

# ab hier ist das Script noch nicht umgebaut, da bisher keine funktionierenden
# Testdaten für die 2. Abfrage vorlagen.


# ###################################################
# # Dritte FHIR search Abfrage
# ###################################################
# 
# fsq <- paste0(FHIR_ENDPOINT, "Patient?_count=100")
# bundles <- fhircrackr::fhir_search(fsq, max_bundles = MAX_BUNDLES, verbose = verbose, username = FHIR_USERNAME, password = FHIR_PASSWORD)
# design <- list(Patient = list(
#   resource = "//Patient",
#   cols = list(
#     pid = "id",
#     birthday = "birthDate",
#     Geschlecht = "gender"
#   ),
#   style = list(
#     sep = "|",
#     brackets = NULL,
#     rm_empty_cols = TRUE
#   )
# ))
# 
# patientData <- fhircrackr::fhir_crack(bundles, design, verbose = verbose)
# 
# if (verbose > 0) writeCsv(patientData, 3)

###################################################
# Cleanup 
###################################################


# library(stringr)
# library(utils)
# #library(writexl)
# library(WriteXLS)


#result <- left_join(fullData, patientData[[1]], by = "pid")
result <- fullData

result$Alter <- as.numeric(difftime(result$datum_labor, result$DOB, units = "days") / 365.25)

result$Geschlecht <- factor(
  result$Sex,
  levels = c("male", "female"),
  labels = c(1, 2)
)

result$NTproBNP <- as.numeric(result$NTproBNP)
result$Station <- "kardiologie"

result = result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")]
save(result, file = 'DATEINAME.rdata' )

load('DATEINAME.rdata')

#WriteXLS(result, ExcelFileName = "FILENAME.xlsx")


xlsx::write.xlsx(
  result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")],
  outputLocalDataFile,
  row.names = FALSE
)

#writeCsv(list(result = result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")]))

# write.table(
#   x = result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")],
#   file = paste0(targetDirectory, table_name, ".csv"),
#   na = "",
#   sep = "\t",
#   dec = ",",
#   row.names = F,
#   quote = F
# )
