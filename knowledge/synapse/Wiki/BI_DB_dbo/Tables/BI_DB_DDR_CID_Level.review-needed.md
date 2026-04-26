# BI_DB_DDR_CID_Level — Review Needed

Generated: 2026-04-21 | Batch 11 #2

## Tier 4 Items (Limited Confidence)

*None — all 174 columns are Tier 2 from SP_DDR code analysis. No Tier 3 or Tier 4 assignments.*

## Questions for Reviewer

1. **FTF Definition Gap**: The `FirstTimeFunded` flag in this table uses `Function_Population_First_Time_Funded()` (5-criteria: FTD + Verified + Trade/IOB/Options). The standalone `BI_DB_FirstTimeFunded` table uses `SP_FirstTimeFunded` (3-criteria: deposit + verified + trade). These produce different populations. Confirm whether analysts accessing this table understand the discrepancy when comparing DDR FTF counts to the standalone table.

2. **InvestedInManualTradeing typo**: Column #128 is named `InvestedInManualTradeing` (typo: "Tradeing" not "Trading"). Confirm this is the canonical name in production — it is in the DDL and cannot be silently renamed in docs.

3. **Equity formula completeness**: The Equity computation (PositionPNL + InProcessCashout + PositionAmount + TotalCash + StockOrders) was derived from SP_DDR code analysis. Confirm this is the authoritative formula and no additional components (e.g., credit, bonuses) are included/excluded intentionally.

4. **#allUsers CID universe**: CIDs appear in `BI_DB_DDR_CID_Level` if they exist in either Fact_CustomerAction OR BI_DB_Client_Balance_CID_Level_New for @date. Confirm this is intentional — particularly whether Client_Balance-only rows (no action today) should appear in DDR.

5. **UC target freshness**: The UC Gold target `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level` was confirmed in generic_pipeline_mapping.json. Confirm the pipeline is active and latency is acceptable (same-day or T+1).

6. **FTDCurrentYear boundary**: The FTDCurrentYear flag uses `YEAR(FirstDepositDate) = YEAR(@date)`. Confirm this resets at calendar year boundary (Jan 1) and is not fiscal-year aligned.

7. **Phase 10 Atlassian skip**: No Confluence/Jira sources were searched (MCP not available). If there is business documentation for any DDR metric definitions (especially Revenue, CustomerPnL, Funded_New_Def), that documentation should supersede the SP-derived Tier 2 descriptions.

## Correction Notes

*None at this time.*

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 174 cols; HASH(CID); CLUSTERED INDEX (DateID, CID) |
| P2 Sample | PASS | ~6.81M rows/day; 1563 distinct dates; DateID 20220101–20260412 |
| P3 Distribution | PASS | HASH(CID) confirmed; estimated ~10.6B total rows |
| P4 Lookup | PASS | DateID → Dim_Date; CID → Dim_Customer |
| P5 JOINs | PASS | SP_DDR_Auxiliary_Metrics reads this table; SP_DDR produces downstream Daily_Aggregated |
| P6 Business Logic | PASS | All major logic derived from SP_DDR code: CID universe, FTF TVF, Equity formula, Revenue formula, IsBlocked CASE |
| P7 Views | SKIP | Not checked — no views listed in SP scan scope |
| P8 SP Scan | PASS | Writer: SP_DDR; Reader: SP_DDR_Auxiliary_Metrics |
| P9 SP Logic | PASS | SP_DDR read fully; #CIDAgg assembly, all source temp tables, INSERT logic documented |
| P9B ETL Orch | PASS | Daily SB_Daily; SP_DDR runs before SP_DDR_Auxiliary_Metrics |
| P10 Atlassian | SKIP (soft) | No Atlassian MCP available |
| P10A Upstream | PASS | Fact_SnapshotCustomer.md and Dim_Customer.md reviewed for T1 candidates — none applicable to DDR cols |
| P10B Lineage | PASS | .lineage.md written — full 174-column source mapping |
| P11 Wiki | PASS | .md written — grouped by 13 column categories |
