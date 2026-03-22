---
object: Dealing_ClientCountry
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_ClientCountry — Review Notes

## Auto-Generated Flags

- **Hardcoded country mapping**: The SP contains a hardcoded CASE expression mapping Exchange strings and InstrumentIDs to countries. If new exchanges or instruments are added to the DWH, this mapping may be incomplete. Reviewer: is the mapping kept up to date?
- **Foreign holdings excluded by design**: The filter `Instrument_Country = Client_Country` means cross-border positions are not counted. Is this the intended scope for all dashboard consumers?
- **ROUND_ROBIN + full scans**: This table has no partitioning beyond the clustered index on Date. Queries not filtered by Date will full-scan.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
