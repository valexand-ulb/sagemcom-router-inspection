import sys

def process_file(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            # Remove the first 10 and the last 20 characters from the line
            processed_line = line[10:-20]
            # Replace every '\n' with '' and every space with ''
            processed_line = processed_line.replace('\n', '').replace(' ', '')
            processed_line = ' '.join(processed_line[i:i+2] for i in range(0, len(processed_line), 2))
            outfile.write(processed_line + '\n')

# Example usage
input_filename = sys.argv[1]
output_filename = sys.argv[2]
process_file(input_filename, output_filename)
