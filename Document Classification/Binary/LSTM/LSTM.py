import numpy as np
from pandas import read_json, concat, get_dummies
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from keras.models import Sequential
from keras.layers import Dense, Embedding, LSTM
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix


def main():

    abstracts = read_json("../Data/Datasets/abstracts.json")
    abstracts = preprocess(abstracts)
    y = get_dummies(abstracts['is_nano']).values
    max_features = 2000
    tokenizer = Tokenizer(num_words=max_features, split=' ')
    tokenizer.fit_on_texts(abstracts['abstract'].values)
    X = tokenizer.texts_to_sequences(abstracts['abstract'].values)
    X = pad_sequences(X)
    X_train, X_test, Y_train, Y_test = train_test_split(X, y, test_size=0.4, random_state=42)

    """  Model Creation """

    embed_dim = 128
    lstm_out = 196

    model = Sequential()
    model.add(Embedding(max_features, embed_dim, input_length=X.shape[1]))
    model.add(LSTM(lstm_out, dropout=0.2, recurrent_dropout=0.2))
    model.add(Dense(2, activation='softmax'))
    model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

    """  Model Training  """

    model.fit(X_train, Y_train, epochs=10, batch_size=32, verbose=2)

    """  Model Testing  """

    y_pred = model.predict(X_test, verbose=0, batch_size=32)
    y_pred = np.around(y_pred).astype('int')   # Round the output of the softmax layer
    y_pred = [np.argmax(x) for x in y_pred]    # Place back into distict predictions
    Y_test = [np.argmax(x) for x in Y_test]    # Place back into distict predictions

    metrics = get_metrics(y_pred, Y_test)
    print(metrics)


def get_metrics(y_pred, y_true):

    metrics = {}
    metrics['accuracy'] = accuracy_score(y_pred, y_true)
    metrics['precsion'] = precision_score(y_pred, y_true)
    metrics['recall'] = recall_score(y_pred, y_true)
    metrics['f1'] = f1_score(y_pred, y_true)
    metrics['confusionmatrix'] = confusion_matrix(y_pred, y_true)
    return metrics


def preprocess(abstracts):

    nano_abstracts = abstracts[abstracts['is_nano'] == "Yes"]
    non_nano_abstracts = abstracts[abstracts['is_nano'] == "No"]
    samp_non_nano_abstracts = non_nano_abstracts.sample(500)
    return concat([nano_abstracts, samp_non_nano_abstracts])


if __name__ == "__main__":
    main()