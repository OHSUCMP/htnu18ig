library "Hypertension" version '0.1'

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

// TODO: Determine Usage of this file with Hypertension flow process - Exclusion Criteria and Sub Populations.

/* Recommendation Criteria - Hypertension  */
define "Meets Inclusion Criteria":
  "Age 18 to 85"
    and "elevated BP"

define "Meets Exclusion Criteria":
  "Pregnant (SNOMED)"
    or "Non essential Hypertension SNOMEDCT"
    or "End Stage Renal Disease"
    or "Hospice Care"

define "In Population":
  "Meets Inclusion Criteria"
    and not "Meets Exclusion Criteria"

define "Recommendation":
  if "Meets Exclusion Criteria" then 'Patient meets the exclusion criteria, so standard high blood pressure (hypertension) guidelines will not apply.'
  else if "Pregnant Subpopulation" then 'Follow up with your OB-Gyn and or Family Practitioner regarding your highblood pressure reading today.'
  else if "Secondary hypertension subpopulation" then 'You have a known cause of high blood pressure (hypertension) and had a high blood pressure reading today.  Please see your specialist regarding the high reading today.'
  else if "End stage renal disease subpopulation" then 'You have kidney damage and had a high blood pressure reading today.  Please follow-up with your nephrologist. '
  else null

define "Rationale":
  if "Meets Exclusion Criteria" then null
  else if "Pregnant Subpopulation" then 'Uncontrolled blood pressure during pregnancy can lead to preeclampsia or even seizures.  Usually high blood pressure occurs in women with usually normal blood pressure roughly around 20 weeks pregnant.'
  else if "Secondary hypertension subpopulation" then 'Your high blood pressure (hypertension) has a known cause and requires specific therapy outside the normal scope of the hypertension guidelines.'
  else if "End stage renal disease subpopulation" then 'With your kidney damage you are outside of the normal high blood pressure (hypertension) guidelines.'
  else null

define "Errors":
  null


/*  Population  */
define "Age 18 to 85":
  AgeInYears() >= 18 and AgeInYears() <= 85

define "Age under 18 subpopulation":
  AgeInYears() <= 18

define "Age over 85 subpopulation":
  AgeInYears() >= 85

define "Pregnant (SNOMED) Subpopulation":
  exists(Common.QualifiedCondition([Condition: "Pregnant (SNOMED) VS"]))

define "Non essential Hypertension SNOMEDCT subpopulation":
  exists(Common.QualifiedCondition([Condition: "Non essential Hypertension SNOMEDCT VS"]))

define "Hospice Care subpopulation":
  exists(Common.QualifiedCondition([Condition: "Hospice Care VS"]))

define "End Stage Renal Disease subpopulation":
  exists(Common.QualifiedCondition([Condition: "End Stage Renal Disease VS"]))

define "Pregnant Subpopulation":
  if "In Population" is not true then
    null
  else
  "Pregnant (SNOMED) Subpopulation"

define "Secondary hypertension subpopulation":
  if "In Population" is not true then
    null
  else
  "Non essential Hypertension SNOMEDCT subpopulation"

define "Out of age range subpopulation":
  "Age under 18 subpopulation"
  or "Age over 85 subpopulation"

define "Had hospice subpopulation":
  "Hospice Care subpopulation"

define "End stage renal disease subpopulation":
  if "In Population" is not true then
    null
  else
  "End Stage Renal Disease subpopulation"


/* Blood Pressure */

/* define "elevated BP":
  "Systolic BP greater than or equal to 140"
  or "Diastolic BP greater than 90"
  or "Elevated Blood Pressure Reading"

define "Systolic BP greater than 140":
  WithUnit(Common.QualifiedObservation([Observation: "Systolic Blood Pressure Greater Than Equal To 140 VS"]),  'mm[Hg]')

define "Diastolic Blood Pressure Greater Than Equal To 90":
  Common.QualifiedObservation([Observation: "Diastolic Blood Pressure Greater Than Equal To 90 VS"])

define "Systolic BP greater than or equal to 140":
  exists(WithUnit(Common.QualifiedObservation([Observation: "Systolic Blood Pressure Greater Than Equal To 140 VS"]),  'mm[Hg]'))

define "Diastolic BP greater than 90":
  exists(WithUnit(Common.QualifiedObservation([Observation: "Diastolic Blood Pressure Greater Than Equal To 90 VS_1"]),  'mm[Hg]'))

define "Elevated Blood Pressure Reading":
  exists([Encounter: "Elevated Blood Pressure Reading VS"]) */


/*  Exclusion Criteria  */
define "Pregnant (SNOMED)":
  exists(Common.ConfirmedCondition(Common.ActiveOrRecurring([Condition: "Pregnant (SNOMED) VS"])))

define "Non essential Hypertension SNOMEDCT":
  exists(Common.QualifiedCondition([Condition: "Non essential Hypertension SNOMEDCT VS"]))

define "End Stage Renal Disease":
  exists(Common.ConfirmedCondition([Condition: "End Stage Renal Disease VS"]))

define "Hospice Care":
  exists(Common.ConfirmedCondition([Condition: "Palliative or Hospice Care VS"]))


/* Helpers */
define function WithUnit(list List<Observation>, Unit String):
  list Observations
    where (Observations.value as FHIR.Quantity).unit.value = Unit
     or (Observations.value as FHIR.Quantity).code.value = Unit
