library HypertensiveEmergency version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

context Patient

define "In Population":
  Common."HTN Crisis"

define "Recommendation":
  if "In Population" then 'Warning: Very high blood pressure. Please recheck the pressure in 5 minutes; if it is still >180/120, consult care team immediately.'
  else null

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if "In Population" then '{{#patient}}Your blood pressure is high (> 180 mmHg systolic and/or > 120 mmHg diastolic). Contact your care team immediately, or seek immediate care if you do not feel well.{{/patient}}{{#careTeam}}Patient\'s blood pressure is > 180 systolic or > 120 diastolic. Consider immediate evaluation for treatment or escalation of care.{{/careTeam}}'
  else null

define "Indicator Status":
  if "In Population" then 'critical'
  else null

define "Suggestions":
  if "In Population" then '[ { "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about your high blood pressure", "url":"/contact?token=urgent-bp"}] } ]'
  else null

define "Selection Behavior":
  'at-most-one'

define "Links":
  '[{"label":"AHA: When to call 911 for high blood pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings/hypertensive-crisis-when-you-should-call-911-for-high-blood-pressure"}]'

define "TEST Most Recent BP Reading":
  Common."Most Recent BP Reading"

define "TEST BP Within 14 days":
  Common."BP Within 14 days"
