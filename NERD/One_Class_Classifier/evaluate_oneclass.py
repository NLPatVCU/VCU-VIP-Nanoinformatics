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

pars.add_argument('-te', '--test',
                  help='Testing ARFF file')

pars.add_argument('-l', '--labels',
                  help='Name of the Labels Column')


def main():
    arguments = pars.parse_args()
    args = vars(arguments)
    labelName = args['labels']
    data, meta = arff.loadarff(args['test'])
    testing_df = DataFrame(data=data, columns=meta.names())
    testing_labels = convert_labels_to_numeric(testing_df, labelName)
    testing_features = testing_df.drop([labelName], axis=1)

    clf = load_classifier()
    preds = clf.predict(testing_features)
    targs = testing_labels

    cfMat = create_conf_mat(targs, preds)

    print '\nConfusion Matrix\n\n{}'.format(cfMat)
    print_metrics(targs, preds)
    plot_conf_mat(targs, preds)

def load_classifier():
    return joblib.load('../Models/testmodel_oneclass.pkl')


def print_metrics(targs, preds):
    print('\nMetrics\n')
    print("accuracy: ", metrics.accuracy_score(targs, preds))
    print("precision: ", metrics.precision_score(targs, preds))
    print("recall: ", metrics.recall_score(targs, preds))
    print("f1: ", metrics.f1_score(targs, preds))
    print("Geometric Mean", metrics.fowlkes_mallows_score(targs, preds))
    print("area under curve (auc): ", metrics.roc_auc_score(targs, preds))


def create_conf_mat(targs, preds):
    return pd.crosstab(targs, preds, rownames=['Actual'], colnames=['Predicted'], margins=True)


def plot_conf_mat(targs, preds):
    cf = metrics.confusion_matrix(targs, preds)
    df_cm = pd.DataFrame(cf, index=[i for i in ["Nano", "Non-Nano"]], columns=[i for i in ["Nano", "Non-Nano"]])
    plt.figure(figsize=(8, 5))
    sn.heatmap(df_cm, annot=True, cmap='Blues', fmt='g')
    plt.show()


def convert_labels_to_numeric(df, labelName):
    return df[labelName].map({'Yes': -1, 'No': 1})


if __name__ == "__main__":
    main()
>>>>>>> 9024613e7ae0780904e643b1eaa3a28c17e51a89
