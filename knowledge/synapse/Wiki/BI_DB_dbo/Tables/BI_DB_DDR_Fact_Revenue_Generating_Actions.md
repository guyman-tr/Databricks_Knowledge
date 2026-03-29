# BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions

> 3.1B-row comprehensive revenue fact table capturing 18 distinct revenue streams (spreads, rollovers, ticket fees, conversion fees, dormant fees, dividends, staking, options PFOF, and more) per customer per day, broken down by instrument type, position flags, and trade characteristics. Sourced from 16+ `Function_Revenue_*` TVFs, enriched with IBAN/recurring/CopyFund/C2P position attributes, assembled by `SP_DDR_Fact_Revenue_Generating_Actions` with daily DELETE/INSERT plus special reload strategies for Options (full history) and Staking (monthly lag).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multiple — 16+ `Function_Revenue_*` TVFs + `Dim_Revenue_Metrics` + enrichment tables |
| **Refresh** | Daily (DELETE/INSERT by DateID) + Options full reload + Staking monthly reload |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table is the **master revenue fact table** within the DDR framework. Each row represents an aggregated revenue action for a customer on a specific date, categorized by `Metric` (revenue stream type) and broken down by instrument type, settlement status, copy-trade status, and 10+ binary position flags.

It answers: "How much revenue did each customer generate today, by revenue stream and trade characteristics, and which streams count toward total reported revenue?"

**18 Revenue Streams** (via `Metric` column):

| # | Metric | Source Function | IncludedInTotalRevenue | Description |
|---|--------|----------------|----------------------|-------------|
| 1 | FullCommission | Function_Revenue_FullCommissions | Yes | Full spread commission on position open/close |
| 2 | Commission | Function_Revenue_Commissions | No | Commission sub-component (already counted in FullCommission) |
| 3 | RollOverFee | Function_Revenue_RolloverFee | Yes | Overnight rollover/swap fee on open CFD positions |
| 4 | TicketFee | Function_Revenue_TicketFee | Yes | Fixed ticket fee per trade |
| 5 | TicketFeeByPercent | Function_Revenue_TicketFeeByPercent | Yes | Percentage-based ticket fee |
| 6 | Dividends | Function_Revenue_Dividend | No | Dividend payments (cost, not revenue) |
| 7 | SDRT | Function_Revenue_SDRT | No | UK Stamp Duty Reserve Tax (pass-through, not revenue) |
| 8 | CashoutFeeExclRedeem | Function_Revenue_CashoutFee_ExcludeRedeem | Yes | Withdrawal fee excluding crypto redeems |
| 9 | ConversionFee | Function_Revenue_ConversionFee | Yes | Currency conversion fee |
| 10 | DormantFee | Function_Revenue_DormantFee | Yes | Dormant account maintenance fee |
| 11 | InterestFee | Function_Revenue_InterestFee | Yes | Interest charged on margin |
| 12 | TransferCoinFee | Function_Revenue_TransferCoinFee | Yes | Crypto withdrawal/transfer fee |
| 13 | AdminFee | Function_Revenue_AdminFee | Yes | Administrative fee on positions |
| 14 | SpotPriceAdjustment | Function_Revenue_SpotAdjustFee | Yes | Spot price adjustment fee |
| 15 | ShareLending | Function_Revenue_Share_Lending | Yes | Revenue from lending customer shares |
| 16 | CryptoToFiatFee | Function_Revenue_CryptoToFiat_C2F | Yes | Crypto-to-fiat conversion fee |
| 17 | StakingLagOneMonth | Function_Revenue_StakingFee | Yes | Crypto staking fee (lagged one month) |
| 18 | Options_PFOF | Function_Revenue_OptionsPlatform | Yes | Options payment for order flow |

The SP runs daily via Service Broker. Three insertion strategies are used:
1. **Daily DELETE/INSERT** by DateID for most metrics
2. **Full historical reload** for Options (RevenueMetricID=18) — data arrives unreliably
3. **Monthly DELETE/re-INSERT** for Staking (RevenueMetricID=12) — source data changes retroactively

---

## 2. Business Logic

### 2.1 Revenue Inclusion Flag

**What**: Controls which metrics are summed into "total revenue" reporting

**Columns Involved**: `IncludedInTotalRevenue`, `Metric`

**Rules**:
- `IncludedInTotalRevenue = 1` for revenue-generating streams (spreads, fees, staking, etc.)
- `IncludedInTotalRevenue = 0` for pass-through costs: Commission (subset of FullCommission), Dividends, SDRT
- SDRT has been explicitly forced to 0 via repeated post-INSERT UPDATEs (corrected multiple times per change history)
- Value ultimately comes from `Dim_Revenue_Metrics.IncludedInTotalRevenue` for the main INSERT

### 2.2 Active Trade Counting

**What**: Identifies rows that represent a revenue-generating trading action (not just a fee)

**Columns Involved**: `CountAsActiveTrade`, `ActionTypeID`, `IsAirDrop`

**Rules**:
- `CountAsActiveTrade = 1` only for FullCommission/Commission rows where `ActionTypeID IN (1, 39)` (Open, Close) AND `IsAirDrop = 0`
- All other metrics: `CountAsActiveTrade = 0`
- AirDrop positions are excluded from active trade counts even if they generate spread revenue

### 2.3 NULL Sentinel Convention

**What**: All boolean/dimension flags use -1 (not 0) as "not applicable" sentinel

**Columns Involved**: All flag columns (IsCopy, IsBuy, IsLeveraged, IsFuture, IsCopyFund, IsOpenedFromIBAN, IsClosedToIBAN, IsRecurring, IsAirDrop, IsSQF, IsMarginTrade, IsC2P, ActionTypeID, InstrumentTypeID, IsSettled)

**Rules**:
- `ISNULL(column, -1)` applied to all flags at INSERT time
- -1 means "not applicable to this revenue stream" (e.g., IsCopy is meaningless for DormantFee)
- 0 means "applicable but false" (e.g., IsCopy=0 for a non-copy trade's FullCommission)
- Always filter with `WHERE column != -1` or `WHERE column IN (0, 1)` to exclude non-applicable rows

### 2.4 Position-Level Enrichment

**What**: Trading-related revenues are enriched with IBAN, recurring, CopyFund, and C2P flags

**Columns Involved**: `IsOpenedFromIBAN`, `IsClosedToIBAN`, `IsRecurring`, `IsCopyFund`, `IsC2P`

**Rules**:
- `IsOpenedFromIBAN`: set via UPDATE JOIN to `External_*_opened_from_iban_parquet` by PositionID; filtered to OpenDateID <= @dateID
- `IsClosedToIBAN`: set via UPDATE JOIN to `External_*_closed_to_iban_parquet` by PositionID; filtered to CloseDateID <= @dateID and != 0
- `IsRecurring`: set via UPDATE JOIN to `External_bi_db_recurringinvestment_positions_parquet` by PositionID
- `IsCopyFund`: set via UPDATE JOIN to `BI_DB_CopyFund_Positions` by PositionID
- `IsC2P`: set via LEFT JOIN to `V_C2P_Positions` by PositionID
- Applied to overnight fees (Rollover, Dividend, SDRT, TicketFee, TicketFeeByPercent) and commission fees

### 2.5 Staking Lag Logic

**What**: Staking revenue is reported one month forward from when it was earned

**Columns Involved**: `DateID` (for Staking rows), `Metric = 'StakingLagOneMonth'`

**Rules**:
- Source: `Function_Revenue_StakingFee` called for previous month's date range
- DateID in target: `DATEADD(MONTH, 1, frcf.Date)` — shifted forward one month
- DELETE scope: current month range, RevenueMetricID=12
- Handles retroactive source data changes via monthly re-INSERT

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX. Always include `RealCID` in WHERE or JOIN conditions for optimal distribution-aligned queries. With 3.1B rows, always filter by `DateID` and ideally also by `Metric` or `RevenueMetricID`.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total revenue for a date | `WHERE DateID = @dt AND IncludedInTotalRevenue = 1` — SUM `Amount` |
| Revenue by stream | `GROUP BY Metric` — SUM `Amount` WHERE `IncludedInTotalRevenue = 1` |
| Customer revenue breakdown | `WHERE RealCID = @cid AND DateID BETWEEN @s AND @e GROUP BY Metric` |
| Active trades per day | `WHERE CountAsActiveTrade = 1 GROUP BY DateID` — SUM `CountTransactions` |
| IBAN-originated revenue | `WHERE IsOpenedFromIBAN = 1 AND IncludedInTotalRevenue = 1` |
| Copy vs manual revenue | `WHERE IsCopy IN (0, 1) GROUP BY IsCopy` — exclude -1 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_InstrumentType` | `ON r.InstrumentTypeID = dit.InstrumentTypeID` | Instrument class name (filter -1) |
| `DWH_dbo.Dim_Customer` | `ON r.RealCID = dc.RealCID` | Customer demographics |
| `BI_DB_dbo.Dim_Revenue_Metrics` | `ON r.RevenueMetricID = drm.RevenueMetricID` | Metric name, category, inclusion rules |
| `DWH_dbo.Dim_ActionType` | `ON r.ActionTypeID = dat.ActionTypeID` | Open/Close/ManualClose action names (filter -1) |

### 3.4 Gotchas

- **3.1B rows** — always filter by `DateID` and `Metric`/`RevenueMetricID`. Unfiltered scans are extremely expensive.
- **-1 sentinel, NOT 0** — all boolean flags use -1 for "not applicable". `WHERE IsCopy = 0` returns non-copy trades; `WHERE IsCopy = -1` returns metrics where copy status is undefined.
- **Commission double-counting** — FullCommission includes the full spread. Commission is a subset. Do NOT sum both for total revenue; use `IncludedInTotalRevenue = 1`.
- **SDRT is not revenue** — explicitly excluded from total revenue (`IncludedInTotalRevenue = 0`). It's a UK tax pass-through.
- **Dividends are not revenue** — `IncludedInTotalRevenue = 0`. They represent payouts to customers, not company revenue.
- **Staking is lagged** — `StakingLagOneMonth` DateID is one month AFTER the earning period. The actual staking period is the previous month.
- **Options full reload** — all Options_PFOF data (RevenueMetricID=18) is deleted and re-inserted every run across full history. Row counts may change retroactively.
- **IsSQF is NULL for some streams** — set to -1 for Dividends, SDRT; available for position-level metrics.
- **CountTransactions is NULL for ShareLending/Staking** — these are aggregated differently and don't have meaningful transaction counts.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — ...)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date key in YYYYMMDD format. DELETE/INSERT partition key. Direct from revenue functions (except Staking: lagged one month via `DATEADD(MONTH,1,...)`). (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 2 | Date | date | YES | Calendar date. `@date` SP parameter for main INSERT; computed from DateID for Staking. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 3 | RealCID | int | YES | Customer identifier. Distribution key. From revenue functions (CID renamed to RealCID for some). (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 4 | ActionTypeID | int | YES | Trading action type. From `Function_Revenue_FullCommissions/Commissions.ActionTypeID` for trading fees; `ISNULL(...,-1)` — sentinel -1 for non-trading metrics. Values: 1=Open, 39=Close. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 5 | ActionType | varchar(50) | YES | Action or revenue stream label. `Dim_ActionType.Name` for commissions; literal string for others ('Rollover', 'SDRT', 'CashoutFeeExclRedeem', etc.). (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 6 | InstrumentTypeID | int | YES | Instrument asset class. From revenue functions. `ISNULL(...,-1)` — sentinel -1 for account-level fees (CashoutFee, ConversionFee, DormantFee, InterestFee). (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 7 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 8 | IsCopy | int | YES | Copy-trade flag. `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END`; `ISNULL(...,-1)`. C2F forced to -1. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 9 | Metric | varchar(50) | YES | Revenue stream identifier. 18 distinct values: 'FullCommission', 'Commission', 'RollOverFee', 'Dividends', 'SDRT', 'TicketFee', 'TicketFeeByPercent', 'CashoutFeeExclRedeem', 'ConversionFee', 'DormantFee', 'InterestFee', 'TransferCoinFee', 'AdminFee', 'SpotPriceAdjustment', 'ShareLending', 'CryptoToFiatFee', 'StakingLagOneMonth', 'Options_PFOF'. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 10 | Amount | decimal(16,6) | YES | Revenue amount in USD. `SUM(fee_column)` aggregated per CID × Metric × flags group. Positive = revenue, negative possible for dividends paid out. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 11 | CountTransactions | int | YES | Number of transactions/positions in the group. `COUNT(RealCID)` or `SUM(CountTransactions)`; `ISNULL(...,0)`. NULL/0 for ShareLending and Staking. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 12 | IncludedInTotalRevenue | int | YES | Revenue inclusion flag. From `Dim_Revenue_Metrics.IncludedInTotalRevenue`. 1 = counts toward total revenue, 0 = excluded (Commission, Dividends, SDRT). (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 13 | CountAsActiveTrade | int | YES | Active trade indicator. `CASE WHEN ActionTypeID IN (1,39) AND ISNULL(IsAirDrop,0) = 0 THEN 1 ELSE 0 END`; `ISNULL(...,0)`. Only 1 for non-airdrop commission rows. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 14 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 15 | IsBuy | int | YES | Trade direction. `ISNULL(...,-1)`. 1=buy/long, 0=sell/short, -1=not applicable. Dividends: overridden to 1 if Amount>0, 0 if Amount<0. C2F: forced -1. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 16 | IsLeveraged | int | YES | Leverage flag. `CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`; `ISNULL(...,-1)`. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 17 | IsFuture | int | YES | Futures contract flag. From functions or `Dim_Instrument.IsFuture` (AdminFee/SpotAdjust). `ISNULL(...,-1)`. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 18 | IsCopyFund | int | YES | Smart Portfolio flag. `CASE WHEN BI_DB_CopyFund_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END`; `ISNULL(...,-1)`. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 19 | IsOpenedFromIBAN | int | YES | Position opened from eMoney IBAN flag. Set via UPDATE JOIN to `External_*_opened_from_iban_parquet`; `ISNULL(...,-1)`. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 20 | IsClosedToIBAN | int | YES | Position closed to eMoney IBAN flag. Set via UPDATE JOIN to `External_*_closed_to_iban_parquet`; `ISNULL(...,-1)`. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 21 | IsRecurring | int | YES | Recurring investment position flag. Set via UPDATE JOIN to `External_bi_db_recurringinvestment_positions_parquet`; `ISNULL(...,-1)`. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 22 | IsAirDrop | int | YES | AirDrop (free share) flag. From revenue functions; `ISNULL(...,-1)`. AirDrop positions excluded from active trade counts. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 23 | IsSQF | int | YES | Sustainable & Quality-Focused instrument flag. From functions or `Function_Instrument_Snapshot_Enriched`; `ISNULL(...,-1)`. NULL for Dividends/SDRT. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 24 | RevenueMetricID | int | YES | Revenue metric dictionary ID. From `Dim_Revenue_Metrics.RevenueMetricID` via Metric text match. 12=Staking, 18=Options. Enables ID-based filtering. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 25 | RevenueMetricCategoryID | int | YES | Revenue category ID. From `Dim_Revenue_Metrics.RevenueMetricCategoryID`. Groups metrics into categories (4=Staking, 5=Options). (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 26 | IsMarginTrade | int | YES | Margin trade flag. From revenue functions; `ISNULL(...,-1)`. Forced 0 for SDRT and Options_PFOF. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |
| 27 | IsC2P | int | YES | Copy-to-Portfolio flag. `CASE WHEN V_C2P_Positions.PositionID IS NOT NULL THEN 1 ELSE 0 END`; `ISNULL(...,-1)`. NULL for non-position metrics. (Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Metric | — | — | Literal per revenue stream |
| Amount | 16+ Function_Revenue_* | Fee columns | SUM per group |
| ActionTypeID | Function_Revenue_FullCommissions/Commissions | ActionTypeID | passthrough; -1 for non-trading |
| ActionType | Dim_ActionType / literal | Name | join-enriched or literal |
| IncludedInTotalRevenue | Dim_Revenue_Metrics | IncludedInTotalRevenue | join-enriched |
| RevenueMetricID | Dim_Revenue_Metrics | RevenueMetricID | join-enriched |
| IsCopyFund | BI_DB_CopyFund_Positions | PositionID | join-enriched |
| IsOpenedFromIBAN | External_*_opened_from_iban_parquet | PositionID | join-enriched via UPDATE |
| IsC2P | V_C2P_Positions | PositionID | join-enriched |

### 5.2 ETL Pipeline

```
16+ Function_Revenue_* TVFs (position/account/crypto/platform-level fees)
  + BI_DB_CopyFund_Positions (IsCopyFund)
  + V_C2P_Positions (IsC2P)
  + External_*_parquet (IsOpenedFromIBAN, IsClosedToIBAN, IsRecurring)
  + Dim_Position (date filtering for IBAN positions)
  + Dim_ActionType (action name resolution)
  + Dim_Instrument (IsFuture for AdminFee/SpotAdjust)
  + Dim_Revenue_Metrics (IDs + IncludedInTotalRevenue)
  |
  |-- SP_DDR_Fact_Revenue_Generating_Actions(@date):
  |     Position enrichment → overnight fees → trading fees → account fees → crypto fees
  |     UNION ALL 17 streams → #revenue
  |     Post-UNION UPDATEs (C2F/Dividend/SDRT nulls)
  |     DELETE/INSERT by DateID (JOIN Dim_Revenue_Metrics)
  |     + Options full reload (RevenueMetricID=18)
  |     + Staking monthly reload (RevenueMetricID=12)
  v
BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions (3.1B rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Sources | 16+ Function_Revenue_* | Position/account/crypto/platform-level fee calculations |
| Enrichment | CopyFund_Positions, V_C2P, External_*_parquet | Flag enrichment by PositionID |
| ETL | SP_DDR_Fact_Revenue_Generating_Actions | Multi-stream UNION, aggregation, ISNULL(-1), metric dictionary JOIN |
| Target | BI_DB_DDR_Fact_Revenue_Generating_Actions | Master revenue fact table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| InstrumentTypeID | DWH_dbo.Dim_InstrumentType | Instrument class (filter -1) |
| ActionTypeID | DWH_dbo.Dim_ActionType | Action type name (filter -1) |
| RevenueMetricID | BI_DB_dbo.Dim_Revenue_Metrics | Revenue metric dictionary |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_DDR_CID_Level | — | CID-level daily DDR aggregation |
| BI_DB_dbo.Function_DDR_Aggregation_* | — | Time-range aggregation functions |

---

## 7. Sample Queries

### 7.1 Total revenue by stream for a date

```sql
SELECT Metric,
       SUM(Amount) AS Revenue,
       SUM(CountTransactions) AS Transactions
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE DateID = 20260309
  AND IncludedInTotalRevenue = 1
GROUP BY Metric
ORDER BY Revenue DESC;
```

### 7.2 Customer revenue breakdown

```sql
SELECT Metric,
       SUM(Amount) AS Revenue
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE RealCID = 12345678
  AND DateID BETWEEN 20260301 AND 20260309
  AND IncludedInTotalRevenue = 1
GROUP BY Metric
ORDER BY Revenue DESC;
```

### 7.3 IBAN-originated vs standard revenue

```sql
SELECT CASE WHEN IsOpenedFromIBAN = 1 THEN 'IBAN' ELSE 'Standard' END AS Source,
       SUM(Amount) AS Revenue
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE DateID = 20260309
  AND IncludedInTotalRevenue = 1
  AND IsOpenedFromIBAN IN (0, 1)
GROUP BY CASE WHEN IsOpenedFromIBAN = 1 THEN 'IBAN' ELSE 'Standard' END;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 14/14*
*Tiers: 0 T1, 27 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions | Type: Table | Production Source: 16+ Function_Revenue_* TVFs + Dim_Revenue_Metrics*
