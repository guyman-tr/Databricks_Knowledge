# BI_DB_dbo.BI_DB_ASIC_Monthly_Positions — Column Lineage

> Generated: 2026-04-21 | Pipeline Phase: 10B | Writer SP: SP_ASIC_Monthly_Positions

## ETL Chain

```
DWH_dbo.Dim_Position (CID, PositionID, OpenDateID, CloseDateID, RegulationIDOnOpen, InitialAmountCents, Amount, Leverage, IsPartialCloseChild)
DWH_dbo.Fact_SnapshotCustomer (RealCID, RegulationID, CountryID, DateRangeID)
DWH_dbo.Dim_Range (DateRangeID, FromDateID, ToDateID)
  |
  |-- SP_ASIC_Monthly_Positions(@DateFirst) ---|
  |   #allpos: JOIN Dim_Position × Fact_SnapshotCustomer, filter ASIC regulations (4,10)
  |   #final: UNION open_pos × close_pos × AU/NON_AU CASE → 4 ASIC_Client_Group rows per month
  |   DELETE for YearMonth + INSERT
  v
BI_DB_dbo.BI_DB_ASIC_Monthly_Positions (400 rows, monthly grain, Jan 2018–Apr 2026)
  |
  |-- UC Target: _Not_Migrated (not in Generic Pipeline mapping)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | YearMonth | DWH_dbo.Dim_Position | OpenDateID | LEFT(OpenDateID, 6) → YYYYMM int | Tier 2 — SP_ASIC_Monthly_Positions |
| 2 | ASIC_Client_Group | Computed | RegulationIDOnOpen / RegulationOnClose + CountryID | CASE: open/close × AU (CountryID=12) / NON_AU | Tier 2 — SP_ASIC_Monthly_Positions |
| 3 | NO.Positions | DWH_dbo.Dim_Position | PositionID / IsPartialCloseChild | COUNT of non-partial-close positions per group | Tier 2 — SP_ASIC_Monthly_Positions |
| 4 | TotalVolume | DWH_dbo.Dim_Position | InitialAmountCents / Amount / Leverage | SUM(InitialAmount × Leverage) for opens; SUM(Amount × Leverage) for closes | Tier 2 — SP_ASIC_Monthly_Positions |
| 5 | UpdateDate | ETL system | GETDATE() | ETL timestamp at INSERT | Tier 2 — SP_ASIC_Monthly_Positions |

## Population Logic Summary

| ASIC_Client_Group | Trigger | Volume Formula |
|------------------|---------|----------------|
| open_pos_AU | RegulationIDOnOpen IN(4,10) AND CountryID=12 | SUM(InitialAmountCents/100 × Leverage) |
| open_pos_NON_AU | RegulationIDOnOpen IN(4,10) AND CountryID≠12 | SUM(InitialAmountCents/100 × Leverage) |
| close_pos_AU | RegulationOnClose IN(4,10) AND CountryID=12 | SUM(Amount × Leverage) |
| close_pos_NON_AU | RegulationOnClose IN(4,10) AND CountryID≠12 | SUM(Amount × Leverage) |

## UC External Lineage

| UC Target | `_Not_Migrated` (not in Generic Pipeline mapping) |
|-----------|---|
