import serial
import time

# Constants
PAGE_SIZE = 2048  # size of each page in bits
TOTAL_MEMORY = 16777216  # total memory in bits = 2048 KiB ~ 2 MB
NUM_PAGES = TOTAL_MEMORY // PAGE_SIZE  # total number of pages

last_dumped_page = 0

# Setup serial connection
ser = serial.Serial(
    port='/dev/ttyUSB0',
    baudrate=115200,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS,
    timeout=1
)

ser.isOpen()

time.sleep(5)

# Function to write the output of a page to a file
def write_page_to_file(page_number, data):
    filename = f'nand_dump/nand_{page_number}.dmp'
    with open(filename, 'w') as f:
        f.write(data)
        print(f" -> Dumped page {page_number} into {filename}")

# Iterate over each page
for page_number in range(last_dumped_page, NUM_PAGES):
    print(f"[+] offset :{hex(page_number * PAGE_SIZE)}")
    command = f'nand dump {hex(page_number * PAGE_SIZE)}\n'
    ser.write(command.encode())

    # Read the output for the current page
    page_data = ""
    while True:
        out = ser.readline()
        if out:
            page_data += out.decode()
        else:
            break

    # Write the page data to a file
    write_page_to_file(page_number, page_data)

ser.close()
