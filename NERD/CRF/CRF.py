# Used for when precision or recall == 0 to supress warnings
def warn(*args, **kwargs):
    pass
import warnings
warnings.warn = warn

import numpy as np
import sklearn_crfsuite
from sklearn.metrics import make_scorer, confusion_matrix
from sklearn_crfsuite import metrics
from sklearn_crfsuite.utils import flatten
from sklearn.model_selection import cross_validate, cross_val_predict, StratifiedKFold
from collections import Counter
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
from chemdataextractor.doc import Paragraph
from Tools import TextTools

stop_word_list = set(stopwords.words('english'))
wordnet_lemmatizer = WordNetLemmatizer()
chem_ents = []


def main():


    train_docs = TextTools.loadNER("ASC")
    train_sents = []
    for index, row in train_docs.iterrows():
        for word in row['text']:
            train_sents.append(word)


    chem_ents = extract_chem_entities(train_sents)
    X = [sent2features(s,chem_ents) for s in train_sents]
    y = [sent2labels(s) for s in train_sents]


    crf = sklearn_crfsuite.CRF(
        algorithm='lbfgs',
        c1=0.1,
        c2=0.1,
        all_possible_transitions=True)
    crf.fit(X, y)

    # List of labels removing the non-entity classes
    labels = list(crf.classes_)
    labels.remove('O')


    NUMBER_OF_FOLDS = 5
    scoreers = {
        "f1_scores": make_scorer(metrics.flat_f1_score, average='weighted', labels=labels),
        "precision_scores": make_scorer(metrics.flat_precision_score, average='weighted', labels=labels),
        "recall_scores": make_scorer(metrics.flat_recall_score, average='weighted', labels=labels),
    }
    scores = cross_validate(crf, X, y, cv=NUMBER_OF_FOLDS, scoring=scoreers, return_train_score=False, n_jobs=-1)

    f1_scores = scores['test_f1_scores']
    precision_scores = scores['test_precision_scores']
    recall_scores = scores['test_recall_scores']

    for x in range(NUMBER_OF_FOLDS):
        print("Fold number: ", x)
        print("Precision: ", precision_scores[x])
        print("Recall: ", recall_scores[x])
        print("F1 Score: ", f1_scores[x])
        print("\n")
    print("Averages Across Folds")
    print("Precision: ", np.average(np.array(precision_scores)))
    print("Recall: ", np.average(np.array(recall_scores)))
    print("F1 Score: ", np.average(np.array(f1_scores)))

    y_pred = cross_val_predict(crf, X, y, cv=NUMBER_OF_FOLDS)
    conf_mat = confusion_matrix(flatten(y), flatten(y_pred))
    print("\nConfusion Matrix\n")
    print(" ".join(["NonEntity", "CoreComposition", "Precursor", "ReducingAgent", "Solvent", "Stabilizer"]))
    print(conf_mat)
    
    print("Top positive:")
    print_state_features(Counter(crf.state_features_).most_common(30))

    print("\nTop negative:")
    print_state_features(Counter(crf.state_features_).most_common()[-30:])


def extract_chem_entities(sents):
    document_text = [[str(w[0]) for w in s] for s in sents]
    document_text = [" ".join(s) for s in document_text]
    document_text = " ".join(document_text)
    paragraph = Paragraph(document_text)
    chem_entities = paragraph.cems
    chem_entities = [c.text for c in chem_entities]
    return chem_entities

def print_state_features(state_features):
    for (attr, label), weight in state_features:
        print("%0.6f %-8s %s" % (weight, label, attr))


def word2features(sent, word_position):

    SENTENCE_BEGGINING = 0
    SENTENCE_END = len(sent) - 1

    word = sent[word_position][0]
    pos = sent[word_position][1]
    features = featureize(word, pos)

    if word_position == SENTENCE_BEGGINING:
        features.append('BOS')

    if word_position > SENTENCE_BEGGINING:
        previous_word = sent[word_position-1][0]
        previous_pos = sent[word_position-1][1]
        features.extend(featureize(previous_word, previous_pos, relation="-1"))

    if word_position < SENTENCE_END:
        next_word = sent[word_position+1][0]
        next_pos = sent[word_position+1][1]
        features.extend(featureize(next_word, next_pos, relation="+1"))

    if word_position == SENTENCE_END:
        features.append('EOS')

    return features


def featureize(word, postag, relation=""):
    suffix = word[-3:]
    prefix = word[:3]
    return [
        relation + 'word.lower=' + word.lower(),
        relation + 'word.isupper=%s' % word.isupper(),
        relation + 'word.istitle=%s' % word.istitle(),
        relation + 'word.isdigit=%s' % word.isdigit(),
        relation + 'word.postag=%s' % postag,
        relation + 'word.prefix=%s' % prefix,
        relation + 'word.suffix=%s' % suffix,
        relation + 'word.lemma=%s' % wordnet_lemmatizer.lemmatize(word),
        relation + 'word.ischem=%s' % (word in chem_ents),
        relation + 'word.containsdigit=%s' % contains_digit(word),
    ]


def sent2features(sent, chem_ents):
    return [word2features(sent, i) for i in range(len(sent))]


def sent2labels(sent):
    return [label for token, postag, label in sent]


def contains_digit(s):
    return any(i.isdigit() for i in s)

if __name__ == "__main__":
    main()
