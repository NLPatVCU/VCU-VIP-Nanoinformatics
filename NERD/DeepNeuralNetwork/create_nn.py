from sklearn.model_selection import train_test_split
import tensorflow as tf
import numpy as np
from scipy.io import arff
from pandas import DataFrame
import argparse

pars = argparse.ArgumentParser(usage='Creates and evaluates a OneClassSVM in Scikit',
                               formatter_class=argparse.RawTextHelpFormatter,
                               description='''Creates and evaluates a OneClassSVM in Scikit''',
                               version='0.1')

pars.add_argument('-tr', '--train',
                  help='Training ARFF file')

pars.add_argument('-l', '--labels',
                  help='Name of the Labels Column')


def main():
    arguments = pars.parse_args()
    args = vars(arguments)
    data, meta = arff.loadarff(args['train'])
    df = DataFrame(data=data, columns=meta.names())
    df['Entity'] = df['Entity'].map({'Yes': 1, 'No': 0})  # Map the classes to binary digits
    train_set, test_set = train_test_split(df,  # Split the data into test and training data
                                           test_size=.4,
                                           random_state=42)
    testing_labels = test_set['Entity']  # Labels for the testing set
    training_labels = train_set['Entity']  # Labels for the training set
    train_set = train_set.drop(["Entity"], axis=1)  # Drop the labels
    test_set = test_set.drop(["Entity"], axis=1)  # Drop the labels
    X_train = np.array(train_set.values, np.int32)  # Place the training data into numpy array
    y_train = np.array(training_labels.values, np.int32)  # Place the labels into a numpy array

    feature_columns = [tf.feature_column.numeric_column("x", shape=[7])]  # All the features are important

    dnn_clf = tf.estimator.DNNClassifier(  # Deep NN Classifier
        feature_columns=feature_columns,
        hidden_units=[300, 100],
        model_dir='Neural_Net_Model'
    )

    train_input_fn = tf.estimator.inputs.numpy_input_fn(  # Train input functions
        x={"x": X_train},
        y=y_train,
        num_epochs=None,
        shuffle=True)

    dnn_clf.train(input_fn=train_input_fn, steps=2000)  # Train the classifier


if __name__ == "__main__":
    main()
