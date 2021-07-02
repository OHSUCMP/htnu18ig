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

/* Return a reference to the most recent observation related to the list of counseling procedures given */
define function "Last Relevant Counseling"(procedures List<FHIR.Procedure>):
  (Last(procedures P sort by start of Common."Normalize Interval"(performed))).reasonReference

define function "Last Counseling Procedure"(procedures List<FHIR.Procedure>):
    (Last(procedures P sort by start of Common."Normalize Interval"(performed)))

/* Return a list containing the json string needed to update each given Goal */
define function "Update Goals String"(goals List<FHIR.Goal>, code String):
  goals Goal return '{"id": "' + Goal.id + '", "type": "update-goal", "references": {"system":"https//coach-dev.ohsu.edu", "code":"' + code + '"}, "label": "Update your goal."}'

define function "Goal Summary"(goals List<FHIR.Goal>):
  goals Goal return 'Goal: ' + Goal.description.text + ' Status: ' + (singleton from Goal.achievementStatus.coding).display

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
  '{{#patient}}You have a hypertension (high blood pressure) diagnosis and do not currently have a blood pressure goal.  Setting goals to achieve better health has been proven to help.  Please set up an appointment with your care team to identify an initial blood pressure goal.  Lowering your blood pressure will reduce your risk of stroke and other conditions.<br><br>Stroke, MI, "Reduce risk of stroke, heart disease, or kidney disease"{{/patient}}{{#careTeam}}No BP Goal set: Setting a blood pressure goal can help engage patients and improve outcomes. For most patients, choosing a target between <120-140/80-90 is recommended; lower targets may be for ASCVD, ASCVD risk >10%, multimorbidity (CKD and diabetes), or preference; higher targets may be for age, adverse events, or frailty.{{/careTeam}}|https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065||at-most-one|'

define "Smoking Recommendation":
  if exists "Tobacco Cessation Goals" then
    if exists "Tobacco Cessation Goals Needing Update" then
      'Update your Smoking Cessation Goals'
      else
      'Smoking Cessation'
  else
    if "Patient is Currently a Smoker" then
      if ("Last Smoking Counseling Procedure" is null) then
          'Discuss Smoking Cessation'
      else
        'Reminder about Smoking Cessation'
  else
    'None'

define "Smoking Rationale":
  if exists "Tobacco Cessation Goals" then
    if exists "Tobacco Cessation Goals Needing Update" then
      '{{#patient}}You have set some tobacco cessation goals. Tell us how you\'re doing.{{/patient}}|' + "Suggestions for Updating Tobacco Cessation Goals" + '|at-most-one|'
    else
      '{{#patient}}This might be some tailored output based on the achievementStatus of your goals or we could list goals here or on the right.<br>' + "Tobacco Goal Summary" + '{{/patient}}||at-most-one|'
  else
    if "Patient is Currently a Smoker" then
      if ("Last Smoking Counseling Procedure" is null) then
        '{{#patient}}You have a hypertension (high blood pressure) diagnosis and reported smoking. Reducing smoking will help lower blood pressure, the risk of stroke, and other harmful events; talk to your care team about quitting smoking.{{/patient}}{{#careTeam}}Patient reports they smoke. Counsel about quitting according to your local protocol.{{/careTeam}}|[ {"id": "smoking-counseling", "type":"counseling", "references": {"system":"http://snomed.info/sct", "code":"225323000"},"label": "Suggested Reading","actions": [{"url":"/SmokingCessation", "label":"Click here to learn more about tobacco cessation."}]},{ "id": "smoking-freetext-goal", "type":"goal", "references":{"system":"https//coach-dev.ohsu.edu", "code":"smoking-cessation"}, "label": "Set a Tobacco Cessation Goal", "actions": [] } ]|at-most-one|[{"label":"Additional Link 1", "url":"https://www.google.com"}, {"label":"Additional Link 2", "url":"https://www.google.com"}]'
      else
        '{{#patient}}You received counseling about stopping smoking, which would lower your blood pressure and reduce stroke and heart attack risk.{{/patient}}{{#careTeam}}Patient still smokes, but has been counseled. Consider reminding about quitting according to your local protocol.{{/careTeam}}|[ { "id": "smoking-freetext-goal", "type":"goal", "references":{"system":"https//coach-dev.ohsu.edu", "code":"smoking-cessation"}, "label": "Set a Tobacco Cessation Goal", "actions": [] } ]|at-most-one|'
    else
      'None'

// Convert the list to a string for use in suggestions
define "Suggestions for Updating Tobacco Cessation Goals":
  '[' + Combine("Update Goals String"("Tobacco Cessation Goals Needing Update", 'smoking-cessation'), ',') + ']'

define "Tobacco Goal Summary":
  Combine("Goal Summary"("Tobacco Cessation Goals"), '<br>')

define "BMI Recommendation":
  if exists "Weight Loss Goals" then
    if exists "Weight Loss Goals Needing Update" then
      'Goals need updating'
    else
      'Tailored recommendation'
  else
    if "Patient BMI is Greater than 25 kg/m2" then
      if ("Last BMI Counseling Procedure" is null) then
        'Consider weight loss strategies.'
      else
        'Remind about weight loss.'
  else
    'None'

define "BMI Rationale":
  if exists "Weight Loss Goals" then
    if exists "Weight Loss Goals Needing Update" then
      '{{#patient}}You have set some weight loss goals. Tell us how you\'re doing.{{/patient}}|' + "Suggestions for Updating Weight Loss Goals" + '|at-most-one|'
    else
      '{{#patient}}This might be some tailored output based on the achievementStatus of your goals or we could list goals here or on the right.<br>' + "Weight Loss Goal Summary" + '{{/patient}}||at-most-one|'
  else
    if "Patient BMI is Greater than 25 kg/m2" then
      if ("Last BMI Counseling Procedure" is null) then
        '{{#patient}}Your weight suggests that weight reduction will help lower your blood pressure, and with it the risk of stroke and other harmful events. Selecting a weight loss goal can help reduce weight.{{/patient}}{{#careTeam}}Patient has a BMI of 25 or greater. Guidelines recommend weight loss to aid in lowering blood pressure.{{/careTeam}}|[ { "id": "weight-loss-counseling", "label": "Weight Loss Counseling", "type": "counseling", "references": {"system":"http://snomed.info/sct", "code":"266724001"}, "actions": [ {"label":"Learn more about weight loss.", "url":"/weightLoss"}]}, { "id": "weight-loss-freetext-goal", "type":"goal", "references":{"system":"https//coach-dev.ohsu.edu", "code":"weight-loss"}, "label": "Set a Weight Loss Goal", "actions": [] } ]|at-most-one|[{"label":"University of Michigan: Hypertension", "url":"https://uhs.umich.edu/hypertension"}, {"label":"AHA: Changes You Can Make to Manage High Blood Pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure"}]'
      else
        '{{#patient}}Your weight is not yet decreasing. When it\'s time, consider readdressing your weight loss goal.{{/patient}}{{#careTeam}}Patient has a BMI of 25 or greater; they have been counseled, but may need a reminder.{{/careTeam}}|[ { "id": "weight-loss-freetext-goal", "type":"goal", "references":{"system":"https//coach-dev.ohsu.edu", "code":"weight-loss"}, "label": "Set a Weight Loss Goal", "actions": [] } ]|at-most-one|[{"label":"University of Michigan: Hypertension", "url":"https://uhs.umich.edu/hypertension"}, {"label":"AHA: Changes You Can Make to Manage High Blood Pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure"}]'
  else
    'None'

// Convert the list to a string for use in suggestions
define "Suggestions for Updating Weight Loss Goals":
  '[' + Combine("Update Goals String"("Weight Loss Goals Needing Update", 'weight-loss'), ',') + ']'

define "Weight Loss Goal Summary":
  Combine("Goal Summary"("Weight Loss Goals"), '<br>')

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
      '{{#patient}}You have a hypertension (high blood pressure) diagnosis.  Lowering your blood pressure will help improve your overall health.  Reducing alcohol use will help lower blood pressure, the risk of stroke, and other harmful events.{{/patient}}{{#careTeam}}Patient reports heavy alcohol use. Counsel them to cut down or quit according to your local protocol.{{/careTeam}}|[ { "label": "Request Alcohol Moderation Assistance", "type": "counseling", "references": {"system":"http://snomed.info/sct", "code":"24165007"}, "actions": [ {"label":"Click here to request Alcohol Moderation Counseling", "url":"/alcoholModeration"} ] } ]|at-most-one|'
    else
      'Alcohol reminder rationale placeholder.|||'
  else
    'None'

define "Dietary Counseling Recommendation":
  if "Last Nutrition Counseling" is null then
    'Discuss dietary changes (with salt/sodium reduction)'
  else
    'Dietary reminder recommendation placeholder'

define "Dietary Counseling Rationale":
  if "Last Nutrition Counseling" is null then
    '{{#patient}}Choosing the DASH diet, a low sodium diet, or another heart healthy diet may lower your elevated blood pressure and reduce your risk of heart attack and stroke.{{/patient}}{{#careTeam}}Patient needs counseling about reducing sodium or choosing a heart healthy diet.{{/careTeam}}||at-most-one|'
  else
    'Dietary reminder rationale placeholder.|||'

define "Physical Activity Counseling Recommendation":
  if "Last Physical Activity Counseling" is null then
    'Discuss physical activity'
  else
    'Provide physical activity reminder placeholder'

define "Physical Activity Counseling Rationale":
  if "Last Physical Activity Counseling" is null then
    '{{#patient}}Physical activity can help reduce your blood pressure and risk of stroke and other harmful events. {{/patient}}{{#careTeam}}Patient needs counseling about increasing physical activity.{{/careTeam}}||at-most-one|'
  else
    'Provide physical activity reminder rationale placeholder.|||'

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

// Look for custom tobacco goal coding
define "Tobacco Cessation Goals":
  (Common.QualifiedGoal(["Goal"])) Goal
    where Goal.lifecycleStatus = 'active' and singleton from (Goal.category.coding.code) = 'smoking-cessation'

// Return Goals that haven't been updated for at least 2 weeks
define "Tobacco Cessation Goals Needing Update":
  ("Tobacco Cessation Goals") Goal where Goal.statusDate < (Today() -  2 weeks)

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

// Look for custom weight loss goal coding
define "Weight Loss Goals":
  (Common.QualifiedGoal(["Goal"])) Goal
    where Goal.lifecycleStatus = 'active' and singleton from (Goal.category.coding.code) = 'weight-loss'

// Return Goals that haven't been updated for at least 2 weeks
define "Weight Loss Goals Needing Update":
  ("Weight Loss Goals") Goal where Goal.statusDate < (Today() -  2 weeks)

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

define "Last Drinking Counseling":
  "Last Relevant Counseling"(Common.QualifiedProcedure(["Procedure": "Alcohol Brief Intervention and Counseling"]))

define "Last BMI Counseling Procedure":
  "Last Counseling Procedure"((["Procedure": "Weight Reduction Recommendations"]) union (["Procedure": "BMI Follow Up Plan SNOMEDCT"]))

define "Last Nutrition Counseling":
  "Last Relevant Counseling"(Common.QualifiedProcedure(["Procedure": "Counseling for Nutrition"]))

define "Last Physical Activity Counseling":
  "Last Relevant Counseling"(Common.QualifiedProcedure(["Procedure": "Physical Activity Recommendations"]))

define "Last Smoking Counseling Procedure":
  "Last Counseling Procedure"(["Procedure": "Tobacco Use Cessation Counseling"])

define "Counseling Drinking Observation":
  Last("Observations Measuring Amount of Alcoholic Drinks Patient has per Drinking Day" DrinksPerDay
    with "Last Drinking Counseling" Counseling
      such that DrinksPerDay.id = Common.GetId(Counseling.reference))

define "Patient Drinking Increased Since Last Visit":
  from
    "Most Recent Patient Drinking Observation" DrinkingThisVisit,
    "Counseling Drinking Observation" DrinkingLastVisit
      return (FHIRHelpers.ToQuantity(DrinkingThisVisit.value) > FHIRHelpers.ToQuantity(DrinkingLastVisit.value)) is true

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
