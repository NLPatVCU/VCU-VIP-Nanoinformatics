from scipy.io import arff
from pandas import DataFrame


def arff2df(filepath):
    data, meta = arff.loadarff(filepath)
    return DataFrame(data=data, columns=meta.names())
