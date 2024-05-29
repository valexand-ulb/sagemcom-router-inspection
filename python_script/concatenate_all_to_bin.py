import binascii
import os
import re

# Function to extract the number from the file name
def extract_number(file_name):
    match = re.search(r'(\d+)\.dmp$', file_name)
    return int(match.group(1)) if match else float('inf')

# Function to concatenate .dmp files
def concatenate_dmp_files():
    # Get list of .dmp files in current directory
    dmp_files = [file for file in os.listdir() if file.endswith('.dmp')]
    dmp_files.sort(key=extract_number)  # Sort the files by the extracted number
    
    with open('concatenated.bin', 'wb') as output_file:
        for dmp_file in dmp_files:
            print(f"Concatenation of {dmp_file}")
            with open(dmp_file, 'r') as input_file:
                hex_data = input_file.read().replace(" ", "").replace("\n", "")
                binary_data = binascii.unhexlify(hex_data)
                output_file.write(binary_data)

if __name__ == "__main__":
    concatenate_dmp_files()
    print("Concatenation complete. Output file: concatenated.bin")
