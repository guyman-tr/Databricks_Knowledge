# Dealing_dbo.Dealing_PDT — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| Status | What are all possible PDT status values? | Only 'WARN' observed in data. 'OK' is filtered out. Are there others like 'RESTRICTED', 'FROZEN'? |
| ApexID | Is this the Apex account number or a different identifier? | Format: "3EW35324" / "3EX86394" — alphanumeric, 8 chars. |

## Structural Questions

| Question | Context |
|----------|---------|
| Is PDT tracking still Apex-only? | With etoro moving to multi-broker, are there other PDT data sources? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
