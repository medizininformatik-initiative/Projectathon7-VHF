# Konfigurations-Datei für Vorhofflimmern Retrieval
# Bitte die folgenden Variablen entsprechend der Gegebenheiten vor Ort anpassen!

# FHIR-Endpunkt
#base <- "http://host.docker.internal:8080/fhir" 
FHIR_SERVER_URL <- "https://mii-agiop-polar.life.uni-leipzig.de/fhir"

### Authentifizierung
# Falls Authentifizierung, bitte entsprechend anpassen (sonst ignorieren):
# Username und Passwort für Basic Authentification
FHIR_SERVER_USERNAME <- "" # zB "myusername"
FHIR_SERVER_PASSWORD <- "" #zB "mypassword"

# Alternativ: Token für Bearer Token Authentifizierung
FHIR_SERVER_TOKEN <- NULL #zB "mytoken"

### Verzeichnisse
# Verzeichnis für Zwischenergebnisse/Debug
OUTPUT_DIR_LOCAL <- "outputLocal"
# Verzeichnis für Endergebnisse
OUTPUT_DIR_GLOBAL <- "outputGlobal"

# SSL peer verification angeschaltet lassen?
# TRUE = peer verification anschalten, FALSE = peer verification ausschalten 
OPTION_SSL_VERIFY_PEER <- TRUE

# Das Script lädt zuerst alle passenden Observations, davon ausgehend
# die zugehörigen Patienten und Conditions.
# Inf = alle Observation Bundles, ansonsten wird maximal die gegebene Anzahl geladen
OPTION_MAX_OBSERVATION_BUNLDES = 30
# Debug = TRUE -> Bundles werden in outputLocal gespeichert
OPTION_DEBUG = TRUE
# Verbose-Level des fhircrackr
OPTION_FHIRCRACKR_VERBOSE_LEVEL = 0

### Profile, der gesuchten Resourcen:
#Encounter 
PROFILE_ENC <- "&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung"

#Observation
PROFILE_OBS <- "&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab"

#Condition
PROFILE_CON <- "&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-diagnose/StructureDefinition/Diagnose"