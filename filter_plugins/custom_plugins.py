# Copyright 2015 SURFnet B.V.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Custom filter plugins
#
# Usage: {{ foo | vault(path to keystore or empty string when using ansible-vault or not using encryption) }}
#        {{ foo | sha256 }}
#        {{ foo | depem }}
# vault: decrypt string using key stored in keyczar vault.
# sha256: return hex encoded SHA-256 hash of string
# depem: Strip PEM headers and remove all whitespace from string


# vault filter
# ------------
#
# When the keydir argument is set to an empty string, the "encrypted" value is returned and keyczar is
# not invoked. Use this when using ansible-vault or when not using encryption.
# This function is vompatible with both python2 and python3. When using keyczar the python keyzar module is required:
# - for python2 install python-keyczar
# - for python3 install python3-keyczar
def vault(encrypted, keydir):

  if not keydir:
    # The keydir variable is empty. Assume we are not using keyczar i.e.:
    # - We are using Ansible Vault, which would have already decrypted the string at this point, or
    # - Passwords are stored plaintext

    # The vault filter is a no-op in this case
    return encrypted

# Assume the string is encrypted using keyczar
  method = """
from keyczar import keyczar
import os.path
import sys

expanded_keydir = os.path.expanduser("%s")
crypter = keyczar.Crypter.Read(expanded_keydir)
sys.stdout.write(crypter.Decrypt("%s"))
  """ % (keydir, encrypted)
  from subprocess import check_output
  import sys
  return check_output([sys.executable, "-c", method], universal_newlines=True)


# sha256 filter
# -------------
#
# Calculate hex encoded sha256 checksum of "data"
#
# Compatible with python2 and python3
def sha256s(data):
  import hashlib
  return hashlib.sha256(data.encode('utf-8')).hexdigest()


# depem filter
# -------------
#
# Remove PEM headers and whitespace from a PEM encoded object like a X.509 certificate or private key
# leaving just the base64 encoded part without any whitespace
#
# This filter can be used to convert a PEM encoded X.509 certificate to the base64 representation used
# in SAML Metadata
#
# Compatible with python2 and python3
def depem(string):
  import re
  return re.sub(r'\s+|(-----(BEGIN|END).*-----)', '', string)


class FilterModule(object):

  def filters(self):
    return {
      'vault': vault,
      'sha256': sha256s,
      'depem': depem,
    }
