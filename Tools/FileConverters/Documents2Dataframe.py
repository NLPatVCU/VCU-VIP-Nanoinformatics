import os
import pickle

topdir = 'Data' # Starting Directory

for dirpath, dirnames, files in os.walk(topdir):
    for name in files:
        if name.lower().endswith('.txt'):
            file_name = os.path.join(dirpath, name)
            with open(file_name) as file:
                content = file.read()
                print(content)
