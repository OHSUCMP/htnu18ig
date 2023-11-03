library Pharma version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

context Patient

define "Meets Inclusion Criteria":
  exists Common."Condition Indicating Preexisting Hypertension"

define "Meets Exclusion Criteria":
  Common."Patient Under Age 18"
    or Common."Patient Over Age 80"
    or exists Common."Condition Indicating End Stage Renal Disease"
    or exists Common."Condition Indicating Pregnancy"
    or Common."HTN Crisis"

define "In Population":
  // Preserve this ordering so excluded patients fail fast
  not "Meets Exclusion Criteria" and "Meets Inclusion Criteria"

// Pharma Therapy should be received if there are 12 home BPs and goal has not been achieved
define "Receive Therapy":
  Common."Has 12 Home BPs" and Common."Patient has a BP Goal" and Common."Above Goal Average Most Recent"

// Tests conditions from other workflows needed for Pharma intervention to proceed
define "Enter Workflow":
    "In Population" and "Receive Therapy"

define "Recommendation":
  'Blood Pressure is not at goal'

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if Common."Patient is Using Antihypertensive Medications" then 'Your blood pressure is not at goal despite continuous monitoring. You may want to consider starting or changing antihypertensive medication. Other factors that can contribute to BP not being at goal include excessive stress, new over the counter remedies. Contact your care team to discuss options.'
  else 'Your blood pressure is not at goal despite continuous monitoring. You may want to consider starting or changing antihypertensive medication. Other factors that can contribute to BP not being at goal include excessive stress, new over the counter remedies. Contact your care team to discuss options.'

define "Suggestions":
  if Common."Patient is Using Antihypertensive Medications" then '[ { "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about options to control your high blood pressure.", "url":"/contact?token=recommend-advancing-treatment"}] } ]'
  else '[ { "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about options to control your high blood pressure.", "url":"/contact?token=recommend-pharma"}] } ]'

define "Indicator Status":
  'warning'

define "Selection Behavior":
  'at-most-one'

define "Links":
  ''

define "Test Antihypertensive Medications":
  Common."Patient is Using Antihypertensive Medications"
