# Konfigurations-Datei für Vorhofflimmern Retrieval
# Bitte die folgenden Variablen entsprechend der Gegebenheiten vor Ort anpassen!

emptyToNull <- function(v) {
  if (v == '') return(NULL) else return(v)
}

# FHIR-Endpunkt
#base <- "http://host.docker.internal:8080/fhir"
FHIR_SERVER_ENDPOINT <- Sys.getenv('FHIR_SERVER_ENDPOINT')

### Authentifizierung
# Falls Authentifizierung, bitte entsprechend anpassen (sonst ignorieren):
# Username und Passwort für Basic Authentification
FHIR_SERVER_USER <- emptyToNull(Sys.getenv('FHIR_SERVER_USER')) # zB "myusername"
FHIR_SERVER_PASS <- emptyToNull(Sys.getenv('FHIR_SERVER_PASS')) #zB "mypassword"

# Alternativ: Token für Bearer Token Authentifizierung
FHIR_SERVER_TOKEN <- emptyToNull(Sys.getenv('FHIR_SERVER_TOKEN')) #zB "mytoken"

# SSL peer verification angeschaltet lassen?
# TRUE = peer verification anschalten, FALSE = peer verification ausschalten
SSL_VERIFY <- as.logical(Sys.getenv('SSL_VERIFY', "TRUE"))

# Wenn true (= dezentrale Analyse im DIZ), dann wird die Analyse nach dem
# Retrieval ausgeführt und nur die Ergebnisse der Analyse ins
# outputGlobal-Verzeichnis kopiert.
# Wenn false (= zentrale Analyse), dann wird die Analyse nicht automatisch nach
# dem Retrieval ausgefüht, sondern die Ergebnisse des Retrieval in das
# auszuleitenden outputGlobal-Verzeichnis gelegt.
DECENTRAL_ANALYSIS <- as.logical(Sys.getenv('DECENTRAL_ANALYSIS', "TRUE"))

# Das Script lädt zuerst alle passenden Observations, davon ausgehend
# die zugehörigen Patienten und Conditions.
# Inf = alle Observation Bundles, ansonsten wird maximal die gegebene Anzahl geladen
MAX_BUNDLES <- as.double(Sys.getenv('MAX_BUNDLES', "Inf"))

# Anzahl der Resources pro Bundle. Wird als "&_count="-Parameter an die 
# fhir_search()-Requests gehängt. Dieser Parameter wird eventuell vom Server
# ignoriert oder beschränkt. Hapi hat per Default 20, Blaze 50. Ein anderer
# Wert hat beim Blaze aber keinerlei Vorteile oder Nachteile in der Laufzeit
# ergeben. Nur beim Testen dauert es eben länger, wenn man 100 Resources
# pro Bundle lädt oder nur 20.
BUNDLE_RESOURCES_COUNT <- as.numeric(Sys.getenv('BUNDLE_RESOURCES_COUNT', 50))

# Maximale Gesamtlänge eines get-Requests, der an den Server geschickt wird. Diese
# Länge wird definitiv niemals erreicht/überschritten. Dieser Parameter entscheidet
# darüber, wieviele subject-IDs tatsächlich gleichzeitig in einen Request gepackt
# werden, wenn bei FHIR_SEARCH_SUBJECT_LIST_OPTION eine Option gewählt wurde, bei
# der mehr als eine ID im Request steht. Der Wert hier ist durch Testen herausgefunden
# worden und kann auf einem speziellen Server anders sein.
MAX_REQUEST_STRING_LENGTH <- as.numeric(Sys.getenv('MAX_REQUEST_STRING_LENGTH', 2048))

# Debug = TRUE -> Bundles werden in outputLocal gespeichert
DEBUG <- as.logical(Sys.getenv('DEBUG', "FALSE"))
# Verbose-Level des fhircrackr
VERBOSE <- as.integer(Sys.getenv('VERBOSE', "0"))

# Directory where 'outputLocal' and 'outputGlobal' directories are located 
OUTPUT_DIR_BASE <- Sys.getenv('OUTPUT_DIR_BASE', '.')

### Profile, der gesuchten Resourcen:
# Encounter
PROFILE_ENC <- Sys.getenv("PROFILE_ENC",
                          "https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung")
# Observation
PROFILE_OBS <- Sys.getenv("PROFILE_OBS",
                          "https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab")
# Condition
PROFILE_CON <- Sys.getenv("PROFILE_CON",
                          "https://www.medizininformatik-initiative.de/fhir/core/modul-diagnose/StructureDefinition/Diagnose")

# Option for the structure of subject IDs in fhir_search(...) requests
FHIR_SEARCH_SUBJECT_LIST_OPTION <- Sys.getenv("FHIR_SEARCH_SUBJECT_LIST_OPTION",
                                              "COMMA_SEPARATED_PURE_IDS")

### Log Parameters to Console
message("Run Retrieval with Parameters:")
message("------------------------------")
message(paste0("           FHIR_SERVER_ENDPOINT = ", FHIR_SERVER_ENDPOINT))
message(paste0("               FHIR_SERVER_USER = ", ifelse(nchar(FHIR_SERVER_USER) > 0, "not empty username", "empty username")))
message(paste0("               FHIR_SERVER_PASS = ", ifelse(nchar(FHIR_SERVER_PASS) > 0, "not empty password", "empty password")))
message(paste0("              FHIR_SERVER_TOKEN = ", ifelse(nchar(FHIR_SERVER_TOKEN) > 0, "not empty token", "empty token")))
message(paste0("                     SSL_VERIFY = ", SSL_VERIFY))
message(paste0("             DECENTRAL_ANALYSIS = ", DECENTRAL_ANALYSIS))
message(paste0("                    MAX_BUNDLES = ", MAX_BUNDLES))
message(paste0("         BUNDLE_RESOURCES_COUNT = ", BUNDLE_RESOURCES_COUNT))
message(paste0("      MAX_REQUEST_STRING_LENGTH = ", MAX_REQUEST_STRING_LENGTH))
message(paste0("                          DEBUG = ", DEBUG))
message(paste0("                        VERBOSE = ", VERBOSE))
message(paste0("                OUTPUT_DIR_BASE = ", OUTPUT_DIR_BASE))
message(paste0("                    PROFILE_ENC = ", PROFILE_ENC))
message(paste0("                    PROFILE_OBS = ", PROFILE_OBS))
message(paste0("                    PROFILE_CON = ", PROFILE_CON))
message(paste0("FHIR_SEARCH_SUBJECT_LIST_OPTION = ", FHIR_SEARCH_SUBJECT_LIST_OPTION))

