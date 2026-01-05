#!/usr/bin/env python3
"""
Parse Magic: The Gathering Comprehensive Rules into structured JSON files.

This script splits the comprehensive_rules.md file into digestible chunks:
- Index/Table of Contents
- 9 main sections (1. Game Concepts through 9. Casual Variants)
- Glossary
- Credits

Output files are created in the docs/rulesdocs directory as JSON.
Re-running the script will overwrite existing files.
"""

import json
import os
import re
from pathlib import Path
from typing import Dict, List, Tuple


def find_section_boundaries(lines: List[str]) -> Dict[str, Tuple[int, int]]:
    """
    Find the line boundaries for each section in the comprehensive rules.

    Returns a dictionary mapping section names to (start_line, end_line) tuples.
    Line numbers are 0-indexed.
    """
    boundaries = {}

    # Find Glossary and Credits first (we need these to limit our search)
    glossary_line = None
    credits_line = None

    for i, line in enumerate(lines):
        if i > 6000 and line.strip() == "Glossary" and glossary_line is None:
            glossary_line = i
        if i > 9000 and line.strip() == "Credits" and credits_line is None:
            credits_line = i

    print(f"  Glossary starts at line {glossary_line + 1 if glossary_line else 'NOT FOUND'}")
    print(f"  Credits starts at line {credits_line + 1 if credits_line else 'NOT FOUND'}")

    # Find where actual content starts (look for "1. Game Concepts")
    first_section_line = None
    for i in range(180, min(300, len(lines))):
        if re.match(r'^1\. Game Concepts$', lines[i].strip()):
            first_section_line = i
            break

    # Index is everything before the first section
    if first_section_line is not None:
        boundaries['index'] = (0, first_section_line - 1)

    # Define the exact section names we're looking for
    expected_sections = {
        1: "Game Concepts",
        2: "Parts of a Card",
        3: "Card Types",
        4: "Zones",
        5: "Turn Structure",
        6: "Spells, Abilities, and Effects",
        7: "Additional Rules",
        8: "Multiplayer Rules",
        9: "Casual Variants"
    }

    # Find all 9 main sections (only search up to glossary)
    section_starts = []
    search_limit = glossary_line if glossary_line else len(lines)

    for i in range(first_section_line if first_section_line else 180, search_limit):
        line_stripped = lines[i].strip()

        # Try to match each expected section
        for section_num, section_name in expected_sections.items():
            if line_stripped == f"{section_num}. {section_name}":
                section_starts.append((i, section_num, section_name))
                print(f"  Found section {section_num} at line {i + 1}: {section_name}")
                break

    # Sort by section number
    section_starts.sort(key=lambda x: x[1])

    # Verify we found all 9 sections
    if len(section_starts) != 9:
        print(f"  WARNING: Found {len(section_starts)} sections, expected 9")

    # Create boundaries for each section
    for idx, (start_line, section_num, section_name) in enumerate(section_starts):
        # Determine end line
        if idx + 1 < len(section_starts):
            end_line = section_starts[idx + 1][0] - 1
        elif glossary_line is not None:
            end_line = glossary_line - 1
        else:
            end_line = len(lines) - 1

        boundaries[f'section_{section_num}'] = (start_line, end_line)

    # Add Glossary
    if glossary_line is not None and credits_line is not None:
        boundaries['glossary'] = (glossary_line, credits_line - 1)

    # Add Credits
    if credits_line is not None:
        boundaries['credits'] = (credits_line, len(lines) - 1)

    return boundaries


def extract_metadata(lines: List[str]) -> Dict[str, str]:
    """Extract metadata from the first few lines of the file."""
    metadata = {}

    # Look for effective date
    for line in lines[:10]:
        match = re.search(r'effective as of (.+)\.', line)
        if match:
            metadata['effective_date'] = match.group(1)

    return metadata


def parse_rules_file(input_path: str, output_dir: str):
    """
    Parse the comprehensive rules file and output structured JSON files.

    Args:
        input_path: Path to comprehensive_rules.md
        output_dir: Directory to output JSON files (will be created if needed)
    """
    # Read the input file
    print(f"Reading {input_path}...")
    with open(input_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Strip newlines but preserve empty lines
    lines = [line.rstrip('\n\r') for line in lines]

    print(f"Total lines: {len(lines)}")

    # Extract metadata
    metadata = extract_metadata(lines)
    print(f"Effective date: {metadata.get('effective_date', 'Unknown')}")

    # Find section boundaries
    print("Finding section boundaries...")
    boundaries = find_section_boundaries(lines)

    print(f"Found {len(boundaries)} sections:")
    for name, (start, end) in sorted(boundaries.items(), key=lambda x: x[1][0]):
        print(f"  {name}: lines {start+1}-{end+1} ({end-start+1} lines)")

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    # Process each section
    section_titles = {
        'index': 'Table of Contents',
        'section_1': '1. Game Concepts',
        'section_2': '2. Parts of a Card',
        'section_3': '3. Card Types',
        'section_4': '4. Zones',
        'section_5': '5. Turn Structure',
        'section_6': '6. Spells, Abilities, and Effects',
        'section_7': '7. Additional Rules',
        'section_8': '8. Multiplayer Rules',
        'section_9': '9. Casual Variants',
        'glossary': 'Glossary',
        'credits': 'Credits'
    }

    for section_name, (start_line, end_line) in boundaries.items():
        # Extract content
        content = '\n'.join(lines[start_line:end_line + 1])

        # Create JSON structure
        json_data = {
            'title': section_titles.get(section_name, section_name),
            'section_key': section_name,
            'metadata': metadata,
            'line_range': {
                'start': start_line + 1,  # Convert to 1-indexed for readability
                'end': end_line + 1
            },
            'content': content
        }

        # Write to file
        output_file = os.path.join(output_dir, f'{section_name}.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)

        print(f"Created {output_file}")

    print("\nParsing complete!")
    print(f"Output files written to {output_dir}")


def main():
    """Main entry point for the script."""
    # Determine paths relative to script location
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    input_file = project_root / 'docs' / 'rulesdocs' / 'comprehensive_rules.md'
    output_dir = project_root / 'docs' / 'rulesdocs'

    if not input_file.exists():
        print(f"Error: Input file not found: {input_file}")
        return 1

    parse_rules_file(str(input_file), str(output_dir))
    return 0


if __name__ == '__main__':
    exit(main())
