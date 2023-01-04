library Hypertension version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "v3 Code System ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

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
  // Preserve this ordering so excluded patients fail fast
  not "Meets Exclusion Criteria" and "Meets Inclusion Criteria"

define "No Further Action":
  "In Population" and Common."Has BP Set" and not "HTN Stage 2" and not "Consider HTN Stage 2" and not "Consider HTN Stage 1" and not "Prescribe Monitoring to Confirm HTN"

define "Recommendation Needed":
  "In Population" and not "No Further Action"

define "Recommendation":
  if not "In Population" then 'None'
  else if not Common."Has BP Set" then 'Hypertension.2-MoreMeasurements.Summary'
  else if "HTN Stage 2" then 'Hypertension.3-DiagnoseStage2.Summary'
  else if "Consider HTN Stage 2" then 'Hypertension.4-ConsiderStage2.Summary'
  else if "Consider HTN Stage 1" then 'Hypertension.5-ConsiderStage1.Summary'
  else if "Prescribe Monitoring to Confirm HTN" then 'Hypertension.6-PrescribeMonitoring.Summary'
  else 'No Further Action'

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if not "In Population" then 'None'
  else if not Common."Has BP Set" then 'Hypertension.2-MoreMeasurements.Rationale'
  else if "HTN Stage 2" then 'Hypertension.3-DiagnoseStage2.Rationale'
  else if "Consider HTN Stage 2" then 'Hypertension.4-ConsiderStage2.Rationale'
  else if "Consider HTN Stage 1" then 'Hypertension.5-ConsiderStage1.Rationale'
  else if "Prescribe Monitoring to Confirm HTN" then 'Hypertension.6-PrescribeMonitoring.Rationale'
  else 'None'

define "Indicator Status":
  if not "In Population" then "Info"
  else if not Common."Has BP Set" then "Info"
  else if "HTN Stage 2" then "Warning"
  else if "Consider HTN Stage 2" then "Info"
  else if "Consider HTN Stage 1" then "Info"
  else if "Prescribe Monitoring to Confirm HTN" then "Info"
  else "Info"

define "Suggestions":
  if not "In Population" then 'None'
  else if not Common."Has BP Set" then 'Hypertension.2-MoreMeasurements.Suggestions'
  else if "HTN Stage 2" then 'Hypertension.3-DiagnoseStage2.Suggestions'
  else if "Consider HTN Stage 2" then 'Hypertension.4-ConsiderStage2.Suggestions'
  else if "Consider HTN Stage 1" then 'Hypertension.5-ConsiderStage1.Suggestions'
  else if "Prescribe Monitoring to Confirm HTN" then 'Hypertension.6-PrescribeMonitoring.Suggestions'
  else 'None'

define "Selection Behavior":
  'Hypertension.SelectionBehavior'

define "Links":
  if not "In Population" then ''
  else if not Common."Has BP Set" then 'Hypertension.2-MoreMeasurements.Links'
  else if "HTN Stage 2" then 'Hypertension.3-DiagnoseStage2.Links'
  else if "Consider HTN Stage 2" then 'Hypertension.4-ConsiderStage2.Links'
  else if "Consider HTN Stage 1" then 'Hypertension.5-ConsiderStage1.Links'
  else if "Prescribe Monitoring to Confirm HTN" then 'Hypertension.6-PrescribeMonitoring.Links'
  else '[]'

define "Exclusion Summary":
  'Hypertension.Exclusion.Summary'

define "Exclusion Reason":
  if "Meets Exclusion Criteria" then
    if Common."Patient Under Age 18" then 'Hypertension.ExclusionMinAge.Detail'
    else if Common."Patient Over Age 80" then 'Hypertension.ExclusionMaxAge.Detail'
    else if exists Common."Condition Indicating End Stage Renal Disease" then 'Hypertension.ExclusionRenal.Detail'
    else if exists Common."Condition Indicating Pregnancy" then 'Hypertension.ExclusionPregnant.Detail'
    else if Common."HTN Crisis" then 'Hypertension.ExclusionWarning.Detail'
    else ''
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
define "Test Most Recent BP":
  Common."Most Recent BP Reading"

define "Test Get All BP Observation Resources":
  Common."All BP Observations" BP

define "Test Get Most Recent BP Set":
  Common."Most Recent BP Set" BPSet

define "Test Average BP of Set":
  Common."Avg BP"(Common."Most Recent BP Set")

define "Test All BP Last 2 Years":
  Common."Blood Pressure Observations for Last 2 Years Descending"

define "Test Get Average All BP Last 2 Years":
  Common."Avg BP"(Common."Blood Pressure Observations for Last 2 Years")

define "Test Get Average Most Recent BP Set":
  Common."Avg BP"(Common."Most Recent BP Set")

define "Home Blood Pressures":
  Common."Home Blood Pressure Observations"

define "Test Patient Age on BP Reading":
  AgeInYearsAt(Common."Most Recent BP Reading".effective)
