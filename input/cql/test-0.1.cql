library test_FHIR3 version '0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.0' called FHIRHelpers

context Patient

define "Returns True Always":
  true

define "Empty List":
  { }

define "All True List of Booleans":
  { true, true, true }

define "Mixed List of Booleans":
  { true, false, true }

define "List of Integers":
  { 1, 2, 3, 4, 5 }

define "Another List of Integers":
  { 4, 5, 6, 7 }

define "List of List of Integers":
  { { 1, 2 }, { 3, 4, 5 }, { 6, 7 } }

define "List of Decimals":
  { 0.1, 2.3, 4.5, 6.7 }

define "List of Strings":
  { 'hello', 'there', 'world' }

define "List of Dates":
  { @1999-12-31, @2005-05-05, @2020-06-17 }
