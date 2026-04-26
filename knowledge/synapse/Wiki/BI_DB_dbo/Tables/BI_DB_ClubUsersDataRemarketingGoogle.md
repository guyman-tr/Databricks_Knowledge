# BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle

> 767,258-row daily snapshot of eToro Club members (Silver through Diamond) enriched with equity, lifetime deposits, recent deposit activity, and 8-year LTV predictions — designed to power Google remarketing audience segments for the Club loyalty programme.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_CID_MonthlyPanel_FullData + BI_DB_AllDeposits + BI_DB_LTV_BI_Actual via SP_ClubUsersDataRemarketingGoogle |
| **Refresh** | Daily — TRUNCATE + INSERT; @panelActiveDate = first day of month of @date |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Eti Rozolio (2022-01-26); migrated to Synapse by Chen (2024-02-28) |

---

## 1. Business Meaning

This table is a **daily marketing extract** for Google Ads remarketing. It contains one row per Club-tier customer (Silver, Gold, Platinum, Platinum Plus, Diamond — PlayerLevelID IN 2,3,5,6,7), snapshotted from the beginning of the current month via `BI_DB_CID_MonthlyPanel_FullData`. Each row carries the customer's current Club tier (from `Dim_PlayerLevel`), their end-of-month equity, lifetime deposit total, rolling deposit sums (last 6 months and last year), customer behaviour cluster, and 8-year LTV prediction.

The table is refreshed daily via TRUNCATE + INSERT. The MonthlyPanel data used is always from `ActiveDate = first day of month of @date` — meaning all rows within a calendar month reflect the same monthly snapshot (equity, cluster, lifetime deposits) until the month rolls over. The deposit windows (last 6 months, last year) and LTV are refreshed daily against current data.

As of 2026-04-12: **767,258 rows** across 5 Club tiers. Club distribution: Silver 37.2%, Gold 33.6%, Platinum 16.0%, Platinum Plus 11.8%, Diamond 1.4%. ClusterDetail distribution: Equities Crypto 24.2%, Equities Investors 20.2%, Diversified Traders 16.8%, Crypto 15.8%, Equities Traders 13.1%, Leveraged Traders 8.3%, NULL 1.6%.

---

## 2. Business Logic

### 2.1 Club Tier Population Filter

**What**: Only customers with Club membership are included — registered users and Bronze-tier customers (PlayerLevelID=1) are excluded.
**Columns Involved**: `Club`, `CID`
**Rules**:
- Population: `Dim_Customer.PlayerLevelID IN (2,3,5,6,7)` joined via `BI_DB_CID_MonthlyPanel_FullData.CID = Dim_Customer.RealCID`
- Club name sourced from `Dim_PlayerLevel.Name` for the matched PlayerLevelID
- 5 tiers: Silver (2), Gold (3), Platinum (5), Platinum Plus (6), Diamond (7)

### 2.2 Monthly Panel Snapshot Anchor

**What**: The main row attributes (Equity, TotalDeposits, ClusterDetail) are snapshot-static within the calendar month.
**Columns Involved**: `Equity`, `TotalDeposits`, `ClusterDetail`
**Rules**:
- `@panelActiveDate = CAST(CONCAT(YEAR(@date),'-',MONTH(@date),'-01') AS DATE)` — first day of month
- All three columns pulled from `BI_DB_CID_MonthlyPanel_FullData WHERE ActiveDate = @panelActiveDate`
- Mid-month runs reflect the same monthly snapshot; values only change when the month rolls over

### 2.3 Rolling Deposit Windows

**What**: DepositsLast6Months and DepositsLastYear are recalculated daily from BI_DB_AllDeposits.
**Columns Involved**: `DepositsLast6Months`, `DepositsLastYear`
**Rules**:
- Source: `BI_DB_AllDeposits` filtered to `PaymentStatus = 'Approved'` only
- DepositsLast6Months: `SUM([Amount in $]) WHERE [Deposit Time] >= DATEADD(MONTH,-6,@date)`
- DepositsLastYear: `SUM([Amount in $]) WHERE [Deposit Time] >= DATEADD(YEAR,-1,@date)`
- Both are LEFT JOINed — NULL when the customer made no approved deposits in the window

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN / HEAP — no distribution key. This is a marketing export table; no heavy analytics should be performed on it directly. All lookups by CID will fan out across all distributions.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All Diamond customers with LTV > $5,000 | `SELECT * WHERE Club = 'Diamond' AND LTV > 5000` |
| Average LTV by Club tier | `SELECT Club, AVG(LTV) FROM ... GROUP BY Club` |
| High-equity customers with no recent deposits | `SELECT * WHERE Equity > 10000 AND DepositsLast6Months IS NULL` |
| Audience for a specific cluster | `SELECT CID WHERE ClusterDetail = 'Equities Investors'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | `CID = Dim_Customer.RealCID` | Enrich with regulation, country, KYC level |
| BI_DB_dbo.BI_DB_LTV_BI_Actual | `CID = BI_DB_LTV_BI_Actual.CID` | Get full LTV variant suite (LTV here is Revenue8Y_LTV_New only) |

### 3.4 Gotchas

- **Monthly snapshot freeze**: Equity, TotalDeposits, and ClusterDetail do NOT change daily — they are frozen to the BOMonth value until the month rolls over. Do NOT use this table for real-time equity tracking.
- **NULL deposits mean zero activity in window**: NULL in DepositsLast6Months / DepositsLastYear means no approved deposits in that period (not data quality issues).
- **UpdateDate precision**: GETDATE() at ETL run time — all rows in the same batch share the same UpdateDate.
- **Bronze customers absent**: No rows for PlayerLevelID=1 (Bronze). If the audience requires all depositors, use BI_DB_CID_MonthlyPanel_FullData directly.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (no transformation) |
| Tier 2 | Derived from ETL SP code, DWH wiki, or staging DDL |
| Tier 3 | Inferred from column name, data pattern, or business context |
| Tier 4 | Best available — no source traceable |
| Propagation | ETL infrastructure column (GETDATE(), row metadata) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | Club | varchar(50) | YES | Club loyalty tier name from Dim_PlayerLevel. Population restricted to members only. Values: Silver=2, Gold=3, Platinum=5, Platinum Plus=6, Diamond=7. (Tier 2 — SP_ClubUsersDataRemarketingGoogle via Dim_PlayerLevel) |
| 3 | Equity | money | YES | Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance. Sourced from BI_DB_CID_MonthlyPanel_FullData.EOM_Equity; frozen to BOMonth snapshot until month rolls over. (Tier 2 — DWH_dbo.V_Liabilities) |
| 4 | TotalDeposits | money | YES | Lifetime accumulated total deposits (USD). Sourced from BI_DB_CID_MonthlyPanel_FullData.ACC_TotalDeposits; frozen to BOMonth snapshot within the calendar month. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 5 | ClusterDetail | varchar(50) | YES | Customer behaviour cluster name from BI_DB_CID_DailyCluster (e.g., 'Equities Crypto'). NULL for unclustered customers. Frozen to BOMonth snapshot within the calendar month. (Tier 2 — BI_DB_CID_DailyCluster) |
| 6 | DepositsLast6Months | money | YES | Sum of approved deposits in the 6 months prior to the ETL run date (@date). NULL when no approved deposits in window. Refreshed daily. (Tier 2 — SP_ClubUsersDataRemarketingGoogle via BI_DB_AllDeposits) |
| 7 | DepositsLastYear | money | YES | Sum of approved deposits in the 12 months prior to the ETL run date (@date). NULL when no approved deposits in window. Refreshed daily. (Tier 2 — SP_ClubUsersDataRemarketingGoogle via BI_DB_AllDeposits) |
| 8 | LTV | money | YES | 8-year cumulative broker revenue prediction (new 2023+ methodology), individual prediction only. Sourced from BI_DB_LTV_BI_Actual.Revenue8Y_LTV_New. May be low for inactive customers — use Revenue8Y_LTV_New_Group_LTV from LTV_BI_Actual for group-level fallback. (Tier 2 — BI_DB_LTV_BI_Actual wiki) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | BI_DB_CID_MonthlyPanel_FullData → Customer.CustomerStatic | CID / RealCID | Passthrough |
| Club | Dim_PlayerLevel | Name | JOIN on PlayerLevelID IN (2,3,5,6,7) |
| Equity | BI_DB_CID_MonthlyPanel_FullData | EOM_Equity | Rename; BOMonth anchor |
| TotalDeposits | BI_DB_CID_MonthlyPanel_FullData | ACC_TotalDeposits | Rename; BOMonth anchor |
| ClusterDetail | BI_DB_CID_MonthlyPanel_FullData | ClusterDetail | Passthrough; BOMonth anchor |
| DepositsLast6Months | BI_DB_AllDeposits | [Amount in $] | SUM approved, 6-month rolling |
| DepositsLastYear | BI_DB_AllDeposits | [Amount in $] | SUM approved, 12-month rolling |
| LTV | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | Passthrough |
| UpdateDate | ETL | GETDATE() | Runtime timestamp |

### 5.2 ETL Pipeline

```
BI_DB_CID_MonthlyPanel_FullData (ActiveDate = BOMonth)
  + Dim_Customer (PlayerLevelID IN 2,3,5,6,7 filter)
  + Dim_PlayerLevel (Club name)
    |
    v
#MainTable (CID, Club, Equity, TotalDeposits, ClusterDetail)

BI_DB_AllDeposits (PaymentStatus='Approved', rolling windows)
    → #DepositsLastYear / #DepositsLast6Months

BI_DB_LTV_BI_Actual
    → #LTV (Revenue8Y_LTV_New)

    |-- SP_ClubUsersDataRemarketingGoogle (@date) TRUNCATE+INSERT ---|
    v
BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle (767K rows)
    |-- UC: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | BI_DB_CID_MonthlyPanel_FullData | Primary data source for monthly snapshot |
| Club | DWH_dbo.Dim_PlayerLevel | Club tier name lookup |
| Equity / TotalDeposits / ClusterDetail | BI_DB_CID_MonthlyPanel_FullData | Monthly snapshot attributes |
| DepositsLast6Months / DepositsLastYear | BI_DB_AllDeposits | Rolling deposit windows |
| LTV | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New value |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified (marketing export table, consumed externally by Google Ads).

---

## 7. Sample Queries

### Diamond customers with high LTV for targeted campaign

```sql
SELECT CID, Equity, LTV, TotalDeposits
FROM [BI_DB_dbo].[BI_DB_ClubUsersDataRemarketingGoogle]
WHERE Club = 'Diamond'
  AND LTV > 10000
ORDER BY LTV DESC;
```

### Club distribution with average LTV and equity

```sql
SELECT Club,
       COUNT(*) AS members,
       AVG(Equity) AS avg_equity,
       AVG(LTV) AS avg_ltv,
       SUM(CASE WHEN DepositsLast6Months > 0 THEN 1 ELSE 0 END) AS active_depositors_6m
FROM [BI_DB_dbo].[BI_DB_ClubUsersDataRemarketingGoogle]
GROUP BY Club
ORDER BY avg_ltv DESC;
```

### Customers with recent deposit activity but low LTV (re-engagement candidates)

```sql
SELECT CID, Club, ClusterDetail, DepositsLast6Months, LTV
FROM [BI_DB_dbo].[BI_DB_ClubUsersDataRemarketingGoogle]
WHERE DepositsLast6Months > 500
  AND LTV < 100
  AND Club IN ('Silver', 'Gold')
ORDER BY DepositsLast6Months DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this object. SP comment: "club users data for remarketing campaigns in google" (Eti Rozolio, 2022-01-26).

---

*Generated: 2026-04-23 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 1 T1, 7 T2, 0 T3, 0 T4, 1 Propagation | Elements: 9/9, Logic: 8/10*
*Object: BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle | Type: Table | Production Source: SP_ClubUsersDataRemarketingGoogle*
