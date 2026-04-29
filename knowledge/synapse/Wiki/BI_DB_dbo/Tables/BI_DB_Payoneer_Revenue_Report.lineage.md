# BI_DB_dbo.BI_DB_Payoneer_Revenue_Report — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Payoneer_Revenue_Report` — daily DELETE+INSERT by EndofMonth

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Population — verified depositors active in month |
| DWH_dbo.Dim_Customer | DWH_dbo | FirstDepositDate >= 2020-01-01 filter |
| DWH_dbo.Dim_Country | DWH_dbo | Country name |
| DWH_dbo.Dim_Range | DWH_dbo | Date range validity for snapshot |
| DWH_dbo.Fact_BillingDeposit | DWH_dbo | Payoneer indicator (FundingTypeID=39) |
| BI_DB_dbo.BI_DB_DailyCommisionReport | BI_DB_dbo | Revenue (FullCommissions + RollOverFee) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| EndofMonth | (computed) | — | EOMONTH(@Date) — end of the parameter month |
| Country | DWH_dbo.Dim_Country | Name | dim-lookup via Fact_SnapshotCustomer.CountryID |
| Client Type | (computed) | — | CASE: Payoneer deposit (FundingTypeID=39) ever → 'Payoneer Only/Both...' else 'Only Other MOP' |
| Clients Generated Revenue | (computed) | — | COUNT(CID) WHERE Revenue >= 0 |
| Clients | (computed) | — | COUNT(CID) per group |
| Revenue | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM for the month |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
