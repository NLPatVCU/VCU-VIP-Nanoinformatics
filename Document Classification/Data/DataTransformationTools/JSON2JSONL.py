import json
import os
import argparse

parser = argparse.ArgumentParser(description='Convert a JSON file into a JSONL file. Most Likely to be used by '
                                             'the Prodigy annotation tool.')
parser.add_argument('--inputdir', help='Directory which contains JSON files.')
parser.add_argument('--outputdir', help='Directory to write the JSONL files to.')

arguments = parser.parse_args()
args = vars(arguments)
outputDirectory = args['outputdir']
inputDirectory = args['inputdir']

if not os.path.exists(outputDirectory):
    os.makedirs(outputDirectory)

for dirpath, dirnames, files in os.walk(inputDirectory):
    for name in files:
        if name.lower().endswith('.json'):
            file_name = os.path.join(dirpath, name)

            with open(file_name) as file:
                content = file.read()

            JSON_entries = json.loads(content)
            basename = os.path.basename(file_name)
            filename = os.path.splitext(basename)[0]
            complete_path = os.path.join(outputDirectory, filename + ".jsonl")

            with open(complete_path, "w") as jsonlfile:
                for entry in JSON_entries:
                    json.dump(entry, jsonlfile)
                    jsonlfile.write("\n")