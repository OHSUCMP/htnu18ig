# Given a directory with patient FHIR resources, copy it to a new directory with new id
import os
import re

old_bp = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/Hypertension/H-HTNStage2LastBPSetAmbulatory/Observation/observation-H-HTNStage2LastBPSetAmbulatory-5.json"
new_bp = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/NonPharmacologicIntervention/NPI-DietaryReminder/Observation/observation-NPI-DietaryReminder-2.json"

new_bp = input("Path to new BP observation\n")
effectiveDate = input("The date formatted as yyyy-MM-dd\n")
sbp = input("Systolic to two decimals\n")
dbp = input("Diastolic to two decimals\n")

old_observation_id = re.search('.*/(.*).json$', old_bp).group(1)
new_observation_id = re.search('.*/(.*).json$', new_bp).group(1)
old_ident = re.search('.*/(.*)/.*/.*json$', old_bp).group(1)
new_ident = re.search('.*/(.*)/.*/.*json$', new_bp).group(1)

print(old_observation_id)
print(new_observation_id)


with open(old_bp, 'r') as f:
    whole = f.read()
    new_file_content = whole.replace(old_observation_id, new_observation_id)
    new_file_content = new_file_content.replace(old_ident, new_ident)
    new_file_content = new_file_content.replace('2021-01-06', effectiveDate)
    new_file_content = new_file_content.replace('165.50', sbp)
    new_file_content = new_file_content.replace('89.96', dbp)

    with open(new_bp, 'w') as nf:
        nf.write(new_file_content)
