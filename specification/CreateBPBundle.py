# This script can be used to create a Bundle file that can create a bunch of random BP observations for a patient in Logica
# It alternates between home and office readings and uses a Guassian distribution around BPs of 120/80.
import os
import re
import random
import time

# Modify the count, the patient id, the start and end dates to vary between, and a file to write to.
n = 11
patient = 1203
start_date = "2023-01-24T00:00:00"
end_date = "2023-02-22T00:00:00"
filename = "/Users/yateam/temp.json"

bundle_start = """
{
  "resourceType": "Bundle",
  "id": "tests-AE-Excluded-bundle",
  "type": "transaction",
  "entry": [
"""

bundle_request = """
    "request": {
      "method": "POST",
      "url": "Observation"
    }
  },
"""

bundle_end = """]
}
"""

home = """
{ "resource": {
  "resourceType": "Observation",
  "status": "final",
  "note": [
    {
      "text": "Home Blood Pressure Reading"
    }
  ],
  "extension": [
    {
      "url": "http://hl7.org/fhir/us/vitals/StructureDefinition/MeasurementSettingExt",
      "valueCoding": {
        "system": "http://snomed.info/sct",
        "code": "264362003"
      }
    }
  ],
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "vital-signs",
          "display": "vital-signs"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "55284-4",
        "display": "Blood Pressure"
      }
    ],
    "text": "Blood Pressure"
  },
  "subject": {
    "reference": "Patient/<patient>"
  },
  "effectiveDateTime": "<date>-05:00",
  "component": [
    {
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "8462-4",
            "display": "Diastolic Blood Pressure"
          }
        ],
        "text": "Diastolic Blood Pressure"
      },
      "valueQuantity": {
        "value": <dia>,
        "unit": "mm[Hg]",
        "system": "http://unitsofmeasure.org",
        "code": "mm[Hg]"
      }
    },
    {
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "8480-6",
            "display": "Systolic Blood Pressure"
          }
        ],
        "text": "Systolic Blood Pressure"
      },
      "valueQuantity": {
        "value": <sys>,
        "unit": "mm[Hg]",
        "system": "http://unitsofmeasure.org",
        "code": "mm[Hg]"
      }
    }
  ]
}"""

office = """
{ "resource": {
  "resourceType": "Observation",
  "status": "final",
  "note": [
    {
      "text": "Office Blood Pressure Reading"
    }
  ],
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "vital-signs",
          "display": "vital-signs"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "55284-4",
        "display": "Blood Pressure"
      }
    ],
    "text": "Blood Pressure"
  },
  "subject": {
    "reference": "Patient/<patient>"
  },
  "effectiveDateTime": "<date>-05:00",
  "component": [
    {
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "8462-4",
            "display": "Diastolic Blood Pressure"
          }
        ],
        "text": "Diastolic Blood Pressure"
      },
      "valueQuantity": {
        "value": <dia>,
        "unit": "mm[Hg]",
        "system": "http://unitsofmeasure.org",
        "code": "mm[Hg]"
      }
    },
    {
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "8480-6",
            "display": "Systolic Blood Pressure"
          }
        ],
        "text": "Systolic Blood Pressure"
      },
      "valueQuantity": {
        "value": <sys>,
        "unit": "mm[Hg]",
        "system": "http://unitsofmeasure.org",
        "code": "mm[Hg]"
      }
    }
  ]
}"""

def str_time_prop(start, end, time_format, prop):
    """Get a time at a proportion of a range of two formatted times.

    start and end should be strings specifying times formatted in the
    given format (strftime-style), giving an interval [start, end].
    prop specifies how a proportion of the interval to be taken after
    start.  The returned time will be in the specified format.
    """

    stime = time.mktime(time.strptime(start, time_format))
    etime = time.mktime(time.strptime(end, time_format))

    ptime = stime + prop * (etime - stime)

    return time.strftime(time_format, time.localtime(ptime))


def random_date(start, end, prop):
    return str_time_prop(start, end, '%Y-%m-%dT%H:%M:%S', prop)

i = 1
bps = bundle_start
while i <= n:
  sys = random.gauss(120, 15)
  dia = random.gauss(80, 15)
  date = random_date(start_date, end_date, random.random())
  # readingType = random.randint(0,1)
  readingType = 0
  if readingType == 0:
    reading = home
  else:
    reading = office
  reading = reading.replace('<sys>', str(sys))
  reading = reading.replace('<dia>', str(dia))
  reading = reading.replace('<date>', str(date))
  reading = reading.replace('<patient>', str(patient))
  bps = bps + reading + "," + bundle_request
  i += 1

def rreplace(s, old, new, occurrence):
  li = s.rsplit(old, occurrence)
  return new.join(li)

bps = rreplace(bps, ",", bundle_end, 1)
with open(filename, 'w') as nf:
  nf.write(bps)
