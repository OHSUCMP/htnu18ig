library Hypertension version '0.1'

using FHIR version '4.0.1'

include OHSUHTN_Common version '0.1' called Common

context Patient

define "Info":
  'info'

define "Warning":
  'warning'

define "Critical":
  'critical'

define "Adult at start of Measurement Period":
  "Common"."Adult at start of Measurement Period"

define "Normal BP":
  ("Common"."Normal BP") is not null

define "Elevated BP":
  ("Common"."Elevated BP") is not null

define "HTN Stage 1 BP":
  ("Common"."HTN Stage 1 BP") is not null

define "HTN Stage 2 BP":
  ("Common"."HTN Stage 2 BP") is not null

define "HTN Crisis BP":
  ("Common"."HTN Crisis BP") is not null

define "MeetsInclusionCriteria":
  "Adult at start of Measurement Period"

define "Normal":
  if "InPopulation" is not true then
    null
  else
  "Normal BP"

define "Elevated":
  if "InPopulation" is not true then
    null
  else
  "Elevated BP"

define "HTN Stage 1":
  if "InPopulation" is not true then
    null
  else
  "HTN Stage 1 BP"

define "HTN Stage 2":
  if "InPopulation" is not true then
    null
  else
  "HTN Stage 2 BP"

define "HTN Crisis":
  if "InPopulation" is not true then
    null
  else
  "HTN Crisis BP"

define "InPopulation":
   "MeetsInclusionCriteria"

define "Recommendation":
  if "HTN Crisis" then 'Patient is in Hypertension Crisis.  Get this person to a hospital RIGHT NOW, like, not even kidding.  Call them an ambulance.'
  else if "HTN Stage 2" then 'Patient has Stage 2 Hypertension.  Add or increase medication dosage, improve on exercise and diet initiatives.  Patient actually has to stop smoking and drinking now, for real.  I know they said they were going to stop last time around, but this time they really need to do it.'
  else if "HTN Stage 1" then 'Patient has Stage 1 Hypertension and needs to get on some meds.  Increase exercise and improve diet.  Stop smoking and drinking so much.'
  else if "Elevated" then 'Patient has Elevated blood pressure.  Consider behavioral modifications and continue monitoring BP.'
  else if "Normal" then 'Patient has Normal blood pressure.  Monitor BP for future elevation.'
  else null

define "Rationale":
  if "HTN Crisis" then 'This person could die at any moment.  Keeling over with a heart attack is best handled in a hospital setting, so best they get to one ASAP.'
  else if "HTN Stage 2" then 'Whatever we\'ve been doing to get this under control isn\'t working.  Time to add more and get more serious about addressing this.'
  else if "HTN Stage 1" then 'Now that the patient has legit Hypertension, we need to get it under control one way or another.  Meds will do that, but exercise and diet are also important.  Smoking and drinking also affect this so that should stop also.'
  else if "Elevated" then 'Merely elevated BP isn\'t anything to get too concerned about, but we don\'t want it getting any higher.'
  else if "Normal" then 'No treatment is needed for those with normal BP.'
  else null

define "Errors":
  null
