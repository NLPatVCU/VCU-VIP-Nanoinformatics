import re, sys, fileinput, glob
from os.path import join

'''
Quick script to get the arff files in the correct format for the coverter just pass the directory with the arff files
as as argument
'''


path = path = join(sys.argv[1],"*")
files = glob.glob(path)
for line in fileinput.input(files, inplace=1):
    line_1 = re.sub('}.*', '}', line.rstrip())  # Strip out all the junk
    line_2 = re.sub(r'(\d),\s([A-z]+)', r'\1 \2', line_1.rstrip())  # Remove the extra column
    line = line_2
    print(line)