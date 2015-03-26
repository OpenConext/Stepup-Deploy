#!/usr/bin/env python
import os.path
import getpass
import sys
from optparse import OptionParser
from keyczar import keyczar

parser = OptionParser(usage="usage: %prog [options] <keyczar keystore directory>")
parser.add_option("-d", "--decrypt", action="store_true", help="decrypt the input", dest="decrypt")

(options, args) = parser.parse_args()

if len(args) != 1:
  parser.error("wrong number of arguments")

if not os.path.isdir(args[0]):
  print 'Error: keystore directory "%s" not found' % args[0]
  sys.exit(1)

keydir = os.path.expanduser(args[0])
crypter = keyczar.Crypter.Read(keydir)

if options.decrypt:
  encrypted_input = raw_input("Type the encrypted string: ")
  print 'The decrypted secret: %s' % crypter.Decrypt(encrypted_input)
else:
  password = getpass.getpass('Type the secret you want to encrypt: ')
  encrypted_secret = crypter.Encrypt(password)
  print 'The encrypted secret: %s' % encrypted_secret
