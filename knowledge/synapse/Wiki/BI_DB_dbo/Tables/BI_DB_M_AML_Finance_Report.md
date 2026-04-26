# BI_DB_dbo.BI_DB_M_AML_Finance_Report

> 102.2M-row monthly AML finance report capturing end-of-month equity snapshots and last login dates for all verified, funded, Normal/Warning customers across non-US/BVI regulations, from January 2023 to March 2026. Used to assess dormant account risk by combining equity balance (from V_Liabilities) with login recency (from Fact_CustomerAction). Refreshed monthly via `SP_M_AML_Finance_Report` with delete-insert by EOM.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed from DWH_dbo dimensions/facts + V_Liabilities + Fact_CustomerAction + DDR_CID_Level via `SP_M_AML_Finance_Report` |
| **Refresh** | Monthly (delete-insert by EOM). Parameter @Date capped to EOMONTH(GETDATE(),-1). OpsDB: SB_Daily, Priority 0 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table provides a monthly equity and login snapshot for AML (Anti-Money Laundering) finance reporting. Each row represents a customer's state at the end of a given month: their regulation, country, player status (Normal or Warning), club level, account equity, and last login date.

The population is restricted to:
- **Verified** customers (VerificationLevelID=3)
- **Funded** depositors (IsDepositor=1, plus DDR_CID_Level Funded_New_Def=1)
- **Valid** customers (IsValidCustomer=1)
- **Active statuses only**: Normal (PlayerStatusID=1) or Warning (PlayerStatusID=5)
- **Excludes**: NFA (3), BVI (5), eToroUS (6) regulations

The table contains ~102.2M rows spanning January 2023 to March 2026 (~39 months). At the latest month (March 2026), there are ~3.5M rows (99.9% Normal, 0.1% Warning). Regulations: CySEC 56%, FCA 26%, FinCEN+FINRA 6%.

Equity is computed as `ISNULL(Liabilities,0) + ISNULL(ActualNWA,0)` from `V_Liabilities`. Last_Login is the MAX DateID from `Fact_CustomerAction` where ActionTypeID=14 (LoggedIn), stored as integer YYYYMMDD.

---

## 2. Business Logic

### 2.1 Equity Calculation

**What**: Computes total account equity at end-of-month.
**Columns Involved**: Equity
**Rules**:
- Formula: `ISNULL(Liabilities, 0) + ISNULL(ActualNWA, 0)`
- Source: `DWH_dbo.V_Liabilities` LEFT JOIN on CID + DateID
- NULL Liabilities or ActualNWA treated as 0
- Equity can be negative (margin positions)

### 2.2 Population Filtering

**What**: Restricts to funded, verified, active customers in applicable regulations.
**Columns Involved**: CID, Regulation, PlayerStatus
**Rules**:
- Fact_SnapshotCustomer filters: IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3
- PlayerStatus filter: IN (1=Normal, 5=Warning) — excludes Blocked, Suspended, etc.
- Regulation filter: NOT IN (3=NFA, 5=BVI, 6=eToroUS) — excludes US and BVI jurisdictions
- Additional funding filter: JOIN to BI_DB_DDR_CID_Level with Funded_New_Def=1

### 2.3 Last Login Detection

**What**: Finds the most recent login date for each customer.
**Columns Involved**: Last_Login
**Rules**:
- Source: MAX(Fact_CustomerAction.DateID) WHERE ActionTypeID=14 (LoggedIn)
- INNER JOIN — customers without any login record are excluded from the output
- Stored as integer YYYYMMDD (e.g., 20241120)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index. The table is large (102M rows). For analytical queries, always filter by EOM first to reduce scan scope.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Total equity by regulation for a given month? | `SELECT Regulation, SUM(Equity) FROM ... WHERE EOM = '2026-03-31' GROUP BY Regulation` |
| Dormant accounts (no login in 6+ months)? | `SELECT * FROM ... WHERE EOM = '2026-03-31' AND Last_Login < 20250901` |
| Customer count by regulation and status? | `SELECT Regulation, PlayerStatus, COUNT(*) FROM ... WHERE EOM = '2026-03-31' GROUP BY Regulation, PlayerStatus` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | CID = RealCID | Enrich with customer demographics |
| BI_DB_dbo.BI_DB_M_AML_Account_Closed | CID = CID | Cross-reference with AML closures |
| DWH_dbo.Dim_Date | Last_Login = DateKey | Convert Last_Login int to readable date |

### 3.4 Gotchas

- **Large table**: 102M rows — ALWAYS filter by EOM. Unfiltered scans will be slow
- **Last_Login is int**: Stored as YYYYMMDD integer (e.g., 20241120), not a date type. Use `WHERE Last_Login < CAST(CONVERT(CHAR(8), DATEADD(MONTH,-6,GETDATE()), 112) AS INT)` for date arithmetic
- **INNER JOIN on Fact_CustomerAction**: Customers who have NEVER logged in are excluded from this table entirely (the login query uses INNER JOIN via GROUP BY)
- **Equity includes NWA**: The equity formula adds ActualNWA (Net Withdrawable Amount), which may include pending withdrawal amounts
- **Regulation exclusions**: NFA, BVI, and eToroUS customers are excluded — this table is NOT a complete customer population. Use BI_DB_Client_Balance tables for full coverage

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB docs) | Highest — verified against source system documentation |
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 3 | Live data observation | Medium — inferred from data patterns |
| Tier 4 | Contextual inference | Lower — best available knowledge |
| Tier 5 | Standard ETL column | Canonical — well-known ETL metadata pattern |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Sourced from Fact_SnapshotCustomer.RealCID. Identifies the verified, funded, Normal/Warning customer in the AML finance snapshot. (Tier 2 — SP_M_AML_Finance_Report) |
| 2 | Regulation | varchar(250) | YES | Regulation name resolved from Dim_Regulation.Name via JOIN on DWHRegulationID. Excludes NFA (3), BVI (5), eToroUS (6). Values: CySEC, FCA, FinCEN+FINRA, ASIC & GAML, FSA Seychelles, FSRA, FinCEN, ASIC, MAS, NYDFS+FINRA, None. (Tier 2 — SP_M_AML_Finance_Report) |
| 3 | Country | varchar(250) | YES | Country name resolved from Dim_Country.Name via JOIN on DWHCountryID. Country of the customer at the end-of-month snapshot. (Tier 2 — SP_M_AML_Finance_Report) |
| 4 | PlayerStatus | varchar(250) | YES | Player status at end-of-month. Always one of: Normal (PlayerStatusID=1, 99.9%) or Warning (PlayerStatusID=5, 0.1%). Resolved from Dim_PlayerStatus.Name. (Tier 2 — SP_M_AML_Finance_Report) |
| 5 | Club | varchar(250) | YES | Player level (club tier) resolved from Dim_PlayerLevel.Name via JOIN on PlayerLevelID. Values include Bronze, Silver, Gold, Platinum, etc. (Tier 2 — SP_M_AML_Finance_Report) |
| 6 | Equity | money | YES | Total account equity at end-of-month. Computed as ISNULL(V_Liabilities.Liabilities,0) + ISNULL(V_Liabilities.ActualNWA,0). LEFT JOIN — NULL if no V_Liabilities record exists for the CID at that DateID. Can be negative for margin accounts. (Tier 2 — SP_M_AML_Finance_Report) |
| 7 | EOM | date | YES | End-of-month date for the reporting period. Computed from SP parameter @Date, capped to EOMONTH(GETDATE(),-1). Each row represents the customer's state at this month-end. (Tier 2 — SP_M_AML_Finance_Report) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — SP_M_AML_Finance_Report) |
| 9 | Last_Login | int | YES | Most recent login date as integer YYYYMMDD. Computed as MAX(Fact_CustomerAction.DateID) WHERE ActionTypeID=14 (LoggedIn). INNER JOIN means customers with no login history are excluded. (Tier 2 — SP_M_AML_Finance_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Alias rename |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID, excludes 3,5,6 |
| Country | DWH_dbo.Dim_Country | Name | JOIN on DWHCountryID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN, filtered to 1,5 |
| Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN on PlayerLevelID |
| Equity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL sum, LEFT JOIN |
| EOM | (computed) | @EndOfMonth | SP parameter |
| UpdateDate | (computed) | GETDATE() | ETL timestamp |
| Last_Login | DWH_dbo.Fact_CustomerAction | DateID | MAX, filtered ActionTypeID=14 |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_PlayerStatus + Dim_Regulation
+ Dim_Country + Dim_PlayerLevel + Dim_Customer + BI_DB_DDR_CID_Level
  |-- #pop (verified, funded, Normal/Warning, non-US/BVI, DDR Funded_New_Def=1)
  v
DWH_dbo.V_Liabilities (LEFT JOIN on CID + DateID → Equity)
  v
DWH_dbo.Fact_CustomerAction (INNER JOIN, ActionTypeID=14, MAX DateID → Last_Login)
  |-- #login (population × last login)
  v
BI_DB_dbo.BI_DB_M_AML_Finance_Report (DELETE by EOM + INSERT, ~3.5M rows/month)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID | DWH_dbo.Fact_SnapshotCustomer | Customer snapshot — primary source of population |
| CID | DWH_dbo.Dim_Customer | Customer dimension — JOIN target for demographics |
| Equity | DWH_dbo.V_Liabilities | Liabilities view — source of equity calculation |
| Last_Login | DWH_dbo.Fact_CustomerAction | Customer action fact — source of login dates |
| CID | BI_DB_dbo.BI_DB_DDR_CID_Level | DDR CID-level metrics — funding filter |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the BI_DB_dbo schema.

---

## 7. Sample Queries

### 7.1 Dormant High-Equity Accounts (AML Risk)

```sql
SELECT CID, Regulation, Country, Equity, Last_Login,
       DATEDIFF(DAY, CAST(CAST(Last_Login AS VARCHAR(8)) AS DATE), EOM) AS days_since_login
FROM BI_DB_dbo.BI_DB_M_AML_Finance_Report
WHERE EOM = '2026-03-31'
  AND Equity > 10000
  AND Last_Login < 20250401
ORDER BY Equity DESC
```

### 7.2 Monthly Equity by Regulation

```sql
SELECT EOM, Regulation,
       COUNT(*) AS customers,
       SUM(Equity) AS total_equity,
       AVG(Equity) AS avg_equity
FROM BI_DB_dbo.BI_DB_M_AML_Finance_Report
WHERE EOM >= '2025-01-31'
GROUP BY EOM, Regulation
ORDER BY EOM DESC, total_equity DESC
```

### 7.3 Warning Status Customer Profile

```sql
SELECT Regulation, Country, Club,
       COUNT(*) AS warning_customers,
       AVG(Equity) AS avg_equity
FROM BI_DB_dbo.BI_DB_M_AML_Finance_Report
WHERE EOM = '2026-03-31'
  AND PlayerStatus = 'Warning'
GROUP BY Regulation, Country, Club
ORDER BY warning_customers DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_M_AML_Finance_Report | Type: Table | Production Source: SP_M_AML_Finance_Report*
