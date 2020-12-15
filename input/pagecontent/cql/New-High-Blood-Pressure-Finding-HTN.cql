library "New-High-Blood-Pressure-Finding-HTN" version '0.0.1'

using FHIR version '4.0.1'

include "FHIRHelpers" version '4.0.1' called FHIRHelpers
include "OHSUHTN_Common" version '0.1' called Common

valueset "Systolic Blood Pressure Greater Than Equal To 140 VS": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1182.84'
valueset "Diastolic Blood Pressure Greater Than Equal To 90 VS": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1138.419'
valueset "Diastolic Blood Pressure Greater Than Equal To 90 VS_1": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1182.78'
valueset "Elevated Blood Pressure Reading VS": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1047.513'
valueset "Pregnant (SNOMED) VS": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1146.676'
valueset "Non essential Hypertension SNOMEDCT VS": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'
valueset "End Stage Renal Disease VS": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.353'
valueset "Palliative or Hospice Care VS": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.1.1579'
valueset "Hospice Care VS": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.3157.1004.20'

parameter "Measurement Period" default Interval[@2019-01-01T00:00:00,@2021-01-01T00:00:00]
context Patient

define "generic_condition_valuesets":
  [Condition: "Hospice Care VS"]
  union [Condition: "Hospice Care VS"]

define "Systolic BP greater than 140":
  WithUnit([Observation: "Systolic Blood Pressure Greater Than Equal To 140 VS"],  'mm[Hg]')

define "Diastolic Blood Pressure Greater Than Equal To 90":
  [Observation: "Diastolic Blood Pressure Greater Than Equal To 90 VS"]

define "Age 18 to 85":
  AgeInYears() >= 18 and AgeInYears() <= 85

define "Systolic BP greater than or equal to 140":
  exists(WithUnit([Observation: "Systolic Blood Pressure Greater Than Equal To 140 VS"],  'mm[Hg]'))

define "Diastolic BP greater than 90":
  exists(WithUnit([Observation: "Diastolic Blood Pressure Greater Than Equal To 90 VS_1"],  'mm[Hg]'))

define "Elevated Blood Pressure Reading":
  exists([Encounter: "Elevated Blood Pressure Reading VS"])

define "Pregnant (SNOMED)":
  exists(ActiveOrRecurring([Condition: "Pregnant (SNOMED) VS"]))

define "Non essential Hypertension SNOMEDCT":
  exists(ActiveCondition([Condition: "Non essential Hypertension SNOMEDCT VS"]))

define "End Stage Renal Disease":
  exists(Confirmed([Condition: "End Stage Renal Disease VS"]))

define "Hospice Care":
  exists(Confirmed([Condition: "Palliative or Hospice Care VS"]))

define "Pregnant (SNOMED) Subpopulation":
  exists(Confirmed(ActiveCondition([Condition: "Pregnant (SNOMED) VS"])))

define "Non essential Hypertension SNOMEDCT subpopulation":
  exists(Confirmed([Condition: "Non essential Hypertension SNOMEDCT VS"]))

define "Age under 18 subpopulation":
  AgeInYears() <= 18

define "Age over 85 subpopulation":
  AgeInYears() >= 85

define "Hospice Care subpopulation":
  exists(Confirmed("generic_condition_valuesets"))

define "End Stage Renal Disease subpopulation":
  exists(Confirmed([Condition: "End Stage Renal Disease VS"]))

define "MeetsInclusionCriteria":
  "Age 18 to 85"
  and "elevated BP"

define "elevated BP":
  "Systolic BP greater than or equal to 140"
  or "Diastolic BP greater than 90"
  or "Elevated Blood Pressure Reading"

define "MeetsExclusionCriteria":
  "Pregnant (SNOMED)"
  or "Non essential Hypertension SNOMEDCT"
  or "End Stage Renal Disease"
  or "Hospice Care"

define "Pregnant Subpopulation":
  if "InPopulation" is not true then
    null
  else
  "Pregnant (SNOMED) Subpopulation"

define "Secondary hypertension subpopulation":
  if "InPopulation" is not true then
    null
  else
  "Non essential Hypertension SNOMEDCT subpopulation"

define "Out of age range subpopulation":
  "Age under 18 subpopulation"
  or "Age over 85 subpopulation"

define "Had hospice subpopulation":
  "Hospice Care subpopulation"

define "End stage renal disease subpopulation":
  if "InPopulation" is not true then
    null
  else
  "End Stage Renal Disease subpopulation"

define "InPopulation":
  "MeetsInclusionCriteria" and not "MeetsExclusionCriteria"

define "Recommendation":
  if "MeetsExclusionCriteria" then 'Patient meets the exclusion criteria, so standard high blood pressure (hypertension) guidelines will not apply.'
  else if "Pregnant Subpopulation" then 'Follow up with your OB-Gyn and or Family Practitioner regarding your highblood pressure reading today.  '
  else if "Secondary hypertension subpopulation" then 'You have a known cause of high blood pressure (hypertension) and had a high blood pressure reading today.  Please see your specialist regarding the high reading today. '
  else if "End stage renal disease subpopulation" then 'You have kidney damage and had a high blood pressure reading today.  Please follow-up with your nephrologist. '
  else null


define "Rationale":
  if "MeetsExclusionCriteria" then null
  else if "Pregnant Subpopulation" then 'Uncontrolled blood pressure during pregnancy can lead to preeclampsia or even seizures.  Usually high blood pressure occurs in women with usually normal blood pressure roughly around 20 weeks pregnant. '
  else if "Secondary hypertension subpopulation" then 'Your high blood pressure (hypertension) has a known cause and requires specific therapy outside the normal scope of the hypertension guidelines.'
  else if "End stage renal disease subpopulation" then 'With your kidney damage you are outside of the normal high blood pressure (hypertension) guidelines. '
  else null

define "Errors":
  null


define function WithUnit(ObsList List<Observation>, Unit String):
  ObsList O
    where (O.value as FHIR.Quantity).unit.value = Unit or (O.value as FHIR.Quantity).code.value = Unit

define function Confirmed(CondList List<Condition>):
  CondList C where FHIRHelpers.ToConcept(C.verificationStatus) = Common."confirmed"

define function ActiveCondition(CondList List<Condition>):
  CondList C
    where FHIRHelpers.ToConcept(C.clinicalStatus) = Common."active"
      and (
        C.abatement is null
      )

define function ActiveOrRecurring(CondList List<Condition>):
  CondList C where FHIRHelpers.ToConcept(C.clinicalStatus) = Common."active"
  or FHIRHelpers.ToConcept(C.clinicalStatus) = Common."relapse"
