# BI_DB_dbo.BI_DB_M_AML_Report — Column Lineage

Generated: 2026-04-22 | Batch: 29 | Writer SP: SP_M_AML_Report

## ETL Pipeline Summary

| Property | Value |
|----------|-------|
| **Writer SP** | `BI_DB_dbo.SP_M_AML_Report` |
| **Author** | Unknown (no DDL comment) |
| **Load Pattern** | DELETE WHERE EOM + INSERT (monthly partition upsert) |
| **Also Writes** | `BI_DB_dbo.BI_DB_M_AML_Report_AGG` (aggregated companion) |
| **Frequency** | Monthly (per EOM parameter) |
| **Row Count** | ~144,666,513 (28 EOM months, 2023-12 to 2026-03) |
| **UC Target** | Not Migrated |

## Column Lineage

| Column | Source Table | Source Column | Transform | Tier |
|--------|-------------|---------------|-----------|------|
| CID | Fact_SnapshotCustomer | RealCID | passthrough | Tier 1 — Customer.CustomerStatic |
| Regulation | Dim_Regulation | Name | lookup via Fact_SnapshotCustomer.RegulationID | Tier 2 — SP_M_AML_Report |
| Country | Dim_Country | Name | lookup via Fact_SnapshotCustomer.CountryID | Tier 1 — Dictionary.Country |
| PlayerStatus | Dim_PlayerStatus | Name | lookup via Fact_SnapshotCustomer.PlayerStatusID | Tier 2 — SP_M_AML_Report |
| PlayerStatusReason | Dim_PlayerStatusReasons | Name | lookup via Fact_SnapshotCustomer.PlayerStatusReasonID; LEFT JOIN | Tier 2 — SP_M_AML_Report |
| Club | Dim_PlayerLevel | Name | lookup via Fact_SnapshotCustomer.PlayerLevelID | Tier 2 — SP_M_AML_Report |
| RiskGroup | Dim_Country | RiskGroupID | passthrough (country-level risk); renamed from RiskGroupID | Tier 1 — Dictionary.Country |
| RiskScore | External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | passthrough; LEFT JOIN on CID | Tier 2 — SP_M_AML_Report |
| Is_FTD | Dim_Customer | FirstDepositDate | CASE WHEN FirstDepositDate BETWEEN @StartDateTime AND @EndDateTime | Tier 2 — SP_M_AML_Report |
| ScreeningStatus | Dim_ScreeningStatus | Name | lookup via Dim_Customer.ScreeningStatusID; LEFT JOIN | Tier 2 — SP_M_AML_Report |
| HasWallet | Dim_Customer | HasWallet | passthrough | Tier 1 — BackOffice.Customer |
| Is_Active | Fact_CustomerAction | RealCID | CASE WHEN EXISTS (ActionTypeID IN (1–8,39–40,42–43) within 12 months) | Tier 2 — SP_M_AML_Report |
| Wire_Transactions | Fact_BillingDeposit | DepositID | COUNT where FundingTypeID=2, PaymentStatusID=2, AmountUSD≥150000, in month; ISNULL→0 | Tier 2 — SP_M_AML_Report |
| Wire_Amount | Fact_BillingDeposit | AmountUSD | SUM where same filter as Wire_Transactions; ISNULL→0 | Tier 2 — SP_M_AML_Report |
| Prev_Regulation | Fact_RegulationTransfer + Dim_Regulation | FromRegulationID → Name | most recent regulation change in month; ROW_NUMBER by Occurred DESC; LEFT JOIN | Tier 2 — SP_M_AML_Report |
| EOM | — | @Date param | EOMONTH(@Date) — snapshot partition date | Tier 5 — ETL metadata |
| UpdateDate | — | — | GETDATE() | Tier 5 — ETL metadata |
| VerificationLevelID | Dim_Customer | VerificationLevelID | passthrough; filtered to 2 or 3 only | Tier 1 — BackOffice.Customer |
| Is_EEA_EU_Country | Dim_Country | DWHCountryID | CASE WHEN in hardcoded 37-country EU/EEA list | Tier 2 — SP_M_AML_Report |
| AML_Sub_Entity | BI_DB_AML_SubEntity_Categorization | AML_Sub_Entity | passthrough; LEFT JOIN on CID | Tier 2 — SP_M_AML_Report |

## Source Objects

| Object | Schema | Purpose |
|--------|--------|---------|
| Fact_SnapshotCustomer | DWH_dbo | Base population: IsValidCustomer=1, IsDepositor=1, at EOM date (DateRangeID filter) |
| Dim_Customer | DWH_dbo | FirstDepositDate (Is_FTD), HasWallet, VerificationLevelID, ScreeningStatusID |
| Dim_Country | DWH_dbo | Country name, RiskGroupID, DWHCountryID (EEA/EU check) |
| Dim_Regulation | DWH_dbo | Regulation name text |
| Dim_PlayerStatus | DWH_dbo | Player status name text |
| Dim_PlayerLevel | DWH_dbo | Club/loyalty tier name text |
| Dim_PlayerStatusReasons | DWH_dbo | Player status reason name text |
| Dim_ScreeningStatus | DWH_dbo | Screening status name text |
| Fact_BillingDeposit | DWH_dbo | Wire_Transactions and Wire_Amount (FundingTypeID=2, ≥$150K) |
| Fact_CustomerAction | DWH_dbo | Is_Active flag (12-month activity lookback) |
| Fact_RegulationTransfer | DWH_dbo | Prev_Regulation (regulation changes in month) |
| BI_DB_AML_SubEntity_Categorization | BI_DB_dbo | AML_Sub_Entity (LEFT JOIN; daily snapshot) |
| External_RiskClassification_dbo_V_RiskClassificationDataLake | BI_DB_dbo | RiskScore (AML risk text; LEFT JOIN) |

## UC External Lineage

Not applicable — UC Target: Not Migrated.
