from sklearn import svm
import argparse
from sklearn import tree
from sklearn.externals import joblib
from Tools import arff_converter
from imblearn.over_sampling import SMOTE



# Get the Command Line Arguments
pars = argparse.ArgumentParser()
pars.add_argument('-tr', '--train', help='Training ARFF file')
arguments = pars.parse_args()
args = vars(arguments)

# Obtain the Dataset

args['train'] = "../ARFF_Files/activeingredient_ARFF/_o/_train/activeingredient_train-1.arff"
dataset = arff_converter.arff2df(args['train'])
X = dataset.iloc[:, :-1].values
y = dataset.iloc[:, -1].map({'Yes': -1, 'No': 1}).values


# Create and fit the classifier
dtree = tree.DecisionTreeClassifier();

dtree.fit(X,y);



# Save the classifier
joblib.dump(dtree, '../Models/decisiontree%s_%s.pkl' % (args['train'].split("/")[-3], args['train'].split("/")[-1]))


