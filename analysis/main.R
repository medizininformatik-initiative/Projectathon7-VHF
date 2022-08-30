### Preparation
start <- Sys.time()
# load/install a packages
source("analysis/install-dependencies.R")

# source config
source("analysis/config.R")

PROJECT_NAME <- "VHF"

### Verzeichnisse
# Verzeichnis für Zwischenergebnisse/Debug
OUTPUT_DIR_LOCAL <- paste0(OUTPUT_DIR_BASE, "/outputLocal/", PROJECT_NAME)
# Verzeichnis für Endergebnisse
OUTPUT_DIR_GLOBAL <- paste0(OUTPUT_DIR_BASE, "/outputGlobal/", PROJECT_NAME)
if (DECENTRAL_ANALYIS) {
  retrieve_dir = OUTPUT_DIR_LOCAL
} else {
  retrieve_dir = OUTPUT_DIR_GLOBAL
}

result_file_retrieve <- paste0(retrieve_dir, "/Retrieve.csv")

# TODO WIP

# ### Build the result table ###
# result <- cohort[, .(
#   subject,
#   # fill the date (=timestamp) column with the timestamp of the max NTproBNP
#   # value for every encounter
#   NTproBNP.date = NTproBNP.date[NTproBNP.valueQuantity.value == max(NTproBNP.valueQuantity.value)],
#   # fill the NTproBNP value for every encounter with the maximum value
#   NTproBNP.valueQuantity.value = max(NTproBNP.valueQuantity.value),
#   NTproBNP.valueCodeableConcept.code,
#   NTproBNP.unit,
#   birthdate,
#   gender
# ), by = encounter.id]
# 
# # remove equal columns which are now present if there were multiple NTproBNP
# # values for the same encounter with different timestamps (now these NTproBNP
# # values have all the same timestamp and so the whole row is equals)
# result <- unique(result)
# 
# # for each encounter, extract the Boolean information whether certain diagnoses
# # were present
# conditionsReduced <- conditions[, .(
#   VHF = as.numeric(any(grepl("I48.0|I48.1|I48.2|I48.9", code))),
#   MI = as.numeric(any(grepl("I21|I22|I25.2", code))),
#   HI = as.numeric(any(grepl("I50", code))),
#   Schlaganfall = as.numeric(any(grepl("I60|I61|I62|I63|I64|I69", code)))
# ), by = encounter.id]
# 
# # merge the result encounters with the diagnoses information
# result <- merge.data.table(
#   x = result,
#   y = conditionsReduced,
#   by = "encounter.id",
#   all.x = TRUE
# )
# # bring the subject column to the front again
# setcolorder(result, neworder = "subject")
# 
# # Write result files
# write.csv2(result, result_file_retrieve, row.names = FALSE)
