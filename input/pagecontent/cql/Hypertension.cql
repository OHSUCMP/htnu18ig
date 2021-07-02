library Hypertension version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "v3 Code System ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

/* Inclusion */
valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'
valueset "Ambulatory Blood Pressure Monitoring (ABPM)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1047.511'
valueset "Systolic blood pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'

/* Exclusion */
valueset "Hypertension": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.3157.4012'
valueset "Non essential Hypertension SNOMEDCT": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'
valueset "Pregnancy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.378'
valueset "End Stage Renal Disease": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.590'
valueset "Hospice care ambulatory": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1108.15'

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
 "Patient Has Above Normal BP"

define "Meets Exclusion Criteria":
  "Patient Under Age 18"
    or "Patient Over Age 80"
    or exists "Condition Indicating End Stage Renal Disease"
    or exists "Condition Indicating Pregnancy"

define "In Population":
  "Meets Inclusion Criteria"
  and not "Meets Exclusion Criteria"

define "Recommendation":
  if not "In Population" then 'None'
  else if "Diagnosis of Preexisting Hypertension" then 'Standard high blood pressure guidelines do not apply'
  else if "HTN Crisis" then 'Warning: Potential hypertensive emergency. Consult care team immediately.'
  else if not "Has BP Set" then 'Consider obtaining additional blood pressure measurements'
  else if "HTN Stage 2" then 'Consider diagnosis of Stage 2 hypertension'
  else if "Consider HTN Stage 2" then 'Consider diagnosis of Stage 2 hypertension'
  else if "Consider HTN Stage 1" then 'Consider Diagnosis of Stage 1 hypertension.'
  else if "Prescribe HBP or ABP Monitoring" then 'Use ambulatory or home blood pressure monitoring to confirm diagnosis'
  else if "Prescribe Ambulatory BP Monitoring" then 'Use ambulatory blood pressure monitoring to address blood pressure variability'
  else 'Patient does not have an indication of a hypertensive state.'

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if not "In Population" then 'None'
  else if "Diagnosis of Preexisting Hypertension" then '{{#patient}}As you already have a high blood pressure diagnosis, please see your provider regarding your recent high blood pressure reading.{{/patient}}{{#careTeam}}{{/careTeam}}'
  else if "HTN Crisis" then '{{#patient}}Your blood pressure is high (>180 systolic or >120 diastolic).  Contact your care team immediately, OR, if you do not feel well, seek care.  {{/patient}}{{#careTeam}}Patient\'s blood pressure is > 180 systolic or > 120 diastolic. Consider immediate evaluation for treatment or escalation of care.{{/careTeam}}'
  else if not "Has BP Set" then '{{#patient}}You had a high blood pressure reading recently.  We do not have enough blood pressure measurements to provide a full picture of your health.  We consider a full set to be more than 4 in-office measurements, 6 home measurements, or 24 hours of ambulatory monitoring.{{/patient}}{{#careTeam}}Patient does not have enough blood pressures to make a strong determination of control or diagnosis.  We consider a full set to be more than 4 in-office measurements, 6 home measurements, or 24 hours of ambulatory monitoring.{{/careTeam}}'
  else if "HTN Stage 2" then '{{#patient}}You had multiple high blood pressure readings recently (>= 140 Systolic and/or 90 Diastolic).  This suggests you have Stage 2 hypertension, a treatable condition of high blood pressure. Please discuss with your care team.{{/patient}}{{#careTeam}}Patient had multiple blood pressure readings of SBP >= 140 mm HG and/or DBP >= 90 mm Hg. This strongly suggests the patient has Stage 2 Hypertension but no diagnosis was found.{{/careTeam}}'
  else if "Consider HTN Stage 2" then '{{#patient}}You recently had high blood pressure readings (>140 systolic or > 90 diastolic) which suggests hypertension, but no diagnosis is in your chart.{{/patient}}{{#careTeam}}Patient had multiple blood pressure readings of SBP > 140mm Hg and/or DBP > 90. This suggests the patient may have Stage 2 Hypertension, but no diagnosis was found.{{/careTeam}}'
  else if "Consider HTN Stage 1" then '{{#patient}}You recently had high blood pressure readings (> 130 systolic or > 80 diastolic), but do not have a recorded diagnosis of hypertension. You may want to discuss with your care team.{{/patient}}{{#careTeam}}Patient had multiple blood pressure readings of SBP > 130mm Hg and/or DBP > 80. This suggests the patient may have Stage 1 Hypertension, but no diagnosis was found.{{/careTeam}}'
  else if "Prescribe HBP or ABP Monitoring" then '{{#patient}}You had a high blood pressure reading recently and have a blood pressure is high, but have no hypertension diagnosis.  Taking more blood pressures will help your care team decide if the high blood pressures need treatment.{{/patient}}{{#careTeam}}In adults with suspected hypertension and without diagnostic uncertainty or BP variability, use Ambulatory Blood Pressure Monitoring or HBPM for diagnostic confirmation.{{/careTeam}}'
  else if "Prescribe Ambulatory BP Monitoring" then '{{#patient}}You had some variation in your blood pressures recently. Sometimes variation in blood pressure is a health risk ; your care team may recommend ambulatory blood pressure monitoring.{{/patient}}{{#careTeam}}In adults with suspected blood pressure variability, use Ambulatory Blood Pressure Monitoring to better understand risk.{{/careTeam}}'
  else 'No Further Action Required.'

define "Indicator Status":
  if not "In Population" then "Info"
  else if "Diagnosis of Preexisting Hypertension" then "Info"
  else if "HTN Crisis" then "Critical"
  else if not "Has BP Set" then "Info"
  else if "HTN Stage 2" then "Warning"
  else if "Consider HTN Stage 2" then "Warning"
  else if "Consider HTN Stage 1" then "Info"
  else if "Prescribe HBP or ABP Monitoring" then "Info"
  else if "Prescribe Ambulatory BP Monitoring" then "Info"
  else "Info"

define "Suggestions":
  if not "In Population" then 'None'
  else if "Diagnosis of Preexisting Hypertension" then ''
  else if "HTN Crisis" then '[ { "label": "Contact care team BP urgent", "type": "suggestion-link", "actions": [{"label":"Contact your care team about your high blood pressure", "url":"/contact"}] } ]'
  else if not "Has BP Set" then '[ { "label": "Enter Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Click here to go to the Home Blood Pressure entry page", "url":"/bp-readings"}] } ]'
  else if "HTN Stage 2" then '[ { "label": "Contact care team diagnosis", "type": "suggestion-link", "actions": [{"label":"Contact your care team about high blood presure diagnosis", "url":"/contact"}] } ]'
  else if "Consider HTN Stage 2" then '[ { "label": "Contact care team diagnosis", "type": "suggestion-link", "actions": [{"label":"Contact your care team about high blood presure diagnosis", "url":"/contact"}] } ]'
  else if "Consider HTN Stage 1" then '[ { "label": "Contact care team diagnosis", "type": "suggestion-link", "actions": [{"label":"Contact your care team about high blood presure diagnosis", "url":"/contact"}] } ]'
  else if "Prescribe HBP or ABP Monitoring" then '[ { "label": "Enter Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Click here to go to the Home Blood Pressure entry page", "url":"/bp-readings"}] } ]'
  else if "Prescribe Ambulatory BP Monitoring" then '[ { "label": "Request Ambulatory Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Click here to request Ambulatory Blood Pressure", "url":"/ambulatoryBP"}] } ]'
  else ''

define "Selection Behavior":
  if not "In Population" then 'None'
  else if "Diagnosis of Preexisting Hypertension" then 'at-most-one'
  else if "HTN Crisis" then 'at-most-one'
  else if not "Has BP Set" then 'at-most-one'
  else if "HTN Stage 2" then 'at-most-one'
  else if "Consider HTN Stage 2" then 'at-most-one'
  else if "Consider HTN Stage 1" then 'at-most-one'
  else if "Prescribe HBP or ABP Monitoring" then 'at-most-one'
  else if "Prescribe Ambulatory BP Monitoring" then 'at-most-one'
  else 'at-most-one'

define "Links":
  if not "In Population" then ''
  else if "Diagnosis of Preexisting Hypertension" then ''
  else if "HTN Crisis" then ''
  else if not "Has BP Set" then ''
  else if "HTN Stage 2" then '[{"label":"AHA: Understanding High Blood Pressure Readings", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings"}]'
  else if "Consider HTN Stage 2" then ''
  else if "Consider HTN Stage 1" then ''
  else if "Prescribe HBP or ABP Monitoring" then ''
  else if "Prescribe Ambulatory BP Monitoring" then ''
  else ''

define "Exclusion Reason":
  if "Meets Exclusion Criteria" then
    (
      'Patient was excluded from initial diagnosis of hypertension due to '
      + (
          if "Patient Under Age 18" then 'being under the age of 18.'
          else if "Patient Over Age 80" then 'being over the age of 80.'
          else if exists "Condition Indicating End Stage Renal Disease" then 'having end stage renal disease.'
          else if exists "Condition Indicating Pregnancy" then 'being pregnant.'
          else ''
        )
    )
  else ''


/* Patient Entered Elevated BP Reading Today */
// NOTE: Office-based visit Encounter valueset?
define "Patient Ambulatory Encounters":
  ["Encounter"] PE
    where (
      PE.status ~ 'arrived'
      or PE.status ~ 'in-progress'
      or PE.status ~ 'finished'
    )
      and PE.class ~ "ambulatory"


/* Blood Pressure Reading */
define "Blood Pressure Observations":
  (Common.WithUnit(Common.QualifiedObservation([Observation: "Blood Pressure Measured"]), 'mm[Hg]')) O

define "Most Recent BP":
  Last("Blood Pressure Observations" O sort by Coalesce(issued, start of Common."Normalize Interval"(effective)))

define "Blood Pressure Observations for Last 2 Years":
  ((
    "Blood Pressure Observations" BP
      with "Most Recent BP" MostRecentBP
        such that Common."Normalize Interval"(BP.effective) starts 24 months or less before end of Common."Normalize Interval"(MostRecentBP.effective)
  )
  union { "Most Recent BP" }) O
    sort by Coalesce(issued, start of Common."Normalize Interval"(effective))


define "Ambulatory Blood Pressure Monitoring Procedures":
  (Common.QualifiedProcedure(["Procedure": "Ambulatory Blood Pressure Monitoring (ABPM)"])) ABPMProcedure
    let ABPMProcedureInterval: Common."Normalize Interval"(ABPMProcedure.performed)
      where exists (
        "Blood Pressure Observations for Last 2 Years" BPObservation
          where BPObservation.partOf.reference includes ('Procedure/' + ABPMProcedure.id)
      )
      and hours between start of ABPMProcedureInterval and end of ABPMProcedureInterval >= 12

define "Office Blood Pressure Observations":
  "Blood Pressure Observations for Last 2 Years" BPObservation
    with "Patient Ambulatory Encounters" BPEncounter
      such that BPEncounter.class ~ "ambulatory"
        and Common."Normalize Interval"(BPObservation.effective) during BPEncounter.period

define "Home Blood Pressure Observations":
  "Blood Pressure Observations for Last 2 Years" BPObservation
    without "Patient Ambulatory Encounters" BPEncounter
      such that BPEncounter.class ~ "ambulatory"
        and Common."Normalize Interval"(BPObservation.effective) during BPEncounter.period

define "Ambulatory Blood Pressure Monitoring Observations":
  (Last("Ambulatory Blood Pressure Monitoring Procedures" P sort by end of Common."Normalize Interval"(performed))) ABPMProcedure
    return (
      "Blood Pressure Observations for Last 2 Years" BPObservation
      where BPObservation.partOf.reference includes ('Procedure/' + ABPMProcedure.id)
    )

define "Has BP Set":
  if exists "Ambulatory Blood Pressure Monitoring Procedures" then true
  else if Count("Office Blood Pressure Observations") >= 4 then true
  else if Count("Home Blood Pressure Observations") >= 6 then true
  else false

define "Most Recent BP Set":
  if exists "Ambulatory Blood Pressure Monitoring Procedures" then
    "Ambulatory Blood Pressure Monitoring Observations"
  else if Count("Office Blood Pressure Observations") >= 4 then
    Take(
      ("Office Blood Pressure Observations" O
        sort by Coalesce(issued, end of Common."Normalize Interval"(effective)) desc
      ), 4)
  else if Count("Home Blood Pressure Observations") >= 6 then
    Take(
      ("Home Blood Pressure Observations" O
        sort by Coalesce(issued, end of Common."Normalize Interval"(effective)) desc
      ), 6)
  else null


/* Blood Pressure Workflow */
define "Patient Has Above Normal BP":
  Common."Elevated or Above BP"({ "Most Recent BP" }) is not null

// Does patient have 'set' of BPs?
define "Patient has Set of BP Observations":
  if "In Population" is not true then
    false
  else
    "Has BP Set"

define "Patient does not have a Set of BP Observations":
  if "In Population" is not true then
    false
  else
    not "Has BP Set"

define "All BP":
  "Blood Pressure Observations for Last 2 Years"

// Is SBP > 180 and/or DBP > 120?
define "Patient Has Hypertensive BP":
  Common."HTN Crisis BP"({ "Most Recent BP" }) is not null

define "HTN Crisis":
  if "In Population" is not true then
    false
  else
    "Patient Has Hypertensive BP"

// Is last BP set or all BPs average > 140 SBP or > 90 DBP?
define "Patient Has Potential HTN Stage 2 BP":
  (
    Common."HTN Stage 2 BP"("Most Recent BP Set") is not null
    or Common."HTN Stage 2 BP"("All BP") is not null
  )

// Is last BP set or all BPs average > 160 SBP?
define "Patient Has HTN Stage 2 BP":
  "Patient Has Potential HTN Stage 2 BP"
    and (
        Common."HTN Stage 2 BP Systolic Second Test"("Most Recent BP Set") is not null
        or Common."HTN Stage 2 BP Systolic Second Test"("All BP") is not null
    )

define "HTN Stage 2":
  if "In Population" is not true then
    false
  else
    "Patient Has HTN Stage 2 BP"

define "Consider HTN Stage 2":
  if "In Population" is not true then
    false
  else
    "Patient Has Potential HTN Stage 2 BP"
      and not "Patient Has HTN Stage 2 BP"

// Is last BP set AND all BPs avg > 130/80?
define "Patient Has Potential HTN Stage 1 BP":
  (
    Common."HTN Stage 1 BP"("Most Recent BP Set") is not null
    and Common."HTN Stage 1 BP"("All BP") is not null
  )

define "Consider HTN Stage 1":
  if "In Population" is not true then
    false
  else
    "Patient Has Potential HTN Stage 1 BP"

// Is last BP set or all BPs avge > 130/80?
define "Confirm HTN":
  (
    Common."HTN Stage 1 BP"("Most Recent BP Set") is not null
    or Common."HTN Stage 1 BP"("All BP") is not null
  )

define "Prescribe HBP or ABP Monitoring":
  if "In Population" is not true then
    false
  else
    "Confirm HTN"

// Is SBP Coeff of Var > 11 for all BPs and no ABPM?
define "Confirm need for Patient Ambulatory BP Monitoring":
  if "Patient has Set of BP Observations" then
    (
      Common."Systolic BP Variability"("All BP").value > 11
      and not exists "Ambulatory Blood Pressure Monitoring Procedures"
    )
  else null

define "Prescribe Ambulatory BP Monitoring":
  if "In Population" is not true then
    false
  else
    "Confirm need for Patient Ambulatory BP Monitoring"

define "No Further Action":
  not (
    "HTN Crisis"
    and "Diagnosis of Preexisting Hypertension"
    and "Patient does not have a Set of BP Observations"
    and "HTN Stage 2"
    and "Consider HTN Stage 2"
    and "Consider HTN Stage 1"
    and "Prescribe HBP or ABP Monitoring"
    and "Prescribe Ambulatory BP Monitoring"
  )


/* Exclusion Criteria */
define "Patient Under Age 18":
  AgeInYearsAt(start of Common."Normalize Interval"("Most Recent BP".effective)) < 18

define "Patient Over Age 80":
  AgeInYearsAt(start of Common."Normalize Interval"("Most Recent BP".effective)) > 80

define "Condition Indicating End Stage Renal Disease":
  (Common.QualifiedCondition(["Condition": "End Stage Renal Disease"])) ESRD
    with "Most Recent BP" RecentBP
      such that Common."Prevalence Period"(ESRD) overlaps Common."Normalize Interval"(RecentBP.effective)

define "Condition Indicating Pregnancy":
  (Common.QualifiedCondition(["Condition": "Pregnancy"])) Pregnancy
    with "Most Recent BP" RecentBP
      such that Common."Prevalence Period"(Pregnancy) overlaps Common."Normalize Interval"(RecentBP.effective)

// Has patient already been diagnosed with HTN?
define "Condition Indicating Preexisting Hypertension":
  (
    (Common.QualifiedCondition(["Condition": "Hypertension"]))
    union (Common.QualifiedCondition(["Condition": "Non essential Hypertension SNOMEDCT"]))
  ) PreexistingCondition
    with "Most Recent BP" RecentBP
      such that Common."Prevalence Period"(PreexistingCondition) overlaps Common."Normalize Interval"(RecentBP.effective)

define "Diagnosis of Preexisting Hypertension":
  if "In Population" is not true then
    false
  else
    exists "Condition Indicating Preexisting Hypertension"


/* TESTS */
define "Test Patient Age on BP Reading":
  AgeInYearsAt(start of Common."Normalize Interval"("Most Recent BP".effective))

define "Test Count All BP":
  Count("All BP")

define "Test Most Recent BP":
  "Most Recent BP" BP
    return Tuple {
      "ID": BP.id,
      "Date": BP.effective.end,
      "Systolic": singleton from (BP.component C where C.code in "Systolic blood pressure").value.value,
      "Diastolic": singleton from (BP.component C where C.code in "Diastolic Blood Pressure").value.value
    }

define "Test Get All BP Observation Resources":
  ("Blood Pressure Observations" BP sort by Coalesce(issued, start of Common."Normalize Interval"(effective))) BP
    return Tuple {
      "Observation ID": BP.id
      }

define "Test Get Encounter BP Observations":
  from
    "Blood Pressure Observations" BPObservation,
      "Patient Ambulatory Encounters" BPEncounter
        where BPEncounter.class ~ "ambulatory"
          and Common."Normalize Interval"(BPObservation.effective) during BPEncounter.period
      return Tuple {
        "Observation ID": BPObservation.id,
        "Encounter ID": BPEncounter.id
        }

define "Test Get Most Recent BP Set":
  "Most Recent BP Set" BPSet
    return Tuple {
      "Observation ID": BPSet.id,
      "Encounter Reference": BPSet.encounter.reference
      }

define "Test All BP Last 2 Years":
  "Blood Pressure Observations for Last 2 Years" BPs
    return Tuple {
      "Observation ID": BPs.id,
      "Date": BPs.effective.end,
      "Encounter Reference": BPs.encounter.reference
      }

define "Test Get Average All BP Last 2 Years":
  Common."Avg BP"("All BP")

define "Test Get Average Most Recent BP Set":
  Common."Avg BP"("Most Recent BP Set")

define "Test Get All BP SBP Coefficient Variability":
  Common."Systolic BP Variability"("All BP").value
