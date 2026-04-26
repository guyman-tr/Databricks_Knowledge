# BI_DB_dbo.BI_DB_Cross_Selling_Daily

> 887.8M-row daily cross-selling product-holdings panel for all active depositors (2.69M distinct CIDs per day). Captures product type usage per customer per date across 7 categories: ETF, Smart Portfolios, Copy Trader, CFD, Real Crypto, Real Non-US Stocks, Real US Stocks, and eMoney — with distinct semantics for "currently holding" vs "active in last 3 months". Built by SP_Cross_Selling_Daily, data spans February 2025 to April 2026 (418 dates).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + Dim_Mirror + V_Liabilities + Fact_SnapshotCustomer via SP_Cross_Selling_Daily |
| **Refresh** | Daily — DELETE WHERE DateKey=@date_int + INSERT (incremental per date) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Cross_Selling_Daily is a daily snapshot of which eToro product categories each active depositor holds or has been active in. Each row represents one customer on one date, with binary (0/1) flags for most product types plus a count for CFD active opens.

The table powers cross-sell analysis: identifying customers who hold only one product type (55% of rows on 2026-04-11 have Total_Products=1) and those with multi-product portfolios. On 2026-04-11, 2.16M CIDs had Total_Products>0, with Real Crypto (61%) and Real US Stocks (50%) as the two dominant holdings.

**Product column semantics** — two distinct definitions coexist:
- **Hold columns** (ETF_Hold, Smart_Portfolios_Hold, Copy_Trader_Hold): customer has an open position at @date
- **ActiveOpen3M columns** (CFD_ActiveOpen3M, eMoney_ActiveOpen3M): activity within the last 3 months
- **Union columns** (Real_Crypto, Real_Non_US_Stocks, Real_US_Stocks): 1 if Hold OR ActiveOpen3M for that asset class

**3-month window**: On EOM dates, the lookback is 2 prior months (to avoid partial-month bias). On other days, it is 3 calendar months back.

**eMoney filter**: eMoney_ActiveOpen3M uses ActionTypeID=44 (eToro Money IBAN trade), restricted to ValidETM accounts with GCID_Unique_Count=1, and only counts activity from 2024-04-01 onwards.

EOM_Club and ClusterDetail come from BI_DB_CID_MonthlyPanel_FullData at the beginning of the current month — they are month-level attributes, not daily-refreshed.

---

## 2. Business Logic

### 2.1 Product Hold Logic (ETF / Smart Portfolios / Copy Trader)

**What**: Flags whether the customer has an open position in each non-real-assets product type at @date.

**Columns Involved**: `ETF_Hold`, `Smart_Portfolios_Hold`, `Copy_Trader_Hold`

**Rules**:
- ETF_Hold=1: has open Dim_Position row with InstrumentTypeID=6, IsSettled=1, MirrorID=0, OpenDateID<=@date_int, (CloseDateID>@date_int OR CloseDateID=0), IsAirDrop=0, IsPartialCloseChild=0
- Smart_Portfolios_Hold=1: has open Dim_Mirror row with MirrorTypeID=4, OpenDateID<=@date_int, (CloseDateID>@date_int OR CloseDateID=0)
- Copy_Trader_Hold=1: has open Dim_Mirror row with MirrorTypeID≠4 (same open-date filter as above)

### 2.2 Real Assets Union Logic (Crypto / Non-US Stocks / US Stocks)

**What**: Combined "engaged" flag — customer holds OR has opened recently.

**Columns Involved**: `Real_Crypto`, `Real_Non_US_Stocks`, `Real_US_Stocks`

**Rules**:
- Real_Crypto=1 if: (holds open real crypto position today) OR (opened real crypto position in last 3M)
  - InstrumentTypeID=10, IsSettled=1
- Real_Non_US_Stocks=1 if: holds OR opened in last 3M, InstrumentTypeID=5, IsSettled=1, Exchange NOT IN (US exchanges)
- Real_US_Stocks=1 if: holds OR opened in last 3M, InstrumentTypeID=5, IsSettled=1, Exchange IN ('Chicago Board Options Exchange', 'NYSE', 'Nasdaq', 'OTC Markets Stock Exchange')

### 2.3 CFD ActiveOpen3M Count

**What**: Integer count (not binary) of CFD positions the customer opened in the last 3 months.

**Columns Involved**: `CFD_ActiveOpen3M`

**Rules**:
- IsSettled=0, MirrorID=0, OpenDateID in [@StartOpenDate, @date_int]
- CFD_ActiveOpen3M is a SUM/COUNT, not a 0/1 flag — can be >1 unlike other product columns
- 15.1% of customers had CFD_ActiveOpen3M>0 on 2026-04-11

### 2.4 High Bronze+ Equity Threshold

**What**: Binary flag for customers with total equity ≥ $1,000.

**Columns Involved**: `High_Bronze+`

**Rules**:
- High_Bronze+ = CASE WHEN (ActualNWA + Liabilities) >= 1000 THEN 1 ELSE 0 END
- Sourced from V_Liabilities at DateID=@date_int (LEFT JOIN — customers with no V_Liabilities row get High_Bronze+=NULL → 0 via ISNULL)
- 42.6% of customers qualify on 2026-04-11

### 2.5 Total Products Count

**What**: Sum of all 7 product engagement indicators for cross-sell cardinality.

**Columns Involved**: `Total_Products`

**Rules**:
- Total_Products = ETF_Hold + Smart_Portfolios_Hold + Copy_Trader_Hold + CFD_ActiveOpen3M + Real_Crypto + Real_Non_US_Stocks + Real_US_Stocks + eMoney_ActiveOpen3M
- Note: CFD_ActiveOpen3M is an int (can be >1), inflating Total_Products for heavy CFD traders
- Only rows with Total_Products > 0 are inserted (customers with zero engagement on all 7 dimensions are excluded)
- Distribution on 2026-04-11: 1 product (55%), 2 (24%), 3 (13%), 4+ (8%)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution + HEAP — optimised for full-scan cross-sell aggregations, not point lookups. No clustered index means range scans by date are full-table scans unless filtered early. Filter on DateKey (int) rather than FullDate (date) for slightly better predicate pushdown on HEAP tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Who are customers with only 1 product type? | `WHERE DateKey=X AND Total_Products=1` |
| Cross-sell opportunity for ETF → Real Stocks | `WHERE DateKey=X AND ETF_Hold=1 AND Real_US_Stocks=0 AND Real_Non_US_Stocks=0` |
| eMoney engagement by club tier | `WHERE DateKey=X GROUP BY EOM_Club` with `SUM(eMoney_ActiveOpen3M)/COUNT(*)` |
| Multi-product customers | `WHERE DateKey=X AND Total_Products>=3` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON cs.CID = dc.RealCID` | Customer demographics |
| DWH_dbo.Dim_Country | `ON dc.Name = cs.Country` (or use Dim_Customer for CountryID) | Country-level grouping |
| BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | `ON cs.CID = mp.CID AND mp.ActiveDate = [first_day_of_month]` | Additional monthly metrics |

### 3.4 Gotchas

- **[High_Bronze+]**: Column name contains `+` — always use bracket quoting: `[High_Bronze+]`
- **CFD_ActiveOpen3M is not binary**: It's an integer count, not 0/1 like other columns — can inflate Total_Products comparisons
- **EOM_Club is monthly, not daily**: Sourced from beginning-of-month snapshot — does not reflect intra-month club changes
- **eMoney_ActiveOpen3M only from Apr 2024**: Pre-2024-04-01 rows have eMoney_ActiveOpen3M=0 regardless of actual eMoney activity
- **HEAP + ROUND_ROBIN**: No optimal distribution — all joins cause data movement in Synapse. Use CTEs to pre-filter date slices before joining
- **3M window varies**: On EOM dates, window = 2 months back (not 3) — avoid exact date arithmetic assumptions
- **Country/Region from snapshot-date join**: Reflects country at ETL run time, not at position open time

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (authoritative) |
| Tier 2 | Derived from ETL SP code analysis — high confidence |
| Tier 3 | Derived from external/config sources — moderate confidence |
| Propagation | ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateKey | int | YES | ETL date integer (YYYYMMDD) for the reporting date. Derived as CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Used for incremental DELETE+INSERT (DELETE WHERE DateKey=@date_int). (Tier 2 — SP_Cross_Selling_Daily) |
| 2 | FullDate | date | YES | Reporting date (e.g., 2026-04-11). Matches @date parameter passed to SP. Always equals CAST(DateKey as date). (Tier 2 — SP_Cross_Selling_Daily) |
| 3 | CID | bigint | YES | Customer ID — platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 4 | Country | varchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — Dim_Country wiki) |
| 5 | Region | varchar(max) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. (Tier 3 — Dim_Country.MarketingRegionManualName via Ext_Dim_Country) |
| 6 | EOM_Club | varchar(max) | YES | eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000–Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. Distribution on 2026-04-11: LowBronze 53%, HighBronze 18%, Silver 10%, Gold 9%, Platinum 5%, Platinum+ 4%, Diamond <1%. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki) |
| 7 | ClusterDetail | varchar(max) | YES | Customer behaviour cluster name from BI_DB_CID_DailyCluster (e.g., 'Equities Crypto'). NULL for unclustered customers. (Tier 2 — BI_DB_CID_DailyCluster) |
| 8 | High_Bronze+ | int | YES | Binary flag: 1 if total equity (ActualNWA + Liabilities from V_Liabilities) >= $1,000 at @date, else 0. 42.6% of customers qualify on 2026-04-11. Column name contains '+' — must use bracket quoting: [High_Bronze+]. NULL if customer has no V_Liabilities row. (Tier 2 — SP_Cross_Selling_Daily) |
| 9 | ETF_Hold | int | YES | 1 if customer has at least one open ETF position (InstrumentTypeID=6, IsSettled=1, MirrorID=0) at @date; 0 otherwise. 8.3% of customers on 2026-04-11. (Tier 2 — SP_Cross_Selling_Daily) |
| 10 | Smart_Portfolios_Hold | int | YES | 1 if customer has at least one open CopyPortfolio mirror (Dim_Mirror.MirrorTypeID=4) at @date; 0 otherwise. 4.3% of customers on 2026-04-11. (Tier 2 — SP_Cross_Selling_Daily) |
| 11 | Copy_Trader_Hold | int | YES | 1 if customer has at least one open Copy Trader mirror (Dim_Mirror.MirrorTypeID≠4) at @date; 0 otherwise. 10.5% of customers on 2026-04-11. (Tier 2 — SP_Cross_Selling_Daily) |
| 12 | CFD_ActiveOpen3M | int | YES | Count (not binary) of CFD positions (IsSettled=0, MirrorID=0) opened by this customer in the last 3 months. Unlike other product columns this can be >1. 15.1% of customers had CFD_ActiveOpen3M>0 on 2026-04-11. (Tier 2 — SP_Cross_Selling_Daily) |
| 13 | Real_Crypto | int | YES | 1 if customer holds an open real crypto position (InstrumentTypeID=10, IsSettled=1) at @date OR opened one in the last 3 months; 0 otherwise. Dominant product: 60.6% of customers on 2026-04-11. (Tier 2 — SP_Cross_Selling_Daily) |
| 14 | Real_Non_US_Stocks | int | YES | 1 if customer holds or recently opened real non-US stock positions (InstrumentTypeID=5, IsSettled=1, Exchange not in US exchanges) at @date OR in last 3M; 0 otherwise. 22.1% of customers on 2026-04-11. US exchanges = 'Chicago Board Options Exchange', 'NYSE', 'Nasdaq', 'OTC Markets Stock Exchange'. (Tier 2 — SP_Cross_Selling_Daily) |
| 15 | Real_US_Stocks | int | YES | 1 if customer holds or recently opened real US stock positions (InstrumentTypeID=5, IsSettled=1, Exchange IN US exchanges) at @date OR in last 3M; 0 otherwise. 50.5% of customers on 2026-04-11. (Tier 2 — SP_Cross_Selling_Daily) |
| 16 | eMoney_ActiveOpen3M | int | YES | 1 if customer executed an eToro Money IBAN trade (Fact_CustomerAction.ActionTypeID=44) in the last 3 months, restricted to ValidETM accounts (eMoney_Dim_Account.IsValidETM=1, GCID_Unique_Count=1). Only populated for activity from 2024-04-01 onwards; earlier rows always 0. (Tier 2 — SP_Cross_Selling_Daily) |
| 17 | Total_Products | int | YES | Sum of all 7 product engagement flags: ETF_Hold + Smart_Portfolios_Hold + Copy_Trader_Hold + CFD_ActiveOpen3M + Real_Crypto + Real_Non_US_Stocks + Real_US_Stocks + eMoney_ActiveOpen3M. Range: 1–8 (Total_Products=0 rows are excluded from INSERT). Distribution: 1 product (55%), 2 (24%), 3 (13%), 4 (6%), 5+ (2%) on 2026-04-11. Note: CFD_ActiveOpen3M is an int so can inflate this sum for active CFD traders. (Tier 2 — SP_Cross_Selling_Daily) |
| 18 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Direct passthrough |
| Country | DWH_dbo.Dim_Country | Name | JOIN on CountryID |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | JOIN on CountryID |
| EOM_Club | BI_DB_CID_MonthlyPanel_FullData | EOM_Club | Beginning-of-month snapshot |
| ClusterDetail | BI_DB_CID_MonthlyPanel_FullData | ClusterDetail | Beginning-of-month snapshot |
| High_Bronze+ | DWH_dbo.V_Liabilities | ActualNWA + Liabilities | CASE WHEN >= 1000 |
| ETF_Hold | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentTypeID=6 | Open position flag |
| Smart_Portfolios_Hold | DWH_dbo.Dim_Mirror | MirrorTypeID=4 | Open mirror flag |
| Copy_Trader_Hold | DWH_dbo.Dim_Mirror | MirrorTypeID<>4 | Open mirror flag |
| CFD_ActiveOpen3M | DWH_dbo.Dim_Position | IsSettled=0, 3M window | Position count |
| Real_Crypto | DWH_dbo.Dim_Position | InstrumentTypeID=10 | Hold OR Active3M |
| Real_Non_US_Stocks | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentTypeID=5, non-US | Hold OR Active3M |
| Real_US_Stocks | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentTypeID=5, US | Hold OR Active3M |
| eMoney_ActiveOpen3M | DWH_dbo.Fact_CustomerAction | ActionTypeID=44, from Apr 2024 | 3M activity flag |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Country
  |-- Population: IsValidCustomer=1, IsDepositor=1 → #CIDs (CID, Country, Region)
  |
DWH_dbo.V_Liabilities (DateID=@date_int)
  |-- #AUA: Equity = ActualNWA + Liabilities, High_Bronze+ flag
  |
BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData (@beginning_of_Month)
  |-- #club: EOM_Club, ClusterDetail (monthly snapshot)
  |
DWH_dbo.Dim_Position + Dim_Instrument [open at @date]
  |-- #position_held: ETF/Real_Crypto/Real_Stocks/CFD hold flags
  |
DWH_dbo.Dim_Mirror [open at @date]
  |-- #position_held: Smart_Portfolios_Hold, Copy_Trader_Hold
  |
DWH_dbo.Dim_Position + Fact_CustomerAction [last 3M]
  |-- #position_activeopen3M: CFD_ActiveOpen3M, ActiveOpen3M flags
  |
DWH_dbo.Fact_CustomerAction (ActionTypeID=44) + eMoney_Dim_Account
  |-- #TradedFromIban3M: eMoney_ActiveOpen3M (from Apr 2024)
  |
  └─ SP_Cross_Selling_Daily (@date)
       DELETE WHERE DateKey=@date_int
       INSERT WHERE Total_Products>0
       ↓
  BI_DB_dbo.BI_DB_Cross_Selling_Daily (887.8M rows)
       (UC: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer identity |
| Country | DWH_dbo.Dim_Country.Name | Country decode |
| EOM_Club, ClusterDetail | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | Monthly CRM panel |
| ETF_Hold, Real_* flags | DWH_dbo.Dim_Position | Open position source |
| Copy_Trader_Hold, Smart_Portfolios_Hold | DWH_dbo.Dim_Mirror | Open mirror source |

### 6.2 Referenced By (other objects point to this)

| Object | Reference | Purpose |
|--------|-----------|---------|
| BI_DB_dbo.BI_DB_Cross_Selling_Monthly | Same SP family | Monthly sibling aggregation |

---

## 7. Sample Queries

### Cross-sell opportunity: customers with only Real Crypto (no stocks or ETF)

```sql
SELECT COUNT(DISTINCT CID) AS crypto_only_cids
FROM [BI_DB_dbo].[BI_DB_Cross_Selling_Daily]
WHERE DateKey = 20260411
  AND Real_Crypto = 1
  AND Real_US_Stocks = 0
  AND Real_Non_US_Stocks = 0
  AND ETF_Hold = 0
```

### Multi-product distribution by club tier

```sql
SELECT EOM_Club
     , Total_Products
     , COUNT(*) AS cid_count
     , COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY EOM_Club) AS pct
FROM [BI_DB_dbo].[BI_DB_Cross_Selling_Daily]
WHERE DateKey = 20260411
GROUP BY EOM_Club, Total_Products
ORDER BY EOM_Club, Total_Products
```

### eMoney engagement trend over last 30 days

```sql
SELECT FullDate
     , SUM(eMoney_ActiveOpen3M) AS emoney_active_cids
     , COUNT(*) AS total_cids
     , SUM(eMoney_ActiveOpen3M) * 100.0 / COUNT(*) AS pct_emoney
FROM [BI_DB_dbo].[BI_DB_Cross_Selling_Daily]
WHERE DateKey >= 20260312
GROUP BY FullDate, DateKey
ORDER BY DateKey
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for BI_DB_Cross_Selling_Daily.

---

*Generated: 2026-04-23 | Quality: 8.7/10 | Phases: 14/14*
*Tiers: 3 T1, 13 T2, 1 T3, 0 T4, 1 Propagation | Elements: 18/18, Logic: 5 subsections*
*Object: BI_DB_dbo.BI_DB_Cross_Selling_Daily | Type: Table | Production Source: SP_Cross_Selling_Daily*
