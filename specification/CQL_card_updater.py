#!/usr/bin/python3
import glob
import os, os.path
import re
import shutil
import pandas as pd
import fileinput

#from pandas import ExcelFile


#The purpose of this program is to import the summary/recommendations and the 
#detail/rationale along with other attributes of the CDS Hooks Card system into
#our CQL program for fast efficient updating.  The card attributes are here: 
# https://cds-hooks.hl7.org/ballots/2018May/specification/1.0/#card-attributes

#The program looks for:
# A directory named CQL at the same level as this program
# Within the directory:
# 	Excel sheet named XCQL_cards.xlsxY, where X and Y are user defined
# 	All the CQL files that need to be updated.
# The sheets within the Excel program need to have the same names as the 
# CQL files that need to be updated.
# The first column should be *unique* tag for the program to find
# the subsequent columns should follow the order given in the CDS CArds


lineend = "\r\n"
line1 = ""
line2 = ""
line3 = ""
num_files_deleted = 0
num_files = 0
json_list = []
cql_list = []
cql_trunc_list = []
XL_sheet_list = []
num_json_files = 0
printeron = True
CQL_match = False
Backup_existed = False
cards_list = ['define "Summary":', 'define "Details":','define "Rationale":', 'define "Recommendation":', 'define "Indicator":', 'define "Source":', 'define "Suggestions":', 'define "SelectionBehavior":', 'define "Links":', 'define "details":', 'define "summary":', 'define "indicator":', 'define "source":', 'define "suggestions":', 'define "selectionBehavior":', 'define "links":' ]


print("\n***Updating .cql files with card data in CQL_cards.xlsx***\n")
print("Finding .cql files and Excel worksheets within the CQL directory")
print("  31 character limit on Excel worksheet names, truncating .cql file names")
#move to the CQL directory 
top_dir = os.getcwd()
os.chdir('CQL')

#Backup all the CQL files. If Backup already exists, do not backup.
if not os.path.isdir('Backup'):
	print("  No backup directory exists.  Backing up files")
	os.mkdir('Backup')
	Backup_existed = True

#Delete the old files
print("  Removing old card files, .cards_to_add and .no_cards")
for old_cards in glob.glob("*.cards_to_add"):
	os.remove(old_cards)

for old_no_cards in glob.glob("*.no_cards"):
	os.remove(old_no_cards)



# Get the .cql file names in the CQL directory
# NOTE: there is a 31 character limit on Excel worksheet, so it will be
# the root of the search string, rather than the .cql filenames.
#The CQL filename list elements will be truncated for a match 
for cql_file in glob.glob("*.cql"):
	cql_list.append(cql_file)

	#Copy all the .cql files for backup, only once, so it will not write over old files.
	if Backup_existed == True:
				shutil.copyfile(cql_file, os.path.join('Backup', cql_file +'.old'))

print("  CQL files: " + str(cql_list))
cql_trunc_list = [elem[:30][:-4] for elem in cql_list]
print("  Truncated CQL: " + str(cql_trunc_list))


# We may want to date or specify the Excel-CQL-cards file by subject
# So it just need CQL_cards.xlsx in the name somewhere
for CQL_cards_Excel_file in glob.glob("*CQL_cards.xlsx*"):
	#print("The Excel file with CQL cards is: " + CQL_cards_Excel_file)
	break

# Open a matching Excel file and all the sheets within it using Pandas, pd
# sheet_name none will import all shees with the names specified in Excel
XL_file = pd.read_excel(CQL_cards_Excel_file, sheet_name=None)
print("\nLoading worksheets from Excel file " + CQL_cards_Excel_file)
for ws in list(XL_file.keys()):
	XL_sheet_list.append(ws)
	#print("Excel worksheets: ", str(XL_sheet_list))
	df = pd.read_excel(CQL_cards_Excel_file, sheet_name=ws)
	print("  " + str(ws))
	#print(df)
	
	#Open a file corresponding to a .cql file (31 characters)
	card_file_obj = open(ws + ".cards_to_add", "a")

	#Append card text to the open file
	#Within a worksheet print all the values by column and row
	for i in range(2, len(df.columns)):
		#print("Column name: " + df.columns[i])
		column_header = str(df.columns[i])
		if column_header == "summary":
			column_header = "Recommendation"
		if column_header == "detail":
			column_header = "Rationale"
		card_file_obj.write('define "'+ column_header +'":\n')

		for j in range(1, len(df)):
			#Subpopulation must be in column 2 of worksheets. 
			#"Strings" are encapsulated by quotes, but null is bare.
			cell_value=("'" + str(df.iloc[j][df.columns[i]]) + "'")
			subpopulation_value=(df.iloc[j][df.columns[1]])
			if cell_value == ("'nan'" or "'Nan'" or "''"):
				cell_value = "null"

			#Syntax for 1st, last, and all other rows to match CQL formatting		
			if j == 1:
				card_file_obj.write(str('  if "' + str(subpopulation_value) + '" then ' + cell_value + "\n"))
			elif j == (len(df)-1):
				card_file_obj.write(str('  else ' + cell_value + "\n\n"))
			else:
				card_file_obj.write(str('  else if "' + str(subpopulation_value) + '" then ' + cell_value + "\n"))
			
	card_file_obj.close()
		
# Try to match the Excel sheets with the .cql filename
for XL_sheet in XL_sheet_list:
	print("\nExcel worksheet is: " + str(XL_sheet))

	for cql_element in cql_list:
		#print("  The CQL full element is:  " + str(cql_element))
		#The [2:-6] should remove the braces and .cql from the filename
		# [:30] for the 31 character limit, Python starts at 0 for the first character
		#CQL_element_bare=str([cql_element])[2:-2]
		CQL_trunc=str([cql_element[:30]])[2:-6]
		
		#print("  Truncated CQL element is: " + CQL_trunc)
		if CQL_trunc == str(XL_sheet):
			print("  " + cql_element + " matches the Excel worksheet.")
			CQL_match = True

			#Once there is a match, open the file.
			with open (cql_element) as open_cql:
				print("  Finding and removing old cards:" + cql_element)
				
				#Open a file to write to
				cql_no_cards = open(cql_element + ".no_cards", 'a')
				#print("PrinterOn at beginning is " + str(printeron))

				for cql_line in open_cql:
					line3 = line2
					line2 = line1
					line1 = cql_line				
					#DO NOT capture the old material.
					for match in cards_list:
						if match in cql_line:
							block_match = match
							print ("  Found a matching card-- " + match)
							printeron = False
					
					#Start capturing again at the end of matching block
					if printeron == False:		
						if cql_line == ('\n' or '\r\n'):
							#print("  Reached end of the-- " + block_match + " --block")
							printeron = True
						
					#Write while not in a matching block
					#and not lots of blank lines
					if cql_line != ('\n' or '\r\n'):
						if line2 != ('\n' or '\r\n'):
							if line3 != ('\n' or '\r\n'):
								if printeron == True:
									cql_no_cards.write(cql_line)

				cql_no_cards.close()
			open_cql.close()
	if CQL_match == False:
		print("  Checked all .cql files. None matched the Excel worksheet-- " + XL_sheet)
	CQL_match = False
	printeron = True

print("\nCombining stripped .cql files with new cards")
#Now combine the old stripped .no_cards files with the .cards_to_add
for new_cards in glob.glob("*.cards_to_add"):
	no_cards_cql = str(new_cards)[:-13] + ".cql.no_cards"
	final_cql = str(new_cards)[:-13] + ".cql"

	#Only for the files that matched previous and exist now
	if os.path.isfile(no_cards_cql):
		print("  " + new_cards + " with " + str(new_cards)[:-13] + ".cql.no_cards")
		no_cards_cql_obj = open(no_cards_cql, 'a+') 
		new_card_obj = open(new_cards, 'r') 

		#Need an extra space to separate old from new
		no_cards_cql_obj.write("\n")
		no_cards_cql_obj.write(new_card_obj.read())
		no_cards_cql_obj.close()
		new_card_obj.close()

		#Replace the old .cql file with the newly improved .no_cards
		shutil.copy(no_cards_cql, final_cql)


print("\nProcessed all worksheets listed in: " + CQL_cards_Excel_file + "\n")

cleanup = input("Cleaning up .no_cards and .cards_to_add files (Y/N): ")
if cleanup in ("Y", "y", "yes", "Yes"):
	print("  Removing old card files, .cards_to_add and .no_cards")
	for old_cards in glob.glob("*.cards_to_add"):
		os.remove(old_cards)
	for old_no_cards in glob.glob("*.no_cards"):
		os.remove(old_no_cards)
else:
	print("")
print("  Backup directory still holds the original .cql files")

print("\n***DONE***\n")
