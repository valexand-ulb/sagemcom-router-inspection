import sys

def write_all_lines_as_binary_file(source_file_path, output_file_path):
    # Open the source file for reading
    with open(source_file_path, 'r', encoding='utf-8-sig') as source_file:
        with open(output_file_path, 'wb') as output_file:
            for line_number, line in enumerate(source_file, start=1):
                # Clean and prepare the line (strip any extra whitespace)
                line = line[10:49].strip()
                
                # Remove any non-hexadecimal characters (keeping spaces for formatting purposes)
                hex_chars = '0123456789abcdefABCDEF '
                line = ''.join(filter(lambda x: x in hex_chars, line))
                
                try:
                    # Convert the cleaned hexadecimal string to binary data
                    binary_data = bytes.fromhex(line.replace(' ', ''))
                    
                    # Write the binary data to the output file
                    output_file.write(binary_data)
                except ValueError as e:
                    print(f"Skipping line {line_number}: {e}")
    
    print(f"Processed {line_number} lines. Binary data is stored in '{output_file_path}'.")

# Example usage
source_file_path = sys.argv[1]
output_file_path = sys.argv[2]
write_all_lines_as_binary_file(source_file_path, output_file_path)
