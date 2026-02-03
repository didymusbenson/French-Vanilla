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


# Vertical gap threshold (in points) for paragraph break detection.
# MTR uses ~13pts for same-paragraph line spacing and ~22pts for paragraph breaks.
# 19pts sits cleanly in the dead zone between the two clusters (only 9 hits in
# the 15-21 range across the entire document).
PARAGRAPH_GAP_THRESHOLD = 19


def extract_text_from_pdf(pdf_path):
    """
    Extract text from PDF with layout-aware paragraph detection.

    Groups words into lines by y-position, then uses vertical gaps between
    lines to detect paragraph breaks: gaps > PARAGRAPH_GAP_THRESHOLD become
    \\n\\n, smaller gaps become \\n. This gives clean, reliable paragraph
    boundaries from the PDF layout itself rather than guessing from punctuation.

    Header/footer regions (top/bottom 50 points) are excluded to filter out
    page numbers.
    """
    page_texts = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            page_height = page.height

            # Extract words with bounding boxes
            words = page.extract_words(x_tolerance=3, y_tolerance=3)

            # Filter out header/footer regions
            words = [w for w in words if w['top'] > 50 and w['bottom'] < page_height - 50]

            if not words:
                continue

            # Sort by vertical position, then horizontal
            words.sort(key=lambda w: (w['top'], w['x0']))

            # Group words into lines by y-position (3pt tolerance)
            lines = []  # list of (avg_top, line_text)
            current_line = [words[0]]

            for word in words[1:]:
                if abs(word['top'] - current_line[0]['top']) <= 3:
                    current_line.append(word)
                else:
                    # Flush current line
                    avg_top = sum(w['top'] for w in current_line) / len(current_line)
                    line_text = ' '.join(w['text'] for w in sorted(current_line, key=lambda w: w['x0']))
                    lines.append((avg_top, line_text))
                    current_line = [word]

            # Flush final line
            if current_line:
                avg_top = sum(w['top'] for w in current_line) / len(current_line)
                line_text = ' '.join(w['text'] for w in sorted(current_line, key=lambda w: w['x0']))
                lines.append((avg_top, line_text))

            # Build page text with gap-detected paragraph breaks
            text_parts = []
            prev_top = None
            for top, text in lines:
                if prev_top is not None:
                    gap = top - prev_top
                    text_parts.append('\n\n' if gap > PARAGRAPH_GAP_THRESHOLD else '\n')
                text_parts.append(text)
                prev_top = top

            page_texts.append(''.join(text_parts))

    # Join pages with paragraph break
    full_text = '\n\n'.join(page_texts)

    # Normalize whitespace
    full_text = re.sub(r' +', ' ', full_text)
    full_text = re.sub(r'\n{3,}', '\n\n', full_text)

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
    Clean rule content using layout-detected paragraph breaks.

    Paragraph breaks (\\n\\n) are reliable — they come from vertical spacing
    detection in extract_text_from_pdf(), not punctuation guessing. This lets
    us process each paragraph independently:
    - List paragraphs: continuation lines (wrapping) join to their list item
    - Prose paragraphs: all lines join into a single string

    Content that contains any list items uses \\n between paragraphs (no dash
    dividers in UI). Pure prose uses \\n\\n (dash dividers between paragraphs).
    """
    list_item_pattern = r'^(?:[•\-*◦▪]|\d+\.|\w+\.|\(\d+\)|\([a-z]\))\s+'

    # Split on layout-detected paragraph breaks
    paragraphs = [p.strip() for p in content.split('\n\n') if p.strip()]

    # Determine overall separator: content with lists uses \n (current behavior),
    # pure prose uses \n\n (enables dash dividers in UI)
    all_lines = [l.strip() for p in paragraphs for l in p.split('\n') if l.strip()]
    content_has_lists = any(re.match(list_item_pattern, line) for line in all_lines)

    cleaned = []
    for para in paragraphs:
        lines = [l.strip() for l in para.split('\n') if l.strip()]

        # Filter standalone page numbers
        lines = [l for l in lines if not re.match(r'^\d{1,3}$', l)]
        if not lines:
            continue

        has_list = any(re.match(list_item_pattern, line) for line in lines)

        if has_list:
            # List paragraph: join continuation lines to their list items.
            # Any non-list line before the first bullet is intro text (kept as-is).
            # Any non-list line after a bullet is a wrapped continuation of that bullet.
            items = []
            current_item = None

            for line in lines:
                if re.match(list_item_pattern, line):
                    if current_item is not None:
                        items.append(current_item)
                    current_item = line
                else:
                    if current_item is not None:
                        current_item += ' ' + line
                    else:
                        # Intro text before first list item
                        items.append(line)

            if current_item is not None:
                items.append(current_item)

            cleaned.append('\n'.join(items))
        else:
            # Prose paragraph: join all lines into one string
            cleaned.append(' '.join(lines))

    separator = '\n' if content_has_lists else '\n\n'
    return separator.join(cleaned)


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
