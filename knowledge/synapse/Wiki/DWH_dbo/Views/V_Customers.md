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

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | GCID | int | Global Customer ID — unique cross-platform identifier. ISNULL → 0. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 2 | DateID | int | Calendar date in YYYYMMDD format from V_M2M_Date_DateRange. Not from Fact_SnapshotCustomer directly. (Tier 2 — view DDL) |
| 3 | RealCID | int | Real-money account Customer ID. ISNULL → 0. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 4 | DemoCID | int | Demo account Customer ID. Legacy — always 0 in current ETL. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 5 | CustomerChangeTypeID | int | Change type that triggered this snapshot row. Legacy — always 0 in current ETL. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 6 | CurentValue | int | Current attribute value at time of change. Legacy — always 0 in current ETL. Note typo: "Curent" not "Current". (Tier 1 — Fact_SnapshotCustomer wiki) |
| 7 | PreviousValue | int | Previous attribute value before change. Legacy — always 0 in current ETL. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 8 | CountryID | int | Customer's registered country. FK → Dim_Country. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 9 | LabelID | int | Business label/brand the customer belongs to. FK → Dim_Label. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 10 | LanguageID | int | Customer's preferred language. FK → Dim_Language. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 11 | VerificationLevelID | int | KYC verification level. FK → Dim_VerificationLevel. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 12 | DocsOK | int | Document verification status. Legacy — always 0 in current ETL. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 13 | PlayerStatusID | int | Current account status (active, blocked, closed, etc.). FK → Dim_PlayerStatus. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 14 | Bankruptcy | int | Bankruptcy flag. Legacy — always 0 in current ETL. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 15 | RiskStatusID | int | Risk assessment status. FK → Dim_RiskStatus. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 16 | RiskClassificationID | int | Risk classification tier. FK → Dim_RiskClassification. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 17 | CommunicationLanguageID | int | Language used for customer communications. FK → Dim_Language. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 18 | PremiumAccount | int | Premium account flag. Legacy — always 0 in current ETL. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 19 | Evangelist | int | Evangelist program flag. Legacy — always 0 in current ETL. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 20 | GuruStatusID | int | Popular Investor (PI) status. FK → Dim_GuruStatus. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 21 | RegulationID | int | Regulatory jurisdiction. FK → Dim_Regulation. Sourced from RegulationChangeLog, not BO. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 22 | AccountStatusID | int | Account lifecycle status. FK → Dim_AccountStatus. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 23 | AccountManagerID | int | Assigned account manager. FK → Dim_Manager. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 24 | PlayerLevelID | int | Gamification/tier level. FK → Dim_PlayerLevel. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 25 | AccountTypeID | int | Account type (Real=1, Demo=2, CopyFund=9, etc.). FK → Dim_AccountType. (Tier 1 — Fact_SnapshotCustomer wiki) |
| 26 | IsDepositor | bit | Whether the customer has ever deposited. Not wrapped in ISNULL. (Tier 1 — Fact_SnapshotCustomer wiki) |

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

*Generated: 2026-03-19 | Quality: 8.2/10 (★★★★☆) | Phases: 9/14*
*Tiers: 23 T1, 2 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10*
*Object: DWH_dbo.V_Customers | Type: View | Base Tables: DWH_dbo.Fact_SnapshotCustomer, DWH_dbo.V_M2M_Date_DateRange*
