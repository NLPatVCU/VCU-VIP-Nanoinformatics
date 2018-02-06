import json
import os
import re

from nltk import wordpunct_tokenize
from nltk.corpus import words
from nltk.tokenize import sent_tokenize

words = set(words.words())  # List of all English Words
topdir = 'MultinomialNB' # Starting Directory

for dirpath, dirnames, files in os.walk(topdir):
    for name in files:
        if name.lower().endswith('.txt'):
            file_name = os.path.join(dirpath, name)
            with open(file_name, encoding='latin-1') as file:
                content = file.read()
            with open(file_name,'w') as file:
                data = {}
                sentences = sent_tokenize(content)
                sentences = [re.sub('\d', '', s) for s in sentences]  # Remove Numbers
                sentences = [''.join([x for x in s if ord(x) < 128]) for s in sentences]  # Remove non-ASCII characters
                sentences = [re.sub(r'[^\w\s]', '', s) for s in sentences]  # Remove punctuation
                sentences = [re.sub('\s+', ' ', s).strip() for s in sentences] # Remove the Uneeded Spacing
                sentences = [s.lower() for s in sentences] # Lowercase everything
                sentences = [" ".join(w for w in wordpunct_tokenize(s) if w in words) for s in sentences] # Remove garbage (May be naieve)
                sentences = [' '.join([w for w in s.split() if len(w) > 1]) for s in sentences] # Remove single characters
                sentences = list(filter(None, sentences))  # Remove sentences with nothing in them
                data['sentences'] = sentences
                json.dump(data, file, indent=4)
