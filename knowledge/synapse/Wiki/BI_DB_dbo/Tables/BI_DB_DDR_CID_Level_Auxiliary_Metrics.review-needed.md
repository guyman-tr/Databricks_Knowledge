# BI_DB_DDR_CID_Level_Auxiliary_Metrics — Review Needed

Generated: 2026-04-21 | Batch 11 #3

## Tier 4 Items (Limited Confidence)

*None — all 23 columns are Tier 2 from SP_DDR_Auxiliary_Metrics code analysis.*

## Questions for Reviewer

1. **WalletBalanceUSD permanence**: The column is hardcoded NULL in the SP (wallet balance feature commented out). Is this permanently deprecated, or is there a plan to populate it? If permanently deprecated, the column should ideally be dropped from the DDL to avoid analyst confusion.

2. **TradingFees vs TicketFees intended use**: The wiki describes TradingFees as TicketFees + Islamic fees. Confirm analysts are aware that using `TradingFees` for "total ticket costs" would overcount for non-Islamic accounts. Is there an authoritative definition document for these metrics?

3. **DormantFee sign convention**: The SP explicitly negates the Amount (SUM(-Amount)) because dormant fee actions are stored negative. Confirm this is still accurate — if the recording convention in Fact_CustomerAction changed (e.g., ActionTypeID=36 charges became positive), the negation would double-invert.

4. **CID universe mismatch with main DDR**: This table appears for a CID only when they incur a fee. Analysts joining this LEFT JOIN to DDR_CID_Level will get NULLs for most rows. Confirm that all downstream consumers use a LEFT JOIN (not INNER JOIN) to avoid silently dropping non-fee customers.

5. **DateID type discrepancy**: DateID is `bigint` in this table vs `int` in `BI_DB_DDR_CID_Level`. This can cause implicit conversion warnings in JOINs. Confirm this is known and accepted, or confirm whether a DDL correction is needed.

6. **UpdateDate type**: DDL declares UpdateDate as `date` (not `datetime`). SP inserts `GETDATE()` which is datetime — Synapse will truncate to date silently. Confirm this truncation is intentional (date-precision is sufficient for audit purposes).

7. **UC target**: No UC Gold target was found in the generic_pipeline_mapping.json. Confirm whether a Databricks replication is planned or whether this table is intentionally Synapse-only.

8. **Phase 10 Atlassian skip**: No Confluence/Jira sources were searched. If there is documentation for SDRT computation rules, Islamic fee criteria, or DormantFee triggering conditions, those sources should supersede the SP-derived Tier 2 descriptions.

## Correction Notes

*None at this time.*

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 23 cols; HASH(CID); CLUSTERED INDEX (DateID, CID) |
| P2 Sample | PASS | 492M rows; 1,933 distinct dates; DateID 20201227–20260412; 5.23M distinct CIDs |
| P3 Distribution | PASS | HASH(CID); ~254K rows/day average (sparse — fee-incurring customers only) |
| P4 Lookup | PASS | DateID → Dim_Date; CID → Dim_Customer |
| P5 JOINs | PASS | BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics reads from same SP run (#RegAgg) |
| P6 Business Logic | PASS | All 6 fee types traced to source; WalletBalanceUSD NULL documented; DormantFee sign inversion noted |
| P7 Views | SKIP | Not checked |
| P8 SP Scan | PASS | Writer: SP_DDR_Auxiliary_Metrics; also writes BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics |
| P9 SP Logic | PASS | SP fully read; all 7 source temp tables documented; #CIDAgg and #RegAgg assembly confirmed |
| P9B ETL Orch | PASS | Daily SB_Daily; SP_DDR_Auxiliary_Metrics runs after SP_DDR |
| P10 Atlassian | SKIP (soft) | No Atlassian MCP available |
| P10A Upstream | PASS | Fact_SnapshotCustomer.md reviewed; no T1 candidates for auxiliary-specific columns |
| P10B Lineage | PASS | .lineage.md written — all 23 columns with CID universe note |
| P11 Wiki | PASS | .md written |
