import os
from pandas import DataFrame
from nltk.stem.porter import PorterStemmer
from nltk.corpus import stopwords
from nltk.tokenize import sent_tokenize, word_tokenize
import numpy as np
import re

''' Methods used to clean and prepare text for classification '''


porter = PorterStemmer()


def detokenize(text_array):
    return ' '.join(np.hstack(text_array).flatten())


def read_files(path):
    for root, dir_names, file_names in os.walk(path):
        for path in dir_names:
            read_files(os.path.join(root, path))
        for file_name in file_names:
            file_path = os.path.join(root, file_name)
            if os.path.isfile(file_path):
                content = ''
                with open(file_path) as f:
                    for line in f:
                        line = line.rstrip('\n')
                        content += line
                yield file_path, content


def build_data_frame(path, classification):
    rows = []
    index = []
    for file_name, text in read_files(path):
        rows.append({'text': text, 'class': classification})
        index.append(file_name)

    data_frame = DataFrame(rows, index=index)
    return data_frame


def remove_stop_words(text):
    tokenized_docs_no_stopwords = []
    for doc in text:
        new_term_vector = []
        for word in doc:
            if not word in stopwords.words('english'):
                new_term_vector.append(word)
        tokenized_docs_no_stopwords.append(new_term_vector)

    return tokenized_docs_no_stopwords


def lemmatize(text):
    preprocessed_docs = []

    for doc in text:
        final_doc = []
        for word in doc:
            final_doc.append(porter.stem(word))
        preprocessed_docs.append(final_doc)

    return preprocessed_docs


def clean_text(text):
    text = re.sub(' +', ' ', text.strip())
    sentences = sent_tokenize(text)
    text = [word_tokenize(doc) for doc in sentences]
    text = remove_stop_words(text)
    text = lemmatize(text)
    return text
