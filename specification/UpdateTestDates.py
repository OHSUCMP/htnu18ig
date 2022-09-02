# Update all tests with more recent dates so they are still valid
# Once this is complete, run CreateCQFRulerInput.py
import os
import re
import datetime
import json

def days_between(d1, d2):
    return abs((d2 - d1).days)

format = '%Y-%m-%d'  # The date format
# Locate the root directory of the project
m = re.search('(.*?htnu18ig).*', os.getcwd())
root_directory = m.group(1)

with open(os.path.join(root_directory, "tests/requests/lastValidDate.txt"), 'r') as f:
    date_time = f.read().strip()

last_valid_date = datetime.datetime.strptime(date_time, format).date()
today = datetime.date.today()
days_to_add = days_between(last_valid_date, today)

directory = os.path.join(root_directory, "input/tests/plandefinition")

for root, dirs, files in os.walk(directory, topdown=False):
   for name in files:
       if re.match('.*\.json', name):
           with open(os.path.join(root, name), 'r') as f:
               whole = f.read()
               dates = re.findall(r'[0-9]{4}-[0-9]{2}-[0-9]{2}', whole)
               for date in dates:
                   the_date = datetime.datetime.strptime(date, format).date()
                   new_date = the_date + datetime.timedelta(days=days_to_add)
                   whole = whole.replace(date, new_date.strftime(format))

           with open(os.path.join(root, name), 'w') as f:
               f.write(whole)

with open(os.path.join(root_directory, "tests/requests/lastValidDate.txt"), 'w') as f:
    f.write((last_valid_date + datetime.timedelta(days=days_to_add)).strftime(format))
