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
  "Meets Inclusion Criteria"
  and not "Meets Exclusion Criteria"

// Tests conditions from other workflows needed for Pharma intervention to proceed
define "Enter Workflow":
    "In Population" and (Common."Patient Has Potential HTN Stage 2 BP" or not Common."Patient on Track")

define "Recommendation":
  if Common."Patient is Using Antihypertensive Medications" then 'Advancing Treatment'
  else 'Initial Pharmacology'

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  'placeholder'

define "Suggestions":
  ''

define "Indicator Status":
  'warning'

define "Selection Behavior":
  'at-most-one'

define "Links":
  ''
