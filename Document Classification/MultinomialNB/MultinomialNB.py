import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
import Tools.TextTools as TextTools
from sklearn import metrics
import sys

documents_map = []
documents_mapping_df = pd.read_csv(sys.argv[1])

for index, row in documents_mapping_df.iterrows():
    documents_map.append(TextTools.build_data_frame(row["Label"], row['Directory']))

documets = pd.concat(documents_map)
documets['text'] = documets['text'].map(lambda x: TextTools.clean_text(x)).map(lambda x: TextTools.detokenize(x))
documets = documets.reindex(np.random.permutation(documets.index))

X = documets.iloc[:, 1].values
y = documets.iloc[:, 0].values

# Splitting the dataset into the Training set and Test set
from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = .2, random_state = 0)

count_vectorizer = CountVectorizer()
counts = count_vectorizer.fit_transform(X_train)
classifier = MultinomialNB()
targets = y_train
classifier.fit(counts, targets)

preds = classifier.predict(count_vectorizer.transform(X_test))

print(metrics.classification_report(y_test, preds))

