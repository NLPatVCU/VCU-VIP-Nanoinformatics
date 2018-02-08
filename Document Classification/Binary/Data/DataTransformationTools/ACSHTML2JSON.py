import json
import os
from bs4 import BeautifulSoup
import re


inputDirectory = "../HTML/ACSHTML"
outputDirectory = "../JSON"
papers = []
for dirpath, dirnames, files in os.walk(inputDirectory):
    for name in files:
        file_json = {}
        if name.lower().endswith('.html'):
            file_name = os.path.join(dirpath, name)
            f = open(file_name, 'rb')
            html = BeautifulSoup(f, "html.parser")
            abstract = html.find("p", class_ ='articleBody_abstractText').getText()
            file_json['doi'] = re.sub("DOI: ","",html.find("div", id ='doi').getText())
            file_json['abstract_location'] = "https://pubs.acs.org" + html.find("a", title='Full Text HTML')['href']
            file_json['abstract'] = abstract
            papers.append(file_json)
    complete_path = os.path.join(outputDirectory, "ACS.json")
    with open(complete_path, "w") as jsonfile:
        jsonfile.write(json.dumps(papers, indent=4, separators=(',', ":")))

