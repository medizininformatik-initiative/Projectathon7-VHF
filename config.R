# Konfigurations-Datei für Projectathon Select-Abfrage
# Bitte die folgenden Variablen entsprechend der Gegebenheiten vor Ort anpassen!


# FHIR-Endpunkt
base <- "http://host.docker.internal:8080/fhir" 

# SSL peer verification angeschaltet lassen?
# TRUE = peer verification anschalten, FALSE = peer verification ausschalten 
ssl_verify_peer <- TRUE

### Authentifizierung

# Falls Authentifizierung, bitte entsprechend anpassen (sonst ignorieren):
# Username und Passwort für Basic Authentification
username <- ""#zB "myusername"
password <- ""#zB "mypassword"

# Alternativ: Token für Bearer Token Authentifizierung
token <- NULL #zB "mytoken"


filterConsent <- FALSE
#Encounter 
enc_profile <- "&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung"

#Observation
obs_profile <- "&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab"

#Condition
con_profile <- "&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-diagnose/StructureDefinition/Diagnose"