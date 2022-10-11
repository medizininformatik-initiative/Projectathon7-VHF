# ![Status: Entwurf](https://img.shields.io/badge/Status-Entwurf-yellow.svg) SMITH VHF Vorhofflimmern

## Einführung

Dieses Projekt führt das SMITH DUP Vorhofflimmern (VHF) aus. Dafür erzeugt dieses Skript zwei Tabellen mit den für die
Analyse benötigten Inhalten. Diese Tabellen sollen entweder zentral erzeugt und an die datenauswertendende Stelle
übergeben oder dezentral in den DIZen analysiert werden, das Analyseergebnis muss in diesem Fall manuell an die
Biometrie übergeben werden.

Das Readme beschreibt zunächst die technischen Details der Verwendung. Darunter sind die verwendeten
CodeSysteme/Ressourcen/Profile und der konzeptionelle Ablauf der Abfrage beschrieben.

## Verwendung

### dupctl (Docker)

Eine einfache und reproduzierbare Ausführung der SMITH PheP DUPs wird über das dupctl Command Line Interface (cli)
sichergestellt. Dafür sind folgende Schritte nötig:

* Installation dupctl (siehe [DUP Control Readme][dupctl#install]
* Arbeitsverzeichnis wählen

Wählen Sie ein Verzeichnis, in dem dupctl Kommandos ausgeführt werden sollen. Die Ergebnisse der DUPs werden im
gleichen Verzeichnis gespeichert! Siehe auch [DUP Control Readme][dupctl#workdir]

* Anlegen einer DUP Control Konfigurationsdatei (`config.toml`)

```toml
project = "smith"
registry = "registry.gitlab.com/smith-phep/dup"
```

* Ausführung des Retrievals

```bash
dupctl retrieve --dup vhf [...]
```
Für weitere Informationen bzgl. Retrieval: [VHF Retrieval README](retrieval/README.md)

* Ausführung der Analyse

```bash
dupctl analyze --dup vhf [...]
```
Für weitere Informationen bzgl. Analysis: [VHF Analysis README](analysis/README.md)

**Hinweis: Weitere Einstellungsmöglichkeiten von DUP Control sind in der [DUP Control README][dupctl#settings] zu finden.**

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
