# Import FHIR resources into an open FHIR Server
# Provide the url of the FHIR server and the base directory where the JSON files live.
# It will recurse through. By default it loads all resources, but this is problematic with Logica
# sandbox which checks references. For that load "Patient" resources first.
import os
import re
import requests

directory = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition/Hypertension"
print("Loading resources into FHIR server from " + directory)
override = input("Override? y/n\n")
if override.lower() == "y":
 	directory = input("The path to the resources\n")

fhir_url = "https://api.logicahealth.org/htnu18r42/open/"
print("FHIR Server URL: " + fhir_url)
override = input("Override? y/n\n")
if override.lower() == "y":
    fhir_url = input("The path to the FHIR server\n")

load_resource_type = "all"
print("Not limiting by Resource Type")
override = input("Override? y/n\n")
if (override.lower() == "y"):
    load_resource_type = input("The resource type to load\n")

for root, dirs, files in os.walk(directory, topdown=False):
   for name in files:
       if re.match('.*\.json', name) and not re.match('cqfruler-.*\.json', name):
           with open(os.path.join(root, name), 'r') as f:
               whole = f.read()
               resourceType = re.search('.*"resourceType": "(.*?)",.*', whole).group(1)
               if (load_resource_type == "all" or load_resource_type.lower() == resourceType.lower()):
                   resourceId = re.search('.*"id": "(.*?)",.*', whole).group(1)
                   url = fhir_url + resourceType + "/" + resourceId
                   headers = {'Accept' : 'application/json', 'Content-Type' : 'application/json'}
                   r = requests.put(url, data=whole, headers=headers)
                   print(r.text)
