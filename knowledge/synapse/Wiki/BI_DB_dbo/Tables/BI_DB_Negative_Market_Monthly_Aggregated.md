# BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated

> 1,923-row end-of-month CFD block compliance snapshot for March 2026 (single month retained per TRUNCATE+INSERT), tracking the count of customers subject to CFD trading restrictions under the EU MiFID II Negative Market test across 15 regulations and all countries — aggregated from BI_DB_Scored_Appropriateness_Negative_Market by the same SP on EOM trigger dates.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ComplianceStateDB.Compliance (CustomerRestrictions, UserTradingData, History.UserTradingData) via BI_DB_Scored_Appropriateness_Negative_Market |
| **Refresh** | Monthly EOM only — SP_BI_DB_Scored_Appropriateness_Negative_Market runs daily but populates this table ONLY when @Date = EOMONTH(@Date); TRUNCATE+INSERT each run (single month retained) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (EOMonth ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

Monthly end-of-month compliance snapshot that counts eToro customers across all regulations and countries who are subject to CFD trading restrictions ("CFD Blocked") under the EU MiFID II Negative Market appropriateness test framework. Each row represents one distinct combination of (EOMonth, DspositorInd, RegulationName, CountryName).

The table contains 1,923 rows for March 2026 (the most recently processed EOM). The TRUNCATE+INSERT design means only the **current month** is retained — no historical EOM snapshots accumulate. The March 2026 snapshot covers 18M total customers across 15 regulations; 3.68M (20.5%) are CFD-blocked. CySEC dominates with 10.5M customers (58.5% of total). The FCA is the second largest (3.7M, 18.6%), with 688K (18.6%) blocked — consistent with FCA appropriateness test enforcement.

The parent table `BI_DB_Scored_Appropriateness_Negative_Market` holds the individual-level data (one row per customer). This table provides the dimension-cross aggregated view for compliance reporting. The DspositorInd dimension splits depositors from non-depositors because the regulation used differs: depositors use their registration regulation (RegulationName), non-depositors use their designated regulation (DesignatedRegulationName).

**CRITICAL: `DspositorInd` is stored as int (DDL) but the SP inserts VARCHAR literals `'0'`/`'1'` via implicit conversion — always filter as integer (`DspositorInd = 1` not `= '1'`).**

---

## 2. Business Logic

### 2.1 End-of-Month Aggregation Gate

**What**: This table is only populated once per month, on the last calendar day.
**Columns Involved**: EOMonth, all columns
**Rules**:
- SP checks `IF @Date = EOMONTH(@Date)` — the block only executes on the last day of each month
- On that date, TRUNCATE removes all prior data, and a fresh INSERT loads the EOM snapshot
- On non-EOM dates, the SP still runs (populating the parent table) but this table remains unchanged

### 2.2 Depositor vs. Non-Depositor Regulation Split

**What**: Customers are classified by depositor status, and the regulation label differs based on that classification.
**Columns Involved**: DspositorInd, RegulationName
**Rules**:
- `DspositorInd = 1` (depositor): FTD_Date != '1900-01-01' AND FTD_Date <= @Date → uses `RegulationName` (the regulation at time of registration/FTD)
- `DspositorInd = 0` (non-depositor): all others → uses `DesignatedRegulationName` (current regulatory assignment)
- This split means the same CountryName can appear in the same EOMonth twice — once for depositors, once for non-depositors

### 2.3 CFD Block Status at EOM

**What**: CFDBlockedUsers counts customers who were actively restricted from CFD trading at month-end.
**Columns Involved**: CFDBlockedUsers, [Total Customers]
**Rules**:
- A customer is "CFD Blocked at EOM" if: BlockDate IS NOT NULL AND BlockDate <= @Date AND ISNULL(ReleaseDate, '2300-01-01') > @Date
- This captures customers currently in Blocked state (BlockDate in past, ReleaseDate in future or NULL)
- CFDBlockedUsers / [Total Customers] = CFD block rate per dimension bucket

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no distribution key advantage. CLUSTERED INDEX on EOMonth for ordered scans. With only one EOMonth value retained per run, all queries effectively scan the entire table. Use `WHERE EOMonth = (SELECT MAX(EOMonth) FROM BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated)` for defensive currency checks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| CFD block rate by regulation for current month | `SELECT RegulationName, SUM([Total Customers]) AS Total, SUM(CFDBlockedUsers) AS Blocked, CAST(SUM(CFDBlockedUsers)*100.0/NULLIF(SUM([Total Customers]),0) AS DECIMAL(5,2)) AS BlockPct FROM [BI_DB_dbo].[BI_DB_Negative_Market_Monthly_Aggregated] GROUP BY RegulationName ORDER BY Total DESC` |
| Depositor vs non-depositor block rate | `GROUP BY DspositorInd` — 0=Non-depositor, 1=Depositor |
| FCA block rate for UK customers | `WHERE RegulationName = 'FCA' AND DspositorInd = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | (no direct join — aggregation source) | Individual-level detail for drill-down |

### 3.4 Gotchas

- **Single-month table**: TRUNCATE+INSERT monthly — no historical data. Do NOT query for prior months.
- **DspositorInd as int vs varchar**: SP inserts `'0'`/`'1'` as varchar literals; DDL is int. Implicit conversion works but filter as `DspositorInd = 1` (integer).
- **`[Total Customers]` has a space**: Always bracket-quote: `[Total Customers]` in all queries and JOIN conditions.
- **Regulation string inconsistency**: `RegulationName` for depositors (RegistrationRegulation) vs `DesignatedRegulationName` for non-depositors — the same physical country can appear under different regulations for the two depositor buckets.
- **`ASIC & GAML`**: Appears as a combined regulation label (330 rows, 1.69M customers) — this is a dual-regulation market assignment, not a typo.
- **No country for "None" regulation**: 4 rows with RegulationName = 'None' — edge case for unassigned accounts.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production or DWH wiki |
| Tier 2 | Description derived from SP code analysis |
| Tier 3 | Description inferred from context and data patterns |
| Tier 4 | Description is best-available estimate; low confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | EOMonth | date | NO | End-of-month date for this compliance snapshot. SP assigns EOMONTH(@Date) — always the last calendar day of the month. With TRUNCATE+INSERT design, all rows share the same EOMonth (only one month retained). Currently 2026-03-31. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 2 | DspositorInd | int | YES | Depositor indicator for the aggregation dimension. 1=Depositor (FTD_Date != '1900-01-01' AND FTD_Date <= @Date), 0=Non-depositor. Stored as int but SP inserts varchar literals '0'/'1' via implicit cast. 1=1,043 rows (54.2%), 0=880 rows (45.8%). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 3 | RegulationName | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. For depositors (DspositorInd=1): the registration regulation. For non-depositors (DspositorInd=0): the designated regulation. 15 distinct values: CySEC (496 rows), ASIC (379), ASIC & GAML (330), FCA (301), FSA Seychelles (233), FSRA (104), BVI (26), FinCEN (18), MAS (12), FinCEN+FINRA (10), NYDFS+FINRA (4), None (4), FINRAONLY (4), NFA (1), eToroUS (1). (Tier 1 — Dictionary.Regulation) |
| 4 | CountryName | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — Dictionary.Country upstream wiki) |
| 5 | [Total Customers] | int | YES | COUNT of RealCID values per (EOMonth, DspositorInd, RegulationName, CountryName) group. Represents the total customer population in each compliance dimension bucket. Range: 1–1,459,983 (UK FCA depositors). Grand total for March 2026: 18,003,342 customers. Column name contains a space — always bracket-quote: `[Total Customers]`. (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 6 | CFDBlockedUsers | int | YES | SUM of customers with active CFD block at EOMonth: BlockDate IS NOT NULL AND BlockDate <= @Date AND ISNULL(ReleaseDate, '2300-01-01') > @Date. Range: 0–388,364 (UK FCA depositors). Grand total March 2026: 3,682,186 (20.5% of all customers). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |
| 7 | UpdateDate | datetime | NO | GETDATE() at the time the EOM ETL run inserts data. All rows share a single timestamp per monthly load. Current value: 2026-04-01 05:15:53 (loaded on the first morning after month-end). (Tier 2 — SP_BI_DB_Scored_Appropriateness_Negative_Market) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| EOMonth | SP-computed | @Date parameter | EOMONTH(@Date) |
| DspositorInd | BI_DB_Scored_Appropriateness_Negative_Market | FTD_Date | CASE WHEN FTD_Date != '1900-01-01' THEN '1' ELSE '0' |
| RegulationName | DWH_dbo.Dim_Regulation | Name | JOIN via Dim_Customer.RegulationID / DesignatedRegulationID |
| CountryName | DWH_dbo.Dim_Country | Name | JOIN via Dim_Customer.CountryID |
| [Total Customers] | BI_DB_Scored_Appropriateness_Negative_Market | RealCID | COUNT(RealCID) per group |
| CFDBlockedUsers | BI_DB_Scored_Appropriateness_Negative_Market | BlockDate, ReleaseDate | SUM(EOM-block CASE) |
| UpdateDate | SP-computed | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
ComplianceStateDB.Compliance.CustomerRestrictions (production — CFD restriction events)
ComplianceStateDB.Compliance.UserTradingData (production — current restriction status)
ComplianceStateDB.History.UserTradingData (production — historical restrictions)
  |-- Generic Pipeline (Bronze export) ---|
  v
BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerRestrictions
BI_DB_dbo.External_ComplianceStateDB_Compliance_UserTradingData
BI_DB_dbo.External_ComplianceStateDB_History_UserTradingData
  |-- SP_BI_DB_Scored_Appropriateness_Negative_Market @Date (daily) ---|
  v
BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market (individual-level, daily TRUNCATE+INSERT)
  |-- SP_BI_DB_Scored_Appropriateness_Negative_Market (EOM gate: IF @Date=EOMONTH(@Date)) ---|
  v
BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated (~1,923 rows, monthly TRUNCATE+INSERT)
  |-- UC: Not Migrated ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RegulationName | DWH_dbo.Dim_Regulation | Regulation short code, passthrough string |
| CountryName | DWH_dbo.Dim_Country | Country full name, passthrough string |
| (aggregated from) | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | Parent individual-level appropriateness test table |

### 6.2 Referenced By

No downstream consumers found in SSDT repo. This is a compliance reporting leaf table.

---

## 7. Sample Queries

### Current Month CFD Block Rate by Regulation

```sql
SELECT
    RegulationName,
    SUM([Total Customers]) AS TotalCustomers,
    SUM(CFDBlockedUsers) AS BlockedCustomers,
    CAST(SUM(CFDBlockedUsers) * 100.0 / NULLIF(SUM([Total Customers]), 0) AS DECIMAL(5,2)) AS BlockPct
FROM [BI_DB_dbo].[BI_DB_Negative_Market_Monthly_Aggregated]
WHERE DspositorInd = 1  -- depositors only
GROUP BY RegulationName
ORDER BY TotalCustomers DESC;
```

### Depositor vs Non-Depositor Block Rate Comparison

```sql
SELECT
    DspositorInd,
    SUM([Total Customers]) AS TotalCustomers,
    SUM(CFDBlockedUsers) AS BlockedCustomers,
    CAST(SUM(CFDBlockedUsers) * 100.0 / NULLIF(SUM([Total Customers]), 0) AS DECIMAL(5,2)) AS BlockPct
FROM [BI_DB_dbo].[BI_DB_Negative_Market_Monthly_Aggregated]
GROUP BY DspositorInd
ORDER BY DspositorInd;
```

### Top 10 Countries by CFD Block Count (FCA Depositors)

```sql
SELECT TOP 10
    CountryName,
    [Total Customers],
    CFDBlockedUsers,
    CAST(CFDBlockedUsers * 100.0 / NULLIF([Total Customers], 0) AS DECIMAL(5,2)) AS BlockPct
FROM [BI_DB_dbo].[BI_DB_Negative_Market_Monthly_Aggregated]
WHERE RegulationName = 'FCA' AND DspositorInd = 1
ORDER BY CFDBlockedUsers DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Appropriateness test documentation may exist under MiFID II compliance spaces in Confluence (DATA space — not queried).

---

*Generated: 2026-04-22 | Quality: 8.6/10 | Phases: 13/14*
*Tiers: 2 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 7/7, Logic: 8/10*
*Object: BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated | Type: Table | Production Source: ComplianceStateDB.Compliance via BI_DB_Scored_Appropriateness_Negative_Market*
