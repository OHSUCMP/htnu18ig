library OHSUHTNCommon version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED": 'http://snomed.info/sct'
codesystem "ConditionClinicalStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-clinical'
codesystem "ConditionVerificationStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-ver-status'
codesystem "v3 Code System ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "ConditionCategorySystem": 'http://terminology.hl7.org/CodeSystem/condition-category'
codesystem "Medication request status": 'http://hl7.org/fhir/CodeSystem/medicationrequest-status'

valueset "Systolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'
valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'
valueset "Ambulatory Blood Pressure Monitoring (ABPM)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1047.511'
valueset "Antihypertensive Medications 1": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1178.10'
valueset "Antihypertensive Medications 2": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1200.242'

/* Possible exclusions from workflows */
/* valueset "Hypertension": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.3157.4012' */
valueset "Hypertension": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.104.12.1016'
valueset "Non essential Hypertension SNOMEDCT": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'
valueset "Pregnancy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.378'
valueset "End Stage Renal Disease": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.590'
valueset "Hospice care ambulatory": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1108.15'

code "ambulatory": 'AMB' from "v3 Code System ActCode" display 'ambulatory'

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

code "problem-list-item": 'problem-list-item' from "ConditionCategorySystem" display 'Problem List Item'
code "encounter-diagnosis": 'encounter-diagnosis' from "ConditionCategorySystem" display 'Encounter Diagnosis'

code "home-measurement": '264362003' from "SNOMED"

code "Active Medication Request": 'active' from "Medication request status"

context Patient

define function "Avg Systolic BP"(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  Avg(list O return all O.systolic)

define function "Avg Diastolic BP"(list List<Tuple {id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  Avg(list O return all O.diastolic)

define function "Avg BP"(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  Tuple { systolic: "Avg Systolic BP"(list), diastolic: "Avg Diastolic BP"(list) }

define function "Normal BP"(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  ("Avg BP"(list)) O
    where O.systolic <= 130
    and O.diastolic <= 80

define function "Elevated or Above BP"(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  ("Avg BP"(list)) O
    where O.systolic > 130
    or O.diastolic > 80

define function "HTN Stage 1 BP"(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  ("Avg BP"(list)) O
    where (O.systolic > 130 and O.systolic <= 140)
    or (O.diastolic > 80 and O.diastolic <= 90)

define function "HTN Stage 2 BP"(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  ("Avg BP"(list)) O
    where O.systolic > 140
    or O.diastolic > 90

define function "HTN Stage 2 BP Systolic Second Test"(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  ("Avg BP"(list)) O
    where O.systolic > 160

define function "HTN Crisis BP"(O Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }):
  O.systolic >= 180 or O.diastolic >= 120

/* Helpers */
define function WithUnit(list List<Observation>, Unit String):
  list Observations
    where (
      ((singleton from (Observations.component C where C.code in "Systolic Blood Pressure").value as FHIR.Quantity).unit.value ~ Unit
        and (singleton from (Observations.component C where C.code in "Diastolic Blood Pressure").value as FHIR.Quantity).unit.value ~ Unit)
      or ((singleton from (Observations.component C where C.code in "Systolic Blood Pressure").value as FHIR.Quantity).code.value ~ Unit
        and (singleton from (Observations.component C where C.code in "Diastolic Blood Pressure").value as FHIR.Quantity).code.value ~ Unit)
    )

define function WithUnit(value Quantity, Unit String):
  (
    value quantity
    where (
      quantity.code.value ~ Unit
      or quantity.unit.value ~ Unit
    )
  ) is not null

define function BPReadingType(o FHIR.Observation):
  if ("MeasurementSettings"(o.extension) contains "home-measurement") then 'home'
  else 'office'

define function QualifiedEncounter(list List<FHIR.Encounter>):
  list Encounter
    //planned | arrived | triaged | in-progress | onleave | finished | cancelled +
    where Encounter.status ~ 'finished'

define function QualifiedCondition(list List<FHIR.Condition>):
  list Condition
    //active | recurrence | relapse | inactive | remission | resolved
    //where ActiveCondition(Condition) is not null
    //unconfirmed | provisional | differential | confirmed | refuted | entered-in-error
    where ConfirmedCondition(Condition) is not null

define function QualifiedObservation(list List<FHIR.Observation>):
  list Observation
		where (
      //registered | preliminary | final | amended | corrected | cancelled | entered-in-error | unknown
			Observation.status ~ 'final'
			or Observation.status ~ 'amended'
			or Observation.status ~ 'corrected'
		)

define function QualifiedProcedure(list List<FHIR.Procedure>):
  list Procedure
    //preparation | in-progress | not-done | on-hold | stopped | completed | entered-in-error | unknown
    where Procedure.status ~ 'completed'

define function ConfirmedCondition(list List<Condition>):
  list Condition
    where Condition.verificationStatus is null
      or FHIRHelpers.ToConcept(Condition.verificationStatus) ~ "confirmed"

define function ConfirmedCondition(value Condition):
  value Condition
    where Condition.verificationStatus is null
      or FHIRHelpers.ToConcept(Condition.verificationStatus) ~ "confirmed"

define function ActiveCondition(list List<Condition>):
  list Condition
    where (
      Condition.clinicalStatus is null
        or FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "active"
      )
      and Condition.abatement is null

define function ActiveCondition(value Condition):
  value Condition
    where (
      Condition.clinicalStatus is null
        or FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "active"
      )
      and Condition.abatement is null

define function ActiveOrRecurring(list List<Condition>):
  list Condition
    where ActiveCondition(Condition) is not null
//      (
//      FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "active"
//        and Condition.abatement is null
//      )
      or FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "relapse"

// Epic sometimes provides the oid instead of the named system, but we need the named system for comparing to ValueSets
define function FixEpicSystemMapping(system String):
  if Matches(system, 'urn:oid:2.16.840.1.113883.6.96') then 'http://snomed.info/sct'
  else if Matches(system, 'urn:oid:2.16.840.1.113883.6.90') then 'http://hl7.org/fhir/sid/icd-10-cm'
  else system

// Take the list of Codes and replace the systems when needed
define function TranformCodeList(list List<System.Code>):
  list coding
  return System.Code {
    code: coding.code,
    system: FixEpicSystemMapping(coding.system),
    version: coding.version,
    display: coding.display
  }

// Transform the codes in the CodeableConcept, replacing the systems when needed
define function TransformCodeableConcept(cc FHIR.CodeableConcept):
  TranformCodeList(FHIRHelpers.ToConcept(cc).codes)

define function QualifiedGoal(list List<Goal>):
  list Goal
    //proposed | planned | accepted | active | on-hold | completed | cancelled | entered-in-error | rejected
    where (
      Goal.lifecycleStatus ~ 'accepted'
      or Goal.lifecycleStatus ~ 'active'
    )


define function "GetId"(uri String):
	Last(Split(uri, '/'))

/*
@description: Normalizes a value that is a choice of timing-valued types to an equivalent interval
@comment: Normalizes a choice type of FHIR.dateTime, FHIR.Period, FHIR.Timing, FHIR.instance, FHIR.string, FHIR.Age, or FHIR.Range types
to an equivalent interval. This selection of choice types is a superset of the majority of choice types that are used as possible
representations for timing-valued elements in FHIR, allowing this function to be used across any resource. NOTE: Due to the
complexity of determining a single interval from a Timing or String type, this function will throw a run-time exception if it is used
with a Timing or String.
*/
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

define function "Check Goal Start"(choice Choice<FHIR.date,FHIR.CodeableConcept>):
  case
	  when choice is FHIR.date then
    	FHIRHelpers.ToDate(choice)
		else
      null as System.Date
  end

/*
@description: Returns an interval representing the normalized Abatement of a given Condition resource.
@comment: NOTE: Due to the complexity of determining an interval from a String, this function will throw
a run-time exception if used with a Condition instance that has a String as the abatement value.
*/
define function "Normalize Abatement"(condition Condition):
  if condition.abatement is FHIR.dateTime then
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
    Interval[end of "Normalize Interval"(condition.onset), condition.recordedDate)
  else null

/*
@description: returns TRUE if the prevalence period is specified and encompasses today.  considers clinical status
              as a surrogate in the absence of prevalence period components (onset, abatement).
*/
define function "Is Valid Prevalence Period"(condition Condition):
  if condition.onset is not null and condition.abatement is not null then
    start of "Normalize Interval"(condition.onset) <= Today() + 1 day and end of "Normalize Abatement"(condition) >= Today() + 1 day
  else if condition.clinicalStatus is null
    or condition.clinicalStatus ~ "active"
    or condition.clinicalStatus ~ "recurrence"
    or condition.clinicalStatus ~ "relapse" then
      if condition.onset is not null then
        start of "Normalize Interval"(condition.onset) <= Today() + 1 day
      else if condition.abatement is not null then
        end of "Normalize Abatement"(condition) >= Today() + 1 day
      else
        true
  else
    false

/*
A pregnancy is considered active if one of the following are true:
- An onset and abatement exist, and today is after the onset and before the abatement
- Clinical status is active or null and
-- Only the onset exists and it's at least 42 weeks in the past
-- Only the abatement exists and it's in the future
-- Only the recorded date exists and it's at least 42 weeks in the past
-- No dates exist to provide additional context
*/
define function "Is Active Pregnancy"(condition Condition):
  if condition.onset is not null and condition.abatement is not null then
    start of "Normalize Interval"(condition.onset) <= Today() + 1 day and end of "Normalize Abatement"(condition) >= Today() + 1 day
  else if condition.clinicalStatus is null or condition.clinicalStatus ~ "active" then
      if condition.onset is not null then
        start of "Normalize Interval"(condition.onset) > Today() - 42 week
      else if condition.abatement is not null then
        end of "Normalize Abatement"(condition) >= Today() + 1 day
      else if condition.recordedDate is not null then
        condition.recordedDate > Today() - 42 week
      else
        true
  else
    false



/*
  @description: returns true if the procedure was known to be performed in the previous 2 years. Note that 'performed' seems to
  be going away in FHIR 5 and another way to get at a date could be through a encounter reference, so this is not very robust.
  This is only used to decide whether to show someone counseling again if the record is stale, and we will err on the side of
  showing if we don't know.
  */
define function "Procedure Occurred In Last 2 Years"(procedure Procedure):
  if procedure is null then false
  else if procedure.performed is not null then "Normalize Interval"(procedure.performed) ends 24 months or less before Today()
  else false

/*
@description: Returns an interval representing the normalized prevalence period of a given Condition resource.
              DEPRECATED - storer 2022-07-06 - use "Is Valid Prevalence Period" function above instead
*/
define function "Prevalence Period"(condition Condition):
  if condition.clinicalStatus ~ "active"
    or condition.clinicalStatus ~ "recurrence"
    or condition.clinicalStatus ~ "relapse"
    // This prevents errors when a condition has an onset and abatement on the same day and no timestamp is provided (Epic)
    or end of "Normalize Abatement"(condition) is not null then
      Interval[start of "Normalize Interval"(condition.onset), end of "Normalize Abatement"(condition)]
  else
    // The condition is not active but has no abatement date, so we can't say when it ended
    Interval[start of "Normalize Interval"(condition.onset), null)

/***** Common Data *****/

/* Potential Exclusion Criteria */
define "Patient Under Age 18":
  AgeInYearsAt(Today()) < 18

define "Patient Over Age 80":
  AgeInYearsAt(Today()) > 80

// Grab all conditions for patients since we can't limit by code in Epic.
define "Conditions":
  "Problem Conditions" union "Encounter Conditions"

// Epic requires category to be provided
define "Problem Conditions":
  (QualifiedCondition(["Condition": category ~ "problem-list-item"]))

// Epic requires category to be provided
define "Encounter Conditions":
  (QualifiedCondition(["Condition": category ~ "encounter-diagnosis"]))

define "Condition Indicating End Stage Renal Disease":
  "Conditions" Condition
    where TransformCodeableConcept(Condition.code) in "End Stage Renal Disease" and "Is Valid Prevalence Period"(Condition)

define "Condition Indicating Pregnancy":
  "Conditions" Condition
    where TransformCodeableConcept(Condition.code) in "Pregnancy" and "Is Active Pregnancy"(Condition)

define "Condition Indicating Preexisting Hypertension":
  "Problem Condition Indicating Preexisting Hypertension" union
  "Encounter Condition Indicating Preexisting Hypertension"

define "Problem Condition Indicating Preexisting Hypertension":
  "Problem Conditions" Condition
    where (TransformCodeableConcept(Condition.code) in "Hypertension" or TransformCodeableConcept(Condition.code) in
        "Non essential Hypertension SNOMEDCT") and "Is Valid Prevalence Period"(Condition)

define "Encounter Condition Indicating Preexisting Hypertension":
  "Encounter Conditions" Condition
    where (TransformCodeableConcept(Condition.code) in "Hypertension" or TransformCodeableConcept(Condition.code) in
        "Non essential Hypertension SNOMEDCT")

// We do not limit Observations by code to prevent CQF Ruler from looking beyond what is provided in the prefetch
define "All Observations":
  ["Observation"]

// "Normal" observations with systolic/diastolic components
define "Component BP Observations":
  (WithUnit(QualifiedObservation("All Observations" A where TransformCodeableConcept(A.code) in "Blood Pressure Measured"), 'mm[Hg]')) O
  return Tuple {
    id: O.id.value,
    effective: Coalesce(start of "Normalize Interval"(O.effective), O.issued),
    systolic: FHIRHelpers.ToQuantity(singleton from (O.component C where C.code in "Systolic Blood Pressure").value).value,
    diastolic: FHIRHelpers.ToQuantity(singleton from (O.component C where C.code in "Diastolic Blood Pressure").value).value,
    readingType: BPReadingType(O)
  }

define function ConvertSystolic(systolic List<FHIR.Observation>):
  systolic O
  return Tuple {
    id: O.id.value,
    effective: Coalesce(start of "Normalize Interval"(O.effective), O.issued),
    systolic: FHIRHelpers.ToQuantity(O.value).value,
    diastolic: null as Decimal,
    readingType: "BPReadingType"(O)
  } sort by effective

define function ConvertDiastolic(diastolic List<FHIR.Observation>):
  diastolic O
  return Tuple {
    id: O.id.value,
    effective: Coalesce(start of "Normalize Interval"(O.effective), O.issued),
    systolic: null as Decimal,
    diastolic: FHIRHelpers.ToQuantity(O.value).value,
    readingType: "BPReadingType"(O)
  }

/* For each systolic observation, gather a list of diastolic values that match by date */
define function GatherMatches(s List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>,
  d List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  s S
    return Tuple {
      systolicObservation : S,
      diastolicValues : (d D where S.effective = D.effective and S.readingType = D.readingType).diastolic
    }

/* For each systolic observation with exactly one disatolic match, return the paired observation */
define function PairMatchedBPObservations(list List<Tuple { systolicObservation Tuple {id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String },
  diastolicValues List<Decimal>} > ):
  (list B where Count(B.diastolicValues) = 1) matched return {
    // Only keeping the systolic id on the match - this is just for distinguishing unique readings at the same time which should be an edge case
    id: matched.systolicObservation.id,
    effective: matched.systolicObservation.effective,
    systolic: matched.systolicObservation.systolic,
    diastolic: matched.diastolicValues[0],
    readingType: matched.systolicObservation.readingType
  }

define function PairBPObservations(s List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>,
  d List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  PairMatchedBPObservations(GatherMatches(s, d))

define "Paired BP Observations":
  PairBPObservations(ConvertSystolic(QualifiedObservation("All Observations" A where TransformCodeableConcept(A.code) in "Systolic Blood Pressure")), ConvertDiastolic(QualifiedObservation("All Observations" A where TransformCodeableConcept(A.code) in "Diastolic Blood Pressure")))

define "All BP Observations":
  "Component BP Observations" union "Paired BP Observations"

define "Most Recent BP Reading":
  Last("All BP Observations" O sort by effective)

define "BP Within 14 days":
  "Most Recent BP Reading" BP
  return BP.effective + 14 days >= Today()

define "HTN Crisis":
  "BP Within 14 days" and "HTN Crisis BP"("Most Recent BP Reading")

define "Blood Pressure Observations for Last 2 Years":
  "All BP Observations" BP where BP.effective + 24 months >= Today()
    sort by effective

define "Blood Pressure Observations for Last 2 Years Descending":
  "Blood Pressure Observations for Last 2 Years" O sort by effective desc

define function MeasurementSettings(list List<Extension>):
  list Extension
    where Extension.url = 'http://hl7.org/fhir/us/vitals/StructureDefinition/MeasurementSettingExt'
  return FHIRHelpers.ToCode(Extension.value)

define "Home Blood Pressure Observations":
  "Blood Pressure Observations for Last 2 Years" O
    where O.readingType = 'home'

define "Office Blood Pressure Observations":
  "Blood Pressure Observations for Last 2 Years" except "Home Blood Pressure Observations"

// Revisit logic when ready to address ambulatory observations. Check out commit 57046448a24d24a767d402e5fa8a96779a488f02 for old logic
define "Ambulatory Blood Pressure Monitoring Observations":
  {}

define "Has BP Set":
    if not exists "Blood Pressure Observations for Last 2 Years" then false
    else calculateScore("Blood Pressure Observations for Last 2 Years") >= 4

define function score(observation Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }):
  if observation in "Ambulatory Blood Pressure Monitoring Observations" then 0.334
  else if observation in "Home Blood Pressure Observations" then 0.334
  else 1

define function calculateScore(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  Sum(list O
    return all score(O)
  )

define "Most Recent BP Set":
  if not "Has BP Set" then null
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 4)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 4)
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 5)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 5)
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 6)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 6)
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 7)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 7)
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 8)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 8)
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 9)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 9)
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 10)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 10)
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 11)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 11)
  else if calculateScore(Take("Blood Pressure Observations for Last 2 Years Descending", 12)) >= 4 then Take("Blood Pressure Observations for Last 2 Years Descending", 12)
  else null

define "Average All BP Last 2 Years":
  "Avg BP"("Blood Pressure Observations for Last 2 Years")

define "Average Most Recent BP Set":
  "Avg BP"("Most Recent BP Set")

// Is last BP set or all BPs avge > 130/80?
define "Patient Has Potential HTN Stage 1 BP":
  (
    "HTN Stage 1 BP"("Most Recent BP Set") is not null
    or "HTN Stage 1 BP"("Blood Pressure Observations for Last 2 Years") is not null
  )

// Is last BP set or all BPs average > 140 SBP or > 90 DBP?
define "Patient Has Potential HTN Stage 2 BP":
  (
    "HTN Stage 2 BP"("Most Recent BP Set") is not null
    or "HTN Stage 2 BP"("Blood Pressure Observations for Last 2 Years") is not null
  )

// Does patient have a BP goal?
define "Qualifying Blood Pressure Goals":
  (QualifiedGoal(["Goal"])) BPGoal
    where (
      singleton from (BPGoal.target Systolic
        where Systolic.measure in "Systolic Blood Pressure"
          and Systolic.detail is Quantity
          and WithUnit(Systolic.detail, 'mm[Hg]'))
    ) SystolicTarget is not null
      and (
        singleton from (BPGoal.target Diastolic
          where Diastolic.measure in "Diastolic Blood Pressure"
            and Diastolic.detail is Quantity
            and WithUnit(Diastolic.detail, 'mm[Hg]'))
      ) DiastolicTarget is not null

define "Most Recently Established Blood Pressure Goal":
  Last (
    "Qualifying Blood Pressure Goals" G
      sort by (Coalesce("Check Goal Start"(start), FHIRHelpers.ToDate(statusDate)))
  )

define "Patient has a BP Goal":
  exists "Qualifying Blood Pressure Goals"


define "BP from Most Recent Goal":
  "Most Recently Established Blood Pressure Goal" BPGoal
    return Tuple {
      systolic: (singleton from (BPGoal.target Systolic where Systolic.measure in "Systolic Blood Pressure").detail as Quantity).value,
      diastolic: (singleton from (BPGoal.target Diastolic where Diastolic.measure in "Diastolic Blood Pressure").detail as Quantity).value
    }

define "Above Goal Average Most Recent":
  "Average Most Recent BP Set".systolic > "BP from Most Recent Goal".systolic or
  "Average Most Recent BP Set".diastolic > "BP from Most Recent Goal".diastolic

// Therapy should be received if there's a BP set and a goal and the patient hasn't achived their goal
define "Receive Therapy":
  "Has BP Set" and "Patient has a BP Goal" and "Above Goal Average Most Recent"

define "Active Medication Requests":
  ["MedicationRequest"] Rx where Rx.status.value ~ "Active Medication Request".code

// Medication may be a Reference or a CodeableConcept. Return it as a Medication - only the code matters for processing
define function getMedication(Rx MedicationRequest):
  if Rx.medication is FHIR.Reference then
    singleton from ([Medication: id in Last(Split(Rx.medication.reference, '/'))])
  else
    Medication {code: Rx.medication}

define "Medication Requests With Medication":
  "Active Medication Requests" Rx
    let medication: getMedication(Rx)
    return
      MedicationRequest {
        id: Rx.id,
        status: Rx.status,
        intent: Rx.intent,
        category: Rx.category,
        medication: medication.code,
        subject: Rx.subject,
        authoredOn: Rx.authoredOn,
        recorder: Rx.recorder,
        dosageInstruction: Rx.dosageInstruction,
        dispenseRequest: Rx.dispenseRequest
      }

define "Patient is Using Antihypertensive Medications":
  "Medication Requests With Medication".medication in "Antihypertensive Medications 1" or
  "Medication Requests With Medication".medication in "Antihypertensive Medications 2"
