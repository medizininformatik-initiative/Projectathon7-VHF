# Konfigurations-Datei für Vorhofflimmern Retrieval
# Bitte die folgenden Variablen entsprechend der Gegebenheiten vor Ort anpassen!

# FHIR-Endpunkt
#base <- "http://host.docker.internal:8080/fhir" 
FHIR_SERVER_ENDPOINT <- Sys.getenv('FHIR_SERVER_ENDPOINT')

### Authentifizierung
# Falls Authentifizierung, bitte entsprechend anpassen (sonst ignorieren):
# Username und Passwort für Basic Authentification
FHIR_SERVER_USER <- Sys.getenv('FHIR_SERVER_USER') # zB "myusername"
FHIR_SERVER_PASS <- Sys.getenv('FHIR_SERVER_PASS') #zB "mypassword"

# Alternativ: Token für Bearer Token Authentifizierung
FHIR_SERVER_TOKEN <- Sys.getenv('FHIR_SERVER_TOKEN') #zB "mytoken"

# SSL peer verification angeschaltet lassen?
# TRUE = peer verification anschalten, FALSE = peer verification ausschalten 
SSL_VERIFY <- as.logical(Sys.getenv('SSL_VERIFY', "TRUE"))

# Das Script lädt zuerst alle passenden Observations, davon ausgehend
# die zugehörigen Patienten und Conditions.
# Inf = alle Observation Bundles, ansonsten wird maximal die gegebene Anzahl geladen
MAX_BUNLDES <- as.integer(Sys.getenv('MAX_BUNLDES', "30"))
# Debug = TRUE -> Bundles werden in outputLocal gespeichert
DEBUG <- as.logical(Sys.getenv('DEBUG', "TRUE"))
# Verbose-Level des fhircrackr
VERBOSE <- as.integer(Sys.getenv('VERBOSE', "0"))

### Profile, der gesuchten Resourcen:
#Encounter 
PROFILE_ENC <- Sys.getenv("PROFILE_ENC",
                          "https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung")
#Observation
PROFILE_OBS <- Sys.getenv("PROFILE_OBS",
                          "https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab")
#Condition
PROFILE_CON <- Sys.getenv("PROFILE_CON",
                          "https://www.medizininformatik-initiative.de/fhir/core/modul-diagnose/StructureDefinition/Diagnose")
