import subprocess
import json

""" Wrapper for WSD.pl Perl Program """


def wsd(jsoninput):

    perl_interpreter_loc = "/usr/bin/perl"  # Location of the perl interpreter on your system
    perl_script_loc = "WSD/wsd.pl"          # Location of the perl program you wish to run
    vectors = "WSD/newvectors.bin"          # Location of the vector file
    input = jsoninput                       # JSON input
    cuis = "WSD/edef.snomedct"              # List of CUIS
    stop = "WSD/stoplist"                   # Stop list

    pl_script = subprocess.Popen([perl_interpreter_loc,
                                  perl_script_loc,
                                  "--vectors", vectors,
                                  "--jsonstr", input,
                                  "--cuis", cuis,
                                  "--stop", stop],
                                 stdout=subprocess.PIPE)

    out, errs = pl_script.communicate()
    out_decoded = json.loads(out.decode("utf-8"))
    return out_decoded
