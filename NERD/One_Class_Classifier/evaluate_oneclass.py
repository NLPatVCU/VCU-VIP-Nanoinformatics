import matplotlib as mpl
from Tools import arff_converter
import pandas as pd
from sklearn.externals import joblib
from sklearn import metrics
import argparse
mpl.use('TkAgg')
import matplotlib.pyplot as plt
import seaborn as sn

# Get the Command Line Arguements
pars = argparse.ArgumentParser()
pars.add_argument('-te', '--test', help='Testing ARFF file')
arguments = pars.parse_args()
args = vars(arguments)

# Obtain the Dataset
dataset = arff_converter.arff2df(args['test'])
X = dataset.iloc[:, :-1].values
y = dataset.iloc[:, -1].map({'Yes': -1, 'No': 1}).values

# Load the classifier and make predictions
clf = joblib.load('../Models/oneclass.pkl')
preds = clf.predict(X)

# Print the Metrics
print(metrics.classification_report(y, preds))
cf = metrics.confusion_matrix(y, preds)
df_cm = pd.DataFrame(cf)
plt.figure(figsize=(8, 5))
sn.heatmap(df_cm, annot=True, cmap='Blues', fmt='g')
plt.show()