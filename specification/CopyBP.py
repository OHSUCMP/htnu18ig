# Given a directory with patient FHIR resources, copy it to a new directory with new id
import os
import re

old_bp = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/NonPharmacologicIntervention/NPI-ActivityReminder/Observation/observation-NPI-ActivityReminder-6.json"
new_bp = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/NonPharmacologicIntervention/NPI-ActivityReminder/Observation/observation-NPI-ActivityReminder-8.json"

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
    new_file_content = new_file_content.replace('2022-12-09', effectiveDate)
    new_file_content = new_file_content.replace('128.65', sbp)
    new_file_content = new_file_content.replace('81.52', dbp)

    with open(new_bp, 'w') as nf:
        nf.write(new_file_content)
