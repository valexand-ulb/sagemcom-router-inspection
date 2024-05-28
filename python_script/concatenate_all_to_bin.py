import os
import binascii

# Function to concatenate .dmp files
def concatenate_dmp_files():
    # Get list of .dmp files in current directory
    dmp_files = [file for file in os.listdir() if file.endswith('.dmp')]
    dmp_files.sort()  # Sort the files to maintain order
    
    with open('concatenated.bin', 'wb') as output_file:
        for dmp_file in dmp_files:
            with open(dmp_file, 'r') as input_file:
                hex_data = input_file.read().replace(" ", "").replace("\n", "")
                binary_data = binascii.unhexlify(hex_data)
                output_file.write(binary_data)

if __name__ == "__main__":
    concatenate_dmp_files()
    print("Concatenation complete. Output file: concatenated.bin")
