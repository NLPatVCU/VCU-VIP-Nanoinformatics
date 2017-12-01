import matplotlib as mpl
from scipy.io import arff
from pandas import DataFrame
import pandas as pd
from sklearn.externals import joblib
from sklearn import metrics
import argparse
mpl.use('TkAgg')
import matplotlib.pyplot as plt
import seaborn as sn

pars = argparse.ArgumentParser(usage='Creates and evaluates a OneClassSVM in Scikit',
                               formatter_class=argparse.RawTextHelpFormatter,
                               description='''Creates and evaluates a OneClassSVM in Scikit''',
                               version='0.1')

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
    return joblib.load('Models/oneclass.pkl')


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
