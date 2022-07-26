# Changelog
*Note: This changelog reflects the changes until first released projectathon version*

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
