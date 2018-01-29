from selenium import webdriver
from chemdataextractor import Document


def main():

    options= webdriver.ChromeOptions()
    options.add_argument('headless')
    driver = webdriver.Chrome(chrome_options=options)
    driver.get('http://pubs.acs.org/doi/abs/10.1021/la049463z')
    p_element = driver.find_element_by_id(id_='abstractBox')
    abstract = p_element.text
    print(abstract)
    doc = Document(abstract)
    print(doc.cems)



if __name__ == "__main__":
    main()
