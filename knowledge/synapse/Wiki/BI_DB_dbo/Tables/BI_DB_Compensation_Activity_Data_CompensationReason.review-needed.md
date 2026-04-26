# Review Needed — BI_DB_dbo.BI_DB_Compensation_Activity_Data_CompensationReason

Generated: 2026-04-23 | Batch 71

## Tier 4 Items (Unverified)

None — all columns resolved to Tier 1 or Tier 2.

## Questions for Reviewer

1. **CompensationReasonID mapping**: The SP uses CompensationReasonID IN (3, 26, 125, 126, 127, 128), but only 4 reason names appear in current data. Confirm which names map to all 6 IDs — some may only appear historically or at low frequency.
2. **Negative amounts**: Data shows Amount range −$8,062 to $8,062. Are negative amounts expected (correction reversals)? Confirm this is not a data quality issue.
3. **Downstream consumers**: No downstream SP/view references found in SSDT. Is this table consumed by an external reporting tool or BI layer?
4. **Scope stability**: The SP uses no date parameter and always loads the previous month. Is this intended to run once per month, or is a daily overwrite with identical data acceptable?

## Known Limitations

- **FCA only** — non-FCA regulations not covered (see `BI_DB_Compensation_Activity_Data_Regulation` for cross-regulation metrics).
- **Reason subset** — only CompensationReasonIDs (3, 26, 125, 126, 127, 128) included; other compensation categories (marketing, dividends, accounting ops) are absent.
- **Single month window** — table holds exactly one calendar month; no historical trend in this table.
- ROUND_ROBIN / HEAP — not suitable for large analytical joins; this is a reporting export table.
