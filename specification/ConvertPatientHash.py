# Given a salt, summarize the expected hashes for all the test patients
import os
import re
import hashlib

# Sandbox salt
salt = 'aY+Mlmv6WDrsDp&fnvO1wYgu&c*hCxSk'
patient = 'e3EcYt8iKNhwevqUm.OdYznV5kKRVRXhek749uw132uA3'
encoded = (patient + salt).encode('UTF-8')
print(patient + "," + hashlib.sha256(encoded).hexdigest())
