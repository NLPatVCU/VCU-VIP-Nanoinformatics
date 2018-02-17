import subprocess
import json

def wsd(inputString):

    output = {}
    perl_interpreter_loc = "/usr/bin/perl"
    perl_script_loc = "wsd.pl"
    name = inputString

    pl_script = subprocess.Popen([perl_interpreter_loc, perl_script_loc, name], stdout=subprocess.PIPE)
    out, errs = pl_script.communicate()
    output['out'] = out.decode("utf-8")

    return output
