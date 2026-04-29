# BI_DB_dbo.BI_DB_VAT_Transactions — Column Lineage

## Source Objects

| Source Object | Schema | Role | Confidence |
|--------------|--------|------|------------|
| Dim_Position | DWH_dbo | Primary source — position open/close events counted as transactions | Tier 2 — SP code |
| Fact_CustomerAction | DWH_dbo | Filter — ActionTypeID IN (1,2,3,39) + IsSettled flag | Tier 2 — SP code |
| Fact_SnapshotCustomer | DWH_dbo | Filter — IsCreditReportValidCB=1, provides RegulationID and CountryID | Tier 2 — SP code |
| Dim_Range | DWH_dbo | JOIN — date range validation (OpenDateID/CloseDateID BETWEEN FromDateID AND ToDateID) | Tier 2 — SP code |
| Dim_Regulation | DWH_dbo | Lookup — Regulation name | Tier 1 — Dictionary.Regulation wiki |
| Dim_Country | DWH_dbo | Lookup — Country name | Tier 1 — Dictionary.Country wiki |

## Column Lineage

| Target Column | Source Table | Source Column | Transform | Tier |
|--------------|-------------|---------------|-----------|------|
| Month | — | — | ETL-computed: EOMONTH(@Date). Last day of the reporting month. | Tier 2 |
| IsSettled | DWH_dbo.Fact_CustomerAction | IsSettled | Passthrough. 1=settled, 0=unsettled, -1=unknown/other. | Tier 2 |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via RegulationID from Fact_SnapshotCustomer | Tier 1 |
| Transactions | DWH_dbo.Dim_Position | PositionID | SUM(COUNT(PositionID)) across open+close position events for the month | Tier 2 |
| UpdateDate | — | — | ETL metadata: GETDATE() | Tier 5 |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough via CountryID from Fact_SnapshotCustomer | Tier 1 |

## ETL Pipeline

```
DWH_dbo.Dim_Position (open + close positions for @StartMonth)
  + Fact_SnapshotCustomer (IsCreditReportValidCB=1, RegulationID, CountryID)
  + Dim_Range (date range validation via DateRangeID)
  + Fact_CustomerAction (ActionTypeID IN (1,2,3,39), IsSettled)
  |
  UNION ALL (open positions + close positions)
  |
  + Dim_Regulation (Name → Regulation)
  + Dim_Country (Name → Country)
  |
  GROUP BY IsSettled, Regulation, Country → SUM(countpositions)
  |
  |-- SP_VAT_Transaction @Date ---|
  |-- DELETE WHERE Month = @EndMonth + INSERT ---|
  v
BI_DB_dbo.BI_DB_VAT_Transactions (~101K rows, monthly grain)
```
