# BI_DB_dbo.BI_DB_Compliance_Clients_Dashboard_EOM_Pos — Column Lineage

> Generated: 2026-04-23 | Batch 71

## Object Metadata

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Writer SP | SP_Compliance_BI_Clients_Dashboard |
| Load Pattern | DELETE WHERE DateID = @DateID + INSERT (incremental by EOM date; @Date must be last day of month) |
| Population | Valid depositor customers (IsValidCustomer=1, IsDepositor=1) who opened a position on @Date; one row per [Date, Regulation, Country, MirrorType, IsBuyType, IsSettledType, InstrumentType, IsSettledTypeDetailed] group |

## ETL Pipeline

```
DWH_dbo.Dim_Position (positions opened on @Date = last day of month)
  + DWH_dbo.Dim_Instrument (InstrumentType + InstrumentTypeID for IsSettledTypeDetailed)
  + DWH_dbo.Dim_Date (dd.IsLastDayOfMonth = 'Y' — EOM gate: no insert if @Date not EOM)
    → #positio_pop (CID-level: MirrorType, IsBuyType, IsSettledType, IsSettledTypeDetailed, Volume)

  + DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1, IsDepositor=1, RegulationID, CountryID)
  + DWH_dbo.Dim_Range (DateRangeID effective for @DateID)
  + DWH_dbo.Dim_Customer (FirstDepositDate → New_Customer_Ind)
  + DWH_dbo.Dim_Country (Country name)
  + DWH_dbo.Dim_Regulation (Regulation name)
    → #aggEOMpop (aggregated: COUNT RealCID, SUM New_Customer_Ind, SUM Volume)
    |-- SP_Compliance_BI_Clients_Dashboard (@Date) DELETE+INSERT ---|
    v
BI_DB_dbo.BI_DB_Compliance_Clients_Dashboard_EOM_Pos (150,063 rows, 51 EOM dates)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | Date | SP parameter | @Date | Passthrough (last day of month only) | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 2 | DateID | SP parameter | @DateID | YYYYMMDD integer of @Date | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 3 | Regulation | DWH_dbo.Dim_Regulation | Name | LEFT JOIN via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.ID | Tier 1 — Dim_Regulation wiki, Dictionary.Regulation |
| 4 | Country | DWH_dbo.Dim_Country | Name | LEFT JOIN via Fact_SnapshotCustomer.CountryID | Tier 1 — Dim_Country wiki, Dictionary.Country |
| 5 | MirrorType | DWH_dbo.Dim_Position | MirrorID | CASE: NULL/0 → 'Manual', else → 'Copy' | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 6 | IsBuyType | DWH_dbo.Dim_Position | IsBuy | CASE: 1 → 'Long', else → 'Short' | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 7 | IsSettledType | DWH_dbo.Dim_Position | IsSettled | CASE: 1 → 'Real', else → 'CFD' | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 8 | PositionType | SP literal | — | Hardcoded 'Opened_EOD' for all rows | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 9 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough (DWH-computed text label) | Tier 2 — Dim_Instrument wiki |
| 10 | IsSettledTypeDetailed | DWH_dbo.Dim_Position + Dim_Instrument | IsSettled + InstrumentTypeID | CASE: (5,6)+Settled=1→'Real Stocks ETF', 10+Settled=1→'Real Crypto', (5,6)+Settled=0→'CFD Stocks ETF', 10+Settled=0→'CFD Crypto', (1,2,4)+Settled=0→'CFD FX', else→'N/A' | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 11 | RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | COUNT(RealCID) — customer count per group (column name misleading; this is NOT a customer ID) | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 12 | New_Customers | DWH_dbo.Dim_Customer | FirstDepositDate | SUM(CASE WHEN DATEDIFF(DAY, FirstDepositDate, Date) <= 60 THEN 1 ELSE 0 END) | Tier 2 — SP_Compliance_BI_Clients_Dashboard |
| 13 | Volume | DWH_dbo.Dim_Position | Volume | SUM (ETL-computed USD approximation: ROUND(AmountInUnitsDecimal * InitForexRate * USD factor, 0)) | Tier 2 — Dim_Position wiki |
| 14 | UpdateDate | ETL | GETDATE() | Runtime timestamp | Propagation |
