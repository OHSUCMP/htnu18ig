library HypertensiveEmergency version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

context Patient

define "In Population":
  Common."HTN Crisis"

define "Recommendation":
  if "In Population" then 'Warning: Potential hypertensive emergency. Consult care team immediately.'
  else null

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if "In Population" then '{{#patient}}Your blood pressure is high (>180 systolic or >120 diastolic).  Contact your care team immediately, OR, if you do not feel well, seek care.{{/patient}}{{#careTeam}}Patient\'s blood pressure is > 180 systolic or > 120 diastolic. Consider immediate evaluation for treatment or escalation of care.{{/careTeam}}'
  else null

define "Indicator Status":
  if "In Population" then 'critical'
  else null

define "Suggestions":
  if "In Population" then '[ { "id": "contact-suggestion", "label": "Contact care team BP urgent", "type": "suggestion-link", "actions": [{"label":"Contact your care team about your high blood pressure", "url":"/contact"}] } ]'
  else null

define "Selection Behavior":
  'at-most-one'

define "Links":
  ''

define "TEST Most Recent BP Reading":
  Common."Most Recent BP Reading"

define "TEST BP Within 14 days":
  Common."BP Within 14 days"
