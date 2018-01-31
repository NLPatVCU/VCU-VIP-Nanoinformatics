from Tools import arff_converter
from sklearn.externals import joblib
from sklearn import metrics
import argparse


# Get the Command Line Arguements
pars = argparse.ArgumentParser()
pars.add_argument('-te', '--test', help='Testing ARFF file')
arguments = pars.parse_args()
args = vars(arguments)

# Obtain the Dataset
#args['test'] = "../ARFF_Files/activeingredient_ARFF/_omt/_test/activeingredient_test-1.arff"
dataset = arff_converter.arff2df(args['test'])

X = dataset.iloc[:, :-1].values
y_test = dataset.iloc[:, -1].map({'Yes': -1, 'No': 1}).values

# Load the classifier and make predictions
dtree = joblib.load('../Models/randomforest/%s%s/randomforest%s_%s.pkl' % (args['test'].split("/")[-1].split("_")[0],args['test'].split("/")[-3],args['test'].split("/")[-3], args['test'].split("/")[-1].replace('test','train')))
y_predicted = dtree.predict(X)
#
# dot_data = tree.export_graphviz(dtree, out_file=None,
#                                       feature_names=dataset.columns.values[:-1],
#                                       class_names=["Entity", "Non-Entity"], label='all',
#                                    filled=True, rounded=True, proportion=False, leaves_parallel=True,
#                                      special_characters=True)
#
# graph = graphviz.Source(dot_data)
# graph.render("visual/decisiontree%s_%s" % (args['test'].split("/")[-3], args['test'].split("/")[-1].replace('test','train')))

# Print the Metrics
precision = metrics.precision_score(y_test, y_predicted, average=None)[0]
recall = metrics.recall_score(y_test, y_predicted, average=None)[0]
matrix = metrics.confusion_matrix(y_test, y_predicted)

print(args['test'].split("/")[-1])
print("Precision: %f" % (precision))
print("Recall: %f" % (recall))
print(matrix)
print()

