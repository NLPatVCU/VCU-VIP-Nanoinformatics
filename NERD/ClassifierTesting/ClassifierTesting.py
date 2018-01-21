from sklearn import svm
from sklearn.externals import joblib
from Tools import arff_converter


# Obtain the Dataset
dataset = arff_converter.arff2df("../ARFF_Files/nanoparticle_ARFF/_o/_train/nanoparticle_train-1.arff")
X = dataset.iloc[:, :-1].values
y = dataset.iloc[:, -1].map({'Yes': -1, 'No': 1}).values

# Create and fit the classifier
outliers = y[y == -1]
nu = float(outliers.shape[0]) / float(y.shape[0])
clf = svm.OneClassSVM(nu=nu, kernel='rbf', gamma=0.0005)
clf.fit(X, y)

# Save the classifier
joblib.dump(clf, '../Models/testmodel_oneclass.pkl')


