library Monitoring version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

context Patient

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

/* Recommendation Criteria - Monitoring Hypertension  */
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

define "Provide Recommendation":
  "In Population" and (not Common."Patient has a BP Goal" or not Common."Has 12 Home BPs" or not Common."Above Goal Average Most Recent")

define "Recommendation":
  if not "Provide Recommendation" then ''
  // 12
  else if not Common."Patient has a BP Goal" then 'Discuss target blood pressure and set a blood pressure goal'
  // 13
  else if not Common."Has 12 Home BPs" then 'Consider obtaining additional blood pressure measurements.'
  // Patient at Goal
  else 'Monitoring.Success.Summary' // COACH must look for this hack to display the green checkmark

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if not "Provide Recommendation" then ''
  else if not Common."Patient has a BP Goal" then '{{#patient}}You recently received a hypertension (high blood pressure) diagnosis.  Setting goals for lowering your blood pressure has been proven to help overall health and reduce your chance of stroke or other conditions.{{/patient}}{{#careTeam}}No BP Goal set: Setting a blood pressure goal can help engage patients and improve outcomes. For most patients, choosing a target between <120-140/80-90 is recommended; lower targets may be for ASCVD, ASCVD risk >10%, multimorbidity (CKD and diabetes), or preference; higher targets may be for age, adverse events, or frailty.{{/careTeam}}'
  else if not Common."Has 12 Home BPs" then 'Since we do not have enough blood pressure measurements to obtain a full picture of your health, we recommend you take a full set of measurements. We consider a full set to be at least 12 home measurements.'
  // Patient at Goal
  else 'At or below your goal BP: Keep up the good work! Click the link for what to do next.'

define "Indicator Status":
  "Info"

define "Suggestions":
  if not "Provide Recommendation" then ''
  else if not Common."Patient has a BP Goal" then '[ { "id": "bp-radio-goal", "label": "BP Goal", "type": "bp-goal", "references":{"system":"https://coach.ohsu.edu", "code":"blood-pressure"}, "actions": [{"label":"140/90"}, {"label":"130/80"}, {"label":"120/80"}]}]'
  else if not Common."Has 12 Home BPs" then '[ { "id": "enter-bp-suggestion", "label": "Enter Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Click here to go to the Home Blood Pressure entry page.", "url":"/vitals"}] } ]'
  else '[ { "id": "link-suggestion", "label": "", "type": "suggestion-link", "actions": [{"label":"My blood pressure is controlled: What to do next?", "url":"/infographic-controlled-bp.pdf"}] } ]'

define "Selection Behavior":
  'at-most-one'

define "Links":
  if not "Provide Recommendation" then ''
  else if not Common."Patient has a BP Goal" then '[{"label": "AHA: Understanding High Blood Pressure Readings", "url": "https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings"}]'
  else if not Common."Has 12 Home BPs" then '[{"label":"Bell 2021: The potential for overdiagnosis and underdiagnosis because of blood pressure variability: a comparison of the 2017 ACC/AHA, 2018 ESC/ESH and 2019 NICE hypertension guidelines", "url":"https://pubmed.ncbi.nlm.nih.gov/32773652/"}]'
  else '[]'

define "No Entry into Population":
  not "Meets Inclusion Criteria"
    and not "Meets Exclusion Criteria"

/* TESTS */
define "Test Count All BP":
  Count(Common."Blood Pressure Observations for Last 2 Years")

define "Test Most Recent BP":
  Common."Most Recent BP Reading" BP

define "Test Get All BP Observation Resources":
  Common."All BP Observations" BP

define "Test Get Has BP Set":
  Common."Has BP Set"

define "Test Get Most Recent BP Set":
  Common."Most Recent BP Set" BPSet

define "Test All BP Last 2 Years":
  Common."Blood Pressure Observations for Last 2 Years"

define "Test Get Average All BP Last 2 Years":
  Common."Avg BP"(Common."Blood Pressure Observations for Last 2 Years")

define "Test Get Average Most Recent BP Set":
  Common."Avg BP"(Common."Most Recent BP Set")

define "Test Get BP Goal":
  Common."BP from Most Recent Goal" BPGoal
    return Tuple { systolic: BPGoal.systolic.value,  diastolic: BPGoal.diastolic.value }

define "TEST Condition Prevalence Period":
  Common."Conditions" Problem
    return Common."Prevalence Period"(Problem)

define "TEST Condition Is Valid Prevalence Period":
  Common."Conditions" Problem
    return Common."Is Valid Prevalence Period"(Problem)

define "TEST Condition Indicating Preexisting Hypertension":
  Common."Condition Indicating Preexisting Hypertension"

define "TEST Problem Conditions":
  Common."Problem Conditions"

define "TEST Encounter Conditions":
  Common."Encounter Conditions"

define "Test Home BPs":
  Count(Common."Home Blood Pressure Observations")