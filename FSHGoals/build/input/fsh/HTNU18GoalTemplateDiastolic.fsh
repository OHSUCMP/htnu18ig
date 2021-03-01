Alias: LNC = http://loinc.org
Instance: HTNU18GoalTemplateDiastolic
InstanceOf: Goal
Title: "Goal Example for HTNU18"
Description: "test patient goal template for HTNU18"
Usage: #example
* lifecycleStatus = #planned
* achievementStatus = #in-progress
* startDate = "2012-02-12"
* description.text = "goals for HTNU18"
* subject = Reference(test)
//check codes in CQL match here to diastolic
* target.measure = LNC#8462-4 "Diastolic Blood Pressure"
* target[1].detailQuantity.value = 80
* target[1].detailQuantity.unit = "mm[Hg]"
* target[1].detailQuantity.system = "http://unitsofmeasure.org"