from selenium import webdriver
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.firefox.firefox_profile import FirefoxProfile
from selenium.webdriver.firefox.options import Options
from webdriver_manager.firefox import GeckoDriverManager

import urllib.request

from bs4 import BeautifulSoup

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

url = 'https://www.mpa.gov.sg/who-we-are/newsroom-resources/publications/singapore-nautilus'

# open the url
driver.get(url)
driver.implicitly_wait(100)
html = driver.page_source
soup = BeautifulSoup(html, 'html.parser')

# Retrieve all links
links = soup.find_all('a')

pdfs_list = []
index_list = []

# Loop through the list of urls and find the links which contain 'pdf' characters

for link in links:
    if link.get('href').find('pdf') != -1:
        pdfs_list.append(link.get('href'))
    elif link.get('href').find('index') != -1:
        index_list.append(link.get('href'))

print(pdfs_list)

# for each link in the list of links, add mpa.gov.sg to the beginning of the link and download the pdf
for link in pdfs_list:
    href = 'https://www.mpa.gov.sg' + link
    filename = link.split('/')[-1]
    filename = filename.split('?')[0]
    urllib.request.urlretrieve(href, filename)

driver.quit()