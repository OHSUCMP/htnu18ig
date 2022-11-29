# Given a directory with patient FHIR resources, bundle it into a single JSON file for use with CQF-Ruler
import os
import re
import json

# Locate the root directory of the project
m = re.search('(.*?htnu18ig).*', os.getcwd())
root_directory = m.group(1)
patient_directory = os.path.join(root_directory, "input/tests/plandefinition/")
plan_definition = input("Enter the plan definition\n")
patient_directory = os.path.join(patient_directory, plan_definition)
output_directory = os.path.join(root_directory, "tests/requests/" + plan_definition)

for patient_folder in os.listdir(patient_directory):
    patient_path = os.path.join(patient_directory, patient_folder)
    if os.path.isdir(patient_path):
        directory = patient_directory
        ident = patient_folder
        template = {
          "hookInstance": "test",
          "fhirServer": "https://api.logicahealth.org/htnu18r42/open",
          "hook": "patient-view",
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
            if os.path.isdir(folder_path):
                for filename in os.listdir(folder_path):
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
        with open(os.path.join(output_directory, "cqfruler-" + ident + ".json"), 'w') as f:
            print(f.name)
            f.write(json.dumps(template, indent = 2))
