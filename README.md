# DUP VHF Vorhofflimmern

## Einführung

Dieses Projekt führt die Select-Anfrage für das SMITH Projekt im Rahmen des 6. Projectathons aus. Hier ist eine 
zentrale Analyse vorgesehen. Dafür erzeugt dieses Skript zwei Tabellen mit den für die Analyse benötigten Inhalten. 
Diese Tabellen sollen zentral zusammengeführt und an die datenauswertendende Stelle übergeben werden.

Das Readme beschreibt zunächst die technischen Details der Verwendung. Darunter sind die verwendeten 
CodeSysteme/Ressourcen/Profile und der konzeptionelle Ablauf der Abfrage beschrieben.

## Verwendung

### polarctl (Docker)

Eine einfache und reproduzierbare Ausführung der SMITH PheP DUPs wird über das dupctl Command Line Interface (cli) 
sichergestellt. Nach der Installation der cli (siehe [dupctl][dupctl]) wird das DUP Skript über eine Kommandozeile 
wie folgt gestartet:

```bash
dupctl retrieve --dup vhf [...]
```

### Manuelle Ausführung

Bei Bedarf können die POLAR-Analysen auch ohne den Einsatz von Docker durchgeführt werden.

*Die manuelle Ausführung ist **nicht** durch das downloaden/klonen dieses Repositories möglich!*
Stattdessen muss das Workpackage in Form eines Archivs mittels folgenden Links heruntergeladen werden. Das Archiv
enthält alle nötigen Skripte und Libraries für eine manuelle Ausführung mittels R.

<div align="center"><a href="https://git.smith.care/smith/uc-phep/dup/vhf/-/jobs/artifacts/master/download?job=build-archive:latest">Download als ZIP Archiv</a></div>

* **R Version: 4.2.0**

* **CRAN Snaphot Datum: 2022-06-22**

Die weiteren Schritte der manuellen Ausführung sind in der [DUP README][readme] erläutert.

## Output

Das Skript erzeugt mehrere Ordner im Projekt-Directory. Um für den Projectathon eine möglichst einfache übersichtliche Lösung zu bekommen, werden alle files, die darin erzeugt werden bei mehrmaligem Ausführen ggf. einfach überschrieben.

### Ergebnisse

Wenn die Abfrage erfolgreich durchgeführt wurde, sind hier zwei semikolongetrennte csv-Dateien (= lässt sich durch Doppelklick in Excel öffnen) zu finden. Die enthaltenen Variablen sind hier kurz erklärt: 

**Kohorte.csv**

Diese Tabelle enthält eine Kombination von Informationen aus der Patient Ressource, der Encounter Ressource und der Observation Ressource. Sie enthält alle Fälle, für die es eine Observation mit einer NTproBNP Messung im geforderten Zeitraum gibt.

| Variable                             | Bedeutung                                                                                                                                           |
|--------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| subject                              | Logical id der Patient Ressource                                                                                                                    |
| encounter.start                      | Startzeitpunkt des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.                                                        |
| encounter.end                        | Stoppzeitpunkt des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.                                                        |
| serviceType                          | ServiceType (Stationsschlüssel) des Einrichtungskontakt-Encounters, der zeitlich zur NTproBNP-Messung gehört.                                       |
| NTproBNP.date                        | Datum (effectiveDateTime) der Observation mit der NTproBNP-Messung.                                                                                 |
| NTproBNP.valueQuantity.value         | Numerischer Wert (valueQuantity.value) der Observation mit der NTproBNP-Messung.                                                                    |
| NTproBNP.valueQuantity.comparator    | Komparator (valueQuantity.comparator, falls vorhanden) der Observation mit der NTproBNP-Messung, welcher den numerischen Wert qualifiziert.         |
| NTproBNP.valueCodeableConcept.code   | Kodierter Wert (valueCodeableConcept.code) der Observation mit der NTproBNP-Messung, für Fälle in denen die Messung nicht numerisch abgelegt wurde. |
| NTproBNP.valueCodeableConcept.system | Codesystem zu NTproBNP.valueCodeableConcept.code                                                                                                    |
| NTproBNP.code                        | Loinc-Code (code.coding.code) der Observation mit der NTproBNP-Messung.                                                                             |
| NTproBNP.codeSystem                  | CodeSystem (code.coding.system) der Observation mit der NTproBNP-Messung.                                                                           |
| NTproBNP.unit                        | Code der Einheit (valueQuantity.code) der NTproBNP-Messung.                                                                                         |
| NTproBNP.unitSystem                  | Codesystem der Einheit (valueQuantity.code) der NTproBNP-Messung.                                                                                   |
| gender                               | Geschlecht (gender) der Patient Ressource                                                                                                           |
| birthdate                            | Geburtsdatum (birthDate) der Patient Ressource                                                                                                      |

**Diagnosen.csv**

Diese Tabelle enthält alle Diagnosen der Patienten aus Kohorte.csv, die einen der im Antrag genannten ICD-Kodes enthalten.

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

Für Serverabfrage verwendete Elemente:

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

Für Serverabfrage verwendete Elemente:

- keine

Extrahierte Elemente:

- `Patient.id`
- `Patient.gender`
- `Patient.birthDate`

### Modul Fall: Encounter

Profil: `https://www.medizininformatik-initiative.de/fhir/core/modul-fall/StructureDefinition/KontaktGesundheitseinrichtung`

Version: [1.0.1](https://simplifier.net/packages/de.medizininformatikinitiative.kerndatensatz.fall/1.0.1)

Für Serverabfrage verwendete Elemente:

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

Für Serverabfrage verwendete Elemente:

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

Für Serverabfrage verwendete Elemente:

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


[dupctl]: https://git.smith.care/smith/uc-phep/dup-control
[readme]: https://git.smith.care/smith/uc-phep/dup/readme
