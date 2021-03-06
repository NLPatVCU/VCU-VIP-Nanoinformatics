
from Tools import arff_converter
import pandas as pd
from sklearn.externals import joblib
from sklearn import metrics

import matplotlib.pyplot as plt
import seaborn as sn


# Obtain the Dataset
dataset = arff_converter.arff2df("../ARFF_Files/nanoparticle_ARFF/_o/_test/nanoparticle_test-1.arff")
X = dataset.iloc[:, :-1].values
y = dataset.iloc[:, -1].map({'Yes': -1, 'No': 1}).values

# Load the classifier and make predictions
clf = joblib.load('../Models/oneclasssvm_omt_1.pkl')
preds = clf.predict(X)


# Print the Metrics
print(metrics.precision_score(y,preds, average=None)[0])
cf = metrics.confusion_matrix(y, preds)
df_cm = pd.DataFrame(cf)
plt.figure(figsize=(8, 5))
sn.heatmap(df_cm, annot=True, cmap='Blues', fmt='g')
plt.show()

