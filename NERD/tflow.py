import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split

import arff2df


def input_fn(df_data, num_epochs, shuffle):
    labels = df_data['class']
    df_data.drop(['class'], axis=1)
    return tf.estimator.inputs.pandas_input_fn(
        x=df_data,
        y=labels,
        batch_size=100,
        num_epochs=num_epochs,
        shuffle=shuffle,
        num_threads=1)


df = arff2df.arff2dataframe("diabetes.arff")                               # Create pandas df from .arff files
df['class'] = pd.factorize(df['class'])[0]                                 # Turn the class labels into numerical form
train_set, test_set = train_test_split(df, test_size=.2, random_state=42)  # Split the data into test and training data
input = input_fn(train_set, 100, True)                                     # Create input function to tf.estimator()
feature_columns = [                                                        # List the feature colums of our dataset
    tf.feature_column.numeric_column("preg")
]

classifier = tf.estimator.DNNClassifier(feature_columns=feature_columns,   # Create our Classifier
                                            hidden_units=[10, 20, 10],
                                            n_classes=3,
                                            model_dir="model")

classifier.train(input_fn=input, steps=2000)                               # Train the classifier
