import os
from urllib.parse import urlparse
from selenium import webdriver
import re
import json
from bs4 import BeautifulSoup


def main():

    driver = createDriver()

    with open("asc.dois") as file:
        content = file.read()
        content = content.split("\n")
        content = [re.split(r"\s:\s", x) for x in content if x]
        JSONContent = []

        print("Starting DOI Conversion.")

        for item in content:
            currentURL = item[1]
            driver.get(currentURL)
            URL = getURL(driver)
            source = driver.page_source

            print("Currently Parsing URL:", currentURL)

            if URL == "pubs.rsc.org":
                parsedHTML = RSCHTMLParser.parse(source)

            elif URL == 'pubs.acs.org':
                parsedHTML = ASCHTMLParser.parse(source)

            JSONContent.append(parsedHTML)

        with open("../JSON/DOIData.json", "w") as f:
            f.write(json.dumps(JSONContent, indent=4, separators=(',', ":")))

        print("DOI Conversion Successful.")


def createDriver():
    options = webdriver.ChromeOptions()
    options.add_argument('headless')
    return webdriver.Chrome(chrome_options=options)


def getURL(driver):
    parsed_URL = urlparse(driver.current_url)
    return parsed_URL.netloc


class ASCHTMLParser:

    @staticmethod
    def parse(html):
        htmlSoup = BeautifulSoup(html, "html.parser")
        abstract = htmlSoup.find("p", class_='articleBody_abstractText')
        abstract = abstract.getText() if abstract else "No Abstract Provided"
        doi = htmlSoup.find("meta",  attrs={'name': 'dc.Identifier'})["content"]
        title = htmlSoup.find("meta",  attrs={'name': 'dc.Title'})["content"]
        article_url = htmlSoup.find("meta",  property='og:url')["content"]
        journal = htmlSoup.find("meta",  attrs={'name': 'dc.Publisher'})["content"]
        publish_date = htmlSoup.find("meta",  attrs={'name': 'dc.Identifier'})["content"]
        return {"abstract": abstract,
                "doi": doi,
                "title": title,
                "article_url": article_url,
                "journal": journal,
                "publish_date": publish_date}


class RSCHTMLParser:

    @staticmethod
    def parse(html):
        htmlSoup = BeautifulSoup(html, "html.parser")
        abstract = htmlSoup.find("div", class_ ='capsule__text').getText()
        doi = htmlSoup.find("meta",  attrs={'name': 'DC.Identifier'})["content"]
        title = htmlSoup.find("meta",  attrs={'name': 'DC.title'})
        title = title['content'] if title else "No Title Provided"
        article_url = htmlSoup.find("meta",  attrs={'name': 'citation_fulltext_html_url'})["content"]
        journal = htmlSoup.find("meta",  attrs={'name': 'DC.publisher'})["content"]
        publish_date = htmlSoup.find("meta",  attrs={'name': 'DC.issued'})["content"]
        return {"abstract": abstract,
                "doi": doi,
                "title": title,
                "article_url": article_url,
                "journal": journal,
                "publish_date": publish_date}


if __name__ == "__main__":
    main()
