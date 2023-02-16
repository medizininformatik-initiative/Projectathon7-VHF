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
source("../utils/utils.R")

PROJECT_NAME <- "VHF"

### Verzeichnisse
# Verzeichnis für Zwischenergebnisse/Debug
OUTPUT_DIR_LOCAL <- paste0(OUTPUT_DIR_BASE, "/outputLocal/", PROJECT_NAME)
# Verzeichnis für Endergebnisse
OUTPUT_DIR_GLOBAL <- paste0(OUTPUT_DIR_BASE, "/outputGlobal/", PROJECT_NAME)
result_dir <- ifelse(DECENTRAL_ANALYSIS, OUTPUT_DIR_LOCAL, OUTPUT_DIR_GLOBAL)
# Output directories
output_local_errors <- paste0(OUTPUT_DIR_LOCAL, "/Errors")
output_local_bundles <- paste0(OUTPUT_DIR_LOCAL, "/Bundles")
# Error files
error_file <- list(
  main = paste0(output_local_errors, "/ErrorMessage.txt"),
  obs  = paste0(output_local_errors, "/ObservationError.xml"),
  enc  = paste0(output_local_errors, "/EncounterError.xml"),
  con  = paste0(output_local_errors, "/ConditionError.xml")
)
# Debug files
debug_dir_obs_bundles <- paste0(output_local_bundles, "/Observations")
debug_dir_enc_bundles <- paste0(output_local_bundles, "/Encounters")
debug_dir_con_bundles <- paste0(output_local_bundles, "/Conditions")

# Result files
retrieve_file <- list(
  cohort    = paste0(result_dir, "/Cohort.csv"),
  diagnoses = paste0(result_dir, "/Diagnoses.csv"),
  log       = paste0(OUTPUT_DIR_GLOBAL, "/Retrieval.log")
)

ERROR <- NA
tryCatch({
  # rename old dirs and create new ones  (surpress warning if dir exists)
  createDirWithBackup(OUTPUT_DIR_LOCAL)
  createDirWithBackup(OUTPUT_DIR_GLOBAL)
  createDirsRecursive(output_local_errors)
  createDirsRecursive(debug_dir_obs_bundles, debug_dir_enc_bundles, debug_dir_con_bundles, condition = DEBUG)
}, warning = function(w) {
  ERROR <<- paste0(w, 'At least one file in this folder is locked by a(nother) program.')
}, error = function(e) {
  ERROR <<- e
})
if (!all(is.na(ERROR))) {
  stop(ERROR)
}

# ensure profile Strings without leading or tailing whitespaces
PROFILE_ENC <- trimws(PROFILE_ENC)
PROFILE_OBS <- trimws(PROFILE_OBS)
PROFILE_CON <- trimws(PROFILE_CON)
ENCOUNTER_TYPE <- trimws(ENCOUNTER_TYPE)

#####################
# Chunk List Option #
#####################

# The urls in get requests have a maximum length of approx. 2000 characters.
# Depending on how the requests to the server are to be structured (option
# FHIR_SEARCH_SUBJECT_LIST_OPTION), it is specified here how many subject
# IDs are to come into a request at the same time and which strings are
# (must be) inserted in the request before and after the ID.

# option name | max IDs per chunk (if fits) | string after subject | string before every ID | string after every ID
CHUNK_LIST_OPTION <- c(
  "COMMA_SEPARATED_PURE_IDS",                      Inf,         "",         "", "%2C", # every comma after an ID will
  "COMMA_SEPARATED_PURE_IDS_WITH_SUBJECT_PATIENT", Inf, ":Patient",         "", "%2C", # be replaced by "%2C"
  "COMMA_SEPARATED_IDS_WITH_PATIENT_PREFIX",       Inf,         "", "Patient/", "%2C",
  "SINGLE_REQUEST_PER_ID",                           1,         "",         "",    "",
  "SINGLE_REQUEST_PER_ID_WITH_SUBJECT_PATIENT",      1, ":Patient",         "",    "",
  "SINGLE_REQUEST_PER_ID_WITH_PATIENT_PREFIX",       1,         "", "Patient/",    "",
  "IGNORE_IDS",                                      0,         "",         "",    ""
)
CHUNK_LIST_OPTION <- matrix(CHUNK_LIST_OPTION, length(CHUNK_LIST_OPTION) / 5, 5, byrow = TRUE)

# Row index of the choosed option in the above matrix 
chunkListOptionRowIndex <- match(FHIR_SEARCH_SUBJECT_LIST_OPTION, CHUNK_LIST_OPTION[, 1])

# the option was not found (probably typo in config.toml or .RProfile)
if (is.na(chunkListOptionRowIndex)) {
  logGlobalAndError("Ungültiger Wert für Parameter FHIR_SEARCH_SUBJECT_LIST_OPTION gefunden: ", FHIR_SEARCH_SUBJECT_LIST_OPTION)
  stop("No NTproBNP Observations found - aborting.")
}
# max number of IDs in one chunk (if it fits)
chunkListOptionMaxIDsPerChunk <- as.numeric(CHUNK_LIST_OPTION[chunkListOptionRowIndex, 2])
# string that will be added after "subject" and before "="
chunkListOptionSubjectSuffix <- as.character(CHUNK_LIST_OPTION[chunkListOptionRowIndex, 3])
# number of chars added to every ID in the request as prefix
chunkListOptionIDPrefix <- as.character(CHUNK_LIST_OPTION[chunkListOptionRowIndex, 4])
# number of chars added to every ID in the request as suffix
chunkListOptionIDSuffix <- as.character(CHUNK_LIST_OPTION[chunkListOptionRowIndex, 5])

# cleanup
rm(CHUNK_LIST_OPTION)
rm(chunkListOptionRowIndex)

#################
# Log Functions #
#################

#'
#' Logs the given arguments to the global log file and via message()
#'
logGlobal <- function(..., append = TRUE) {
  logText <- paste0(...)
  write(logText, file = retrieve_file$log, append = append)
  message(logText)
}

#'
#' Logs the given arguments to the error file and optionally via message()
#'
logError <- function(..., append = TRUE, message = TRUE) {
  logText <- paste0(...)
  write(logText, file = error_file$main, append = append)
  if (message) {
    message(logText)
  }
}

#'
#' Logs the given arguments to the global log file and via message()
#' and in the error file.
#'
logGlobalAndError <- function(...) {
  logGlobal(...)
  logError(..., message = FALSE)
}

# counts how many error logs are written to the error file
errorLogCount <- 0
# log only the first 100 observation errors
maxErrorLogCount <- 100

#'
#' Logs the message and the dataTable. If this function is called more than 100 times
#' then nothing will be logged anymore.
#' 
#' @param message
#' @param dataTable
#'
logErrorMax100 <- function(message, dataTable) {
  if (errorLogCount < maxErrorLogCount) {
    logError(message)
    logError(paste(names(dataTable[i]), dataTable[i]), sep = " ")
  } else if (errorLogCount == maxErrorLogCount) {
    logError("More errors of the same type have occurred -> stop logging these errors...")
  }
  errorLogCount <<- errorLogCount + 1
}

#########
# Utils #
#########

#'
#' @param dateStringWithLeadingYear a string representing a date or only a year. The year must be the
#' first 4 characters of the string.
#' @return the extracted year from the given date string
#'
getYear <- function(dateStringWithLeadingYear) {
  date <- as.POSIXct(as.character(dateStringWithLeadingYear), format = "%Y")
  return (year(date))
}

####################################
# Absolute to Relative ID Function #
####################################

#'
#' @param references single string or list of strings
#' @return single string or list of strings where only the last part of each string
#' remains after a slash '/'. Strings without slashes are returned unchanged.
#'
makeRelative <- function(references) {
  return(sub(".*/", "", references))
}

####################################
# fhir search convenience function #
####################################

#'
#' Convenience function to call fhircrackr::fhir_search with
#' the global fhir server settings.
#'
#' @param request
#' @param erroor_file
#' @param max_bundles
#'
fhirSearch <- function(request, error_file, max_bundles = Inf) {
  fhir_search(
    request = request,
    username = FHIR_SERVER_USER,
    password = FHIR_SERVER_PASS,
    token = FHIR_SERVER_TOKEN,
    log_errors = error_file,
    verbose = VERBOSE,
    max_bundles = max_bundles
  )
}

#####################
# Create PID Chunks #
#####################
# FHIR_SEARCH_SUBJECT_LIST_OPTION
# -------------------------------
# COMMA_SEPARATED_PURE_IDS
#    $fhirServerEndpoint/Encounter?subject=PID01,PID02,PID...&type=einrichtungskontakt&_profile=$PROFILE_ENC
#    $fhirServerEndpoint/Condition?subject=PID01,PID02,PID...&_profile=$PROFILE_CON
# COMMA_SEPARATED_PURE_IDS_WITH_SUBJECT_PATIENT
#    $fhirServerEndpoint/Encounter?subject:Patient=PID01,PID02,PID...&type=einrichtungskontakt&_profile=$PROFILE_ENC
#    $fhirServerEndpoint/Condition?subject:Patient=PID01,PID02,PID...&_profile=$PROFILE_CON
# COMMA_SEPARATED_IDS_WITH_PATIENT_PREFIX
#    $fhirServerEndpoint/Encounter?subject=Patient/PID01,Patient/PID02&...&type=einrichtungskontakt&_profile=$PROFILE_ENC
#    $fhirServerEndpoint/Condition?subject=Patient/PID01,Patient/PID02&...&_profile=$PROFILE_CON
# SINGLE_REQUEST_PER_ID:
#    $fhirServerEndpoint/Encounter?subject=PID01&type=einrichtungskontakt&_profile=$PROFILE_ENC
#    $fhirServerEndpoint/Condition?subject=PID01&_profile=$PROFILE_CON
# SINGLE_REQUEST_PER_ID_WITH_SUBJECT_PATIENT:
#    $fhirServerEndpoint/Encounter?subject:Patient=PID01&type=einrichtungskontakt&_profile=$PROFILE_ENC
#    $fhirServerEndpoint/Condition?subject:Patient=PID01&_profile=$PROFILE_CON
# SINGLE_REQUEST_PER_ID_WITH_PATIENT_PREFIX:
#    $fhirServerEndpoint/Encounter?subject=Patient/PID01&type=einrichtungskontakt&_profile=$PROFILE_ENC
#    $fhirServerEndpoint/Condition?subject=Patient/PID01&_profile=$PROFILE_CON
# IGNORE_IDS:
#    $fhirServerEndpoint/Encounter?einrichtungskontakt&_profile=$PROFILE_ENC
#    $fhirServerEndpoint/Condition?_profile=$PROFILE_CON

#'
#' Splits the patient id list into smaller chunks that can be used in a GET url
#' (split because we don't want to exceed allowed URL length)
#' remaining number of characters in the url that can be used for patient IDs
#' (assume maximal length of MAX_REQUEST_STRING_LENGTH)
#' @return the number patient IDs so that the request fits the maximum length of MAX_REQUEST_STRING_LENGTH
#'
#'
getPatientIDChunkSize <- function(allPatientIDs) {
  # The magic number 10 means that we assume that at least
  # 10 IDs can be contained in a chunk and that the search
  # query will not exceed the length of about 2000.
  patientIDsChunkSize <- chunkListOptionMaxIDsPerChunk
  if (patientIDsChunkSize > 10) {
    profile <- ifelse(nchar(PROFILE_ENC) > nchar(PROFILE_CON), PROFILE_ENC, PROFILE_CON)
    
    # maximum lenght of all parts of a paged query
    fixLength <- nchar(fhir_server_url) + 1 + # the url with a slash
      nchar("/Encounter/__page?subject=") +   # fix part after url ("Condition" has the same lenght like "Encounter")
      nchar(chunkListOptionSubjectSuffix) +        # ":Patient" after subject or empty string
      nchar("&type=einrichtungskontakt") +    # parameter for encounters
      nchar("&_profile") + nchar(profile) +   # the full profile length
      countCharInString(profile, "/") * 2 +   # "/" will be replaced by "%2F" -> count * 2
      countCharInString(profile, ":") * 2 +   # ":" will be replaced by "%3A" -> count * 2
      nchar("&_count=1000&__t=1000000&__page-id=EncounterID_ABCDEFGHIJKLMNOPQRSTUVWXYZ") # Something like this will be
                                                                                         # added to every paging query.
                                                                                         # The values here are super large.
                                                                                         # Realistic values should be 
                                                                                         # shorter.
    ncharForAllIDs <- MAX_REQUEST_STRING_LENGTH - fixLength
    maxSingleIDLength <- nchar(chunkListOptionIDPrefix) + max(nchar(allPatientIDs)) + nchar(chunkListOptionIDSuffix)
    patientIDsChunkSize <- ncharForAllIDs / maxSingleIDLength
  }
  return (patientIDsChunkSize)
}


##############
# SSL Veryfy #
##############

# If needed disable peer verification
if (!SSL_VERIFY) {
  httr::set_config(httr::config(ssl_verifypeer = 0L))
}

##################
# Start Download #
##################

logGlobal("main.R startet at ", start, ".\n")

# reset Error file
logError("Errors in Retrieval from ", Sys.time(), ":", append = FALSE, message = FALSE)

# remove trailing slashes from endpoint
fhir_server_url <-
  if (startsWith(FHIR_SERVER_ENDPOINT, "/")) {
    strtrim(FHIR_SERVER_ENDPOINT, width = nchar(FHIR_SERVER_ENDPOINT) - 1)
  } else {
    FHIR_SERVER_ENDPOINT
  }

# Brackets around indexes for nested values after fhir_crack()
brackets <- c("[", "]")
sep <- " || "

### Get all Observations between 2019-01-01 and 2021-12-31 with loinc 33763-4,71425-3,33762-6,83107-3, 83108-1, 77622-9,77621-1
# also get associated patient resources --> initial patient population
# Observations have to implement MII profile
# TODO: weitere LOINC Codes ergänzen zB für proBNP
parameters = c(
  "code" = paste0(
    "http://loinc.org|33763-4,",
    "http://loinc.org|71425-3,",
    "http://loinc.org|33762-6,",
    "http://loinc.org|83107-3,",
    "http://loinc.org|83108-1,",
    "http://loinc.org|77622-9,",
    "http://loinc.org|77621-1"),
  "date" = "ge2019-01-01",
  "date" = "le2022-12-31"
)
# add profile from config if not empty
if (PROFILE_OBS != "") parameters <- c(parameters, "_profile" = PROFILE_OBS)
# include patients of observation
parameters <- c(
  parameters,
  "_include" = "Observation:patient", 
  "_count" = BUNDLE_RESOURCES_COUNT
)

obs_request <- fhir_url(url = fhir_server_url, resource = "Observation", parameters = parameters)

# download bundles
message("Downloading Observations: ", obs_request, "\n")
obs_bundles <- fhirSearch(obs_request, error_file$obs, MAX_BUNDLES)

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
    encounter.id = "encounter/reference",
    NTproBNP.valueQuantity.value = "valueQuantity/value",
    NTproBNP.valueQuantity.comparator = "valueQuantity/comparator",
    NTproBNP.valueCodeableConcept.code = "valueCodeableConcept/coding/code",
    NTproBNP.valueCodeableConcept.system = "valueCodeableConcept/coding/system",
    NTproBNP.code = "code/coding/code",
    NTproBNP.codeSystem = "code/coding/system",
    NTproBNP.unit = "valueQuantity/code", # should be the SI unit
    NTproBNP.unitLabel = "valueQuantity/unit", # some DIZ write the SI unit not
                                               # in the "valueQuantity/code"
                                               # but in this field which should
                                               # be used in FHIR as a human
                                               # readable unit description !?
    NTproBNP.unitSystem = "valueQuantity/system"
  )
)

pat_description <- fhir_table_description(
  "Patient",
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
  logGlobalAndError("Konnte keine Observations für NTproBNP auf dem Server finden. Abfrage abgebrochen.")
  stop("No NTproBNP Observations found - aborting.")
}

if (nrow(obs_tables$pat) == 0) {
  logGlobalAndError("Konnte keine Patientenressourcen für NTproBNP-Observations auf dem Server finden. Abfrage abgebrochen.")
  stop("No Patients for NTproBNP Observations found - aborting.")
}

# remove indices in sub table pat in obs_tables
obs_tables$pat <- fhir_rm_indices(obs_tables$pat, brackets = brackets)

# expand multiple cell values to multiple lines
for (i in 1 : 2) {
  obs_tables$obs <- fhir_melt(
    obs_tables$obs,
    columns = c("NTproBNP.code", "NTproBNP.codeSystem"),
    brackets = brackets,
    sep = sep,
    all_columns = TRUE
  )
}
# remove remaining indices
obs_tables$obs <- fhir_rm_indices(obs_tables$obs, brackets = brackets)

# remove the resource_identifier inserted by fhir_melt
obs_tables$obs[, resource_identifier := NULL]

# get rid of resources that have been downloaded multiple times via _include
obs_tables$pat <- unique(obs_tables$pat)

### Prepare Patient id from initial patient population for Search requests that
### download associated resources (e.g. consent, encounters, conditions)

### merge observation and patient data
# prepare key variables for merge
obs_tables$obs[, subject := makeRelative(subject)]
obs_tables$obs[, encounter.id := makeRelative(encounter.id)]

# check if all patients referenced by observations
# could be really loaded as patient resource ->
# if not then remove observations with invalid patient refs
invalidPatRefs  <- setdiff(obs_tables$obs$subject, obs_tables$pat$id)
if (length(invalidPatRefs) > 0) {
  logError("Could not resolve Patient ID references from Observations:")
  for (i in 1 : length(invalidPatRefs)) {
    logError("   ", i, ": ", invalidPatRefs[i])
  }
  obsCount <- nrow(obs_tables$obs)                                 # number of all observations
  patRefsInObs <- length(unique(obs_tables$obs$subject))           # number of unique patient refs in observations
  obs_tables$obs <- obs_tables$obs[!(subject %in% invalidPatRefs)] # remove observations with unresolvable patient refs
  obsCountWithValidPatRefs <- nrow(obs_tables$obs)                 # number of observations with resolvable patient refs
  validPatRefsInObs <- length(unique(obs_tables$obs$subject))      # number of unique resolvable patient refs in observations
  if (obsCount != obsCountWithValidPatRefs) {
    logGlobal("Removed Observations with invalid Patient references: ", obsCount - obsCountWithValidPatRefs, " of ", obsCount)
  }
}

# backup the NTproBNP.date as date string with day and time
# after conversion as.Date(...) the day remains but the time is lost
#obs_tables$obs$NTproBNP.date.bak <- as.POSIXct(obs_tables$obs$NTproBNP.date, format = "%Y-%m-%dT%H:%M:%S")
obs_tables$obs[, NTproBNP.date := as.Date(NTproBNP.date)]

# merge
logGlobal("Merging Observation and Patient data based on Patient id:")
logGlobal("Number of unique Patient ids in Patient data: ", length(unique(obs_tables$pat$id)), " in ", nrow(obs_tables$pat), " rows")
logGlobal("Number of unique Patient ids in Observation data: ", length(unique(obs_tables$obs$subject)), " in ", nrow(obs_tables$obs), " rows\n")

observations <- merge.data.table(
  x = obs_tables$obs,
  y = obs_tables$pat,
  by.x = "subject",
  by.y = "id",
  all.x = TRUE
)

rm(obs_tables)

# get patient IDs in chunks of the maximum list length for page queries
patientIDs <- unique(observations$subject)
logGlobal("Number of unique Patient ids in merged table: ", length(patientIDs), " in ", length(observations$subject), " rows")
patientIDChunkSize <- as.integer(getPatientIDChunkSize(patientIDs))
logGlobal("Patient ID Chunk Size in request: ", patientIDChunkSize)

# get encounters and diagnoses
# --> all encounters and diagnoses of initial patient population,
# has be filtered to only include encounters with NTproBNP Observation later on
encounter_bundles <- list()
condition_bundles <- list()

message("Downloading Encounters and Conditions.\n")

invisible({

  # get the maximum number of subject IDs for a single request
  patientIDCount <- length(patientIDs)
  chunkCount <- ifelse(patientIDChunkSize > 0, as.integer(patientIDCount / patientIDChunkSize) + 1, NA) 
  
  ignoreIDs <- is.na(chunkCount)
  if (ignoreIDs) chunkCount <- 1
  
  idStartIndex <- 1
  idEndIndex <- patientIDChunkSize

  for (chunkIndex in 1 : chunkCount) {

    if (idStartIndex <= patientIDCount) {
      if (idEndIndex > patientIDCount) {
        idEndIndex <- patientIDCount
      }
  
      ### Encounters
      parameters <- c()
      # append subject IDs as parameter if they should not be ignored
      if (!ignoreIDs) {
        idChunk <- patientIDs[c(idStartIndex : idEndIndex)]
        ids <- paste(paste0(chunkListOptionIDPrefix, idChunk), collapse = chunkListOptionIDSuffix)
        parameters <- c(subject = ids)
        # change the name of the list element if needed (from "subject" to "subject:Patient")
        if (nchar(chunkListOptionSubjectSuffix) > 0) names(parameters)[1] <- paste0("subject", chunkListOptionSubjectSuffix)
      }
      # add type parameter for encounters
      if (ENCOUNTER_TYPE != "") parameters <- c(parameters, "type" = ENCOUNTER_TYPE)
      # add profile from config if not empty
      if (PROFILE_ENC != "") parameters <- c(parameters, "_profile" = PROFILE_ENC)
      # add count parameter
      parameters <- c(parameters, c("_count" = BUNDLE_RESOURCES_COUNT))                                                  
      
      enc_request <- fhir_url(url = fhir_server_url, resource = "Encounter", parameters = parameters)
      encounter_bundles <<- append(encounter_bundles, fhirSearch(enc_request, error_file$enc))

      ### Conditions
      parameters <- c()
      if (!ignoreIDs) {
        parameters <- c(subject = ids)
        # change the name of the list element if needed (from "subject" to "subject:Patient")
        if (nchar(chunkListOptionSubjectSuffix) > 0) names(parameters)[1] <- paste0("subject", chunkListOptionSubjectSuffix)
      }
      # add profile from config if not empty
      if (PROFILE_CON != "") parameters <- c(parameters, "_profile" = PROFILE_CON)
      # add count parameter
      parameters <- c(parameters, c("_count" = BUNDLE_RESOURCES_COUNT))                                                  
      
      con_request <- fhir_url(url = fhir_server_url, resource = "Condition", parameters = parameters)
      condition_bundles <<- append(condition_bundles, fhirSearch(con_request, error_file$con))

      idStartIndex <- idEndIndex + 1
      idEndIndex <- idStartIndex + patientIDChunkSize - 1
    }
  }

})

# bring encounter results together, save and flatten
encounter_bundles <- fhircrackr:::fhir_bundle_list(encounter_bundles)
condition_bundles <- fhircrackr:::fhir_bundle_list(condition_bundles)

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

if (nrow(encounters) == 0) {
  logGlobalAndError( "Konnte keine Encounter-Ressourcen zu den gefundenen Patients finden. Abfrage abgebrochen.")
  stop("No Encounters for Patients found - aborting.")
}

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


### generate conditions table --> has all conditions of all Patients in the initial population
if (nrow(conditions) > 0) {
  #extract diagnosis use info from encounter table
  useInfo <- fhir_melt(
    encounters,
    columns = c("diagnosis", "diagnosis.use.code", "diagnosis.use.system"),
    brackets = brackets,
    sep = sep,
    all_columns = TRUE
  )
  
  useInfo <- fhir_rm_indices(useInfo, brackets = brackets)

  useInfo <- useInfo[, c("encounter.id", "diagnosis", "diagnosis.use.code","diagnosis.use.system")]

  useInfo[, diagnosis := makeRelative(diagnosis)]

  # expand condition codes + remove indices
  for (i in 1 : 2) {
    conditions <- fhir_melt(
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
  logGlobal("Merging Condition and Encounter data based on Condition id:")
  logGlobal("Number of unique Condition ids in Condition data: ", length(unique(conditions$condition.id)), " in ", nrow(conditions), " rows")
  logGlobal("Number of unique Condition ids in Encounter data: ", length(unique(useInfo$diagnosis)), " in ", nrow(useInfo), " rows\n")

  conditions <- merge.data.table(
    x = conditions,
    y = useInfo,
    by.x = "condition.id",
    by.y = "diagnosis",
    all.x = TRUE
  )

  # prepare key variables for merge (removing ID prefixes caused by join)
  conditions[, subject := makeRelative(subject)]
  conditions[, encounter := makeRelative(encounter)]

  # fill empty values in column encounter.id with the value of column encounter
  # (which are the encounter IDs from the condition.encounter)
  conditions[is.na(encounter.id), encounter.id := encounter]
  conditions[, encounter := NULL]
}

### prepare encounter table ###

# remove diagnosis info clumns and indices
encounters[, c("diagnosis", "diagnosis.use.code", "diagnosis.use.system") := NULL]
encounters <- fhir_rm_indices(encounters, brackets = brackets)

# prepare key variable for merge (removing ID prefixes caused by join)
encounters[, subject := makeRelative(subject)]

# sort out col types
encounters[, encounter.start := as.Date(encounter.start)]
encounters[, encounter.end := as.Date(encounter.end)]

# merge based on subject id and temporal relation of observation date and encounter times
logGlobal("Merging Observation and Encounter data based on Subject id and time:")
logGlobal("Number of unique Subject ids in Observation data: ", length(unique(observations$subject)), " in ", nrow(observations), " rows")
logGlobal("Number of unique Subject ids in Encounter data: ", length(unique(encounters$subject)), " in ", nrow(encounters), " rows\n")

# Try to find the encounter to the observations via date check.
# This check only considers the start date of all encounters
# of the patient with the current observation and tries to find
# the closest start date of all encounters in the past. 
for(i in 1 : nrow(observations)) {
 
  observationEncounter <- data.table()

  encounterID <- observations[i, encounter.id]
  if (!is.na(encounterID)) {
    observationEncounter <- encounters[encounter.id == encounterID]
    if (nrow(observationEncounter) > 0) {
      observationEncounter <- observationEncounter[1]
    }
  }

  # found no encounter by its ID?
  if (nrow(observationEncounter) == 0) {
    # get the observation date of the current observation i
    obs_date <- observations[i, NTproBNP.date]
    # get all encounters for the patient with the current observation
    obs_subject_encounters <- encounters[subject == observations[i, subject]]

    # there are two possible errors at this point
    # 1. No encounter found for the given patient ID (this is a real error that should never happen).
    #    In this case nrow(obs_subject_encounters) == 0
    #    -> Log an Error
    # 2. The encounter has no start date -> the script will crash at 'if (closest_date_diff != Inf) {'
    #    -> We try to find the encounter via the 'encounter' column (= Encounter ID) in the observation table 
    #    -> If there is no Counter ID or no Encounter for this ID
    #    -> Log an Error
    
    if (nrow(obs_subject_encounters) == 0) {
      logErrorMax100("There is no Encounter for Observation:", observations)
      next
    }

    # get a list of all differences between the observation date and
    # the encounter start date
    obs_enc_date_diffs <- obs_date - obs_subject_encounters$encounter.start
    
    obs_enc_date_diffs <- obs_enc_date_diffs[!is.na(obs_enc_date_diffs)]
    
    if (length(obs_enc_date_diffs) == 0) {
      logErrorMax100(
        "Observation has no Encounter Reference and all Encounters of the Patient of the Observation have no start date -> can not find Encounter for Observation:",
        observations
      )
      next
    }
    
    # if there were encounter start dates after the observation date
    # then set them to the maximum distance to the observation date
    obs_enc_date_diffs[obs_enc_date_diffs < 0] <- Inf
    # find the index of the encounter date with the minimum distance
    # to the observation date
    closest_date_diff_index <- which.min(obs_enc_date_diffs)
    # get this nearest encounter date
    closest_date_diff <- obs_enc_date_diffs[closest_date_diff_index]
    # if the result date was not in the future (could be if all encounter
    # dates are invalid in relation to the observation date)
    if (closest_date_diff != Inf) {
      # find the corresponding encounter and merge its properties
      # to new columns in the observation table
      observationEncounter <- obs_subject_encounters[closest_date_diff_index, ]
    }
  }
  
  if (nrow(observationEncounter) > 0) { # should alway be 1 row here, but sure is...
    observations[i, encounter.id := observationEncounter$encounter.id[1]]
    observations[i, encounter.start := observationEncounter$encounter.start[1]]
    observations[i, encounter.end := observationEncounter$encounter.end[1]]
  }  

}


# the observation table with encounters is now our cohort table
cohort <- observations # it's a copy by reference (type is data.table)
rm(observations)

# filter conditions: only keep conditions belonging to the encounters we have just filtered
if (nrow(conditions) > 0) {
  conditions <- conditions[encounter.id %in% cohort$encounter.id]
}

# calculate age by birthdate and NTproBNP date 
cohort$age <- getYear(cohort$NTproBNP.date) - getYear(cohort$birthdate)
# remove the date column
cohort[, NTproBNP.date := NULL]
# remove the birthdate column
cohort[, birthdate := NULL]

# Write result files
write.csv2(cohort, retrieve_file$cohort, row.names = FALSE)
write.csv2(conditions, retrieve_file$diagnoses, row.names = FALSE)

# logging
runtime <- Sys.time() - start

logGlobal("main.R finished at ", Sys.time(), ".")
logGlobal("Extracted ", length(cohort$encounter.id), " Encounters based on ", length(unique(cohort$subject)), " Patients.")
logGlobal("R script execution took ", round(runtime, 2), " ", attr(runtime, "units"), ".")
