# Column Lineage — DWH_dbo.Fact_Guru_Copiers

## Production Source

| Property | Value |
|----------|-------|
| **Source Database** | etoro |
| **Source Schema** | History |
| **Source Table** | GuruCopiers |
| **Staging Table** | DWH_staging.etoro_History_GuruCopiers → Ext_FGC_Guru_Copiers |
| **Writer SP** | SP_Fact_Guru_Copiers (aggregation), SP_Fact_Guru_Copiers_DL_To_Synapse (orchestration) |
| **Load Pattern** | Daily DELETE + re-INSERT |
| **Generic Pipeline** | ID 415 → `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers` |

## Column Mapping

| # | DWH Column | Source Expression | Transform |
|---|-----------|-------------------|-----------|
| 1 | CID | Ext_FGC_Guru_Copiers.CID | Pass-through (GROUP BY key) |
| 2 | DateID | V_M2M_Date_DateRange.DateKey | From date range expansion JOIN |
| 3 | Cash | `SUM(ISNULL(Ext_FGC_Guru_Copiers.Cash, 0))` | Aggregated across copy relationships |
| 4 | Investment | `SUM(ISNULL(Ext_FGC_Guru_Copiers.Investment, 0))` | Aggregated across copy relationships |
| 5 | PnL | `SUM(ISNULL(Ext_FGC_Guru_Copiers.PnL, 0))` | Aggregated across copy relationships |
| 6 | DetachedPosInvestment | `SUM(ISNULL(Ext_FGC_Guru_Copiers.DetachedPosInvestment, 0))` | Aggregated across copy relationships |
| 7 | Dit_PnL | `SUM(ISNULL(Ext_FGC_Guru_Copiers.Dit_PnL, 0))` | Aggregated across copy relationships |
| 8 | CopyFundAUM | `SUM(Cash) + SUM(Investment) + SUM(PnL) + SUM(DetachedPosInvestment) + SUM(Dit_PnL)` | Computed total AUC |
| 9 | UpdateDate | `GETDATE()` | ETL load timestamp |

## Upstream Wiki

No upstream wiki available. Source `etoro.History.GuruCopiers` is not documented in DB_Schema.

## JOIN Sources

| Source Table | JOIN Condition | Purpose |
|-------------|----------------|---------|
| Ext_FGC_Guru_Copiers | Primary source | Individual copy relationship records |
| Fact_SnapshotCustomer | `g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9` | Filter to CopyFund accounts |
| V_M2M_Date_DateRange | `fsc.DateRangeID = bb.DateRangeID AND DateID = bb.DateKey` | Date range expansion |
