# VHF Vorhofflimmern Analysis

## Verwendung

siehe [VHF Readme](../README.md#Verwendung)

## Output

Das Skript erzeugt mehrere Dateien im Ausgabeverzeichnis `outputGlobal/VHF`. Das Ausgabeverzeichnis wird im 
Arbeitsverzeichnis angelegt und ist das Verzeichnis, dessen Inhalt an die datenauswertende Stelle ausgeleitet werden
soll. 

Das Script erwartet als Eingabedaten die beiden Tabellen aus dem [Retrieval](../retrieval/README.md). Diese
müssen sich je nach Start-Parameter `DECENTRAL_ANALYSIS` entweder im Verzeichnis `outputLocal/VHF` (bei
`DECENTRAL_ANALYSIS = TRUE`) oder im Verzeichnis ebenfalls im Verzeichnis `outputGlobal/VHF` (bei
`DECENTRAL_ANALYSIS = FALSE`) befinden.

Genau wie beim Retrieval gilt: Fall im Ordner `outputGlobal/VHF` bereits ein Analyseergebnis existiert, wird der
bestehende Ordner vor einer erneuten Ausführung mit dem Zeitstempel des Zeitpunktes seines Anlegens umbenannt und 
bleibt somit erhalten.

### Ergebnisse

Wenn die Analyse erfolgreich durchgeführt wurde, befinden sich im `outputGlobal`- Verzeichnis 9 Text- und 9 PDF-Dateien.
Zusätzlich dazu kann es noch das File `DQ-Report.html` mit dem Datenqualitätsreport geben (bei Startparameter
`DATA_QUALITY_REPORT = TRUE`).

Die Textdateien enthalten neben Log Informationen wie dem Start und End-Zeitpunt der Analyse folgende Informationen:

Die Textdateien enthalten jeweils alle Textausgaben der Analyse zu einer bestimmten (Sub)Kohorte bzw. Datenmenge, die
PDF-Dateien die zugehörigen ROC-Kurven als Bilder.

#### Einzelkohortenanalyse für eine Diagnose
Die Analyse wird mehrstufig durchgeführt. Das bedeutet im Einzelnen:
* für jede Kohorte wird bezüglich einer speziellen Diagnose (Vorhofflimmern oder Herzinsuffizienz)
  * für die Gesamtkohorte eine ROC-Kurve erstellt (PDF) und der AUC berechnet (Text) 
  * in 50er Schritten von 0 bis 3000 alle Beobachtungen von NTproBNP Werten in 2 Gruppen geteilt (`>` oder `<=`
  Schwellwert) und dann jeweils
    * eine ROC-Kurve erstellt (PDF) 
    * der AUC-Wert der ROC-Kurve ausgegeben (Text) 
    * eine GLM-Analyse durchgeführt (Text)
    * die Spezifität, Sensitivität, Positive und Negative Predictive Value berechnet (Text)
  * Falls eine ROC-Kurve nicht erstellt oder ein Wert nicht berechnet werden kann, wird stattdessen der Grund dafür
  geloggt (Text). Dies kann an zu wenigen oder zu gleichartigen Daten liegen (z.B. nur extrem hohe oder niedrige
  NTproBNP-Werte oder alle Patienten haben dasselbe Geschlecht oder ...).

Nachdem diese Einzelkohortenanalyse auf der gegebenen (Sub)Kohorte gelaufen ist, werden aus den Daten alle
NTproBNP-Werte entfernt, die mit einem Komparator (`>`, `>=`,`<`, `<=`,`=`) versehen waren und dann dieselbe Analyse
noch einmal durchgeführt. Enthält die gesamte (Sub)Kohorte gar keine oder ausschließlich Werte mit Komparatoren, wird
diese zweite Analyse nicht durchgeführt.

#### Wiederholungen der Einzelkohortenanalyse
Die Einzelkohortenanalyse wird in folgenden Schritten mehrfach wiederholt:
1. Unter Einschluss aller NTproBNP-Werte für die Diagnose Vorhofflimmern
2. Unter Einschluss aller NTproBNP-Werte für die Diagnose Herzinsuffizienz
3. Unter Auschluss aller NTproBNP-Werte mit Diagnose Herzinfarkt oder Schlaganfall für die Diagnose Vorhofflimmern
4. Unter Auschluss aller NTproBNP-Werte mit Diagnose Herzinfarkt oder Schlaganfall für die Diagnose Herzinsuffizienz
5. Unter Auschluss aller NTproBNP-Werte mit Diagnose Herzinfarkt, Schlaganfall oder Herzinsuffizienz für die Diagnose
   Vorhofflimmern

#### Bildung der Einzelkohorten
Insgesamt werden 9 (Sub)Kohorten gebildet und durch die beschriebene wiederholte Einzelkohortenanalyse geschickt.
Für jede dieser (Sub)Kohorten wird eine Text- und eine PDF-Datei erzeugt.
1. Gesamtkohorte
2. Männer
3. Frauen
4. Alter <= 50 Jahre
5. Alter > 50 Jahre
6. Männer mit Alter <= 50 Jahre
7. Männer mit Alter > 50 Jahre
8. Frauen mit Alter <= 50 Jahre
9. Frauen mit Alter > 50 Jahre

Die Einzelkohorten werden zunächst jeweils aus den Daten der Datei `Cohort.csv` gebildet. Danach wird das Vorligen der
4 Diagnosen aus der `Diagnoses.csv` (Vorhofflimmern, Herzinsuffizienz, Herzinfarkt und Schlaganfall) binär für jeden der
NTproBNP-Werte in der Kohortentabelle hinzugefügt. Die interne zusammengeführte Kohortentabelle enthält somit pro Zeile: 
* eine NTproBNP Messung (mit Wert, Einheit, Datum, ...)
* den zugehörigen Patienten (mit ID, Geburtsdatum, Alter, ...)
* den zugehörigen Fall (mit ID, Startdatum, Enddatum)
* das Vorliegen der 4 Diagnosen während des zugehörigen Falles bzw. zum Zeitpunkt der NTproBNP-Messung (0 oder 1 in der
  entsprechenden Spalte)

## Notwendige Vorbereitungen in der Analyse

Die Daten des Retrievals aus den beiden CSV-Dateien (`Cohort.csv` und `Diagnoses.csv`) werden in folgenden Schritten
für die Analyse vorbereitet:
1. Datenreihen aus `Cohort.csv` mit fehlenden NTproBNP Werten oder < 0 werden entfernt.
2. NTproBNP Werte mit den Komparatoren `<` oder `>` werden um 1 erniedrigt bzw. erhöht.
3. die Einheiten werden alle in `pg/mL` (picogram per milliliter) umgerechnet. Werte mit fehlenden oder nicht
   umrechenbaren Einheiten werden entfernt.
4. Das Alter des Patienten wird aus dem Datum des NTproBNP-Wertes und dem Geburtsdatum des Patienten berechnet.
