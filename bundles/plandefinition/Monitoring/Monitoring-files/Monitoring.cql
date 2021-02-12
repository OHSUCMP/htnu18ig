library Monitoring version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

codesystem "v3 Code System ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

/* Inclusion */
valueset "Blood Pressure Measured": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.600.2012'
valueset "Ambulatory Blood Pressure Monitoring (ABPM)": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1047.511'
valueset "Systolic blood pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.2'
valueset "Diastolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.1045'

/* Exclusion */
valueset "Hypertension": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.3157.4012'
valueset "Non essential Hypertension SNOMEDCT": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1032.10'
valueset "Pregnancy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.3.378'
valueset "End Stage Renal Disease": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.526.2.590'
valueset "Hospice care ambulatory": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1108.15'

code "ambulatory": 'AMB' from "v3 Code System ActCode" display 'ambulatory'

context Patient

define "Info":
  'info'

define "Warning":
  'warning'

define "Critical":
  'critical'

define "Errors":
  null

define "Patient Name":
  First(Patient.name.given)
   + ' ' +
  First(Patient.name.family)


/* Recommendation Criteria - Hypertension  */
define "Meets Inclusion Criteria":
 "Patient Has Above Normal BP"
    and exists "Condition Indicating Preexisting Hypertension"

define "Meets Exclusion Criteria":
  "Patient Under Age 18"
    or "Patient Over Age 80"
    or exists "Condition Indicating End Stage Renal Disease"
    or exists "Condition Indicating Pregnancy"

define "In Population":
  "Meets Inclusion Criteria"
  and not "Meets Exclusion Criteria"

define "Recommendation":
  if exists "Condition Indicating Pregnancy" then 'Standard high blood pressure guidelines do not apply'
  else if exists "Condition Indicating End Stage Renal Disease" then 'Standard high blood pressure guidelines do not apply'
  else if not "Patient has a BP Goal" then 'Discuss target blood pressure and set initial BP goal'
  else if not "Has BP Set" then 'Consider obtaining additional blood pressure measurements'
  else if "HTN Stage 2" then 'Not at goal: Recommend treatment.'
  else if "Not At Goal" then 'Not at goal: Recommend treatment.'
  else if "Prescribe HBP or ABP Monitoring" then 'Use ambulatory or home blood pressure monitoring to confirm not at BP goal'
  else if "Prescribe Ambulatory BP Monitoring" then 'Use ambulatory blood pressure monitoring to address blood pressure variability'
  else 'Patient at goal!'

define "Rationale":
  if exists "Condition Indicating Pregnancy" then 'Please see your Ob-Gyn provider for specialized care regarding your high blood pressure reading while pregnant'
  else if exists "Condition Indicating End Stage Renal Disease" then 'Please see your nephrologist for specialized care regarding your recent high blood pressure reading.'
  else if not "Patient has a BP Goal" then 'Please see your health-care provider to discuss a target blood pressure and set an initial BP goal.'
  else if not "Has BP Set" then 'You had a high blood pressure reading recently.  We do not have enough blood pressure measurements to provide a full picture of your health.  Getting a full set of blood pressures will help us provide the best care.  We consider a full set to be more than 4 in-office measurements, 6 home measurements, or 24 hours of ambulatory monitoring.'
  else if "HTN Stage 2" then 'You had a high blood pressure reading recently and are not at your blood pressure goal. Treatment is recommended.  Please see your provider to lower your blood pressure and reduce your risk of stroke or other adverse events.  More severe hypertension, stage 2 hypertension is a systolic pressure of 140 mm Hg or higher or a diastolic pressure of 90 mm Hg or higher.'
  else if "Not At Goal" then 'You had a high blood pressure reading recently and are not at your blood pressure goal. Treatment is recommended. Please see your provider to lower your blood pressure and reduce your risk of stroke or other adverse events.'
  else if "Prescribe HBP or ABP Monitoring" then 'You had a high blood pressure reading recently and have a blood pressure that is in a borderline for a hypertension diagnosis.  Taking a full set of blood pressures, approximately 6 days of home measurements (twice a day), or 24 hours of ambulatory monitoring, will help find the right diagnosis.'
  else if "Prescribe Ambulatory BP Monitoring" then 'You had a high blood pressure reading recently.  Your blood pressure has varied from reading to reading significantly.  Sometimes there is a health risk with highly variable blood pressure.  A 24 hour ambulatory/walking measurement will us provide the best care.'
  else 'No Further Action Required.'

define "Indicator Status":
  if exists "Condition Indicating Pregnancy" then "Info"
  else if exists "Condition Indicating End Stage Renal Disease" then "Info"
  else if not "Has BP Set" then "Info"
  else if "HTN Stage 2" then "Warning"
  else if "Not At Goal" then "Warning"
  else if "Prescribe HBP or ABP Monitoring" then "Info"
  else if "Prescribe Ambulatory BP Monitoring" then "Info"
  else "Info"

define "Exclusion Reason":
  if "Meets Exclusion Criteria" then
    (
      'Patient was excluded from monitoring of hypertension due to '
      + (
          if "Patient Under Age 18" then 'being under the age of 18.'
          else if "Patient Over Age 80" then 'being over the age of 80.'
          else if exists "Condition Indicating End Stage Renal Disease" then 'having end stage renal disease.'
          else if exists "Condition Indicating Pregnancy" then 'being pregnant.'
          else ''
        )
    )
  else ''


/* Patient Entered Elevated BP Reading Today */
// NOTE: Office-based visit Encounter valueset?
define "Patient Ambulatory Encounters":
  ["Encounter"] PE
    where (
      PE.status ~ 'arrived'
      or PE.status ~ 'in-progress'
      or PE.status ~ 'finished'
    )
      and PE.class ~ "ambulatory"


/* Blood Pressure Reading */
define "Blood Pressure Observations":
  (Common.WithUnit(Common.QualifiedObservation([Observation: "Blood Pressure Measured"]), 'mm[Hg]')) O

define "Most Recent BP":
  Last("Blood Pressure Observations" O sort by Coalesce(issued, start of Common."Normalize Interval"(effective)))

define "Blood Pressure Observations for Last 2 Years":
  ((
    "Blood Pressure Observations" BP
      with "Most Recent BP" MostRecentBP
        such that Common."Normalize Interval"(BP.effective) starts 24 months or less before end of Common."Normalize Interval"(MostRecentBP.effective)
  )
  union { "Most Recent BP" }) O
    sort by Coalesce(issued, start of Common."Normalize Interval"(effective))


define "Ambulatory Blood Pressure Monitoring Procedures":
  (Common.QualifiedProcedures(["Procedure": "Ambulatory Blood Pressure Monitoring (ABPM)"])) ABPMProcedure
    let ABPMProcedureInterval: Common."Normalize Interval"(ABPMProcedure.performed)
      where exists (
        "Blood Pressure Observations for Last 2 Years" BPObservation
          where BPObservation.partOf.reference includes ('Procedure/' + ABPMProcedure.id)
      )
      and hours between start of ABPMProcedureInterval and end of ABPMProcedureInterval >= 12

define "Office Blood Pressure Observations":
  "Blood Pressure Observations for Last 2 Years" BPObservation
    with "Patient Ambulatory Encounters" BPEncounter
      such that BPEncounter.class ~ "ambulatory"
        and Common."Normalize Interval"(BPObservation.effective) during BPEncounter.period

define "Home Blood Pressure Observations":
  "Blood Pressure Observations for Last 2 Years" BPObservation
    without "Patient Ambulatory Encounters" BPEncounter
      such that BPEncounter.class ~ "ambulatory"
        and Common."Normalize Interval"(BPObservation.effective) during BPEncounter.period

define "Ambulatory Blood Pressure Monitoring Observations":
  (Last("Ambulatory Blood Pressure Monitoring Procedures" P sort by end of Common."Normalize Interval"(performed))) ABPMProcedure
    return (
      "Blood Pressure Observations for Last 2 Years" BPObservation
      where BPObservation.partOf.reference includes ('Procedure/' + ABPMProcedure.id)
    )

define "Has BP Set":
  if exists "Ambulatory Blood Pressure Monitoring Procedures" then true
  else if Count("Office Blood Pressure Observations") >= 4 then true
  else if Count("Home Blood Pressure Observations") >= 6 then true
  else false

define "Most Recent BP Set":
  if exists "Ambulatory Blood Pressure Monitoring Procedures" then
    "Ambulatory Blood Pressure Monitoring Observations"
  else if Count("Office Blood Pressure Observations") >= 4 then
    Take(
      ("Office Blood Pressure Observations" O
        sort by Coalesce(issued, end of Common."Normalize Interval"(effective)) desc
      ), 4)
  else if Count("Home Blood Pressure Observations") >= 6 then
    Take(
      ("Home Blood Pressure Observations" O
        sort by Coalesce(issued, end of Common."Normalize Interval"(effective)) desc
      ), 6)
  else null

define "All BP":
  "Blood Pressure Observations for Last 2 Years"


/* Blood Pressure Workflow */
define "Patient Has Above Normal BP":
  Common."Elevated or Above BP"({ "Most Recent BP" }) is not null

define "Condition Indicating Preexisting Hypertension":
  (
    (Common.QualifiedCondition(["Condition": "Hypertension"]))
    union (Common.QualifiedCondition(["Condition": "Non essential Hypertension SNOMEDCT"]))
  ) PreexistingCondition
    with "Most Recent BP" RecentBP
      such that Common."Prevalence Period"(PreexistingCondition) overlaps Common."Normalize Interval"(RecentBP.effective)


// Does patient have a BP goal?
// Goal required lifecycleStatus of Active / planned / proposed / etc
// Goal achievementStatus for determining if we're reaching the target.
// Goal default primary path = category https://www.hl7.org/fhir/valueset-goal-category.html
// Goal required description: Blood Pressure Measured? Text with target BP under 130/80?
// Goal target.measure = Systolic / diastolic
// Goal Quantity Value

define "Qualifying Blood Pressure Goals":
  (Common.QualifiedGoals(["Goal"])) BPGoal
    where (
      singleton from (BPGoal.target Systolic
        where Systolic.measure in "Systolic blood pressure"
          and Systolic.detail is not null
          and Systolic.detail is Quantity
          and Common.WithUnit(Systolic.detail, 'mm[Hg]'))
    ) SystolicTarget is not null
      and (
        singleton from (BPGoal.target Diastolic
          where Diastolic.measure in "Diastolic Blood Pressure"
            and Diastolic.detail is not null
            and Diastolic.detail is Quantity
            and Common.WithUnit(Diastolic.detail, 'mm[Hg]'))
      ) DiastolicTarget is not null

define "Most Recently Established Blood Pressure Goal":
  Last (
    "Qualifying Blood Pressure Goals" BPGoal
      sort by (start as date)
  )

define "Patient has a BP Goal":
  if "In Population" is not true then
    false
  else
    exists "Qualifying Blood Pressure Goals"


// Does patient have 'set' of BPs?
define "Patient has Set of BP Observations":
  if "In Population" is not true then
    false
  else
    "Has BP Set"

define "Patient does not have a Set of BP Observations":
  if "In Population" is not true then
    false
  else
    not "Has BP Set"


// Is last BP set or all BPs average > 140 SBP or > 90 DBP?
define "Patient Has Potential HTN Stage 2 BP":
  (
    Common."HTN Stage 2 BP"("Most Recent BP Set") is not null
    or Common."HTN Stage 2 BP"("All BP") is not null
  )

define "HTN Stage 2":
  if "In Population" is not true then
    false
  else
    "Patient Has Potential HTN Stage 2 BP"


// Is last BP set AND all BPs avg > goal?
define "Average All BP Last 2 Years":
  Common."Avg BP"("All BP")

define "Average Most Recent BP Set":
  Common."Avg BP"("Most Recent BP Set")

define "BP from Most Recent Goal":
  "Most Recently Established Blood Pressure Goal" BPGoal
    return Tuple {
      systolic: singleton from (BPGoal.target Systolic where Systolic.measure in "Systolic blood pressure").detail as Quantity,
      diastolic: singleton from (BPGoal.target Diastolic where Diastolic.measure in "Diastolic Blood Pressure").detail as Quantity
    }

define "BP Average is Above Goal":
  AllTrue (
    from
      (
        { "Average All BP Last 2 Years" }
        union { "Average Most Recent BP Set" }
      ) BPAverages,
      "BP from Most Recent Goal" BPGoal
      return (
        BPAverages.systolic > BPGoal.systolic
          and BPAverages.diastolic > BPGoal.diastolic
      )
  )

define "Not At Goal":
  if "In Population" is not true then
    false
  else
    "BP Average is Above Goal"


// Is Last BP set or all BPs avg > 130/80?
define "Confirm HTN":
  (
    Common."HTN Stage 1 BP"("Most Recent BP Set") is not null
    or Common."HTN Stage 1 BP"("All BP") is not null
  )

define "Prescribe HBP or ABP Monitoring":
  if "In Population" is not true then
    false
  else
    "Confirm HTN"


// Is SBP Coeff of Var > 11 for all BPs and no ABPM?
define "Confirm need for Patient Ambulatory BP Monitoring":
  if "Patient has Set of BP Observations" then
    (
      Common."Systolic BP Variability"("All BP").value > 11
      and not exists "Ambulatory Blood Pressure Monitoring Procedures"
    )
  else null

define "Prescribe Ambulatory BP Monitoring":
  if "In Population" is not true then
    false
  else
    "Confirm need for Patient Ambulatory BP Monitoring"


/* Exclusion Criteria */
define "Patient Under Age 18":
  AgeInYearsAt(start of Common."Normalize Interval"("Most Recent BP".effective)) < 18

define "Patient Over Age 80":
  AgeInYearsAt(start of Common."Normalize Interval"("Most Recent BP".effective)) > 80

define "Condition Indicating End Stage Renal Disease":
  (Common.QualifiedCondition(["Condition": "End Stage Renal Disease"])) ESRD
    with "Most Recent BP" RecentBP
      such that Common."Prevalence Period"(ESRD) overlaps Common."Normalize Interval"(RecentBP.effective)

define "Condition Indicating Pregnancy":
  (Common.QualifiedCondition(["Condition": "Pregnancy"])) Pregnancy
    with "Most Recent BP" RecentBP
      such that Common."Prevalence Period"(Pregnancy) overlaps Common."Normalize Interval"(RecentBP.effective)


/* TESTS */
define "Test Patient Age on BP Reading":
  AgeInYearsAt(start of Common."Normalize Interval"("Most Recent BP".effective))

define "Test Count All BP":
  Count("All BP")

define "Test Most Recent BP":
  "Most Recent BP" BP
    return Tuple {
      "ID": BP.id,
      "Date": BP.effective.end,
      "Systolic": singleton from (BP.component C where C.code in "Systolic blood pressure").value.value,
      "Diastolic": singleton from (BP.component C where C.code in "Diastolic Blood Pressure").value.value
    }

define "Test Get All BP Observation Resources":
  ("Blood Pressure Observations" BP sort by Coalesce(issued, start of Common."Normalize Interval"(effective))) BP
    return Tuple {
      "Observation ID": BP.id
      }

define "Test Get Encounter BP Observations":
  from
    "Blood Pressure Observations" BPObservation,
      "Patient Ambulatory Encounters" BPEncounter
        where BPEncounter.class ~ "ambulatory"
          and Common."Normalize Interval"(BPObservation.effective) during BPEncounter.period
      return Tuple {
        "Observation ID": BPObservation.id,
        "Encounter ID": BPEncounter.id
        }

define "Test Get Most Recent BP Set":
  "Most Recent BP Set" BPSet
    return Tuple {
      "Observation ID": BPSet.id,
      "Encounter Reference": BPSet.encounter.reference
      }

define "Test All BP Last 2 Years":
  "Blood Pressure Observations for Last 2 Years" BPs
    return Tuple {
      "Observation ID": BPs.id,
      "Date": BPs.effective.end,
      "Encounter Reference": BPs.encounter.reference
      }

define "Test Get Average All BP Last 2 Years":
  Common."Avg BP"("All BP")

define "Test Get Average Most Recent BP Set":
  Common."Avg BP"("Most Recent BP Set")

define "Test Get BP Goal":
  "BP from Most Recent Goal" BPGoal
    return Tuple { systolic: BPGoal.systolic.value,  diastolic: BPGoal.diastolic.value }

define "Test Get All BP SBP Coefficient Variability":
  Common."Systolic BP Variability"("All BP").value
