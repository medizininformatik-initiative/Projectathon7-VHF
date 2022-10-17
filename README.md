# ![Status: Entwurf](https://img.shields.io/badge/Status-Entwurf-yellow.svg) VHF Vorhofflimmern

## Einführung

Dieses Projekt führt das DUP Vorhofflimmern (VHF) aus. Es kann sowohl für die zentrale als auch für die dezentrale
Analyse genutzt werden. Der Retrieval-Teil des DUP erzeugt zwei Tabellen mit den für die Analyse benötigten Inhalten.
Diese Tabellen sollen entweder erzeugt und an die datenauswertendende Stelle übergeben werden (zentrale Analyse) oder
in den DIZen analysiert werden (dezentrale Analyse). Bei der zentralen Analyse werden die o.g. Tabellen in das
auszuleitende Verzeichnis 'outputGlobal' geschrieben, bei der dezentralen Analyse werden die Analyseergebnisse
(Textdateien und ROC-Plots in PDF-Dateien) in dieses Verzeichnis geschrieben.

## Verwendung

### dupctl (Docker)

Eine einfache und reproduzierbare Ausführung der DUPs wird über das dupctl Command Line Interface (cli)
sichergestellt. Dafür sind folgende Schritte nötig:

* Installation dupctl (siehe [DUP Control Readme][dupctl#install])


* Arbeitsverzeichnis wählen
  *  Es muss ein Verzeichnis gewählt werden, in dem dupctl Kommandos ausgeführt werden sollen. Die Ergebnisse der DUPs
  werden im gleichen Verzeichnis gespeichert! Siehe auch [DUP Control Readme][dupctl#workdir]
 

* `config.toml` im Arbeitsverzeichnis erstellen
  * Zum Ausführen des DUP muss eine DUP Control Konfigurationsdatei (`config.toml`) im Arbeitsverzeichnis liegen. 
  *  Vorlage mit allen Parametern (sowohl für das Retrieval als auch für die Analyse): [config.toml](.\config.toml)


* Ausführung des Retrievals
  * Wenn alle Retrieval-Parameter in der `config.toml` angegeben wurden, kann das Retrieval im Arbeitsverzeichnis über
  folgendes Kommando gestartet werden:
```bash
dupctl retrieve --dup vhf
```


* Ausführung der Analyse
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

Bei Bedarf können DUPs auch ohne den Einsatz von Docker durchgeführt werden.

*Die manuelle Ausführung ist **nicht** durch das downloaden/klonen dieses Repositories möglich!*
Stattdessen muss das Workpackage in Form von Archiven mittels folgender Links heruntergeladen werden. Die Archive
enthalten alle nötigen Skripte für eine manuelle Ausführung mittels R.

<div align="center">
    Download als ZIP Archiv:
    <a href="https://git.smith.care/smith/uc-phep/dup/vhf/-/jobs/artifacts/master/download?job=retrieval::publish-archive">[Retrieval]</a>
    <a href="https://git.smith.care/smith/uc-phep/dup/vhf/-/jobs/artifacts/master/download?job=analysis::publish-archive">[Analysis]</a>
</div>

* **R Version: 4.2.0**

* **CRAN Snaphot Datum: 2022-06-22**

Die weiteren Schritte der manuellen Ausführung sind in der [DUP README][readme] erläutert.


[dupctl]: https://git.smith.care/smith/uc-phep/dup-control
[dupctl#install]: https://git.smith.care/smith/uc-phep/dup-control#installation
[dupctl#workdir]: https://git.smith.care/smith/uc-phep/dup-control#working-directory
[dupctl#settings]: https://git.smith.care/smith/uc-phep/dup-control#global-settings
[readme]: https://git.smith.care/smith/uc-phep/dup/readme
