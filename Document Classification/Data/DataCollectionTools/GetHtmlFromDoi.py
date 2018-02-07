import re
import os
from selenium import webdriver
from urllib.parse import urlparse
from time import sleep


options = webdriver.ChromeOptions()
options.add_argument('headless')
driver = webdriver.Chrome(chrome_options=options)
outputDir = 'test'

with open("asc.cu.dois") as file:
    content = file.read()
    content = content.split("\n")
    content = [re.split(r"\s:\s", x) for x in content if x]
    for item in content:
        filename = os.path.splitext(item[0])[0]
        fileURL = item[1]
        driver.get(fileURL)
        parsed_URL = urlparse(driver.current_url)
        site = parsed_URL.netloc
        if site == "pubs.rsc.org":
            sleep(5)
            source = driver.execute_script("return document.getElementsByTagName('html')[0].innerHTML")
            complete_path = os.path.join(outputDir, filename + ".html")
            with open(complete_path, "w") as htmlfile:
                htmlfile.write(source)
