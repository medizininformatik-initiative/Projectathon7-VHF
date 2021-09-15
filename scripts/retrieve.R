# Rscript zum Download von FHIR-Daten zum Vorhofflimmern VHF

library(base)
library(dplyr)
library(fhircrackr)
library(stringr)
library(utils)
library(readxl)
library(writexl)

FHIR_ENDPOINT <- Sys.getenv("FHIR_ENDPOINT")
FHIR_USERNAME <- Sys.getenv("FHIR_USERNAME")
FHIR_PASSWORD <- Sys.getenv("FHIR_PASSWORD")

MAX_BUNDLES     = Inf
VERBOSE         = 2
SAVE_LABOR_DATA = TRUE
SAVE_DIAG_DATA  = TRUE
STYLE = fhir_style(
  sep           = "|",
  brackets      = NULL,
  rm_empty_cols = TRUE
)
# only needed if verbose > 0; write intermediate results
writeCsv <- function(lot) {
  for (n in names(lot)) {
    write.table(
      x = lot[[n]],
      file = paste0(dataDirectory, "/", n, ".csv"),
      na = "",
      sep = ";",
      dec = ",",
      row.names = F,
      quote = F
    )
  }
}

###############################################################################################################
# Erste FHIR search Abfrage
###############################################################################################################
fsq <- fhir_url(
  url = FHIR_ENDPOINT,
  resource = "Observation",
  parameters = list(
#    "code" = "33762-6", #echter Vorhofflimmercode
#    "code" = "3142-7", #Gewicht
    "_include" = "Observation:patient",
    "_include" = "Observation:encounter",
    "_count" = "100"
  )
)

obs_bundles <- fhircrackr::fhir_search(
  request = fsq, 
  max_bundles = MAX_BUNDLES, 
  verbose = VERBOSE, 
  username = FHIR_USERNAME, 
  password = FHIR_PASSWORD
)

Observations <- fhir_table_description(
  resource = "Observation",
  cols     = list(
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
  cols = list(
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
  cols = list(
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

laborData <- fhircrackr::fhir_crack(obs_bundles, obs_design, verbose = VERBOSE, data.table = T)

# for(i in seq_len(length(laborData))) {
#   meta_names <- names(laborData[[i]])[grepl("meta.", names(laborData[[i]]))]
#   laborData[[i]][,(meta_names):=NULL]
# }

for(n in names(laborData)) {
  names_ <- names(laborData[[n]])
  id_names <- names_[grep(".ID", names_)]
  for(idn in id_names) {
    laborData[[n]][[idn]] <- gsub("^[A-Za-z]+/", "", laborData[[n]][[idn]])
  }
}
laborData$Patients <- distinct(laborData$Patients, Pat.Pat.ID,.keep_all = T)
laborData$Encounters <- distinct(laborData$Encounters, Enc.Enc.ID,.keep_all = T)

laborData$ALL <- left_join(
  left_join(
    laborData$Observations,
    laborData$Patients,
    by = c("Obs.Pat.ID" = "Pat.Pat.ID")
  ),
  laborData$Encounters,
  by = c("Obs.Enc.ID" = "Enc.Enc.ID")
)

if(SAVE_LABOR_DATA) writeCsv(laborData)

###################################################
# Zweite FHIR search Abfrage
###################################################

#fsq <- paste_paths(FHIR_ENDPOINT, "Condition?code=I48.0,I48.1,I48.9&_incConditio_count=100")

fsq <- fhir_url(
  url = FHIR_ENDPOINT,
  resource = "Condition",
  parameters = list(
    "code" = "I48.0,I48.1,I48.9",
    "_include" = "Condition:patient",
    "_include" = "Condition:encounter",
    "_count" = "100"
  )
)

con_bundles <- try(fhircrackr::fhir_search(
  request = fsq,
  max_bundles = MAX_BUNDLES, 
  verbose = VERBOSE,
  username = FHIR_USERNAME,
  password = FHIR_PASSWORD
))

if(inherits(con_bundles, "try-error")) {
  message("Das ging schief")
}

Conditions <- fhir_table_description(
  resource = "Condition",
  cols = list(
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

diagData <- fhircrackr::fhir_crack(con_bundles, con_design, verbose = VERBOSE, data.table = T)

for(n in names(diagData)) {
  names_ <- names(diagData[[n]])
  id_names <- names_[grep(".ID", names_)]
  for(idn in id_names) {
    diagData[[n]][[idn]] <- gsub("^[A-Za-z]+/", "", diagData[[n]][[idn]])
  }
}

diagData$Patients <- distinct(diagData$Patients, Pat.Pat.ID,.keep_all = T)
diagData$Encounters <- distinct(diagData$Encounters, Enc.Enc.ID,.keep_all = T)

# for(i in seq_len(length(diagData))) {
#   meta_names <- names(diagData[[i]])[grepl("meta.", names(diagData[[i]]))]
#   diagData[[i]][,(meta_names):=NULL]
# }

diagData$ALL <- left_join(
  left_join(
    diagData$Conditions,
    diagData$Patients,
    by = c("Con.Pat.ID" = "Pat.Pat.ID")
  ),
  diagData$Encounters,
  by = c("Con.Enc.ID" = "Enc.Enc.ID")
)

if(SAVE_DIAG_DATA) writeCsv(diagData)




tab <- merge(
  diagData$ALL, 
  laborData$ALL,
  by.x = c("Con.Pat.ID", "NName", "VName", "DOB", "Sex", "Enc.Pat.ID", "Enc.Con.ID", "StartTime", "EndTime"),
  by.y = c("Obs.Pat.ID", "NName", "VName", "DOB", "Sex", "Enc.Pat.ID", "Enc.Con.ID", "StartTime", "EndTime")
)

tab$datum_labor <- as.POSIXct(tab$datum_labor, tz = Sys.timezone())
tab$recordedDate <- as.POSIXct(tab$recordedDate, tz = Sys.timezone())
#tab$datumDiff <- tab$datum_labor - tab$recordedDate
# better:
tab$datumDiff_days <- difftime(tab$datum_labor, tab$recordedDate, units = "d")

#datumDiff muss => 0 sein, sonst muss die Diagnose auf NA gesetzt werden.
# tab_tmp <- filter(tab, tab$datumDiff < 0)
# d <- dim(tab_tmp)
# if (0 < d[1]) {
#   tab_tmp$Diagnose <- NA
# }
# better:
tab <- tab[0 <= datumDiff_days,]


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
# if (verbose > 0) writeCsv(patientData)

###################################################
# Cleanup
###################################################

#result <- left_join(tab, patientData[[1]], by = "pid")
result <- tab

result$Alter <- as.numeric(difftime(result$datum_labor, result$DOB, units = "days") / 365.25)

result$Geschlecht <- factor(
  result$Sex,
  levels = c("male", "female"),
  labels = c(1, 2)
)

result$NTproBNP <- as.numeric(result$NTproBNP)
result$Station <- "kardiologie"

xlsx::write.xlsx(
  result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")],
  dataFile,
  row.names = FALSE
)
