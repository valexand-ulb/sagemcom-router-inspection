import os

def check_dmp_files(directory, min_lines=140):
    # List all files in the given directory
    files = os.listdir(directory)
    # Filter out only .dmp files
    dmp_files = [f for f in files if f.endswith('.dmp')]
    
    # Iterate through each .dmp file
    for dmp_file in dmp_files:
        file_path = os.path.join(directory, dmp_file)
        
        # Open the file and count the number of lines
        with open(file_path, 'r') as file:
            line_count = sum(1 for line in file)
            
            # Check if the file has at least the minimum number of lines
            if line_count < min_lines:
                print(f"File '{dmp_file}' has only {line_count} lines. It should have at least {min_lines} lines.")
            elif line_count > min_lines:
                print(f"File '{dmp_file}' has {line_count} lines. It should have at least {min_lines} lines. Mayber corrupted block")

# Use the current directory
current_directory = os.getcwd()
check_dmp_files(current_directory)
