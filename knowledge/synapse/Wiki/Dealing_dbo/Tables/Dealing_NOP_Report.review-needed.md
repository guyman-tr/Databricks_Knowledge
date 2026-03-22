---
object: Dealing_NOP_Report
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_NOP_Report — Review Notes

## Auto-Generated Flags

- **Per-LP source tables not traced**: SP_NOP_Report is ~21K tokens — too large to read in full. Each LP (GS, IB, JP, SAXO, BNY, Marex, IronBeam, FXCM, UBS, Vision) likely has its own source table or staging area. Reviewer: document the source per LP for completeness.
- **NOP units (USD vs. native)**: It is unclear whether NOP is in native instrument units or USD-converted before storage. NOP_USD column suggests the main NOP column may be native. Reviewer: confirm unit convention per LP.
- **`[Unrealised_P&L/VariationMargin]` semantics**: This column appears to combine two different concepts (unrealised P&L and variation margin). Reviewer: is this a single blended metric, or does the content vary by LP/instrument type?
- **Saturday skip vs. Sunday Friday-date**: Confirm that downstream reports correctly handle the Friday-date pattern on Sundays — a consumer expecting yesterday's date on Monday would see Friday's date.
- **ProcessType 3 (SQL&TIME)**: Confirm what the TIME component controls — is there a specific time window or SLA for this SP to run?
- **Last data 2026-03-09 (not 2026-03-10)**: The table is one day behind the ADV tables. Is this expected given the SP schedule, or is it a gap?

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
