# BI_DB_dbo.BI_DB_InterestMonthly — Column Lineage

## Source Systems

| Source | Type | Description |
|--------|------|-------------|
| BI_DB_dbo.External_Interest_Trade_InterestMonthly | External Table | Interest database — monthly accumulated interest per CID |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| CID | External_Interest_Trade_InterestMonthly | CID | Passthrough |
| RegulationID | External_Interest_Trade_InterestMonthly | RegulationID | Passthrough |
| StatusID | External_Interest_Trade_InterestMonthly | StatusID | Passthrough (filtered to StatusID=3) |
| MonthOfInterest | External_Interest_Trade_InterestMonthly | MonthOfInterest | Passthrough (filtered to 2 months prior) |
| MonthlyAccumulatedInterest | External_Interest_Trade_InterestMonthly | MonthlyAccumulatedInterest | Passthrough |
| TaxPercentage | External_Interest_Trade_InterestMonthly | TaxPercentage | Passthrough |
| FinalTaxedlnterest | External_Interest_Trade_InterestMonthly | FinalTaxedlnterest | Passthrough |
| ValidFrom | External_Interest_Trade_InterestMonthly | ValidFrom | Passthrough |
| UpdateDate | — | — | GETDATE() |

## Pipeline

```
Interest.Trade.InterestMonthly (production Interest database)
  |-- Generic Pipeline (Bronze export) --|
  v
Data Lake (Bronze/Interest/Trade/InterestMonthly)
  |-- External Table --|
  v
BI_DB_dbo.External_Interest_Trade_InterestMonthly
  |-- SP_InterestMonthly @date (daily, delete-insert by MonthOfInterest) --|
  |   Filter: StatusID = 3 AND MonthOfInterest = 2 months prior            |
  v
BI_DB_dbo.BI_DB_InterestMonthly (4.86M rows, monthly CID-level)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```
