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
# The cql file name without the extension and truncated to 31 character limit of Excel worksheet names
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
	if ws != 'Lookups':
		XL_sheet_list.append(ws)
		df = pd.read_excel(CQL_cards_Excel_file, sheet_name=ws)
		print("  " + str(ws))

		#Open a file corresponding to a .cql file (31 characters)
		card_file_obj = open(ws + ".cards_to_add", "a")
