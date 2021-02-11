#!/usr/bin/python3
import re
import glob
import os
import shutil

#The purpose of this python script is to split synthetic or real bundled
#data within a bundle.json file into a form that ATOM can process.  

#Atom requires .json files for conditions, encounters, observations etc.
#within their own directories named for the patient  

#For Windows vs Unix/Linux line ending issues
lineend = "\n"


print("\nSplitting all the .json files in the JSON directory \n")
print("Currently in directory:", os.getcwd())
top_dir = os.getcwd()
os.chdir('JSON')
print("Moving to:", os.getcwd())

num_files_deleted = 0
num_files = 0
json_list = []
num_json_files = 0

#Delete old directories and files, keep JSON directory clean 
for json_files in glob.glob("*.json"):
	json_list.append(json_files)
	os.rename(json_files, os.path.join(top_dir,json_files))

print("Clearing out old files/directories the JSON directory")
os.chdir("..")
shutil.rmtree("JSON")
os.mkdir("JSON")

#Only move files originally in the JSON directory.
for json_files in json_list:
	os.rename(json_files, os.path.join("JSON",json_files))

os.chdir("JSON")
for bundlejsonfiles in glob.glob("*.json"):
	num_json_files+=1

	#Make new directories consistent with ATOM expectations
	BundleDirectory = str(bundlejsonfiles).rstrip(".json")
	os.mkdir(BundleDirectory)
	SplitDirs = ["Condition", "Encounter", "Observation", "Patient"]
	for Dirs in SplitDirs:
		os.mkdir(os.path.join(BundleDirectory,Dirs))

	#Start working with the Bundle files
	if bundlejsonfiles.endswith(".json"):
		print("\nSplitting apart bundle file: ", bundlejsonfiles)
		file = open(bundlejsonfiles, 'r')
		filelines = file.readlines()
		print("Searching through", len(filelines), "lines.")
		file.close()

		#Separate bundled data into the files above.
		lineN5=lineN4=lineN3=lineN2=lineN1=line=""
		ConditionCount=EncounterCount=ObservationCount=PatientCount=0
		printeron=False
		with open(bundlejsonfiles) as bundlefiles:
			for line in bundlefiles:
				line=line.rstrip("\n")
				lineN4=lineN3
				lineN3=lineN2
				lineN2=lineN1
				lineN1=line

				if line.__contains__('"resourceType": "Condition",'):
					printeron=True
					BraceCount=1
					ConditionCount+=1
					ConditionName = "condition-" + str(BundleDirectory) + "-" + str(ConditionCount) + ".json"
					WriteFile = open(ConditionName, "w")
					IDName = "condition-" + str(BundleDirectory) + "-" + str(ConditionCount)
					CommonName = ConditionName
					WriteDir = "Condition"
					WriteFile.write("{" + lineend)
					WriteFile.write(line + lineend)
					continue
				
				elif line.__contains__('"resourceType": "Encounter",'):
					printeron=True
					BraceCount=1
					EncounterCount+=1
					EncounterName = "encounter-" + str(BundleDirectory) + "-" + str(EncounterCount) + ".json"
					WriteFile = open(EncounterName, "w")
					IDName = "encounter-" + str(BundleDirectory) + "-" + str(EncounterCount)
					CommonName = EncounterName
					WriteDir = "Encounter"
					WriteFile.write("{" + lineend)
					WriteFile.write(line + lineend)
					continue

				elif line.__contains__('"resourceType": "Observation",'):
					printeron=True
					BraceCount=1
					ObservationCount+=1
					ObservationName = "observation-" + str(BundleDirectory) + "-" +  str(ObservationCount) + ".json"
					WriteFile = open(ObservationName, "w")
					IDName =  "observation-" + str(BundleDirectory) + "-" +  str(ObservationCount)
					CommonName = ObservationName
					WriteDir = "Observation"
					WriteFile.write("{" + lineend)
					WriteFile.write(line + lineend)
					continue
				
				#File does not need "patient" in the filename, but will overwrite directories otherwise
				#Need the file to be named without "patient" in it.  Look at PatientName2
				elif line.__contains__('"resourceType": "Patient",'):
					printeron=True
					BraceCount=1
					PatientCount+=1
					PatientName = "patient-" + str(BundleDirectory) + ".json"
					PatientName2 = str(BundleDirectory) + ".json"
					WriteFile = open(PatientName, "w")
					IDName = BundleDirectory
					CommonName = PatientName
					WriteDir = "Patient"
					WriteFile.write("{" + lineend)
					WriteFile.write(line + lineend)
					continue

				elif(printeron==True):
					#Count braces, { and }, to find end of the resource block 
					if line.__contains__('}'): 
						BraceCount = BraceCount - 1

					if line.__contains__('{'): 
						BraceCount = BraceCount + 1

					#Quit at the end of the resource type
					#Move files to their proper directory
					if BraceCount == 0: 
						lineclean=line.rstrip(",")
						WriteFile.write(lineclean + lineend)
						WriteFile.close()
						if CommonName.startswith("patient-"):
							TargetLoc=os.path.join(BundleDirectory,WriteDir,PatientName2)
						else:
							TargetLoc=os.path.join(BundleDirectory,WriteDir,CommonName)
						shutil.move(CommonName,TargetLoc)
						printeron=False
						continue
					
					#The bulk of lines are processed here.  Only a few special cases
					else:
						if line.__contains__('"id": "'):
							WriteFile.write('        "id": "' + IDName + '",' + lineend)
						# encounter, observation, and condition files need to be labeled as such
						# The patient file just gets the name, no "patient" in front.
						elif line.__contains__('"reference":') and lineN2.__contains__('"subject":'):
							if WriteDir == "Encounter":
								WriteFile.write('          "reference": "Patient/' + BundleDirectory + '",' + lineend)
							else:
								WriteFile.write('          "reference": "Patient/' + BundleDirectory + '"' + lineend)
						elif line.__contains__('"reference":') and lineN2.__contains__('"encounter":'):
							WriteFile.write('          "reference": "Encounter/' + "encounter-" + str(BundleDirectory) + "-" + str(EncounterCount) + '"' + lineend)
						
						#Alphora request for removing absolute urn:uuid:123456-abc and replacing them with relative references, 
						#for example "Provider/123456-abc" for participant and "Organization/123456-abc" for serviceProvider
						elif line.__contains__('"reference":') and lineN4.__contains__('"participant":'):
							relative_ref = re.search(r'("reference": "urn:uuid:)(.*)(",)', line).group(2)
							WriteFile.write('          "reference": "Provider/' + str(relative_ref) + '",' + lineend)
						elif line.__contains__('"reference":') and lineN2.__contains__('"serviceProvider":'):
							relative_ref = re.search(r'("reference": "urn:uuid:)(.*)(",)', line).group(2)
							WriteFile.write('          "reference": "Organization/' + str(relative_ref) + '",' + lineend)



						# "issued": lines throws errors for observation files.  
						# less than a second off the "effectivedate", so redundant	
						elif line.__contains__('"issued":'):
							continue 
						else:	
							WriteFile.write(lineN1 + lineend)
						continue

		print(ConditionCount, "Condition file(s) from bundle", bundlejsonfiles)
		print(EncounterCount, "Encounter file(s) from bundle", bundlejsonfiles)
		print(ObservationCount, "Observation file(s) from bundle", bundlejsonfiles)
		print(PatientCount, "Patient file(s) from bundle", bundlejsonfiles)


#Other "resourceTypes" can be added easily from the bundle.json file
str_num_json_files = str(num_json_files)

print("\nFinished.  A total of " + str_num_json_files +  " bundled .json file(s) processed\n")
