# BI_DB_dbo.BI_DB_Vulnerable_Customers — Column Lineage

## Source Objects

| Source Object | Schema | Role | Confidence |
|--------------|--------|------|------------|
| BI_DB_KYC_Questions_Answers_Row_Data | BI_DB_dbo | Primary — self-identified vulnerable customer answers (QuestionId=32, AnswerId=151) | Tier 2 — SP code |
| Dim_Customer | DWH_dbo | Demographics — RealCID, GCID, FirstDepositDate, VerificationLevelID | Tier 1 — Customer.CustomerStatic wiki |
| Dim_Regulation | DWH_dbo | Lookup — Regulation (×2: RegulationID and DesignatedRegulationID) | Tier 1 — Dictionary.Regulation wiki |
| Dim_Country | DWH_dbo | Lookup — Country name | Tier 1 — Dictionary.Country wiki |
| BI_DB_CIDFirstDates | BI_DB_dbo | Lookup — VL2/VL3 dates | Tier 2 — local wiki |
| V_Liabilities | DWH_dbo | Financial — RealizedEquity, UnrealizedEquity, PositionPnL at yesterday | Tier 2 — SP code |
| Dim_Position | DWH_dbo | Financial — Closed PnL (SUM NetProfit last year) | Tier 2 — SP code |
| External_ComplianceStateDB tables | BI_DB_dbo (external) | Compliance — Appropriateness restriction status | Tier 2 — SP code |

## Column Lineage

| Target Column | Source Table | Source Column | Transform | Tier |
|--------------|-------------|---------------|-----------|------|
| GCID | BI_DB_KYC_Questions_Answers_Row_Data | GCID | Passthrough | Tier 2 |
| CID | DWH_dbo.Dim_Customer | RealCID | Rename (RealCID → CID) | Tier 1 |
| AnswerText | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | Passthrough (always the self-identification text) | Tier 2 |
| Answer_Date | BI_DB_KYC_Questions_Answers_Row_Data | OccurredAt | CAST AS DATE | Tier 2 |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | CASE WHEN < 2000-01-01 THEN NULL (sentinel removal) | Tier 2 |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough | Tier 2 |
| VerificationLevel2Date | BI_DB_CIDFirstDates | VerificationLevel2Date | Passthrough | Tier 2 |
| VerificationLevel3Date | BI_DB_CIDFirstDates | VerificationLevel3Date | Passthrough | Tier 2 |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via RegulationID → DWHRegulationID | Tier 1 |
| DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via DesignatedRegulationID → DWHRegulationID | Tier 1 |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup via CountryID → DWHCountryID | Tier 1 |
| Closed_PNL_Last_Year | DWH_dbo.Dim_Position | NetProfit | SUM WHERE CloseDateID >= @YearBeforeID | Tier 2 |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | At yesterday's DateID | Tier 2 |
| UnrealizedEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) | Tier 2 |
| Opened_PNL | DWH_dbo.V_Liabilities | PositionPnL | At yesterday's DateID | Tier 2 |
| Appropriatness_Status | External_ComplianceStateDB | RestrictionStatus.Name | WHERE RestrictionStatusReasonID=14, since 2020-05-01 | Tier 2 |
| UpdateDate | — | — | GETDATE() | Tier 5 |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (QuestionId=32, AnswerId=151, since 2021-04-01)
  + DWH_dbo.Dim_Customer (GCID JOIN, demographics)
  + DWH_dbo.Dim_Regulation (×2: RegulationID and DesignatedRegulationID)
  + DWH_dbo.Dim_Country (CountryID → Name)
  + BI_DB_CIDFirstDates (VL2/VL3 dates)
  |
  → #pop (self-identified vulnerable customers)
  |
  + V_Liabilities (equity and PnL at yesterday)
  + Dim_Position (closed PnL last 365 days)
  + ComplianceStateDB (appropriateness restriction status, ReasonID=14)
  |
  |-- SP_Vulnerable_Customers (TRUNCATE + INSERT) ---|
  v
BI_DB_dbo.BI_DB_Vulnerable_Customers (~20.6K rows, daily snapshot)
```
