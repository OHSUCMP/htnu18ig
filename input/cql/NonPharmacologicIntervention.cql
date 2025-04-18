library NonPharmacologicIntervention version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "LOINC": 'http://loinc.org'
codesystem "Goal achievement status": 'http://terminology.hl7.org/CodeSystem/goal-achievement'

valueset "Tobacco Use Cessation Counseling": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.509'
valueset "Weight Reduction Recommendations": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.420'
valueset "BMI Follow Up Plan SNOMEDCT": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1195.111'
valueset "Alcohol Brief Intervention and Counseling": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.124'
valueset "Counseling for Nutrition": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.195.12.1003'
valueset "Physical Activity Recommendations": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1116.418'
valueset "Tobacco Smoking Status [Current] (Social History) (LOINC)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1146.1330'
valueset "Tobacco User": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.422'
valueset "BMI Ratio": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.1.1490'
valueset "Average Number of Drinks per Drinking Day": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.106.11.1030'
valueset "Alcohol Abuse Disorder": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1222.24'

code "PACKS A DAY": '8663-7' from "LOINC" display 'Cigarettes smoked current (pack per day) - Reported'

context Patient

define "Info":
  'info'

define function "Last Counseling Procedure"(procedures List<FHIR.Procedure>):
    (Last(procedures P sort by start of Common."Normalize Interval"(performed)))

define function "Unique Goal Id"(goal String):
  goal + ToString(Now())

/* Extract the COACH Code from the Goal */
define function "Goal Category"(goal FHIR.Goal):
  singleton from (goal.category category
    let coding: singleton from (category.coding c where c.system.value = 'https://coach.ohsu.edu')
    return FHIRHelpers.ToCode(coding))

/* Return a list containing the json string needed to update each given Goal */
define function "Update Goals String"(goals List<FHIR.Goal>):
  goals Goal
    let coding: "Goal Category"(Goal)
    return '{"id": "' + Goal.id + '", "type": "update-goal", "references": {"system":"' + coding.system + '", "code":"' + coding.code + '"}, "label": "Goal: '+ Goal.description.text + '"}'

define function "Goal Summary"(goals List<FHIR.Goal>):
  goals Goal return '<strong>' + Goal.description.text + '</strong>'

define "Patient Name":
  First(Patient.name.given)
   + ' ' +
  First(Patient.name.family)

/* Recommendation Criteria - Non-Pharmacologic Interventions  */
define "Meets Inclusion Criteria":
  exists Common."Condition Indicating Preexisting Hypertension" and not Common."HTN Crisis"

define "Meets Exclusion Criteria":
  Common."Patient Under Age 18"
    or Common."Patient Over Age 100"
    or exists Common."Condition Indicating End Stage Renal Disease"
    or exists Common."Condition Indicating Pregnancy"

define "In Population":
  // Preserve this ordering so excluded patients fail fast
  not "Meets Exclusion Criteria" and "Meets Inclusion Criteria"

/***** Decision Diamonds *****/
define "Patient Has Behavioral Goals":
  exists "Tobacco Cessation Goals" or
  exists "Weight Loss Goals" or
  exists "Alcohol Goals" or
  exists "Physical Activity Goals" or
  exists "Nutrition Goals"

// Therapy should be received if we're still collecting BPs or if the patient hasn't achieved their goal yet
define "Receive Therapy":
  not Common."Has BP Set" or (Common."Patient has a BP Goal" and Common."Above Goal Average Most Recent")

define "Enter Workflow":
  "In Population" and ("Patient Has Behavioral Goals" or "Receive Therapy")

/***** SMOKING CARD OUTPUT *****/

define "Smoking Recommendation":
  if exists "Tobacco Cessation Goals Needing Update" then 'Smoking cessation goal check-in.'
  else if exists "Tobacco Cessation Goals" then 'Smoking cessation goal check-in.'
  else if "Needs Smoking Counseling" then 'Discuss smoking cessation.'
  else if "Patient is Currently a Smoker" then 'Reminder about smoking cessation.'
  else ''

define "Smoking Rationale Combined Data":
  "Smoking Rationale" + '|' + "Smoking Suggestions" + '|at-most-one|' + "Smoking Links"

define "Smoking Rationale":
  if exists "Tobacco Cessation Goals Needing Update" then '{{#patient}}You set a smoking cessation goal and it is time to update your progress.{{/patient}}'
  else if exists "Tobacco Cessation Goals" then '{{#patient}}You set a smoking cessation goal; it isn\'t quite the time you set to update, but you can update that goal at any time.<br>' + "Tobacco Goal Summary" + '{{/patient}}'
  else if "Needs Smoking Counseling" then '{{#patient}}Reducing your smoking will help lower blood pressure, the risk of stroke, and other harmful events. Please discuss methods to reduce smoking with your care team.{{/patient}}{{#careTeam}}Patient reports they smoke. Counsel about quitting according to your local protocol.{{/careTeam}}'
  else if "Patient is Currently a Smoker" then '{{#patient}}You previously received counseling about quitting smoking, which would lower your blood pressure and other health risks. Please consider readdressing this goal.{{/patient}}{{#careTeam}}Patient still smokes, but has been counseled. Consider reminding about quitting according to your local protocol.{{/careTeam}}'
  else ''

define "Smoking Suggestions":
  if exists "Tobacco Cessation Goals Needing Update" then '[' + Combine("Update Goals String"("Tobacco Cessation Goals Needing Update"), ',') + ']'
  else if exists "Tobacco Cessation Goals" then '[ { "id": "goal-suggestion", "label": "", "type": "suggestion-link", "actions": [{"label":"View/Edit Goals", "url":"/goals"}] } ]'
  else if "Needs Smoking Counseling" then '[
    {"id": "smoking-counseling", "type":"counseling-link", "references": {"system":"http://snomed.info/sct", "code":"225323000"},"label": "Smoking Cessation Counseling","actions": [{"url":"/counseling/smoking-cessation", "label":"Click here to learn more about tobacco cessation."}]},
    {"id": "' + "Unique Goal Id"('smoking-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"smoking-cessation", "display": "Smoking Cessation"}, "label": "Set a Tobacco Cessation Goal", "actions": [{"label":"Reduce my tobacco use to [quantity] [method:cigarettes] per [time period]."}] }]'
  else if "Patient is Currently a Smoker" then '[ { "id": "' + "Unique Goal Id"('smoking-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"smoking-cessation", "display": "Smoking Cessation"}, "label": "Set a Tobacco Cessation Goal", "actions": [{"label":"Reduce my tobacco use to [quantity] [method:cigarettes] per [time period]."}] } ]'
  else ''

define "Smoking Links":
  '[
    { "label": "AHA: Smoking and your Health", "url": "https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure/smoking-high-blood-pressure-and-your-health"}
  ]'

define "Tobacco Goal Summary":
  Combine("Goal Summary"("Tobacco Cessation Goals"), '<br>')

define "Smoking Indicator Status":
  if exists "Tobacco Cessation Goals Needing Update" then 'warning'
  else 'info'

/***** WEIGHT LOSS CARD OUTPUT *****/

define "BMI Recommendation":
  if exists "Weight Loss Goals Needing Update" then 'Weight loss goal check-in.'
  else if exists "Weight Loss Goals" then 'Weight loss goal check-in.'
  else if "Patient BMI is Greater than 25 kg/m2" and "Last BMI Counseling Procedure" is null then 'Consider weight loss strategies.'
  else if "Patient BMI is Greater than 25 kg/m2" then 'Reminder about weight loss.'
  else ''

define "BMI Rationale Combined Data":
  "BMI Rationale" + '|' + "BMI Suggestions" + '|at-most-one|' + "BMI Links"

define "BMI Rationale":
  if exists "Weight Loss Goals Needing Update" then '{{#patient}}You set a goal for weight loss and it is time to update your progress.{{/patient}}'
  else if exists "Weight Loss Goals" then '{{#patient}}You set a goal for weight loss; it isn\'t quite the time you set to update, but you can update at any time.<br>' + "Weight Loss Goal Summary" + '{{/patient}}'
  else if "Patient BMI is Greater than 25 kg/m2" and "Last BMI Counseling Procedure" is null then '{{#patient}}Your current weight suggests that weight reduction will help lower your blood pressure, the risk of stroke, and other harmful events. Please discuss stategies with your care team to lose weight.{{/patient}}{{#careTeam}}Patient has a BMI of 25 or greater. Guidelines recommend weight loss to aid in lowering blood pressure.{{/careTeam}}'
  else if "Patient BMI is Greater than 25 kg/m2" then '{{#patient}}You previously received counseling about weight loss. Weight reduction will help lower your blood pressure. Please consider readdressing this goal.{{/patient}}{{#careTeam}}Patient has a BMI of 25 or greater; they have been counseling, but may need a reminder.{{/careTeam}}'
  else ''

define "BMI Suggestions":
  if exists "Weight Loss Goals Needing Update" then '[' + Combine("Update Goals String"("Weight Loss Goals Needing Update"), ',') + ']'
  else if exists "Weight Loss Goals" then '[ { "id": "goal-suggestion", "label": "", "type": "suggestion-link", "actions": [{"label":"View/Edit Goals", "url":"/goals"}] } ]'
  else if "Patient BMI is Greater than 25 kg/m2" and "Last BMI Counseling Procedure" is null then '[
    {"id": "weight-loss-counseling", "label": "Weight Loss Counseling", "type": "counseling-link", "references": {"system":"http://snomed.info/sct", "code":"266724001"}, "actions": [ {"label":"Learn more about weight loss.", "url":"/counseling/weight-loss"}]},
    {"id": "' + "Unique Goal Id"('weight-loss-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"weight-loss", "display": "Weight Loss"}, "label": "Set a Weight Loss Goal", "actions": [{"label":"Reduce my weight by [quantity] pounds."}] }
  ]'
  else if "Patient BMI is Greater than 25 kg/m2" then '[ { "id": "' + "Unique Goal Id"('weight-loss-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"weight-loss", "display": "Weight Loss"}, "label": "Set a Weight Loss Goal", "actions": [{"label":"Reduce my weight by [quantity] pounds."}] } ]'
  else ''

define "BMI Links":
  '[
    {"label":"University of Michigan: Hypertension", "url":"https://uhs.umich.edu/hypertension"},
    {"label":"AHA: Changes You Can Make to Manage High Blood Pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure"}
  ]'

define "Weight Loss Goal Summary":
  Combine("Goal Summary"("Weight Loss Goals"), '<br>')

define "Weight Loss Indicator Status":
  if exists "Weight Loss Goals Needing Update" then 'warning'
  else 'info'

/***** ALCOHOL CARD OUTPUT *****/

define "Alcohol Recommendation":
  if exists "Alcohol Goals Needing Update" then 'Alcohol moderation goal due for update.'
  else if exists "Alcohol Goals" then 'Alcohol moderation check-in.'
  else if "Needs Alcohol Counseling" then 'Discuss alcohol moderation.'
  else if "Patient is a Heavy Alcoholic Drinker" then 'Reminder about strategies for alcohol moderation.'
  else ''

define "Alcohol Rationale Combined Data":
  "Alcohol Rationale" + '|' + "Alcohol Suggestions" + '|at-most-one|' + "Alcohol Links"

define "Alcohol Rationale":
  if exists "Alcohol Goals Needing Update" then '{{#patient}}You set a goal to reduce drinking alcohol and it is time to update your progress.{{/patient}}'
  else if exists "Alcohol Goals" then '{{#patient}}You set a goal to reduce alcohol; it isn\'t quite the time you set to update, but you can update at any time.<br>' + "Alcohol Moderation Goal Summary" + '{{/patient}}'
  else if "Needs Alcohol Counseling" then '{{#patient}}Reducing your alcohol consumption will help lower your blood pressure, along with other health risks. Please discuss methods to reduce your drinking with your care team.{{/patient}}{{#careTeam}}Patient reports heavy alcohol use. Counsel them to cut down or quit according to your local protocol.{{/careTeam}}'
  else if "Patient is a Heavy Alcoholic Drinker" then '{{#patient}}You previously received counseling about alcohol consumption. Moderating alcohol consumption has proven benefits to heart health and reducing blood pressure. Please consider readdressing this goal.{{/patient}}'
  else ''

define "Alcohol Suggestions":
  if exists "Alcohol Goals Needing Update" then '[' + Combine("Update Goals String"("Alcohol Goals Needing Update"), ',') + ']'
  else if exists "Alcohol Goals" then '[ { "id": "goal-suggestion", "label": "", "type": "suggestion-link", "actions": [{"label":"View/Edit Goals", "url":"/goals"}] } ]'
  else if "Needs Alcohol Counseling" then '[
    {"id": "alcohol-counseling", "label": "Alcohol Counseling", "type": "counseling-link", "references": {"system":"http://snomed.info/sct", "code":"24165007"}, "actions": [ {"label":"Learn more about alcohol moderation.", "url":"/counseling/alcohol-moderation"}]},
    {"id": "' + "Unique Goal Id"('alcohol-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"alcohol-moderation", "display": "Alcohol Moderation"}, "label": "Set an Alcohol Moderation Goal", "actions": [{"label":"Reduce my alcohol consumption to [quantity] drinks per [time period]."}] }
  ]'
  else if "Patient is a Heavy Alcoholic Drinker" then '[{ "id": "' + "Unique Goal Id"('alcohol-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"alcohol-moderation", "display": "Alcohol Moderation"}, "label": "Set an Alcohol Moderation Goal", "actions": [{"label":"Reduce my alcohol consumption to [quantity] drinks per [time period]."}] } ]'
  else ''

define "Alcohol Links":
  '[
    {"label":"AHA: Alcohol and High Blood Pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure/limiting-alcohol-to-manage-high-blood-pressure"}
  ]'

define "Alcohol Moderation Goal Summary":
  Combine("Goal Summary"("Alcohol Goals"), '<br>')

define "Alcohol Moderation Indicator Status":
  if exists "Alcohol Goals Needing Update" then 'warning'
  else 'info'

/***** NUTRITION CARD OUTPUT *****/

define "Nutrition Recommendation":
  if exists "Nutrition Goals Needing Update" then 'Nutrition goal update.'
  else if exists "Nutrition Goals" then 'Nutrition goal check-in.'
  else if "Last Nutrition Counseling Procedure" is null then 'Discuss dietary changes (with salt/sodium reduction).'
  else 'Reminder about nutrition.'

define "Nutrition Rationale Combined Data":
  "Nutrition Rationale" + '|' + "Nutrition Suggestions" + '|at-most-one|' + "Nutrition Links"

define "Nutrition Rationale":
  if exists "Nutrition Goals Needing Update" then '{{#patient}}You set a nutrition goal and it is time to update your progress.{{/patient}}'
  else if exists "Nutrition Goals" then '{{#patient}}You set a nutrition goal; it isn\'t quite the time you set to update it, but you may update that goal at any time.<br>' + "Nutrition Goal Summary" + '{{/patient}}'
  else if "Last Nutrition Counseling Procedure" is null then '{{#patient}}Choosing the DASH diet, a low-sodium diet or another heart-healthy diet, may lower your elevated blood pressure and reduce your risk of heart attack and stroke. Please discuss potential dietary changes with your care team.{{/patient}}{{#careTeam}}Patient needs counseling about reducing sodium or choosing a heart healthy diet.{{/careTeam}}'
  else '{{#patient}}You have previously received counseling about dietary change. Maintaining a healthy diet that avoids excess salt/sodium could help control blood pressure. Please consider readressing this goal.{{/patient}}'

define "Nutrition Suggestions":
  if exists "Nutrition Goals Needing Update" then '[' + Combine("Update Goals String"("Nutrition Goals Needing Update"), ',') + ']'
  else if exists "Nutrition Goals" then '[ { "id": "goal-suggestion", "label": "", "type": "suggestion-link", "actions": [{"label":"View/Edit Goals", "url":"/goals"}] } ]'
  else if "Last Nutrition Counseling Procedure" is null then '[
    {"id": "nutrition-counseling", "label": "Nutrition Counseling", "type": "counseling-link", "references": {"system":"http://snomed.info/sct", "code":"11816003"}, "actions": [ {"label":"Learn more about nutrition and diet changes.", "url":"/counseling/diet"}]},
    {"id": "' + "Unique Goal Id"('nutrition-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"nutrition", "display": "Nutrition"}, "label": "Set a Nutrition/Diet Change Goal", "actions": [{"label":"Avoid eating [food item] for the next [quantity] [time period:week(s)]."}]}
  ]'
  else '[{ "id": "' + "Unique Goal Id"('nutrition-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"nutrition", "display": "Nutrition"}, "label": "Set a Nutrition/Diet Change Goal", "actions": [{"label":"Avoid eating [food item] for the next [quantity] [time period:week(s)]."}] } ]'

define "Nutrition Links":
  '[
    {"label": "NIH: DASH Diet", "url": "https://www.nhlbi.nih.gov/health-topics/dash-eating-plan"},
    {"label": "CDC: Eating Healthy", "url": "https://www.cdc.gov/healthy-weight-growth/healthy-eating/"}
  ]'

define "Nutrition Goal Summary":
    Combine("Goal Summary"("Nutrition Goals"), '<br>')

define "Nutrition Indicator Status":
  if exists "Nutrition Goals Needing Update" then 'warning'
  else 'info'

/***** PHYSICAL ACTIVITY CARD OUTPUT *****/

define "Physical Activity Recommendation":
  if exists "Physical Activity Goals Needing Update" then 'Physical activity goal check-in.'
  else if exists "Physical Activity Goals" then 'Physical activity goal check-in.'
  else if "Last Physical Activity Counseling Procedure" is null then 'Discuss strategies for increasing physical activity.'
  else 'Reminder about physical activity.'

define "Physical Activity Rationale Combined Data":
  "Physical Activity Rationale" + '|' + "Physical Activity Suggestions" + '|at-most-one|' + "Physical Activity Links"

define "Physical Activity Rationale":
  if exists "Physical Activity Goals Needing Update" then '{{#patient}}You set a physical activity goal and it is time to update your progress.{{/patient}}'
  else if exists "Physical Activity Goals" then '{{#patient}}You set a physical activity goal; it isn\'t quite the time you set to update it, but you may update that goal at any time.<br>' + "Physical Activity Goal Summary" + '{{/patient}}'
  else if "Last Physical Activity Counseling Procedure" is null then '{{#patient}}Physical activity can help reduce your blood pressure, risk of stroke, and other harmful events. Please discuss strategies to increase your physical activity with your care team.{{/patient}}{{#careTeam}}Patient needs counseling about increasing physical activity.{{/careTeam}}'
  else '{{#patient}}You previously received counseling about physical activity. Maintaining at least a moderate amount of physical activity will help control blood pressure. Please consider readdressing this goal.{{/patient}}'

define "Physical Activity Suggestions":
  if exists "Physical Activity Goals Needing Update" then '[' + Combine("Update Goals String"("Physical Activity Goals Needing Update"), ',') + ']'
  else if exists "Physical Activity Goals" then '[ { "id": "goal-suggestion", "label": "", "type": "suggestion-link", "actions": [{"label":"View/Edit Goals", "url":"/goals"}] } ]'
  else if "Last Physical Activity Counseling Procedure" is null then '[
    {"id": "physical-activity-counseling", "label": "Physical Activity Counseling", "type": "counseling-link", "references": {"system":"http://snomed.info/sct", "code":"304507003"}, "actions": [ {"label":"Learn more about physical activity.", "url":"/counseling/physical-activity"}]},
    {"id": "' + "Unique Goal Id"('physical-activity-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"physical-activity", "display": "Physical Activity"}, "label": "Set a Physical Activity Goal", "actions": [{"label":"Exercise for [quantity] [time period:hours], [quantity] times per [time period]."}] }
  ]'
  else '[{ "id": "' + "Unique Goal Id"('physical-activity-goal-') + '", "type":"goal", "references":{"system":"https://coach.ohsu.edu", "code":"physical-activity", "display": "Physical Activity"}, "label": "Set a Physical Activity Goal", "actions": [{"label":"Exercise for [quantity] [time period:hours], [quantity] times per [time period]."}] } ]'

define "Physical Activity Links":
  '[
    {"label": "AHA: Getting Active to Control your High Blood Pressure", "url": "https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure/getting-active-to-control-high-blood-pressure"},
    {"label": "Health.gov: Current physical activity guidelines", "url": "https://health.gov/our-work/physical-activity/current-guidelines"},
    {"label": "CDC: Physical Activity Index", "url":"https://www.cdc.gov/physical-activity/php/about/"}
  ]'

define "Physical Activity Goal Summary":
    Combine("Goal Summary"("Physical Activity Goals"), '<br>')

define "Physical Activity Indicator Status":
  if exists "Physical Activity Goals Needing Update" then 'warning'
  else 'info'

/* Non-Pharmacologic Interventions Workflow */
define "Goals":
  (Common.QualifiedGoal(["Goal"])) Goal where Goal.lifecycleStatus = 'active'

// Look for custom tobacco goal coding
define "Tobacco Cessation Goals":
  "Goals" Goal
    where Goal.category.coding.code contains 'smoking-cessation'

// Return Goals past target date
define "Tobacco Cessation Goals Needing Update":
  ("Tobacco Cessation Goals") Goal
    where First(Goal.target).due.value same day or before Today()

// Smoking Observations less than 5 years old (Issue #113)
// For smoking, we check when the observation ends in case the practioner has documented the start date as when the patient started smoking
define "Smoking Status Observations":
  (Common.QualifiedObservation(Common."All Observations" A where Common.TransformCodeableConcept(A.code) in "Tobacco Smoking Status [Current] (Social History) (LOINC)")) SmokingObserved
  where Common."Normalize Interval"(SmokingObserved.effective) ends 60 months or less before Today()

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
  "In Population" and "Observations Indicating Patient is a Smoker" contains "Most Recent Observation of Patient Smoking Status"

// Look for custom weight loss goal coding
define "Weight Loss Goals":
  "Goals" Goal
    where Goal.category.coding.code contains 'weight-loss'

// Return Goals past target date
define "Weight Loss Goals Needing Update":
  ("Weight Loss Goals") Goal
    where First(Goal.target).due.value same day or before Today()

// All BMI observations for previous 2 years (Issue #113)
define "Observations Specifying Patient BMI":
  (Common.QualifiedObservation(Common."All Observations" A where Common.TransformCodeableConcept(A.code) in "BMI Ratio")) BMIObserved
    where BMIObserved.value is Quantity
      and Common.WithUnit(BMIObserved.value, 'kg/m2') and
      Common."Normalize Interval"(BMIObserved.effective) starts 24 months or less before Today()

define "Most Recent Patient BMI":
  Last(
    "Observations Specifying Patient BMI" BMIObserved
    sort by Coalesce(end of Common."Normalize Interval"(effective), issued)
  )

define "Patient BMI is Greater than 25 kg/m2":
  "In Population" and "Most Recent Patient BMI".value >= 25.0 'kg/m2'

// Look for custom alcohol goal coding
define "Alcohol Goals":
  "Goals" Goal
    where Goal.category.coding.code contains 'alcohol-moderation'

// Return Goals past target date
define "Alcohol Goals Needing Update":
  ("Alcohol Goals") Goal
    where First(Goal.target).due.value same day or before Today()

// Get observations from the last 5 years reporting number of drinks per day (Issue #113)
// We check when the observation ends in case the practioner has documented the start date as when the patient started drinking that amount
define "Observations Measuring Amount of Alcoholic Drinks Patient has per Drinking Day":
  (Common.QualifiedObservation(Common."All Observations" A where Common.TransformCodeableConcept(A.code) in "Average Number of Drinks per Drinking Day")) DrinksPerDay
    where Common."Normalize Interval"(DrinksPerDay.effective) ends 60 months or less before Today() and
      DrinksPerDay.value is Quantity
      and Common.WithUnit(DrinksPerDay.value, 'Drinks/Day')

define "Most Recent Patient Drinking Observation":
  Last(
    "Observations Measuring Amount of Alcoholic Drinks Patient has per Drinking Day" DrinksPerDay
    sort by Coalesce(end of Common."Normalize Interval"(effective), issued)
  )

define "Heavy Daily Drinker":
  if Patient.gender = 'male' then 3.0
  else 2.0

// Get Conditions for Alcohol Abuse Disorder
define "Condition Indicating Alcohol Abuse Disorder":
  Common."Conditions" Problem
    where Problem.code in "Alcohol Abuse Disorder" and
    Common."Is Valid Prevalence Period"(Problem)

define "Patient is a Heavy Alcoholic Drinker":
  if not "In Population" then
    false
  else
    "Most Recent Patient Drinking Observation".value.value >= "Heavy Daily Drinker" or
      exists "Condition Indicating Alcohol Abuse Disorder"

define "Nutrition Goals":
  "Goals" Goal
    where Goal.category.coding.code contains 'nutrition'

define "Nutrition Goals Needing Update":
  ("Nutrition Goals") Goal
    where First(Goal.target).due.value same day or before Today()

define "Physical Activity Goals":
  "Goals" Goal
    where Goal.category.coding.code contains 'physical-activity'

define "Physical Activity Goals Needing Update":
  ("Physical Activity Goals") Goal
    where First(Goal.target).due.value same day or before Today()

/***** COUNSELING PROCEDURES *****/
// Get all procedures for subject since Epic does not support getting by code
define "Procedures":
  Common.QualifiedProcedure(["Procedure"])

define "Last Alcohol Counseling Procedure":
  "Last Counseling Procedure"("Procedures" Procedure
    where Procedure.code in "Alcohol Brief Intervention and Counseling")

define "Last Smoking Counseling Procedure":
  "Last Counseling Procedure"("Procedures" Procedure
    where Procedure.code in "Tobacco Use Cessation Counseling")

define "Last BMI Counseling Procedure":
  "Last Counseling Procedure"("Procedures" Procedure
    where Procedure.code in "Weight Reduction Recommendations" or Procedure.code in "BMI Follow Up Plan SNOMEDCT")

define "Last Nutrition Counseling Procedure":
  "Last Counseling Procedure"("Procedures" Procedure
    where Procedure.code in "Counseling for Nutrition")

define "Last Physical Activity Counseling Procedure":
  "Last Counseling Procedure"("Procedures" Procedure
    where Procedure.code in "Physical Activity Recommendations")

define "Needs Alcohol Counseling":
  "Patient is a Heavy Alcoholic Drinker" and not Common."Procedure Occurred In Last 2 Years"("Last Alcohol Counseling Procedure")

define "Needs Smoking Counseling":
  "Patient is Currently a Smoker" and not Common."Procedure Occurred In Last 2 Years"("Last Smoking Counseling Procedure")

/* Action Conditionals defined in Plan Definition */
define "Patient Smoking Goals Action Path":
  "Enter Workflow" and ("Patient is Currently a Smoker" or exists "Tobacco Cessation Goals")

define "Patient Weight Loss Goals Action Path":
  "Enter Workflow" and ("Patient BMI is Greater than 25 kg/m2" or exists "Weight Loss Goals")

define "Patient Alcohol Goals Action Path":
  "Enter Workflow" and ("Patient is a Heavy Alcoholic Drinker" or exists "Alcohol Goals")

define "Patient Nutrition Goals Action Path":
  "Enter Workflow"

define "Patient Physical Activity Goals Action Path":
  "Enter Workflow"

define "TEST Get Average All BP Last 2 Years":
  Common."Avg BP"(Common."Blood Pressure Observations for Last 2 Years")

define "TEST Get Average Most Recent BP Set":
  Common."Avg BP"(Common."Most Recent BP Set")

define "TEST Exclusion":
  Common."Patient Under Age 18"
