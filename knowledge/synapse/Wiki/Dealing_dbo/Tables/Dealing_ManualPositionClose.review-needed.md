---
object: Dealing_ManualPositionClose
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_ManualPositionClose — Review Notes

## Auto-Generated Flags

- **OperationDescription is free-text varchar(max)**: Naming is not standardized — different dealers may use different formats. Does the Dealing team have a convention?
- **Date window (DateMinus1 → Date)**: The SP processes log entries from the prior day. This means a position closed on day T appears in the Date=T+1 record. Confirm this is expected for all downstream users.
- **US_Client country list hardcoded**: The 6 US-jurisdiction CountryIDs are hardcoded in the SP. If Dim_Country adds a new US territory, it must be manually added to SP.
- **Row count growth**: 2.2M rows growing daily — no partitioning beyond clustered index on Date. Monitor query performance for analytical queries over large date ranges.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
