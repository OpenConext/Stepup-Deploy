#
# Usage: {{ foo | vault }}
#        {{ foo | sha256 }}

def vault(encrypted):
  method = """
from keyczar import keyczar
import os.path
import sys

keydir = os.path.expanduser('~/.stepup-ansible-keystore')
crypter = keyczar.Crypter.Read(keydir)
sys.stdout.write(crypter.Decrypt("%s"))
  """ % encrypted
  from subprocess import check_output
  return check_output(["python", "-c", method])


def sha256s(data):
  import hashlib
  return hashlib.sha256(data).hexdigest()


class FilterModule(object):

  def filters(self):
    return {
      'vault': vault,

      'sha256': sha256s,
    }
