library AdverseEvents version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "AdverseEventOutcomeCodeSystem": 'http://terminology.hl7.org/CodeSystem/adverse-event-outcome'
code "ongoing": 'ongoing' from "AdverseEventOutcomeCodeSystem" display 'Ongoing'
code "resolved": 'resolved' from "AdverseEventOutcomeCodeSystem" display 'Resolved'

context Patient

define function "AE Suggestion String"(aes List<FHIR.AdverseEvent>):
  aes AE return '{"id": "' + AE.id + '", "type": "adverse-event", "label": "' + First(AE.event.coding).display + '"}'

define function "Contact Suggestion String"(aes List<FHIR.AdverseEvent>):
  aes AE return First(AE.event.coding).display

define "Untreated Recommendation":
  'Consider adjusting treatment.'

define "Untreated Rationale Combined Data":
  "Untreated Rationale" + '|' + "Untreated Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Untreated Rationale":
  'You recently had a condition recorded that may be an adverse event from high blood pressure treatment. Contacting your care team will help them resolve it.'

define "Untreated Suggestions":
  '[' +
  Combine("AE Suggestion String"("Untreated Adverse Events"), ',') +
  ']'

define "Indicator Status":
  'warning'

define "Selection Behavior":
  'at-most-one'

define "Links":
  ''

define "Treated Recommendation":
  'See care team and discuss treatment for hypertension.'

define "Treated Rationale Combined Data":
  "Treated Rationale" + '|' + "Treated Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Treated Rationale":
  'You recently had a condition recorded that may be an adverse event from high blood pressure treatment; you noted to us that this was already treated, but if it recurs or doesn\'t get better, please contact your care team.'

define "Treated Suggestions":
  '[ { "id": "contact-suggestion", "label": "Contact care team Adverse Event", "type": "suggestion-link", "actions": [{"label":"Contact your care team about your condition(s): ' + Combine("Contact Suggestion String"("Treated Adverse Events"), ', ') + '" , "url":"/contact"}] } ]'

define "Adverse Events":
  [AdverseEvent]

define "Treated Adverse Events":
  "Adverse Events" AE where AE.outcome ~ "resolved"

define "Untreated Adverse Events":
  "Adverse Events" AE where AE.outcome ~ "ongoing"

define "Untreated Adverse Events Action Path":
  exists "Untreated Adverse Events"

define "Treated Adverse Events Action Path":
  exists "Treated Adverse Events"
