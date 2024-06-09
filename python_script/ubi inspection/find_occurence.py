import os
import subprocess
import sys

def search_keywords(directory, keywords):
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            for keyword in keywords:
                try:
                    # Use grep to search for the keyword in the file
                    result = subprocess.run(['grep', '-H', '-i', keyword, file_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    if result.stdout:
                        print(f"Keyword '{keyword}' found in {file_path}:\n{result.stdout}")
                except Exception as e:
                    print(f"An error occurred while processing file {file_path}: {e}")

if __name__ == "__main__":
    # Set the directory you want to search and the keywords
    directory_to_search = sys.argv[1]
    keywords_to_search = ["root", "password"]
    
    # Run the search
    search_keywords(directory_to_search, keywords_to_search)
