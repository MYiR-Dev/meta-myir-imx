#!/usr/bin/env python3
"""
mx95_gen_csf.py - Generate i.MX95 AHAB CSF file from template.

Usage:
    mx95_gen_csf.py <template> <output>         --srk-table PATH --srk-cert PATH --srk-source-idx N         --flash-bin PATH --container-offset HEX --signature-offset HEX         [--sgk-cert PATH] [--use-sgk]

This script reads the CSF template, substitutes variable placeholders,
and writes the final CSF file for use with NXP CST tool.
"""

import argparse
import os
import re
import sys


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate i.MX95 AHAB CSF from template"
    )
    parser.add_argument("template", help="Path to CSF template file")
    parser.add_argument("output", help="Path for generated CSF output")
    parser.add_argument("--srk-table", required=True, help="Path to SRK table binary")
    parser.add_argument("--srk-cert", required=True, help="Path to SRK certificate PEM")
    parser.add_argument("--srk-source-idx", required=True, type=int,
                        help="SRK source index (0-3)")
    parser.add_argument("--flash-bin", required=True, help="Path to flash.bin to sign")
    parser.add_argument("--container-offset", required=True,
                        help="Container header offset (e.g. 0x400)")
    parser.add_argument("--signature-offset", required=True,
                        help="Signature block offset (e.g. 0x590)")
    parser.add_argument("--sgk-cert", default="",
                        help="Path to SGK certificate PEM (optional)")
    parser.add_argument("--use-sgk", action="store_true",
                        help="Enable SGK subordinate key block")
    return parser.parse_args()


def main():
    args = parse_args()

    if not os.path.isfile(args.template):
        print(f"ERROR: CSF template not found: {args.template}", file=sys.stderr)
        sys.exit(1)

    with open(args.template, 'r') as f:
        template = f.read()

    # Build substitutions
    subs = {
        '@@MYIR_AHAB_SRK_TABLE@@':      args.srk_table,
        '@@MYIR_AHAB_SRK_CERT@@':       args.srk_cert,
        '@@MYIR_AHAB_SRK_SOURCE_IDX@@': str(args.srk_source_idx),
        '@@MYIR_AHAB_SGK_CERT@@':       args.sgk_cert,
        '@@FLASH_BIN_PATH@@':           args.flash_bin,
        '@@CONTAINER_OFFSET@@':         args.container_offset,
        '@@SIGNATURE_OFFSET@@':         args.signature_offset,
    }

    # Remove SGK block if not using SGK
    if not args.use_sgk:
        template = re.sub(
            r'#\+START_SGK_BLOCK.*?#\+END_SGK_BLOCK\n',
            '', template, flags=re.DOTALL
        )

    # Apply substitutions
    for key, value in subs.items():
        template = template.replace(key, str(value))

    # Strip comment-only lines: CST 4.0.1 does NOT support '#' comments
    # before the [Header] section. Only lines starting with '#' are removed;
    # empty lines and section headers are preserved.
    lines = template.split('\n')
    filtered_lines = [line for line in lines if not line.lstrip().startswith('#')]
    template = '\n'.join(filtered_lines).lstrip('\n')

    with open(args.output, 'w') as f:
        f.write(template)

    print(f"Generated CSF: {args.output}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
