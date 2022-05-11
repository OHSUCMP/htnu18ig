library Hypertension version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "v3 Code System ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

/* Inclusion */
valueset "Systolic blood pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'

code "ambulatory": 'AMB' from "v3 Code System ActCode" display 'ambulatory'

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


/* Recommendation Criteria - Hypertension  */
define "Meets Inclusion Criteria":
 not exists Common."Condition Indicating Preexisting Hypertension"

define "Meets Exclusion Criteria":
  Common."Patient Under Age 18"
    or Common."Patient Over Age 80"
    or exists Common."Condition Indicating End Stage Renal Disease"
    or exists Common."Condition Indicating Pregnancy"
    or Common."HTN Crisis"

define "In Population":
  "Meets Inclusion Criteria"
  and not "Meets Exclusion Criteria"

define "Recommendation":
  if not "In Population" then 'None'
  else if not Common."Has BP Set" then 'Consider obtaining additional blood pressure measurements.'
  else if "HTN Stage 2" then 'Consider diagnosis of Stage 2 hypertension.'
  else if "Consider HTN Stage 2" then 'Consider diagnosis of Stage 2 hypertension.'
  else if "Consider HTN Stage 1" then 'Consider diagnosis of Stage 1 hypertension.'
  else if "Prescribe Monitoring to Confirm HTN" then 'Use ambulatory or home blood pressure monitoring to confirm diagnosis.'
  else if Common."BP Highly Variable" then 'Use ambulatory blood pressure monitoring to address blood pressure variability.'
  else ''

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if not "In Population" then 'None'
  else if not Common."Has BP Set" then '{{#patient}}You recently had a high blood pressure reading, but <strong>we do not have enough blood pressure measurements</strong> to obtain a full picture of your current health. We consider a full set of measurements to be more than 4 in-office measurements, 6 home measurements, or 24 hours of ambulatory monitoring.{{/patient}}{{#careTeam}}Patient does not have enough blood pressures to make a strong determination of control or diagnosis.  We consider a full set to be more than 4 in-office measurements, 6 home measurements, or 24 hours of ambulatory monitoring.{{/careTeam}}'
  else if "HTN Stage 2" then '{{#patient}}You had multiple high blood pressure readings recently (≥ 140 mmHg systolic and/or ≥ 90 mmHg diastolic). These readings <strong>suggest you have stage 2 hypertension</strong>, a treatable condition of high blood pressure. Please discuss next steps with your care team.{{/patient}}{{#careTeam}}Patient had multiple blood pressure readings of SBP >= 140 mm HG and/or DBP >= 90 mm Hg. This strongly suggests the patient has Stage 2 Hypertension but no diagnosis was found.{{/careTeam}}'
  else if "Consider HTN Stage 2" then '{{#patient}}You recently had high blood pressure readings (≥ 140 mmHg systolic and/or ≥ mmHg 90 diastolic) which <strong>suggest you have hypertension</strong>, but there is no diagnosis in your chart. You may want to discuss your blood pressure with your care team.{{/patient}}{{#careTeam}}Patient had multiple blood pressure readings of SBP > 140mm Hg and/or DBP > 90. This suggests the patient may have Stage 2 Hypertension, but no diagnosis was found.{{/careTeam}}'
  else if "Consider HTN Stage 1" then '{{#patient}}You recently had high blood pressure readings (≥ 130 mmHg systolic and/or ≥ 80 mmHg diastolic) which <strong>suggest you have hypertension</strong>, but do not have a recorded diagnosis of hypertension. You may want to discuss your blood pressure with your care team.{{/patient}}{{#careTeam}}Patient had multiple blood pressure readings of SBP > 130mm Hg and/or DBP > 80. This suggests the patient may have Stage 1 Hypertension, but no diagnosis was found.{{/careTeam}}'
  else if "Prescribe Monitoring to Confirm HTN" then '{{#patient}}You recently had a <strong>high blood pressure reading</strong>, but do not have a recorded diagnosis of hypertension. Discuss out of office blood pressure monitoring with your care team.{{/patient}}{{#careTeam}}In adults with suspected hypertension and without diagnostic uncertainty or BP variability, use Ambulatory Blood Pressure Monitoring or HBPM for diagnostic confirmation.{{/careTeam}}'
  else if Common."BP Highly Variable" then '{{#patient}}You recently have had some <strong>variation in your blood pressure readings</strong>. Sometimes variation in blood pressure is a health risk; please contact your care team, as they may recommend ambulatory blood pressure monitoring.{{/patient}}{{#careTeam}}In adults with suspected blood pressure variability, use Ambulatory Blood Pressure Monitoring to better understand risk.{{/careTeam}}'
  else ''

define "Indicator Status":
  if not "In Population" then "Info"
  else if not Common."Has BP Set" then "Info"
  else if "HTN Stage 2" then "Warning"
  else if "Consider HTN Stage 2" then "Info"
  else if "Consider HTN Stage 1" then "Info"
  else if "Prescribe Monitoring to Confirm HTN" then "Info"
  else if Common."BP Highly Variable" then "Info"
  else "Info"

define "Suggestions":
  if not "In Population" then 'None'
  else if not Common."Has BP Set" then '[ { "id": "enter-bp-suggestion", "label": "Enter Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Click here to go to the Home Blood Pressure entry page", "url":"/vitals"}] } ]'
  else if "HTN Stage 2" then '[ { "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about a high blood pressure diagnosis", "url":"/contact?token=suspect-htn-stage2"}] } ]'
  else if "Consider HTN Stage 2" then '[ { "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about a high blood pressure diagnosis", "url":"/contact?token=possible-htn-stage2"}] } ]'
  else if "Consider HTN Stage 1" then '[ { "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about a high blood pressure diagnosis", "url":"/contact?token=possible-htn-stage1"}] } ]'
  else if "Prescribe Monitoring to Confirm HTN" then '[ { "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about out of office blood pressure measurements", "url":"/contact?token=office-bps"}] } ]'
  else if Common."BP Highly Variable" then '[ { "id": "ambulatory-suggestion", "label": "Request Ambulatory Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Click here to request Ambulatory Blood Pressure", "url":"/contact?token=ambulatory-bps"}] } ]'
  else ''

define "Selection Behavior":
  if not "In Population" then 'None'
  else if not Common."Has BP Set" then 'at-most-one'
  else if "HTN Stage 2" then 'at-most-one'
  else if "Consider HTN Stage 2" then 'at-most-one'
  else if "Consider HTN Stage 1" then 'at-most-one'
  else if "Prescribe Monitoring to Confirm HTN" then 'at-most-one'
  else if Common."BP Highly Variable" then 'at-most-one'
  else 'at-most-one'

define "Links":
  if not "In Population" then ''
  else if not Common."Has BP Set" then '[{"label":"CDC: How to measure blood pressure", "url":"https://www.cdc.gov/bloodpressure/measure.htm"}]'
  else if "HTN Stage 2" then '[{"label":"AHA: Understanding High Blood Pressure Readings", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings"}]'
  else if "Consider HTN Stage 2" then '[{"label":"AHA: Understanding High Blood Pressure Readings", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings"}]'
  else if "Consider HTN Stage 1" then '[{"label":"AHA: Understanding High Blood Pressure Readings", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings"}]'
  else if "Prescribe Monitoring to Confirm HTN" then '[{"label":"AHA: Monitoring your blood pressure at home", "url": "https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings/monitoring-your-blood-pressure-at-home"}]'
  else if Common."BP Highly Variable" then '[{"label":"24-hour Ambulatory Blood Pressure Monitoring", "url":"https://my.clevelandclinic.org/health/diagnostics/16330-24-hour-ambulatory-blood-pressure-monitoring"}]'
  else ''

define "Exclusion Reason":
  if "Meets Exclusion Criteria" then
    (
      'Patient was excluded from initial diagnosis of hypertension due to '
      + (
          if Common."Patient Under Age 18" then 'being under the age of 18.'
          else if Common."Patient Over Age 80" then 'being over the age of 80.'
          else if exists Common."Condition Indicating End Stage Renal Disease" then 'having end stage renal disease.'
          else if exists Common."Condition Indicating Pregnancy" then 'being pregnant.'
          else if Common."HTN Crisis" then 'a recent hypertensive emergency.'
          else ''
        )
    )
  else ''

// Is last BP set or all BPs average > 160 SBP?
define "Patient Has HTN Stage 2 BP":
  Common."Patient Has Potential HTN Stage 2 BP"
    and (
        Common."HTN Stage 2 BP Systolic Second Test"(Common."Most Recent BP Set") is not null
        or Common."HTN Stage 2 BP Systolic Second Test"(Common."Blood Pressure Observations for Last 2 Years") is not null
    )

define "HTN Stage 2":
  "In Population" and "Patient Has HTN Stage 2 BP"

define "Consider HTN Stage 2":
  "In Population" and Common."Patient Has Potential HTN Stage 2 BP"
      and not "Patient Has HTN Stage 2 BP"

// Is last BP set AND all BPs avg > 130/80?
define "Consider HTN Stage 1":
  "In Population" and (
    Common."HTN Stage 1 BP"(Common."Most Recent BP Set") is not null
    and Common."HTN Stage 1 BP"(Common."Blood Pressure Observations for Last 2 Years") is not null
  )

define "Prescribe Monitoring to Confirm HTN":
  "In Population" and Common."Patient Has Potential HTN Stage 1 BP" and not "Consider HTN Stage 1"

/* TESTS */
define "Test Patient Age on BP Reading":
  AgeInYearsAt(start of Common."Normalize Interval"(Common."Most Recent BP Reading".effective))

define "Test Count All BP":
  Count(Common."Blood Pressure Observations for Last 2 Years")

define "Test Most Recent BP":
  Common."Most Recent BP Reading" BP
    return Tuple {
      "ID": BP.id,
      "Date": BP.effective.end,
      "Systolic": singleton from (BP.component C where C.code in "Systolic blood pressure").value.value,
      "Diastolic": singleton from (BP.component C where C.code in "Diastolic Blood Pressure").value.value
    }

define "Test Get All BP Observation Resources":
  (Common."Blood Pressure Observations" BP sort by Coalesce(issued, start of Common."Normalize Interval"(effective))) BP
    return Tuple {
      "Observation ID": BP.id
      }

define "Test Get Most Recent BP Set":
  Common."Most Recent BP Set" BPSet
    return Tuple {
      "Observation ID": BPSet.id,
      "Encounter Reference": BPSet.encounter.reference
      }

define "Test All BP Last 2 Years":
  Common."Blood Pressure Observations for Last 2 Years" BPs
    return Tuple {
      "Observation ID": BPs.id,
      "Date": BPs.effective.end,
      "Encounter Reference": BPs.encounter.reference
      }

define "Test Get Average All BP Last 2 Years":
  Common."Avg BP"(Common."Blood Pressure Observations for Last 2 Years")

define "Test Get Average Most Recent BP Set":
  Common."Avg BP"(Common."Most Recent BP Set")

define "Test Get All BP SBP Coefficient Variability":
  Common."Systolic BP Variability"(Common."Blood Pressure Observations for Last 2 Years").value
