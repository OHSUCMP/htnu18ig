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
 exists Common."Condition Indicating Preexisting Hypertension"

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
  if not "In Population" then ''
  // 12
  else if not Common."Patient has a BP Goal" then '12. Discuss target blood pressure and set a blood pressure goal'
  // 13
  else if not Common."Has BP Set" then '13. Consider obtaining additional blood pressure measurements'
  // 14.a
  else if Common."Patient Has Potential HTN Stage 2 BP" then '14.a Blood pressure goal not reached. Discuss treatment options'
  // 14.b
  else if Common."Above Goal Average Most Recent" then '14.b Blood pressure goal not reached. Discuss treatment options'
  else if Common."BP Highly Variable" then '16. Use ambulatory blood pressure monitoring to address blood pressure variability'
  else 'Patient at goal!'

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if not "In Population" then ''
  else if not Common."Patient has a BP Goal" then '{{#patient}}You recently received a hypertension (high blood pressure) diagnosis.  Setting goals for lowering your blood pressure has been proven to help overall health and reduce your chance of stroke or other conditions.{{/patient}}{{#careTeam}}No BP Goal set: Setting a blood pressure goal can help engage patients and improve outcomes. For most patients, choosing a target between <120-140/80-90 is recommended; lower targets may be for ASCVD, ASCVD risk >10%, multimorbidity (CKD and diabetes), or preference; higher targets may be for age, adverse events, or frailty.{{/careTeam}}'
  else if not Common."Has BP Set" then '{{#patient}}Your recent blood pressure is above your goal.  We do not have enough blood pressures to provide a full picture of your blood pressure. Taking a full set of blood pressures can help.  We consider a full set to be ~4 in-office measurements, ~6 home measurements, or 12 hours of ambulatory monitoring.{{/patient}}{{#careTeam}}Patient does not have enough blood pressures to make a strong determination of control or diagnosis.  We consider a full set to be more than 4 in-office measurements, 6 home measurements, or 24 hours of ambulatory monitoring.{{/careTeam}}'
  else if Common."Patient Has Potential HTN Stage 2 BP" then '{{#patient}}Your recent blood pressure is above your goal. Changing your behaviors may help - see the additional options. In addition, please consult your care team to consider additional treatment options. Please review the home blood pressure measurement protocol presented on the blood pressure entry page to make sure that the tool is accurately measuring your blood pressure.{{/patient}}{{#careTeam}}BP not at goal. Consider initiating antihypertensive drug therapy with a single antihypertinsive drug with dosage titration and sequential addition of other agents to achieve the target BP.{{/careTeam}}'
  else if Common."Above Goal Average Most Recent" then '{{#patient}}Your recent blood pressure is above your goal. Changing your behaviors may help - see the additional options. In addition, please consult your care team to consider additional treatment options. Please review the home blood pressure measurement protocol presented on the blood pressure entry page to make sure that the tool is accurately measuring your blood pressure.{{/patient}}{{#careTeam}}BP not at goal. Consider initiating antihypertensive drug therapy with a single antihypertinsive drug with dosage titration and sequential addition of other agents to achieve the target BP.{{/careTeam}}'
  else if Common."BP Highly Variable" then '{{#patient}}Your recent blood pressure is above your goal and appears to be highly variable, which can indicate a health risk.  Ask your care team about ordering ambulatory blood pressure monitoring or how to get better measurements from home blood pressure monitoring.{{/patient}}{{#careTeam}}In adults with suspected blood pressure variability, use Ambulatory Blood Pressure Monitoring to better understand risk. If ABPM is not available, discuss more better protocols for home blood pressure monitoring.{{/careTeam}}'
  else 'No Further Action Required.'

define "Indicator Status":
  if not "In Population" then "Info"
  else if not Common."Patient has a BP Goal" then "Info"
  else if not Common."Has BP Set" then "Info"
  else if Common."Patient Has Potential HTN Stage 2 BP" then "Warning"
  else if Common."Above Goal Average Most Recent" then "Warning"
  else if Common."BP Highly Variable" then "Info"
  else "Info"

define "Suggestions":
  if not "In Population" then ''
  else if not Common."Patient has a BP Goal" then '[ { "id": "bp-radio-goal", "label": "BP Goal", "type": "bp-goal", "references":{"system":"https//coach.ohsu.edu", "code":"blood-pressure"}, "actions": [{"label":"140/90"}, {"label":"130/80"}, {"label":"120/80"}]}]'
  else if not Common."Has BP Set" then '[ { "id": "enter-bp-suggestion", "label": "Enter Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Click here to go to the Home Blood Pressure entry page", "url":"/bp-readings"}] } ]'
  else if Common."Patient Has Potential HTN Stage 2 BP" then '[ { "id": "contact-suggestion", "label": "Contact care team BP Treatment", "type": "suggestion-link", "actions": [{"label":"Contact your care team about options to control your high blood pressure", "url":"/contact"}] } ]'
  else if Common."Above Goal Average Most Recent" then '[ { "id": "contact-suggestion", "label": "Contact care team BP Treatment", "type": "suggestion-link", "actions": [{"label":"Contact your care team about options to control your high blood pressure", "url":"/contact"}] } ]'
  else if Common."BP Highly Variable" then '[ {"id": "ambulatory-suggestion", "label": "Request Ambulatory Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Click here to request Ambulatory Blood Pressure", "url":"/ambulatoryBP"}] } ]'
  else ''

define "Selection Behavior":
  'at-most-one'

define "Links":
  if not "In Population" then ''
  else if not Common."Patient has a BP Goal" then ''
  else if not Common."Has BP Set" then '[{"label":"Bell 2021: The potential for overdiagnosis and underdiagnosis because of blood pressure variability: a comparison of the 2017 ACC/AHA, 2018 ESC/ESH and 2019 NICE hypertension guidelines", "url":"https://pubmed.ncbi.nlm.nih.gov/32773652/"}]'
  else if Common."Patient Has Potential HTN Stage 2 BP" then ''
  else if Common."Above Goal Average Most Recent" then ''
  else if Common."BP Highly Variable" then ''
  else '[]'

define "Exclusion Reason":
  if "Meets Exclusion Criteria" then
    (
      'Patient was excluded from monitoring of hypertension due to '
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

define "No Entry into Population":
  not "Meets Inclusion Criteria"
    and not "Meets Exclusion Criteria"

define "No Entry Title":
  'Patient did not have a preexisting hypertensive condition.'

define "No Entry Description":
  'No Further Action Required.'

/* TESTS */
define "Test Count All BP":
  Count(Common."Blood Pressure Observations for Last 2 Years")

define "Test Most Recent BP":
  Common."Most Recent BP Reading" BP
    return Tuple {
      "ID": BP.id,
      "Date": BP.effective.end,
      "Systolic": singleton from (BP.component C where C.code in Common."Systolic blood pressure").value.value,
      "Diastolic": singleton from (BP.component C where C.code in Common."Diastolic Blood Pressure").value.value
    }

define "Test Get All BP Observation Resources":
  (Common."Blood Pressure Observations" BP sort by Coalesce(issued, start of Common."Normalize Interval"(effective))) BP
    return Tuple {
      "Observation ID": BP.id
      }

define "Test Get Encounter BP Observations":
  from
    Common."Blood Pressure Observations" BPObservation,
      Common."Patient Ambulatory Encounters" BPEncounter
        where BPEncounter.class ~ Common."ambulatory"
          and Common."Normalize Interval"(BPObservation.effective) during BPEncounter.period
      return Tuple {
        "Observation ID": BPObservation.id,
        "Encounter ID": BPEncounter.id
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

define "Test Get BP Goal":
  Common."BP from Most Recent Goal" BPGoal
    return Tuple { systolic: BPGoal.systolic.value,  diastolic: BPGoal.diastolic.value }

define "Test Get All BP SBP Coefficient Variability":
  Common."Systolic BP Variability"(Common."Blood Pressure Observations for Last 2 Years").value
