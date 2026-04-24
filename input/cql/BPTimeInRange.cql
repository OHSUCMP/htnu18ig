library BPTimeInRange version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'
include OHSUHTNCommon version '0.1' called Common

codesystem "LOINC": 'http://loinc.org'

// -- Panel Concepts --
code "Office BP Panel": '85354-9' from "LOINC" display 'Blood pressure panel with all children optional'
code "Home BP Panel": '55284-4' from "LOINC" display 'Blood pressure systolic & diastolic - cardiovascular device'

concept "All BP Panels": { "Office BP Panel", "Home BP Panel" } display 'All Blood Pressure Panels'

// -- Component Codes --
code "Office Systolic": '8480-6' from "LOINC" display 'Systolic blood pressure'
code "Home Systolic": '8459-0' from "LOINC" display 'Systolic blood pressure - Home'
code "Office Diastolic": '8462-4' from "LOINC" display 'Diastolic blood pressure'
code "Home Diastolic": '8453-3' from "LOINC" display 'Diastolic blood pressure - Home'

concept "Systolic BP Components": { "Office Systolic", "Home Systolic" } display 'Systolic BP'
concept "Diastolic BP Components": { "Office Diastolic", "Home Diastolic" } display 'Diastolic BP'

// -- Parameters --
parameter "Measurement Period" Interval<DateTime>
  default Interval[Now() - 3 months, Now()]

// Target Thresholds (Customizable based on clinical guidelines)
parameter "Systolic Target" Decimal default 130.0
parameter "Diastolic Target" Decimal default 80.0

context Patient

// -- Logic --

define "Info":
  'info'

define "Warning":
  'warning'

define "Critical":
  'critical'

define "Errors":
  null

define "Meets Inclusion Criteria":
 true

define "Meets Exclusion Criteria":
  Common."Patient Under Age 18"
    or Common."Patient Over Age 100"
    or exists Common."Condition Indicating End Stage Renal Disease"
    or exists Common."Condition Indicating Pregnancy"
    or Common."HTN Crisis"

define "In Population":
  // Preserve this ordering so excluded patients fail fast
  not "Meets Exclusion Criteria" and "Meets Inclusion Criteria"

define "Provide Recommendation":
  "In Population"

define "Recommendation":
  if not "Provide Recommendation" then 'None'
  else 'Blood Pressure Time-in-Range'

define "Rationale Combined Data":
  "Rationale" + '|' + "Suggestions" + '|' + "Selection Behavior" + '|' + "Links"

define "Rationale":
  if not "Provide Recommendation" then ''
  else if "Total Readings Count" > 0 then
    '{{#patient}}Your blood pressure was in range for '
      + ToString(Round("Percentage Time In Range", 1))
      + '% of recorded readings during the measurement period (most recent 3 months).{{/patient}}'
      + '{{#careTeam}}Patient blood pressure was in range for '
      + ToString(Round("Percentage Time In Range", 1))
      + '% of recorded readings during the measurement period (most recent 3 months).{{/careTeam}}'
  else 'Consider obtaining additional blood pressure measurements.'

define "Indicator Status":
  "Info"

define "Suggestions":
  ''

define "Selection Behavior":
  'at-most-one'

define "Links":
  ''

// 1. Retrieve valid BP observations within the last 3 months
define "Valid BP Observations":
  [Observation: "All BP Panels"] BP
    where BP.status in { 'final', 'amended', 'corrected' }
      and BP.effective as dateTime in "Measurement Period"

// 2. Extract components and structure the data
define "BP Readings":
  "Valid BP Observations" BP
    let
      SysComp: singleton from (BP.component C where FHIRHelpers.ToConcept(C.code) ~ "Systolic BP Components"),
      DiaComp: singleton from (BP.component C where FHIRHelpers.ToConcept(C.code) ~ "Diastolic BP Components"),
      SysValue: SysComp.value as Quantity,
      DiaValue: DiaComp.value as Quantity
    where SysValue is not null and DiaValue is not null
    return {
      Date: BP.effective as dateTime,
      Systolic: SysValue.value,
      Diastolic: DiaValue.value
    }

// 3. Filter for readings within the target range
define "Readings In Range":
  "BP Readings" R
    where R.Systolic < "Systolic Target"
      and R.Diastolic < "Diastolic Target"

// 4. Calculate aggregates
define "Total Readings Count":
  Count("BP Readings")

define "In Range Count":
  Count("Readings In Range")

// 5. Generate Time in Range percentage
define "Percentage Time In Range":
  if "Total Readings Count" > 0 then
    ("In Range Count" * 100.0) / "Total Readings Count"
  else
    null