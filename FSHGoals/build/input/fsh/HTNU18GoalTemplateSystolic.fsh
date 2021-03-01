Alias: LNC = http://loinc.org
Instance: HTNU18GoalTemplateSystolic
InstanceOf: Goal
Title: "Goal Example for HTNU18"
Description: "test patient goal template for HTNU18"
Usage: #example
* lifecycleStatus = #planned
* achievementStatus = #in-progress
* startDate = "2012-02-12"
* description.text = "goals for HTNU18"
* subject = Reference(test)
//check codes in CQL match here to systolic 
* target.measure = LNC#8480-6 "Systolic Blood Pressure"
* target[0].detailQuantity.value = 130
* target[0].detailQuantity.unit = "mm[Hg]"
* target[0].detailQuantity.system = "http://unitsofmeasure.org"
