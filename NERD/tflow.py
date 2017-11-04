import pandas as pd
from sklearn.model_selection import train_test_split
import tensorflow as tf
import arff2df


def create_feature_columns(df):
    headers = list(df)
    feature_columns = []
    for header in headers:
        feature_columns.append(tf.feature_column.numeric_column(header))
    return feature_columns


df = arff2df.arff2df("nanop.arff")
df['Entity'] = df['Entity'].map({'Yes': 1, 'No': 0})        # Map the classes to binary digits
train_set, test_set = train_test_split(df,                  # Split the data into test and training data
                                       test_size=.4,
                                       random_state=42)
testing_labels = test_set['Entity']                         # Labels for the testing set
training_labels = train_set['Entity']                       # Labels for the training set
train_set = train_set.drop(["Entity"], axis=1)              # Drop the labels
test_set = test_set.drop(["Entity"], axis=1)                # Drop the labels

feature_columns = create_feature_columns(train_set)         # Create feature columns

dnn_clf = tf.estimator.DNNClassifier(                       # Deep NN Classifier
    feature_columns=feature_columns,
    hidden_units=[300, 100],
    )

train_input_fn = tf.estimator.inputs.pandas_input_fn(       # Train input functions
    x=train_set,
    y=training_labels,
    batch_size=100,
    num_epochs=None,
    shuffle=True)

dnn_clf.train(input_fn=train_input_fn, steps=2000)          # Train the classifier

########## Testing ##########

test_input_fn = tf.estimator.inputs.pandas_input_fn(
    x=test_set,
    y=testing_labels,
    num_epochs=1,
    shuffle=False
)

ev = dnn_clf.evaluate(input_fn=test_input_fn)

print("\nTest Accuracy: {0:f}\n".format(ev["accuracy"]))
print("\nLoss: {0:f}\n".format(ev["loss"]))
