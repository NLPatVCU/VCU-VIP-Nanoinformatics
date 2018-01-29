import os
import pathlib
import pickle
import re

import nltk


def stripWord(word):
    return word.lstrip("(").rstrip(")")


def combine_POS_and_tag(ar1, ar2):
    ar = []
    for sentence_index, sentence in enumerate(ar1):
        sent = []
        for word_index, word in enumerate(sentence):
            sent.append(tuple((word[0], ar2[sentence_index][word_index][1], word[1])))
        ar.append(sent)
    return ar


topdir = 'ASC' # Starting Directory
pickeld_directory = topdir + "/pickled_data"


for dirpath, dirnames, files in os.walk(topdir):
    for name in files:
        if name.lower().endswith('.txt'):
            file_name = os.path.join(dirpath, name)
            with open(file_name, encoding='latin-1') as file:
                content = file.read()
            pathlib.Path(pickeld_directory).mkdir(parents=True, exist_ok=True)
            with open(os.path.join(pickeld_directory, name + ".pkl"), 'wb') as file:
                data = {}
                sentences = content.split("[")
                sentences = [s.strip() for s in sentences if s]  # Remove empty strings
                sentences = [s.split("\n") for s in sentences] # Split the strings by words
                sentences = [[w.strip() for w in s] for s in sentences]
                sentences = [[w for w in s if re.match("\((\S+)\s\s\S+\)", w)] for s in sentences]
                sentences = [[stripWord(w).split("  ") for w in s] for s in sentences]
                sentences = [[(w[0], w[1]) for w in s if w[0]] for s in sentences]
                sentences_tags_removed = [[w[0] for w in s] for s in sentences]
                sentences_pos_tagged = [nltk.pos_tag(s) for s in sentences_tags_removed]
                sentences = combine_POS_and_tag(sentences, sentences_pos_tagged)
                sentences = [[('NUM', w[1], w[2]) if w[0].isnumeric() else w for w in s] for s in sentences]
                print(sentences)
                pickle.dump(sentences, file)

