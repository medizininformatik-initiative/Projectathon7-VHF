### Preparation
start <- Sys.time()
# load/install a packages
source("install-dependencies.R")

# source config
source("config.R")

PROJECT_NAME <- "VHF"

### Verzeichnisse
# Verzeichnis für Zwischenergebnisse/Debug
OUTPUT_DIR_LOCAL <- paste0("/mnt/outputLocal/", PROJECT_NAME)
# Verzeichnis für Endergebnisse
OUTPUT_DIR_GLOBAL <- paste0("/mnt/outputGlobal/", PROJECT_NAME)

# Maximum character length of GET requests to the FHIR server.
# This value was created by testing.
# Request to load patients are divided under this maximum length.
MAX_REQUEST_STRING_LENGTH <- 1800

# Output directories
output_local_errors <- paste0(OUTPUT_DIR_LOCAL, "/Errors")
output_local_bundles <- paste0(OUTPUT_DIR_LOCAL, "/Bundles")
# Error files
error_file <- paste0(output_local_errors, "/error_message.txt")
error_file_obs <- paste0(output_local_errors, "/observation_error.xml")
error_file_enc <- paste0(output_local_errors, "/encounter_error.xml")
error_file_con <- paste0(output_local_errors, "/condition_error.xml")
# Debug files
debug_dir_obs_bundles <- paste0(output_local_bundles, "/Observations")
debug_dir_enc_bundles <- paste0(output_local_bundles, "/Encounter")
debug_dir_con_bundles <- paste0(output_local_bundles, "/Conditions")
# Result files
result_file_cohort <- paste0(OUTPUT_DIR_GLOBAL, "/Kohorte.csv")
result_file_diagnoses <- paste0(OUTPUT_DIR_GLOBAL, "/Diagnosen.csv")
result_file_full <- paste0(OUTPUT_DIR_GLOBAL, "/Result.csv")
result_file_log <- paste0(OUTPUT_DIR_GLOBAL, "/retrieve.log")

# remove old files and dirs and create new dirs  (surpress warning if dir exists)
unlink(OUTPUT_DIR_GLOBAL, recursive = TRUE)
unlink(OUTPUT_DIR_LOCAL, recursive = TRUE)
dir.create(OUTPUT_DIR_GLOBAL, recursive = TRUE, showWarnings = FALSE)
dir.create(output_local_errors, recursive = TRUE, showWarnings = FALSE)
if (DEBUG) {
  dir.create(debug_dir_obs_bundles, recursive = TRUE, showWarnings = FALSE)
  dir.create(debug_dir_enc_bundles, recursive = TRUE, showWarnings = FALSE)
  dir.create(debug_dir_con_bundles, recursive = TRUE, showWarnings = FALSE)
}

# If needed disable peer verification
if (!SSL_VERIFY) {
  httr::set_config(httr::config(ssl_verifypeer = 0L))
}

# remove trailing slashes from endpoint
fhir_server_url <-
  if (startsWith(FHIR_SERVER_ENDPOINT, "/")) {
    strtrim(FHIR_SERVER_ENDPOINT, width = nchar(FHIR_SERVER_ENDPOINT) - 1)
  } else{
    FHIR_SERVER_ENDPOINT
  }

# Brackets around indexes for nested values after fhir_crack()
brackets <- c("[", "]")
sep <- " || "

### Get all Observations between 2019-01-01 and 2021-12-31 with loinc 33763-4,71425-3,33762-6,83107-3, 83108-1, 77622-9,77621-1
# also get associated patient resources --> initial patient population
# Observations have to implement MII profile
# TODO: weitere LOINC Codes ergänzen zB für proBNP
obs_request <- fhir_url(
  url = fhir_server_url,
  resource = "Observation",
  parameters = c(
    "code" = "http://loinc.org|33763-4,http://loinc.org|71425-3,http://loinc.org|33762-6,http://loinc.org|83107-3,http://loinc.org|83108-1,http://loinc.org|77622-9,http://loinc.org|77621-1",
    "date" = "ge2019-01-01",
    "date" = "le2021-12-31",
    "_include" = "Observation:patient"
  )
)

# add profile from config
obs_request <- fhir_url(paste0(obs_request, "&_profile=", PROFILE_OBS))

# download bundles
message("Downloading Observations: ", obs_request, "\n")
obs_bundles <- fhir_search(
  request = obs_request,
  username = FHIR_SERVER_USER,
  password = FHIR_SERVER_PASS,
  token = FHIR_SERVER_TOKEN,
  log_errors = error_file_obs,
  verbose = VERBOSE,
  max_bundles = MAX_BUNDLES
)

# save for checking purposes
if (DEBUG) {
  fhir_save(bundles = obs_bundles, directory = debug_dir_obs_bundles)
}

# flatten
obs_description <- fhir_table_description(
  "Observation",
  cols = c(
    NTproBNP.date = "effectiveDateTime",
    subject = "subject/reference",
    NTproBNP.valueQuantity.value = "valueQuantity/value",
    NTproBNP.valueQuantity.comparator = "valueQuantity/comparator",
    NTproBNP.valueCodeableConcept.code = "valueCodeableConcept/coding/code",
    NTproBNP.valueCodeableConcept.system = "valueCodeableConcept/coding/system",
    NTproBNP.code = "code/coding/code",
    NTproBNP.codeSystem = "code/coding/system",
    NTproBNP.unit = "valueQuantity/code",
    NTproBNP.unitSystem = "valueQuantity/system"
  )
)

pat_description <- fhir_table_description("Patient",
                                          cols = c(
                                            id = "id",
                                            gender = "gender",
                                            birthdate = "birthDate"
                                          ))

message("Cracking ", length(obs_bundles), " Observation Bundles.\n")
obs_tables <- fhir_crack(
  obs_bundles,
  design = fhir_design(obs = obs_description, pat = pat_description),
  sep = sep,
  brackets = brackets,
  data.table = TRUE,
  verbose = VERBOSE
)

rm(obs_bundles)

if (nrow(obs_tables$obs) == 0) {
  write(
    "Konnte keine Observations für NTproBNP auf dem Server finden. Abfrage abgebrochen.",
    file = error_file
  )
  stop("No NTproBNP Observations found - aborting.")
}

if (nrow(obs_tables$pat) == 0) {
  write(
    "Konnte keine Patientenressourcen für NTproBNP-Observations auf dem Server finden. Abfrage abgebrochen.",
    file = error_file
  )
  stop("No Patients for NTproBNP Observations found - aborting.")
}

# remove indices in sub table pat in obs_tables 
obs_tables$pat <-
  fhir_rm_indices(obs_tables$pat, brackets = brackets)

# expand multiple cell values to multiple lines
for (i in 1:2) {
  obs_tables$obs <- fhir_melt(
    obs_tables$obs,
    columns = c("NTproBNP.code", "NTproBNP.codeSystem"),
    brackets = brackets,
    sep = sep,
    all_columns = TRUE
  )
}
# remove remaining indices
obs_tables$obs <-
  fhir_rm_indices(obs_tables$obs, brackets = brackets)

# remove the resource_identifier inserted by fhir_melt
obs_tables$obs[, resource_identifier := NULL]

# remove all not loinc lines 
obs_tables$obs <-
  obs_tables$obs[NTproBNP.codeSystem == "http://loinc.org"]

# get rid of resources that have been downloaded multiple times via _include
obs_tables$pat <- unique(obs_tables$pat)

### Prepare Patient id from initial patient population for Search requests that
### download associated resources (e.g. consent, encounters, conditions)

### merge observation and patient data
# prepare key variables for merge
obs_tables$obs[, subject := sub("Patient/", "", subject)]

# backup the NTproBNP.date as date string with day and time
# after conversion as.Date(...) the day remains but the time is lost
obs_tables$obs$NTproBNP.date.bak <- obs_tables$obs$NTproBNP.date
obs_tables$obs[, NTproBNP.date := as.Date(NTproBNP.date)]

# merge
message(
  "Merging Observation and Patient data based on Patient id.\n",
  "Number of unique Patient ids in Patient data: ",
  length(unique(obs_tables$pat$id)),
  " in ",
  nrow(obs_tables$pat),
  " rows",
  "\n",
  "Number of unique Patient ids in Observation data: ",
  length(unique(obs_tables$obs$subject)),
  " in ",
  nrow(obs_tables$obs),
  " rows",
  "\n"
)

obsdata <- merge.data.table(
  x = obs_tables$obs,
  y = obs_tables$pat,
  by.x = "subject",
  by.y = "id",
  all.x = TRUE
)

rm(obs_tables)

#split patient id list into smaller chunks that can be used in a GET url
#(split because we don't want to exceed allowed URL length)
patient_ids <- obsdata$subject #all patient ids

#remaining number of characters in the url that can be used for patient IDs
nchar_for_ids <- MAX_REQUEST_STRING_LENGTH - nchar(paste0(fhir_server_url,
                                                          paste0("Encounter", "&_profile=", PROFILE_ENC))) #assume maximal length of 1800

# reduce the chunk size until number of characters is small enough
patient_ids_chunk_size <- length(patient_ids)
repeat {
  patient_ids_chunks <-
    split(patient_ids, ceiling(seq_along(patient_ids) / patient_ids_chunk_size)) # split patients ids in chunks of size n
  nchar <- sapply(patient_ids_chunks, function(x) {
    sum(nchar(x)) + (length(x) - 1)
  }) # compute number of characters for each chunk, including commas for seperation
  if (any(nchar <= nchar_for_ids)) {
    break
  }
  patient_ids_chunk_size <- patient_ids_chunk_size / 2
}


# get encounters and diagnoses
# --> all encounters and diagnoses of initial patient population,
# has be filtered to only include encounters with NTproBNP Observation later on
encounter_bundles <- list()
condition_bundles <- list()

message("Downloading Encounters and Conditions.\n")

invisible({
  lapply(patient_ids_chunks, function(x) {
    # x <- patient_ids_chunks[[1]]
    ids <- paste(x, collapse = ",")

    ### Encounters
    enc_request <- fhir_url(
      url = fhir_server_url,
      resource = "Encounter",
      parameters = c(subject = ids,
                     type = "einrichtungskontakt")
    )

    # add profile from config
    enc_request <- fhir_url(url = paste0(enc_request, "&_profile=", PROFILE_ENC))


    encounter_bundles <<- append(
      encounter_bundles,
      fhir_search(
        enc_request,
        username = FHIR_SERVER_USER,
        password = FHIR_SERVER_PASS,
        token = FHIR_SERVER_TOKEN,
        log_errors = error_file_enc,
        verbose = VERBOSE
      )
    )

    ### Conditions
    con_request <- fhir_url(
      url = fhir_server_url,
      resource = "Condition",
      parameters = c(subject = ids)
    )

    # add profile from config
    con_request <- fhir_url(url = paste0(con_request, "&_profile=", PROFILE_CON))


    condition_bundles <<- append(
      condition_bundles,
      fhir_search(
        con_request,
        username = FHIR_SERVER_USER,
        password = FHIR_SERVER_PASS,
        token = FHIR_SERVER_TOKEN,
        log_errors = error_file_con,
        verbose = VERBOSE
      )
    )

  })
})

# bring encounter results together, save and flatten
encounter_bundles <-
  fhircrackr:::fhir_bundle_list(encounter_bundles)

condition_bundles <-
  fhircrackr:::fhir_bundle_list(condition_bundles)

if (DEBUG) {
  fhir_save(bundles = encounter_bundles, directory = debug_dir_enc_bundles)
  fhir_save(bundles = condition_bundles, directory = debug_dir_con_bundles)
}

enc_description <- fhir_table_description(
  "Encounter",
  cols = c(
    encounter.id = "id",
    subject = "subject/reference",
    encounter.start = "period/start",
    encounter.end = "period/end",
    diagnosis = "diagnosis/condition/reference",
    diagnosis.use.code = "diagnosis/use/coding/code",
    diagnosis.use.system = "diagnosis/use/coding/system",
    serviceType = "serviceType/coding/display"
  )
)

message("Cracking ", length(encounter_bundles), " Encounter Bundles.\n")

encounters <- fhir_crack(
  encounter_bundles,
  design = enc_description,
  brackets = brackets,
  sep = sep,
  data.table = TRUE,
  verbose = VERBOSE
)

rm(encounter_bundles)


con_description <- fhir_table_description(
  "Condition",
  cols = c(
    condition.id = "id",
    clinicalStatus.code = "clinicalStatus/coding/code",
    clinicalStatus.system = "clinicalStatus/coding/system",
    verificationStatus.code = "verificationStatus/coding/code",
    verificationStatus.system = "verificationStatus/coding/system",
    code = "code/coding/code",
    code.system = "code/coding/system",
    subject = "subject/reference",
    encounter = "encounter/reference"
  )
)

message("Cracking ", length(condition_bundles), " Condition Bundles.\n")

conditions <- fhir_crack(
  condition_bundles,
  design = con_description,
  brackets = brackets,
  sep = sep,
  data.table = TRUE,
  verbose = VERBOSE
)

rm(condition_bundles)


if (nrow(encounters) == 0) {
  write(
    "Konnte keine Encounter-Ressourcen zu den gefundenen Patients finden. Abfrage abgebrochen.",
    file = error_file
  )
  stop("No Encounters for Patients found - aborting.")
}

### generate conditions table --> has all conditions of all Patients in the initial population
if (nrow(conditions) > 0) {
  #extract diagnosis use info from encounter table
  useInfo <-
    fhir_melt(
      encounters,
      columns = c("diagnosis", "diagnosis.use.code", "diagnosis.use.system"),
      brackets = brackets,
      sep = sep,
      all_columns = TRUE
    )

  useInfo <- fhir_rm_indices(useInfo, brackets = brackets)

  useInfo <-
    useInfo[, c("encounter.id",
                "diagnosis",
                "diagnosis.use.code",
                "diagnosis.use.system")]

  useInfo[, diagnosis := sub("Condition/", "", diagnosis)]

  # expand condition codes + remove indices
  for (i in 1:2) {
    conditions <-
      fhir_melt(
        conditions,
        columns = c("code", "code.system"),
        brackets = brackets,
        sep = sep,
        all_columns = TRUE
      )
  }
  # remove remaining indices and remove resource_identifier column
  conditions <- fhir_rm_indices(conditions, brackets = brackets)
  conditions[, resource_identifier := NULL]

  # filter for ICD codesystem
  conditions <- conditions[grepl("icd-10", code.system)]

  # add diagnosis use info to condition table
  message(
    "Merging Condition and Encounter data based on Condition id.\n",
    "Number of unique Condition ids in Condition data: ",
    length(unique(conditions$condition.id)),
    " in ",
    nrow(conditions),
    " rows",
    "\n",
    "Number of unique Condition ids in Encounter data: ",
    length(unique(useInfo$diagnosis)),
    " in ",
    nrow(useInfo),
    " rows",
    "\n"
  )

  conditions <- merge.data.table(
    x = conditions,
    y = useInfo,
    by.x = "condition.id",
    by.y = "diagnosis",
    all.x = TRUE
  )

  # prepare key variables for merge (removing ID prefixes caused by join)
  conditions[, subject := sub("Patient/", "", subject)]
  conditions[, encounter := sub("Encounter/", "", encounter)]

  # fill empty values in column encounter.id with the value of column encounter
  # (which are the encounter IDs from the condition.encounter)
  conditions[is.na(encounter.id), encounter.id := encounter]
  conditions[, encounter := NULL]
}

### prepare encounter table ###

# remove diagnosis info clumns and indices
encounters[, c("diagnosis", "diagnosis.use.code", "diagnosis.use.system") :=
             NULL]
encounters <- fhir_rm_indices(encounters, brackets = brackets)

# prepare key variable for merge (removing ID prefixes caused by join)
encounters[, subject := sub("Patient/", "", subject)]

# sort out col types
encounters[, encounter.start := as.Date(encounter.start)]
encounters[, encounter.end := as.Date(encounter.end)]

# merge based on subject id and temporal relation of observation date and encounter times
message(
  "Merging Observation and Encounter data based on Subject id and time.\n",
  "Number of unique Subject ids in Observation data: ",
  length(unique(obsdata$subject)),
  " in ",
  nrow(obsdata),
  " rows",
  "\n",
  "Number of unique Subject ids in Encounter data: ",
  length(unique(encounters$subject)),
  " in ",
  nrow(encounters),
  " rows",
  "\n"
)
# encounters <- encounters[!grepl(".*-E-[0-9]-A", encounters$encounter.id)]
cohort <-
  obsdata[encounters, on = .(subject,
                             NTproBNP.date >= encounter.start,
                             NTproBNP.date <= encounter.end),
          c("encounter.id",
            "encounter.start",
            "encounter.end",
            "serviceType") := list(encounter.id, encounter.start, encounter.end, serviceType)][]

rm(obsdata)

# only keep encounters that have a NTproBNP observation within their encounter.period
cohort <-
  cohort[NTproBNP.date >= encounter.start &
           NTproBNP.date <= encounter.end]

# filter conditions: only keep conditions belonging to the encounters we have just filtered
if (nrow(conditions) > 0) {
  conditions <- conditions[encounter.id %in% cohort$encounter.id]
}

# replace the NTproBNP.date (with only day) by the backup (with day and time)
cohort$NTproBNP.date <- cohort$NTproBNP.date.bak
# remove the date column backup
cohort[, NTproBNP.date.bak := NULL] #cohort <- within(cohort, rm(NTproBNP.date.bak)) 


### Build the result table ### 

result <- cohort[, .(
  subject,
  NTproBNP.date,
  NTproBNP.valueQuantity.value = max(NTproBNP.valueQuantity.value),
  NTproBNP.valueCodeableConcept.code,
  NTproBNP.unit,
  birthdate,
  gender
           ), by = encounter.id]

conditionsReduced <- conditions[, .(
  VHF = as.numeric(grepl("I48.0|I48.1|I48.2|I48.9", code)),
  MI = as.numeric(grepl("I21|I22|I25.2", code)),
  HI = as.numeric(grepl("I50", code)),
  Schlaganfall = as.numeric(grepl("I60|I61|I62|I63|I64|I69", code))
  ), by = encounter.id]

result <- merge.data.table(
  x = result,
  y = conditionsReduced,
  by = "encounter.id",
  all.x = TRUE
)

setcolorder(result, neworder = "subject")

# Write result files
if (DEBUG) {
  write.csv2(cohort, result_file_cohort, row.names = FALSE)
  write.csv2(conditions, result_file_diagnoses, row.names = FALSE)
}
write.csv2(result, result_file_full, row.names = FALSE)

# logging
runtime <- Sys.time() - start

con <- file(result_file_log)
write(
  paste0(
    "smith_select.R finished at ",
    Sys.time(),
    ".\n",
    "Extracted ",
    length(cohort$encounter.id),
    " Encounters based on ",
    length(unique(cohort$subject)),
    " Patients.\n",
    "R script execution took ",
    round(runtime, 2),
    " ",
    attr(runtime, "units"),
    "."
  ),
  file = con
)
close(con)
