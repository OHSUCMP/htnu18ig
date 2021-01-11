library OHSUHTNCommon version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "ConditionClinicalStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-clinical'
codesystem "ConditionVerificationStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-ver-status'

valueset "Systolic blood pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'


// Condition Clinical Status Codes - Consider value sets for these
code "active": 'active' from "ConditionClinicalStatusCodes"
code "recurrence": 'recurrence' from "ConditionClinicalStatusCodes"
code "relapse": 'relapse' from "ConditionClinicalStatusCodes"
code "inactive": 'inactive' from "ConditionClinicalStatusCodes"
code "remission": 'remission' from "ConditionClinicalStatusCodes"
code "resolved": 'resolved' from "ConditionClinicalStatusCodes"

// Condition Verification Status Codes - Consider value sets for these
code "unconfirmed": 'unconfirmed' from ConditionVerificationStatusCodes
code "provisional": 'provisional' from ConditionVerificationStatusCodes
code "differential": 'differential' from ConditionVerificationStatusCodes
code "confirmed": 'confirmed' from ConditionVerificationStatusCodes
code "refuted": 'refuted' from ConditionVerificationStatusCodes
code "entered-in-error": 'entered-in-error' from ConditionVerificationStatusCodes


context Patient

define function "Avg Systolic BP"(list List<FHIR.Observation>):
  Avg(list O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where C.code in "Systolic blood pressure").value)
  )

define function "Avg Diastolic BP"(list List<FHIR.Observation>):
  Avg(list O
    return all FHIRHelpers.ToQuantity(singleton from (O.component C where C.code in "Diastolic Blood Pressure").value)
  )

define function "Avg BP"(list List<FHIR.Observation>):
  Tuple { systolic: "Avg Systolic BP"(list), diastolic: "Avg Diastolic BP"(list) }

define function "Avg BP String"(list List<FHIR.Observation>):
  ("Avg BP"(list)) O
    return ToString(Round(O.systolic.value)) + '/' + ToString(Round(O.diastolic.value)) + ' ' + O.systolic.unit

define function "Normal BP"(list List<FHIR.Observation>):
  ("Avg BP"(list)) O
    where O.systolic.value < 130
    and O.diastolic.value < 80

define function "Elevated or Above BP"(list List<FHIR.Observation>):
  ("Avg BP"(list)) O
    where O.systolic.value >= 130
    or O.diastolic.value >= 80

define function "HTN Stage 1 BP"(list List<FHIR.Observation>):
  ("Avg BP"(list)) O
    where (O.systolic.value >= 130 and O.systolic.value < 140)
    or (O.diastolic.value >= 80 and O.diastolic.value < 90)

define function "HTN Stage 2 BP"(list List<FHIR.Observation>):
  ("Avg BP"(list)) O
    where O.systolic.value >= 140
    or O.diastolic.value >= 90

define function "HTN Stage 2 BP Systolic Second Test"(list List<FHIR.Observation>):
  ("Avg BP"(list)) O
    where O.systolic.value >= 160

define function "HTN Crisis BP"(list List<FHIR.Observation>):
  ("Avg BP"(list)) O
    where O.systolic.value > 180
    or O.diastolic.value > 120

define function "Systolic BP Variability"(list List<FHIR.Observation>):
  if Count(list) = 1 then
    null
  else
    StdDev(list O
      return all FHIRHelpers.ToQuantity(singleton from (O.component C where C.code in "Systolic blood pressure").value)
  )

define function "Systolic BP Variability String"(list List<FHIR.Observation>):
  ("Systolic BP Variability"(list)) S
    return ToString(Round(S.value, 1)) + ' ' + S.unit


/* Helpers */
define function WithUnit(list List<Observation>, Unit String):
  list Observations
    where (
      ((singleton from (Observations.component C where C.code in "Systolic blood pressure").value as FHIR.Quantity).unit.value = Unit
        and (singleton from (Observations.component C where C.code in "Diastolic Blood Pressure").value as FHIR.Quantity).unit.value = Unit)
      or ((singleton from (Observations.component C where C.code in "Systolic blood pressure").value as FHIR.Quantity).code.value = Unit
        and (singleton from (Observations.component C where C.code in "Diastolic Blood Pressure").value as FHIR.Quantity).code.value = Unit)
    )

define function QualifiedEncounters(list List<FHIR.Encounter>):
  list Encounter
    //planned | arrived | triaged | in-progress | onleave | finished | cancelled +
    where Encounter.status ~ 'finished'

define function QualifiedCondition(list List<FHIR.Condition>):
  list Condition
    //active | recurrence | relapse | inactive | remission | resolved
    where ActiveCondition(Condition) is not null
    //unconfirmed | provisional | differential | confirmed | refuted | entered-in-error
    and ConfirmedCondition(Condition) is not null

define function QualifiedObservation(list List<FHIR.Observation>):
  list Observation
		where (
      //registered | preliminary | final | amended | corrected | cancelled | entered-in-error | unknown
			Observation.status ~ 'final'
			or Observation.status ~ 'amended'
			or Observation.status ~ 'corrected'
		)

define function QualifiedProcedures(list List<FHIR.Procedure>):
  list Procedure
    //preparation | in-progress | not-done | on-hold | stopped | completed | entered-in-error | unknown
    where Procedure.status ~ 'completed'

define function ConfirmedCondition(list List<Condition>):
  list Conditions
    where FHIRHelpers.ToConcept(Conditions.verificationStatus) ~ "confirmed"

define function ConfirmedCondition(value Condition):
  value Condition
    where FHIRHelpers.ToConcept(Condition.verificationStatus) ~ "confirmed"

define function ActiveCondition(list List<Condition>):
  list Conditions
    where FHIRHelpers.ToConcept(Conditions.clinicalStatus) ~ "active"
      and Conditions.abatement is null

define function ActiveCondition(value Condition):
  value Condition
    where FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "active"
      and Condition.abatement is null

define function ActiveOrRecurring(list List<Condition>):
  list Conditions
    where (
      FHIRHelpers.ToConcept(Conditions.clinicalStatus) ~ "active"
        and Conditions.abatement is null
      )
      or FHIRHelpers.ToConcept(Conditions.clinicalStatus) ~ "relapse"

define function "GetId"(uri String):
	Last(Split(uri, '/'))

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

define function "Normalize Onset"(onset Choice<FHIR.dateTime, FHIR.Age, FHIR.Period, FHIR.Range, FHIR.string>):
  if onset is FHIR.dateTime then
	  Interval[FHIRHelpers.ToDateTime(onset as FHIR.dateTime), FHIRHelpers.ToDateTime(onset as FHIR.dateTime)]
	else if onset is FHIR.Period then
	  FHIRHelpers.ToInterval(onset as FHIR.Period)
	else if onset is FHIR.string then
    Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute an interval from a String value')
	else if onset is FHIR.Age then
	  Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(onset as FHIR.Age),
		  FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(onset as FHIR.Age) + 1 year)
	else if onset is FHIR.Range then
	  Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((onset as FHIR.Range).low),
		  FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((onset as FHIR.Range).high) + 1 year)
	else null

define function "Normalize Abatement"(condition Condition):
  if condition.onset is not null and condition.abatement is null then
    Interval[Now(), Now()]
	else if condition.abatement is FHIR.dateTime then
	  Interval[FHIRHelpers.ToDateTime(condition.abatement as FHIR.dateTime), FHIRHelpers.ToDateTime(condition.abatement as FHIR.dateTime)]
	else if condition.abatement is FHIR.Period then
	  FHIRHelpers.ToInterval(condition.abatement as FHIR.Period)
	else if condition.abatement is FHIR.string then
    Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute an interval from a String value')
	else if condition.abatement is FHIR.Age then
		Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(condition.abatement as FHIR.Age),
			FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(condition.abatement as FHIR.Age) + 1 year)
	else if condition.abatement is FHIR.Range then
	  Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((condition.abatement as FHIR.Range).low),
		  FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((condition.abatement as FHIR.Range).high) + 1 year)
	else if condition.abatement is FHIR.boolean then
	  Interval[end of "Normalize Onset"(condition.onset), condition.recordedDate)
	else null

define function "Prevalence Period"(condition Condition):
  Interval[start of "Normalize Onset"(condition.onset), end of "Normalize Abatement"(condition))
