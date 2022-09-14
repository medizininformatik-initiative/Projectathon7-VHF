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
sichergestellt. Nach der Installation der cli (siehe [dupctl][dupctl]) wird das DUP Skript über eine Kommandozeile
wie folgt gestartet:

```bash
dupctl retrieve --dup vhf [...]
```
Für weitere Informationen bzgl. Retrieval: [VHF Retrieval README](retrieval/README.md)

```bash
dupctl analyze --dup vhf [...]
```
Für weitere Informationen bzgl. Analysis: [VHF Analysis README](analysis/README.md)

### Manuelle Ausführung

Bei Bedarf können DUPs auch ohne den Einsatz von Docker durchgeführt werden.

*Die manuelle Ausführung ist **nicht** durch das downloaden/klonen dieses Repositories möglich!*
Stattdessen muss das Workpackage in Form eines Archivs mittels folgenden Links heruntergeladen werden. Das Archiv
enthält alle nötigen Skripte und Libraries für eine manuelle Ausführung mittels R.

<div align="center"><a href="https://git.smith.care/smith/uc-phep/dup/vhf/-/jobs/artifacts/master/download?job=build-archive:latest">Download als ZIP Archiv</a></div>

* **R Version: 4.2.0**

* **CRAN Snaphot Datum: 2022-06-22**

Die weiteren Schritte der manuellen Ausführung sind in der [DUP README][readme] erläutert.


[dupctl]: https://git.smith.care/smith/uc-phep/dup-control
[readme]: https://git.smith.care/smith/uc-phep/dup/readme
