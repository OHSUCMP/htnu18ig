# Execute the plan definitions with the requests in this directory and write the
# responses.
#
# intended to be executed from htnu18ig/input/pagecontent/requests folder (paths in this script are relative)
#
import os
import re
import requests

cqf_ruler_url = "http://localhost:8080/cqf-ruler-r4/cds-services/plandefinition-"
only_folders = ['Hypertension']
only_files = []

for folder in os.listdir("."):
    if os.path.isdir(folder):
        if not only_folders or folder in only_folders:
            for filename in sorted(os.listdir(folder)):
                if not only_files or filename in only_files:
                    print(filename)
                    path = os.path.join(folder, filename)
                    with open(path, 'r') as f:
                        whole = f.read()
                        url = cqf_ruler_url + folder
                        headers = {'Accept' : 'application/json', 'Content-Type' : 'application/json'}
                        response = requests.post(url, data=whole, headers=headers)
                        with open(os.path.join("../responses", path), 'w') as nf:
                            # Replace timestamp info in Goals so we get consistent responses when we rerun this
                            replacement = re.sub('-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}', '-1', response.text)
                            nf.write(replacement)
