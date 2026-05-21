# DWH_dbo.V_Fact_SnapshotCustomer

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer]` |
| **Type** | View |
| **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range`, `Dim_Date` |
| **Purpose** | Expands Fact_SnapshotCustomer SCD2 date ranges into individual daily rows via `Dim_Range` + `Dim_Date` bridge. Adds `DateKey` for easy daily-grain queries. |

## 2. Business Context

This view converts the range-level SCD2 grain of `Fact_SnapshotCustomer` into a daily grain by joining through `Dim_Range` and `Dim_Date` (same pattern as `V_Fact_SnapshotEquity`). Each date range row is exploded into one row per day within the range, with `DateKey` identifying the specific day.

Unlike `V_Customers` (which applies ISNULL defaults and filters out today), this view exposes all raw columns including NULLs.

## 3. View Definition

```sql
SELECT DateKey, a.*
FROM DWH_dbo.Fact_SnapshotCustomer a WITH(NOLOCK)
JOIN DWH_dbo.Dim_Range b WITH(NOLOCK) ON a.DateRangeID = b.DateRangeID
JOIN DWH_dbo.Dim_Date d ON d.DateKey BETWEEN FromDateID AND ToDateID
```

## 4. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | DateKey | int | Dim_Date.DateKey | Specific date within the snapshot range (YYYYMMDD integer). One row per day per customer. (Tier 2 — view DDL) |
| 2 | GCID | int | Fact_SnapshotCustomer.GCID | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 — via Fact_SnapshotCustomer) |
| 3 | RealCID | int | Fact_SnapshotCustomer.RealCID | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 — via Fact_SnapshotCustomer) |
| 4 | DemoCID | int | Fact_SnapshotCustomer.DemoCID | [UNVERIFIED] Legacy: Demo account customer ID. NOT populated by current SP. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 5 | CustomerChangeTypeID | tinyint | Fact_SnapshotCustomer.CustomerChangeTypeID | [UNVERIFIED] Legacy: type of change that created this snapshot row. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 6 | CurentValue | int | Fact_SnapshotCustomer.CurentValue | [UNVERIFIED] Legacy: current value of changed attribute. NOT populated. Typo in name ("Curent"). (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 7 | PreviousValue | int | Fact_SnapshotCustomer.PreviousValue | [UNVERIFIED] Legacy: previous value of changed attribute. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 8 | CountryID | int | Fact_SnapshotCustomer.CountryID | Customer's registered country. FK to Dim_Country. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 9 | LabelID | int | Fact_SnapshotCustomer.LabelID | Brand/label (e.g., eToro UK). FK to Dim_Label. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 10 | LanguageID | int | Fact_SnapshotCustomer.LanguageID | Preferred interface language. FK to Dim_Language. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 11 | VerificationLevelID | int | Fact_SnapshotCustomer.VerificationLevelID | KYC verification level. FK to Dim_VerificationLevel. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 12 | DocsOK | smallint | Fact_SnapshotCustomer.DocsOK | [UNVERIFIED] Legacy: documents verified flag. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 13 | PlayerStatusID | int | Fact_SnapshotCustomer.PlayerStatusID | Customer lifecycle status. FK to Dim_PlayerStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 14 | Bankruptcy | smallint | Fact_SnapshotCustomer.Bankruptcy | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 15 | RiskStatusID | int | Fact_SnapshotCustomer.RiskStatusID | Customer risk assessment status. FK to Dim_RiskStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 16 | RiskClassificationID | int | Fact_SnapshotCustomer.RiskClassificationID | Risk classification tier for compliance. FK to Dim_RiskClassification. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 17 | CommunicationLanguageID | int | Fact_SnapshotCustomer.CommunicationLanguageID | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 18 | PremiumAccount | smallint | Fact_SnapshotCustomer.PremiumAccount | [UNVERIFIED] Legacy: premium account flag. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 19 | Evangelist | smallint | Fact_SnapshotCustomer.Evangelist | [UNVERIFIED] Legacy: evangelist flag. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 20 | GuruStatusID | smallint | Fact_SnapshotCustomer.GuruStatusID | Popular Investor (Guru) program status. FK to Dim_GuruStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 21 | UpdateDate | datetime | Fact_SnapshotCustomer.UpdateDate | DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 — via Fact_SnapshotCustomer) |
| 22 | RegulationID | tinyint | Fact_SnapshotCustomer.RegulationID | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 23 | AccountStatusID | int | Fact_SnapshotCustomer.AccountStatusID | Account enabled/suspended status. FK to Dim_AccountStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 24 | AccountManagerID | int | Fact_SnapshotCustomer.AccountManagerID | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 25 | PlayerLevelID | int | Fact_SnapshotCustomer.PlayerLevelID | Account tier (4=demo). FK to Dim_PlayerLevel. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 26 | AccountTypeID | int | Fact_SnapshotCustomer.AccountTypeID | Account type (7=Employee, 9=excluded). FK to Dim_AccountType. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 27 | DateRangeID | bigint | Fact_SnapshotCustomer.DateRangeID | SCD2 range key: 12-digit bigint. Join to Dim_Range for FromDateID/ToDateID. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 28 | IsDepositor | bit | Fact_SnapshotCustomer.IsDepositor | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 — via Fact_SnapshotCustomer) |
| 29 | PendingClosureStatusID | tinyint | Fact_SnapshotCustomer.PendingClosureStatusID | Pending account closure status. FK to Dim_PendingClosureStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 30 | DocumentStatusID | int | Fact_SnapshotCustomer.DocumentStatusID | KYC document review status. FK to Dim_DocumentStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 31 | SuitabilityTestStatusID | int | Fact_SnapshotCustomer.SuitabilityTestStatusID | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 — via Fact_SnapshotCustomer) |

## 5. Access Patterns

```sql
-- Daily customer snapshot for a specific CID and date range
SELECT * FROM DWH_dbo.V_Fact_SnapshotCustomer
WHERE CID = @CID AND DateKey BETWEEN @FromDate AND @ToDate;
```

---
*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Batch: 17 | 31 columns expanded (30 Tier 1 from Fact_SnapshotCustomer wiki + 1 DateKey) | Sources: SSDT DDL, Fact_SnapshotCustomer.md*
