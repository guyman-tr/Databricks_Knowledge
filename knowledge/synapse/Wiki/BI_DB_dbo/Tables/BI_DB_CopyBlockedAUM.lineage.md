# BI_DB_dbo.BI_DB_CopyBlockedAUM — Column Lineage

Generated: 2026-04-23 | Schema: BI_DB_dbo | Object: BI_DB_CopyBlockedAUM

## ETL Chain

```
etoro.Customer.BlockedCustomerOperations (OperationTypeID=2, current blocks)
  |-- SP_CopyBlockedAUM (Dan, 2021-11-22; Synapse: Tom Boksenbojm, 2023-12-18) ---|
  |   + etoro.Customer.BlockedCustomerOperations (External_etoro_Customer_BlockedCustomerOperations)
  |   + DWH_dbo.Dim_Customer (UserName, GuruStatusID, CountryID, AccountManagerID)
  |   + DWH_dbo.Dim_GuruStatus (GuruStatusName)
  |   + DWH_dbo.Dim_Country (Country Name)
  |   + DWH_dbo.Dim_Manager (Manager name composite)
  |   + DWH_dbo.V_Liabilities (Equity = ActualNWA + Liabilities)
  |   + general.etoroGeneral_History_GuruCopiers (AUM, NumOfCopiers as of @date)
  |   + BI_DB_dbo.DWH_CIDsDailyRisk (risk score history 151-day lookback)
  |   + External_etoro_Dictionary_OperationTypesForBlocking (OperationDescription)
  |   + External_etoro_Dictionary_BlockUnBlockReason (Reason)
  |   + External_etoro_Internal_RiskScore (risk thresholds)
  v
BI_DB_dbo.BI_DB_CopyBlockedAUM (TRUNCATE+INSERT daily, 691 rows as of 2026-04-12)
  |-- Not in Generic Pipeline (no UC target) ---|
  v
UC Target: _Not_Migrated
```

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| CID | External_etoro_Customer_BlockedCustomerOperations | CID | Passthrough | Tier 1 |
| UserName | DWH_dbo.Dim_Customer | UserName | Passthrough via Dim_Customer | Tier 1 |
| Manager | DWH_dbo.Dim_Manager | FirstName+' '+LastName | String concatenation | Tier 2 |
| OperationTypeID | External_etoro_Customer_BlockedCustomerOperations | OperationTypeID | Passthrough; always 2 (Copied filter) | Tier 2 |
| BlockReasonID | External_etoro_Customer_BlockedCustomerOperations | BlockReasonID | Passthrough | Tier 2 |
| Occurred | External_etoro_Customer_BlockedCustomerOperations | Occurred | Passthrough | Tier 2 |
| OccurredID | External_etoro_Customer_BlockedCustomerOperations | Occurred | CAST(CONVERT(CHAR(8),Occurred,112) AS INT) | Tier 2 |
| OperationDescription | External_etoro_Dictionary_OperationTypesForBlocking | OperationDescription | Passthrough via dictionary | Tier 2 |
| Reason | External_etoro_Dictionary_BlockUnBlockReason | Reason | Passthrough via dictionary | Tier 2 |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via Dim_Country.Name | Tier 1 |
| GuruStatusID | DWH_dbo.Dim_Customer | GuruStatusID | Passthrough via Dim_Customer | Tier 1 |
| GuruStatusName | DWH_dbo.Dim_GuruStatus | GuruStatusName | Passthrough via Dim_GuruStatus | Tier 1 |
| AUM | general.etoroGeneral_History_GuruCopiers | Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL | ISNULL(SUM,0) as of @date | Tier 2 |
| NumOfCopiers | general.etoroGeneral_History_GuruCopiers | (count of copiers) | ISNULL(COUNT(*),0) as of @date | Tier 2 |
| Equity | DWH_dbo.V_Liabilities | ActualNWA + Liabilities | Sum of two V_Liabilities columns | Tier 2 |
| DaysUnderRisk6 | BI_DB_dbo.DWH_CIDsDailyRisk | FullDate, RiskScore | CASE: DATEDIFF from LastDateOver6, NULL if equity=0, '31+' otherwise | Tier 2 |
| UpdateDate | ETL metadata | (none) | GETDATE() | Propagation |
| AvgRiskPreviousMonth | BI_DB_dbo.DWH_CIDsDailyRisk | RiskScore | CAST(ROUND(AVG(RiskScore),0,1) AS INT) for prior calendar month | Tier 2 |
| DaysSinceMaxRiskScore8 | BI_DB_dbo.DWH_CIDsDailyRisk | FullDate, RiskScore | DATEDIFF(MAX date where RiskScore>=8); -1 if never reached 8 | Tier 2 |

## Source Objects

- `External_etoro_Customer_BlockedCustomerOperations` — current PI copy blocks (OperationTypeID=2)
- `External_etoro_Dictionary_OperationTypesForBlocking` — operation type dictionary
- `External_etoro_Dictionary_BlockUnBlockReason` — block reason dictionary
- `DWH_dbo.Dim_Customer` — customer master (UserName, GuruStatusID, CountryID, AccountManagerID)
- `DWH_dbo.Dim_GuruStatus` — PI tier names
- `DWH_dbo.Dim_Country` — country name lookup
- `DWH_dbo.Dim_Manager` — account manager names
- `DWH_dbo.V_Liabilities` — daily equity snapshot (ActualNWA + Liabilities)
- `general.etoroGeneral_History_GuruCopiers` — daily copier AUM snapshot (partition_date = @date)
- `BI_DB_dbo.DWH_CIDsDailyRisk` — 151-day rolling risk score history

## UC External Lineage

UC Target: _Not_Migrated — not in Generic Pipeline mapping
