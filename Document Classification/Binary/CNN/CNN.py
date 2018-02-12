import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)

from sklearn.feature_extraction.text import CountVectorizer
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from keras.models import Sequential
from keras.layers import Dense, Embedding, LSTM
from sklearn.model_selection import train_test_split
from keras.utils.np_utils import to_categorical
import re

abstracts = pd.read_json("../Data/DOIData.json")
abstracts['is_nano'] = 1
abstracts = abstracts.reindex(np.random.permutation(abstracts.index))
with pd.option_context('expand_frame_repr', False):
    print(abstracts)


print("Number of Nanofiles:", abstracts[abstracts['is_nano'] == 1].shape[0])
print("Number of Non-Nanofiles:", abstracts[abstracts['is_nano'] == 0].shape[0])


max_fatures = 2000
tokenizer = Tokenizer(num_words=max_fatures, split=' ')
tokenizer.fit_on_texts(abstracts['abstract'].values)
X = tokenizer.texts_to_sequences(abstracts['abstract'].values)
X = pad_sequences(X)

embed_dim = 128
lstm_out = 196

model = Sequential()
model.add(Embedding(max_fatures, embed_dim,input_length = X.shape[1]))
model.add(LSTM(lstm_out, dropout=0.2, recurrent_dropout=0.2))
model.add(Dense(2,activation='softmax'))
model.compile(loss = 'categorical_crossentropy', optimizer='adam',metrics = ['accuracy'])
print(model.summary())

y = abstracts["is_nano"].values

X_train, X_test, Y_train, Y_test = train_test_split(X,y, test_size = 0.33, random_state = 42)
print(X_train.shape,Y_train.shape)
print(X_test.shape,Y_test.shape)


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