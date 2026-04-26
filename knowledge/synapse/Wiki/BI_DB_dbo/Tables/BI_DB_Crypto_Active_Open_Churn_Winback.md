# BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback

> 213.5M-row monthly crypto activity panel tracking every verified depositor's crypto trading engagement (manual, copy, real, CFD), active-open status, churn, and win-back transitions from June 2022 to present (47 months, 5.4M distinct CIDs). Refreshed daily by SP_Crypto_Active_Open_Churn_Winback via DELETE+INSERT for the current month, with LAG-based churn/win-back UPDATE across all months.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (population) + DWH_dbo.Fact_CustomerAction (crypto activity) via SP_Crypto_Active_Open_Churn_Winback |
| **Refresh** | Daily (SB_Daily, Priority 0). DELETE current month → INSERT current month → UPDATE Churn/Win_Back across all months |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (Active_Month ASC, RealCID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Adva Jakobson (2024-09-24) |

---

## 1. Business Meaning

`BI_DB_Crypto_Active_Open_Churn_Winback` is a monthly crypto engagement panel for the eToro Crypto Dashboard. Each row represents one customer (RealCID) in one month (Active_Month), with binary flags indicating whether the customer had crypto trading activity in that month, and whether they churned (stopped being active) or won back (returned to activity) relative to the prior month.

The population is fully-verified (VerificationLevelID=3), valid, depositing customers (IsDepositor=1, IsValidCustomer=1) excluding internal accounts (PlayerLevelID<>4), sourced from `Fact_SnapshotCustomer` as of the execution date. Crypto activity is defined as any action in `Fact_CustomerAction` during the current month where InstrumentTypeID=10 (Real Crypto instruments) and CategoryID=18 (crypto-relevant action category), excluding AirDrop actions (IsAirDrop=0).

The SP runs daily but only modifies the current month: it deletes and re-inserts current-month rows, then recomputes Churn and Win_Back for ALL months using a LAG window function over Active_Open. This means historical months' Churn/Win_Back values are recalculated on every run.

---

## 2. Business Logic

### 2.1 Crypto Activity Type Classification

**What**: Each customer's crypto activity is classified into four non-exclusive binary flags based on trade attributes in Fact_CustomerAction.
**Columns Involved**: `Active_Crypto_Manual`, `Active_Crypto_Copy`, `Active_Crypto_Real`, `Active_Crypto_CFD`
**Rules**:
- `Active_Crypto_Manual=1`: Customer had at least one crypto action with MirrorID=0 (direct/manual trade, not via CopyTrader)
- `Active_Crypto_Copy=1`: Customer had at least one crypto action with MirrorID<>0 (trade executed through a copy relationship)
- `Active_Crypto_Real=1`: Customer had at least one crypto action with IsSettled=1 (real/settled crypto — actual asset ownership)
- `Active_Crypto_CFD=1`: Customer had at least one crypto action with IsSettled=0 (CFD crypto — contract for difference, no asset ownership)
- A customer can have multiple flags set simultaneously (e.g., both Manual and Copy, both Real and CFD)

### 2.2 Active Open Definition

**What**: A customer is considered "Active Open" in crypto when they have BOTH a trade-type AND a settlement-type activity in the same month.
**Columns Involved**: `Active_Open`, `Active_Crypto_Manual`, `Active_Crypto_Copy`, `Active_Crypto_Real`, `Active_Crypto_CFD`
**Rules**:
- `Active_Open=1` requires: (Active_Crypto_Manual=1 OR Active_Crypto_Copy=1) AND (Active_Crypto_Real=1 OR Active_Crypto_CFD=1)
- This is a conjunction — having only manual trades without any real/CFD settlement does NOT qualify as Active Open
- In March 2026, approximately 155K out of 5.39M rows had Active_Open=1

### 2.3 Churn and Win-Back Transition Detection

**What**: Month-over-month transitions in Active_Open status are tracked using LAG window functions over the customer's monthly history.
**Columns Involved**: `Churn`, `Win_Back`, `Active_Open`
**Rules**:
- `Churn=1`: Active_Open decreased from previous month (was 1, now 0) — customer stopped crypto activity
- `Win_Back=1`: Active_Open increased from previous month (was 0, now 1) — customer returned to crypto activity
- Both use `LAG(Active_Open) OVER(PARTITION BY RealCID ORDER BY RealCID, Active_Month ASC)`
- First month for a customer always has Churn=0 and Win_Back=0 (no prior month to compare)
- Churn and Win_Back are recalculated across ALL months on every daily run (full UPDATE after INSERT)

### 2.4 Population Filters

**What**: Only qualified customers appear in this panel.
**Columns Involved**: Population derived from Fact_SnapshotCustomer
**Rules**:
- IsDepositor=1 (has deposited)
- IsValidCustomer=1 (valid account)
- VerificationLevelID=3 (fully verified)
- PlayerLevelID<>4 (excludes Internal accounts)
- Snapshot date range: DateRangeID resolved via Dim_Range to include only current-date ranges

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) distribution with CLUSTERED INDEX on (Active_Month ASC, RealCID ASC). Queries filtering by Active_Month are index-aligned. Queries JOINing on RealCID are co-located with other HASH(RealCID) tables (Dim_Customer, Fact_CustomerAction).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly active crypto users over time | `SELECT Active_Month, SUM(Active_Open) FROM ... GROUP BY Active_Month ORDER BY Active_Month` |
| Churn rate by month | `SELECT Active_Month, SUM(Churn)*1.0/COUNT(*) FROM ... GROUP BY Active_Month` |
| Win-back rate by region | `SELECT Region, Active_Month, SUM(Win_Back) FROM ... WHERE Active_Open=1 GROUP BY Region, Active_Month` |
| Manual vs copy crypto breakdown | `SELECT Active_Month, SUM(Active_Crypto_Manual), SUM(Active_Crypto_Copy) FROM ... WHERE Active_Open=1 GROUP BY Active_Month` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Full customer profile enrichment |
| BI_DB_dbo.BI_DB_CryptoDashboardNew | — (different grain) | Cross-reference crypto dashboard metrics |

### 3.4 Gotchas

- **Active_Open is conjunctive**: A customer with only manual trades but no real/CFD settlement has Active_Open=0. Both dimensions (trade-type AND settlement-type) must be present.
- **Churn/Win_Back recomputed globally**: The UPDATE in Step 8 recalculates Churn/Win_Back for ALL months, not just the current month. Historical values may change retroactively if rows are inserted or deleted.
- **Monthly grain with daily refresh**: The table has monthly granularity (Active_Month = first of month), but the SP runs daily. Within a month, running the SP on different days may produce different results as more trades are accumulated.
- **Club is point-in-time from Fact_SnapshotCustomer**: Club value reflects the customer's tier at the snapshot date, not their current tier.
- **No internal accounts**: PlayerLevelID=4 (Internal) is excluded from the population.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest — verified against source code and live data |
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 3 | Live data observation | Medium — inferred from data patterns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Distribution key. (Tier 1 — Customer.CustomerStatic) |
| 2 | Active_Month | date | NO | First day of the calendar month this row represents. ETL-computed: DATEFROMPARTS(YEAR(@date), MONTH(@date), 1). Range: 2022-06-01 to 2026-04-01 (47 months). Part of clustered index. (Tier 2 — SP_Crypto_Active_Open_Churn_Winback) |
| 3 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID JOIN. (Tier 1 — Dictionary.Country) |
| 4 | Region | varchar(50) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from automated MarketingRegion label (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Passthrough from Dim_Country.MarketingRegionManualName. (Tier 3 — Ext_Dim_Country) |
| 5 | Club | varchar(50) | YES | eToro Club tier name from Dim_PlayerLevel at the snapshot date. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Passthrough from Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID JOIN. (Tier 2 — SP_Crypto_Active_Open_Churn_Winback via Dim_PlayerLevel) |
| 6 | Active_Crypto_Manual | tinyint | YES | Binary flag (0/1). 1 = customer had at least one direct (non-copy) crypto trade this month. Determined by MirrorID=0 in Fact_CustomerAction where InstrumentTypeID=10 and CategoryID=18, excluding AirDrops. (Tier 2 — SP_Crypto_Active_Open_Churn_Winback) |
| 7 | Active_Crypto_Copy | tinyint | YES | Binary flag (0/1). 1 = customer had at least one copy-trade crypto action this month. Determined by MirrorID<>0 in Fact_CustomerAction where InstrumentTypeID=10 and CategoryID=18, excluding AirDrops. (Tier 2 — SP_Crypto_Active_Open_Churn_Winback) |
| 8 | Active_Crypto_CFD | tinyint | YES | Binary flag (0/1). 1 = customer had at least one CFD (contract for difference) crypto trade this month. Determined by IsSettled=0 in Fact_CustomerAction where InstrumentTypeID=10 and CategoryID=18, excluding AirDrops. (Tier 2 — SP_Crypto_Active_Open_Churn_Winback) |
| 9 | Active_Crypto_Real | tinyint | YES | Binary flag (0/1). 1 = customer had at least one real (settled) crypto trade this month. Determined by IsSettled=1 in Fact_CustomerAction where InstrumentTypeID=10 and CategoryID=18, excluding AirDrops. (Tier 2 — SP_Crypto_Active_Open_Churn_Winback) |
| 10 | Active_Open | tinyint | YES | Binary flag (0/1). 1 = customer has BOTH a trade-type (Manual or Copy) AND a settlement-type (Real or CFD) crypto activity this month. Conjunctive condition: (Active_Crypto_Manual=1 OR Active_Crypto_Copy=1) AND (Active_Crypto_Real=1 OR Active_Crypto_CFD=1). (Tier 2 — SP_Crypto_Active_Open_Churn_Winback) |
| 11 | Churn | tinyint | YES | Binary flag (0/1). 1 = customer's Active_Open decreased from the prior month (was active, now inactive). Computed via LAG(Active_Open) OVER(PARTITION BY RealCID ORDER BY Active_Month). 0 for a customer's first month. Recalculated across all months on every SP run. (Tier 2 — SP_Crypto_Active_Open_Churn_Winback) |
| 12 | Win_Back | tinyint | YES | Binary flag (0/1). 1 = customer's Active_Open increased from the prior month (was inactive, now active). Computed via LAG(Active_Open) OVER(PARTITION BY RealCID ORDER BY Active_Month). 0 for a customer's first month. Recalculated across all months on every SP run. (Tier 2 — SP_Crypto_Active_Open_Churn_Winback) |
| 13 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() on INSERT; also updated during the Churn/Win_Back UPDATE pass. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (DISTINCT from population) |
| Active_Month | — | — | ETL-computed: DATEFROMPARTS(YEAR(@date), MONTH(@date), 1) |
| Country | DWH_dbo.Dim_Country | Name | Passthrough via CountryID JOIN |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Passthrough via CountryID JOIN |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough via PlayerLevelID JOIN |
| Active_Crypto_Manual | DWH_dbo.Fact_CustomerAction | MirrorID | MAX(CASE WHEN ISNULL(MirrorID,0)=0 THEN 1 ELSE 0 END) |
| Active_Crypto_Copy | DWH_dbo.Fact_CustomerAction | MirrorID | MAX(CASE WHEN ISNULL(MirrorID,0)<>0 THEN 1 ELSE 0 END) |
| Active_Crypto_CFD | DWH_dbo.Fact_CustomerAction | IsSettled | MAX(CASE WHEN ISNULL(IsSettled,0)=0 THEN 1 ELSE 0 END) |
| Active_Crypto_Real | DWH_dbo.Fact_CustomerAction | IsSettled | MAX(CASE WHEN ISNULL(IsSettled,0)=1 THEN 1 ELSE 0 END) |
| Active_Open | — | — | CASE: (Manual OR Copy) AND (Real OR CFD) |
| Churn | self | Active_Open | LAG(Active_Open) decrease |
| Win_Back | self | Active_Open | LAG(Active_Open) increase |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (population)
  + DWH_dbo.Dim_Customer (PlayerLevelID<>4 filter)
  + DWH_dbo.Dim_Range (date range resolution)
  + DWH_dbo.Dim_PlayerLevel (Club name)
  + DWH_dbo.Dim_Country (Country + Region)
  |-- Step 2: #pop (DISTINCT RealCID + demographics) ---|
  v
DWH_dbo.Fact_CustomerAction
  + DWH_dbo.Dim_Instrument (InstrumentTypeID=10)
  + DWH_dbo.Dim_ActionType (CategoryID=18)
  |-- Step 3: #step3 (crypto activity flags per RealCID) ---|
  v
  |-- Step 4-5: #step4/#step5 (merge + Active_Open logic) ---|
  v
BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback
  |-- Step 6: DELETE+INSERT current month ---|
  |-- Step 7-8: LAG window → UPDATE Churn/Win_Back ---|
  v
BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback (final)

UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension — universal customer identifier |
| Country | DWH_dbo.Dim_Country | Country dimension — resolved from Dim_Country.Name |
| Club | DWH_dbo.Dim_PlayerLevel | Player level dimension — club tier name |

### 6.2 Referenced By (other objects point to this)

No known consumers identified in this batch.

---

## 7. Sample Queries

### 7.1 Monthly Active Crypto Users Trend

```sql
SELECT Active_Month,
       SUM(Active_Open) AS active_open_users,
       SUM(Churn) AS churned_users,
       SUM(Win_Back) AS winback_users
FROM BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback
GROUP BY Active_Month
ORDER BY Active_Month
```

### 7.2 Churn Rate by Region for Recent Months

```sql
SELECT Region,
       Active_Month,
       SUM(Churn) AS churned,
       COUNT(*) AS total_customers,
       CAST(SUM(Churn) AS FLOAT) / COUNT(*) * 100 AS churn_rate_pct
FROM BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback
WHERE Active_Month >= '2026-01-01'
GROUP BY Region, Active_Month
ORDER BY Region, Active_Month
```

### 7.3 Manual vs Copy Crypto Activity Breakdown

```sql
SELECT Active_Month,
       SUM(Active_Crypto_Manual) AS manual_traders,
       SUM(Active_Crypto_Copy) AS copy_traders,
       SUM(Active_Crypto_Real) AS real_crypto,
       SUM(Active_Crypto_CFD) AS cfd_crypto,
       SUM(Active_Open) AS active_open
FROM BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback
WHERE Active_Month >= '2025-01-01'
GROUP BY Active_Month
ORDER BY Active_Month
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 2 T1, 8 T2, 1 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 9/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_Crypto_Active_Open_Churn_Winback | Type: Table | Production Source: DWH_dbo dimensions+facts via SP_Crypto_Active_Open_Churn_Winback*
