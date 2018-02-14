import numpy as np
import pandas as pd
import re
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from keras.models import Sequential
from keras.layers import Dense, Embedding, LSTM
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix

def main():
    """ Preprocessing Steps """

    PMC_NONNANO_abstracts = pd.read_json("../Data/JSON/Non-Nano.json")
    PMC_NONNANO_abstracts = PMC_NONNANO_abstracts.sample(500)
    PMC_NONNANO_abstracts['is_nano'] = "No"
    PMC_abstracts = pd.read_json("../Data/JSON/Nano.json")
    PMC_abstracts['is_nano'] = 'Yes'
    DOI_abstracts = pd.read_json("../Data/JSON/DOIData.json")
    DOI_abstracts['is_nano'] = 'Yes'
    DOI_abstracts['abstract'] = DOI_abstracts['abstract'].apply(lambda x: re.sub("\n", "", x))  # Remove new lines
    abstracts = pd.concat([PMC_abstracts, DOI_abstracts, PMC_NONNANO_abstracts], ignore_index=True)  # Combine data
    abstracts = abstracts[abstracts.abstract != "No Abstract Provided"]  # Remove papers with no abstract
    abstracts = abstracts[abstracts.abstract.str.strip() != ""]  # Remove papers with empty abstracts
    abstracts = abstracts.reindex(np.random.permutation(abstracts.index))

    with pd.option_context('expand_frame_repr', False):
        print(abstracts)

    print("Number of Nanofiles:", abstracts[abstracts['is_nano'] == "Yes"].shape[0])
    print("Number of Non-Nanofiles:", abstracts[abstracts['is_nano'] == "No"].shape[0])


    """ Model Training """

    max_features = 2000
    tokenizer = Tokenizer(num_words=max_features, split=' ')
    tokenizer.fit_on_texts(abstracts['abstract'].values)
    X = tokenizer.texts_to_sequences(abstracts['abstract'].values)
    X = pad_sequences(X)

    embed_dim = 128
    lstm_out = 196

    model = Sequential()
    model.add(Embedding(max_features, embed_dim, input_length=X.shape[1]))
    model.add(LSTM(lstm_out, dropout=0.2, recurrent_dropout=0.2))
    model.add(Dense(2, activation='softmax'))
    model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])
    print(model.summary())

    y = pd.get_dummies(abstracts['is_nano']).values

    X_train, X_test, Y_train, Y_test = train_test_split(X, y, test_size=0.4, random_state=42)
    print(X_train.shape,Y_train.shape)
    print(X_test.shape,Y_test.shape)

    model.fit(X_train, Y_train, epochs=10, batch_size=32, verbose=2)

    y_pred = model.predict(X_test, verbose=0, batch_size=32)
    y_pred = np.around(y_pred).astype('int')
    y_pred = [np.argmax(x) for x in y_pred]
    Y_test = [np.argmax(x) for x in Y_test]

    print("Y pred:", y_pred)
    print("Y True", Y_test)

    acc = accuracy_score(y_pred=y_pred, y_true=Y_test)
    precision = precision_score(y_pred=y_pred, y_true=Y_test, average='micro')
    recall = recall_score(y_pred=y_pred, y_true=Y_test)
    f1 = f1_score(y_pred=y_pred, y_true=Y_test)
    confmat = confusion_matrix(y_pred=y_pred, y_true=Y_test)



    print("Accuracy:", acc)
    print("Precision:", precision)
    print("Recall:", recall)
    print("F1 score:", f1)
    print("Confusion Matrix")
    print(confmat)


if __name__ == "__main__":
    main()
