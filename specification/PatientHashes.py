# Given a salt, summarize the expected hashes for all the test patients
import os
import re
import hashlib

# Sandbox salt
salt = 'CHANGE_THIS_BEFORE_RUNNING_IN_PRODUCTION'

directory = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition"
for folder in os.listdir(directory):
    workflow_path = os.path.join(directory, folder)
    for patient in os.listdir(workflow_path):
        patient_path = os.path.join(workflow_path, patient)
        if os.path.isdir(patient_path):
            encoded = (patient + salt).encode('UTF-8')
            print(patient + "," + hashlib.sha256(encoded).hexdigest())
