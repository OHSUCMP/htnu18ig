# Import CQL resources into the cqf-ruler HAPI FHIR Server
# Provide the directory where the JSON files live and the url of the FHIR server
# (This only does one directory at a time, but could easily be adapted to recurse)
import os
import re
import requests

directory = "/Users/yateam/HTN/htnu18ig/input/vocabulary/valueset"

print("Loading resources into FHIR server from " + directory)
override = input("Override? y/n\n")
if override.lower() == "y":
	directory = input("The path to the resources\n")

fhir_url = "http://localhost:8080/cqf-ruler-r4/fhir/"
print("FHIR Server URL: " + fhir_url)
override = input("Override? y/n\n")
if override.lower() == "y":
	fhir_url = input("The path to the FHIR server\n")

for filename in os.listdir(directory):
   with open(os.path.join(directory, filename), 'r') as f:
   		whole = f.read()
   		p = re.compile('.*"resourceType": "(.*?)",.*', re.MULTILINE | re.DOTALL)
   		m = p.match(whole)
   		resourceType = m.group(1)
   		p = re.compile('.*"id": "(.*?)",.*', re.MULTILINE | re.DOTALL)
   		m = p.match(whole)
   		resourceId = m.group(1)
   		url = fhir_url + resourceType + "/" + resourceId
   		headers = {'Accept' : 'application/json', 'Content-Type' : 'application/json'}
   		r = requests.put(url, data=whole, headers=headers)
   		print(r.text)  		
   		
