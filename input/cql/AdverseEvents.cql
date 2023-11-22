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
  'Report Side Effect'

define "Untreated Rationale Combined Data":
  "Untreated Rationale" + '|' + "Untreated Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Untreated Rationale":
  'A side effect can be any undesirable outcome that results from blood pressure management. You recently had a condition that may be a side effect. If you are currently experiencing ongoing symptoms, we strongly recommend reaching out to your primary care provider.'

define "Untreated Suggestions":
  '[{ "id": "contact-suggestion", "label": "Contact care team", "type": "suggestion-link", "actions": [{"label":"Contact your care team if you are currently experiencing a side effect" , "url":"/contact?token=untreated-adverse-event"}] },' +
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
  'See care team and discuss treatment if event recurs'

define "Treated Rationale Combined Data":
  "Treated Rationale" + '|' + "Treated Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Treated Rationale":
  'A side effect associated with blood pressure management has been detected and addressed: <strong>' + Combine("Contact Suggestion String"("Treated Adverse Events"), ', ') + '</strong>. If event recurs, adjustment to medication and/or blood pressure goal may be required.'

define "Treated Suggestions":
  '[]'

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
