from sklearn import svm
from collections import Counter
from sklearn.externals import joblib
from scipy.io import arff
from pandas import DataFrame

from imblearn.over_sampling import SMOTE, ADASYN


data, meta = arff.loadarff("../ARFF_Files/nanoparticle_ARFF/_om/_train/nonsparse_nanoparticle_train-1.arff")
training_df = DataFrame(data=data, columns=meta.names())


training_labels = training_df["Entity"].map({'Yes': -1, 'No': 1})
training_features = training_df.drop(["Entity"], axis=1);

X_resampled, y_resampled = SMOTE(ratio={-1:500}).fit_sample(training_features.values, training_labels.values)



print(sorted(Counter(y_resampled).items()))

outliers = y_resampled[y_resampled == -1]
nu = float(outliers.shape[0]) / float(y_resampled.shape[0])

exit()
clf = svm.OneClassSVM(nu=nu, kernel='rbf', gamma=0.0005);
clf.fit(X_resampled, y=y_resampled)
joblib.dump(clf, '../Models/testmodel_oneclass.pkl')





def create_classifier(training_labels):
    '''
    Method to create the one class classifier
    :param training_labels: all of the labels for training
    :return: One_Class_Classifier
    '''
    outliers = training_labels[training_labels == -1]
    nu = float(outliers.shape[0]) / float(training_labels.shape[0])
    return svm.OneClassSVM(nu=nu, kernel='rbf', gamma=0.0005)


