import pandas as pd
import tensorflow as tf
import numpy as np
from sklearn.model_selection import train_test_split
import matplotlib as mpl
mpl.use('TkAgg')
import matplotlib.pyplot as plt
from pandas_ml import ConfusionMatrix
from scipy.io import arff
from pandas import DataFrame


def plot_confusion_matrix(df_confusion, title='Confusion matrix', cmap=plt.cm.gray_r):
    plt.matshow(df_confusion, cmap=cmap) # imshow
    plt.colorbar()
    tick_marks = np.arange(len(df_confusion.columns))
    plt.xticks(tick_marks, df_confusion.columns, rotation=45)
    plt.yticks(tick_marks, df_confusion.index)
    plt.ylabel(df_confusion.index.name)
    plt.xlabel(df_confusion.columns.name)


def main():
    feature_columns = [tf.feature_column.numeric_column("x", shape=[7])]  # List the features
    classifier = tf.estimator.DNNClassifier(  # Load Classifier
        feature_columns=feature_columns,
        hidden_units=[300, 100],
        model_dir='Neural_Net_Model'
    )

    data, meta = arff.loadarff("nanop.arff")
    df = DataFrame(data=data, columns=meta.names())
    df['Entity'] = df['Entity'].map({'Yes': 1, 'No': 0})  # Map the classes to binary digits
    train_set, test_set = train_test_split(df,  # Split the data into test and training data
                                           test_size=.4,
                                           random_state=42)
    testing_labels = test_set['Entity']  # Labels for the testing set
    test_set = test_set.drop(["Entity"], axis=1)  # Drop the labels
    X_test = np.array(test_set.values, np.int32)  # Place the vectors in a numpy array
    y_test = np.array(testing_labels.values, np.int32)  # Place the labels into a numpy array

    predict_input_fn = tf.estimator.inputs.numpy_input_fn(  # Define the input function
        x={"x": X_test},
        num_epochs=1,
        shuffle=False)

    predictions = list(classifier.predict(input_fn=predict_input_fn))  # Get the predictions
    predicted_classes = [p["classes"] for p in predictions]  # Extract the predicted classes from the predictions
    predicted_classes = np.array(predicted_classes, np.int32)  # Place the predicted classes in a numpy array
    predicted_classes = predicted_classes.flatten()  # Flatten the array
    predicted_classes = pd.Series(predicted_classes)
    y_test = pd.Series(y_test)

    ##### Testing output #####

    cm = ConfusionMatrix(y_test, predicted_classes)  # Confusion Matrix
    print("******************** CONFUSION MATRIX ********************\n")
    print(cm)
    print("\n******************** CONFUSION MATRIX STATS ********************\n")
    print cm.print_stats()
    df_confusion = pd.crosstab(y_test, predicted_classes, rownames=['Actual'], colnames=['Predicted'], margins=True)
    plot_confusion_matrix(df_confusion)
    plt.show()


if __name__ == "__main__":
    main()
