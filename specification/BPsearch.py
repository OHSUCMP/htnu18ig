#!/usr/bin/python3
from datetime import date, datetime, timedelta
from dateutil.relativedelta import relativedelta
import re
import glob
import os, os.path
import shutil


#Get all the files listed within the "In Population" file
json_list = []
In_pop_file = open("In_population.txt")
for jsonfile in In_pop_file:
	bare_line = jsonfile.strip()
	json_sep = bare_line.split()
	json_list.append(json_sep)
In_pop_file.close()



file_list = json_list
today = datetime.today()
#print("Today is :" + str(today))

print("\nIn population data search program\n")
user_dir = input("What directory to search? ")
top_dir = os.getcwd()
work_dir = os.path.join(top_dir,user_dir)
os.chdir(work_dir)


print("\nTo find suitable patients, enter as many regular expressions (regex) as desired")
print('When finished enter "STOP!"\n')

search_term = ""
line5=line4=line3=line2=line=""
while search_term != "STOP!":
	search_term = input("Regular expression for searching: ")
	if search_term == "STOP!":
		print("Stopping loop\n")
	else:
		print("Regex search string: " + search_term + " entered\n")
		for i in file_list:
			i=(str(i)[2:-2])
			print(i)
			with open(i) as searched_file:
				for line in searched_file:
					line=line.rstrip("\n")
					line5=line4
					line4=line3
					line3=line2
					line2=line
					if re.search(search_term, line5):
						print(line)
			searched_file.close()	

print("\nDone\n")		
