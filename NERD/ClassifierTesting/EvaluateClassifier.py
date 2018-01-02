#import matplotlib as mpl
from scipy.io import arff
from pandas import DataFrame
import pandas as pd
from sklearn.externals import joblib
from sklearn import metrics
import matplotlib.pyplot as plt
import seaborn as sn


labelName = 'Entity'
data, meta = arff.loadarff("../ARFF_Files/nanoparticle_ARFF/_om/_test/nonsparse_nanoparticle_test-1.arff")
testing_df = DataFrame(data=data, columns=meta.names())
testing_labels = testing_df[labelName].map({'Yes': 1, 'No': -1})
testing_features = testing_df.drop([labelName], axis=1)

clf = joblib.load('../Models/testmodel_oneclass_om_1.pkl')
preds = clf.predict(testing_features)
for i, val in enumerate(preds):
    if val==1:
        preds[i] = -1;
    else:
        preds[i] = 1;

targs = testing_labels

print metrics.confusion_matrix(targs,preds)
print metrics.precision_score(targs,preds)
print metrics.recall_score(targs,preds)


def create_conf_mat(targs, preds):
    return pd.crosstab(targs, preds, rownames=['Actual'], colnames=['Predicted'], margins=True)


def plot_conf_mat(targs, preds):
    cf = metrics.confusion_matrix(targs, preds)
    df_cm = pd.DataFrame(cf, index=[i for i in ["Nano", "Non-Nano"]], columns=[i for i in ["Nano", "Non-Nano"]])
    plt.figure(figsize=(8, 5))
    sn.heatmap(df_cm, annot=True, cmap='Blues', fmt='g')
    plt.show()

def print_metrics(targs, preds):
    print('\nMetrics\n')
    print("accuracy: ", metrics.accuracy_score(targs, preds))
    print("precision: ", metrics.precision_score(targs, preds))
    print("recall: ", metrics.recall_score(targs, preds))
    print("f1: ", metrics.f1_score(targs, preds))
    print("Geometric Mean", metrics.fowlkes_mallows_score(targs, preds))
    print("area under curve (auc): ", metrics.roc_auc_score(targs, preds))