# DWH_dbo.V_Fact_SnapshotCustomer_FromDateID

## 1. Overview

| Property | Value |
|----------|-------|
| **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer_FromDateID]` |
| **Type** | View |
| **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range` |
| **Purpose** | Exposes Fact_SnapshotCustomer with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range boundary filtering without expanding to daily rows. |

## 2. Business Context

Structurally identical pattern to `V_Fact_SnapshotEquity_FromDateID`. Denormalizes the SCD Type 2 `DateRangeID` by joining `Dim_Range` to expose date boundaries alongside all `Fact_SnapshotCustomer` columns. Preserves the range-level grain (one row per customer per date range).

## 3. View Definition

```sql
SELECT R.FromDateID, R.ToDateID, SC.*
FROM DWH_dbo.Fact_SnapshotCustomer SC WITH(NOLOCK)
JOIN DWH_dbo.Dim_Range R WITH(NOLOCK)
  ON SC.DateRangeID = R.DateRangeID
```

## 4. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | FromDateID | int | Dim_Range.FromDateID | Start date of the customer snapshot range (YYYYMMDD integer). (Tier 1 — inherited from Dim_Range wiki) |
| 2 | ToDateID | int | Dim_Range.ToDateID | End date of the customer snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 1 — inherited from Dim_Range wiki) |
| 3 | GCID | int | Fact_SnapshotCustomer.GCID | Global Customer ID — cross-platform identifier linking RealCID to demo and external systems. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 4 | RealCID | int | Fact_SnapshotCustomer.RealCID | Real (funded) customer ID. Hash distribution key. Primary customer identifier. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 5 | DemoCID | int | Fact_SnapshotCustomer.DemoCID | [UNVERIFIED] Legacy: Demo account customer ID. NOT populated by current SP. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 6 | CustomerChangeTypeID | tinyint | Fact_SnapshotCustomer.CustomerChangeTypeID | [UNVERIFIED] Legacy: type of change that created this snapshot row. NOT populated by current SP. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 7 | CurentValue | int | Fact_SnapshotCustomer.CurentValue | [UNVERIFIED] Legacy: current value of changed attribute. NOT populated. Column name has typo ("Curent"). (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 8 | PreviousValue | int | Fact_SnapshotCustomer.PreviousValue | [UNVERIFIED] Legacy: previous value of changed attribute. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 9 | CountryID | int | Fact_SnapshotCustomer.CountryID | Customer's registered country. FK to Dim_Country. Key filter for valid customer segmentation. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 10 | LabelID | int | Fact_SnapshotCustomer.LabelID | Brand/label associated with customer (e.g., eToro UK). FK to Dim_Label. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 11 | LanguageID | int | Fact_SnapshotCustomer.LanguageID | Customer's preferred interface language. FK to Dim_Language. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 12 | VerificationLevelID | int | Fact_SnapshotCustomer.VerificationLevelID | KYC verification level. FK to Dim_VerificationLevel. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 13 | DocsOK | smallint | Fact_SnapshotCustomer.DocsOK | [UNVERIFIED] Legacy: documents verified flag. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 14 | PlayerStatusID | int | Fact_SnapshotCustomer.PlayerStatusID | Customer lifecycle status. FK to Dim_PlayerStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 15 | Bankruptcy | smallint | Fact_SnapshotCustomer.Bankruptcy | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 16 | RiskStatusID | int | Fact_SnapshotCustomer.RiskStatusID | Customer risk assessment status. FK to Dim_RiskStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 17 | RiskClassificationID | int | Fact_SnapshotCustomer.RiskClassificationID | Risk classification tier for compliance. FK to Dim_RiskClassification. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 18 | CommunicationLanguageID | int | Fact_SnapshotCustomer.CommunicationLanguageID | Preferred communication language (may differ from interface language). FK to Dim_Language. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 19 | PremiumAccount | smallint | Fact_SnapshotCustomer.PremiumAccount | [UNVERIFIED] Legacy: premium account flag. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 20 | Evangelist | smallint | Fact_SnapshotCustomer.Evangelist | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated. (Tier 4 — inherited from Fact_SnapshotCustomer wiki) |
| 21 | GuruStatusID | smallint | Fact_SnapshotCustomer.GuruStatusID | Popular Investor (Guru) program status. FK to Dim_GuruStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 22 | UpdateDate | datetime | Fact_SnapshotCustomer.UpdateDate | DWH load timestamp. Not the customer event date. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 23 | RegulationID | tinyint | Fact_SnapshotCustomer.RegulationID | Customer's assigned regulatory jurisdiction. FK to Dim_Regulation. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 24 | AccountStatusID | int | Fact_SnapshotCustomer.AccountStatusID | Account enabled/suspended status. FK to Dim_AccountStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 25 | AccountManagerID | int | Fact_SnapshotCustomer.AccountManagerID | Assigned account manager (sales/retention). FK to Dim_Manager. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 26 | PlayerLevelID | int | Fact_SnapshotCustomer.PlayerLevelID | Account tier (4=demo, other=real tiers). FK to Dim_PlayerLevel. Critical for IsValidCustomer. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 27 | AccountTypeID | int | Fact_SnapshotCustomer.AccountTypeID | Account type (e.g., 7=Employee, 9=excluded). FK to Dim_AccountType. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 28 | DateRangeID | bigint | Fact_SnapshotCustomer.DateRangeID | SCD2 range key: 12-digit bigint = YYYYMMDD + MMDD. Join to Dim_Range for FromDateID/ToDateID. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 29 | IsDepositor | bit | Fact_SnapshotCustomer.IsDepositor | 1 if customer has made at least one real-money deposit. Never reverted to 0 once set. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 30 | PendingClosureStatusID | tinyint | Fact_SnapshotCustomer.PendingClosureStatusID | Status of pending account closure request. FK to Dim_PendingClosureStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 31 | DocumentStatusID | int | Fact_SnapshotCustomer.DocumentStatusID | KYC document review status. FK to Dim_DocumentStatus. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |
| 32 | SuitabilityTestStatusID | int | Fact_SnapshotCustomer.SuitabilityTestStatusID | MiFID suitability test completion status. (Tier 1 — inherited from Fact_SnapshotCustomer wiki) |

---
*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Batch: 17 | 32 columns expanded (30 Tier 1 from Fact_SnapshotCustomer wiki + 2 from Dim_Range) | Sources: SSDT DDL, Fact_SnapshotCustomer.md, Dim_Range.md*
