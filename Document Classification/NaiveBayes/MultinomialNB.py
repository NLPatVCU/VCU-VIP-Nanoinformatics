import numpy as np
from sklearn.metrics import confusion_matrix, classification_report, accuracy_score
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.model_selection import KFold
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import Tools.TextTools as TextTools
import pandas as pd


def shuffle(documents):
    return documents.reindex(np.random.permutation(documents.index))


# Load the Data
mapping_df = pd.read_csv('mapping.csv')
documents_array = []
for index, row in mapping_df.iterrows():
    documents_array.append(TextTools.build_data_frame(row["Directory"], row['Label']))
documents = pd.concat(documents_array)
documents = shuffle(documents)


# Clean the Data
documents['text'] = documents['text'].map(lambda x: TextTools.clean_text(x))

X = documents.iloc[:, 1].values
y = documents.iloc[:, 0].values

# Create Data Pipeline
pipeline = Pipeline([
    ('vectorizer', CountVectorizer(ngram_range=(1, 2))),
    ('classifier', MultinomialNB())
])

# Make Predictions
k_fold = KFold(n_splits=3)
confusion = np.zeros(shape=(4,4))
accuracy = 0
for train_index, test_index in k_fold.split(X):

    train_text, test_text = X[train_index],  X[test_index]
    train_y, test_y = y[train_index], y[test_index]

    pipeline.fit(train_text, train_y)
    predictions = pipeline.predict(test_text)

    y_actu = pd.Series(test_y, name='Actual')
    y_pred = pd.Series(predictions, name='Predicted')
    df_confusion = pd.crosstab(y_actu, y_pred)
    print(df_confusion)

    confusion += confusion_matrix(test_y, predictions)
    accuracy += accuracy_score(test_y, predictions)
    print(classification_report(test_y, predictions))
    print("Accuracy: ", accuracy_score(test_y, predictions))

print('Confusion matrix:')
print(confusion)
print("Accuracy: ", accuracy/3)
