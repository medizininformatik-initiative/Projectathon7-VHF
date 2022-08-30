# Konfigurations-Datei für Vorhofflimmern Retrieval
# Bitte die folgenden Variablen entsprechend der Gegebenheiten vor Ort anpassen!

emptyToNull <- function(v) {
  if (v == '') return(NULL) else return(v)
}

DEBUG <- as.logical(Sys.getenv('DEBUG', "FALSE"))
# Verbose-Level des fhircrackr
VERBOSE <- as.integer(Sys.getenv('VERBOSE', "0"))
# Run the Data Quality Check
DATA_QUALITY_REPORT <- as.logical(Sys.getenv('DATA_QUALITY_REPORT', "TRUE"))

# Directory where 'outputLocal' and 'outputGlobal' directories are located 
OUTPUT_DIR_BASE <- Sys.getenv('OUTPUT_DIR_BASE', '.')
