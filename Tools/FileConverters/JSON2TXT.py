import json
import os

newDir = 'TXTFiles'
topdir = 'DataFilesAsJson' # Starting Directory

for dirpath, dirnames, files in os.walk(topdir):
    for name in files:
        if name.lower().endswith('.json'):
            file_name = os.path.join(dirpath, name)
            with open(file_name) as file:
                content = file.read()
            if not os.path.exists(newDir):
                os.makedirs(newDir)
            text = json.loads(content)
            txt_file_contents = ""
            for section in text:
                txt_file_contents += (section['text'] + "\n")
            complete_path = os.path.join(newDir, name + ".txt")
            fh = open(complete_path, "w")
            fh.write(txt_file_contents)
            fh.close()