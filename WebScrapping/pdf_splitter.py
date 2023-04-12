# Divide a PDF into multiple PDFs, one page per PDF
import os
import PyPDF2

# Set the path to the folder containing the PDF files
folder_path = "NautilusPDFs"

# Loop through each file in the folder
for filename in os.listdir(folder_path):
    # Check if the file is a PDF file
    if filename.endswith('.pdf'):
        # Open the PDF file in read binary mode
        pdf_file = open(os.path.join(folder_path, filename), 'rb')

        # Create a PDF reader object
        pdf_reader = PyPDF2.PdfFileReader(pdf_file)

        # Loop through each page in the PDF file
        for page in range(pdf_reader.numPages):
            # Create a PDF writer object
            pdf_writer = PyPDF2.PdfFileWriter()

            # Add the current page to the writer object
            pdf_writer.addPage(pdf_reader.getPage(page))

            # Create a new PDF file with the current page
            output_pdf = open(os.path.join(f'{folder_path}\\splitfiles', f'{os.path.splitext(filename)[0]}_page_{page+1}.pdf'), 'wb')

            # Write the PDF file to disk
            pdf_writer.write(output_pdf)

            # Close the output PDF file
            output_pdf.close()

        # Close the input PDF file
        pdf_file.close()