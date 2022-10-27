# VHF Vorhofflimmern Retrieval

## Verwendung

siehe [VHF Readme](../README.md#Verwendung)

## Output

Das Skript erzeugt mehrere Ordner im Projekt-Directory. Um für den Projectathon eine möglichst einfache übersichtliche
Lösung zu bekommen, werden alle Files, die darin erzeugt werden bei mehrmaligem Ausführen ggf. einfach überschrieben.

### Ergebnisse

Wenn die Abfrage erfolgreich durchgeführt wurde, sind hier zwei semikolongetrennte csv-Dateien (= lässt sich durch
Doppelklick in Excel öffnen) zu finden. Die enthaltenen Variablen sind hier kurz erklärt:

**Cohort.csv**

Diese Tabelle enthält eine Kombination von Informationen aus der Patient Ressource, der Encounter Ressource und der
Observation Ressource. Sie enthält alle Fälle, für die es eine Observation mit einer NTproBNP Messung im geforderten
Zeitraum gibt.

| Variable                             | Bedeutung                                                                                                                                           |
|--------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| subject                              | Logical ID der Patient Ressource                                                                                                                    |
| NTproBNP.date                        | Datum (effectiveDateTime) der Observation mit der NTproBNP-Messung.                                                                                 |
| NTproBNP.valueQuantity.value         | Numerischer Wert (valueQuantity.value) der Observation mit der NTproBNP-Messung.                                                                    |
| NTproBNP.valueQuantity.comparator    | Komparator (valueQuantity.comparator, falls vorhanden) der Observation mit der NTproBNP-Messung, welcher den numerischen Wert qualifiziert.         |
| NTproBNP.valueCodeableConcept.code   | Kodierter Wert (valueCodeableConcept.code) der Observation mit der NTproBNP-Messung, für Fälle in denen die Messung nicht numerisch abgelegt wurde. |
| NTproBNP.valueCodeableConcept.system | Codesystem zu NTproBNP.valueCodeableConcept.code                                                                                                    |
| NTproBNP.code                        | Loinc-Code (code.coding.code) der Observation mit der NTproBNP-Messung.                                                                             |
| NTproBNP.codeSystem                  | CodeSystem (code.coding.system) der Observation mit der NTproBNP-Messung.                                                                           |
| NTproBNP.unit                        | Code der Einheit (valueQuantity.code) der NTproBNP-Messung.                                                                                         |
| NTproBNP.unitLabel                   | Anzeigetext der Einheit (valueQuantity.code) der NTproBNP-Messung.                                                                                  |
| NTproBNP.unitSystem                  | Codesystem der Einheit (valueQuantity.code) der NTproBNP-Messung.                                                                                   |
| gender                               | Geschlecht (gender) der Patient Ressource                                                                                                           |
| birthdate                            | Geburtsdatum (birthDate) der Patient Ressource                                                                                                      |
| encounter.id                         | ID des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.                                                                    |
| encounter.start                      | Startzeitpunkt des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.                                                        |
| encounter.end                        | Stoppzeitpunkt des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.                                                        |

**Diagnoses.csv**

Diese Tabelle enthält alle Diagnosen der Patienten aus Kohorte.csv, die einen der im Antrag genannten ICD-Kodes
enthalten.

| Variable                  | Bedeutung                                                                                            |
|---------------------------|------------------------------------------------------------------------------------------------------|
| condition.id              | Ressourcen ID der Condition Ressource                                                                |
| clinicalStatus.code       | Code des ClinicalStatus                                                                              |
| clinicalStatus.system     | Codesystem des ClinicalStatus                                                                        |
| verificationStatus.code   | Code des verificationStatus                                                                          |
| verificationStatus.system | CodeSystem des verificationStatus                                                                    |
| code                      | ICD-Code                                                                                             |
| code.system               | Codesystem des ICD Codes                                                                             |
| subject                   | ID der zugehörigen Patient Ressource                                                                 |
| encounter.id              | ID der zugehörigen Encounter Ressource                                                               |
| diagnosis.use.code        | Encounter.diagnosis.use.coding.code mit dem die Condition im zugehörigen Encounter beschrieben ist   |
| diagnosis.use.system      | Encounter.diagnosis.use.coding.system mit dem die Condition im zugehörigen Encounter beschrieben ist |

**Retrieval.log**

Neben den Ergebnistabellen wird außerdem eine "Retrieval.log"-Datei erzeugt, welche die Anzahl der extrahierten
Fälle, Patienten und die Laufzeit des R-Skriptes dokumentiert. Das log-file muss nicht geteilt werden, es dient den
DIZen nur als Hilfestellung für die Einschätzung von Laufzeiten und Ergebnismengen.

### Bundles

Dieser Ordner enthält die heruntergeladenen Bundles und kann der Kontrolle dienen, falls die Tabellen nicht aussehen wie
erwartet.

### errors

Dieser Ordner enthält ggf. Fehlermeldungen, wenn die Abfrage nicht erfolgreich durchgeführt werden kann.

## Verwendete Codesysteme

Das Skript verwendet folgende Codesysteme:

- *http://loinc.org* für `Observation.code.coding.system` -> Dieses System wird für den Download per FHIR Search
  verwendet
- *urn:oid:2.16.840.1.113883.3.1937.777.24.5.3* für `Consent.provision.provision.code.coding.system` -> Nur verwendet,
  wenn konsentierte Daten über Consent Ressource selektiert werden, also wenn `filterConsent <- TRUE` in config.R.

## Verwendete Profile/Datenelemente

Die Abfragen sind auf Basis der MII Profile für die entsprechenden Ressouren geschrieben. Alle Profile (außer Patient)
können optional (über die Environment-Parameter des Retrievals) geändert werden, falls sie nicht den MII Profilen
entsprechen. Mit den Default-Profilen sind die Skripte kompatibel mit dem jeweils neuesten Release der verfügbaren
Major Versionen (1 und, wenn vorhanden, 2). In den meisten Fällen werden die Skripte auch funktionieren, wenn nicht
genau dieser Release des Profils verwendet wird. Es ist jedoch zwingend notwendig, dass die Ressourcen das jeweilige
Profil im `Resource.meta.profile` Element benennen. Im Folgenden ist für jeden verwendeten Ressourcentyp beschrieben,
welche Elemente für die FHIR-Search-Abfrage an den Server verwendet werden (diese Elemente *müssen* vorhanden sein,
damit kein Fehler geworfen wird) und welche Elemente im Skript extrahiert und in die Ergebnistabellen geschrieben werden.

### Modul Labor: Observation

Default Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab`

Version: [1.0.6](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.laborbefund/1.0.6/~introduction)

Es kann optional ein anderes Profil angegeben werden.

Für Serverabfrage verwendete Elemente:

- `Observation.subject`
- `Observation.code`
- `Observation.effective`
- `Observation.meta.profile`

Extrahierte Elemente:

- `Observation.effectiveDateTime`
- `Observation.subject.reference`
- `Observation.encounter.reference`
- `Observation.code.coding.code`
- `Observation.code.coding.system`
- `Observation.valueQuantity.value`
- `Observation.valueQuantity.comparator`
- `Observation.valueQuantity.code`
- `Observation.valueQuantity.unit`
- `Observation.valueQuantity.system`
- `Observation.valueCodeableConcept.coding.code`
- `Observation.valueCodeableConcept.coding.system`

### Modul Person: Patient

Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-person/StructureDefinition/Patient`

Version: [2.0.0-alpha3](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.person/2.0.0-alpha3)
bzw. [1.0.14](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.person/1.0.14)

Für Serverabfrage verwendete Elemente:

- keine

Extrahierte Elemente:

- `Patient.id`
- `Patient.gender`
- `Patient.birthDate`

### Modul Fall: Encounter

Default Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung`

Version: [1.0.1](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.fall/1.0.1)

Es kann optional ein anderes Profil angegeben werden.

Für Serverabfrage verwendete Elemente:

- `Encounter.meta.profile`
- `Encounter.subject.reference`

Extrahierte Elemente:

- `Encounter.id`
- `Encounter.subject.reference`
- `Encounter.period.start`
- `Encounter.period.end`
- `Encounter.diagnosis.condition.reference`
- `Encounter.diagnosis.use.coding.code`
- `Encounter.diagnosis.use.coding.system`
- `Encounter.serviceType.coding.display`


### Modul Diagnose: Condition

Default Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-diagnose/StructureDefinition/Diagnose`

Version: [2.0.0-alpha3](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.diagnose/2.0.0-alpha3)
bzw. [1.0.4](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.diagnose/1.0.4)

Es kann optional ein anderes Profil angegeben werden.

Für Serverabfrage verwendete Elemente:

- `Condition.meta.profile`
- `Condition.subject.reference`

Extrahierte Elemente:

- `Condition.id`
- `Condition.clinicalStatus.coding.code`
- `Condition.clinicalStatus.coding.system`
- `Condition.verificationStatus.coding.code`
- `Condition.verificationStatus.coding.system`
- `Condition.code.coding.code`
- `Condition.code.coding.system`
- `Condition.subject.reference`
- `Condition.encounter.reference`


## Konzeptioneller Ablauf der Abfrage

Prinzipiell geht das Skript wie folgt vor:

1) Lade alle Observations, die eine NTproBNP-Messung darstellen (`loinc code` ist einer
   aus: `33763-4,71425-3,33762-6,83107-3, 83108-1,77622-9,77621-1`), welche ein `effective` im
   Zeitraum `2019-01-01 - 2021-12-31` haben und das (optional änderbare)
   Profil `https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab`
   erfüllen, herunter. Ziehe dazu außerdem (mit `_include`) die zugehörigen Patient Ressourcen.

- `[base]/Observation?_include=Observation:patient&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-labor/StructureDefinition/ObservationLab&code=http://loinc.org|33763-4,http://loinc.org|71425-3,http://loinc.org|33762-6,http://loinc.org|83107-3,http://loinc.org|83108-1,http://loinc.org|77622-9,http://loinc.org|77621-1&date=ge2019-01-01&date=le2021-12-31`

- `[base]/Consent?patient=xxx%2Cyyy`

2) Extrahiere die IDs der Patient Ressourcen und verwende sie um alle zugehörigen Encounter und Condition-Ressourcen
   herunterzuladen. Dafür werden die Abfragen soweit gesplittet, dass der jeweilige GET-Request eine Länge von 1800
   Zeichen nicht überschreitet.(Mir ist klar, das POST eleganter ist, aber wir versuchen die Anforderungen an den
   Server/Rechte möglichst niedrig zu halten.)

- `[base]/Encounter?&_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung&subject=xxx,yyy`
- `[base]/Condition?_profile=https://www.medizininformatik-initiative.de/fhir/core/modul-diagnose/StructureDefinition/Diagnose&subject=xxx,yyy`


3) Filtere die Encounter, sodass nur die Encounter übrig bleiben, in deren `period` eine NTproBNP Observation liegt.

4) Filtere die Diagnosen, sodass nur Diagnosen übrig bleiben, die zu den Encountern aus 4) gehören.
