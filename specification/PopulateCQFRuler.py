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
import sys

port = 8080
if len(sys.argv) > 1:
  port = sys.argv[1]

paths = ["../input/vocabulary/valueset", "../input/resources/library", "../input/resources/plandefinition", "../input/resources/device"]

cqf_ruler_url = "http://localhost:" + str(port) + "/fhir/"
print("CQF Ruler URL = " + cqf_ruler_url)

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
