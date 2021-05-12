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


/* Recommendation Criteria - Monitoring Hypertension  */
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
  else if not "Patient has a BP Goal" then 'Discuss target blood pressure and set a blood pressure goal'
  else if not "Has BP Set" then 'Consider obtaining additional blood pressure measurements'
  else if ("HTN Stage 2" or "Not At Goal") then 'Blood pressure goal not reached. Discuss treatment options'
  else if "Prescribe HBP or ABP Monitoring" then 'Use home or ambulatory blood pressure monitoring to confirm blood pressure'
  else if "Prescribe Ambulatory BP Monitoring" then 'Use ambulatory blood pressure monitoring to address blood pressure variability'
  else 'Patient at goal!'

define "Rationale":
  if exists "Condition Indicating Pregnancy" then '{{#patient}}Please see your Ob-Gyn provider for specialized care regarding your high blood pressure reading while pregnant{{/patient}}{{#careTeam}}{{/careTeam}}'
  else if exists "Condition Indicating End Stage Renal Disease" then '{{#patient}}Please see your nephrologist for specialized care regarding your recent high blood pressure reading.{{/patient}}{{#careTeam}}{{/careTeam}}'
  else if not "Patient has a BP Goal" then '{{#patient}}You recently received a hypertension (high blood pressure) diagnosis.  Setting goals for lowering your blood pressure has been proven to help overall health and reduce your chance of stroke or other conditions.{{/patient}}{{#careTeam}}No BP Goal set: Setting a blood pressure goal can help engage patients and improve outcomes. For most patients, choosing a target between <120-140/80-90 is recommended; lower targets may be for ASCVD, ASCVD risk >10%, multimorbidity (CKD and diabetes), or preference; higher targets may be for age, adverse events, or frailty.{{/careTeam}}'
  else if not "Has BP Set" then '{{#patient}}Your recent blood pressure is above your goal.  We do not have enough blood pressures to provide a full picture of your blood pressure. Taking a full set of blood pressures can help.  We consider a full set to be ~4 in-office measurements, ~6 home measurements, or 12 hours of ambulatory monitoring.{{/patient}}{{#careTeam}}Patient does not have enough blood pressures to make a strong determination of control or diagnosis.  We consider a full set to be more than 4 in-office measurements, 6 home measurements, or 24 hours of ambulatory monitoring.{{/careTeam}}'
  else if ("HTN Stage 2" or "Not At Goal") then '{{#patient}}Your recent blood pressure is above your goal. Changing your behaviors may help - see the additional options. In addition, please consult your care team to consider additional treatment options. Please review the home blood pressure measurement protocol presented on the blood pressure entry page to make sure that the tool is accurately measuring your blood pressure.{{/patient}}{{#careTeam}}BP not at goal. Consider initiating antihypertensive drug therapy with a single antihypertinsive drug with dosage titration and sequential addition of other agents to achieve the target BP.{{/careTeam}}'
  else if "Prescribe HBP or ABP Monitoring" then '{{#patient}}Your recent blood pressure is above your goal and is borderline for a hypertension diagnosis.  More measurements over a longer period could help.  We consider a full set to be ~4 in-office measurements, ~6 home measurements, or ~24 hours of ambulatory monitoring.{{/patient}}{{#careTeam}}Patient does not have enough blood pressures to make a strong determination of control or diagnosis.  We consider a full set to be more than 4 in-office measurements, 6 home measurements, or 24 hours of ambulatory monitoring.{{/careTeam}}'
  else if "Prescribe Ambulatory BP Monitoring" then '{{#patient}}Your recent blood pressure is above your goal and appears to be highly variable, which can indicate a health risk.  Ask your care team about ordering ambulatory blood pressure monitoring or how to get better measurements from home blood pressure monitoring.{{/patient}}{{#careTeam}}In adults with suspected blood pressure variability, use Ambulatory Blood Pressure Monitoring to better understand risk. If ABPM is not available, discuss more better protocols for home blood pressure monitoring.{{/careTeam}}'
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

define "Source":
  if exists "Condition Indicating Pregnancy" then 'https://www.ahajournals.org/doi/10.1161/HYPERTENSIONAHA.120.15015'
  else if exists "Condition Indicating End Stage Renal Disease" then 'https://www.ahajournals.org/doi/10.1161/HYPERTENSIONAHA.120.15017'
  else if not "Patient has a BP Goal" then 'https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065'
  else if not "Has BP Set" then 'https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065'
  else if ("HTN Stage 2" or "Not At Goal") then 'https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065'
  else if "Prescribe HBP or ABP Monitoring" then 'https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065'
  else if "Prescribe Ambulatory BP Monitoring" then 'https://www.ahajournals.org/doi/10.1161/HYP.0000000000000065'
  else ''

define "Suggestions":
  if exists "Condition Indicating Pregnancy" then ''
  else if exists "Condition Indicating End Stage Renal Disease" then ''
  else if not "Patient has a BP Goal" then '[ { "label": "BPGoal", "actions": [ "{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'BPGoalhigh\'>BP target < 140/90</input>{{/patient}}","{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'BPGoalmedium\'>BP target < 130/80</input>{{/patient}}","{{#patient}}<input type=\'checkbox\' class=\'goal\' data-id=\'BPGoallow\'>BP target < 120/80</input>{{/patient}}" ] } ]'
  else if not "Has BP Set" then '[ { "label": "Enter Blood Pressure", "actions": [ "ServiceRequest for High Blood Pressure Monitoring", "{{#patient}}<a href=\'/bp-readings\'>Click here to go to the Home Blood Pressure entry page</a>{{/patient}}" ] } ]'
  else if ("HTN Stage 2" or "Not At Goal") then '[ { "label": "Contact care team BP treatment", "actions": ["{{#patient}}<a data-id=\'CommunicationTreatment\' data-recipient=\'CareTeam\' data-sender=\'Patient\' href=\'/contact\'> Contact your care team about options to control your high blood pressure</a> {{/patient}}"] } ]'
  else if "Prescribe HBP or ABP Monitoring" then '[ { "label": "Enter Blood Pressure", "actions": [ "ServiceRequest for High Blood Pressure Monitoring", "{{#patient}}<a href=\'/bp-readings\'>Click here to go to the Home Blood Pressure entry page</a>{{/patient}}" ] } ]'
  else if "Prescribe Ambulatory BP Monitoring" then '[ { "label": "Request Ambulatory Blood Pressure", "actions": [ "ServiceRequest for Ambulatory Blood Pressure Monitoring", "{{#patient}}<a href=\'/ambulatoryBP\'>Click here to request Ambulatory Blood Pressure</a>{{/patient}}" ] } ]'
  else ''

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

define "No Entry into Population":
  not "Meets Inclusion Criteria"
    and not "Meets Exclusion Criteria"

define "No Entry Title":
  if not "Patient Has Above Normal BP" then
   'Patient did not have above normal blood pressure.'
  else 'Patient did not have a preexisting hypertensive condition.'

define "No Entry Description":
  'No Further Action Required.'


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
  (Common.WithUnit(Common.QualifiedObservation(["Observation": "Blood Pressure Measured"]), 'mm[Hg]')) O
    sort by Coalesce(start of Common."Normalize Interval"(effective), issued)

define "Most Recent BP":
  Last("Blood Pressure Observations" O sort by Coalesce(start of Common."Normalize Interval"(effective), issued))

define "Blood Pressure Observations for Last 2 Years":
  ((
    "Blood Pressure Observations" BP
      with "Most Recent BP" MostRecentBP
        such that Common."Normalize Interval"(BP.effective) starts 24 months or less before end of Common."Normalize Interval"(MostRecentBP.effective)
  )
  union { "Most Recent BP" }) O
    sort by Coalesce(start of Common."Normalize Interval"(effective), issued)


define "Ambulatory Blood Pressure Monitoring Procedures":
  (Common.QualifiedProcedure(["Procedure": "Ambulatory Blood Pressure Monitoring (ABPM)"])) ABPMProcedure
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
define "Qualifying Blood Pressure Goals":
  (Common.QualifiedGoal(["Goal"])) BPGoal
    where (
      singleton from (BPGoal.target Systolic
        where Systolic.measure in "Systolic blood pressure"
          and Systolic.detail is Quantity
          and Common.WithUnit(Systolic.detail, 'mm[Hg]'))
    ) SystolicTarget is not null
      and (
        singleton from (BPGoal.target Diastolic
          where Diastolic.measure in "Diastolic Blood Pressure"
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
