import os
import sys

KEEP_OOB = int(sys.argv[1])

def delete_lines(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    
    # Remove the first two lines, the 131st line, and the last line
    del lines[:2]

    if KEEP_OOB:
        del lines[128]  # 131st line after removing the first two lines
        del lines[-1]
    else:
        del lines[128:]

    # Remove leading tabulation, replace double space by space, replace \n to space
    lines = [line.lstrip('\t').replace('  ', ' ').replace('\n', ' ') for line in lines]

    with open(file_path, 'w') as file:
        file.writelines(lines)

def main():
    # Get the current directory
    current_directory = os.getcwd()

    # List all files in the current directory
    files = os.listdir(current_directory)

    # Iterate over each file
    for file_name in files:
        # Check if the item is a file
        if os.path.isfile(file_name) and file_name.endswith('.dmp'):
            # Delete lines from the file
            delete_lines(file_name)
            print(f"Lines deleted from '{file_name}'")

if __name__ == "__main__":
    main()
