#!/usr/bin/env python3
"""
Parse Magic Tournament Rules (MTR) PDF into structured JSON.

This script uses pdfplumber for clean text extraction with proper
paragraph and list formatting.

Outputs JSON files to assets/judgedocs/
"""

import json
import re
from pathlib import Path
import pdfplumber


def extract_text_from_pdf(pdf_path):
    """
    Extract text from PDF using pdfplumber.

    Returns clean text with proper paragraph breaks and list formatting.
    Filters out page numbers by excluding text in header/footer regions.
    """
    text_parts = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            # Get page dimensions to calculate header/footer regions
            page_height = page.height

            # Define header/footer margins (top 50 points, bottom 50 points)
            # Page numbers typically appear in these regions
            header_threshold = 50
            footer_threshold = page_height - 50

            # Filter characters to exclude header/footer regions
            def not_in_header_footer(obj):
                # obj is a char dict with 'top' and 'bottom' keys
                return obj['top'] > header_threshold and obj['bottom'] < footer_threshold

            # Crop page to exclude header/footer, then extract text
            cropped_page = page.filter(not_in_header_footer)
            page_text = cropped_page.extract_text(layout=True, x_tolerance=3, y_tolerance=3)

            if page_text:
                text_parts.append(page_text)

    # Join pages with double newline
    full_text = '\n\n'.join(text_parts)

    # Clean up common PDF artifacts
    # Remove excessive whitespace while preserving paragraph structure
    full_text = re.sub(r' +', ' ', full_text)  # Multiple spaces to single
    full_text = re.sub(r'\n{4,}', '\n\n', full_text)  # Excessive newlines to double

    return full_text.strip()


def extract_metadata(text):
    """Extract metadata from the document header."""
    metadata = {}

    # Extract effective date (e.g., "Effective November 10, 2025")
    date_match = re.search(r'Effective\s+([A-Z][a-z]+\s+\d{1,2},\s+\d{4})', text)
    if date_match:
        metadata['effective_date'] = date_match.group(1)

    return metadata


def parse_table_of_contents(text):
    """
    Parse the table of contents to identify section boundaries.

    Returns dict mapping section identifiers to their titles.
    For numbered sections: integer keys (1-10)
    For appendices: string keys ("A"-"F")
    """
    sections = {}

    # Look for numbered sections like "       1. Tournament Fundamentals .....5"
    # Allow for leading whitespace
    toc_pattern = r'^\s*(\d+)\.\s+([A-Za-z\s/\-]+?)\s*\.{2,}'

    for match in re.finditer(toc_pattern, text, re.MULTILINE):
        section_num = int(match.group(1))
        section_title = match.group(2).strip()

        # Only include main sections (1-99)
        if section_num >= 1 and section_num <= 99:
            sections[section_num] = section_title

    # Look for appendices like "       Appendix A—Changes From Previous Versions  ....."
    # Note: Some have space after em dash, some don't
    # Allow for leading whitespace
    appendix_pattern = r'^\s*Appendix\s+([A-F])\s*[—–-]\s*([^.]+?)\s*\.{2,}'

    for match in re.finditer(appendix_pattern, text, re.MULTILINE):
        appendix_letter = match.group(1)
        appendix_title = match.group(2).strip()
        sections[appendix_letter] = appendix_title

    return sections


def clean_rule_content(content):
    """
    Clean up PDF line break artifacts in rule content.

    Preserves paragraph breaks (double newlines) and list formatting,
    but removes mid-sentence line breaks that are PDF layout artifacts.
    Also strips page numbers.
    """
    # First, normalize paragraph breaks
    # Replace any sequence of whitespace with newlines to double newline
    content = re.sub(r'\n\s*\n', '\n\n', content)

    # Split into paragraphs
    paragraphs = content.split('\n\n')

    cleaned_paragraphs = []
    for para in paragraphs:
        # Check if this paragraph contains list items
        lines = para.split('\n')

        # List item patterns:
        # - Bullets: •, -, *, ◦, ▪
        # - Numbered: 1., 2., a., b., (1), (a), etc.
        list_item_pattern = r'^\s*(?:[•\-*◦▪]|\d+\.|\w+\.|\(\d+\)|\([a-z]\))\s+'

        # Check if any line starts with a list marker
        has_list_items = any(re.match(list_item_pattern, line) for line in lines)

        if has_list_items:
            # This is a list paragraph - preserve list structure
            cleaned_lines = []
            current_item = []

            for line in lines:
                line = line.strip()
                if not line:
                    continue

                # Check if line contains multiple list items (two-column layout)
                # After PDF processing, columns are separated by just " • " (single space + bullet + space)
                # Look for bullet markers in the middle of the line
                multi_item_split = re.split(r'\s+([•\-*◦▪])\s+', line)
                # Filter out empty parts and recombine with bullets
                multi_item_parts = []
                for i in range(0, len(multi_item_split), 2):
                    if i == 0 and multi_item_split[i].strip():
                        # First part (already has bullet if it's a list item)
                        multi_item_parts.append(multi_item_split[i].strip())
                    elif i > 0 and i < len(multi_item_split):
                        # Later parts - need to add back the bullet
                        content = multi_item_split[i].strip()
                        if content and i - 1 < len(multi_item_split):
                            bullet = multi_item_split[i - 1]
                            multi_item_parts.append(f"{bullet} {content}")

                if len(multi_item_parts) > 1:
                    # This line has multiple items (two-column layout)
                    # Process each part as a separate list item
                    for part in multi_item_parts:
                        # Skip if empty or just a bullet
                        if not part or part in '•-*◦▪':
                            continue

                        # Save previous item if exists
                        if current_item:
                            cleaned_lines.append(' '.join(current_item))
                            current_item = []

                        # Check if part already has a bullet, if not add one
                        if re.match(list_item_pattern, part):
                            current_item = [part]
                        else:
                            # Add bullet to part
                            current_item = [f"• {part}"]
                else:
                    # Single item per line (normal case)
                    # Check if this line starts a new list item
                    if re.match(list_item_pattern, line):
                        # Save previous item if exists
                        if current_item:
                            cleaned_lines.append(' '.join(current_item))
                        # Start new item
                        current_item = [line]
                    else:
                        # Continuation of current item
                        if current_item:
                            current_item.append(line)
                        else:
                            # Not in a list item yet, treat as regular line
                            cleaned_lines.append(line)

            # Don't forget the last item
            if current_item:
                cleaned_lines.append(' '.join(current_item))

            # Join list items with single newlines
            para = '\n'.join(cleaned_lines)
        else:
            # Regular paragraph - join all lines with spaces
            para = re.sub(r'\n', ' ', para)

        # Clean up multiple spaces
        para = re.sub(r' +', ' ', para)
        para = para.strip()

        # Skip if this is just a page number (1-3 digits)
        if para and not re.match(r'^\d{1,3}$', para):
            cleaned_paragraphs.append(para)

    # Join paragraphs with double newline
    return '\n\n'.join(cleaned_paragraphs)


def parse_rules_in_section(section_text, section_num):
    """
    Parse individual rules within a section.

    Rules are numbered like 1.1, 1.2, etc.
    Returns list of rule dicts with number, title, and content.
    """
    rules = []

    # Pattern: rule number (e.g., "       1.1  Tournament Types"), with leading whitespace
    # IMPORTANT: Exclude TOC entries which have dots (e.g., "         1.1 Tournament Types .....5")
    rule_pattern = rf'^\s*{section_num}\.(\d+)\s+([^\n]+)'

    # Find all rule starts (excluding TOC entries)
    rule_starts = []
    for match in re.finditer(rule_pattern, section_text, re.MULTILINE):
        title = match.group(2).strip()

        # Skip TOC entries (they have multiple dots like "......" followed by page number)
        if re.search(r'\.{3,}', title):
            continue

        # Get end position (after the newline following the title)
        title_end = match.end()

        rule_starts.append({
            'pos': match.start(),
            'title_end': title_end,
            'number': f"{section_num}.{match.group(1)}",
            'title': title
        })

    # Extract content between rule starts
    for i, rule_start in enumerate(rule_starts):
        # Get content from after the title line to next rule (or end of section)
        content_start = rule_start['title_end']
        if i + 1 < len(rule_starts):
            content_end = rule_starts[i + 1]['pos']
        else:
            content_end = len(section_text)

        content = section_text[content_start:content_end].strip()

        # Clean up PDF line break artifacts
        content = clean_rule_content(content)

        rules.append({
            'number': rule_start['number'],
            'title': rule_start['title'],
            'content': content
        })

    return rules


def split_into_sections(text, section_titles):
    """
    Split the cleaned text into individual sections and appendices.

    Returns dict mapping section identifiers (int or str) to their full text content.
    """
    sections = {}

    # Find each section/appendix header in the text
    # IMPORTANT: Skip TOC entries which have dots
    section_starts = []

    for section_id, section_title in section_titles.items():
        # Determine pattern based on whether it's a number or letter
        # Allow for leading whitespace
        if isinstance(section_id, int):
            # Numbered section: "1. Tournament Fundamentals"
            pattern = rf'^\s*{section_id}\.\s+{re.escape(section_title)}(.*)$'
        else:
            # Appendix: "Appendix A—Changes From Previous Versions"
            # Note: Some have space after em dash, some don't
            pattern = rf'^\s*Appendix\s+{section_id}\s*[—–-]\s*{re.escape(section_title)}(.*)$'

        for match in re.finditer(pattern, text, re.MULTILINE | re.IGNORECASE):
            rest_of_line = match.group(1)

            # Skip if this is a TOC entry (has dots)
            if re.search(r'\.{3,}', rest_of_line):
                continue

            section_starts.append({
                'id': section_id,
                'title': section_title,
                'pos': match.start()
            })
            break  # Only take the first non-TOC match

    # Sort by position
    section_starts.sort(key=lambda x: x['pos'])

    # Extract text for each section
    for i, section_start in enumerate(section_starts):
        start_pos = section_start['pos']

        # End is either the start of the next section or end of document
        if i + 1 < len(section_starts):
            end_pos = section_starts[i + 1]['pos']
        else:
            end_pos = len(text)

        section_text = text[start_pos:end_pos].strip()
        sections[section_start['id']] = {
            'title': section_start['title'],
            'text': section_text
        }

    return sections


def main():
    """Main entry point."""
    script_dir = Path(__file__).parent
    data_dir = script_dir / 'data' / 'judge_docs'
    output_dir = script_dir.parent / 'assets' / 'judgedocs'

    mtr_pdf_path = data_dir / 'MTR.pdf'

    print("=" * 80)
    print("MTR Parser (pdfplumber)")
    print("=" * 80)
    print()

    # Check if input file exists
    if not mtr_pdf_path.exists():
        print(f"ERROR: MTR.pdf not found at {mtr_pdf_path}")
        print("Run update_judge_docs.py first to download the file.")
        return 1

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Extract text from PDF
    print(f"Extracting text from {mtr_pdf_path}...")
    text = extract_text_from_pdf(mtr_pdf_path)
    print(f"  Extracted: {len(text)} characters")

    # Extract metadata
    print("Extracting metadata...")
    metadata = extract_metadata(text)
    print(f"  Effective date: {metadata.get('effective_date', 'Unknown')}")

    # Parse table of contents to identify sections
    print("Parsing table of contents...")
    section_titles = parse_table_of_contents(text)
    print(f"  Found {len(section_titles)} sections:")
    # Sort: numbers first, then letters
    sorted_items = sorted(section_titles.items(), key=lambda x: (isinstance(x[0], str), x[0]))
    for section_id, title in sorted_items:
        if isinstance(section_id, int):
            print(f"    {section_id}. {title}")
        else:
            print(f"    Appendix {section_id}: {title}")

    # Split into sections
    print("\nSplitting into sections...")
    sections = split_into_sections(text, section_titles)
    print(f"  Extracted {len(sections)} section texts")

    # Parse rules in each section
    print("\nParsing sections...")
    parsed_sections = []

    # Sort: numbers first, then letters
    sorted_keys = sorted(sections.keys(), key=lambda x: (isinstance(x, str), x))

    for section_id in sorted_keys:
        section_data = sections[section_id]
        section_title = section_data['title']
        section_text = section_data['text']

        if isinstance(section_id, int):
            # Numbered section - parse rules
            rules = parse_rules_in_section(section_text, section_id)
            print(f"  Section {section_id}: {section_title}")
            print(f"    → {len(rules)} rules")

            parsed_sections.append({
                'section_number': section_id,
                'title': f"{section_id}. {section_title}",
                'section_key': f"mtr_section_{section_id}",
                'metadata': metadata,
                'rules': rules
            })
        else:
            # Appendix - just store plain content as a single "rule"
            print(f"  Appendix {section_id}: {section_title}")
            print(f"    → appendix content")

            # Clean up PDF line break artifacts in appendix content
            cleaned_content = clean_rule_content(section_text)

            # Store appendix as a section with one "rule" containing all content
            parsed_sections.append({
                'section_number': section_id,  # Will be "A", "B", etc.
                'title': f"Appendix {section_id}—{section_title}",
                'section_key': f"mtr_appendix_{section_id.lower()}",
                'metadata': metadata,
                'rules': [{
                    'number': section_id,
                    'title': section_title,
                    'content': cleaned_content
                }]
            })

    # Write output files
    print("\nWriting JSON files...")

    # Write index file
    index_data = {
        'title': 'Magic Tournament Rules',
        'document_type': 'mtr',
        'metadata': metadata,
        'sections': [
            {
                'section_number': s['section_number'],
                'title': s['title'],
                'section_key': s['section_key'],
                'rule_count': len(s['rules'])
            }
            for s in parsed_sections
        ]
    }

    index_path = output_dir / 'mtr_index.json'
    with open(index_path, 'w', encoding='utf-8') as f:
        json.dump(index_data, f, indent=2, ensure_ascii=False)
    print(f"  ✓ {index_path}")

    # Write individual section files
    for section_data in parsed_sections:
        section_key = section_data['section_key']
        section_path = output_dir / f"{section_key}.json"

        with open(section_path, 'w', encoding='utf-8') as f:
            json.dump(section_data, f, indent=2, ensure_ascii=False)

        print(f"  ✓ {section_path}")

    print()
    print("=" * 80)
    print("✓ MTR parsing complete!")
    print(f"  Output: {output_dir}")
    print(f"  Files: mtr_index.json + {len(parsed_sections)} section files")
    print("=" * 80)
    print()

    return 0


if __name__ == '__main__':
    exit(main())
