# BI_DB_dbo.BI_DB_CryptoDashboardNew

> 308.6M-row daily crypto-specific dashboard (Jan 2022–Apr 2026, 1,562 dates). Scoped exclusively to InstrumentTypeID=10 (Real Crypto). Each row aggregates AUA, PnL, revenue, and position counts for a (date × regulation × country × crypto-ticker × real/CFD × manual/copy × club × seniority) combination. Excludes Internal accounts (PlayerLevelID=4). Built by SP_BI_DB_CryptoDashboardNew. Active_Hold/Active_Hold_Real/Active_Hold_CFD are date-level scalars broadcast to every row.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + BI_DB_PositionPnL + Fact_CustomerAction + Fact_SnapshotCustomer + Fact_FirstCustomerAction via SP_BI_DB_CryptoDashboardNew |
| **Refresh** | Daily — DELETE WHERE DateID=@dateID + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CryptoDashboardNew is a daily aggregated dashboard table that tracks crypto market participation across eToro's customer base. It is the primary data source powering Crypto analytics dashboards — covering who holds and trades crypto, in what size, from which regulatory jurisdiction, and at which customer lifecycle stage.

**Scope**: Strictly InstrumentTypeID=10 (Real Crypto). Both Real positions (IsSettled=1, directly held crypto) and CFD positions on crypto are included, segmented by the `Real_CFD` column. Internal/employee accounts (PlayerLevelID=4) are excluded.

**Grain**: Each row is a unique combination of:
`(DateID, Regulation, Country, BuyCurrency, Real_CFD, Manual_Copy, Club, Seniority_daily_FTD_Group)`

On 2026-04-12, the most recent date: the table had 1,523,400 unique crypto holders (Active_Hold), of which 1,496,781 held Real crypto and 80,437 held CFD crypto. BTC, ETH, and XRP are the top currencies by row count.

**Metric overview**:
- **AUA**: Sum of (invested amount + unrealized PnL) — current market value of open positions in USD
- **PnL**: Unrealized profit/loss on open positions
- **Revenue**: Commission income (open + close spreads) + rollover fees on crypto
- **Active_Hold columns**: Date-level scalars — same value on every row for a given date (global unique holders, not segment counts)
- **Active_Hold_by_Inst**: Segment-level unique holder count — distinct from the date-level Active_Hold scalars

**Club and Seniority** were added by Adva Jakobson (2024-08-17) to support lifecycle and loyalty analysis on crypto trading.

---

## 2. Business Logic

### 2.1 Instrument Scope (Crypto Only)

**What**: SP filters all position and action data to InstrumentTypeID=10 before any aggregation.

**Columns Involved**: `BuyCurrency`, `Real_CFD`, `Open_Positions`, `AUA`, `PnL`, `Revenue`

**Rules**:
- `#diminstrument` = Dim_Instrument WHERE InstrumentTypeID=10 — all crypto instruments
- All downstream temp tables join to #diminstrument — non-crypto instruments are invisible
- BuyCurrency = cryptocurrency ticker symbol (BTC, ETH, XRP, SOL, ADA, DOGE, LINK, etc.)

### 2.2 Real vs CFD Crypto

**What**: Positions are segmented by settlement type — Real (token ownership) vs CFD (derivative).

**Columns Involved**: `Real_CFD`, `Active_Hold_Real`, `Active_Hold_CFD`

**Rules**:
- `Real_CFD = 'Real'`: IsSettled=1 (customer owns the crypto token)
- `Real_CFD = 'CFD'`: IsSettled=0 (price-difference contract, no token ownership)
- Active_Hold_Real and Active_Hold_CFD may overlap (one customer can hold both)
- Active_Hold ≤ Active_Hold_Real + Active_Hold_CFD due to possible overlap

### 2.3 Manual vs Copy Trading

**What**: Positions are segmented by origin — self-initiated vs copy-trading.

**Columns Involved**: `Manual_Copy`

**Rules**:
- `Manual_Copy = 'Manual'`: MirrorID=0 (customer opened position directly)
- `Manual_Copy = 'Copy'`: MirrorID≠0 (position opened through CopyPortfolio or CopyTrader)

### 2.4 AUA — Crypto Portfolio Value

**What**: Current market value (in USD) of all open crypto positions in the segment.

**Columns Involved**: `AUA`, `Amount_in_Units`

**Rules**:
- AUA = SUM(BI_DB_PositionPnL.Amount + BI_DB_PositionPnL.PositionPnL) — invested amount plus unrealized gain
- Amount_in_Units = SUM(AmountInUnitsDecimal) — position size in crypto units (e.g., BTC count)
- Source: BI_DB_PositionPnL at DateID=@dateID (daily snapshot of all open positions)
- ISNULL(..., 0) — segments without PnL data get 0 (e.g., pure-commission rows)

### 2.5 Revenue — Crypto Commission + Rollover

**What**: Total revenue eToro generates from crypto trading in the segment.

**Columns Involved**: `Revenue`

**Rules**:
- Revenue = ISNULL(FullTotalCommission, 0) + ISNULL(RollOver, 0)
- FullTotalCommission = open commissions (ActionTypeID IN 1,2,3,39) + close commissions (ActionTypeID IN 4,5,6,40) minus spread buyback
- RollOver = rollover fees (ActionTypeID=35, IsFeeDividend=1) — overnight financing cost on CFD crypto
- Revenue can be negative for sessions where rollover credits exceed commissions

### 2.6 First-Action Crypto Metrics

**What**: Identifies new crypto adopters — customers making their very first crypto trade on @date.

**Columns Involved**: `num_of_FA_Crypto`, `FA_Amount_Total`

**Rules**:
- Sourced from Fact_FirstCustomerAction WHERE ActionTypeID=1 AND FirstEver=1 AND DateID=@dateID
- `num_of_FA_Crypto`: 1 if this (CID, BuyCurrency, Real_CFD, Manual_Copy) segment had a first-action customer today; otherwise 0 or aggregated
- `FA_Amount_Total`: SUM(-Amount) — first trade invested amount (Amount is negative on opens, negated to positive)
- Used to measure daily crypto acquisition funnel

### 2.7 Active_Hold — Date-Level Scalar

**What**: Date-level total count of unique crypto holders — same on every row for a given date.

**Columns Involved**: `Active_Hold`, `Active_Hold_Real`, `Active_Hold_CFD`

**Rules**:
- Computed from BI_DB_PositionPnL at @dateID: COUNT DISTINCT CID
- Active_Hold_Real = customers holding at least one Real crypto position
- Active_Hold_CFD = customers holding at least one CFD crypto position
- These are NOT segment-level metrics — they are date totals joined to every row in the final GROUP BY. Summing Active_Hold across rows will massively over-count.
- Use `SELECT MAX(Active_Hold) WHERE DateID=X` to get the date-level total

### 2.8 Seniority Customer Lifecycle Bucket

**What**: Days since customer's first deposit, bucketed into 10 tenure groups.

**Columns Involved**: `Seniority_daily_FTD_Group`

**Rules**:
- Source: Dim_Customer.FirstDepositDate vs @date
- Buckets: 'No deposits' (1900-01-01 sentinel), '0' (same day as FTD), '1-4', '5-7', '8-14', '15-30', '31-91', '92-183', '184-365', '366-730', '731+'
- Represents customer lifecycle stage at the time of crypto activity

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + CLUSTERED INDEX on DateID — unlike the cross-selling tables (HEAP), this has a clustered index. Date-range queries are more efficient. DateID filtering benefits from index pruning.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily total crypto holders | `SELECT DateID, MAX(Active_Hold) FROM ... GROUP BY DateID` — do NOT SUM |
| AUA by crypto (latest date) | `WHERE DateID=MAX AND Real_CFD='Real' GROUP BY BuyCurrency ORDER BY SUM(AUA) DESC` |
| Revenue by regulation | `WHERE DateID=X GROUP BY Regulation ORDER BY SUM(Revenue) DESC` |
| New crypto adopters trend | `SELECT DateID, SUM(num_of_FA_Crypto), SUM(FA_Amount_Total) GROUP BY DateID` |
| Club-level crypto participation | `WHERE DateID=X GROUP BY Club, Real_CFD` |
| Seniority mix of crypto holders | `WHERE DateID=X GROUP BY Seniority_daily_FTD_Group` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Regulation | `ON cr.Regulation = r.Name` | Get RegulationID for further joins |
| DWH_dbo.Dim_Country | `ON cr.Country = dc.Name` | Country dimension enrichment |
| BI_DB_dbo.BI_DB_CryptoDashboardNew (self) | `ON a.DateID = b.DateID AND a.BuyCurrency = b.BuyCurrency` | Period-over-period comparison |

### 3.4 Gotchas

- **Active_Hold is a date-level scalar**: Do NOT SUM Active_Hold across rows. Use `MAX(Active_Hold)` per DateID.
- **PlayerLevelID<>4 exclusion**: Internal/employee accounts are excluded. Cross-checking with total customer counts will show a gap.
- **BI_DB_PositionPnL dependency**: AUA, PnL, Open_Positions, Active_Hold columns all derive from BI_DB_PositionPnL — not directly from Dim_Position. If BI_DB_PositionPnL has a gap day, these metrics will be 0 even if positions exist.
- **Revenue can be negative**: Rollover credits can exceed commission in some segments — negative Revenue is valid.
- **FA_Amount_Total is negated**: Source Amount is negative (cash outflow on open); the SP negates it for readability.
- **Opened vs Open positions**: `Opened_Positions` = count opened today; `Open_Positions` = count currently open at @date. They are not the same.
- **ROUND_ROBIN**: JOINs to other tables cause data movement. Pre-filter DateID before joining.
- **No CID column**: This table is pre-aggregated by dimension group — no individual customer-level rows. Use Dim_Position or BI_DB_PositionPnL for CID-level drill-down.

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
| 1 | Date | date | YES | Reporting date — the date @date parameter passed to SP. Always a valid calendar date. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 2 | DateID | int | NO | ETL date integer (YYYYMMDD). CONVERT(CHAR(8),@date,112). Clustered index key — most efficient filter column. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 3 | DayName | varchar(10) | YES | Day-of-week name (e.g., 'Sunday', 'Monday'). From DWH_dbo.Dim_Date. Useful for weekly pattern analysis. (Tier 2 — Dim_Date) |
| 4 | SSWeekNumberOfMonth | tinyint | YES | Week number within the current month (SS internal week numbering). From Dim_Date. (Tier 2 — Dim_Date) |
| 5 | YearWeek | int | YES | Compact year-week identifier: YEAR*100 + SSWeekNumberOfYear. Computed from SP: YEAR(@date)*100 + Dim_Date.SSWeekNumberOfYear. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 6 | DayNumberOfWeek_Sun_Start | tinyint | YES | Day number within the week, Sunday=1. From Dim_Date. (Tier 2 — Dim_Date) |
| 7 | WeekofMonth | int | YES | Compact week-of-month identifier: YEAR*10000000 + MONTH*100 + SSWeekNumberOfMonth. SP-computed from @date and Dim_Date. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 8 | IsLastDayOfMonth | char(1) | YES | 'Y' if the date is the last day of its calendar month, else 'N'. From Dim_Date. Useful for EOM-specific crypto analysis. (Tier 2 — Dim_Date) |
| 9 | Regulation | varchar(50) | YES | Short code for the regulatory authority governing the customer: FCA, CySEC, NFA, ASIC, BVI, eToroUS, etc. Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 — DWH_dbo.Dim_Regulation wiki) |
| 10 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — Dim_Country wiki) |
| 11 | BuyCurrency | varchar(50) | YES | Cryptocurrency ticker symbol for the instrument (e.g., BTC, ETH, XRP, SOL, ADA, DOGE). Sourced from Dim_Instrument.BuyCurrency for InstrumentTypeID=10. Primary crypto segmentation dimension. (Tier 2 — Dim_Instrument) |
| 12 | Real_CFD | varchar(4) | YES | Position settlement type: 'Real' (IsSettled=1 — customer holds the crypto token directly) or 'CFD' (IsSettled=0 — derivative contract). Segmentation dimension. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 13 | Manual_Copy | varchar(6) | YES | Position origin: 'Manual' (MirrorID=0 — self-initiated trade) or 'Copy' (MirrorID≠0 — opened via CopyPortfolio or CopyTrader). Segmentation dimension. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 14 | AUA | decimal(38,4) | YES | Current market value (USD) of open crypto positions in this segment: SUM(BI_DB_PositionPnL.Amount + PositionPnL). Amount is original invested USD; PositionPnL is the unrealized gain/loss. Represents Assets Under Administration for crypto. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 15 | Amount_in_Units | numeric(38,6) | YES | Total size of open crypto positions in native crypto units (e.g., BTC count). SUM(BI_DB_PositionPnL.AmountInUnitsDecimal). Complements AUA for unit-based analysis (e.g., total BTC held). (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 16 | PnL | decimal(38,4) | YES | Unrealized profit/loss (USD) on open crypto positions: SUM(BI_DB_PositionPnL.PositionPnL). Positive = gain, negative = loss relative to entry price. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 17 | Revenue | decimal(38,2) | YES | Total eToro revenue from crypto in this segment (USD): open/close commissions + rollover fees. Formula: ISNULL(FullTotalCommission,0) + ISNULL(RollOver,0). Can be negative when rollover credits exceed commissions. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 18 | num_of_FA_Crypto | int | YES | Count of customers in this segment who made their very first-ever crypto trade today (Fact_FirstCustomerAction.FirstEver=1, ActionTypeID=1, DateID=@dateID). Measures daily crypto adoption inflow. 0 for segments with no new adopters. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 19 | FA_Amount_Total | decimal(38,2) | YES | Total first-trade investment amount (USD) by new crypto adopters in this segment today. SUM(-Fact_FirstCustomerAction.Amount) — Amount is negative on opens; negated for readability. 0 if no first-action customers today. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 20 | Opened_Positions | int | YES | Count of crypto positions opened today in this segment (Dim_Position.OpenDateID=@dateID, IsPartialCloseChild=0). Represents new position flow for the day. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 21 | Open_Positions | int | YES | Count of open crypto positions at @date in this segment (from BI_DB_PositionPnL). Represents the stock of active positions, not new opens. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 22 | Active_Hold_by_Inst | int | YES | Count of distinct customers holding crypto in this specific segment (BuyCurrency × Real_CFD × Manual_Copy). Segment-scoped unique holder count — differs from the date-level Active_Hold scalars. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 23 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Propagation) |
| 24 | Active_Hold | int | YES | Date-level total count of distinct customers with ANY open crypto position at @date. Same value on every row for a given DateID. On 2026-04-12: 1,523,400. Use MAX(Active_Hold) per DateID — never SUM. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 25 | Active_Hold_Real | int | YES | Date-level total count of distinct customers holding Real crypto (IsSettled=1) at @date. Same value on every row for a given DateID. On 2026-04-12: 1,496,781. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 26 | Active_Hold_CFD | int | YES | Date-level total count of distinct customers holding CFD crypto (IsSettled≠1) at @date. Same value on every row for a given DateID. On 2026-04-12: 80,437. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |
| 27 | Club | varchar(50) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Internal (PlayerLevelID=4) is excluded from population (#pop WHERE PlayerLevelID<>4). (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki) |
| 28 | Seniority_daily_FTD_Group | varchar(50) | YES | Customer tenure bucket: days since first deposit (Dim_Customer.FirstDepositDate) vs @date. Values: 'No deposits' (sentinel), '0', '1-4', '5-7', '8-14', '15-30', '31-91', '92-183', '184-365', '366-730', '731+'. Identifies lifecycle stage. Added 2024-08-17. (Tier 2 — SP_BI_DB_CryptoDashboardNew) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| Regulation | DWH_dbo.Fact_SnapshotCustomer → Dim_Regulation | Name | JOIN via RegulationID → DWHRegulationID |
| Country | DWH_dbo.Fact_SnapshotCustomer → Dim_Country | Name | JOIN via CountryID |
| Club | DWH_dbo.Fact_SnapshotCustomer → Dim_PlayerLevel | Name | JOIN via PlayerLevelID |
| BuyCurrency | DWH_dbo.Dim_Instrument | BuyCurrency | InstrumentTypeID=10 only |
| Real_CFD | DWH_dbo.Dim_Position | IsSettled | CASE WHEN 1='Real' ELSE 'CFD' |
| Manual_Copy | DWH_dbo.Dim_Position | MirrorID | CASE WHEN 0='Manual' ELSE 'Copy' |
| AUA, PnL, Open_Positions | BI_DB_dbo.BI_DB_PositionPnL | Amount, PositionPnL, AmountInUnitsDecimal | SUM at @dateID |
| Revenue | DWH_dbo.Fact_CustomerAction | FullCommission, Amount (rollover) | ActionTypeID filters |
| num_of_FA_Crypto, FA_Amount_Total | DWH_dbo.Fact_FirstCustomerAction | FirstEver=1, ActionTypeID=1 | New adopters today |
| Opened_Positions | DWH_dbo.Dim_Position | OpenDateID=@dateID | COUNT per segment |
| Seniority_daily_FTD_Group | DWH_dbo.Dim_Customer | FirstDepositDate | DATEDIFF bucketed |
| Date dimension cols | DWH_dbo.Dim_Date | DayName, SSWeek*, DayNumber*, IsLastDayOfMonth | JOIN on DateKey |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Country + Dim_Regulation + Dim_PlayerLevel + Dim_Customer
  |-- #pop: ValidCustomer depositors, PlayerLevelID<>4, with Club + Seniority
  |
DWH_dbo.Dim_Instrument (InstrumentTypeID=10)
  |-- #diminstrument: all crypto instruments
  |
DWH_dbo.Dim_Position (crypto, open at @date)
  |-- #dimposition: open crypto positions → Real_CFD, Manual_Copy, BuyCurrency
  |
BI_DB_PositionPnL (DateID=@dateID, InstrumentTypeID=10)
  |-- #positionpnl: AUA, PnL, Amount_in_Units, Open_Positions, Active_Hold
  |
DWH_dbo.Fact_CustomerAction (DateID=@dateID, crypto ActionTypeIDs)
  |-- #Commission: open + close commissions
  |-- #rolloverfee: overnight financing
  |-- → Revenue
  |
DWH_dbo.Fact_FirstCustomerAction (FirstEver=1, crypto, DateID=@dateID)
  |-- #FA: num_of_FA_Crypto, FA_Amount_Total
  |
DWH_dbo.Dim_Date (DateKey=@dateID)
  |-- Date dimension cols
  |
JOIN all → #final → GROUP BY 8 dimensions + 3 date-scalar Active_Hold fields
  |
DELETE WHERE DateID=@dateID + INSERT all rows
  ↓
BI_DB_dbo.BI_DB_CryptoDashboardNew
```

---

## 6. Relationships

| Related Object | Relationship | Notes |
|---------------|-------------|-------|
| DWH_dbo.Fact_SnapshotCustomer | Source — population | IsValidCustomer=1, IsDepositor=1, PlayerLevelID<>4 |
| DWH_dbo.Dim_Instrument | Source — crypto scope | InstrumentTypeID=10 filter defines the universe |
| DWH_dbo.Dim_Position | Source — open positions | All crypto positions open at @date |
| BI_DB_dbo.BI_DB_PositionPnL | Source — daily PnL | AUA, PnL, Open_Positions, Active_Hold metrics |
| DWH_dbo.Fact_CustomerAction | Source — revenue | Commissions + rollover fees |
| DWH_dbo.Fact_FirstCustomerAction | Source — FA metrics | New crypto adopters |
| DWH_dbo.Dim_Customer | Source — seniority | FirstDepositDate for tenure bucketing |
| DWH_dbo.Dim_PlayerLevel | Source — club | PlayerLevelID → tier name |
| DWH_dbo.Dim_Regulation | Source — regulation | RegulationID → name |
| DWH_dbo.Dim_Country | Source — country | CountryID → name |
| DWH_dbo.Dim_Date | Source — calendar | DayName, week numbers, IsLastDayOfMonth |

---

## 7. Sample Queries

```sql
-- Daily crypto holders trend (use MAX not SUM for Active_Hold)
SELECT DateID, MAX(Active_Hold) AS holders, MAX(Active_Hold_Real) AS real_holders
FROM BI_DB_dbo.BI_DB_CryptoDashboardNew
WHERE DateID >= 20260101
GROUP BY DateID
ORDER BY DateID;

-- Top 10 cryptocurrencies by AUA (latest date, Real only)
SELECT BuyCurrency, SUM(AUA) AS total_aua, SUM(Amount_in_Units) AS total_units
FROM BI_DB_dbo.BI_DB_CryptoDashboardNew
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_CryptoDashboardNew)
  AND Real_CFD = 'Real'
GROUP BY BuyCurrency
ORDER BY total_aua DESC;

-- New crypto adopters by regulation (daily inflow)
SELECT DateID, Regulation, SUM(num_of_FA_Crypto) AS new_adopters, SUM(FA_Amount_Total) AS invested
FROM BI_DB_dbo.BI_DB_CryptoDashboardNew
WHERE DateID >= 20260101
GROUP BY DateID, Regulation
ORDER BY DateID, new_adopters DESC;

-- Revenue by club tier (BTC only, latest date)
SELECT Club, SUM(Revenue) AS revenue
FROM BI_DB_dbo.BI_DB_CryptoDashboardNew
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_CryptoDashboardNew)
  AND BuyCurrency = 'BTC'
GROUP BY Club
ORDER BY revenue DESC;
```

---

## 8. Atlassian / External References

No Confluence pages or Jira tickets found for BI_DB_CryptoDashboardNew.

---

*Wiki generated: 2026-04-23 | Quality: 8.8/10 | Pipeline: dwh-semantic-doc v2 | Batch 82*
