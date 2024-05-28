# Number of blocks and sectors per block
blocks = 32
sectors_per_block = 512
sector_size = 0x1000  # Each sector is 4096 bytes (0x1000 in hexadecimal)

# Iterate over each block
for block in range(blocks):
    print(f"Block {block}:")
    # Iterate over each sector in the block
    for sector in range(sectors_per_block):
        start_address = (block * sectors_per_block + sector) * sector_size
        end_address = start_address + sector_size - 1
        print(f"  Sector {sector}: Address range {start_address:06X}h - {end_address:06X}h")
    print()
