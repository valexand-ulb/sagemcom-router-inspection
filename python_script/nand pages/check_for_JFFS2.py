import struct
import sys

INPUT_FILE = sys.argv[1]


# Function to check if the data at the given offset looks like a JFFS2 inode
def is_jffs2_inode(data, offset):
    try:
        # Read the magic number and node type
        magic, nodetype = struct.unpack_from('<HH', data, offset)
        # JFFS2 node types are in the range 0x200-0x208
        if magic == 0x1985 and 0x200 <= nodetype <= 0x208:
            return True
    except struct.error:
        return False
    return False

# Read the NAND dump
with open(INPUT_FILE, 'rb') as f:
    data = f.read()

# Find all occurrences of the JFFS2 magic number
offsets = [i for i in range(len(data)) if data[i:i+2] == b'\x85\x19']

# Check each offset to see if it looks like the start of a JFFS2 inode
jffs2_offsets = [offset for offset in offsets if is_jffs2_inode(data, offset)]

# Print the valid JFFS2 offsets
for offset in jffs2_offsets:
    print(f'Possible JFFS2 offset found at: 0x{offset:X} or {offset}')
