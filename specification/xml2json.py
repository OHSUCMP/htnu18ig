#!/usr/bin/python3.5
import re
import glob
import os, os.path
import shutil
import itertools

#For Windows vs Unix/Linux line ending issues
lineend = "\r\n"


print("\nXML to .json conversion\n")
user_dir = input("Convert the XML files in which directory? ")
top_dir = os.getcwd()
work_dir = os.path.join(top_dir,user_dir)
os.chdir(work_dir)

xml_file_num=0

#For multiline serching - not needed
#lineN5=lineN4=lineN3=lineN2=lineN1=line=""

#Define strings and lists
json_id = "" ; json_url = "" ; json_name = "" ; json_publisher = "" ; json_date = ""
json_conceptVS_list = [] ; json_codeVS_list = [] ; json_versionVS_list = [] ; json_nameVS_list = []

#find the xml files and write the json files
for xml_file in glob.glob("*.xml"):
	xml_file_num+=1
	xml_fileobj = open(xml_file, 'r')
	xml_lines = xml_fileobj.read()

	xml_base = str(xml_file).rstrip(".xml")
	json_file = xml_base + ".json"
	json_fileobj = open(json_file, "w")

	#search through the xml files to find the important data for writing into json
	json_id = re.search(r'(DescribedValueSet ID=")([0-9.]+)(")', xml_lines).group(2)
	json_url = re.search(r'(xmlns:xsi=")([\w:/.-]+)(">)', xml_lines).group(2)
	json_version = re.search(r'(version=")([\w\s\)\(:/.-]+)(">)', xml_lines).group(2)
	json_name = re.search(r'(displayName=")([\w\s\)\(:/.-]+)(")', xml_lines).group(2)
	json_publisher = re.search(r'(<ns0:Source>)([\w\s\)\(:/.-]+)(</ns0)', xml_lines).group(2)
	json_status = re.search(r'(<ns0:Status>)([\w\s\)\(:/.-]+)(</ns0)', xml_lines).group(2)
	json_date = re.search(r'(<ns0:RevisionDate>)([\w\s\)\(:/.-]+)(</ns0)', xml_lines).group(2)
	json_codeVS = re.search(r'(codeSystem=")([\w.]+)(")', xml_lines).group(2)


	#Within Valuesets, VS, "findall" finds many repeating concept codes/OIDs, 
	#later get just the useful part with re.search.  
	#Note "json_versionVS" suits a different purpose than "json_version".
	json_conceptVS = re.findall(r'Concept code="[\w]+"', xml_lines)
	#json_codeVS can be standalone or included in the value set for extended VS
	#seems to work better as standalone.
	json_codeVS = re.search(r'(codeSystem=")([\w.]+)(")', xml_lines).group(2)
	#json_codeVS = re.findall(r'codeSystem="[\w.]+"', xml_lines)
	json_versionVS = re.findall(r'codeSystemVersion="[\w\s\)\(:/.-]+"', xml_lines)
	json_nameVS = re.findall(r'displayName=".*"/>', xml_lines)


	#Get rid of list element 0 (do not want all the concatenated items)
	#json_conceptVS.pop(0) ; json_codeVS.pop(0) ; json_versionVS.pop(0) ; json_nameVS.pop(0)
	
	#print(xml_file + " and list: " + str(json_conceptVS) + "\n")
	

	#later get just the useful part with re.search, later write in the json file
	#loop together will be useful/necessary when lines must all be printed together  
	for i in json_conceptVS:
		json_conceptVS_list.append(re.search(r'(Concept code=")([\w].+)(")', i).group(2))
	
	#only for extended valuesets, VS.
	#for j in json_codeVS:
	#	json_codeVS_list.append(re.search(r'(codeSystem=")([\w.]+)(")', j).group(2))
		
	for k in json_versionVS:
		json_versionVS_list.append(re.search(r'(codeSystemVersion=")([\w\s\)\(:/.-]+)(")', k).group(2))
		
	for l in json_nameVS:
		json_nameVS_list.append(re.search(r'(displayName=")(.*)("/>)', l).group(2))

	#For troubleshooting to ensure the correct data is captured.
	#print(xml_file + " and list: " + str(json_conceptVS_list) + "\n")
	#print(xml_file + " and list: " + str(json_codeVS_list) + "\n")
	#print(xml_file + " and list: " + str(json_versionVS_list) + "\n")
	#print(xml_file + " and list: " + str(json_nameVS_list) + "\n")
	
	#Write to the json file in the standard format, substitute the values from the xml file 
	json_fileobj.write('{' + lineend)
	json_fileobj.write('  "resourceType": "ValueSet",' + lineend)
	json_fileobj.write('  "id": "' + json_id + '",' + lineend)
	json_fileobj.write('  "url": "http://cts.nlm.nih.gov/fhir/ValueSet/' + json_id + '",' + lineend)
	json_fileobj.write('  "version": "' + json_date + '",' + lineend)
	json_fileobj.write('  "name": "' + json_name + '",' + lineend)
	json_fileobj.write('  "status": "' + json_status + '",' + lineend)
	json_fileobj.write('  "date": "' + json_date + '",' + lineend)
	json_fileobj.write('  "publisher": "' + json_publisher + '",' + lineend)
 
	json_fileobj.write('  "compose": {' + lineend)
	json_fileobj.write('    "include": [' + lineend)
	json_fileobj.write('      {' + lineend)
	
	#The system can be from many places usually SNOMED or LOINC.  The major ones are substituted
	#The rest can be added by hand or coded in as needed.  A Google search of the code will take 
	#one to a urn number to website mapping page or use https://www.hl7.org/fhir/terminologies-systems.html
	if   (json_codeVS == "2.16.840.1.113883.6.96"):
		json_fileobj.write('        "system": "http://snomed.info/sct",' + lineend)
	elif (json_codeVS == "2.16.840.1.113883.6.1"):
		json_fileobj.write('        "system": "http://loinc.org",' + lineend)
	elif (json_codeVS == "2.16.840.1.113883.6.88"):
		json_fileobj.write('        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",' + lineend)
	elif (json_codeVS == "2.16.840.1.113883.6.12"):
		json_fileobj.write('        "system": "http://www.ama-assn.org/go/cpt",' + lineend)
	elif (json_codeVS == "2.16.840.1.113883.6.8"):
		json_fileobj.write('        "system": "http://unitsofmeasure.org",' + lineend)
	elif (json_codeVS == "2.16.840.1.113883.6.3"):
		json_fileobj.write('        "system": "http://hl7.org/fhir/sid/icd-10",' + lineend)
	elif (json_codeVS == "2.16.840.1.113883.6.42"):
		json_fileobj.write('        "system": "http://hl7.org/fhir/sid/icd-9-cm",' + lineend)		
	else: 
		json_fileobj.write('        "system" : "urn:oid:' + str(json_codeVS) + '",' + lineend)

	json_fileobj.write('          "concept": [' + lineend)
	
	#There are multipe OID codes per valueset, so write all of them.
	m = 0
	while m < len(json_conceptVS_list): 
		json_fileobj.write('          {' + lineend)
		#json_fileobj.write('        "system": "' + json_codeVS_list[m] + '",' + lineend)
		#json_fileobj.write('        "version": "' + json_versionVS_list[m] + '",' + lineend)
		json_fileobj.write('            "code": "' + json_conceptVS_list[m] + '",' + lineend)
		json_fileobj.write('            "display": "' + json_nameVS_list[m] + '"' + lineend)
		
		#Put commas on all but the last code block
		if m == (len(json_conceptVS_list) - 1):
			json_fileobj.write('          }' + lineend)
			m += 1
			continue
		json_fileobj.write('          },' + lineend)
		m += 1

	#final touches the json file 
	json_fileobj.write('        ]' + lineend)
	json_fileobj.write('      }' + lineend)
	json_fileobj.write('    ]' + lineend)
	json_fileobj.write('  }' + lineend)
	json_fileobj.write('}' + lineend)

	#Close files and restart lists
	xml_fileobj.close()
	json_fileobj.close()
	
	json_conceptVS = []
	json_codeVS = []
	json_versionVS = []
	json_nameVS = []

	json_conceptVS_list = []
	json_codeVS_list = []
	json_versionVS_list = []
	json_nameVS_list = []

print(str(xml_file_num) + " xml files in " + work_dir + " processed")