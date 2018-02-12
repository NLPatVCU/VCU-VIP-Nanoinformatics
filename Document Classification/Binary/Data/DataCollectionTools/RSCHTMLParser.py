from bs4 import BeautifulSoup

class RSCHTMLParser:

    @staticmethod
    def parse(self, html):
        htmlSoup = BeautifulSoup(html, "html.parser")
        abstract = htmlSoup.find("div", class_ ='capsule__text').getText()
        doi = htmlSoup.find("meta",  name='DC.Identifier')["content"]
        title = htmlSoup.find("meta",  name='DC.title')["content"]
        article_url = htmlSoup.find("meta",  name='citation_fulltext_html_url')["content"]
        journal = htmlSoup.find("meta",  name='DC.publisher')["content"]
        publish_date = htmlSoup.find("meta",  name='DC.issued')["content"]
        return {"abstract": abstract,
                "doi": doi,
                "title": title,
                "article_url": article_url,
                "journal": journal,
                "publish_date": publish_date}
