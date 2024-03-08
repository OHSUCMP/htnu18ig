# This script will take a CQF Ruler plan definition payload and break out each resource in the
# prefetch into individual files that can be used to execute CQL. This allows direct debugging
# of recommendations on production data when questions arise. Copy the payload json into
# the directory cqfruler-input. The output will go to the tests directory. That folder can be
# copied into input/tests/plandefinition/<Workflow> to test whichever recommendation workflow is in
# question. Gitignore is set to ignore the input/output directories and any folders that start with
# "PHI" so that none of these production tests get accidentally committed to the repo.
import os
import re
import json

# Locate the root directory of the project
input_directory = os.path.join(os.getcwd(), "cqfruler-input")
output_directory = os.path.join(os.getcwd(), "tests")

for filename in os.listdir(input_directory):
  if re.match('.*\.json', filename):
    with open(os.path.join(input_directory, filename), 'r') as f:
      resources = {}
      resource_array = json.loads(f.read())["prefetch"]["item1"]["resource"]["entry"]
      for item in resource_array:
        resource = item["resource"]
        resource_type = resource["resourceType"]
        if resource_type == 'Patient':
          patient_id = resource["id"]
        resources.setdefault(resource_type, []).append(resource)

  # Prepend the directory and patient id with "PHI-" so Git will ignore
  patient_dir = os.path.join(output_directory, "PHI-" + patient_id)
  if not os.path.exists(patient_dir):
    os.mkdir(patient_dir)
  for key in resources:
    resource_dir = os.path.join(patient_dir, key)
    if not os.path.exists(resource_dir):
      os.mkdir(resource_dir)
    for item in resources[key]:
      if "id" in item:
        item_id = item["id"]
        with open(os.path.join(resource_dir, item_id + ".json"), 'w') as out:
          item_as_string = json.dumps(item, indent = 2)
          replaced_item = item_as_string.replace(patient_id, "PHI-" + patient_id)
          out.write(replaced_item)
        
