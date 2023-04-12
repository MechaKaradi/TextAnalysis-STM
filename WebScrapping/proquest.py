from selenium import webdriver
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.firefox_profile import FirefoxProfile
from selenium.webdriver.firefox.options import Options
from webdriver_manager.firefox import GeckoDriverManager

import pandas as pd

import time
import os
# from PyPDF2 import PdfFileMerger

# Set up Firefox profile to use the "TU Delft" container

# Set up Firefox driver option to allow donloading pdfs
firefox_options = Options()
firefox_options.set_preference("privacy.container.name", "TU Delft")
firefox_options.set_preference("privacy.container.showContainerName", True)
firefox_options.set_preference("pdfjs.disabled", True)
firefox_options.set_preference("browser.download.folderList", 2)
firefox_options.set_preference("browser.download.manager.showWhenStarting", False)
firefox_options.set_preference("browser.download.dir", os.getcwd())
firefox_options.set_preference("browser.helperApps.neverAsk.saveToDisk", "application/pdf")

#initialize driver
driver = webdriver.Firefox(service=FirefoxService(GeckoDriverManager().install()), options=firefox_options)

# Import csv as dataframe
document_list = pd.read_csv('data/ProQuestDocuments-2023-03-08.csv', encoding='windows-1252')
url_list = document_list['DocumentURL']

print(url_list)

# Loop through the list of urls
for url in url_list:
    driver.get(url)
    time.sleep(5)
    # Retrieve the full text of the document
    full_text = driver.find_element('id', 'FullText').text
    time.sleep(5)
