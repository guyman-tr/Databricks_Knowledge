# Column Lineage — eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated

**Generated**: 2026-04-21
**Writer SP**: `SP_eMoney_Reports_Daily` (Steps 5–6)
**Primary Source**: `eMoney_Reports_AcquisitionFunnel` intermediate result (#funnel temp table)
**ETL Pattern**: TRUNCATE + INSERT (full refresh daily)

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | FunnelStage | SP_eMoney_Reports_Daily | — | Hardcoded string label per UNION ALL block (9 values: VerifiedFTD, IsVerifiedFTDPlus2Weeks, IsActiveMIMO, IseMoneyAccount, IsFMI, IsFMO, IsCardCreated, IsCardActivated, IsCardFirstTx) | Tier 2 |
| 2 | Country | #funnel temp table | Country | Passthrough from AcquisitionFunnel.Country (GROUP BY key) | Tier 2 |
| 3 | Club | #funnel temp table | Club | Passthrough from AcquisitionFunnel.Club (GROUP BY key) | Tier 2 |
| 4 | FunnelCount | #funnel temp table | Boolean flag columns | SUM(ISNULL(boolean_flag, 0)) per Country+Club group | Tier 2 |
| 5 | UpdateDate | SP_eMoney_Reports_Daily | — | GETDATE() at insert time | Tier 2 |

---

## ETL Pipeline

```
eMoney_Reports_AcquisitionFunnel (customer-grain, from Steps 1-4)
  → GROUP BY Country, Club with 9 UNION ALL stages
    |-- SP_eMoney_Reports_Daily Steps 5-6 (TRUNCATE + INSERT, daily) ---|
    v
eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated (1,863 rows, REPLICATE HEAP)
    |-- Generic Pipeline (Override, delta, daily) ---|
    v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated
```

---

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| #funnel (temp table in SP_eMoney_Reports_Daily) | eMoney_dbo | Aggregation source — same data as eMoney_Reports_AcquisitionFunnel |
| eMoney_Reports_AcquisitionFunnel | eMoney_dbo | Logical source (same SP run, shared intermediate data) |
