# Given a directory with patient FHIR resources, bundle it into a single JSON file for use with CQF-Ruler
import os
import re
import json

#patient_directory = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/Hypertension"
patient_directory = input("Enter the path to the FHIR resources for all patients\n")

for patient_folder in os.listdir(patient_directory):
    patient_path = os.path.join(patient_directory, patient_folder)
    if os.path.isdir(patient_path):
        directory = patient_directory
        ident = patient_folder
        template = {
          "hookInstance": "test",
          "fhirServer": "http://localhost:8080/cqf-ruler-r4/fhir",
          "hook": "patient-view",
          "applyCql": True,
          "context": {
            "userId": "Practitioner/example",
            "patientId": "patient-id"
          },
          "prefetch": {
            "item1": {
              "response": {
                "status": "200 OK"
              },
              "resource": {
                "resourceType": "Bundle",
                "type": "transaction",
                "entry": [
                ]
              }
            }
          }
        }

        template["context"]["patientId"] = ident
        entry_array = []

        for folder in os.listdir(patient_path):
            folder_path = os.path.join(patient_path, folder)
            print(folder)
            if os.path.isdir(folder_path):
                for filename in os.listdir(folder_path):
                    print(filename)
                    if re.match('.*\.json', filename):
                        with open(os.path.join(folder_path, filename), 'r') as f:
                            entry = {
                                "resource": "resource",
                                "request": {
                                    "method": "PUT",
                                    "url": "request-url"
                                }
                            }
                            entry["resource"] = json.loads(f.read())
                            entry_array.append(entry)

        template["prefetch"]["item1"]["resource"]["entry"] = entry_array
        with open(os.path.join(directory, "cqfruler-" + ident + ".json"), 'w') as f:
            f.write(json.dumps(template, indent = 2))
