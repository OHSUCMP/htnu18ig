# Given a directory with patient FHIR resources, copy it to a new directory with new id
import os
import re

old_directory = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/AdverseEvents/AE-UntreatedAdverseEvent"
new_directory = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/AdverseEvents/AE-LowOfficeBPs"

old_ident = re.search('.*/(.*)$', old_directory).group(1)
new_ident = re.search('.*/(.*)$', new_directory).group(1)

if not os.path.exists(new_directory):
    os.makedirs(new_directory)

for folder in os.listdir(old_directory):
    old_folder = os.path.join(old_directory, folder)
    new_folder = os.path.join(new_directory, folder)
    if not os.path.exists(new_folder):
        os.makedirs(new_folder)
    if os.path.isdir(old_folder):
        for filename in os.listdir(old_folder):
            new_filename = filename.replace(old_ident, new_ident)
            with open(os.path.join(old_folder, filename), 'r') as f:
                whole = f.read()
                new_file_content = whole.replace(old_ident, new_ident)
                with open(os.path.join(new_folder, new_filename), 'w') as nf:
                    nf.write(new_file_content)
