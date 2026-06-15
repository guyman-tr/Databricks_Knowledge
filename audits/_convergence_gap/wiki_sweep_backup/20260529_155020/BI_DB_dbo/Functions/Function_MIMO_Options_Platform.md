# Function_MIMO_Options_Platform

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | MIMO |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 14 (T1: 6, T2: 8) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Surfaces MIMO-style cash activity for US **options** (Apex) accounts: deposits and withdrawals with amounts and metadata, and derives **first-time deposit** and **global FTD** flags by reconciling cash activity to `Dim_Customer` first-deposit facts for platform 2.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| External_Sodreconciliation_apex_EXT869_CashActivity | BI_DB_dbo |
| External_USABroker_Apex_Options | BI_DB_dbo |
| Dim_Customer | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | OfficeCode | External_Sodreconciliation_apex_EXT869_CashActivity.OfficeCode | Passthrough from BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity.OfficeCode (no upstream wiki) | T1 |
| 2 | RegisteredRepCode | External_Sodreconciliation_apex_EXT869_CashActivity.RegisteredRepCode | Passthrough from BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity.RegisteredRepCode (no upstream wiki) | T1 |
| 3 | AccountNumber | External_Sodreconciliation_apex_EXT869_CashActivity.AccountNumber | Passthrough from BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity.AccountNumber (no upstream wiki) | T1 |
| 4 | DateID | External_Sodreconciliation_apex_EXT869_CashActivity.ProcessDate | CONVERT(nvarchar(8), ProcessDate, 112) | T2 |
| 5 | Date | External_Sodreconciliation_apex_EXT869_CashActivity.ProcessDate | CONVERT(date, ProcessDate) | T2 |
| 6 | RealCID | Dim_Customer.RealCID | Via Options GCID → Dim_Customer (MIMORecords) | T1 |
| 7 | MIMOAction | External_Sodreconciliation_apex_EXT869_CashActivity.PayTypeCode | CASE WHEN PayTypeCode = 'C' THEN 'Deposit' WHEN 'D' THEN 'Withdraw' END | T2 |
| 8 | AmountUSD | External_Sodreconciliation_apex_EXT869_CashActivity.Amount | ABS(Amount) WHERE OfficeCode IN ('4GS','5GU'); AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104'); EnteredBy IN ('ACH','WRD') OR TerminalID = 'OMJNL' | T2 |
| 9 | IsFTD | External_Sodreconciliation_apex_EXT869_CashActivity, CTE FinalFTD | CASE WHEN FinalFTD.TransactionID IS NOT NULL THEN 1 ELSE 0 END | T2 |
| 10 | IsInternalTransfer | External_Sodreconciliation_apex_EXT869_CashActivity.TerminalID, EnteredBy | CASE WHEN TerminalID = 'OMJNL' THEN 1 ELSE 0 END | T2 |
| 11 | TransactionID | External_Sodreconciliation_apex_EXT869_CashActivity.ACATSControlNumber | Passthrough from BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity.ACATSControlNumber (no upstream wiki) | T1 |
| 12 | IsGlobalFTD | Dim_Customer, CTE GLOBAL_FTD / FinalFTD | ISNULL(IsGlobalFTD, 0) from FTD match to Dim_Customer first deposit | T2 |
| 13 | IsValidCustomer | Fact_SnapshotCustomer.IsValidCustomer | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |
| 14 | IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) (via Fact_SnapshotCustomer) | T2 |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
