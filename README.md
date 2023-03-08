# VHF Vorhofflimmern

Autor: Alexander Strübing ([alexander.struebing@imise.uni-leipzig.de](mailto:alexander.struebing@imise.uni-leipzig.de))

## Einführung

Dieses Projekt führt das DUP Vorhofflimmern (VHF) aus. Der Retrieval-Teil (Datenselektion) des DUP erzeugt zwei
Tabellen mit den für die Analyse benötigten Inhalten. Diese Tabellen sollen direkt nach dem Retrieval auch in den
DIZen analysiert werden und nur die Analyseergebnisse an die DMSt ausgeleitet werden (VHF-MI-dezentral).

Die o.g. Tabellen werden in das nicht auszuleitende Verzeichnis `outputLocal` geschrieben und danach bei der Analyse
im DIZ die auszuleitenden Analyseergebnisse (Textdateien und ROC-Plots in PDF-Dateien) in das Verzeichnis `outputGlobal`.

Hier wird die Verwendung des DUP beschrieben. Die inhaltliche Beschreibung des Retrieval und der Analyse steht in der
Readme des jeweiligen Unterordners:

* [Retrieval Readme](./retrieval#vhf-vorhofflimmern-retrieval)
* [Analysis Readme](./analysis#vhf-vorhofflimmern-analysis)

## Varianten für die jeweiligen Projekte im MII-Kontext

### VHF-MI-dezentral

DIZ: Sowohl das Retrieval als auch die Analyse werden in den DIZen ausgeführt und die Analyseergebnisse an die
Datenmanagementstelle (DMSt) ausgeleitet. In der Datei `config.toml` (siehe unten) sind alle Default-Werte der
Environment-Parameter für diesen Use Case bereits gesetzt. Es sollte sich ausführen lassen, wenn nur folgenden
Paramter gesetzt werden:

* `fhirServerEndpoint` 
* ggf. `fhirServerUser` und `fhirServerPass`

DMSt: Leitet dann die Analyseergebnisse an den Forscher zur Endauswertung weiter. 

### VHF-MI-2-zentral

**DIZ:** Das DIZ führt keine Scripte aus diesem Repository aus. Statt dessen muss das DIZ FHIR-Daten an die DMSt
ausleiten. Die dazu notwendigen Skripte zum Retrieval finden sich in
https://github.com/medizininformatik-initiative/Projectathon7-VHF-DataExtraction. 

**DMSt:** Die DMSt selbst führt auf einem speziellen FHIR-Server mit den Daten aus den DIZen nur das Retrieval aus.
Folgende Paramter müssen dabei in der Datei `config.toml` (siehe unten) mind. gesetzt bzw. vom Default geändert
werden: 

* `fhirServerEndpoint`
* ggf. `fhirServerUser` und `fhirServerPass`
* `DECENTRAL_ANALYSIS` muss auf `FALSE` geändert werden (Default ist `TRUE`). ACHTUNG: Dieser Paramter steht 2x in der
`config.toml`. Der erste Eintrag ist die Einstellung für das Retrieval (toml-Abschnitt `[retrieve.env]`) und der
zweite für die Analyse (toml-Abschnitt `[analyze.env]`). Die DMSt muss auf jeden Fall den ersten Eintrag ändern! 

Die DMSt leitet dann die Retrievalergebnsse an den Forscher weiter. Der Forscher selbst kann dann die Analyse aus diesem
Projekt auf den Daten ausführen.

### VHF-dataSHIELD

Die Dokumentation, Anleitungen und der Quellcode, die für das Projekt VHF-DataSHIELD im Rahmen des 7. Projektathon relevant sind, sind von dieser hier vorliegenden Dokumentation ausgenommen. Sie finden sich im GitHub Repositorium [Projekthathon7-VHF-DataSHIELD](https://github.com/medizininformatik-initiative/Projectathon7-VHF-DataSHIELD).

## Verwendung

### dupctl (Docker)

Eine einfache und reproduzierbare Ausführung der DUPs wird über das dupctl Command Line Interface (cli)
sichergestellt. Dafür sind folgende Schritte nötig:

* Installation dupctl (siehe [DUP Control Readme][dupctl#install])

* Arbeitsverzeichnis wählen
  * Es muss ein Verzeichnis gewählt werden, in dem dupctl Kommandos ausgeführt werden sollen. Die Ergebnisse der DUPs
  werden im gleichen Verzeichnis gespeichert! Siehe auch [DUP Control Readme][dupctl#workdir]

* `config.toml` im Arbeitsverzeichnis erstellen
  * Zum Ausführen des DUP muss eine DUP Control Konfigurationsdatei (`config.toml`) im Arbeitsverzeichnis liegen.
  * Vorlage mit allen Parametern (sowohl für das Retrieval als auch für die Analyse): [config.toml](./config.toml)

* **Ausführung des Retrievals**
  * Wenn alle Retrieval-Parameter in der `config.toml` angegeben wurden, kann das Retrieval im Arbeitsverzeichnis über
  folgendes Kommando gestartet werden:

```bash
dupctl retrieve --dup vhf
```

* **Ausführung der Analyse**

  * Die Analyse kann beliebig oft auf denselben Daten des Retrievals gestartet werden.
  * Alle Optionen der Analyse werden ebenfalls in der `config.toml` festgelegt.

```bash
dupctl analyze --dup vhf
```

Weitere Informationen
* dupctl: [DUP Control README][dupctl#settings]
* Analysis: [VHF Analysis README](analysis/README.md)
* Retrieval: [VHF Retrieval README](retrieval/README.md)

### Manuelle Ausführung

Bei Bedarf können DUPs auch ohne den Einsatz von Docker ausgeführt werden.

* Die manuelle Ausführung ist durch das downloaden/klonen dieses Repositories möglich.
* Dem Projekt liegt eine ausführlich dokumentierte [.RProfile](./.RProfile) Datei bei. Dieses Profil muss angepasst und
  im R geladen werden.

* **Ausführung des Retrievals und der Analyse direkt nacheinander**
  * vollständiges Ausführen der Datei [manual.R](./manual.R)
  * Voraussetzungen: 
    1. Die Datei `.RProfile` wurde korrekt initialisiert (insbesondere mit den Zugangsdaten des FHIR-Servers und der
       Option `DECENTRAL_ANALYSIS`).
    2. Das R-Arbeitsverzeichnis vor dem Start ist das Verzeichnis, in dem auch die `manual.R` liegt.

* **Ausführung des Retrievals einzeln**
  * Das Retrieval kann einzeln durch Ausführen der Datei [retrieval/main.R](./retrieval/main.R) gestartet wird.
  * Voraussetzungen:
    1. Die Datei `.RProfile` wurde korrekt initialisiert (insbesondere mit den Zugangsdaten des FHIR-Servers).
    2. Die Umgebungsvariable `OUTPUT_DIR_BASE` ist gesetzt und zeigt auf ein beschreibbares Verzeichnis (darin werden
      die Ergebnisordner `outputLocal` und `outputGlobal` geschrieben; ein einfaches Setzen auf das aktelle
      R-Arbeitsverzeichnis ist über die ersten beiden Anweisungen in der `manual.R` möglich).
    3. Das R-Arbeitsverzeichnis ist das Verzeichnis des Scripts `retrieval/main.R`.
  * Das Setzen von `OUTPUT_DIR_BASE` und das Starten des Retrieval kann durch teilweises Ausführen der Datei `manual.R`
    erfolgen (siehe oben).

* **Ausführung der Analyse einzeln**
  * Die Analyse kann beliebig oft auf denselben Daten des Retrievals durch Ausführen der Datei
    [analysis/main.R](./analysis/main.R) gestartet werden.
  * Voraussetzungen:
    1. Die Umgebungsvariable `OUTPUT_DIR_BASE` ist gesetzt und zeigt auf das Verzeichnis mit den Ergebnissen des
       Retrievals (darin werden die Ergebnisordner `outputLocal` und `outputGlobal` erwartet; ein einfaches Setzen auf
       das aktelle R-Arbeitsverzeichnis ist über die ersten beiden Anweisungen in der `manual.R` möglich -> siehe
       *Ausführung des Retrievals einzeln*).
    2. Das R-Arbeitsverzeichnis ist das Verzeichnis des Scripts `analysis/main.R`.
  * Das Setzen von `OUTPUT_DIR_BASE` und das Starten der Analyse kann durch teilweises Ausführen der Datei `manual.R`
    erfolgen (siehe oben).
* **R Version: 4.2.0**
* **CRAN Snaphot Datum: 2022-06-22**

## Problembehandlung

Bei Problemen mit der Ausführung des DUP können Sie unter
https://github.com/medizininformatik-initiative/Projectathon7-VHF/issues einen (möglichst aussagekräftigen) Issue anlegen.
In dringenden Fällen kontaktieren Sie Alexander Strübing direkt unter 
[alexander.struebing@imise.uni-leipzig.de](mailto:alexander.struebing@imise.uni-leipzig.de).

[dupctl]: https://github.com/medizininformatik-initiative/dup-control
[dupctl#install]: https://github.com/medizininformatik-initiative/dup-control#installation
[dupctl#workdir]: https://github.com/medizininformatik-initiative/dup-control#working-directory
[dupctl#settings]: https://github.com/medizininformatik-initiative/dup-control#global-settings
