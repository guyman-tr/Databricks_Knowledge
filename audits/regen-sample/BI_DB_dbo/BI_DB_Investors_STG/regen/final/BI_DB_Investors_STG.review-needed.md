# Review Needed: BI_DB_dbo.BI_DB_Investors_STG

## Items for Human Review

### 1. OpsDB Priority and Scheduling
- The SP_InvestorReport is listed as OpsDB Priority 0, ProcessType 1 (SQL), SB_Daily. Confirm this is still the active scheduling and that no secondary orchestration exists.

### 2. etoroGeneral_History_GuruCopiers — No Upstream Wiki
- The `etoroGeneral_History_GuruCopiers` table (used for Copy stream AUM calculation) has no upstream wiki in the bundle. The AUA/AUM values for the Copy stream are sourced from `Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL` from this table. Column-level descriptions for these source fields are unavailable.

### 3. Balance Stream COUNT(CID) vs COUNT(DISTINCT CID)
- The Manual and Copy streams use `COUNT(DISTINCT CID)` for Customers aggregation, but the Balance stream uses `COUNT(CID)`. This may cause double-counting if a CID has multiple balance rows. Confirm whether this is intentional or a bug in SP_InvestorReport.

### 4. SourceTable and ActionType Redundancy
- Both columns always carry the same literal value ('Manual', 'Copy', or 'Balance'). Confirm whether there is a planned divergence or if one column is purely legacy.

### 5. UC Migration Status
- Table is marked `_Not_Migrated`. Confirm whether there is a plan to migrate this staging table to Unity Catalog or if the downstream aggregated tables (BI_DB_Investors, BI_DB_Investors_Unclustered) are the intended UC targets.

---

*Generated: 2026-04-29 | Object: BI_DB_dbo.BI_DB_Investors_STG*
