library ResistantAndSecondaryHTN version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'

// --- Terminology & Value Sets ---
valueset "Hypertension Diagnosis": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.104.12.1011'
valueset "Diuretic Medications": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.196.12.1005'
valueset "Antihypertensive Medications": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.196.12.1519' // Includes all classes
valueset "Hypokalemia Diagnosis": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1146.541'
valueset "Primary Aldosteronism Screening Tests": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1146.xxxx' // LOINC for ARR, Aldosterone, Renin

// --- Parameters ---
parameter "Measurement Period" Interval<DateTime>

// --- Common Context ---
context Patient

// --- Definitions ---

// 1. Diagnosis of Hypertension
define "Has Hypertension":
exists (
    [Condition: "Hypertension Diagnosis"] C
      where C.clinicalStatus.coding.code.value = 'active'
      and C.verificationStatus.coding.code.value = 'confirmed'
  )

// 2. Medication Logic
// Identify active antihypertensive medications
define "Active Antihypertensive Medications":
  [MedicationRequest: "Antihypertensive Medications"] M
    where M.status.value = 'active'
    and M.intent.value = 'order'
    // Ensure the medication covers the current period
    and M.authoredOn during "Measurement Period"

// Count distinct classes (simplified approach by counting distinct RxNorm codes or mapped classes)
// In a real implementation, you would group by therapeutic class (Thiazide, ACEI/ARB, CCB, BB)
define "Count of Antihypertensive Classes":
  Count("Active Antihypertensive Medications") // Placeholder for class logic

define "Has Diuretic":
exists (
    [MedicationRequest: "Diuretic Medications"] M
      where M.status.value = 'active'
  )

// 3. Blood Pressure Logic
define "Most Recent Systolic BP":
  Last(
    [Observation] O
      where O.code.coding.system contains 'http://loinc.org'
      and O.code.coding.code = '8480-6' // Systolic BP
      and O.status.value = 'final'
      sort by effective.value descending
  ).value as Quantity

define "Most Recent Diastolic BP":
  Last(
    [Observation] O
      where O.code.coding.system contains 'http://loinc.org'
      and O.code.coding.code = '8462-4' // Diastolic BP
      and O.status.value = 'final'
      sort by effective.value descending
  ).value as Quantity

define "BP Uncontrolled":
  "Most Recent Systolic BP" >= 130 'mm[Hg]' or
  "Most Recent Diastolic BP" >= 80 'mm[Hg]'

// --- COHORTS & IDENTIFICATION ---

// A. Resistant Hypertension Definition
// Criteria 1: Uncontrolled BP on >= 3 meds (one being a diuretic)
// Criteria 2: Controlled BP (or Uncontrolled) on >= 4 meds
define "Is Resistant Hypertension":
  "Has Hypertension" and
  (
    (
      "Count of Antihypertensive Classes" >= 3 and
      "Has Diuretic" and
      "BP Uncontrolled"
    )
    or
    (
      "Count of Antihypertensive Classes" >= 4
    )
  )

// B. Secondary Hypertension Screening Flags

// Flag 1: Resistant Hypertension (Universal Screening per 2025 Guidelines)
define "Flag: Screen for Primary Aldosteronism (Resistant HTN)":
  "Is Resistant Hypertension" and
  not exists (
    [Observation: "Primary Aldosteronism Screening Tests"] O
      where O.status.value = 'final'
  )

// Flag 2: Young Onset (Diagnosed < 30 years)
define "Flag: Screen for Secondary HTN (Young Onset)":
  "Has Hypertension" and
  AgeInYears() < 30

// Flag 3: Hypokalemia Presence (Spontaneous or Diuretic-Induced)
define "Has Hypokalemia":
exists (
    [Condition: "Hypokalemia Diagnosis"] C
      where C.clinicalStatus.coding.code.value = 'active'
  )
  or
exists (
    [Observation] O
      where O.code.coding.code = '6298-4' // LOINC for Potassium
      and O.value < 3.5 'mmol/L'
      and O.status.value = 'final'
      and O.effective.value within 1 year of Now()
  )

define "Flag: Screen for Secondary HTN (Hypokalemia)":
  "Has Hypertension" and
  "Has Hypokalemia"

// --- FINAL OUTPUT ---

define "Needs Secondary Hypertension Evaluation":
  "Flag: Screen for Primary Aldosteronism (Resistant HTN)" or
  "Flag: Screen for Secondary HTN (Young Onset)" or
  "Flag: Screen for Secondary HTN (Hypokalemia)"
