from selenium import webdriver
import json
from pandas import read_csv
import os
from bs4 import BeautifulSoup, SoupStrainer
import argparse

parser = argparse.ArgumentParser(description='Tool to Web Scrape the ACS website and parse papers into JSON format. '
                                             'If you would like text format or JSONL use the provided converters.'
                                             'Just provide a CSV that contains the title of a document and '
                                             'the link to the full HTML of the paper.')
parser.add_argument('--csv', help='CSV that should contain (Title,Link) to all pages that you wish to be scraped.')
parser.add_argument('--outputdir', help="Output Directory that you would like the files to be written to.")

arguments = parser.parse_args()
outputDirectory = arguments.outputdir


def main():

    titleLinks = read_csv(arguments.csv)
    for index, row in titleLinks.iterrows():
        page_in_json = JSONize(row['Link'])
        writeJSON(row["Title"], page_in_json, outputDirectory)


def writeJSON(Title, page_json, directory):

    if not os.path.exists(directory):
        os.makedirs(directory)
    complete_path = os.path.join(directory, Title + ".json")
    fh = open(complete_path, "w")
    fh.write(page_json)
    fh.close()


def JSONize(webpage):

    def is_reference(tag):
        prev_neg = False
        if tag.previous_sibling:
            prev_neg = "-" == tag.previous_sibling.string
        is_ion = "+" in tag.getText()
        is_anion = "-" in tag.getText() or prev_neg
        return tag.name == "sup" and not (is_ion or is_anion)

    article_only = SoupStrainer("article")
    document = []
    options = webdriver.ChromeOptions()
    options.add_argument('headless')
    driver = webdriver.Chrome(chrome_options=options)
    driver.get(webpage)

    """ Extract Source of Webpage """

    source = driver.page_source
    html = BeautifulSoup(source, "html.parser", parse_only=article_only)

    """ Remove References, Tables, and Figures """
    [s.extract() for s in html.find_all(is_reference)]
    [s.extract() for s in html.find_all("table")]
    [s.extract for s in html.find_all(class_="figure")]

    article_sections = html.find_all("div", class_='NLM_sec')
    for section in article_sections:
        sectionTitle = section.find('h2')
        if sectionTitle:
            sectionTitle = section.find('h2').get_text()
        else:
            sectionTitle = "NO SECTION HEADER PROVIDED"
        paragraphs = section.find_all("div", class_="NLM_p")
        for i, paragraph in enumerate(paragraphs):
            document.append({"text": paragraph.get_text(), "meta": {"section": sectionTitle,"paragraph": i}})

    driver.quit()
    return json.dumps(document, indent=4, separators=(',',":"))


if __name__ == "__main__":
    main()
