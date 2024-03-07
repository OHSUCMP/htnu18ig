# Import FHIR resources into an open FHIR Server
# Provide the url of the FHIR server and the base directory where the JSON files live.
# It will recurse through. By default it loads all resources, but this is problematic with Logica
# sandbox which checks references. For that load "Patient" resources first.
import os
import re
import requests

directory = "/Users/yateam/HTN/htnu18ig/input/tests/plandefinition"
print("Choose resources to load or hit enter to load all:")
resources = input("hypertension, ae, monitoring, pharma, nonpharm, emergency, other\n").lower()
if resources == "hypertension":
 	directory = directory + "/Hypertension"
elif resources == "ae":
    directory = directory + "/AdverseEvents"
elif resources == "monitoring":
 	directory = directory + "/Monitoring"
elif resources == "pharma":
    directory = directory + "/Pharma"
elif resources == "nonpharm":
    directory = directory + "/NonPharmacologicIntervention"
elif resources == "emergency":
    directory = directory + "/HypertensiveEmergency"  
elif resources == "other":
    directory = directory + "/Other"  

logica_url = "https://api.logicahealth.org/coachdev/open/"
smart_url = "https://r4.smarthealthit.org/"
meld_url = "https://gw.interop.community/COACHsandbox/data/"
bearer = ""
print("Choose FHIR Server:")
server = input("logica, smart, meld\n").lower()
if server == "logica":
    fhir_url = logica_url
elif server == "smart":
    fhir_url = smart_url
elif server == "meld":
    fhir_url = meld_url
    print("For meld, extract the bearer token from developer tools application storage in the browser")
    bearer = input("Enter Token\n")
else:
    print("Server not understood. Enter the url:")
    fhir_url = input("Ex: https://api.logicahealth.org/coachdev/open/\n")

load_resource_type = "all"
print("Not limiting by Resource Type")
override = input("Override? y/n\n")
if (override.lower() == "y"):
    load_resource_type = input("The resource type to load\n")

for root, dirs, files in os.walk(directory, topdown=False):
   for name in files:
       if re.match('.*\.json', name) and not re.match('tests-.*\.json', name):
           with open(os.path.join(root, name), 'r') as f:
               whole = f.read()
               resourceType = re.search('.*"resourceType": "(.*?)",.*', whole).group(1)
               if (load_resource_type == "all" or load_resource_type.lower() == resourceType.lower()):
                   resourceId = re.search('.*"id": "(.*?)",.*', whole).group(1)
                   url = fhir_url + resourceType + "/" + resourceId
                   headers = {'Accept' : 'application/json', 'Content-Type' : 'application/json', 'Authorization' : 'Bearer ' + bearer}
                   r = requests.put(url, data=whole, headers=headers)
                   print(r.text)
