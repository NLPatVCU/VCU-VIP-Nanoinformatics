import os
""" Creates models for each fold and runs evaluation with results """
featureset = "omt"
entity_name = "adversereaction"

for fold in range(1,11):
    training_data = "../ARFF_Files/%s_ARFF/_%s/_train/%s_train-%i.arff" % (entity_name, featureset, entity_name, fold)
    os.system("python3 randomforest.py -tr %s" % (training_data))
    print(fold)


for fold in range(1,1):
    testing_data = "../ARFF_Files/%s_ARFF/_%s/_test/%s_test-%i.arff" % (entity_name, featureset, entity_name, fold)
    os.system("python3 evaluate_randomforest.py -te %s" % (testing_data))