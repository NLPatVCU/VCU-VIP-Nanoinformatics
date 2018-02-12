from bs4 import BeautifulSoup


class ASCHTMLParser:

    @staticmethod
    def parse(html):
        htmlSoup = BeautifulSoup(html, "html.parser")
        abstract = htmlSoup.find("p", class_='articleBody_abstractText').getText()
        doi = htmlSoup.find("meta",  name='dc.Identifier')["content"]
        title = htmlSoup.find("meta",  name='dc.Title')["content"]
        article_url = htmlSoup.find("meta",  property='og:url')["content"]
        journal = htmlSoup.find("meta",  name='dc.Publisher')["content"]
        publish_date = htmlSoup.find("meta",  name='dc.Identifier')["content"]
        return {"abstract": abstract,
                "doi": doi,
                "title": title,
                "article_url": article_url,
                "journal": journal,
                "publish_date": publish_date}
