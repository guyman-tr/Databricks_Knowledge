# DWH_dbo.V_Customers

> Flattened daily customer state view — expands Fact_SnapshotCustomer's SCD Type 2 date ranges into one row per customer per calendar day, making it trivial to query "what was this customer's state on day X?"

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Tables** | DWH_dbo.Fact_SnapshotCustomer, DWH_dbo.V_M2M_Date_DateRange |
| **Purpose** | Daily-grain customer attribute access for BI queries |
| **Filter** | DateKey < TODAY (excludes future dates) |

---

## 1. Business Meaning

`V_Customers` is the primary daily-grain customer dimension view used by BI reports and downstream analytics. It solves the "date range expansion" problem: `Fact_SnapshotCustomer` stores customer state as SCD Type 2 rows with (FromDate, ToDate) date ranges, but most BI queries need to know a customer's state on a specific calendar date.

This view JOINs `Fact_SnapshotCustomer` to `V_M2M_Date_DateRange` to "fan out" each date range into individual rows — one per customer per day. The result is a massive but simple-to-query table: for any (RealCID, DateID) pair, you get the customer's full attribute set on that day.

All columns use `ISNULL(column, 0)` to replace NULLs with zero, ensuring clean aggregation downstream. Note that several columns (`DemoCID`, `CustomerChangeTypeID`, `CurentValue`, `PreviousValue`, `DocsOK`, `Bankruptcy`, `PremiumAccount`, `Evangelist`) are legacy — present in Fact_SnapshotCustomer but not populated by the current ETL (always 0).

---

## 2. Elements

| # | Column | Type | Source | Description |
|---|--------|------|--------|-------------|
| 1 | GCID | int | ISNULL(Fact_SnapshotCustomer.GCID, 0) | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 — via Fact_SnapshotCustomer) |
| 2 | DateID | int | V_M2M_Date_DateRange.DateKey | Calendar date in YYYYMMDD format from the date range expansion view. Not from Fact_SnapshotCustomer directly — derived via DateRangeID JOIN. (Tier 2 — view DDL) |
| 3 | RealCID | int | ISNULL(Fact_SnapshotCustomer.RealCID, 0) | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 — via Fact_SnapshotCustomer) |
| 4 | DemoCID | int | ISNULL(Fact_SnapshotCustomer.DemoCID, 0) | [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 — via Fact_SnapshotCustomer) |
| 5 | CustomerChangeTypeID | int | ISNULL(Fact_SnapshotCustomer.CustomerChangeTypeID, 0) | [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=CountryID, 2=LabelID). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 — via Fact_SnapshotCustomer) |
| 6 | CurentValue | int | ISNULL(Fact_SnapshotCustomer.CurentValue, 0) | [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 — via Fact_SnapshotCustomer) |
| 7 | PreviousValue | int | ISNULL(Fact_SnapshotCustomer.PreviousValue, 0) | [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 — via Fact_SnapshotCustomer) |
| 8 | CountryID | int | ISNULL(Fact_SnapshotCustomer.CountryID, 0) | Customer's registered country. FK → Dim_Country. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 9 | LabelID | int | ISNULL(Fact_SnapshotCustomer.LabelID, 0) | Business label/brand the customer belongs to. FK → Dim_Label. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 10 | LanguageID | int | ISNULL(Fact_SnapshotCustomer.LanguageID, 0) | Customer's preferred language. FK → Dim_Language. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 11 | VerificationLevelID | int | ISNULL(Fact_SnapshotCustomer.VerificationLevelID, 0) | KYC verification level. FK → Dim_VerificationLevel. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 12 | DocsOK | int | ISNULL(Fact_SnapshotCustomer.DocsOK, 0) | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 — via Fact_SnapshotCustomer) |
| 13 | PlayerStatusID | int | ISNULL(Fact_SnapshotCustomer.PlayerStatusID, 0) | Current account status (active, blocked, closed, etc.). FK → Dim_PlayerStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 14 | Bankruptcy | int | ISNULL(Fact_SnapshotCustomer.Bankruptcy, 0) | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 — via Fact_SnapshotCustomer) |
| 15 | RiskStatusID | int | ISNULL(Fact_SnapshotCustomer.RiskStatusID, 0) | Risk assessment status. FK → Dim_RiskStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 16 | RiskClassificationID | int | ISNULL(Fact_SnapshotCustomer.RiskClassificationID, 0) | Risk classification tier. FK → Dim_RiskClassification. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 17 | CommunicationLanguageID | int | ISNULL(Fact_SnapshotCustomer.CommunicationLanguageID, 0) | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 18 | PremiumAccount | int | ISNULL(Fact_SnapshotCustomer.PremiumAccount, 0) | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 — via Fact_SnapshotCustomer) |
| 19 | Evangelist | int | ISNULL(Fact_SnapshotCustomer.Evangelist, 0) | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 — via Fact_SnapshotCustomer) |
| 20 | GuruStatusID | int | ISNULL(Fact_SnapshotCustomer.GuruStatusID, 0) | Popular Investor (PI) status. FK → Dim_GuruStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 21 | RegulationID | int | ISNULL(Fact_SnapshotCustomer.RegulationID, 0) | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 22 | AccountStatusID | int | ISNULL(Fact_SnapshotCustomer.AccountStatusID, 0) | Account lifecycle status. FK → Dim_AccountStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 23 | AccountManagerID | int | ISNULL(Fact_SnapshotCustomer.AccountManagerID, 0) | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 24 | PlayerLevelID | int | ISNULL(Fact_SnapshotCustomer.PlayerLevelID, 0) | Real vs demo account tier. FK → Dim_PlayerLevel (Tier 2 — Fact_SnapshotCustomer) |
| 25 | AccountTypeID | int | ISNULL(Fact_SnapshotCustomer.AccountTypeID, 0) | Account type (Real=1, Demo=2, CopyFund=9, etc.). FK → Dim_AccountType. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 26 | IsDepositor | bit | Fact_SnapshotCustomer.IsDepositor | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 — via Fact_SnapshotCustomer) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Fact_SnapshotCustomer | `a.DateRangeID = b.DateRangeID` | Base customer state (SCD Type 2) | Inbound |
| DWH_dbo.V_M2M_Date_DateRange | Same JOIN | Date range expansion | Inbound |
| DWH_dbo.Dim_Country | CountryID | Country lookup | Outbound FK |
| DWH_dbo.Dim_Label | LabelID | Label/brand lookup | Outbound FK |
| DWH_dbo.Dim_Language | LanguageID, CommunicationLanguageID | Language lookups | Outbound FK |
| DWH_dbo.Dim_PlayerStatus | PlayerStatusID | Account status lookup | Outbound FK |
| DWH_dbo.Dim_Regulation | RegulationID | Regulatory jurisdiction lookup | Outbound FK |
| DWH_dbo.Dim_GuruStatus | GuruStatusID | PI status lookup | Outbound FK |
| DWH_dbo.Dim_AccountType | AccountTypeID | Account type lookup | Outbound FK |

---

## 4. ETL & Data Pipeline

No ETL — computed view. The result set grows as Fact_SnapshotCustomer and Dim_Range accumulate new rows daily.

**Cardinality warning**: This is an extremely high-cardinality view. With ~46M customers × ~7,000 days of history = potentially 300+ billion virtual rows. Always filter on DateID and/or RealCID.

---

## 5. Referenced By

| Object | Usage |
|--------|-------|
| BI reports and dashboards | Primary customer state query interface — "what was customer X's status on day Y?" |
| Regulatory reporting | Historical customer attribute lookups for compliance |
| SP_Fact_Guru_Copiers | Indirectly via Fact_SnapshotCustomer + V_M2M_Date_DateRange |

---

## 6. Business Logic & Patterns

### ISNULL(column, 0) Pattern

All columns except `IsDepositor` are wrapped in `ISNULL(column, 0)`. This guarantees no NULL values in the output — important for BI tools that handle NULLs inconsistently. `IsDepositor` is the only exception (passed through as-is).

### DateKey < TODAY Filter

```sql
WHERE b.DateKey < CAST(CONVERT(VARCHAR(MAX), GETDATE(), 112) AS INT)
```

Excludes today and future dates. This aligns with the DWH convention: only completed days are queryable. Today's data is still being processed by the overnight ETL.

### Legacy Columns

8 columns (`DemoCID`, `CustomerChangeTypeID`, `CurentValue`, `PreviousValue`, `DocsOK`, `Bankruptcy`, `PremiumAccount`, `Evangelist`) are always 0. They exist for backward compatibility with legacy reports that reference these columns.

---

## 7. Query Advisory

### Performance Considerations

- **ALWAYS filter on DateID** — unfilitered queries scan the full ~300B+ row fan-out
- **Filter on RealCID** for single-customer lookups — leverages HASH(RealCID) distribution on Fact_SnapshotCustomer
- **Consider querying Fact_SnapshotCustomer directly** with DateRangeID if you need range-based rather than point-in-time lookups

### Recommended Patterns

```sql
-- Customer state on a specific date
SELECT *
FROM [DWH_dbo].[V_Customers]
WHERE RealCID = 12345678
  AND DateID = 20260318;

-- Active depositors in a regulation on a specific date
SELECT RegulationID, COUNT(DISTINCT RealCID) AS depositor_count
FROM [DWH_dbo].[V_Customers]
WHERE DateID = 20260318
  AND IsDepositor = 1
  AND PlayerStatusID IN (1, 2)  -- active statuses
GROUP BY RegulationID;
```

### Anti-Patterns

- **Never `SELECT COUNT(*) FROM V_Customers`** — will attempt to materialize 300B+ rows
- **Avoid wide date ranges without RealCID filter** — each additional date multiplies the row count

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862) | References Dim_Customer and snapshot tables as core DWH catalog |
| [DWH Usage](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12788367785) | Documents downstream service usage of DWH views including customer snapshot data |
| [DWH mapping - IsDepositor](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/13091733669) | Detailed logic for IsDepositor calculation in Fact_SnapshotCustomer |

---

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Phases: 9/14 | Batch: 16*
*Tiers: 23 T1, 2 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10*
*Object: DWH_dbo.V_Customers | Type: View | Base Tables: DWH_dbo.Fact_SnapshotCustomer, DWH_dbo.V_M2M_Date_DateRange*
