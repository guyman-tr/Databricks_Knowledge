# BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk — Column Lineage

## Source Objects

| Source | Schema | Role | Join Condition |
|--------|--------|------|----------------|
| External_etoro_History_Credit_Compensation_Risk | BI_DB_dbo (Dynamic External) | Technical issue compensation credits (CreditTypeID=6, MoveMoneyReasonID=1, CompensationReasonID=3) | Main driver |
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Customer regulation at date (via DateRangeID) | eehcaa.CID = fsc.RealCID |
| DWH_dbo.Dim_Range | DWH_dbo | Date range validity filter | fsc.DateRangeID = dr1.DateRangeID AND @DateID BETWEEN FromDateID AND ToDateID |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name lookup | fsc.RegulationID = dr.DWHRegulationID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | etoro.History.Credit | CID | Passthrough (filtered to compensation credits for technical issues) |
| Payment | etoro.History.Credit | Payment | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID |
| CreditID | etoro.History.Credit | CreditID | Passthrough |
| Description | etoro.History.Credit | Description | Passthrough |
| DateID | (SP parameter) | @DateID | CONVERT(VARCHAR, @Date, 112) — YYYYMMDD int |
| Occurred | etoro.History.Credit | Occurred | Passthrough |
| Month | etoro.History.Credit | Occurred | EOMONTH(Occurred) — last day of month |
| UpdateDate | (ETL) | GETDATE() | ETL metadata timestamp |

## Production Source Chain

```
etoro.History.Credit (compensation credit transactions)
  |-- SP_Create_External_etoro_History_Credit @Date, 'Compensation_Risk' --|
  v
BI_DB_dbo.External_etoro_History_Credit_Compensation_Risk (Dynamic External table)
  + DWH_dbo.Fact_SnapshotCustomer (customer regulation snapshot)
  + DWH_dbo.Dim_Range (date range validity)
  + DWH_dbo.Dim_Regulation (regulation name)
  |-- SP_Technical_Issues_Compensation_Risk @Date --|
  |-- Filter: CreditTypeID=6, MoveMoneyReasonID=1, CompensationReasonID=3 --|
  |-- DELETE+INSERT by @DateID --|
  v
BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk (310K rows)
```
