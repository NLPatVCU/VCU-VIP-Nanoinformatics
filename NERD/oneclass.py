import matplotlib as mpl
import numpy as np
from sklearn.model_selection import train_test_split
mpl.use('TkAgg')
import matplotlib.pyplot as plt
from sklearn import svm
import arff2df
from sklearn import metrics
import pandas as pd
import seaborn as sn

''' Start by reading in the arff file, turning it into a dataframe, and mapping the classes to -1 and 1'''
df = arff2df.arff2df("nanop.arff")
df['Entity'] = df['Entity'].map({'Yes': -1, 'No': 1})
train_set, test_set = train_test_split(df,                  # Split the data into test and training data
                                       test_size=.2,
                                       random_state=42)

'''Create the testing labels and vectors'''
testing_labels = test_set['Entity']
test_set = test_set.drop(["Entity"], axis=1)
X_test = np.array(test_set.values, np.int32)
y_test = np.array(testing_labels.values, np.int32)

'''Create the training labels and vectors'''
training_labels = train_set['Entity']
train_set = train_set.drop(["Entity"], axis=1)
X_train = np.array(train_set.values, np.int32)
y_train = np.array(training_labels.values, np.int32)

outliers = training_labels[training_labels == -1]               # Obtain the outliers
nu = float(outliers.shape[0])/float(training_labels.shape[0])   # Compute our nu
model = svm.OneClassSVM(nu=nu, kernel='rbf', gamma=0.00005)     # Create the One-Class Classifier
model.fit(train_set)                                            # Train the model

preds = model.predict(test_set)     # Predictions
targs = testing_labels              # Target Values

''' Print Metrics '''
print("nu", nu)
print("accuracy: ", metrics.accuracy_score(targs, preds))
print("precision: ", metrics.precision_score(targs, preds))
print("recall: ", metrics.recall_score(targs, preds))
print("f1: ", metrics.f1_score(targs, preds))
print("area under curve (auc): ", metrics.roc_auc_score(targs, preds))

''' Create the confusion matrix '''
cfMat = pd.crosstab(targs, preds, rownames=['Actual'], colnames=['Predicted'], margins=True)
print(cfMat)

''' Visualize the Confusion Matrix '''
cf = metrics.confusion_matrix(targs,preds)
df_cm = pd.DataFrame(cf, index = [i for i in ["Nano","Non-Nano"]], columns = [i for i in ["Nano","Non-Nano"]])
plt.figure(figsize=(8, 5))
sn.heatmap(df_cm,annot=True, cmap='Blues', fmt='g')
plt.show()

