# BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level

> Aggregated watchlist conversion metrics at Country x Funnel x Version level — measures how effectively the watchlist feature drives first-action trades, first-5-action trades, and position opens (IN watchlist vs OUTSIDE watchlist). Also includes registration/FTD counts, 30-day revenue/deposits, and 8-year LTV per cohort. Daily TRUNCATE+INSERT via SP_Watchlist_Tracking (aggregated FROM BI_DB_Watchlist_Tracking_Item_Level). Paired cluster with BI_DB_Watchlist_Tracking_Item_Level.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_Watchlist_Tracking_Item_Level (aggregated) + CIDFirstDates + LTV_BI_Actual via `SP_Watchlist_Tracking` |
| **Refresh** | Daily (TRUNCATE+INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Priority** | 0 |
| **Schedule** | SB_Daily |
| **Paired With** | BI_DB_Watchlist_Tracking_Item_Level (detail source for aggregation) |
| **Row Count** | _(placeholder — run SELECT COUNT(*) to populate)_ |

---

## 1. Business Meaning

`BI_DB_Watchlist_Tracking_High_Level` provides aggregated watchlist effectiveness metrics at the Country x Funnel x Watchlist Version grain. Each row answers: "For users who registered during this watchlist version, in this country, attributed to this funnel — how many traded watchlist items vs non-watchlist items as their first action, first 5 actions, or total positions?"

The table splits each metric into a total count and a "from watchlist" count, enabling direct conversion rate calculations:
- **First-action watchlist rate**: `FirstActions_from_WL / FirstActions`
- **First-5-actions watchlist rate**: `First5Actions_from_WL / First5Actions_Trades`
- **Position-open watchlist rate**: `PositionsOpened_or_CopyOpened_from_WL / PositionsOpened_or_CopyOpened`

Beyond trade attribution, the table enriches each cohort with registration/FTD counts, 30-day revenue and deposit totals (with counts for averaging), and 8-year LTV metrics (with and without extreme outliers). This enables cohort quality analysis alongside watchlist effectiveness.

This table is the second output of SP_Watchlist_Tracking. The trade-level metrics (FirstActions, First5Actions, PositionsOpened) are aggregated directly from `BI_DB_Watchlist_Tracking_Item_Level`. The cohort-level metrics (Reg, FTD, Revenue, Deposits, LTV) come from additional joins to CIDFirstDates, Dim_Customer, and BI_DB_LTV_BI_Actual.

---

## 2. Business Logic

### 2.1 Watchlist Conversion Metrics (Aggregated from Item Level)

**What**: Trade-level metrics are SUMs from the Item Level table, split by Is_In_WL.
**Columns Involved**: `FirstActions`, `FirstActions_from_WL`, `First5Actions_Trades`, `First5Actions_from_WL`, `PositionsOpened_or_CopyOpened`, `PositionsOpened_or_CopyOpened_from_WL`
**Rules**:
- Total columns = SUM across ALL items (Is_In_WL = 0 and 1)
- `_from_WL` columns = SUM WHERE Is_In_WL = 1 only
- Grouped by VersionID + CountryID + AttributedID

### 2.2 Registration and FTD Counts

**What**: Cohort size metrics independent of watchlist membership.
**Columns Involved**: `Reg`, `FTD`
**Rules**:
- Reg = COUNT of users who registered during the version date range, per country and funnel
- FTD = COUNT of first-time depositors in the same cohort
- Source: BI_DB_CIDFirstDates + Dim_Customer

### 2.3 30-Day Revenue and Deposit Metrics

**What**: Early monetization signals for the cohort.
**Columns Involved**: `Sum_Revenue30days`, `Count_Revenue30days`, `Sum_Deposit30days`, `Count_Deposit30days`
**Rules**:
- Sum = total revenue/deposits within 30 days of registration for the cohort
- Count = number of customers with non-NULL 30-day revenue/deposits (for average calculation)
- Average revenue per depositor = Sum_Revenue30days / Count_Revenue30days

### 2.4 8-Year LTV Metrics

**What**: Long-term value projections for the cohort.
**Columns Involved**: `Sum_8Y_LTV`, `Count_8Y_LTV`, `Sum_8Y_LTV_NoExtreme`, `Count_8Y_LTV_NoExtreme`
**Rules**:
- Source: BI_DB_LTV_BI_Actual
- Sum_8Y_LTV = total 8-year LTV for all cohort customers with LTV data
- NoExtreme variant excludes extreme outliers (likely based on percentile cutoff in LTV_BI_Actual)
- Count columns enable average LTV calculation: Sum_8Y_LTV / Count_8Y_LTV

### 2.5 Country/Region/Desk Enrichment

**What**: Geographic enrichment inherited from Item Level / Dim_Country.
**Columns Involved**: `CountryID`, `Country`, `Region`, `Desk`, `EU`
**Rules**:
- Country, Region passthrough from Dim_Country
- Desk derived from Dim_Country.Region via Region-to-Desk mapping
- EU = 1 for EU countries, 0 for non-EU

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — filter on VersionID + CountryID + AttributedID for specific cohort analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Watchlist conversion rate by country | `SELECT Country, SUM(FirstActions_from_WL)*1.0/NULLIF(SUM(FirstActions),0) FROM ... GROUP BY Country` |
| Best-performing funnel for watchlist | `GROUP BY FunnelName` and compare `FirstActions_from_WL / FirstActions` |
| Cohort LTV by version | `SELECT VersionID, SUM(Sum_8Y_LTV)/NULLIF(SUM(Count_8Y_LTV),0) AS avg_ltv FROM ... GROUP BY VersionID` |
| EU vs non-EU watchlist effectiveness | `GROUP BY EU` and compare conversion rates |
| Version-over-version trend | `ORDER BY Version_FirstDate` to track watchlist improvements over time |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Watchlist_Tracking_Item_Level | VersionID + CountryID + AttributedID | Drill down to per-item detail |
| BI_DB_WatchListsByFunnel | VersionID | Watchlist version metadata and item list |
| DWH_dbo.Dim_Country | CountryID | Full country dimension attributes |

### 3.4 Gotchas

- **Paired table**: This is the aggregated view. For per-item detail, use BI_DB_Watchlist_Tracking_Item_Level
- **Same SP writes both tables**: SP_Watchlist_Tracking writes Item Level first, then aggregates into this table
- **Division by zero**: Always use NULLIF when computing ratios (FirstActions can be 0 for some country/funnel combos)
- **LTV NoExtreme**: The extreme outlier exclusion threshold is defined in BI_DB_LTV_BI_Actual, not in this SP
- **Sum + Count pattern**: Revenue, Deposit, and LTV columns come in Sum/Count pairs to enable average calculation without losing the denominator
- **Reg and FTD are cohort-level**: These are NOT derived from the Item Level table — they come from separate CIDFirstDates/Dim_Customer joins

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | System/ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | VersionID | int | NO | Watchlist version ID. Foreign key to BI_DB_WatchListsByFunnel. Part of the primary grain (Version x Country x Funnel). (Tier 2 — SP_Watchlist_Tracking) |
| 2 | CountryID | int | NO | Country ID. Foreign key to Dim_Country. Part of the primary grain. (Tier 2 — SP_Watchlist_Tracking) |
| 3 | Country | varchar(50) | YES | Country name. Passthrough from Dim_Country. (Tier 2 — SP_Watchlist_Tracking, Dim_Country) |
| 4 | Region | varchar(50) | YES | Marketing region. Passthrough from Dim_Country.Region. (Tier 2 — SP_Watchlist_Tracking, Dim_Country) |
| 5 | Desk | nvarchar(50) | YES | Sales desk. Derived from Dim_Country.Region via Region-to-Desk mapping. (Tier 2 — SP_Watchlist_Tracking, Dim_Country) |
| 6 | EU | int | YES | EU flag: 1=EU country, 0=non-EU. Passthrough from Dim_Country. (Tier 2 — SP_Watchlist_Tracking, Dim_Country) |
| 7 | AttributedID | int | NO | Funnel attributed ID: 1=Stocks, 2=Crypto, 3=Copy, 4=CopyPortfolio, 5=CFD, 0=unattributed. Part of the primary grain. (Tier 2 — SP_Watchlist_Tracking) |
| 8 | FunnelName | varchar(50) | YES | Human-readable funnel display name corresponding to AttributedID. (Tier 2 — SP_Watchlist_Tracking) |
| 9 | FirstActions | int | YES | Total count of users in this cohort whose first platform action was a trade (any item). Aggregated from Item Level SUM(Users_TradedAsFirstAction). (Tier 2 — SP_Watchlist_Tracking) |
| 10 | FirstActions_from_WL | int | YES | Count of users whose first action was trading a watchlist item (Is_In_WL=1). Subset of FirstActions. (Tier 2 — SP_Watchlist_Tracking) |
| 11 | First5Actions_Trades | int | YES | Total first-5-action trades across all items in this cohort. Aggregated from Item Level. (Tier 2 — SP_Watchlist_Tracking) |
| 12 | First5Actions_from_WL | int | YES | First-5-action trades from watchlist items only (Is_In_WL=1). Subset of First5Actions_Trades. (Tier 2 — SP_Watchlist_Tracking) |
| 13 | PositionsOpened_or_CopyOpened | int | YES | Total positions opened or copy relationships started across all items. Aggregated from Item Level. (Tier 2 — SP_Watchlist_Tracking) |
| 14 | PositionsOpened_or_CopyOpened_from_WL | int | YES | Positions/copy from watchlist items only (Is_In_WL=1). Subset of PositionsOpened_or_CopyOpened. (Tier 2 — SP_Watchlist_Tracking) |
| 15 | Reg | int | YES | Registration count for this cohort (Country x Funnel x Version). From CIDFirstDates + Dim_Customer, NOT aggregated from Item Level. (Tier 2 — SP_Watchlist_Tracking) |
| 16 | FTD | int | YES | First-time depositor count for this cohort. From CIDFirstDates, NOT aggregated from Item Level. (Tier 2 — SP_Watchlist_Tracking) |
| 17 | Sum_Revenue30days | decimal(38,2) | YES | Sum of 30-day revenue for all customers in this cohort. For average: divide by Count_Revenue30days. (Tier 2 — SP_Watchlist_Tracking) |
| 18 | Count_Revenue30days | int | YES | Count of customers with non-NULL 30-day revenue in this cohort. Denominator for average revenue. (Tier 2 — SP_Watchlist_Tracking) |
| 19 | Sum_Deposit30days | decimal(38,2) | YES | Sum of 30-day deposits for all customers in this cohort. For average: divide by Count_Deposit30days. (Tier 2 — SP_Watchlist_Tracking) |
| 20 | Count_Deposit30days | int | YES | Count of customers with non-NULL 30-day deposits in this cohort. Denominator for average deposits. (Tier 2 — SP_Watchlist_Tracking) |
| 21 | Sum_8Y_LTV | numeric(38,6) | YES | Sum of 8-year LTV for all customers with LTV data in this cohort. From BI_DB_LTV_BI_Actual. (Tier 2 — SP_Watchlist_Tracking) |
| 22 | Count_8Y_LTV | int | YES | Count of customers with 8-year LTV data. Denominator for average LTV. (Tier 2 — SP_Watchlist_Tracking) |
| 23 | Sum_8Y_LTV_NoExtreme | numeric(38,6) | YES | Sum of 8-year LTV excluding extreme outliers. Outlier threshold defined in BI_DB_LTV_BI_Actual. (Tier 2 — SP_Watchlist_Tracking) |
| 24 | Count_8Y_LTV_NoExtreme | int | YES | Count of customers with non-extreme 8-year LTV. Denominator for average LTV excluding outliers. (Tier 2 — SP_Watchlist_Tracking) |
| 25 | Version_FirstDate | date | YES | Start date of this watchlist version. Passthrough from BI_DB_WatchListsByFunnel. (Tier 2 — SP_Watchlist_Tracking) |
| 26 | Version_LastDate | date | YES | End date of this watchlist version. Passthrough from BI_DB_WatchListsByFunnel. (Tier 2 — SP_Watchlist_Tracking) |
| 27 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. All rows share the same value per daily run. (Tier 5 — system) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| FirstActions, First5Actions_Trades, PositionsOpened_or_CopyOpened | BI_DB_Watchlist_Tracking_Item_Level | Users_TradedAsFirstAction, First5Actions_Trades, PositionsOpened_or_CopyOpened | SUM (all items) |
| FirstActions_from_WL, First5Actions_from_WL, PositionsOpened_or_CopyOpened_from_WL | BI_DB_Watchlist_Tracking_Item_Level | same columns | SUM WHERE Is_In_WL=1 |
| Reg, FTD | BI_DB_CIDFirstDates + Dim_Customer | registration/FTD dates | COUNT per cohort |
| Sum/Count_Revenue30days, Sum/Count_Deposit30days | BI_DB_CIDFirstDates / Dim_Customer | 30-day revenue/deposit values | SUM/COUNT per cohort |
| Sum/Count_8Y_LTV, Sum/Count_8Y_LTV_NoExtreme | BI_DB_LTV_BI_Actual | LTV_8Y | SUM/COUNT per cohort |
| CountryID, Country, Region, Desk, EU | DWH_dbo.Dim_Country | various | passthrough / Region-to-Desk mapping |
| VersionID, Version_FirstDate, Version_LastDate | BI_DB_WatchListsByFunnel | VersionID, FirstDate, LastDate | passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level (written first by same SP)
  + BI_DB_dbo.BI_DB_CIDFirstDates (registration/FTD dates)
  + DWH_dbo.Dim_Customer (customer attributes)
  + BI_DB_dbo.BI_DB_First5Actions (funnel attribution)
  + BI_DB_dbo.BI_DB_LTV_BI_Actual (8-year LTV)
  + BI_DB_dbo.BI_DB_WatchListsByFunnel (version dates)
  + DWH_dbo.Dim_Country (Region -> Desk mapping)
  |
  |-- SP_Watchlist_Tracking (daily TRUNCATE+INSERT, second output)
  |   Step 1: Aggregate Item Level metrics by VersionID x CountryID x AttributedID
  |   Step 2: Split totals vs _from_WL (Is_In_WL filter)
  |   Step 3: Join cohort Reg/FTD counts from CIDFirstDates
  |   Step 4: Join 30-day revenue/deposit metrics
  |   Step 5: Join 8-year LTV metrics from LTV_BI_Actual
  |   Step 6: Enrich with version dates from WatchListsByFunnel
  |   Step 7: TRUNCATE + INSERT into BI_DB_Watchlist_Tracking_High_Level
  v
BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level (ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| VersionID | BI_DB_dbo.BI_DB_WatchListsByFunnel | Watchlist version definition |
| CountryID | DWH_dbo.Dim_Country (CountryID) | Country dimension |
| Trade metrics | BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level | Aggregated from detail table |
| LTV metrics | BI_DB_dbo.BI_DB_LTV_BI_Actual | 8-year LTV source |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Watchlist Conversion Rate by Country (Latest Version)

```sql
SELECT Country, Region, Desk,
       SUM(FirstActions_from_WL) * 1.0 / NULLIF(SUM(FirstActions), 0) AS wl_first_action_rate,
       SUM(Reg) AS total_registrations,
       SUM(FTD) AS total_ftd
FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level
WHERE VersionID = (SELECT MAX(VersionID) FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level)
GROUP BY Country, Region, Desk
ORDER BY wl_first_action_rate DESC
```

### 7.2 Version-Over-Version Watchlist Effectiveness Trend

```sql
SELECT VersionID, Version_FirstDate, Version_LastDate,
       SUM(FirstActions_from_WL) * 1.0 / NULLIF(SUM(FirstActions), 0) AS wl_first_action_rate,
       SUM(First5Actions_from_WL) * 1.0 / NULLIF(SUM(First5Actions_Trades), 0) AS wl_first5_rate,
       SUM(Sum_8Y_LTV) / NULLIF(SUM(Count_8Y_LTV), 0) AS avg_ltv
FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level
GROUP BY VersionID, Version_FirstDate, Version_LastDate
ORDER BY Version_FirstDate
```

### 7.3 Funnel Comparison with LTV

```sql
SELECT FunnelName,
       SUM(Reg) AS registrations,
       SUM(FTD) AS ftd,
       SUM(Sum_Revenue30days) / NULLIF(SUM(Count_Revenue30days), 0) AS avg_revenue_30d,
       SUM(Sum_8Y_LTV_NoExtreme) / NULLIF(SUM(Count_8Y_LTV_NoExtreme), 0) AS avg_ltv_no_extreme
FROM BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level
GROUP BY FunnelName
ORDER BY avg_ltv_no_extreme DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 26 T2, 0 T3, 0 T4, 1 T5 | Elements: 27/27, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level | Type: Table | Production Source: BI_DB_Watchlist_Tracking_Item_Level + CIDFirstDates + LTV_BI_Actual via SP_Watchlist_Tracking*
