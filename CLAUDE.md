# Claude Code Notes for French Vanilla

## Project Overview
**French Vanilla** is a Magic: The Gathering comprehensive rules reference application built with Flutter, targeting iOS and Android platforms.

## Git Workflow - CRITICAL

### ⚠️ NEVER COMMIT OR PUSH AS CLAUDE
- **ALWAYS use the user's git credentials**
- DO NOT configure git user.name or user.email
- DO NOT make commits or pushes without explicit user instruction
- When instructed to commit, use the user's existing git configuration

### Git Commands Policy
1. **Never run**: `git config user.name` or `git config user.email`
2. **Always ask first** before: `git commit`, `git push`, `git rebase`, `git reset --hard`
3. **Safe to run**: `git status`, `git diff`, `git log`, `git branch`

## Project Configuration

### Bundle Identifiers
- **iOS**: `LooseTie.Frenchvanilla`
- **Android**: `com.loosetie.frenchvanilla`
- **Package**: `frenchvanilla`

### Reference Project
- **Gold Standard**: `../doubling-season` - reference this project for conventions, patterns, and structure

## Security & Sensitive Files

### NEVER Commit These Files
The `.gitignore` is configured to exclude:
- **Android**: `key.properties`, `*.keystore`, `*.jks`, `local.properties`
- **iOS**: `*.p12`, `*.pfx`, `*.mobileprovision`
- **Secrets**: `.env`, `.env.*`, `secrets.yaml`, `credentials.json`
- **Firebase**: `google-services.json`, `GoogleService-Info.plist`

### Before Any Commit
1. Review changed files with `git status`
2. Verify no sensitive files are staged
3. Check diffs with `git diff --cached`

## Development Documentation

### Documentation Structure
- **docs/**: Development documentation
- **docs/rulesdocs/**: Parsed MTG comprehensive rules (JSON format)
- **docs/next_feature.md**: Active development planning document

### Rules Parsing
- **Script**: `scripts/parse_rules.py`
- **Source**: `docs/rulesdocs/comprehensive_rules.md`
- **Output**: 12 JSON files (index, 9 sections, glossary, credits)
- **Re-run when rules update**: `python3 scripts/parse_rules.py`

## App Architecture (Planned)

### Core Features
1. Browse MTG comprehensive rules by section
2. Search functionality for quick rule lookup
3. Offline access (embedded data)
4. Clean, readable UI for quick reference

### Data Format
- Rules stored as JSON in `docs/rulesdocs/`
- Each section is a separate JSON file with metadata
- Glossary maintained as complete file (will be split in-app later)

## Development Workflow

### Typical Session
1. Check `docs/next_feature.md` for current objectives
2. Follow conventions from `doubling-season` project
3. Update `next_feature.md` with progress and decisions
4. Keep commits atomic and well-described

### Code Quality Standards
- Follow patterns from `doubling-season`
- Maintain consistency in naming conventions
- Use proper Flutter/Dart style guide
- Test on both iOS and Android

## Tools & Scripts

### Available Scripts
- `scripts/parse_rules.py` - Parse comprehensive rules into JSON chunks

### Future Scripts
(Add as development progresses)

## Notes & Reminders

### For Claude
- This is a greenfield Flutter project
- User has experience shipping Flutter apps (see doubling-season)
- User prefers clear communication about assumptions
- When in doubt, ask before making significant architectural decisions

### Project Status
- ✅ Flutter infrastructure initialized
- ✅ Rules parsing script created
- ✅ Documentation structure established
- 🔜 App feature development (see `docs/next_feature.md`)

---

**Last Updated**: 2026-01-04
