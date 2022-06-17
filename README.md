# Selectanfrage für den 6. Projectathon der MII: SMITH
Datum: 28.03.22

Autorin: [julia.palm@med.uni-jena.de](mailto:julia.palm@med.uni-jena.de).

*Für eine Dokumentation der Änderungen, die seit Veröffentlichung des Skriptes gemacht wurden, siehe ganz unten.*

## Einführung

Dieses Projekt führt die Select-Anfrage für das SMITH Projekt im Rahmen des 6. Projectathons aus. Hier ist eine zentrale Analyse vorgesehen. Dafür erzeugt dieses Skript zwei Tabellen mit den für die Analyse benötigten Inhalten. Diese Tabellen sollen zentral zusammengeführt und an die datenauswertendende Stelle übergeben werden.

Das Readme beschreibt zunächst die technischen Details der Verwendung. Darunter sind die verwendeten CodeSysteme/Ressourcen/Profile und der konzeptionelle Ablauf der Abfrage beschrieben.

## Verwendung
Es gibt zwei Möglichkeiten diese R-Skripte auszuführen: Direkt in R oder in einem Docker Container. Beide werden im folgenden beschrieben.

### Ausführung in R
#### Vor der ersten Nutzung
1. Um die Selectanfrage durchzuführen, muss der Inhalt des Git-Repository auf einen Rechner (PC, Server) gezogen werden, von dem aus der REST-Endpunkt des gewünschten FHIR-Servers (z.B. FHIR-Server der Clinical Domain im DIZ) erreichbar ist. 

2. Auf diesem Rechner muss R (aber nicht notwendigerweise RStudio) als genutzte Laufzeitumgebung installiert sein.

3. Die mitgelieferte Datei `./config.R.default` muss nach `./config.R` kopiert werden und lokal angepasst werden (FHIR-Endpunkt, ggf. Authentifizierung, SSL peer verification); Erklärungen dazu finden sich direkt in dieser Datei. Eine Authentifizierung mit Basic Authentication oder Bearer Token ist möglich. Dafür müssen in `config.R` die Variable `authentication` und die zugehörigen Zugangsdaten (`password`/`username` bzw. `token`) angepasst werden.
Wenn die Abfrage auf einem Server laufen sollen, der sowohl konsentierte als auch nicht konsentierte Daten enthält, so kann durch setzen der Variable `filterConsent <- TRUE` dafür gesorgt werden, dass nur Daten von Patienten extrahiert werden, auf die eine Consent-Ressource mit einem `2.16.840.1.113883.3.1937.777.24.5.3.8` (*MDAT_wissenschaftlich_nutzen_EU_DSGVO_NIVEAU*) Code verweist.  
Außerdem kann über die Variablen `enc_profile`, `obs_profile` und `con_profile` das Profil angepasst werden, für das beim Download gefiltert wird, bzw. durch `NULL` setzen dieser Variable die Prüfung eines Profils vollständig ausgeschaltet werden.

4. Wenn das Skript über `runSmith_select.bat` (unter Windows) gestartet soll, muss in dieser der Pfad zur Datei `Rscript.exe` geprüft und ggf. angepasst werden (z.B. `C:\Program Files\R\R-4.0.4\bin\Rscript.exe`).


#### Start des Skripts
Beim ersten Start des Skripts wird überprüft, ob die zur Ausführung notwendigen R-Pakete (`fhircrackr`, `data.table`) vorhanden sind. Ist dies nicht der Fall, werden diese Pakete nachinstalliert – dieser Prozess kann einige Zeit in Anspruch nehmen.

##### Batch-Datei/Shell-Skript
**Unter Windows**: Mit der Batch-Datei `runSmith_select.bat`.
Beim ersten Ausführen sollte diese ggf. als Administrator gestartet werden (über Eingabeaufforderung oder Rechtsklick), wenn die ggf. notwendigen Berechtigungen zum Nachinstallieren der R-Pakete sonst nicht vorhanden sind. Nach der ersten Installation reicht dann ein Doppelklick zum Starten.

**Unter Linux**: Mit dem Shell-Skript `runSmith_select.sh`. Das Shell-Skript muss ausführbar sein und ggf. beim ersten Ausführen mittels `sudo` gestartet werden, wenn ein Nachinstallieren der R-Pakete außerhalb des User-Kontexts erforderlich ist.

#### R/RStudio
Durch Öffnen des R-Projektes (`Projectathon6-smith2.Rproj`) mit anschließendem Ausführen der Datei `smith_select.R` innerhalb von R/RStudio. Auch hier werden beim ersten Ausführen ggf. notwendige R-Pakete nachinstalliert.


## Ausführung im Docker Container
Um die Abfrage in einem Docker Container laufen zu lassen gibt es drei Möglichkeiten:

**A) Image von DockerHub ziehen:**
1. Git-Repository klonen: `git clone https://github.com/medizininformatik-initiative/Projectathon6-smith2.git`
2. Verzeichniswechsel in das lokale Repository: `cd Projectathon6-smith2`
3. Konfiguration lokal anpassen: `./config.R.default` nach `./config.R` kopieren und anpassen 
4. Image downloaden und Container starten: `docker run --name projectathon6-smith2 -v "$(pwd)/errors:/errors" -v "$(pwd)/Bundles:/Bundles" -v "$(pwd)/Ergebnisse:/Ergebnisse" -v "$(pwd)/config.R:/config.R" palmjulia/projectathon6-smith2`


**B) Image bauen mit Docker Compose:**

1. Git-Repository klonen: `git clone https://github.com/medizininformatik-initiative/Projectathon6-smith2.git`
2. Verzeichniswechsel in das lokale Repository: `cd Projectathon6-smith2`
3. Konfiguration lokal anpassen: `./config.R.default` nach `./config.R` kopieren und anpassen 
4. Image bauen und Container starten: `docker compose up -d`

Zum Stoppen des Containers `docker compose stop`. Um ihn erneut zu starten, `docker compose start`.

**C) Image bauen ohne Docker Compose**

1. Git-Repository klonen: `git clone https://github.com/medizininformatik-initiative/Projectathon6-smith2.git`
2. Verzeichniswechsel in das lokale Repository: `cd Projectathon6-smith2`
3. Image bauen: `docker build -t projectathon6-smith2 .` 
4. Konfiguration lokal anpassen: `./config.R.default` nach `./config.R` kopieren und anpassen 
5. Container starten: `docker run --name projectathon6-smith2 -v "$(pwd)/errors:/errors" -v "$(pwd)/Bundles:/Bundles" -v "$(pwd)/Ergebnisse:/Ergebnisse" -v "$(pwd)/config.R:/config.R" projectathon6-smith2`

Erklärung:

-  `-v "$(pwd)/config.R:/config.R""` bindet die lokal veränderte Variante des config-Files ein. Wenn dieses geändert wird, reicht es, den Container neu zu starten (`docker stop Projectathon6-smith2`, config.R ändern, dann `docker start Projectathon6-smith2`), ein erneutes `docker build` ist nicht nötig.


-----------------------------------------------------------------------------------------------

## Selbstsignierte Server-Zertifikate

Falls der verwendete FHIR-Server ein selbst-signiertes Zertifikat für HTTPS verwendet, ist es notwendig das zugehörige Root-Zertifikat zu übergeben. R nutzt die Systemzertifikate des Betriebssystems hierfür.

Wenn die Abfrage direkt (ohne Docker) ausgeführt wird muss sich das Root-Zertifikat in den systemweit vertrauenswürdigen Zertifikaten befinden. Dies ist Betriebssystemabhängig. Für die Ausführung im Docker-Container kann das Root-Zertifikat als Volume eingebunden werden.

**Docker**
Angenommen das Zertifikat liegt unter `./localca.pem` muss folgender zusätzlicher Parameter beim `docker run ...`-Befehl übergeben werden:
`-v ./localca.pem:/usr/local/share/ca-certificates.crt`

**Docker-Compose**
Angenommen das Zertifikat liegt unter `./localca.pem` muss folgender Eintrag in der `docker-compose.yml` gemacht werden:
```
[...]
  volumes:
  - ./localca.pem:/usr/local/share/ca-certificates.crt
[...]
```

Hintergrund:
Das Image basiert auf Debian und führt bei jedem Start den Befehl `update-ca-certificates` aus, mit dem es die Zertifikate unter `/usr/local/share/ca-certificates` einliest und zu den Vertrauenswürdigen hinzufügt.


## Output
Das Skript erzeugt mehrere Ordner im Projekt-Directory. Um für den Projectathon eine möglichst einfache übersichtliche Lösung zu bekommen, werden alle files, die darin erzeugt werden bei mehrmaligem Ausführen ggf. einfach überschrieben.

### Ergebnisse
Wenn die Abfrage erfolgreich durchgeführt wurde, sind hier zwei semikolongetrennte csv-Dateien (= lässt sich durch Doppelklick in Excel öffnen) zu finden. Die enthaltenen Variablen sind hier kurz erklärt: 

**Kohorte.csv**

Diese Tabelle enthält eine Kombination von Informationen aus der Patient Ressource, der Encounter Ressource und der Observation Ressource. Sie enthält alle Fälle, für die es eine Observation mit einer NTproBNP Messung im geforderten Zeitraum gibt.

|Variable             | Bedeutung|
|---------------------|----------|
|subject                            | Logical id der Patient Ressource|
|encounter.start                    | Startzeitpunkt des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.|
|encounter.end                      | Stoppzeitpunkt des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.|
|serviceType                        | ServiceType (Stationsschlüssel) des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.|
|NTproBNP.date                      | Datum (effectiveDateTime) der Observation mit der NTproBNP-Messung.|
|NTproBNP.valueQuantity.value       | Numerischer Wert (valueQuantity.value) der Observation mit der NTproBNP-Messung.|
|NTproBNP.valueQuantity.comparator  | Komparator (valueQuantity.comparator, falls vorhanden) der Observation mit der NTproBNP-Messung, welcher den numerischen Wert qualifiziert.|
|NTproBNP.valueCodeableConcept.code | Kodierter Wert (valueCodeableConcept.code) der Observation mit der NTproBNP-Messung, für Fälle in denen die Messung nicht numerisch abgelegt wurde.|
|NTproBNP.valueCodeableConcept.system | Codesystem zu NTproBNP.valueCodeableConcept.code|
|NTproBNP.code                      | Loinc-Code (code.coding.code) der Observation mit der NTproBNP-Messung.|
|NTproBNP.codeSystem                | CodeSystem (code.coding.system) der Observation mit der NTproBNP-Messung.|
|NTproBNP.unit                      | Code der Einheit (valueQuantity.code) der NTproBNP-Messung.|
|NTproBNP.unitSystem                | Codesystem der Einheit (valueQuantity.code) der NTproBNP-Messung.|
|gender                             | Geschlecht (gender) der Patient Ressource|
|birthdate                          | Geburtsdatum (birthDate) der Patient Ressource|

**Diagnosen.csv**

Diese Tabelle enthält alle Diagnosen der Patienten aus Kohorte.csv, die einen der im Antrag genannten ICD-Kodes enthalten.

|Variable             | Bedeutung|
|---------------------|----------|
|condition.id               |Ressourcen ID der Condition Ressource|
|clinicalStatus.code        |Code des ClinicalStatus|
|clinicalStatus.system      |Codesystem des ClinicalStatus|
|verificationStatus.code    |Code des verificationStatus|
|verificationStatus.system  |CodeSystem des verificationStatus|
|code                       |ICD-Code|
|code.system                |Codesystem des ICD Codes|
|subject                    |ID der zugehörigen Patient Ressource|
|encounter.id               |ID der zugehörigen Encounter Ressource|
|diagnosis.use.code         |Encounter.diagnosis.use.coding.code mit dem die Condition im zugehörigen Encounter beschrieben ist|
|diagnosis.use.system         |Encounter.diagnosis.use.coding.system mit dem die Condition im zugehörigen Encounter beschrieben ist|

**smith_select.log**

Neben den Ergebnistabellen wird außerdem eine "smith_select.log"-Datei erzeugt, welche die Anzahl der extrahierten Fälle, Patienten und die Laufzeit des R-Skriptes dokumentiert. Das log-file muss nicht geteilt werden, es dient den DIZen nur als Hilfestellung für die Einschätzung von Laufzeiten und Ergebnismengen. 

### Bundles
Dieser Ordner enthält die heruntergeladenen Bundles und kann der Kontrolle dienen, falls die Tabellen nicht aussehen wie erwartet.

### errors
Dieser Ordner enthält ggf. Fehlermeldungen, wenn die Abfrage nicht erfolgreich durchgeführt werden kann.

## Verwendete Codesysteme
Das Skript verwendet folgende Codesysteme:

- *http://loinc.org* für `Observation.code.coding.system` -> Dieses System wird für den Download per FHIR Search verwendet
- *urn:oid:2.16.840.1.113883.3.1937.777.24.5.3* für `Consent.provision.provision.code.coding.system` -> Nur verwendet, wenn konsentierte Daten über Consent Ressource selektiert werden, also wenn `filterConsent <- TRUE` in config.R.

## Verwendete Profile/Datenelemente
Die Abfragen sind auf Basis der MII Profile für die entsprechenden Ressouren geschrieben. Die Skripte sind kompatibel mit dem jeweils neuesten Release der verfügbaren Major Versionen (1 und, wenn vorhanden, 2). In den meisten Fällen werden die Skripte auch funktionieren, wenn nicht genau dieser Release des Profils verwendet wird. Es ist jedoch zwingend notwendig, dass die Ressourcen das jeweilige Profil im `Resource.meta.profile` Element benennen. Im folgenden ist für jeden verwendeten Ressourcentyp beschrieben, welche Elemente für die FHIR-Search-Abfrage an den Server verwendet werden (diese Elemente *müssen* vorhanden sein, damit kein Fehler geworfen wird) und welche Elemente im Skript extrahiert und in die Ergebnistabellen geschrieben werden. 

### Modul Labor: Observation
Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab`

Version: [1.0.6](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.laborbefund/1.0.6/~introduction)

Für Servabfrage verwendete Elemente:

- `Observation.subject`
- `Observation.code`
- `Observation.effective`
- `Observation.meta.profile`

Extrahierte Elemente:

- `Observation.effectiveDateTime`
- `Observation.subject.reference`
- `Observation.code.coding.code`
- `Observation.code.coding.system`
- `Observation.valueQuantity.value`
- `Observation.valueQuantity.code`
- `Observation.valueQuantity.system`

### Modul Person: Patient
Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-person/StructureDefinition/Patient`

Version: [2.0.0-alpha3](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.person/2.0.0-alpha3) bzw. [1.0.14](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.person/1.0.14)

Für Servabfrage verwendete Elemente:

- keine

Extrahierte Elemente:

- `Patient.id`
- `Patient.gender`
- `Patient.birthDate`

### Modul Fall: Encounter
Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung`

Version: [1.0.1](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.fall/1.0.1)

Für Servabfrage verwendete Elemente:

- `Encounter.meta.profile`
- `Encounter.subject.reference`

Extrahierte Elemente:

- `Encounter.subject.reference`
- `Encounter.period.start `
- `Encounter.period.end`
- `Encounter.serviceType.coding.display`
- `Encounter.diagnosis.use.coding.code`
- `Encounter.diagnosis.use.coding.system`

### Modul Diagnose: Condition
Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-diagnose/StructureDefinition/Diagnose`

Version: [2.0.0-alpha3](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.diagnose/2.0.0-alpha3) bzw. [1.0.4](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.diagnose/1.0.4)

Für Servabfrage verwendete Elemente:

- `Condition.meta.profile`
- `Condition.subject.reference`

Extrahierte Elemente:

- `Condition.clinicalStatus.coding.code`
- `Condition.clinicalStatus.coding.system`
- `Condition.verificationStatus.coding.code`
- `Condition.verificationStatus.coding.system`
- `Condition.code.coding.code`
- `Condition.code.coding.system`
- `Condition.subject.reference`
- `Conditions.encounter.reference`


### Modul Consent: Consent
Wird nur verwendet, wenn `filterConsent <- TRUE` in `config.R`, d.h. wenn konsentierte und nicht konsentierte Daten durch das R-Skript gefiltert werden müssen und die Trennung nicht durch unterschiedliche FHIR-Repositories erfolgt.

Profil: `http://fhir.de/ConsentManagement/StructureDefinition/Consent`
Version: [1.0.0](https://simplifier.net/packages/de.einwilligungsmanagement/1.0.0)
Beispiel: https://simplifier.net/packages/de.einwilligungsmanagement/1.0.0/files/405292

Für Servabfrage verwendete Elemente:

- `Consent.patient.reference`

Extrahierte Elemente:

- `Consent.patient.reference`
- `Consent.provision.provision.code.coding.code`
- `Consent.provision.provision.code.coding.system`

## Konzeptioneller Ablauf der Abfrage
Prinzipiell geht das Skript wie folgt vor:

1) Lade alle Observations, die eine NTproBNP-Messung darstellen (`loinc code` ist einer aus: `33763-4,71425-3,33762-6,83107-3, 83108-1,77622-9,77621-1`), welche ein `effective` im Zeitraum `2019-01-01 - 2021-12-31` haben und das Profil `https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab` erfüllen, herunter. Ziehe dazu außerdem (mit `_include`) die zugehörigen Patient Ressourcen.

- `[base]/Observation?_include=Observation:patient&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab&code=http://loinc.org|33763-4,http://loinc.org|71425-3,http://loinc.org|33762-6,http://loinc.org|83107-3,http://loinc.org|83108-1,http://loinc.org|77622-9,http://loinc.org|77621-1&date=ge2019-01-01&date=le2021-12-31`

2) Optional: Lade die zu den Patienten gehörigen Consents herunter und filtere die bisher geladenen Daten, sodass nur Daten von Patienten mit Consent übrig bleiben. 

- `[base]/Consent?patient=xxx%2Cyyy`

3) Extrahiere die IDs der Patient Ressourcen und verwende sie um alle zugehörigen Encounter und Condition-Ressourcen herunterzuladen. Dafür werden die Abfragen soweit gesplittet, dass der jeweilige GET-Request eine Länge von 1800 Zeichen nicht überschreitet.(Mir ist klar, das POST eleganter ist, aber wir versuchen die Anforderungen an den Server/Rechte möglichst niedrig zu halten.) 

- `[base]/Encounter?&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung&subject=xxx,yyy`
- `[base]/Condition?_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-diagnose/StructureDefinition/Diagnose&subject=xxx,yyy`


4) Filtere die Encounter, sodass nur die Encounter übrig bleiben, in deren `period` eine NTproBNP Observation liegt.

5) Filtere die Diagnosen, sodass nur Diagnosen übrig bleiben, die zu den Encountern aus 4) gehören.


## Changelog
**28.03.2022**

*Änderung*: Zusätzlich zu den Ergebnis-Tabellen wird nun ein Textfile "Ergebnisse/smith_select.log" erzeugt, welches die Anzahl der extrahierten Fälle, Patienten und die Laufzeit des R-Skriptes dokumentiert. Das log-file muss nicht geteilt werden, es dient den DIZen nur als Hilfestellung für die Einschätzung von Laufzeiten und Ergebnismengen. 

----------------------------

**17.03.2022**

*Änderung*: In der Variable `serviceType` wird jetzt das Element `Encounter.serviceType.coding.display` extrahiert, anstatt wie vorher `Encounter.serviceType`, was nicht zu einem extrahierbaren einzelnen String geführt hätte. Die Form und der inhalt der Tabelle ändert sich dadurch nicht, nur der Inhalt der betreffenden Variable, die jetzt das enthält, was intendiert/kommuniziert war, statt eines `NA`.

----------------------------

**14.03.2022**

*Änderung*: Es werden nicht mehr nur numerische NTproBNP-Messwerte aus dem Element `Observation.valueQuantity.value` extrahiert, sondern zusätzlich auch die Elemente `Observation.valueQuantity.comparator`, `Observation.valueCodeableConcept.coding.code` und `Observation.valueCodeableConcept.coding.system`, um auch Messwerte abzudecken, die sich nicht in `valueQuantity.value` allein abbilden lassen, z.b. Angaben wie `<50`.
Die Spalten, die diese Informationen insgesamt abdecken heißen `NTproBNP.valueQuantity.value`, `NTproBNP.valueQuantity.comparator`, `NTproBNP.valueCodeableConcept.code`, `NTproBNP.valueCodeableConcept.system`.

----------------------------

**04.03.2022**

*Änderung*: Zur Qualitätssicherung wird für jede NTproBNP-Messung nun auch der zugehörige Loinc-Code extrahiert, der zur Filterung der jeweiligen Observation verwendet wurde. Es gibt deshalb in Kohorte.csv nun zwei zusätzliche Spalten: NTproBNP.code und NTproBNP.codeSystem.

----------------------------

**18.02.2022**

*Änderung*: Das Skript schickt jetzt einige informative Nachrichten in die Konsole um das Debugging zu erleichtern. Die Ergebnisse ändern sich dadurch in keiner Weise.

----------------------------

**19.01.2022**

*Änderung*: Logik beim herunterladen von Conditions geändert: Es werden jetzt alle Conditions zu den untersuchten Patienten gezogen und anschließend so gefiltert, dass nur Conditions übrig bleiben, die zu den gewünschten Encountern gehören. Entsprechend wurde im `config.R` das Profil für die Condition ergänzt und kann nach Bedarf an- und abgeschaltet werden.

*Erklärung*: Damit ist es jetzt irrelevant, ob der Encounter auf die Condition verlinkt oder die Condition auf den Encounter verlinkt. Das Skript funktioniert, solange mindestens eine der Richtungen gegeben ist. Diese Änderung wurde implementiert, weil sich herausstellt, dass die Linkrichtung in den verschiedenen DIZen zu heterogen ist, als das man sich auf eine von beiden verlassen könnte.

----------------------------

**14.01.2022**

*Änderung*: Typo in `smith_select.R` korrigiert.

*Erklärung* Korrigiert Fehler in der zeitlichen Relation im merge-Befehl in Z301. Sollte keine oder maximal geringfügigen Einfluss auf die Ergebnisse haben, da im Folgenden sowieso nochmal nach korrektem Zeitbezug gefiltert wird.

----------------------------

**13.12.21**

*Änderung*: Changelog im README wurde ergänzt

-------------------

**10.12.21**

*Änderung*: Nicht mehr benötigte Zwischenergebnisse werden frühzeitig gelöscht.

*Erklärung*: In DIZen mit großen Datenmengen kommt der Arbeitsspeicher des Docker-Containers an seine Grenzen. Die Änderung hat keinen Einfluss auf die Ergebnisse der Skripte.

---------------------

**07.12.21**

*Änderung*: Encounter-Ressourcen, die durch `_include` doppelt heruntergeladen wurden, werden jetzt im Skript gelöscht. 

*Erklärung*: Doppelt heruntergeladene Encounter führten zuvor im Skript für Fehlermeldungen beim Mergen der Daten. DIZen, die das Skript zuvor schon fehlerfrei ausführen konnten, hatten keine doppelt heruntergeladenen Encounter und bekommen durch diese Änderung demzufolge auch keine geänderten Ergebnisse

---------------------------

*Änderung*: Merge Encounter- und Observation-Ressouren basierend auf Subject-ID und Datum, nicht auf Subject-ID allein.

*Erklärung*: Der Merge anhand der Subject-ID allein funktionierte nur eindeutig, solange Encounter und Observations eines Subject (=Patient) in einem 1:n oder m:1-Verhältnis standen. In diesem Fall konnte man erst mergen und dann die Zeiträume filtern, sodass nur zueinander passende Ressourcen behalten wurden. Wenn Encounter und Observations in m:n Verhältnis vorlagen, warf das Sktipt einen Fehler, der durch die neue Merge-Technik behoben wird.
DIZen, bei denen das Sktipt schon vor der Anpassung keinen Fehler warf, bekommen trotzdem das gleiche Ergebnis, weil die zeitliche Filterung der Ressourcen jetzt einfach nur einen Arbeitsschritt nach vorne gelegt wurde.

----------------------------

*Änderung*: Die Einschränkung der Abfrage auf MII-Profile z.B. über `_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung` ist jetzt im `config.R` konfigurierbar. Sie kann komplett ausgeschaltet oder wenn nötig auf ein andere Profil angepasst werden.

*Erklärung*: Einige DIZen haben die Profile noch nicht in `Resource.meta.profile` referenziert und bekommen mit der Einschränkung keine Ergebnisse.

-------------------------------

