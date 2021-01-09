#!/usr/bin/python3
from datetime import date, datetime, timedelta
from dateutil.relativedelta import relativedelta
import re
import glob
import os, os.path
import shutil

file_list = []
today = datetime.today()
#print("Today is :" + str(today))

print("\nMITRE Synthetic data search program\n")
user_dir = input("What directory to search? ")
top_dir = os.getcwd()
work_dir = os.path.join(top_dir,user_dir)
os.chdir(work_dir)

for json_files in glob.glob("*.json"):
	file_list.append(json_files)
print("There are " + str(len(file_list)) + " patient files in " + work_dir)

#Get ages of inclusion criteria
low_age  = input("\nMinimum patient age in years? ")
low_age_date = (today - relativedelta(years=int(low_age)))
high_age = input("Maximum patient age in years? ")
high_age_date = (today - relativedelta(years=int(high_age)))
print("Searching for patients between " + low_age + " and " + high_age + " years old")


print("\nTo find suitable patients, enter as many regular expressions (regex) as desired")
print('When finished enter "STOP!"\n')
search_num = 0
search_term = ""
found_list = []
low_age_count = 0
high_age_count = 0
while search_term != "STOP!":
	search_num+=1
	search_term = input("Regular expression " + str(search_num) + " for searching: ")
	if search_term == "STOP!":
		print("Stopping loop\n")
	else:
		print("Regex search string: " + search_term + " entered\n")
		for i in file_list:
			search_file = open(i, 'r')
			search_lines = search_file.read()
			pt_birth = re.search(r'("birthDate": ")([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])', search_lines).group(2)
			birth_date = datetime.strptime(str(pt_birth), '%Y-%m-%d')
			if(search_num == 1):
				#print(birth_date)
				#pt_age = relativedelta(today, birth_date).years
				#print(pt_age)
				if(birth_date > low_age_date):
					low_age_count+=1
					continue	
				if(birth_date < high_age_date):
					high_age_count+=1
					continue
			if re.search(search_term, search_lines, re.DOTALL):
			#if search_term in search_lines:
				print("Found- " + search_term + " -in " + i)
				found_list.append(i)
			
			search_file.close()		
		
		if(search_num ==1):
			print("\nOut of " + str(len(file_list)) + " patients, " + str(low_age_count) + " are under the minimum age")
			print("Out of " + str(len(file_list)) + " patients, " + str(high_age_count) + " are over the maximum age")
		print(str(len(found_list)) + " patient files match regular expression- " + search_term + " -within the age range\n")
		file_list = found_list
		found_list = []
