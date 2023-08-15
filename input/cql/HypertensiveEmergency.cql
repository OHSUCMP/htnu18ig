library HypertensiveEmergency version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

context Patient

define "In Population":
  Common."HTN Crisis"

define "BP Observation Count":
  Count(Common."All BP Observations" O)

define "Next Most Recent BP Reading":
  if "BP Observation Count" > 1 then (Common."All BP Observations" O sort by effective)["BP Observation Count"-2]
  else null

define "Two High BPs":
  "In Population" and Common."HTN Crisis BP"("Next Most Recent BP Reading")

define "Recommendation":
  if "Two High BPs" then 'Blank.Summary'
  else if "In Population" then 'Blank.Summary'
  else null

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if "Two High BPs" then 'Your last two BP readings >180 mmHg systolic and/or >120 mmHg diastolic) are very high. <strong>If you <a href="/symptoms-911">do not feel well</a>, call 911; otherwise, it is strongly recommended that you now contact your clinic.</strong>'
  else if "In Population" then 'Remain calm and check your BP again following these <a href="/vitals#instructions">instructions</a> in 5 to 30 minutes. Read more about managing very high blood pressure in the link below.'
  else null

define "Indicator Status":
  if "Two High BPs" then 'critical'
  else if "In Population" then 'critical'
  else null

define "Suggestions":
  if "Two High BPs" then '[{"id": "display-clinic-contact", "label": "", "type": "clinic-contact"}]'
  else if "In Population" then '[ { "id": "enter-bp-suggestion", "label": "Enter Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Check your BP again (strongly recommended)", "url":"/vitals"}] } ]'
  else null

define "Selection Behavior":
  'at-most-one'

define "Links":
  '[{"label":"American Heart Association: When to call 911 for high blood pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings/hypertensive-crisis-when-you-should-call-911-for-high-blood-pressure"}]'

define "TEST Most Recent BP Reading":
  Common."Most Recent BP Reading"

define "TEST BP Within 14 days":
  Common."BP Within 14 days"

define "TEST Next Most Recent BP Reading":
  "Next Most Recent BP Reading"
