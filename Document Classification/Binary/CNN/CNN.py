import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.model_selection import cross_validate
import pandas as pd
from sklearn.metrics import f1_score, precision_score, recall_score, make_scorer
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences


""" Data Gathering """
RSCabstracts = pd.read_json("../Data/JSON/RSC.json")
RSCabstracts['is_nano'] = True
ACSabstracts = pd.read_json("../Data/JSON/ACS.json")
ACSabstracts['is_nano'] = True
abstracts = pd.concat([RSCabstracts, ACSabstracts], ignore_index=True)  # Concatenate to Datasets together
abstracts = abstracts.reindex(np.random.permutation(abstracts.index))  # Intermix the multiple Datasets
with pd.option_context('expand_frame_repr', False):
    print(abstracts)

texts = abstracts.iloc[:, 0].values

""" Preprocessing """
tokenizer = Tokenizer()
tokenizer.fit_on_texts(texts)
sequences = tokenizer.texts_to_sequences(texts)
word_index = tokenizer.word_index
print('Found %s unique tokens.' % len(word_index))

data = pad_sequences(sequences)

print(data)
"""

NUMBER_OF_FOLDS = 10
X = documents.iloc[:, 1].values
y = documents.iloc[:, 0].values

pipeline = Pipeline([
    ('vectorizer', CountVectorizer(ngram_range=(1, 2))),
    ('classifier', MultinomialNB())
])

scoreers = {
        "f1_scores": make_scorer(f1_score, average='weighted'),
        "precision_scores": make_scorer(precision_score, average='weighted'),
        "recall_scores": make_scorer(recall_score, average='weighted'),
    }
scores = cross_validate(pipeline, X, y, cv=NUMBER_OF_FOLDS,scoring=scoreers, n_jobs=-1, return_train_score=False)

f1_scores = scores['test_f1_scores']
precision_scores = scores['test_precision_scores']
recall_scores = scores['test_recall_scores']

for x in range(NUMBER_OF_FOLDS):
    print("Fold number: ", x)
    print("Precision: ", precision_scores[x])
    print("Recall: ", recall_scores[x])
    print("F1 Score: ", f1_scores[x])
    print("\n")

print("Averages Across Folds")
print("Precision: ", np.mean(np.array(precision_scores)))
print("Recall: ", np.mean(np.array(recall_scores)))
print("F1 Score: ", np.mean(np.array(f1_scores)))
"""