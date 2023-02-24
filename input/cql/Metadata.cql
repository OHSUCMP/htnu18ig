library Metadata version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include OHSUHTNCommon version '0.1' called Common

context Patient

define function "BP Set Summary"(list List<Tuple { id String, effective DateTime, systolic Decimal, diastolic Decimal, readingType String }>):
  list BP
    return '{"id": "' + BP.id + '", "effective": "' + ToString(BP.effective) + '", "systolic": ' + ToString(BP.systolic) + '", "diastolic": ' + ToString(BP.diastolic) + '", "readingType": "' + BP.readingType + '"}'

define "True":
  true

define "BP Set":
  '[' + Combine("BP Set Summary"(Common."Most Recent BP Set"), ',') + ']'

define "Average BP Set":
  '{"systolic":' + ToString(Common."Average Most Recent BP Set".systolic) + ', "diastolic":' + ToString(Common."Average Most Recent BP Set".diastolic) + '}'

define "All BPs":
  '[' + Combine("BP Set Summary"(Common."All BP Observations"), ',') + ']'

define "Average BP 2 Years":
  '{"systolic":' + ToString(Common."Average All BP Last 2 Years".systolic) + ', "diastolic":' + ToString(Common."Average All BP Last 2 Years".diastolic) + '}'

define "BP Goal Met":
  ToString(Common."BP Goal Met")

define "Indicator Status":
  'info'