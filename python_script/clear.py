def process_lines(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            stripped_line = line.strip()  # Remove leading and trailing whitespace
            if stripped_line:  # Check if the line is non-empty after stripping
                # Remove the first 10 characters and the last 20 characters
                processed_line = stripped_line[10:-20]
                outfile.write(processed_line + '\n')

# Example usage
input_file = 'mem.dump'
output_file = 'output.txt'
process_lines(input_file, output_file)