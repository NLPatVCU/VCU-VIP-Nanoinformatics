from sklearn import svm
import argparse
from sklearn.externals import joblib
from Tools.FileConverters import Arff2Dataframe

# Get the Command Line Arguements
pars = argparse.ArgumentParser()
pars.add_argument('-tr', '--train', help='Traing ARFF file')
arguments = pars.parse_args()
args = vars(arguments)

# Obtain the Dataset
dataset = Arff2Dataframe.arff2df(args['train'])
X = dataset.iloc[:, :-1].values
y = dataset.iloc[:, -1].map({'Yes': -1, 'No': 1}).values

# Create and fit the classifier
outliers = y[y == -1]
nu = float(outliers.shape[0]) / float(y.shape[0])
clf = svm.OneClassSVM(nu=nu, kernel='rbf', gamma=0.0005)
clf.fit(X, y)

# Save the classifier
joblib.dump(clf, '../Models/oneclass.pkl')


