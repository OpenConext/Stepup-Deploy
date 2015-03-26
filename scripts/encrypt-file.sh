#!/usr/bin/env python
import os.path
import sys
from optparse import OptionParser
from keyczar import keyczar

parser = OptionParser(usage="usage: %prog [options] <keyczar keystore directory>")
parser.add_option("-f", "--file", help="the input file", dest="filename", metavar="FILE")
parser.add_option("-d", "--decrypt", action="store_true", help="decrypt the file", dest="decrypt")

(options, args) = parser.parse_args()

if len(args) != 1:
  parser.error("wrong number of arguments")

if not os.path.isdir(args[0]):
  print 'Error: keystore directory "%s" not found' % args[0]
  sys.exit(1)

if options.filename:
  with open(options.filename, 'r') as content_file:
    content = content_file.read()
    keydir = os.path.expanduser(args[0])
    crypter = keyczar.Crypter.Read(keydir)
    if options.decrypt:
      print crypter.Decrypt(content)
    else:
      encrypted_secret = crypter.Encrypt(content)
      print encrypted_secret
else:
  parser.print_help()

