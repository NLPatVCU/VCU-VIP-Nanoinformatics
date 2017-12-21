import arff
import re
import pandas as pd

decoder = arff.ArffDecoder()

def arff2df(filepath):
    arff_file = ''
    for line in open(filepath):
        line_1 = re.sub('%[-\*\[\]\w\.,\(\)\?:]+', '', line.rstrip())  # Strip out all the junk
        line_2 = re.sub(r'(\d),\s([A-z]+)', r'\1 \2', line_1.rstrip())  # Remove the extra column
        arff_file += line_2 + '\n'
    decoded_arff = decoder.decode(arff_file, encode_nominal=True, return_type=arff.LOD)
    data = decoded_arff['data']
    column_names = list(map(lambda x: x[0], decoded_arff['attributes']))
    df = pd.DataFrame.from_records(data, columns=list(range(len(column_names))))
    df = df.fillna(0)
    df.columns = column_names
    return df
