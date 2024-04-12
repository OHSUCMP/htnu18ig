library HypertensiveEmergency version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

context Patient

define function "BP Within 14 Days"(O Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }):
  O.effective + 14 days >= Today()

// Two Low BPs are handled through an adverse event creation
define "In Population":
  Common."HTN Crisis" and not "Two Low BPs"

define "BP Observation Count":
  Count(Common."All BP Observations" O)

define "Next Most Recent BP Reading":
  if "BP Observation Count" > 1 then (Common."All BP Observations" O sort by effective)["BP Observation Count"-2]
  else null

define "Two High BPs":
  Common."HTN High Crisis" and "BP Within 14 Days"(Common."Most Recent BP Reading") and 
  "BP Within 14 Days"("Next Most Recent BP Reading") and Common."HTN Crisis BP"("Next Most Recent BP Reading")

define "Two Low BPs":
  Common."HTN Low Crisis" and "BP Within 14 Days"(Common."Most Recent BP Reading") and 
  "BP Within 14 Days"("Next Most Recent BP Reading") and Common."HTN Low Crisis BP"("Next Most Recent BP Reading")

define "Recommendation":
  'Blank.Summary'

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if "Two High BPs" then 'Your last two BP readings >=180 mmHg systolic and/or >=120 mmHg diastolic) are very high. <strong>If you <a href="/resources/symptoms-911">do not feel well</a>, call 911; otherwise, it is strongly recommended that you now contact your clinic.</strong>'
  else if Common."HTN High Crisis" then 'Remain calm and check your BP again following these <a href="/vitals#instructions">instructions</a> in 5 to 30 minutes. Read more about managing very high blood pressure in the link below.'
  else if Common."HTN Low Crisis" then 'Remain calm and check your BP again following these <a href="/vitals#instructions">instructions</a> in 5 to 30 minutes. Read more about symptoms from low blood pressure in the link below.'
  else null

define "Indicator Status":
  if "Two High BPs" then 'critical'
  else if "In Population" then 'critical'
  else null

define "Suggestions":
  if "Two High BPs" then '[{"id": "display-clinic-contact", "label": "", "type": "clinic-contact"}]'
  else if Common."HTN Crisis" then '[ { "id": "enter-bp-suggestion", "label": "Enter Blood Pressure", "type": "suggestion-link", "actions": [{"label":"Check your BP again (strongly recommended)", "url":"/vitals"}] } ]'
  else null

define "Selection Behavior":
  'at-most-one'

define "Links":
if "Two High BPs" or Common."HTN High Crisis" then '[{"label":"American Heart Association: When to call 911 for high blood pressure", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings/hypertensive-crisis-when-you-should-call-911-for-high-blood-pressure"}]'
else if Common."HTN Low Crisis" then '[{"label":"American Heart Association: When Blood Pressure is too Low", "url":"https://www.heart.org/en/health-topics/high-blood-pressure/the-facts-about-high-blood-pressure/low-blood-pressure-when-blood-pressure-is-too-low"}]'
else null

define "TEST Most Recent BP Reading":
  Common."Most Recent BP Reading"

define "TEST Next Most Recent BP Reading":
  "Next Most Recent BP Reading"

define "TEST Two High BPs":
  "Two High BPs"

define "TEST Two Low BPs":
  "Two Low BPs"

define "TEST One Low BP":
  Common."HTN Low Crisis"

