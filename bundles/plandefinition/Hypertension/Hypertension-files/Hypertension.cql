library Hypertension version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "v3 Code System ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'
valueset "Systolic blood pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'
valueset "Ambulatory Blood Pressure Monitoring (ABPM)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1047.511'
valueset "Non essential Hypertension SNOMEDCT": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'

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


/* Recommendation Criteria - Hypertension  */
 define "Meets Inclusion Criteria":
   "Patient Has Above Normal BP"

 /* define "Meets Exclusion Criteria":
   "Pregnant (SNOMED)"
     or "Non essential Hypertension SNOMEDCT"
     or "End Stage Renal Disease"
     or "Hospice Care" */

define "In Population":
  "Meets Inclusion Criteria"

define "Recommendation":
  if "HTN Crisis" then 'Patient may be in Hypertensive emergency.  Get this person to a hospital RIGHT NOW, like, not even kidding.  Call them an ambulance.'
  else if "Diagnosis of Preexisting Hypertension" then 'Patient has a preexisting diagnosis of Hypertension. Recommend patient for monitoring and treatment pathway.'
  else if not "Patient has Set of BP Observations" then 'Recommend more BPs at office or home.'
  else if "HTN Stage 2" then 'Patient has Stage 2 Hypertension.  Add or increase medication dosage, improve on exercise and diet initiatives.  Patient actually has to stop smoking and drinking now, for real.  I know they said they were going to stop last time around, but this time they really need to do it.'
  else if "Consider HTN Stage 2" then 'Patient may have Stage 2 Hypertension. Consider diagnosis of stage 2 HTN.'
  else if "Consider HTN Stage 1" then 'Patient may have Stage 1 Hypertension. Consider diagnosis of stage 1 HTN.'
  else if "Prescribe HBP or ABP Monitoring" then 'Prescribe HBP or ABP monitoring to confirm diagnosis of HTN.'
  else if "Prescribe Ambulatory BP Monitoring" then 'Prescribe Ambulatory BP Monitoring'
  else 'No Further Action Required.'

define "Rationale":
  if "HTN Crisis" then 'Patient may be in Hypertensive emergency.  Get this person to a hospital RIGHT NOW, like, not even kidding.  Call them an ambulance.'
  else if "Diagnosis of Preexisting Hypertension" then 'Patient has a preexisting diagnosis of Hypertension. Recommend patient for monitoring and treatment pathway.'
  else if not "Patient has Set of BP Observations" then 'Recommend more BPs at office or home.'
  else if "HTN Stage 2" then 'Patient has Stage 2 Hypertension.  Add or increase medication dosage, improve on exercise and diet initiatives.  Patient actually has to stop smoking and drinking now, for real.  I know they said they were going to stop last time around, but this time they really need to do it.'
  else if "Consider HTN Stage 2" then 'Patient may have Stage 2 Hypertension. Consider diagnosis of stage 2 HTN.'
  else if "Consider HTN Stage 1" then 'Patient may have Stage 1 Hypertension. Consider diagnosis of stage 1 HTN.'
  else if "Prescribe HBP or ABP Monitoring" then 'Prescribe HBP or ABP monitoring to confirm diagnosis of HTN.'
  else if "Prescribe Ambulatory BP Monitoring" then 'Prescribe Ambulatory BP Monitoring'
  else 'No Further Action Required.'


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

define "Most Recent Patient Encounter":
  Last("Patient Ambulatory Encounters" E sort by end of period)


/* Blood Pressure Reading */
define "Blood Pressure Observations":
  (Common.WithUnit(Common.QualifiedObservation([Observation: "Blood Pressure Measured"]), 'mmHg')) O
    with "Most Recent Patient Encounter" PE
      such that Common."Normalize Interval"(O.effective) during PE.period
        or Common."Normalize Interval"(O.effective) starts 24 months or less before end of PE.period

define "Most Recent BP":
  Last("Blood Pressure Observations" O sort by Coalesce(issued, start of Common."Normalize Interval"(effective)))

define "Ambulatory Blood Pressure Monitoring Procedures":
  (Common.QualifiedProcedures(["Procedure": "Ambulatory Blood Pressure Monitoring (ABPM)"])) ABPMProcedure
    let ABPMProcedureInterval: Common."Normalize Interval"(ABPMProcedure.performed)
      where exists (
        "Blood Pressure Observations" BPObservation
          where BPObservation.partOf.reference includes ('Procedure/' + ABPMProcedure.id)
      )
      and hours between start of ABPMProcedureInterval and end of ABPMProcedureInterval >= 12

define "Office Blood Pressure Observations":
  "Blood Pressure Observations" BPObservation
    with "Patient Ambulatory Encounters" BPEncounter
      such that BPEncounter.class ~ "ambulatory"
        and BPObservation.encounter.reference ~ ('Encounter/' + BPEncounter.id)

define "Home Blood Pressure Observations":
  "Blood Pressure Observations" BPObservation
    without "Patient Ambulatory Encounters" BPEncounter
      such that BPEncounter.class ~ "ambulatory"
        and BPObservation.encounter.reference ~ ('Encounter/' + BPEncounter.id)

define "Ambulatory Blood Pressure Monitoring Observations":
  (Last("Ambulatory Blood Pressure Monitoring Procedures" P sort by end of Common."Normalize Interval"(performed))) ABPMProcedure
    return (
      "Blood Pressure Observations" BPObservation
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
    null
  else
    "Has BP Set"

define "All BP":
  "Blood Pressure Observations"

// Is SBP > 180 and/or DBP > 120?
define "Patient Has Hypertensive BP":
  Common."HTN Crisis BP"({ "Most Recent BP" }) is not null

define "HTN Crisis":
  if "In Population" is not true then
    null
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
    null
  else
    "Patient Has HTN Stage 2 BP"

define "Consider HTN Stage 2":
  if "In Population" is not true then
    null
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
    null
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
    null
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
    null
  else
    "Confirm need for Patient Ambulatory BP Monitoring"


/* Exclusion Criteria */
// TODO: Determine if Pregnancy, End Stage Renal Diseasse, and Hospice Care affect Exclusions.
// Has patient already been diagnosed with HTN?
define "Diagnosis of Preexisting Hypertension":
  if "In Population" is not true then
    null
  else
    exists(Common.QualifiedCondition([Condition: "Non essential Hypertension SNOMEDCT"])) HypertensionDiagnosis
  // NOTE: Is there a timing period for diagnosing preexisting hypertensive states?
    //where Common."Prevalence Period"(HypertensionDiagnosis) during Common."Measurement Period"
