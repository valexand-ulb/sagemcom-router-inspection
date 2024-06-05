import sys
import threading
import os

INPUT_FILE = sys.argv[1]
OUTPUT_FILE = sys.argv[2]
LINES_PER_FILE = 100000

def process_chunk(start_line, chunk_num, lines):
    outdata = bytearray()
    for line in lines:
        data = line.split()
        for d in data:
            outdata.extend(bytes.fromhex(d))
            
    with open(f"bin{chunk_num}", 'wb') as bin_file:
        bin_file.write(outdata)
    print(f"Chunk {chunk_num} processed and written to bin{chunk_num}")

def concatenate_dmp_files():
    with open(INPUT_FILE, 'r') as input_file:
        threads = []
        chunk_lines = []
        chunk_num = 0
        for i, line in enumerate(input_file, start=1):
            chunk_lines.append(line)
            if i % LINES_PER_FILE == 0:
                chunk_num += 1
                thread = threading.Thread(target=process_chunk, args=(i, chunk_num, chunk_lines))
                threads.append(thread)
                thread.start()
                chunk_lines = []
        
        # Process any remaining lines
        if chunk_lines:
            chunk_num += 1
            thread = threading.Thread(target=process_chunk, args=(i, chunk_num, chunk_lines))
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

    # Concatenate all binary files
    with open(OUTPUT_FILE, 'wb') as output_file:
        for i in range(1, chunk_num + 1):
            bin_filename = f"bin{i}"
            with open(bin_filename, 'rb') as bin_file:
                output_file.write(bin_file.read())
            os.remove(bin_filename)
            print(f"{bin_filename} has been concatenated and removed")

if __name__ == "__main__":
    concatenate_dmp_files()
    print("Concatenation complete. Output file:", OUTPUT_FILE)
