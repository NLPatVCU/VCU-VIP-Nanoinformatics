from chemdataextractor.scrape import Selector
from chemdataextractor.scrape.pub.rsc import RscHtmlDocument
from chemdataextractor import Document
import json
import os
from bs4 import BeautifulSoup, SoupStrainer


inputDirectory = "../HTML/ACSHTML"
papers = []
for dirpath, dirnames, files in os.walk(inputDirectory):
    for name in files:
        file_json = {}
        if name.lower().endswith('.html'):
            file_name = os.path.join(dirpath, name)
            f = open(file_name, 'rb')
            html = BeautifulSoup(f, "html.parser")
            abstract = html.find("div", class_ ='capsule__text').getText()
            htmlstring = open(file_name, 'rb').read()
            sel = Selector.from_text(htmlstring)
            scrape = RscHtmlDocument(sel)
            file_json['doi'] = scrape.doi
            file_json['journal'] = scrape.journal
            file_json['volume'] = scrape.volume
            file_json['issue'] = scrape.issue
            file_json['abstract_location'] = scrape.html_url
            file_json['abstract'] = abstract
            papers.append(file_json)
    print(json.dumps(papers, indent=4, separators=(',',":")))

