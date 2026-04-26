# BI_DB_dbo.BI_DB_Finance_Staking_Report

> ~500-row monthly crypto staking finance summary aggregating AirDrop reward positions and staking compensation payments by regulation and staking month — from Nov 2020 to present. Loaded by SP_Finance_Staking_Report via DELETE-on-matching-month + INSERT. Two source streams: AirDrop positions from Dim_Position (InstrumentID 100017/100026, IsAirDrop=1) and Compensations from BI_DB_Staking_Platform_Compensations.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Finance_Staking_Report (Dim_Position + Dim_Customer + Dim_Regulation + BI_DB_Staking_Platform_Compensations) |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE matching StakingMonth + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a monthly finance summary for crypto staking operations. Each row represents one type (AirDrop or Compensations) × regulation × staking month combination, with a single Total_Dollars aggregate.

**AirDrop**: SUM(Amount) from Dim_Position for positions on InstrumentID 100017 or 100026 (crypto staking instruments) where IsAirDrop=1 and OpenDateID is within a rolling 2-month window. The staking month is derived as the month BEFORE the position's OpenOccurred month — e.g., a position opened in April 2026 counts toward the March 2026 staking month.

**Compensations**: SUM(Payment) from BI_DB_Staking_Platform_Compensations for credits within a 2-month window around the report date. Same month-shift logic applies to CreditDate.

**Data shape**: ~500 rows spanning Nov 2020 to Mar 2026. Typically 8 regulations per type per month (CySEC, FCA, ASIC & GAML, FSA Seychelles, FSRA, FinCEN+FINRA, ASIC, BVI) — total ~16 rows per month. AirDrop dominates by dollar amount (CySEC ~$167K/month, FCA ~$134K/month). Compensations are smaller (CySEC ~$15K/month).

**ETL pattern**: SP_Finance_Staking_Report runs daily via SB_Daily. It DELETEs rows matching the AirDrop StakingMonth from the table, then INSERTs the fresh AirDrop + Compensations UNION. This means each run refreshes the most recent staking month's data.

---

## 2. Business Logic

### 2.1 Staking Month Derivation

**What**: Maps a date to its staking month — always the month BEFORE the event date.
**Columns Involved**: StakingMonth, StakingMonthID
**Rules**:
- StakingMonth = 3-letter month abbreviation + '-' + 4-digit year (e.g., 'Mar-2026')
- StakingMonthID = YYYYMM as varchar(6) (e.g., '202603')
- A position opened on 2026-04-15 has StakingMonth = 'Mar-2026' (month before OpenOccurred)
- This shift ensures that rewards earned in month M are attributed to month M for reporting, even when positions are opened early in month M+1

### 2.2 AirDrop Filter

**What**: Identifies crypto staking airdrop positions.
**Columns Involved**: type, Total_Dollars
**Rules**:
- InstrumentID IN (100017, 100026) — specific crypto staking instruments
- IsAirDrop = 1 — flag on Dim_Position
- OpenDateID > @DateMonthID — only positions newer than 2 months before @Date
- Total_Dollars = SUM(Dim_Position.Amount) per regulation per staking month

### 2.3 Compensations Filter

**What**: Identifies staking platform compensation payments.
**Columns Involved**: type, Total_Dollars
**Rules**:
- Source: BI_DB_Staking_Platform_Compensations
- CreditDate BETWEEN @DateMonth AND EOMONTH(DATEADD(MONTH,1,@DateMonth)) — 2-month window
- Total_Dollars = SUM(Payment) per regulation per staking month

### 2.4 Delete/Insert Pattern

**What**: Idempotent refresh — only replaces the most recent staking month.
**Rules**:
- DELETE joins BI_DB_Finance_Staking_Report to #Temp_AirDrop on StakingMonth
- Then INSERT #Temp_AirDrop UNION ALL #Temp_Compensations
- Historical months are preserved unless they match the current AirDrop batch

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** with **HEAP** — very small table (~500 rows). No optimization needed; full scan is trivial.
- StakingMonthID is varchar(6), not int — use string comparison.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly staking totals by type | `GROUP BY type, StakingMonthID ORDER BY StakingMonthID DESC` |
| Regulation breakdown for a month | `WHERE StakingMonthID = '202603'` |
| AirDrop trend over time | `WHERE type = 'AirDrop' GROUP BY StakingMonthID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Regulation | Regulation_Name = Name | Get RegulationID for cross-joins |

### 3.4 Gotchas

- **StakingMonthID is varchar, not int**: Use string comparison ('202603'), not integer comparison.
- **StakingMonth format**: 'Mar-2026' — 3-letter abbreviation with hyphen and 4-digit year.
- **DELETE scope**: Only AirDrop months are deleted on refresh — Compensations for older months may be stale if the source data changes retroactively.
- **~500 rows total**: This is an extremely small table. SELECT * is fine.
- **Regulation_Name 'None'**: Appears in early months (pre-2022) for customers without a regulation assignment.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki — description copied verbatim from documented production source |
| Tier 2 | SP code — description derived from ETL stored procedure logic |
| Tier 3 | Live data — description inferred from data sampling and distribution analysis |
| Tier 4 | Inferred — best available knowledge, limited confidence |
| Tier 5 | Expert Review — assigned by subject matter expert or pipeline operator |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | type | varchar(13) | NO | Record type: 'AirDrop' for crypto staking airdrop reward positions (from Dim_Position WHERE IsAirDrop=1 AND InstrumentID IN (100017, 100026)), 'Compensations' for staking platform compensation payments (from BI_DB_Staking_Platform_Compensations). (Tier 2 — SP_Finance_Staking_Report) |
| 2 | Regulation_Name | varchar(50) | YES | Regulation name from Dim_Regulation via Dim_Customer.RegulationID. Values: CySEC, FCA, ASIC & GAML, FSA Seychelles, FSRA, FinCEN+FINRA, ASIC, BVI, None, eToroUS, FinCEN. (Tier 2 — SP_Finance_Staking_Report via Dim_Regulation.Name) |
| 3 | StakingMonth | nvarchar(8) | NO | Staking month label in 'Mon-YYYY' format (e.g., 'Mar-2026'). Derived as the month BEFORE the event date: CONCAT(LEFT(DATENAME(MONTH, EOMONTH(DATEADD(MONTH,-1,date))), 3), '-', year). (Tier 2 — SP_Finance_Staking_Report) |
| 4 | StakingMonthID | varchar(6) | YES | Staking month as YYYYMM string (e.g., '202603'). Derived from EOMONTH of the month before the event date. Use for sorting and filtering (varchar comparison). (Tier 2 — SP_Finance_Staking_Report) |
| 5 | Total_Dollars | money | YES | Total USD amount for this type × regulation × staking month. SUM(Dim_Position.Amount) for AirDrop, SUM(BI_DB_Staking_Platform_Compensations.Payment) for Compensations. CySEC AirDrop typically ~$167K/month, FCA ~$134K/month. (Tier 2 — SP_Finance_Staking_Report) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| type | Computed | — | Hardcoded 'AirDrop' or 'Compensations' |
| Regulation_Name | DWH_dbo.Dim_Regulation | Name | Via Dim_Customer.RegulationID |
| StakingMonth | Dim_Position.OpenOccurred / Compensations.CreditDate | — | Month-1 abbreviation format |
| StakingMonthID | Dim_Position.OpenOccurred / Compensations.CreditDate | — | YYYYMM of month-1 |
| Total_Dollars | Dim_Position.Amount / Compensations.Payment | Amount / Payment | SUM aggregation |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (InstrumentID IN (100017, 100026), IsAirDrop=1, OpenDateID > @DateMonthID)
  + DWH_dbo.Dim_Customer (CID → RealCID)
  + DWH_dbo.Dim_Regulation (RegulationID → Name)
    → #Temp_AirDrop (SUM(Amount) GROUP BY Regulation, StakingMonth)

BI_DB_dbo.BI_DB_Staking_Platform_Compensations (CreditDate in 2-month window)
  + DWH_dbo.Dim_Customer + DWH_dbo.Dim_Regulation
    → #Temp_Compensations (SUM(Payment) GROUP BY Regulation, StakingMonth)

#Temp_AirDrop UNION ALL #Temp_Compensations
  |-- SP_Finance_Staking_Report @Date (DELETE match + INSERT, SB_Daily P0) ---|
  v
BI_DB_dbo.BI_DB_Finance_Staking_Report (~500 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Regulation_Name | DWH_dbo.Dim_Regulation | Regulation name (text, not ID) |
| Total_Dollars (AirDrop) | DWH_dbo.Dim_Position | Position amounts for staking instruments |
| Total_Dollars (Compensations) | BI_DB_dbo.BI_DB_Staking_Platform_Compensations | Staking compensation payments |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Monthly Staking Summary by Type

```sql
SELECT
    type,
    StakingMonthID,
    StakingMonth,
    SUM(Total_Dollars) AS TotalUSD
FROM [BI_DB_dbo].[BI_DB_Finance_Staking_Report]
GROUP BY type, StakingMonthID, StakingMonth
ORDER BY StakingMonthID DESC, type
```

### 7.2 Regulation Breakdown for Latest Month

```sql
SELECT
    type,
    Regulation_Name,
    Total_Dollars
FROM [BI_DB_dbo].[BI_DB_Finance_Staking_Report]
WHERE StakingMonthID = (SELECT MAX(StakingMonthID) FROM [BI_DB_dbo].[BI_DB_Finance_Staking_Report])
ORDER BY type, Total_Dollars DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 6/6, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Finance_Staking_Report | Type: Table | Production Source: SP_Finance_Staking_Report*
