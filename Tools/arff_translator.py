import re, sys, fileinput, glob
from os.path import join

'''
Quick script to modify arff files in the correct format for the converter.
Pass the directory with the arff files as as argument add it will modify all arff files in that directory.


'''

path = path = join(sys.argv[1],"*")
files = glob.glob(path)
for line in fileinput.input(files, inplace=1):
    line_1 = re.sub('}.*', '}', line.rstrip())  # Strip out all the junk
    line_2 = re.sub(r'(\d),\s([A-z]+)', r'\1 \2', line_1.rstrip())  # Remove the extra column
    line = line_2
    print(line)