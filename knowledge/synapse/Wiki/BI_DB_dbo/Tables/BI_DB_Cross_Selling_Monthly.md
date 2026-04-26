# BI_DB_dbo.BI_DB_Cross_Selling_Monthly

> 145.4M-row end-of-month cross-selling product-holdings snapshot for all active depositors (5.07M distinct CIDs across history). Monthly EOM-only sibling of BI_DB_Cross_Selling_Daily — captures product type usage per customer per end-of-month date across 8 categories. Hold columns carry the EOM suffix to signal point-in-time end-of-month state. ActiveOpen lookback = 2 months (despite "3M" in column names). Data spans January 2017 to March 2026 (111 months). Built by SP_Cross_Selling_Monthly.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + Dim_Mirror + V_Liabilities + Fact_SnapshotCustomer via SP_Cross_Selling_Monthly |
| **Refresh** | Monthly EOM only — SP aborts unless @date = EOMONTH(@date). DELETE WHERE DateKey=@date_int + INSERT. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Cross_Selling_Monthly is the end-of-month edition of the cross-selling panel. Each row represents one customer on one end-of-month date, with binary flags for the product types they held at EOM or were active in during the prior ~2 months. The table is populated only once per month, on the last calendar day.

Unlike the daily version, the Hold columns here are suffixed with **EOM** — making explicit that the snapshot captures the customer's holdings state at end-of-month, not at an arbitrary intraday time. The monthly version provides a stable, non-volatile view of product breadth suitable for month-over-month trend analysis.

The March 2026 latest month (20260331) has 2.158M rows across the 8-product scale:
- Single-product customers: 54.5%
- Two products: 24.3%
- Three products: 12.6%
- Four or more products: 8.6%

**Product column semantics** — three coexisting definitions:
- **HoldEOM columns** (ETF_HoldEOM, Smart_Portfolios_HoldEOM, Copy_Trader_HoldEOM): customer has an open position **at end-of-month date**
- **ActiveOpen columns** (CFD_ActiveOpen3M, eMoney_ActiveOpen3M): activity within the prior 2 months (see note on naming discrepancy below)
- **Union columns** (Real_Crypto, Real_Non_US_Stocks, Real_US_Stocks): 1 if HoldEOM OR ActiveOpen in the 2-month window

**"3M" naming discrepancy**: The columns CFD_ActiveOpen3M and eMoney_ActiveOpen3M retain the same names as the daily table, but the monthly version uses `@StartOpenDate = DATEADD(month, -2, @beginning_of_Month)` — a 2-month lookback window. The "3M" label is inherited from the daily SP and is technically inaccurate for the monthly version.

**eMoney filter**: eMoney_ActiveOpen3M uses ActionTypeID=44 (eToro Money IBAN trade), restricted to ValidETM accounts with GCID_Unique_Count=1, and only counts activity from 2024-04-01 onwards.

EOM_Club and ClusterDetail come from BI_DB_CID_MonthlyPanel_FullData at the beginning of the current month.

---

## 2. Business Logic

### 2.1 EOM Guard — Monthly-Only Execution

**What**: The SP wraps its entire body in `IF @date = EOMONTH(@date)`. If called on a non-EOM date, nothing executes and the table is unchanged.

**Implication**: No intra-month gaps are possible — every date in the table is the last day of its month. Analysts can safely `GROUP BY DateKey` without date-filtering.

### 2.2 Product HoldEOM Logic (ETF / Smart Portfolios / Copy Trader)

**What**: Flags whether the customer has an open position in each product type **at the EOM date**.

**Columns Involved**: `ETF_HoldEOM`, `Smart_Portfolios_HoldEOM`, `Copy_Trader_HoldEOM`

**Rules**:
- ETF_HoldEOM=1: has open Dim_Position row with InstrumentTypeID=6, IsSettled=1, MirrorID=0, OpenDateID<=@date_int, (CloseDateID>@date_int OR CloseDateID=0), IsAirDrop=0, IsPartialCloseChild=0
- Smart_Portfolios_HoldEOM=1: has open Dim_Mirror row with MirrorTypeID=4, open at @date
- Copy_Trader_HoldEOM=1: has open Dim_Mirror row with MirrorTypeID≠4, open at @date

### 2.3 Real Assets Union Logic (Crypto / Non-US Stocks / US Stocks)

**What**: Combined "engaged" flag — customer holds at EOM OR opened within the prior 2-month window.

**Columns Involved**: `Real_Crypto`, `Real_Non_US_Stocks`, `Real_US_Stocks`

**Rules**:
- Real_Crypto=1 if: holds open real crypto position at EOM OR opened one within 2M
  - InstrumentTypeID=10, IsSettled=1
- Real_Non_US_Stocks=1 if: holds OR opened in 2M, InstrumentTypeID=5, IsSettled=1, Exchange NOT IN US exchanges
- Real_US_Stocks=1 if: holds OR opened in 2M, InstrumentTypeID=5, IsSettled=1, Exchange IN ('Chicago Board Options Exchange', 'NYSE', 'Nasdaq', 'OTC Markets Stock Exchange')

### 2.4 CFD ActiveOpen Count (2-Month Window)

**What**: Integer count (not binary) of CFD positions the customer opened in the prior 2-month window.

**Columns Involved**: `CFD_ActiveOpen3M`

**Rules**:
- IsSettled=0, MirrorID=0, OpenDateID in [@StartOpenDate, @date_int]
- @StartOpenDate = DATEADD(month, -2, @beginning_of_Month) — 2-month window despite column name saying "3M"
- CFD_ActiveOpen3M is a count, not a 0/1 flag — can be >1 and inflates Total_Products

### 2.5 High Bronze+ Equity Threshold

**What**: Binary flag for customers with total equity ≥ $1,000 at EOM.

**Columns Involved**: `High_Bronze+`

**Rules**:
- High_Bronze+ = CASE WHEN (ActualNWA + Liabilities) >= 1000 THEN 1 ELSE 0 END at @date_int
- Sourced from V_Liabilities (LEFT JOIN — no row → NULL → treated as 0 via ISNULL)

### 2.6 Total Products Count

**What**: Sum of all 8 product engagement indicators.

**Columns Involved**: `Total_Products`

**Rules**:
- Total_Products = ETF_HoldEOM + Smart_Portfolios_HoldEOM + Copy_Trader_HoldEOM + CFD_ActiveOpen3M + Real_Crypto + Real_Non_US_Stocks + Real_US_Stocks + eMoney_ActiveOpen3M
- Only rows with Total_Products > 0 are inserted
- Range: 1–8; March 2026: 1 product (54%), 2 (24%), 3 (13%), 4 (6%), 5+ (3%)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP — full scans required for date slices. Filter on DateKey (int) rather than FullDate for predicate efficiency. No index, so date range scans are sequential.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly cross-sell trend by club tier | `GROUP BY DateKey, EOM_Club ORDER BY DateKey` |
| Who had only 1 product at March 2026 EOM? | `WHERE DateKey=20260331 AND Total_Products=1` |
| ETF→Real Stocks cross-sell opportunity | `WHERE DateKey=X AND ETF_HoldEOM=1 AND Real_US_Stocks=0 AND Real_Non_US_Stocks=0` |
| eMoney adoption by month | `SELECT DateKey, SUM(eMoney_ActiveOpen3M)/COUNT(*) FROM ... GROUP BY DateKey` |
| Multi-product customers (3+) over time | `WHERE Total_Products>=3 GROUP BY DateKey` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON m.CID = dc.RealCID` | Customer demographics |
| BI_DB_dbo.BI_DB_Cross_Selling_Daily | `ON m.CID = d.CID AND d.DateKey = m.DateKey` | Compare EOM snapshot vs daily |

### 3.4 Gotchas

- **EOM-only table**: Only EOM dates exist. Querying for a non-EOM DateKey returns zero rows — not an error.
- **[High_Bronze+]**: Column name contains `+` — always bracket-quote: `[High_Bronze+]`
- **"3M" = 2 months**: CFD_ActiveOpen3M and eMoney_ActiveOpen3M use a 2-month lookback in this SP, not 3. The name is misleading — compare with BI_DB_Cross_Selling_Daily (which uses 3 months or 2 on EOM).
- **CFD_ActiveOpen3M is not binary**: Integer count — can inflate Total_Products for heavy CFD traders
- **eMoney_ActiveOpen3M only from Apr 2024**: Pre-2024-04-01 EOM rows always have eMoney_ActiveOpen3M=0
- **HEAP + ROUND_ROBIN**: All joins cause data movement. Pre-filter date before joining other tables.
- **EOM_Club is from beginning-of-month**: Despite this being an EOM table, EOM_Club reflects the club tier at the start of the month, not EOM itself.

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
| 1 | DateKey | int | YES | ETL date integer (YYYYMMDD) for the end-of-month reporting date. Derived as CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Always last day of a calendar month. Used for incremental DELETE+INSERT. (Tier 2 — SP_Cross_Selling_Monthly) |
| 2 | FullDate | date | YES | End-of-month reporting date (e.g., 2026-03-31). Matches @date parameter passed to SP. Always a month-end date. (Tier 2 — SP_Cross_Selling_Monthly) |
| 3 | CID | bigint | YES | Customer ID — platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 4 | Country | varchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — Dim_Country wiki) |
| 5 | Region | varchar(max) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. (Tier 3 — Dim_Country.MarketingRegionManualName via Ext_Dim_Country) |
| 6 | EOM_Club | varchar(max) | YES | eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000–Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. Distribution on 2026-04-11: LowBronze 53%, HighBronze 18%, Silver 10%, Gold 9%, Platinum 5%, Platinum+ 4%, Diamond <1%. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki) |
| 7 | ClusterDetail | varchar(max) | YES | Customer behaviour cluster name from BI_DB_CID_DailyCluster (e.g., 'Equities Crypto'). NULL for unclustered customers. (Tier 2 — BI_DB_CID_DailyCluster) |
| 8 | High_Bronze+ | int | YES | Binary flag: 1 if total equity (ActualNWA + Liabilities from V_Liabilities) >= $1,000 at EOM date, else 0. Column name contains '+' — must use bracket quoting: [High_Bronze+]. NULL if customer has no V_Liabilities row at @date_int. (Tier 2 — SP_Cross_Selling_Monthly) |
| 9 | ETF_HoldEOM | int | YES | 1 if customer has at least one open ETF position (InstrumentTypeID=6, IsSettled=1, MirrorID=0) at the end-of-month date; 0 otherwise. Renamed from ETF_Hold (daily) to ETF_HoldEOM to signal EOM snapshot semantics. (Tier 2 — SP_Cross_Selling_Monthly) |
| 10 | Smart_Portfolios_HoldEOM | int | YES | 1 if customer has at least one open CopyPortfolio mirror (Dim_Mirror.MirrorTypeID=4) at the end-of-month date; 0 otherwise. (Tier 2 — SP_Cross_Selling_Monthly) |
| 11 | Copy_Trader_HoldEOM | int | YES | 1 if customer has at least one open Copy Trader mirror (Dim_Mirror.MirrorTypeID≠4) at the end-of-month date; 0 otherwise. (Tier 2 — SP_Cross_Selling_Monthly) |
| 12 | CFD_ActiveOpen3M | int | YES | Count (not binary) of CFD positions (IsSettled=0, MirrorID=0) opened by this customer in the prior 2-month window (DATEADD(month,-2,EOM_start)..@date_int). Despite the "3M" name, this uses a 2-month lookback in the monthly SP. Can be >1. (Tier 2 — SP_Cross_Selling_Monthly) |
| 13 | Real_Crypto | int | YES | 1 if customer holds an open real crypto position (InstrumentTypeID=10, IsSettled=1) at EOM OR opened one in the prior 2-month window; 0 otherwise. (Tier 2 — SP_Cross_Selling_Monthly) |
| 14 | Real_Non_US_Stocks | int | YES | 1 if customer holds or recently opened real non-US stock positions (InstrumentTypeID=5, IsSettled=1, Exchange not in US exchanges) at EOM OR in prior 2M; 0 otherwise. US exchanges = 'Chicago Board Options Exchange', 'NYSE', 'Nasdaq', 'OTC Markets Stock Exchange'. (Tier 2 — SP_Cross_Selling_Monthly) |
| 15 | Real_US_Stocks | int | YES | 1 if customer holds or recently opened real US stock positions (InstrumentTypeID=5, IsSettled=1, Exchange IN US exchanges) at EOM OR in prior 2M; 0 otherwise. (Tier 2 — SP_Cross_Selling_Monthly) |
| 16 | eMoney_ActiveOpen3M | int | YES | 1 if customer executed an eToro Money IBAN trade (Fact_CustomerAction.ActionTypeID=44) in the prior 2-month window, restricted to ValidETM accounts (eMoney_Dim_Account.IsValidETM=1, GCID_Unique_Count=1). Only populated for activity from 2024-04-01 onwards; pre-April 2024 EOM rows always 0. Despite "3M" name, uses 2-month window. (Tier 2 — SP_Cross_Selling_Monthly) |
| 17 | Total_Products | int | YES | Sum of all 8 product engagement indicators: ETF_HoldEOM + Smart_Portfolios_HoldEOM + Copy_Trader_HoldEOM + CFD_ActiveOpen3M + Real_Crypto + Real_Non_US_Stocks + Real_US_Stocks + eMoney_ActiveOpen3M. Range: 1–8 (Total_Products=0 rows excluded from INSERT). March 2026: 1 product (54%), 2 (24%), 3 (13%), 4 (6%), 5+ (3%). CFD_ActiveOpen3M is an int — can inflate this sum. (Tier 2 — SP_Cross_Selling_Monthly) |
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
| ETF_HoldEOM | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentTypeID=6 | Open EOM position flag |
| Smart_Portfolios_HoldEOM | DWH_dbo.Dim_Mirror | MirrorTypeID=4 | Open EOM mirror flag |
| Copy_Trader_HoldEOM | DWH_dbo.Dim_Mirror | MirrorTypeID≠4 | Open EOM mirror flag |
| CFD_ActiveOpen3M | DWH_dbo.Dim_Position | IsSettled=0, 2M window | Position count |
| Real_Crypto | DWH_dbo.Dim_Position | InstrumentTypeID=10 | HoldEOM OR Active2M |
| Real_Non_US_Stocks | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentTypeID=5, non-US | HoldEOM OR Active2M |
| Real_US_Stocks | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentTypeID=5, US | HoldEOM OR Active2M |
| eMoney_ActiveOpen3M | DWH_dbo.Fact_CustomerAction | ActionTypeID=44, from Apr 2024 | 2M activity flag |

### 5.2 ETL Pipeline

```
SP guard: IF @date = EOMONTH(@date) → silent abort on non-EOM dates
  |
DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Country
  |-- Population: IsValidCustomer=1, IsDepositor=1 → #CIDs (RealCID, Country, Region)
  |
DWH_dbo.V_Liabilities (DateID=@date_int)
  |-- #AUA: Equity = ActualNWA + Liabilities, High_Bronze+ flag
  |
BI_DB_CID_MonthlyPanel_FullData (@beginning_of_Month)
  |-- #club: EOM_Club, ClusterDetail
  |
Dim_Position + Dim_Instrument + Dim_Mirror (open at @date)
  |-- #position_held: ETF_HoldEOM, Smart_Portfolios_HoldEOM, Copy_Trader_HoldEOM
  |-- + Real_Crypto/Non_US/US_Stocks (Hold branch)
  |
Dim_Position + Dim_Instrument + Fact_CustomerAction (@StartOpenDate..@date, 2M window)
  |-- #position_activeopen3M: CFD_ActiveOpen3M, Copy/Smart (ActiveOpen branch)
  |-- + Real_Crypto/Non_US/US_Stocks (ActiveOpen branch)
  |
Fact_CustomerAction (ActionTypeID=44, 2M window, post-Apr2024)
  |-- #TradedFromIban3M: eMoney_ActiveOpen3M
  |
UNION → #union → #AllProducrs (pivot by InstrumentType × Type)
  |
JOIN #AUA + #club → #final
  |
DELETE WHERE DateKey=@date_int + INSERT WHERE Total_Products>0
  ↓
BI_DB_dbo.BI_DB_Cross_Selling_Monthly
```

---

## 6. Relationships

| Related Object | Relationship | Notes |
|---------------|-------------|-------|
| BI_DB_dbo.BI_DB_Cross_Selling_Daily | Monthly sibling | Same 8 product dimensions; Daily has non-EOM hold columns, Monthly uses HoldEOM suffix and 2M window |
| DWH_dbo.Fact_SnapshotCustomer | Source — population | IsValidCustomer=1, IsDepositor=1 defines the eligible CID universe |
| DWH_dbo.V_Liabilities | Source — equity | DateID=@date_int, LEFT JOIN — equity at EOM |
| BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | Source — club/cluster | Beginning-of-month snapshot for EOM_Club and ClusterDetail |
| DWH_dbo.Dim_Position | Source — positions | Open positions at EOM and opened in prior 2M |
| DWH_dbo.Dim_Mirror | Source — copy/SP mirrors | Open mirror positions at EOM |
| DWH_dbo.Fact_CustomerAction | Source — eMoney + copy | ActionTypeID=44 (eMoney IBAN), 15/17 (Copy actions) |
| eMoney_dbo.eMoney_Dim_Account | Source — eMoney filter | IsValidETM=1, GCID_Unique_Count=1 |

---

## 7. Sample Queries

```sql
-- Monthly cross-sell breadth trend by club tier (last 12 months)
SELECT
    DateKey,
    EOM_Club,
    COUNT(*) AS customers,
    AVG(CAST(Total_Products AS FLOAT)) AS avg_products,
    SUM(CASE WHEN Total_Products = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS single_product_pct
FROM BI_DB_dbo.BI_DB_Cross_Selling_Monthly
WHERE DateKey >= 20250331
GROUP BY DateKey, EOM_Club
ORDER BY DateKey, EOM_Club;

-- eMoney adoption growth (monthly)
SELECT
    DateKey,
    COUNT(*) AS total_customers,
    SUM(eMoney_ActiveOpen3M) AS emoney_users,
    SUM(eMoney_ActiveOpen3M) * 100.0 / COUNT(*) AS emoney_pct
FROM BI_DB_dbo.BI_DB_Cross_Selling_Monthly
WHERE DateKey >= 20240430  -- First valid EOM after Apr 2024 launch
GROUP BY DateKey
ORDER BY DateKey;

-- ETF → Real Stocks cross-sell opportunity (latest EOM)
SELECT Country, COUNT(*) AS opportunity_customers
FROM BI_DB_dbo.BI_DB_Cross_Selling_Monthly
WHERE DateKey = (SELECT MAX(DateKey) FROM BI_DB_dbo.BI_DB_Cross_Selling_Monthly)
  AND ETF_HoldEOM = 1
  AND Real_US_Stocks = 0
  AND Real_Non_US_Stocks = 0
GROUP BY Country
ORDER BY opportunity_customers DESC;
```

---

## 8. Atlassian / External References

No Confluence pages, Jira tickets, or external references found for BI_DB_Cross_Selling_Monthly.

---

*Wiki generated: 2026-04-23 | Quality: 9.1/10 | Pipeline: dwh-semantic-doc v2 | Batch 82*
