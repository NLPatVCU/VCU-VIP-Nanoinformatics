import os
import re
import pickle
import pprint
import nltk
import functools
import numpy
import string
import json

pp = pprint.PrettyPrinter()

topdir = 'Validation' # Starting Directory

for dirpath, dirnames, files in os.walk(topdir):
    for name in files:
        if name.lower().endswith('.ann'):
            file_name = os.path.join(dirpath, name)
            with open(file_name) as file:
                content = file.read()
            with open(file_name + ".pkl",'wb') as file:
                sentences = content.split("\n")
                sentences = [s.split("\t") for s in sentences if s]
                sentences = [s for s in sentences if "R" not in s[0]]  # Remove all the relations
                #sentences = [[w for w in s if re.match("\((\S+)\s\s\S+\)", w)] for s in sentences]
                #sentences = [[stripWord(w).split("  ") for w in s] for s in sentences]
                #sentences = [[(w[0], w[1]) for w in s if w[0].isalnum()] for s in sentences]
                #sentences_tags_removed = [[w[0] for w in s] for s in sentences]
                print(sentences)
                pickle.dump(sentences, file)

