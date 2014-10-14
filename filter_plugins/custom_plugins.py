#
# Usage: {{ foo | vault }}
#
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

class FilterModule(object):

  def filters(self):
    return {
      'vault': vault
    }
