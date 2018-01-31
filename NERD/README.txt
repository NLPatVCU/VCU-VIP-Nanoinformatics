This directory structure represents the Classifier Development Framework
The CDL is an organized system to build and evaluate classifiers for experimentation and data collection purposes.

How to use the CDL (Classifier Development Framework):
    - All data should be located in the ARFF_Files directory.
    - For each new classifier you are experimenting with building (ie. SVM, DecisionTree, NeuralNet, etc), a new sub-
        directory should be created in the root directory.
    - All classifiers should pipe their created models to an appropriately named sub-directory of the Models
        directory. For example, a DecisionTree classifier should save its models into a sub-directory of the
        Models directory named 'DecisionTrees'