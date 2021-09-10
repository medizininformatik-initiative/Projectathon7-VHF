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

MaxBundle <- Inf
verbose <- 2

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

fsq <- paste0(FHIR_ENDPOINT, "Observation?code=33762-6&_count=100")
bundles <- fhircrackr::fhir_search(fsq, max_bundles = MaxBundle, verbose = verbose, username = FHIR_USERNAME, password = FHIR_PASSWORD)

design <- list(Observation = list(
  resource = "//Observation",
  cols = list(
    pid = "subject/reference",
    NTproBNP = "valueQuantity/value",
    datum_labor = "effectiveDateTime"
  ),
  style = list(
    sep = "|",
    brackets = NULL,
    rm_empty_cols = TRUE
  )
))

laborData <- fhircrackr::fhir_crack(bundles, design, verbose = verbose)

if (verbose) writeCsv(laborData)

###################################################
# Zweite FHIR search Abfrage
###################################################

fsq <- paste0(FHIR_ENDPOINT, "Condition?code=I48.0,I48.1,I48.9&_count=100")

bundles <- fhircrackr::fhir_search(fsq, max_bundles = MaxBundle, verbose = verbose, username = FHIR_USERNAME, password = FHIR_PASSWORD)

design <- list(Condition = list(
  resource = "//Condition",
  cols = list(
    pid = "subject/reference",
    Diagnose = "code/coding/code",
    recordedDate = "recordedDate"
  ),
  style = list(
    sep = "|",
    brackets = NULL,
    rm_empty_cols = TRUE
  )
))

diagData <- fhircrackr::fhir_crack(bundles, design, verbose = verbose)

if (verbose) writeCsv(diagData)

tab <- full_join(diagData[[1]], laborData[[1]], by = "pid")
tab$pid <- str_sub(tab$pid, 9, 16)

tab$datum_labor <- as.POSIXct(tab$datum_labor, tz = Sys.timezone())
tab$recordedDate <- as.POSIXct(tab$recordedDate, tz = Sys.timezone())

tab$datumDiff <- tab$datum_labor - tab$recordedDate

# datumDiff muss => 0 sein, sonst muss die Diagnose auf NA gesetzt werden.
tab_tmp <- filter(tab, tab$datumDiff < 0)
d <- dim(tab_tmp)
if (0 < d[1]) {
  tab_tmp$Diagnose <- NA
}

###################################################
# Dritte FHIR search Abfrage
###################################################

fsq <- paste0(FHIR_ENDPOINT, "Patient?_count=100")
bundles <- fhircrackr::fhir_search(fsq, max_bundles = MaxBundle, verbose = verbose, username = FHIR_USERNAME, password = FHIR_PASSWORD)
design <- list(Patient = list(
  resource = "//Patient",
  cols = list(
    pid = "id",
    birthday = "birthDate",
    Geschlecht = "gender"
  ),
  style = list(
    sep = "|",
    brackets = NULL,
    rm_empty_cols = TRUE
  )
))

patientData <- fhircrackr::fhir_crack(bundles, design, verbose = verbose)

if (verbose > 0) writeCsv(patientData)

###################################################
# Cleanup
###################################################

result <- left_join(tab, patientData[[1]], by = "pid")

result$Alter <-
  as.numeric(difftime(result$datum_labor, result$birthday, units = "days") /
               365)
result$Geschlecht <-
  factor(result$Geschlecht,
         levels = c("male", "female"),
         labels = c(1, 2))

result$NTproBNP <- as.numeric(result$NTproBNP)
result$Station <- "kardiologie"

xlsx::write.xlsx(
  result[, c("Station", "Diagnose", "NTproBNP", "Alter", "Geschlecht")],
  dataFile,
  row.names = FALSE
)
