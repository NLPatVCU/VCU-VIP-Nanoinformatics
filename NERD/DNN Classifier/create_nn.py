from sklearn.model_selection import train_test_split
import tensorflow as tf
import numpy as np
import NERD.arff2df

df = NERD.arff2df.arff2df("nanop.arff")
df['Entity'] = df['Entity'].map({'Yes': 1, 'No': 0})        # Map the classes to binary digits
train_set, test_set = train_test_split(df,                  # Split the data into test and training data
                                       test_size=.4,
                                       random_state=42)
testing_labels = test_set['Entity']                         # Labels for the testing set
training_labels = train_set['Entity']                       # Labels for the training set
train_set = train_set.drop(["Entity"], axis=1)              # Drop the labels
test_set = test_set.drop(["Entity"], axis=1)                # Drop the labels
X_train = np.array(train_set.values, np.int32)              # Place the training data into numpy array
y_train = np.array(training_labels.values, np.int32)        # Place the labels into a numpy array

feature_columns = [tf.feature_column.numeric_column("x", shape=[7])]  # All the features are important

dnn_clf = tf.estimator.DNNClassifier(                       # Deep NN Classifier
    feature_columns=feature_columns,
    hidden_units=[300, 100],
    model_dir = 'nn_model'
    )

train_input_fn = tf.estimator.inputs.numpy_input_fn(       # Train input functions
    x={"x": X_train},
    y=y_train,
    num_epochs=None,
    shuffle=True)

dnn_clf.train(input_fn=train_input_fn, steps=2000)          # Train the classifier
