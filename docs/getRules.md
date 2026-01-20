# Updating the Comprehensive Rules

The comprehensive rules for Magic: The Gathering are found at https://magic.wizards.com/en/rules.

## Step-by-Step Update Process

### 1. Find the Latest Rules URL

Visit https://magic.wizards.com/en/rules and find the hyperlink labeled "TXT" that links to a `.txt` file containing the comprehensive rules.

**Note**: The URL typically follows this pattern:
```
https://media.wizards.com/YYYY/downloads/MagicCompRules YYYYMMDD.txt
```
where YYYY is the year and YYYYMMDD is the date (e.g., `20260116` for January 16, 2026).

### 2. Download the Rules File

Use `curl` to download the file. **Important**: The URL contains spaces, so you must URL-encode them as `%20`:

```bash
curl -o docs/rulesdocs/comprehensive_rules.txt "https://media.wizards.com/YYYY/downloads/MagicCompRules%20YYYYMMDD.txt"
```

Replace `YYYY` and `YYYYMMDD` with the actual year and date from the URL.

### 3. Fix Line Endings (CRITICAL)

The downloaded file will have Windows/mixed line endings (CR/CRLF) that the parser cannot handle. You **must** convert to Unix line endings (LF):

```bash
# Rename to .md extension
mv docs/rulesdocs/comprehensive_rules.txt docs/rulesdocs/comprehensive_rules.md

# Convert line endings from CR to LF
tr '\r' '\n' < docs/rulesdocs/comprehensive_rules.md > docs/rulesdocs/comprehensive_rules_fixed.md && mv docs/rulesdocs/comprehensive_rules_fixed.md docs/rulesdocs/comprehensive_rules.md
```

**Verify the line count** (should be ~9,200-9,300 lines, not 12):
```bash
wc -l docs/rulesdocs/comprehensive_rules.md
```

If you see only 12 lines, the line endings weren't converted properly. Repeat step 3.

### 4. Run the Parser

Execute the parsing script to generate the 12 JSON files:

```bash
python3 scripts/parse_rules.py
```

The script will output:
- Effective date (verify this matches the latest rules date)
- Total lines parsed (should be ~9,200-9,300)
- Section boundaries found
- Confirmation that 12 JSON files were created

### 5. Verify the Update

Check that the new rules are included:

```bash
# Check effective date in credits
grep "effective_date" docs/rulesdocs/credits.json

# Verify a recent rule exists (e.g., rule 701.68 "Blight" added January 2026)
grep -n "701\.68" docs/rulesdocs/comprehensive_rules.md
```

### 6. Clean Up

The only file needed in the repository is `comprehensive_rules.md`. The generated JSON files are created by the parser and should be committed with the update.

## Common Pitfalls

### Problem: Parser shows only 12 lines instead of ~9,200
**Cause**: File has Windows line endings (CR or CRLF)
**Solution**: Re-run step 3 to convert line endings

### Problem: URL download fails with "Malformed input to a URL function"
**Cause**: Spaces in URL aren't URL-encoded
**Solution**: Replace spaces with `%20` in the curl command

### Problem: Parser can't find section boundaries
**Cause**: File format changed or line endings are mixed
**Solution**: Check file with `file docs/rulesdocs/comprehensive_rules.md` - should show "ASCII text" with LF line terminators

## What Gets Updated

When you run the parser, these 12 files are regenerated:
- `index.json` - Table of contents
- `section_1.json` through `section_9.json` - Main rule sections
- `glossary.json` - Glossary of terms
- `credits.json` - Credits and effective date

The app automatically picks up these changes on next launch.

