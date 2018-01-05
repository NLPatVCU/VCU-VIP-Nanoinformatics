import arff
import pandas as pd

'''
This converter is used to convert an arff file into a pandas DataFrame
'''


def arff2df(filepath):
    decoder = arff.ArffDecoder()
    arff_file = open(filepath)
    decoded_arff = decoder.decode(arff_file, return_type=arff.LOD)
    data = decoded_arff['data']
    column_names = list(map(lambda x: x[0], decoded_arff['attributes']))
    df = pd.DataFrame.from_records(data, columns=list(range(len(column_names))))
    df = df.fillna(0)
    df.columns = column_names
    return df
