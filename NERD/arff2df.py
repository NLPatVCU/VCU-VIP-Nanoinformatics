import pandas
import StringIO as io
import re

'''arff2df.py will convert an .arff file into a panadas dataframe'''

__author__ = "Brandon Watts"
__license__ = 'MIT'
__version__ = '0.1'

relation = r'@relation (?P<relation>[^\n]+)'
attribute = r'@attribute (?P<attribute>[^\n]+)'
data = r'@data\n(?P<data>.+)'
arff_re = re.compile(r'{}|{}|{}'.format(relation, attribute, data), re.DOTALL)


def arff2dataframe(filename):
    with open(filename, 'r') as f:
        text = f.read()
    column_names = []
    for m in arff_re.finditer(text):
        d = m.groupdict()
        if d['attribute']:
            colm = re.match(r'\'(.+)\'|(\w+)', d['attribute'])
            column_names.append(colm.group(1) or colm.group(2))
        if d['data']:
            csv_data = d['data']
    return pandas.read_csv(io.StringIO(csv_data),
                           header=None,
                           names=column_names)

