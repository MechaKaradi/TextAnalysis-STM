from bs4 import BeautifulSoup

# Load the HTML file
with open('printviewfile.htm', 'rb') as f:
    html = f.read()

# Parse the HTML using BeautifulSoup
soup = BeautifulSoup(html, 'html.parser')

# Find all the h1 tags and split the document based on them

# Find all the div tags with id='ft_container' and extract their content into a list
ft_container_tags = soup.find_all('div', id='ft_container')
docs = []

'''
Document Structure:
    Heading: 
    Full Text: ID = fullTextHeader
        Replace <p> tags with nothing 
        and closing </p> tags with a newline

'''
for i in range(len(ft_container_tags)):
    # extract everything within the div tag
    doc_html = str(ft_container_tags[i])
    # parse the extracted content
    doc_soup = BeautifulSoup(doc_html, 'html.parser')
    # from the parsed content, extract the text from the h1 tag
    doc_title = doc_soup.find('h1').text
    # from the parsed content, extract the text from the text tag
    doc_text = str(doc_soup.find('text'))
    # remove all the tags from the text
    doc_text = BeautifulSoup(doc_text,'html.parser').text

    docs.append(doc_text)

# create a save location
save_location = 'textfiles\\'

# save each document to a text file in the save location
for i in range(len(docs)):
    with open(f'{save_location}doc{i}.txt', mode='w', encoding='utf-8') as f:
        f.write(docs[i])