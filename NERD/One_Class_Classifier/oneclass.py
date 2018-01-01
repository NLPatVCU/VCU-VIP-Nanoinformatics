from sklearn import svm
import argparse
from sklearn.externals import joblib
from Tools import arff_converter

pars = argparse.ArgumentParser(usage='Creates and evaluates a OneClassSVM in Scikit',
                               formatter_class=argparse.RawTextHelpFormatter,
                               description='''Creates and evaluates a OneClassSVM in Scikit''')

pars.add_argument('-tr', '--train',
                  help='Traing ARFF file')

pars.add_argument('-l', '--labels',
                  help='Name of the Labels Column')

def main():
    arguments = pars.parse_args()
    args = vars(arguments)
    labelName = args['labels']
    training_df = arff_converter.arff2df(args['train'])
    y_train = convert_labels_to_numeric(training_df, labelName)
    X_train = training_df.drop([args['labels']], axis=1)
    clf = create_classifier(y_train)
    clf.fit(X_train, y_train)
    joblib.dump(clf, '../Models/oneclass.pkl')


def convert_labels_to_numeric(df, labelName):
    '''
    Method to Convert the Yes and No Columns to -1 and 1 numerical values
    :param df: Dataframe
    :param labelName: Name of the Entity Label
    :return: DataFrame with updated Labels
    '''
    return df[labelName].map({'Yes': -1, 'No': 1})


def create_classifier(training_labels):
    '''
    Method to create the one class classifier
    :param training_labels: all of the labels for training
    :return: One_Class_Classifier
    '''
    outliers = training_labels[training_labels == -1]
    nu = float(outliers.shape[0]) / float(training_labels.shape[0])
    return svm.OneClassSVM(nu=nu, kernel='rbf', gamma=0.0005)


if __name__ == "__main__":
    main()
