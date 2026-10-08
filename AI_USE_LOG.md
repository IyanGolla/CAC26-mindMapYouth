# AI-use log

The Congressional App Challenge requires disclosing AI-assisted work. Add an entry whenever AI helps.

| Date | Tool | What it did | How it was checked |
|------|------|-------------|--------------------|
| 2026-10-07 | AI assistant | Wrote the technical blueprint (PDF). | |
| 2026-10-07 | Claude Code (Claude Opus) | Generated the initial Flutter project from the blueprint: all code in `lib/`, tests in `test/`, Android manifest and `MainActivity.kt` changes, the seed `assets/wa_resources.json` (statewide lines from the blueprint plus placeholder listings), and `README.md`. | Analyzer clean, 15 automated tests pass, flows exercised on an Android emulator by the AI. Not yet reviewed by a person. |
| 2026-10-07 | Claude Code (Claude Opus) | Restyled the app to match a reference mockup (beige/coral palette, serif headings, pill buttons and inputs) and drew the leaf and brain illustrations in code (`lib/widgets/decor.dart`). | Analyzer clean, tests pass, screens checked on an Android emulator by the AI. |
