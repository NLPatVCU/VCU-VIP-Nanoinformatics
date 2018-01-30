import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.svm import SVC
from sklearn.pipeline import Pipeline
from sklearn.model_selection import cross_validate
from Tools.TextTools import build_data_frame, clean_text
import pandas as pd
from sklearn.metrics import f1_score, precision_score, recall_score, make_scorer


def shuffle(documents):
    return documents.reindex(np.random.permutation(documents.index))


mapping_df = pd.read_csv('Data/mapping.csv')
documents_array = []
for index, row in mapping_df.iterrows():
    documents_array.append(build_data_frame(row["Directory"], row['Label']))
documents = pd.concat(documents_array)
documents = shuffle(documents)
documents['text'] = documents['text'].map(lambda x: clean_text(x))

X = documents.iloc[:, 1].values
y = documents.iloc[:, 0].values

pipeline = Pipeline([
    ('vectorizer', CountVectorizer(ngram_range=(1, 2))),
    ('classifier', SVC(kernel='rbf'))
])

scoreers = {
        "f1_scores": make_scorer(f1_score, average='weighted'),
        "precision_scores": make_scorer(precision_score, average='weighted'),
        "recall_scores": make_scorer(recall_score, average='weighted'),
    }
scores = cross_validate(pipeline, X, y, cv=10,scoring=scoreers, n_jobs=-1,)
print(scores)
