library Hypertension version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTN_Common version '0.1' called Common

valueset "Non essential Hypertension SNOMEDCT": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'
valueset "Systolic blood pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'

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
   "Age 18 to 85"
   and "Patient Has Elevated BP"

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
  else null

define "Rationale":
  if "HTN Crisis" then 'This person could die at any moment.  Keeling over with a heart attack is best handled in a hospital setting, so best they get to one ASAP.'
  else if "Diagnosis of Preexisting Hypertension" then 'Patient has a preexisting diagnosis of Hypertension. Recommend patient for monitoring and treatment pathway.'
  else if not "Patient has Set of BP Observations" then 'Recommend more BPs at office or home.'
  else if "HTN Stage 2" then 'Whatever we\'ve been doing to get this under control isn\'t working.  Time to add more BPs and get more serious about addressing this.'
  else if "Consider HTN Stage 2" then 'Patient may have Stage 2 Hypertension. Consider diagnosis of stage 2 HTN'
  else if "Consider HTN Stage 1" then 'Patient may have Stage 1 Hypertension. Consider diagnosis of stage 1 HTN.'
  else if "Prescribe HBP or ABP Monitoring" then 'Prescribe HBP or ABP monitoring to confirm diagnosis of HTN.'
  else if "Prescribe Ambulatory BP Monitoring" then 'Prescribe Ambulatory BP Monitoring'
  else null


/*  Population  */
define "Age 18 to 85":
  AgeInYearsAt(start of Common."Measurement Period"(Common."Patient Encounter")) >= 18
  and AgeInYearsAt(start of Common."Measurement Period"(Common."Patient Encounter")) <= 85


/* Blood Pressure */
define "Patient Has Elevated BP":
  Common."Elevated BP"({ Common."Blood Pressure Observation for Patient Encounter" }) is not null

// Does patient have 'set' of BPs?
define "Patient has Set of BP Observations":
  Common."Has BP Set"

define "Most Recent BP Set":
  Common."Most Recent BP Set"

define "All BP":
  Common."Blood Pressure Observations"

// Is SBP > 180 and/or DBP > 120?
define "Patient Has Hypertensive BP":
  Common."HTN Crisis BP"({ Common."Blood Pressure Observation for Patient Encounter" }) is not null

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
  (
    Common."Systolic BP Variability"("All BP").value > 11
    and not exists Common."Ambulatory Blood Pressure Monitoring Procedures"
  )

define "Prescribe Ambulatory BP Monitoring":
  if "In Population" is not true then
    null
  else
    "Confirm need for Patient Ambulatory BP Monitoring"


/* Exclusion Criteria */
// TODO: Determine if Pregnancy, End Stage Renal Diseasse, and Hospice Care affect Exclusions.
// Has patient already been diagnosed with HTN?
define "Diagnosis of Preexisting Hypertension":
  exists(Common.QualifiedCondition([Condition: "Non essential Hypertension SNOMEDCT"])) HypertensionDiagnosis
  // NOTE: Is there a timing period for diagnosing preexisting hypertensive states?
    //where Common."Prevalence Period"(HypertensionDiagnosis) during Common."Measurement Period"
