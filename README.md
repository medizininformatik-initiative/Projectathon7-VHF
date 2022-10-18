# VHF Vorhofflimmern

## Einführung

Dieses Projekt führt das DUP Vorhofflimmern (VHF) aus. Es kann sowohl für die zentrale als auch für die dezentrale
Analyse genutzt werden. Der Retrieval-Teil des DUP erzeugt zwei Tabellen mit den für die Analyse benötigten Inhalten.
Diese Tabellen sollen entweder erzeugt und an die datenauswertendende Stelle übergeben werden (zentrale Analyse) oder
in den DIZen analysiert werden (dezentrale Analyse). Bei der zentralen Analyse werden die o.g. Tabellen in das
auszuleitende Verzeichnis `outputGlobal` geschrieben, bei der dezentralen Analyse werden die Analyseergebnisse
(Textdateien und ROC-Plots in PDF-Dateien) in dieses Verzeichnis geschrieben.

Die **Datenqualitätsanalyse** braucht **nur einmal auf denselben Retrieval**-Daten gemacht zu werden. Wird eine Analyse
wiederholt, kann man über die Umgebungsvariable bzw. Option `DATA_QUALITY_REPORT` die Datenqualitätsanalyse
ausschalten und damit die **Laufzeit erheblich verkürzen**.

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

[dupctl]: https://git.smith.care/smith/uc-phep/dup-control
[dupctl#install]: https://git.smith.care/smith/uc-phep/dup-control#installation
[dupctl#workdir]: https://git.smith.care/smith/uc-phep/dup-control#working-directory
[dupctl#settings]: https://git.smith.care/smith/uc-phep/dup-control#global-settings
