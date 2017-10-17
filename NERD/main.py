from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
import arff2df
import matplotlib as mpl
mpl.use('TkAgg')  # Special Case for Mac OSX
import pandas as pd

__author__ = "Brandon Watts"
__license__ = 'MIT'
__version__ = '0.1'


df = arff2df.arff2dataframe("diabetes.arff")             # Start by reading in a .arff file
train_set, test_set = train_test_split(df,
                                       test_size=.2,
                                       random_state=42)  # Split the data into test and training data


df = train_set.copy()                                   # Make a copy of the training data so we can play with it
df['class'] = pd.factorize(df['class'])[0]              # Turn the class labels into numerical form
scaler = MinMaxScaler()                                 # Feature Scaling with MinMaxScaling
df[df.columns] = scaler.fit_transform(df[df.columns])   # Apply Feature Scaling
print df

