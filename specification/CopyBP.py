# Given a directory with patient FHIR resources, copy it to a new directory with new id
import os
import re

old_bp = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/Monitoring/MU-TestCase5/Observation/observation-MU-TestCase5-17.json"
new_bp = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/Monitoring/MU-TestCase5/Observation/observation-MU-TestCase5-18.json"

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
    new_file_content = new_file_content.replace('2023-06-28', effectiveDate)
    new_file_content = new_file_content.replace('170', sbp)
    new_file_content = new_file_content.replace('100', dbp)

    with open(new_bp, 'w') as nf:
        nf.write(new_file_content)
