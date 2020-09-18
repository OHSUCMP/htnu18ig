library Screening_FHIR4 version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.0' called FHIRHelpers
include OHSUHTN_Common_FHIR4 version '0.1' called OHSUHTN_Common

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'

valueset "Essential Hypertension Diagnosis": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.104.12.1011'

// commented out this Pregnancy grouping valueset, as its expansion doesn't include SNOMED codes which we need
// valueset "Pregnancy": 'https://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.378'

valueset "Pregnancy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.532'
valueset "Pregnancy Outcome": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.11.20.9.86'
valueset "Secondary Hypertension": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'
valueset "ESRD": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.590'
valueset "Hospice": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1108.15'

parameter MeasurementPeriod default Interval[
  @2019-01-01T00:00:00.0,
  @2019-06-30T23:59:59.0
)

context Patient

define "Info":
  'info'

define "Warning":
  'warning'

define "Critical":
  'critical'

define "In Population":
  "Inclusion Criteria" is true
    and "Exclusion Criteria" is not true

define "Inclusion Criteria":
  "Adult at start of Measurement Period"
    and "Any Essential Hypertension Diagnosis Ever"
    and "Minimum HTN Stage 1 BP over Last 4 readings"

define "Exclusion Criteria":
  "Is Pregnant Right Now"
    or "Secondary Hypertension Right Now"      // TODO: should be Secondary Hypertension Right Now
    or "Any ESRD Ever"
    or "Any Hospice Ever"

define "Recommendation":
  if "In Population" is true then
    'is in population, provide recommendation'
  else
    null

define "Rationale":
  if "In Population" is true then
    'is in population, provide rationale'
  else
    null

// inclusion ////////////////////////

define "Adult at start of Measurement Period":
  OHSUHTN_Common."Adult at start of Measurement Period"

define "Any Essential Hypertension Diagnosis Ever":
  Count("All Essential Hypertension Diagnosis Conditions") > 0

define "Minimum HTN Stage 1 BP over Last 4 readings":
  (OHSUHTN_Common."Avg Last 4 BP" O
    where O.systolic >= 130
    or O.diastolic >= 80) is not null

define "All Essential Hypertension Diagnosis Conditions":
  [Condition: "Essential Hypertension Diagnosis"] C
//    where OHSUHTN_Common."Normalize Interval"(C.onset) during MeasurementPeriod

// exclusion ////////////////////////

define "Secondary Hypertension Right Now":
  Count("Current Secondary Hypertension Conditions") > 0

define "Is Pregnant Right Now":
  "Most Recent Pregnancy Observation" is not null
    and (
      "Most Recent Pregnancy Outcome Observation" is null
      or "Most Recent Pregnancy Outcome Observation".effective < "Most Recent Pregnancy Observation".effective
    )

define "Any ESRD Ever":
  Count("All ESRD Conditions") > 0

define "Any Hospice Ever":
  Count("All Hospice Conditions") > 0

define "Most Recent Pregnancy Outcome Observation":
  Last("Pregnancy Outcome Observations" O
    sort by effective asc
  )

define "Pregnancy Outcome Observations":
  [Observation: "Pregnancy Outcome"] O
    where O.status in { 'final', 'amended' }

define "Most Recent Pregnancy Observation":
  Last("Pregnancy Observations" O
    sort by effective asc
  )

define "Pregnancy Observations":
  [Observation: "Pregnancy"] O
    where O.status in { 'final', 'amended' }

define "Current Secondary Hypertension Conditions":
  [Condition: "Secondary Hypertension"] C
    where C.clinicalStatus = 'active' and C.verificationStatus = 'confirmed'
    and OHSUHTN_Common."Normalize Interval"(C.onset) during MeasurementPeriod
    // also see "Normalize Abatement" for Conditions for the end of the Condition
    // no abatement == still a current Condition
    // abatement is listed as an open interval

define "All ESRD Conditions":
  [Condition: "ESRD"] C
    where C.verificationStatus = 'confirmed'
//  where OHSUHTN_Common."Normalize Interval"(C.onset) during MeasurementPeriod

define "All Hospice Conditions":
  [Condition: "Hospice"] C
    where C.verificationStatus = 'confirmed'
//  where OHSUHTN_Common."Normalize Interval"(C.onset) during MeasurementPeriod
