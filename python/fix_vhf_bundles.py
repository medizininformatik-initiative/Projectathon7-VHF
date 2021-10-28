import json
import os

for jsonfile in os.listdir('/home/tpeschel/servers/data/VHF-Testdaten-FHIR'):
  with open('/home/tpeschel/servers/data/VHF-Testdaten-FHIR/' + jsonfile) as infile:
    data   = json.load(infile)
    try:
      enc_id = data['entry'][4]['resource']['id']
      print(enc_id)
      data['entry'][2]['resource']['encounter'] = {'reference': 'Encounter/' + enc_id}
      with open("/home/tpeschel/servers/data/VHF-Testdaten-FHIR-Curated/" + jsonfile, "w") as outfile:
        json.dump(data, outfile, indent = 4)
    except Exception as e:
      print(e)
      print(enc_id)

