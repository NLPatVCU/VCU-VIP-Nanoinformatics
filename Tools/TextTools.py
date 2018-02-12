import json
import os
import re
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
from nltk.tokenize import word_tokenize
from pandas import DataFrame
import re
import pprint
import pickle
from pandas import DataFrame



def read_files(path):
    for root, dir_names, file_names in os.walk(path):
        for path in dir_names:
            read_files(os.path.join(root, path))
        for file_name in file_names:
            file_path = os.path.join(root, file_name)
            if os.path.isfile(file_path):
                content = ''
                with open(file_path, encoding='latin-1') as f:
                    for line in f:
                        content += line
                yield file_path, content


def clean_text(text):
    text = re.sub(' +', ' ',text)
    sentences = text.split(",")
    sentences = [word_tokenize(s) for s in sentences]
    sentences = remove_stop_words(sentences)
    sentences = collapse(sentences)
    return sentences


def build_data_frame(path, classification):
    rows = []
    index = []
    for file_name, text in read_files(path):
        rows.append({'text': clean_text(",".join(json.loads(text)['sentences'])), 'class': classification})
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


wordnet_lemmatizer = WordNetLemmatizer()


def lemmatize(text):
    preprocessed_docs = []

    for doc in text:
        final_doc = []
        for word in doc:
            final_doc.append(wordnet_lemmatizer.lemmatize(word))
        preprocessed_docs.append(final_doc)

    return preprocessed_docs


def collapse(sentences):
    return " ".join(map(lambda x: " ".join(x), sentences))


pp = pprint.PrettyPrinter(indent=4)

def loadNER(topdir):
    pickeled_data = {}
    for dirpath, dirnames, files in os.walk(topdir):
        for name in files:
            if name.lower().endswith('.pkl'):
                file_name = os.path.join(dirpath, name)
                with open(file_name, 'rb') as f:
                        data = pickle.load(f)
                        pickeled_data[file_name] = data
    df = DataFrame([pickeled_data]).transpose()
    df.columns = ['text']
    return df