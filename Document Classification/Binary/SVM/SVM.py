import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.svm import SVC
from sklearn.pipeline import Pipeline
from sklearn.model_selection import cross_validate
import pandas as pd
from sklearn.metrics import f1_score, precision_score, recall_score, make_scorer
import Tools

def shuffle(documents):
    return documents.reindex(np.random.permutation(documents.index))


mapping_df = pd.read_csv('Data/mapping.csv')
documents_array = []
for index, row in mapping_df.iterrows():
    documents_array.append(build_data_frame(row["Directory"], row['Label']))
documents = pd.concat(documents_array)
documents = shuffle(documents)
documents['text'] = documents['text'].map(lambda x: clean_text(x))

NUMBER_OF_FOLDS = 10
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
scores = cross_validate(pipeline, X, y, cv=NUMBER_OF_FOLDS,scoring=scoreers, n_jobs=-1,)

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
