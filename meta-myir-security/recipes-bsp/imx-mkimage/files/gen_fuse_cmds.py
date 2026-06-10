#!/usr/bin/env python3
"""Generate AHAB fuse burning commands for i.MX95 from SRK fuses binary.

Usage: gen_fuse_cmds.py <SRK_fuses.bin> <output_fuse-cmds.txt>

Reads a 64-byte SRK fuses binary (16 x uint32 LE words) and generates
fuse prog commands for i.MX95 banks 16-17, plus ahab_close.
"""

import struct
import sys

WARNING_SRK = """\
# These are One-Time Programmable e-fuses. Once you write them you can't
# go back, so get it right the first time!"""

WARNING_CLOSE = """\
# After the device successfully boots a signed image without generating
# any HAB events, it is safe to secure, or 'close', the device. This is
# the last step in the process. Once the fuse is blown, the chip does
# not load an image that has not been signed using the correct PKI tree.
# Be careful! This is again a One-Time Programmable e-fuse. Once you
# write it you can't go back, so get it right the first time. If
# anything in the previous steps wasn't done correctly, after writing
# this bit, the SOM will not boot anymore!"""


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <SRK_fuses.bin> <fuse-cmds.txt>", file=sys.stderr)
        sys.exit(1)

    fuse_bin = sys.argv[1]
    output_file = sys.argv[2]

    # Read the 64-byte SRK fuses binary
    try:
        with open(fuse_bin, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"ERROR: SRK fuses file not found: {fuse_bin}", file=sys.stderr)
        sys.exit(1)

    if len(data) != 64:
        print(f"ERROR: SRK fuses file must be 64 bytes, got {len(data)}", file=sys.stderr)
        sys.exit(1)

    # Unpack 16 uint32 words (little-endian)
    words = struct.unpack('<16I', data)

    # Build the output
    lines = [WARNING_SRK, ""]

    # Bank 16: SRK hash words 0-7
    for i in range(8):
        lines.append(f"fuse prog -y 16 {i} 0x{words[i]:08X}")

    # Bank 17: SRK hash words 8-15
    for i in range(8):
        lines.append(f"fuse prog -y 17 {i} 0x{words[i+8]:08X}")

    lines.append("")
    lines.append(WARNING_CLOSE)
    lines.append("ahab_close")

    with open(output_file, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print(f"Generated: {output_file}")


if __name__ == '__main__':
    main()
