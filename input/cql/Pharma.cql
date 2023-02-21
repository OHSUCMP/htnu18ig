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

// Tests conditions from other workflows needed for Pharma intervention to proceed
define "Enter Workflow":
    "In Population" and not Common."Patient on Track"

define "Recommendation":
  if Common."Patient is Using Antihypertensive Medications" then 'Use shared decision making for treatment.'
  else 'Consider using medication to treat high blood pressure.'

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if Common."Patient is Using Antihypertensive Medications" then '{{#patient}}Your <strong>blood pressure is still high despite current efforts to lower it</strong>; changing your medication may be an option. This may occur sooner than expected.{{/patient}}{{#careTeam}}Employ shared decision making practices when discussing treatment for high blood pressure with your patient.{{/careTeam}}'
  else '{{#patient}}Your blood pressure is substantially elevated, to the point where <strong>medication should be considered</strong> to help manage it. This may occur sooner than expected. Speak with your care team to discuss medication options.{{/patient}}{{#careTeam}}In patients under 55 with high blood pressure and listed comorbidities, use thiazide-type diuretic, ACE-I, ARB, or CCB for first-line therapy{{/careTeam}}'

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
