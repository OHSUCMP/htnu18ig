# Import the following FHIR resources into CQF Ruler (R4)
# - ValueSets
# - Libraries
# - PlanDefinitions
#
# intended to be executed from htnu18ig/input folder (paths in this script are relative)
#
import os
import re
import requests

paths = ["vocabulary/valueset", "resources/library", "resources/plandefinition"]

cqf_ruler_url = "http://localhost:8080/cqf-ruler-r4/fhir/"

for path in paths:
  for root, dirs, files in os.walk(path, topdown=False):
    for name in files:
      if re.match('.*\.json', name):
        with open(os.path.join(root, name), 'r') as f:
          print("processing " + name)
          
          whole = f.read()
          resourceType = re.search('.*"resourceType": "(.*?)",.*', whole).group(1)
          resourceId = re.search('.*"id": "(.*?)",.*', whole).group(1)
          url = cqf_ruler_url + resourceType + "/" + resourceId
          headers = {'Accept' : 'application/json', 'Content-Type' : 'application/json'}
          r = requests.put(url, data=whole, headers=headers)


