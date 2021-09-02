library OHSUHTNCommon version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "LOINC": 'http://loinc.org'
codesystem "ConditionClinicalStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-clinical'
codesystem "ConditionVerificationStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-ver-status'
codesystem "v3 Code System ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
codesystem "ConditionCategorySystem": 'http://terminology.hl7.org/CodeSystem/condition-category'

valueset "Systolic blood pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'
valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'
valueset "Ambulatory Blood Pressure Monitoring (ABPM)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1047.511'

/* Possible exclusions from workflows */
valueset "Hypertension": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.3157.4012'
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
    where O.systolic.value >= 180
    or O.diastolic.value >= 120

define function "Systolic BP Variability"(list List<FHIR.Observation>):
  if list is null then
    null
  else if Count(list) <= 1 then
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
      ((singleton from (Observations.component C where C.code in "Systolic blood pressure").value as FHIR.Quantity).unit.value ~ Unit
        and (singleton from (Observations.component C where C.code in "Diastolic Blood Pressure").value as FHIR.Quantity).unit.value ~ Unit)
      or ((singleton from (Observations.component C where C.code in "Systolic blood pressure").value as FHIR.Quantity).code.value ~ Unit
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
    where FHIRHelpers.ToConcept(Condition.verificationStatus) ~ "confirmed"

define function ConfirmedCondition(value Condition):
  value Condition
    where FHIRHelpers.ToConcept(Condition.verificationStatus) ~ "confirmed"

define function ActiveCondition(list List<Condition>):
  list Condition
    where FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "active"
      and Condition.abatement is null

define function ActiveCondition(value Condition):
  value Condition
    where FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "active"
      and Condition.abatement is null

define function ActiveOrRecurring(list List<Condition>):
  list Condition
    where (
      FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "active"
        and Condition.abatement is null
      )
      or FHIRHelpers.ToConcept(Condition.clinicalStatus) ~ "relapse"

define function QualifiedGoal(list List<Goal>):
  list Goal
    //proposed | planned | accepted | active | on-hold | completed | cancelled | entered-in-error | rejected
    where (
      Goal.lifecycleStatus ~ 'proposed'
      or Goal.lifecycleStatus ~ 'planned'
      or Goal.lifecycleStatus ~ 'accepted'
      or Goal.lifecycleStatus ~ 'active'
      or Goal.lifecycleStatus ~ 'completed'
    )


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

/***** Common Data *****/

/* Potential Exclusion Criteria */
define "Patient Under Age 18":
  AgeInYearsAt(Today()) < 18

define "Patient Over Age 80":
  AgeInYearsAt(Today()) > 80

// Grab all conditions for patients since we can't limit by code in Epic.
define "Conditions":
  (QualifiedCondition(["Condition": category ~ "problem-list-item"]))

define "Condition Indicating End Stage Renal Disease":
  "Conditions" Problem
    where Problem.code in "End Stage Renal Disease" and end of "Prevalence Period"(Problem) >= Today()

define "Condition Indicating Pregnancy":
  "Conditions" Problem
    where Problem.code in "Pregnancy" and end of "Prevalence Period"(Problem) >= Today()

define "Blood Pressure Observations":
  (WithUnit(QualifiedObservation(["Observation": "Blood Pressure Measured"]), 'mm[Hg]')) O
      sort by Coalesce(start of "Normalize Interval"(effective), issued)

define "Most Recent BP Reading":
  Last("Blood Pressure Observations" O sort by Coalesce(start of "Normalize Interval"(effective), issued))

define "BP Within 14 days":
  "Most Recent BP Reading" BP
  return Coalesce(start of "Normalize Interval"(BP.effective), BP.issued) + 14 days >= Today()

define "HTN Crisis":
  "BP Within 14 days" and "HTN Crisis BP"({ "Most Recent BP Reading" }) is not null

define "Blood Pressure Observations for Last 2 Years":
  "Blood Pressure Observations" BP where "Normalize Interval"(BP.effective) starts 24 months or less before Today()
    sort by Coalesce(start of "Normalize Interval"(effective), issued)

define "Blood Pressure Observations for Last 2 Years Descending":
  "Blood Pressure Observations for Last 2 Years" O sort by Coalesce(start of "Normalize Interval"(effective), issued) desc

// NOTE: Office-based visit Encounter valueset?
define "Patient Ambulatory Encounters":
  ["Encounter"] PE
    where (
      PE.status ~ 'arrived'
      or PE.status ~ 'in-progress'
      or PE.status ~ 'finished'
    )
      and PE.class ~ "ambulatory"

define "Ambulatory Blood Pressure Monitoring Procedures":
  (QualifiedProcedure(["Procedure": "Ambulatory Blood Pressure Monitoring (ABPM)"])) ABPMProcedure
    let ABPMProcedureInterval: "Normalize Interval"(ABPMProcedure.performed)
      where exists (
        "Blood Pressure Observations for Last 2 Years" BPObservation
          where BPObservation.partOf.reference includes ('Procedure/' + ABPMProcedure.id)
      )
      and hours between start of ABPMProcedureInterval and end of ABPMProcedureInterval >= 12

define "Office Blood Pressure Observations":
  "Blood Pressure Observations for Last 2 Years" BPObservation
    with "Patient Ambulatory Encounters" BPEncounter
      such that BPEncounter.class ~ "ambulatory"
        and "Normalize Interval"(BPObservation.effective) during BPEncounter.period

define "Home Blood Pressure Observations":
  "Blood Pressure Observations for Last 2 Years" BPObservation
    without "Patient Ambulatory Encounters" BPEncounter
      such that BPEncounter.class ~ "ambulatory"
        and "Normalize Interval"(BPObservation.effective) during BPEncounter.period

define "Ambulatory Blood Pressure Monitoring Observations":
  (Last("Ambulatory Blood Pressure Monitoring Procedures" P sort by end of "Normalize Interval"(performed))) ABPMProcedure
    return (
      "Blood Pressure Observations for Last 2 Years" BPObservation
      where BPObservation.partOf.reference includes ('Procedure/' + ABPMProcedure.id)
    )

define "Has BP Set":
    if not exists "Blood Pressure Observations for Last 2 Years" then false
    else calculateScore("Blood Pressure Observations for Last 2 Years") >= 4

define function score(observation Observation):
  if observation in "Ambulatory Blood Pressure Monitoring Observations" then 0.333
  else if observation in "Home Blood Pressure Observations" then 0.667
  else 1

define function calculateScore(list List<FHIR.Observation>):
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

define "OLD Most Recent BP Set":
  if exists "Ambulatory Blood Pressure Monitoring Procedures" then
    "Ambulatory Blood Pressure Monitoring Observations"
  else if Count("Office Blood Pressure Observations") >= 4 then
    Take(
      ("Office Blood Pressure Observations" O
        sort by Coalesce(issued, end of "Normalize Interval"(effective)) desc
      ), 4)
  else if Count("Home Blood Pressure Observations") >= 6 then
    Take(
      ("Home Blood Pressure Observations" O
        sort by Coalesce(issued, end of "Normalize Interval"(effective)) desc
      ), 6)
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

// Is SBP Coeff of Var > 11 for all BPs and no ABPM?
define "BP Highly Variable":
  if "Has BP Set" then
    (
      "Systolic BP Variability"("Blood Pressure Observations for Last 2 Years").value > 11
      and not exists "Ambulatory Blood Pressure Monitoring Procedures"
    )
  else null

define "Condition Indicating Preexisting Hypertension":
  "Conditions" Problem
    where (Problem.code in "Hypertension" or Problem.code in "Non essential Hypertension SNOMEDCT") and end of "Prevalence Period"(Problem) >= Today()

// Does patient have a BP goal?
define "Qualifying Blood Pressure Goals":
  (QualifiedGoal(["Goal"])) BPGoal
    where (
      singleton from (BPGoal.target Systolic
        where Systolic.measure in "Systolic blood pressure"
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
    "Qualifying Blood Pressure Goals" BPGoal
      sort by (start as date)
  )

define "Patient has a BP Goal":
  exists "Qualifying Blood Pressure Goals"


define "BP from Most Recent Goal":
  "Most Recently Established Blood Pressure Goal" BPGoal
    return Tuple {
      systolic: singleton from (BPGoal.target Systolic where Systolic.measure in "Systolic blood pressure").detail as Quantity,
      diastolic: singleton from (BPGoal.target Diastolic where Diastolic.measure in "Diastolic Blood Pressure").detail as Quantity
    }

define "Above Goal Average Most Recent":
  "Average Most Recent BP Set".systolic > "BP from Most Recent Goal".systolic or
  "Average Most Recent BP Set".diastolic > "BP from Most Recent Goal".diastolic

define "BP Goal Met":
  "Patient has a BP Goal" and "Has BP Set" and not "Above Goal Average Most Recent"
  and not "BP Highly Variable"
