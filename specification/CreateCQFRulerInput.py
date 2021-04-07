# Given a directory with patient FHIR resources, bundle it into a single JSON file for use with CQF-Ruler
import os
import re
import json

#resource_directory = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/Hypertension/H-RecommendMoreBPs"
resource_directory = input("Enter the path to the FHIR resources for the patient\n")

match = re.search('^(.*)/(.*)$', resource_directory)
directory = match.group(1)
ident = match.group(2)

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
for folder in os.listdir(resource_directory):
    folder_path = os.path.join(resource_directory, folder)
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
