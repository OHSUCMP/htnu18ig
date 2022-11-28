library AdverseEvents version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "AdverseEventOutcomeCodeSystem": 'http://terminology.hl7.org/CodeSystem/adverse-event-outcome'
code "ongoing": 'ongoing' from "AdverseEventOutcomeCodeSystem" display 'Ongoing'
code "resolved": 'resolved' from "AdverseEventOutcomeCodeSystem" display 'Resolved'

context Patient

define function "AE Event Display"(codes List<FHIR.Coding>):
  First(codes C where C.code != 'coach-adverse-event').display

define function "AE Suggestion String"(aes List<FHIR.AdverseEvent>):
  aes AE return '{"id": "' + AE.id + '", "type": "adverse-event", "label": "' + "AE Event Display"(AE.event.coding) + '"}'

define function "Contact Suggestion String"(aes List<FHIR.AdverseEvent>):
  aes AE return "AE Event Display"(AE.event.coding)

define "Untreated Recommendation":
  'Consider adjusting treatment.'

define "Untreated Rationale Combined Data":
  "Untreated Rationale" + '|' + "Untreated Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Untreated Rationale":
  '{{#patient}}You recently had a condition recorded that <strong>may be an adverse event from high blood pressure treatment</strong>. Contacting your care team will help them resolve it.{{/patient}}{{#careTeam}}Patient recently experienced an adverse reaction to antihypertensive medication. Work with patient to resolve the event, utilizing team-based care and telehealth strategies as needed.{{/careTeam}}'

define "Untreated Suggestions":
  '[{ "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about your condition(s): ' + Combine("Contact Suggestion String"("Untreated Adverse Events"), ', ') + '" , "url":"/contact?token=untreated-adverse-event"}] },' +
  Combine("AE Suggestion String"("Untreated Adverse Events"), ',') +
  ']'

define "Untreated Indicator Status":
  'critical'

define "Treated Indicator Status":
  'warning'

define "Selection Behavior":
  'at-most-one'

define "Links":
  ''

define "Treated Recommendation":
  'See care team and discuss treatment for hypertension if event recurs.'

define "Treated Rationale Combined Data":
  "Treated Rationale" + '|' + "Treated Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Treated Rationale":
  '{{#patient}}You recently had a condition recorded that may be an adverse event from high blood pressure treatment; you noted to us that this was already treated, but <strong>if it recurs or doesn\'t get better, please contact your care team</strong>.{{/patient}}{{#careTeam}}Patient has experienced an adverse event, which has been treated. Consider changes to the patient\'s course of treatment if the patient requests modification to care or if the benefits of continues treatment do not outweigh the risks.{{/careTeam}}'

define "Treated Suggestions":
  '[ { "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team about your condition(s): ' + Combine("Contact Suggestion String"("Treated Adverse Events"), ', ') + '" , "url":"/contact?token=treated-adverse-event"}] } ]'

// Only get the adverse events coded from the application
define "Adverse Events":
  [AdverseEvent] AE where AE.event.coding.code contains 'coach-adverse-event'

define "Treated Adverse Events":
  "Adverse Events" AE where AE.outcome ~ "resolved"

define "Untreated Adverse Events":
  "Adverse Events" AE where AE.outcome ~ "ongoing"

define "Untreated Adverse Events Action Path":
  exists "Untreated Adverse Events"

define "Treated Adverse Events Action Path":
  exists "Treated Adverse Events"
