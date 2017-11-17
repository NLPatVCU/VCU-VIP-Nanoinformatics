from sklearn import svm
import arff2df
import argparse
from sklearn.externals import joblib


pars = argparse.ArgumentParser(usage='Creates and evaluates a OneClassSVM in Scikit',
                               formatter_class=argparse.RawTextHelpFormatter,
                               description='''Creates and evaluates a OneClassSVM in Scikit''',
                               version='0.1')

pars.add_argument('-tr', '--train',
                  help='Traing ARFF file')

pars.add_argument('-l', '--labels',
                  help='Name of the Labels Column')

arguments = pars.parse_args()
args = vars(arguments)

print("Starting Mapping...")
training_df = arff2df.arff2df(args['train'])
training_df[args['labels']] = training_df[args['labels']].map({'Yes': -1, 'No': 1})
print("Mapping Complete.")

print("Loading Training Data...")
training_labels = training_df[args['labels']]
training_features = training_df.drop([args['labels']], axis=1)
print("Training Data Loaded.")

outliers = training_labels[training_labels == -1]
nu = float(outliers.shape[0])/float(training_labels.shape[0])
model = svm.OneClassSVM(nu=nu, kernel='rbf', gamma=0.0005)

print("Begin Training Model...")
model.fit(training_features)
print("Model Training Complete.")

joblib.dump(model, 'Models/oneclass.pkl')
