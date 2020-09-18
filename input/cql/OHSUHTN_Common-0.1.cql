library OHSUHTN_Common version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.0' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'

valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'

code "Blood Pressure": '55284-4' from "LOINC" display 'blood pressure'
code "Systolic Blood Pressure": '8480-6' from "LOINC" display 'Systolic blood pressure'
code "Diastolic Blood Pressure": '8462-4' from "LOINC" display 'Diastolic blood pressure'

parameter MeasurementPeriod default Interval[
  @2019-01-01T00:00:00.0,
  @2019-06-30T23:59:59.0
)

context Patient

define "Adult at start of Measurement Period":
  AgeInYearsAt(start of MeasurementPeriod) >= 18

// Blood Pressure Stuff /////////////////

define "Normal BP":
  "Avg BP" O
    where O.systolic < 120
    and O.diastolic < 80

define "Elevated BP":
  "Avg BP" O
    where O.systolic >= 120 and O.systolic < 130
    and O.diastolic < 80

define "HTN Stage 1 BP":
  "Avg BP" O
    where (O.systolic >= 130 and O.systolic < 140)
    or (O.diastolic >= 80 and O.diastolic < 90)

define "HTN Stage 2 BP":
  "Avg BP" O
    where O.systolic >= 140
    or O.diastolic >= 90

define "HTN Crisis BP":
  "Avg BP" O
    where O.systolic > 180
    or O.diastolic > 120

define "Systolic BP Variability String":
  "Systolic BP Variability" S
    return ToString(Round(S.value, 1)) + ' ' + S.unit

define "Systolic BP Variability":
  StdDev("Blood Pressure Observations" O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Systolic Blood Pressure").value)
  )

// Screening
define "Avg Last 4 BP String":
  "Avg Last 4 BP" O
    return ToString(Round(O.systolic.value)) + '/' + ToString(Round(O.diastolic.value)) + ' ' + O.systolic.unit

// Screening
define "Avg Last 4 BP":
  Tuple { systolic: "Avg Last 4 Systolic BP", diastolic: "Avg Last 4 Diastolic BP" }

// Screening
define "Avg Last 4 Systolic BP":
  Avg("Last 4 Blood Pressure Observations" O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Systolic Blood Pressure").value)
  )

// Screening
define "Avg Last 4 Diastolic BP":
  Avg("Last 4 Blood Pressure Observations" O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Diastolic Blood Pressure").value)
  )

// Screening
define "Last 4 Blood Pressure Observations":
  Take(("Blood Pressure Observations" O
    sort by issued desc
  ), 4)

define "Avg BP String":
  "Avg BP" O
    return ToString(Round(O.systolic.value)) + '/' + ToString(Round(O.diastolic.value)) + ' ' + O.systolic.unit

define "Avg BP":
  Tuple { systolic: "Avg Systolic BP", diastolic: "Avg Diastolic BP" }

define "Avg Systolic BP":
  Avg("Blood Pressure Observations" O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Systolic Blood Pressure").value)
  )

define "Avg Diastolic BP":
  Avg("Blood Pressure Observations" O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where FHIRHelpers.ToConcept(C.code) ~ "Diastolic Blood Pressure").value)
  )

define "Blood Pressure Observations":
   [Observation: "Blood Pressure"] O
   where "Normalize Interval"(O.effective) during MeasurementPeriod
      and O.status in { 'final', 'amended' }


/////////////////////////////////////////


define function "Normalize Interval"(choice Choice<FHIR.dateTime, FHIR.Period, FHIR.Timing, FHIR.instant, FHIR.string, FHIR.Age, FHIR.Range>):
  case
	  when choice is FHIR.dateTime then
    	Interval[FHIRHelpers.ToDateTime(choice as FHIR.dateTime), FHIRHelpers.ToDateTime(choice as FHIR.dateTime)]
		when choice is FHIR.Period then
  		FHIRHelpers.ToInterval(choice as FHIR.Period)
		when choice is FHIR.instant then
			Interval[FHIRHelpers.ToDateTime(choice as FHIR.instant), FHIRHelpers.ToDateTime(choice as FHIR.instant)]
		when choice is FHIR.Age then
		  Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(choice as FHIR.Age),
			  FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(choice as FHIR.Age) + 1 year)
		when choice is FHIR.Range then
		  Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((choice as FHIR.Range).low),
			  FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((choice as FHIR.Range).high) + 1 year)
		when choice is FHIR.Timing then
		  Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute a single interval from a Timing type')
    when choice is FHIR.string then
      Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute an interval from a String value')
		else
			null as Interval<DateTime>
	end
