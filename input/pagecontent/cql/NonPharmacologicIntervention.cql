library NonPharmacologicIntervention version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "v3 Code System ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "LOINC": 'http://loinc.org'
codesystem "Goal achievement status": 'http://terminology.hl7.org/CodeSystem/goal-achievement'

/* Inclusion */
// HYPERTENSION DIAGNOSIS
valueset "Hypertension": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.3157.4012'
valueset "Non essential Hypertension SNOMEDCT": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'
// BLOOD PRESSURE
valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'
valueset "Systolic blood pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'
// COUNSELING
valueset "Tobacco Use Cessation Counseling": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.509'
valueset "Weight Reduction Recommendations": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.420'
valueset "BMI Follow Up Plan SNOMEDCT": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1195.111'
valueset "Alcohol Brief Intervention and Counseling": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.124'
valueset "Counseling for Nutrition": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.195.12.1003'
valueset "Physical Activity Recommendations": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.418'
// SMOKING
valueset "Tobacco Smoking Status [Current] (Social History) (LOINC)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1146.1330'
valueset "Tobacco User": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.422'
// BMI
valueset "BMI Ratio": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.1.1490'
// ALCOHOL
valueset "Average Number of Drinks per Drinking Day": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.106.11.1030'

/* Exclusion */
valueset "Pregnancy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.378'
valueset "End Stage Renal Disease": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.590'


code "PACKS A DAY": '8663-7' from "LOINC" display 'Cigarettes smoked current (pack per day) - Reported'
code "in-progress": 'in-progress' from "Goal achievement status" display 'In Progress'
code "improving": 'improving' from "Goal achievement status" display 'Improving'
code "achieved": 'achieved' from "Goal achievement status" display 'Achieved'
code "sustaining": 'sustaining' from "Goal achievement status" display 'sustaining'


context Patient

/* Return the number of packs/day indicated in the Observation */
define function "Packs Per Day"(O FHIR.Observation):
  FHIRHelpers.ToQuantity(singleton from (O.component C where C.code = "PACKS A DAY").value)

/* Return a reference to the most recent observation related to the list of counseling procedures given */
define function "Last Relevant Counseling"(procedures List<FHIR.Procedure>):
  (Last(procedures P sort by start of Common."Normalize Interval"(performed))).reasonReference

define "Info":
  'info'

define "Warning":
  'warning'

define "Critical":
  'critical'

define "Errors":
  null

define "Patient Name":
  First(Patient.name.given)
   + ' ' +
  First(Patient.name.family)

/* Recommendation Criteria - Non-Pharmacologic Interventions  */
define "Meets Inclusion Criteria":
  exists "Condition Indicating Preexisting Hypertension"

define "Meets Exclusion Criteria":
  "Patient Under Age 18"
    or "Patient Over Age 80"
    or exists "Condition Indicating End Stage Renal Disease"
    or exists "Condition Indicating Pregnancy"

define "In Population":
  "Meets Inclusion Criteria"
  and not "Meets Exclusion Criteria"

// Separate Actions for each Decision Point Output. Separate Definitions for Action Conditions.
define "BP Goal Recommendation":
  'Discuss target blood pressure and set a blood pressure goal'

define "BP Goal Rationale":
  '{{#patient}}You have a hypertension (high blood pressure) diagnosis and do not currently have blood pressure goal yet.  Setting goals to achieve better health has been proven to help.  Please set up an appointment with your care team to identify an initial blood pressure goal.  Lowering your blood pressure will reduce your risk of stroke and other conditions.<br><br>Stroke, MI, "Reduce risk of stroke, heart disease, or kidney disease"{{/patient}}{{#careTeam}}No BP Goal set: Setting a blood pressure goal can help engage patients and improve outcomes. For most patients, choosing a target between <120-140/80-90 is recommended; lower targets may be for ASCVD, ASCVD risk >10%, multimorbidity (CKD and diabetes), or preference; higher targets may be for age, adverse events, or frailty.{{/careTeam}}|https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065|[    {      "label": "BPGoal",      "actions": [       "{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'BPGoalhigh\'>BP target < 140/90</input>{{/patient}}","{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'BPGoalmedium\'>BP target < 130/80</input>{{/patient}}","{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'BPGoallow\'>BP target < 120/80</input>{{/patient}}"      ]    }  ]|at-most-one|'

define "Smoking Recommendation":
  if "Patient is Currently a Smoker" then
    if ("Counseling Smoking Observation" is null or "Patient Smoking Increased Since Last Visit") then
      'Discuss smoking cessation'
    else
      'Smoking Reminder Recommendation Placeholder'
  else
    'None'

define "Smoking Rationale":
  if "Patient is Currently a Smoker" then
    if ("Counseling Smoking Observation" is null or "Patient Smoking Increased Since Last Visit") then
      '{{#patient}}You have a hypertension (high blood pressure) diagnosis and reported smoking.  Reducing smoking will help lower blood pressure, the risk of stroke, and other harmful events; talk to your care team about quitting smoking.{{/patient}}{{#careTeam}}Patient reports they smoke. Counsel about quitting according to your local protocol.{{/careTeam}}|https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065#page=59|[ { "label": "Request Smoking Cessation Assistance", "actions": [ "ServiceRequest for Smoking Cessation Counseling", "{{#patient}}<a href=\'/SmokingCessation\'>Click here to request Smoking Cessation Assistance</a>{{/patient}}" ] } ]|at-most-one|'
    else
      'Smoking Reminder Rationale Placeholder'
  else
    'None'

define "BMI Recommendation":
  if "Patient BMI is Greater than 25 kg/m2" then
    if ("Counseling BMI Observation" is null or "Patient BMI Increased Since Last Visit") then
      'Consider weight loss strategies'
    else
      'Provide reminder of BMI recommendations placeholder.'
  else
    'None'

define "BMI Rationale":
  if "Patient BMI is Greater than 25 kg/m2" then
    if ("Counseling BMI Observation" is null or "Patient BMI Increased Since Last Visit") then
      '{{#patient}}Your weight suggests that weight reduction will help lower your blood pressure, and with it the risk of stroke and other harmful events. Selecting a weight loss goal can help reduce weight.{{/patient}}{{#careTeam}}Patient has a BMI of 25 or greater. Guidelines recommend weight loss to aid in lowering blood pressure.{{/careTeam}}|https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065#page=59|[ { "label": "Request Weight Loss Counseling", "actions": [ "ServiceRequest for Weight Loss Counseling", "{{#patient}}<a href=\'/weightLoss\'>Click here to request Weight Loss Counseling</a>{{/patient}}" ] } ]|at-most-one|[{"label":"University of Michigan: Hypertension", "url":"https://uhs.umich.edu/hypertension"}, {"label":"AHA: Changes You Can Make to Manage High Blood Pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure"}]'
    else
      '{{#patient}}Your weight is not yet decreasing. When it\'s time, consider readdressing your weight loss goal.{{/patient}}{{#careTeam}}Patient has a BMI of 25 or greater; they have been counseling, but may need a reminder.{{/careTeam}}|https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065#page=59|[ { "label": "Request Weight Loss Counseling", "actions": [ "ServiceRequest for Weight Loss Counseling", "{{#patient}}<a href=\'/weightLoss\'>Click here to request Weight Loss Counseling</a>{{/patient}}" ] } ]|at-most-one|[{"label":"University of Michigan: Hypertension", "url":"https://uhs.umich.edu/hypertension"}, {"label":"AHA: Changes You Can Make to Manage High Blood Pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure"}]'
  else
    'None'

define "Alcohol Recommendation":
  if "Patient is a Heavy Alcoholic Drinker" then
    if ("Counseling Drinking Observation" is null or "Patient Drinking Increased Since Last Visit") then
      'Discuss alcohol moderation'
    else
      'Provide reminder of alcohol recommendations placeholder'
  else
    'None'

define "Alcohol Rationale":
  if "Patient is a Heavy Alcoholic Drinker" then
    if ("Counseling Drinking Observation" is null or "Patient Drinking Increased Since Last Visit") then
      '{{#patient}}You have a hypertension (high blood pressure) diagnosis.  Lowering your blood pressure will help improve your overall health.  Reducing alcohol use will help lower blood pressure, the risk of stroke, and other harmful events.{{/patient}}{{#careTeam}}Patient reports heavy alcohol use. Counsel them to cut down or quit according to your local protocol.{{/careTeam}}|https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065#page=59|[ { "label": "Request Alcohol Moderation Assistance", "actions": [ "ServiceRequest for Alcohol Moderation Counseling", "{{#patient}}<a href=\'/alcoholModeration\'>Click here to request Alcohol Moderation Counseling</a>{{/patient}}" ] } ]|at-most-one|'
    else
      'Alcohol reminder rationale placeholder.'
  else
    'None'

define "Dietary Counseling Recommendation":
  if "Last Nutrition Counseling" is null then
    'Discuss dietary changes (with salt/sodium reduction)'
  else
    'Dietary reminder recommendation placeholder'

define "Dietary Counseling Rationale":
  if "Last Nutrition Counseling" is null then
    '{{#patient}}Choosing the DASH diet, a low sodium diet, or another heart healthy diet may lower your elevated blood pressure and reduce your risk of heart attack and stroke.{{/patient}}{{#careTeam}}Patient needs counseling about reducing sodium or choosing a heart healthy diet.{{/careTeam}}|https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065#page=59|[ { "label": "Diet", "actions": [  "{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'lowNADiet\'>Goal: Low sodium diet</input>{{/patient}}" , "{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'dashDiet\'>Goal: DASH Diet</input>{{/patient}}","{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'otherDiet\'>Goal: Other Heart Healthy Diet</input>{{/patient}}" ] } ]|at-most-one|'
  else
    'Dietary reminder rationale placeholder.'

define "Physical Activity Counseling Recommendation":
  if "Last Physical Activity Counseling" is null then
    'Discuss physical activity'
  else
    'Provide physical activity reminder placeholder'

define "Physical Activity Counseling Rationale":
  if "Last Physical Activity Counseling" is null then
    '{{#patient}}Physical activity can help reduce your blood pressure and risk of stroke and other harmful events. {{/patient}}{{#careTeam}}Patient needs counseling about increasing physical activity.{{/careTeam}}|https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065#page=59|[ { "label": "Physical Activity", "actions": [  "{{#patient}}<input type=\'text\' class=\'goal\' data-id=\'physical activity\'>Physical Activity Goal</input>{{/patient}}" ] } ]|at-most-one|'
  else
    'Provide physical activity reminder rationale placeholder.'

define "Patient on Track of Goal Recommendation":
  if "Patient at BP Goal" then
    'Patient on track of goal: End of non-pharmacologic interventions.'
  else
    'Patient not on track of goal: Discuss pharmacological interventions.'

define "Patient on Track of Goal Rationale":
  if "Patient at BP Goal" then
    'Patient on track of goal: No Further Action Required.'
  else
    'Patient not on track of goal: Discuss pharmacological treatment options with Patient.'

define "Indicator Status":
  "Info"

define "Exclusion Reason":
  if "Meets Exclusion Criteria" then
    (
      'Patient was excluded from non-pharmacologic interventions for hypertension due to '
      + (
          if "Patient Under Age 18" then 'being under the age of 18.'
          else if "Patient Over Age 80" then 'being over the age of 80.'
          else if exists "Condition Indicating End Stage Renal Disease" then 'having end stage renal disease.'
          else if exists "Condition Indicating Pregnancy" then 'being pregnant.'
          else ''
        )
    )
  else ''


/* Non-Pharmacologic Interventions Workflow */
// Diagnosis of HTN in Problem List.
define "Condition Indicating Preexisting Hypertension":
  (
    (Common.QualifiedCondition(["Condition": "Hypertension"]))
    union (Common.QualifiedCondition(["Condition": "Non essential Hypertension SNOMEDCT"]))
  ) PreexistingCondition


// Does Patient have a BP Goal?
define "Qualifying Blood Pressure Goals":
  (Common.QualifiedGoal(["Goal"])) BPGoal
    where (
      singleton from (BPGoal.target Systolic
        where Systolic.measure in "Systolic blood pressure"
          and Systolic.detail is Quantity
          and Common.WithUnit(Systolic.detail, 'mm[Hg]'))
    ) SystolicTarget is not null
      and (
        singleton from (BPGoal.target Diastolic
          where Diastolic.measure in "Diastolic Blood Pressure"
            and Diastolic.detail is Quantity
            and Common.WithUnit(Diastolic.detail, 'mm[Hg]'))
      ) DiastolicTarget is not null

define "Most Recently Established Blood Pressure Goal":
  Last (
    "Qualifying Blood Pressure Goals" BPGoal
      sort by (start as date)
  )

define "Patient does not have a BP Goal":
  if "In Population" is not true then
    false
  else
    not exists "Qualifying Blood Pressure Goals"

// All observations pertaining to smoking
define "Smoking Status Observations":
  (Common.QualifiedObservation(["Observation": "Tobacco Smoking Status [Current] (Social History) (LOINC)"]))

// All observations indicating patient is a smoker
define "Observations Indicating Patient is a Smoker":
  "Smoking Status Observations" SmokingStatus
    where SmokingStatus.value as CodeableConcept in "Tobacco User"
      and singleton from (
        SmokingStatus.component C
          where FHIRHelpers.ToConcept(C.code) ~ "PACKS A DAY"
            and C.value is Quantity and Common.WithUnit(C.value, 'Packs/Day')
      ) is not null

define "Most Recent Observation of Patient Smoking Status":
  Last(
    "Smoking Status Observations" SmokingObserved
    sort by Coalesce(end of Common."Normalize Interval"(effective), issued)
  )

define "Patient is Currently a Smoker":
  if "In Population" is not true then
    false
  else
    "Observations Indicating Patient is a Smoker" contains "Most Recent Observation of Patient Smoking Status"

// Is patient's BMI > 25?
define "Observations Specifying Patient BMI":
  (Common.QualifiedObservation(["Observation": "BMI Ratio"])) BMIObserved
    where BMIObserved.value is Quantity
      and Common.WithUnit(BMIObserved.value, 'kg/m2')

define "Most Recent Patient BMI":
  Last(
    "Observations Specifying Patient BMI" BMIObserved
    sort by Coalesce(end of Common."Normalize Interval"(effective), issued)
  )

define "Patient BMI is Greater than 25 kg/m2":
  if "In Population" is not true then
    false
  else
    "Most Recent Patient BMI".value >= 25.0 'kg/m2'


// Does patient drink heavily?
define "Observations Measuring Amount of Alcoholic Drinks Patient has per Drinking Day":
  (Common.QualifiedObservation(["Observation": "Average Number of Drinks per Drinking Day"])) DrinksPerDay
    where DrinksPerDay.value is Quantity
      and Common.WithUnit(DrinksPerDay.value, 'Drinks/Day')

define "Most Recent Patient Drinking Observation":
  Last(
    "Observations Measuring Amount of Alcoholic Drinks Patient has per Drinking Day" DrinksPerDay
    sort by Coalesce(end of Common."Normalize Interval"(effective), issued)
  )

define "Heavy Daily Drinker":
  if Patient.gender = 'male' then 5.0
  else 4.0

define "Patient is a Heavy Alcoholic Drinker":
  if "In Population" is not true then
    false
  else
    "Most Recent Patient Drinking Observation".value.value >= "Heavy Daily Drinker"

define "Last Smoking Counseling":
  "Last Relevant Counseling"(Common.QualifiedProcedure(["Procedure": "Tobacco Use Cessation Counseling"]))

define "Last Drinking Counseling":
  "Last Relevant Counseling"(Common.QualifiedProcedure(["Procedure": "Alcohol Brief Intervention and Counseling"]))

define "Last BMI Counseling":
  "Last Relevant Counseling"(Common.QualifiedProcedure(["Procedure": "Weight Reduction Recommendations"])
  union Common.QualifiedProcedure(["Procedure": "BMI Follow Up Plan SNOMEDCT"]))

define "Last Nutrition Counseling":
  "Last Relevant Counseling"(Common.QualifiedProcedure(["Procedure": "Counseling for Nutrition"]))

define "Last Physical Activity Counseling":
  "Last Relevant Counseling"(Common.QualifiedProcedure(["Procedure": "Physical Activity Recommendations"]))

define "Counseling Smoking Observation":
  Last("Observations Indicating Patient is a Smoker" SmokingObserved
    with "Last Smoking Counseling" Counseling
      such that SmokingObserved.id = Common.GetId(Counseling.reference))

define "Counseling Drinking Observation":
  Last("Observations Measuring Amount of Alcoholic Drinks Patient has per Drinking Day" DrinksPerDay
    with "Last Drinking Counseling" Counseling
      such that DrinksPerDay.id = Common.GetId(Counseling.reference))

define "Counseling BMI Observation":
  Last("Observations Specifying Patient BMI" BMIObserved
    with "Last BMI Counseling" Counseling
      such that BMIObserved.id = Common.GetId(Counseling.reference))

define "Patient Smoking Increased Since Last Visit":
  "Patient is Currently a Smoker" and "Packs Per Day"("Most Recent Observation of Patient Smoking Status") > "Packs Per Day"("Counseling Smoking Observation")

define "Patient Drinking Increased Since Last Visit":
  from
    "Most Recent Patient Drinking Observation" DrinkingThisVisit,
    "Counseling Drinking Observation" DrinkingLastVisit
      return (FHIRHelpers.ToQuantity(DrinkingThisVisit.value) > FHIRHelpers.ToQuantity(DrinkingLastVisit.value)) is true

define "Patient BMI Increased Since Last Visit":
  from
    "Most Recent Patient BMI" BMIThisVisit,
    "Counseling BMI Observation" BMILastVisit
      return (FHIRHelpers.ToQuantity(BMIThisVisit.value) > FHIRHelpers.ToQuantity(BMILastVisit.value)) is true

// Is Patient on Track to reach BP Goal?
define "BP Goal Demonstrating Patient Improvement":
  "Most Recently Established Blood Pressure Goal" BPGoal
    where FHIRHelpers.ToConcept(BPGoal.achievementStatus) ~ "in-progress"
      or FHIRHelpers.ToConcept(BPGoal.achievementStatus) ~ "improving"
      or FHIRHelpers.ToConcept(BPGoal.achievementStatus) ~ "achieved"
      or FHIRHelpers.ToConcept(BPGoal.achievementStatus) ~ "sustaining"

define "Patient at BP Goal":
  if "In Population" is not true then
    false
  else
    "BP Goal Demonstrating Patient Improvement" is not null

/* Action Conditionals */
define "Patient is Currently a Smoker Action Path":
  if not "In Population" then
    false
  else "Patient is Currently a Smoker"

define "Patient BMI is Greater than 25 kg/m2 Action Path":
  if not "In Population" then
    false
  else "Patient BMI is Greater than 25 kg/m2"

define "Patient is a Heavy Alcoholic Drinker Action Path":
  if not "In Population" then
    false
  else "Patient is a Heavy Alcoholic Drinker"

define "Patient is in Need of Dietary Counseling Action Path":
  if not "In Population" then
    false
  else "Last Nutrition Counseling" is null

define "Patient is in Need of Physical Activity Counseling Action Path":
  if not "In Population" then
    false
  else "Last Physical Activity Counseling" is null

/* Exclusion Criteria */
define "Patient Under Age 18":
  AgeInYearsAt(Today()) < 18

define "Patient Over Age 80":
  AgeInYearsAt(Today()) > 80

define "Condition Indicating End Stage Renal Disease":
  (Common.QualifiedCondition(["Condition": "End Stage Renal Disease"])) ESRD

define "Condition Indicating Pregnancy":
  (Common.QualifiedCondition(["Condition": "Pregnancy"])) Pregnancy
    where end of Common."Prevalence Period"(Pregnancy) > Today()

/* TEST */
define "TEST Patient Age":
  AgeInYears()

define "TEST Patient BMI Resources":
  "Observations Specifying Patient BMI".id

define "TEST Most Recent Patient BMI":
  "Most Recent Patient BMI" BMI
    return Tuple {
      "ID": BMI.id,
      "Date": BMI.effective.end,
      "Value": BMI.value.value,
      "Unit": BMI.value.unit
    }

define "TEST Patient Packs Per Day Most Recent":
  "Packs Per Day"("Most Recent Observation of Patient Smoking Status")

define "TEST Patient Packs Per Day At Counseling":
  "Packs Per Day"("Counseling Smoking Observation")
