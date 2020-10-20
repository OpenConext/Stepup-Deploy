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

# Usage: {{ foo | vault(path to keystore or path to Ansible vault password file) }}
#        {{ foo | sha256 }}
#        {{ foo | depem }}

# vault: decrypt string using key stored in keyczar vault.
# sha256: return hex encoded SHA-256 hash of string
# depem: Strip PEM headers and remove all whitespace from string

# Compatible with python2 and python3, but for python2 use python-keyczar and for python3 use python3-keyczar
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


# Compatible with python2 and python3
def sha256s(data):
  import hashlib
  return hashlib.sha256(data.encode('utf-8')).hexdigest()

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
