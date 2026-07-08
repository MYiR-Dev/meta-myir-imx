#!/usr/bin/env python3
"""
inject-tee-its.py — Inject OP-TEE loadable into fitImage ITS file.

Reads an existing FIT ITS (Device Tree Source) file, inserts an OP-TEE
image node in the images section, and adds loadables = "tee-1" to every
configuration node.

Usage:
    python3 inject-tee-its.py <its_file> [tee_node_name] [tee_load_addr] [tee_bin_path]

Defaults:
    tee_node_name  = "tee-1"
    tee_load_addr  = "0x84000000"
    tee_bin_path   = "./tee.bin"
"""

import sys
import re


def find_closing_brace(lines, start_idx):
    """Find the line index of the matching closing brace for the block
    that starts at start_idx (which must point to a '{' line)."""
    depth = 0
    for i in range(start_idx, len(lines)):
        stripped = lines[i].strip()
        depth += stripped.count('{') - stripped.count('}')
        if depth <= 0:
            return i
    return len(lines) - 1


def find_section_blocks(lines):
    """Find the 'images {' and 'configurations {' sections.
    Returns (images_start, images_end, configs_start, configs_end) as line indices.
    """
    images_start = images_end = None
    configs_start = configs_end = None

    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.endswith('images {') or stripped.endswith('images{'):
            images_start = i
            images_end = find_closing_brace(lines, i)
        elif stripped.endswith('configurations {') or stripped.endswith('configurations{'):
            configs_start = i
            configs_end = find_closing_brace(lines, i)

    return images_start, images_end, configs_start, configs_end


def inject_tee(its_file, tee_name='tee-1', tee_load='0x84000000', tee_bin='./tee.bin'):
    """Inject OP-TEE node into ITS file."""

    with open(its_file, 'r') as f:
        content = f.read()

    lines = content.split('\n')

    # Find section boundaries
    im_start, im_end, cfg_start, cfg_end = find_section_blocks(lines)

    if im_start is None:
        print(f'ERROR: Could not find images section in {its_file}')
        sys.exit(1)
    if cfg_start is None:
        print(f'ERROR: Could not find configurations section in {its_file}')
        sys.exit(1)

    # Detect indentation from first image entry
    img_indent = '\t\t'
    for i in range(im_start + 1, im_end):
        stripped = lines[i].strip()
        if stripped and not stripped.startswith('/*') and not stripped.startswith('#'):
            # Count leading tabs
            tabs = len(lines[i]) - len(lines[i].lstrip('\t'))
            img_indent = '\t' * tabs
            break

    cfg_indent = '\t\t\t'
    for i in range(cfg_start + 1, cfg_end):
        stripped = lines[i].strip()
        if stripped and stripped.startswith('kernel ='):
            tabs = len(lines[i]) - len(lines[i].lstrip('\t'))
            cfg_indent = '\t' * tabs
            break

    # Strip leading ./ from bin path for incbin
    tee_bin_clean = tee_bin.lstrip("./")
    # Build TEE image node
    tee_node = f'''{img_indent}{tee_name} {{
{img_indent}\tdescription = "OP-TEE";
{img_indent}\tdata = /incbin/("{tee_bin_clean}");
{img_indent}\ttype = "tee";
{img_indent}\tarch = "arm";
{img_indent}\tos = "tee";
{img_indent}\tcompression = "none";
{img_indent}\tload = <{tee_load}>;
{img_indent}\tentry = <{tee_load}>;
{img_indent}}};'''

    # Insert TEE node at the end of the images section (before closing brace)
    insert_pos = im_end  # Position of images section closing '};'
    lines.insert(insert_pos, tee_node)

    # Adjust indices after insertion
    cfg_start += 1
    cfg_end += 1

    # Add loadables = tee-1 to each configuration
    new_lines = []
    for i, line in enumerate(lines):
        new_lines.append(line)
        # After kernel = kernel-1; add loadables
        stripped = line.strip()
        if cfg_start <= i <= cfg_end:
            if 'kernel =' in stripped:
                new_lines.append(f'{cfg_indent}loadables = "{tee_name}";')

    result = '\n'.join(new_lines)
    with open(its_file, 'w') as f:
        f.write(result)

    print(f'Injected {tee_name} into {its_file}')
    print(f'  load address: {tee_load}')
    print(f'  binary: {tee_bin}')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} <its_file> [tee_name] [load_addr] [tee_bin]')
        sys.exit(1)

    its_file = sys.argv[1]
    tee_name = sys.argv[2] if len(sys.argv) > 2 else 'tee-1'
    tee_load = sys.argv[3] if len(sys.argv) > 3 else '0x84000000'
    tee_bin = sys.argv[4] if len(sys.argv) > 4 else './tee.bin'

    inject_tee(its_file, tee_name, tee_load, tee_bin)
