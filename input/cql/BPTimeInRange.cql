library BloodPressureTimeInRange version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'

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

// 1. Retrieve valid BP observations within the last 3 months
define "Valid BP Observations":
  [Observation: "All BP Panels"] BP
    where BP.status in { 'final', 'amended', 'corrected' }
      and BP.effective as dateTime in "Measurement Period"

// 2. Extract components and structure the data
define "BP Readings":
  "Valid BP Observations" BP
    let
      SysComp: singleton from (BP.component C where C.code in "Systolic BP Components"),
      DiaComp: singleton from (BP.component C where C.code in "Diastolic BP Components"),
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