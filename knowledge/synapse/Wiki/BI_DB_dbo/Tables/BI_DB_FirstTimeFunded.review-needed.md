# BI_DB_FirstTimeFunded — Review Needed

Generated: 2026-04-21 | Batch 11 #1

## Tier 4 Items (Limited Confidence)

*None — all 4 columns are Tier 1 or Tier 2 with strong evidence.*

## Questions for Reviewer

1. **UC Target**: This table was not found in the generic pipeline mapping. Confirm whether a Databricks Gold layer target exists or whether this is Synapse-only.

2. **FTF Definition stability**: The three criteria (verified + deposited + traded) — has this definition changed over time? Are there edge cases where the criteria differ by regulatory region (ASIC, FCA)?

3. **RealCID vs CID**: In SP_DDR, the join is on RealCID. Confirm that RealCID = CID for all customers in scope (no merged accounts where these diverge).

4. **SR-295058 dedup impact**: The TRUNCATE+INSERT was added after a bug. Was historical FTF data corrected, or could there be accuracy gaps for early cohorts?

## Correction Notes

*None at this time.*

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 4 cols, ROUND_ROBIN, CLUSTERED on (RealCID, FirstTimeFundedDateID) |
| P2 Sample | PASS | 4.72M rows, 2012-10-03 to 2025-02-17, writer SP identified |
| P3 Distribution | PASS | 4.72M distinct CIDs, 4386 distinct dates |
| P4 Lookup | PASS | RealCID → Dim_Customer; FirstTimeFundedDateID → Dim_Date |
| P5 JOINs | PASS | SP_DDR reads as FTFDate join |
| P6 Business Logic | PASS | FTF = MAX(verified, deposited, traded) when all 3 non-null |
| P7 Views | PASS | No views reference this table |
| P8 SP Scan | PASS | Writer: SP_FirstTimeFunded; Reader: SP_DDR |
| P9 SP Logic | PASS | Full SP code read and analyzed |
| P9B ETL Orch | PASS | Daily SB_Daily; runs before SP_DDR |
| P10 Atlassian | SKIP (soft) | No Atlassian MCP |
| P10A Upstream | PASS | RealCID → Dim_Customer.md → (Tier 1 — Customer.CustomerStatic) |
| P10B Lineage | PASS | .lineage.md written |
| P11 Wiki | PASS | .md written |
