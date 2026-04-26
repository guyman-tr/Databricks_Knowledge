# BI_DB_dbo.BI_DB_DDR_CID_Level

> 174-column daily CID-level reporting table — the primary DDR (Daily Dashboard Reporting) fact table. One row per customer per day, aggregating all transaction activity, financial metrics, P&L, NOP, regulatory attributes, and lifecycle flags for every active eToro customer. Driven by SP_DDR; ~6.81M rows/day across ~1563 dates (DateID 20220101–20260412). The foundational source for all DDR aggregate and time-range reporting tables.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer + Fact_CustomerAction + Fact_SnapshotEquity + Fact_CustomerUnrealized_PnL + BI_DB_Client_Balance_CID_Level_New + V_Liabilities + V_GermanBaFin + Function_Population_First_Time_Funded via SP_DDR |
| **Refresh** | Daily (SB_Daily); DELETE+INSERT per DateID — idempotent rerun |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, CID ASC) + two NONCLUSTERED indexes on (CID, DateID) and (DateID) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level` |
| **UC Format** | Delta |
| **UC Partitioned By** | N/A (generic pipeline) |
| **UC Table Type** | External (Generic Pipeline) |

---

## 1. Business Meaning

`BI_DB_DDR_CID_Level` is eToro's central daily customer-level reporting table — a 174-column, one-row-per-customer-per-day fact table that captures every reportable metric for each active customer on each trading day. It is the backbone of the DDR (Daily Dashboard Reporting) system, feeding all downstream DDR aggregate tables and executive dashboards.

Each row represents a snapshot of a single customer (`CID`) on a single day (`DateID`), combining:

- **Regulatory & segmentation attributes**: Regulation, Country, AccountType, Label, MifidCategory, PlayerLevel, PlayerStatus, Region, IsGermanBaFin, IsBlocked, IsValidCustomer
- **Lifecycle flags**: IsDepositor, FirstTimeFunded, Funded_New_Def, FTDCurrentYear, FirstDepositors, Registrations
- **Transaction metrics**: Deposits, Cashouts, Bonus, Compensation (11 sub-categories), DividendsPaid, DormantFee, Credit, TransferCoins/Fees
- **Trading activity**: NewTrades, NumberOfClosedPositions, all commission categories (17 variants), NetProfit by type (7 variants), Active* flags (8 variants), TraderWith{Profit/Loss} flags
- **Copy trading metrics**: NewCopyAmount, StopCopyAmount, NewCopyActions, NetMoneyIntoCopy, InvestedInCopyIncludingCash, NewCopyUniqueUsers
- **Social metrics**: PublishPost, PublishComment, PublishLike, EngagedInFeed
- **Balance & equity**: Equity (5-component computation), NOP + 4 breakdowns, PositionPNL, TotalLiability, InProcessCashout, StockOrders, realizedEquity
- **P&L change metrics**: PnlChange + 6 breakdowns (day-over-day Fact_CustomerUnrealized_PnL diffs), CustomerPnL + 7 breakdowns
- **Revenue**: Computed aggregate (commissions + overnight fee + cashout fee + transfer coin fees)
- **First action metadata**: FirstDepositDate, FirstActionType, PositionID, ActionTypeID, InstrumentTypeID, MirrorID

The table contains approximately **10.6 billion rows total** (6.81M distinct CIDs × 1563 distinct dates). It is loaded daily by `SP_DDR`, which takes `@date` as parameter and performs a full DELETE+INSERT for that date's DateID, making reruns idempotent.

**Downstream consumers**:
- `BI_DB_DDR_Daily_Aggregated` — GROUP BY daily totals (from the same SP_DDR run)
- `BI_DB_DDR_TimeRange_Aggregated_Country_Level` — time-windowed aggregates
- `BI_DB_DDR_CID_Level_Auxiliary_Metrics` — 24 supplementary per-CID metrics (SP_DDR_Auxiliary_Metrics reads this table)
- UC Gold layer: `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level`
- Ad-hoc analyst queries for customer-level deep dives

---

## 2. Business Logic

### 2.1 CID Universe

**What**: Every CID that appears in either `Fact_CustomerAction` or `BI_DB_Client_Balance_CID_Level_New` for the given `@date` is included.

**Rules**:
- `#allUsers` = UNION of distinct CIDs from `#fca` (Fact_CustomerAction for @date) and `#ClientBalance`
- All metrics are LEFT JOINed onto this universe — a CID with no activity on a given day can still appear if it has a client balance record
- Zero-activity rows: most metrics will be NULL or 0; Equity/NOP metrics sourced from snapshots may still be non-zero

### 2.2 DateID Conventions

**What**: Two date reference columns per row.

**Rules**:
- `DateID` — YYYYMMDD int = the data date (what day the metrics represent). Equals `@dateID = CONVERT(int, CONVERT(varchar(8), @date, 112))`
- `ReportDate` / `ReportDateID` — the date the report is *delivered* = @date + 1 day (reports are generated for yesterday's data, delivered today)
- `@datePrevID` = the previous day's DateID (used for day-over-day P&L diffs and snapshot comparisons)

### 2.3 IsBlocked Flag

**What**: Binary flag indicating a customer's account is in a blocked state.

**Rules**:
- `IsBlocked = CASE WHEN PlayerStatusID NOT IN (1,3,5,7) THEN 1 ELSE 0`
- IDs 1, 3, 5, 7 are non-blocked statuses in the DWH Dim_PlayerStatus dimension

### 2.4 FirstTimeFunded Flag (Current Definition)

**What**: Binary flag = 1 when a customer has completed all qualifying funded criteria (current 5-criteria definition as of 2025-02-09).

**Rules** (via `Function_Population_First_Time_Funded()`):
- `FTDDateID` — first deposit from Dim_Customer where IsDepositor=1 (excluding 3 bad dates: 2025-08-18/19/20 with Amount=1 and single deposit)
- `FirstVerifiedDateID` — MIN(FromDateID) where VerificationLevelID=3 from Fact_SnapshotCustomer+Dim_Range
- `FirstTradeDateID` — MIN(OpenDateID) from Dim_Position WHERE IsAirDrop=0
- `FirstIOBDateID` — MIN(Occurred) where ActionTypeID=36, CompensationReasonID=57 from Fact_CustomerAction (interest on balance)
- `FirstOptionsTradeDateID` — from Function_Revenue_OptionsPlatform()
- `FirstFundedDateID = GREATEST(FTDDateID, FirstVerifiedDateID, COALESCE(LEAST(first trade/IOB/options), first non-null of the three))`
- Customer must have FTD AND Verification AND at least one of (Trade, IOB, Options trade)
- Result: `CASE WHEN f1.RealCID IS NOT NULL THEN 1 ELSE 0`

> **Note**: The old `BI_DB_FirstTimeFunded` table read in SP_DDR is commented out (since 2025-02-09). The current FTF logic uses the TVF and has a broader definition than the 3-criteria SP_FirstTimeFunded logic.

### 2.5 Funded_New_Def Flag

**What**: Alternative "funded customer" definition used for regulatory/reporting purposes.

**Rules**:
- `Funded_New_Def = CASE WHEN Equity > 0 AND VerificationLevelID = 3 AND FirstActionType <> 'NoAction' THEN 1 ELSE 0`
- Customer must have positive equity, be KYC verified, and have performed at least one action

### 2.6 Equity Computation

**What**: Customer's total equity snapshot for @date.

**Formula**:
```
Equity = PositionPNL + InProcessCashout + PositionAmount + TotalCash + StockOrders
```
- `PositionPNL` — unrealized P&L from Fact_SnapshotEquity
- `InProcessCashout` — pending cashout amount from BI_DB_Client_Balance_CID_Level_New
- `PositionAmount` — amount invested in open positions (Fact_SnapshotEquity)
- `TotalCash` — cash balance from BI_DB_Client_Balance_CID_Level_New
- `StockOrders` — pending stock order value

### 2.7 Revenue Computation

**What**: Total revenue generated from this customer on @date.

**Formula**:
```
Revenue = FullTotalCommissionOnOpen + OvernightFee + CashoutFee + FullCommissionCloseAdjustment + TransferCoinFees
```

### 2.8 Day-Over-Day P&L Changes

**What**: `PnlChange` and 6 breakdown columns capture daily change in unrealized P&L positions.

**Rules**:
- `#customerUnrealizedNewMetrics` = Fact_CustomerUnrealized_PnL for @dateID minus Fact_CustomerUnrealized_PnL for @datePrevID
- 7 PnL change columns: total + Copy, Stocks, Crypto, Manuals, StocksReal, CryptoReal

### 2.9 ETL Idempotency

**What**: Daily refresh is safe to rerun without data duplication.

**Rules**:
- SP_DDR performs `DELETE FROM BI_DB_DDR_CID_Level WHERE DateID = @dateID` before INSERT
- This means a rerun replaces the day's data cleanly

---

## 3. Query Advisory

### 3.1 Distribution & Index

- **HASH(CID)**: All joins on `CID` across DDR tables will be co-located and fast. Avoid table scans; always filter by `DateID` first.
- **CLUSTERED INDEX (DateID, CID)**: Optimal for date-range scans. For a single customer history, add `CID` predicate after `DateID` range.
- **~10.6B total rows**: Full table scans are prohibitive. Always filter by `DateID` or a date range.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All metrics for one customer on one day | `WHERE CID = X AND DateID = YYYYMMDD` |
| Customer history over a date range | `WHERE CID = X AND DateID BETWEEN X AND Y` |
| Daily cohort by regulation | `WHERE DateID = X GROUP BY Regulation` |
| FTF rate on a given date | `WHERE DateID = X — COUNT(FirstTimeFunded=1) / COUNT(*)` |
| Revenue by country for a week | `WHERE DateID BETWEEN X AND Y GROUP BY Country, DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_DDR_CID_Level_Auxiliary_Metrics | CID = CID AND DateID = DateID | Add 24 supplementary metrics |
| DWH_dbo.Dim_Customer | CID = CID | Enrich with additional customer attributes |
| DWH_dbo.Dim_Date | DateID = DateKey | Resolve DateID to calendar attributes |

### 3.4 Gotchas

- **ReportDate ≠ DateID date**: ReportDate is DateID+1. If joining to external systems by report date, use `ReportDate` not `CONVERT(date, CAST(DateID AS varchar(8)))`.
- **Revenue is not TotalCommission**: Revenue = open commissions + overnight + cashout + transfer fees. TotalCommission only includes close-side commission. Use `FullTotalCommission` for full open+close commission.
- **NULL vs 0**: Metrics for CIDs with no activity that day may be NULL (not 0) for some columns. Use `ISNULL(col, 0)` for aggregation.
- **FirstTimeFunded is a daily snapshot flag, not an event**: It is 1 for all dates after the customer becomes FTF. It does NOT indicate the customer became FTF on that specific date.
- **FTDCurrentYear resets**: A customer who was FTD in a prior year will have `FTDCurrentYear = 0` in the current year.
- **~10.6B rows**: This table is enormous. Never run without a `DateID` predicate in a production context.
- **Old FTF logic**: The `BI_DB_FirstTimeFunded` table is no longer consumed by SP_DDR as of 2025-02-09. The FTF flag in this table uses `Function_Population_First_Time_Funded()` which has a broader 5-criteria definition.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (canonical source) |
| Tier 2 | Derived from ETL SP code analysis (SP_DDR logic) |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best-guess — limited evidence |

### 4.1 Identity & Date Columns

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | bigint | YES | Customer identifier — the universal customer key. Sourced from the UNION of Fact_CustomerAction CIDs and BI_DB_Client_Balance_CID_Level_New CIDs for @date. (Tier 2 — SP_DDR #allUsers) |
| 2 | DateID | int | YES | YYYYMMDD integer representing the data date. Computed as CONVERT(int, CONVERT(varchar(8), @date, 112)). FK to DWH_dbo.Dim_Date.DateKey. (Tier 2 — SP_DDR) |
| 169 | ReportDate | date | YES | Calendar date the report is delivered — always DateID + 1 day. DATEADD(DAY,1,@date). Reports are generated for yesterday's data, delivered today. (Tier 2 — SP_DDR) |
| 170 | ReportDateID | int | YES | YYYYMMDD int of ReportDate. CONVERT(int, CONVERT(varchar(8), DATEADD(DAY,1,@date), 112)). (Tier 2 — SP_DDR) |
| 165 | UpdateDate | datetime | YES | GETDATE() captured at SP_DDR execution time. ETL run timestamp — not a business date. (Tier 2 — SP_DDR) |

### 4.2 Customer Attribute Columns

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 3 | Regulation | varchar(100) | YES | Regulatory regime name (e.g., 'ASIC', 'FCA', 'CySEC'). Resolved from Fact_SnapshotCustomer.RegulationID via Dim_Regulation. (Tier 2 — SP_DDR #fsc2days) |
| 4 | IsBlocked | int | YES | 1 if the customer's account is in a blocked state, else 0. CASE WHEN PlayerStatusID NOT IN (1,3,5,7). (Tier 2 — SP_DDR) |
| 5 | IsCreditReportValidCB | int | YES | Flag indicating whether the customer's credit report is valid in the CB system. Passthrough from Fact_SnapshotCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 6 | IsGermanBaFin | int | YES | 1 if the customer falls under German BaFin regulatory reporting scope. Derived from V_GermanBaFin LEFT JOIN. (Tier 2 — SP_DDR) |
| 7 | IsValidCustomer | int | YES | 1 if the customer is considered valid per DWH criteria. Passthrough from Fact_SnapshotCustomer.IsValidCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 8 | AccountType | varchar(100) | YES | Account type name (e.g., 'Real', 'Demo'). Resolved via Dim_AccountType from Fact_SnapshotCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 9 | Country | varchar(100) | YES | Customer's registered country name. Resolved via Dim_Country from Fact_SnapshotCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 10 | Label | varchar(100) | YES | Customer label/tier name (e.g., 'Platinum', 'Gold'). Resolved via Dim_Label from Fact_SnapshotCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 11 | MifidCategory | varchar(100) | YES | MiFID II customer category (e.g., 'Retail', 'Professional'). Resolved via Dim_MifidCategory from Fact_SnapshotCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 12 | PlayerLevel | varchar(100) | YES | Customer experience level (e.g., 'Beginner', 'Advanced'). Resolved via Dim_PlayerLevel from Fact_SnapshotCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 13 | PlayerStatus | varchar(100) | YES | Customer account status name (e.g., 'Active', 'Blocked'). Resolved via Dim_PlayerStatus from Fact_SnapshotCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 14 | Region | varchar(100) | YES | Geographic region name (e.g., 'Europe', 'Asia Pacific'). Resolved via Dim_Region from Fact_SnapshotCustomer. (Tier 2 — SP_DDR #fsc2days) |
| 15 | IsDepositor | int | YES | 1 if the customer has ever made a deposit as of @date. Passthrough from Fact_SnapshotCustomer.IsDepositor. (Tier 2 — SP_DDR #fsc2days) |

### 4.3 Deposit & Cashout Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 16 | Deposits | numeric(38,6) | YES | Total deposit amount received from the customer on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 17 | Bonus | numeric(38,6) | YES | Total bonus amount credited to the customer on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 18 | Compensation | numeric(38,6) | YES | Total compensation amount paid to/from the customer on @date across all types. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 19 | Cashouts | numeric(38,6) | YES | Total cashout (withdrawal) amount processed for the customer on @date (excluding redemptions). SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 20 | CashoutsIncludingRedeem | numeric(38,6) | YES | Total withdrawals including redemptions on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 21 | CashoutFee | numeric(38,6) | YES | Cashout/withdrawal fee charged on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 22 | OvernightFee | numeric(38,6) | YES | Overnight (rollover) fee charged for holding CFD positions overnight on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 23 | CompensationPnLAdjustments | numeric(38,6) | YES | Compensation classified as P&L adjustment on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 24 | TransferCoins | numeric(38,6) | YES | Coin transfer amount on @date (internal eToro coin movements). SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 25 | TransferCoinFees | numeric(38,6) | YES | Fee charged on coin transfers on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 26 | realizedEquity | numeric(38,6) | YES | Realized equity movements (closed position proceeds) on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 27 | DividendsPaid | numeric(38,6) | YES | Dividend payments credited to the customer on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 44 | DepositsCount | numeric(38,6) | YES | Number of deposit transactions by the customer on @date. COUNT from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 45 | Deposited | numeric(38,6) | YES | FLAG: 1 if the customer made any deposit on @date, else 0. (Tier 2 — SP_DDR #fca) |
| 53 | CashoutsCount | numeric(38,6) | YES | Number of cashout transactions by the customer on @date. COUNT from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 58 | FirstDepositors | numeric(38,6) | YES | FLAG: 1 if this is the customer's first-ever deposit (FTD event on @date), else 0. (Tier 2 — SP_DDR #fca) |
| 61 | FirstDepositAmounts | numeric(38,6) | YES | Amount of the customer's first-ever deposit (FTD), if the FTD occurred on @date. (Tier 2 — SP_DDR #fca) |
| 63 | CashedOut | numeric(38,6) | YES | FLAG: 1 if the customer made any cashout on @date, else 0. (Tier 2 — SP_DDR #fca) |
| 64 | Redeemed | numeric(38,6) | YES | FLAG: 1 if the customer redeemed eToro coins or balance on @date. (Tier 2 — SP_DDR #fca) |
| 126 | NetDeposit | numeric(38,6) | YES | Net deposit = Deposits - Cashouts for @date. (Tier 2 — SP_DDR #CIDAgg) |
| 138 | FTDAmountEver | numeric(38,6) | YES | Customer's lifetime first time deposit amount (not necessarily on @date). SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 148 | CashoutsAdjusted | numeric(38,6) | YES | Cashout amount adjusted for reversals and redemptions. (Tier 2 — SP_DDR #fca) |
| 149 | AdjustedNetDeposit | numeric(38,6) | YES | NetDeposit adjusted for cashout reversals and redemptions. Deposits - CashoutsAdjusted. (Tier 2 — SP_DDR #CIDAgg) |
| 156 | Redeposit | numeric(38,6) | YES | FLAG or amount for subsequent deposits (non-FTD deposits). Customer already deposited before @date. (Tier 2 — SP_DDR #fca) |
| 157 | CashedOutDefinition2 | numeric(38,6) | YES | FLAG: alternative cashout definition used for specific regulatory or reporting requirements. (Tier 2 — SP_DDR #fca) |
| 171 | DormantFee | money | YES | Dormant account maintenance fee charged on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |

### 4.4 Compensation Sub-categories

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 46 | CompensationRAFInvited | numeric(38,6) | YES | RAF (Refer-a-Friend) compensation received by invited customer on @date. (Tier 2 — SP_DDR #fca) |
| 47 | CompensationRAFInviting | numeric(38,6) | YES | RAF compensation paid to the inviting customer on @date. (Tier 2 — SP_DDR #fca) |
| 48 | CompensationOther | numeric(38,6) | YES | Compensation not classified under RAF, PI, or affiliate categories on @date. (Tier 2 — SP_DDR #fca) |
| 49 | CompensationPIWithCO | numeric(38,6) | YES | Popular Investor program compensation paid with a cashout event on @date. (Tier 2 — SP_DDR #fca) |
| 50 | CompensationPINoCO | numeric(38,6) | YES | Popular Investor program compensation paid without cashout on @date. (Tier 2 — SP_DDR #fca) |
| 51 | CompensationToAffiliateWithCO | numeric(38,6) | YES | Affiliate compensation paid with a cashout event on @date. (Tier 2 — SP_DDR #fca) |
| 52 | CompensationToAffiliateNoCO | numeric(38,6) | YES | Affiliate compensation paid without cashout on @date. (Tier 2 — SP_DDR #fca) |
| 65 | CompensationRAFInvitedInviting | numeric(38,6) | YES | Combined RAF invited + inviting compensation total on @date. (Tier 2 — SP_DDR #fca) |
| 127 | OtherCompensationAmount | numeric(38,6) | YES | Misc compensation amounts not captured in standard sub-categories. (Tier 2 — SP_DDR #fca) |

### 4.5 Balance & Equity Columns

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 28 | TotalLiability | numeric(38,6) | YES | Total liability owed to the customer per V_Liabilities. LEFT JOIN from #liabilities. (Tier 2 — SP_DDR #liabilities) |
| 29 | InProcessCashout | numeric(38,6) | YES | Pending cashout amount not yet settled, from BI_DB_Client_Balance_CID_Level_New. Included in Equity computation. (Tier 2 — SP_DDR #ClientBalance) |
| 124 | Equity | numeric(38,6) | YES | Total customer equity snapshot: PositionPNL + InProcessCashout + PositionAmount + TotalCash + StockOrders. (Tier 2 — SP_DDR #CIDAgg) |
| 129 | RealizedEquityCalculated | numeric(38,6) | YES | Realized equity computed from equity movements, distinct from the raw realizedEquity passthrough. (Tier 2 — SP_DDR #CIDAgg) |
| 164 | Credit | numeric(38,6) | YES | Non-withdrawable credit balance from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR #ClientBalance) |
| 166 | FirstTimeFunded | int | YES | 1 if the customer has completed the 5-criteria FTF milestone (FTD + Verified + Trade/IOB/Options) as of @date, else 0. Sourced from Function_Population_First_Time_Funded(). (Tier 2 — SP_DDR #FTF) |
| 167 | Funded_New_Def | int | YES | 1 if Equity > 0 AND VerificationLevelID = 3 AND FirstActionType ≠ 'NoAction', else 0. Alternative funded-customer definition. (Tier 2 — SP_DDR #CIDAgg) |
| 168 | FTDCurrentYear | int | YES | 1 if the customer's first time deposit occurred in the current calendar year (YEAR(FirstDepositDate) = YEAR(@date)), else 0. (Tier 2 — SP_DDR) |

### 4.6 NOP & Position Metrics (from Fact_SnapshotEquity)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 30 | NOPCrypto | numeric(38,6) | YES | Net Open Position value in real crypto assets on @dateID snapshot. SUM from Fact_SnapshotEquity via #fse2days. (Tier 2 — SP_DDR) |
| 31 | NOPCryptoCFD | numeric(38,6) | YES | Net Open Position value in crypto CFD positions on @dateID. SUM from Fact_SnapshotEquity. (Tier 2 — SP_DDR) |
| 32 | NOPStocks | numeric(38,6) | YES | Net Open Position value in real stocks on @dateID. SUM from Fact_SnapshotEquity. (Tier 2 — SP_DDR) |
| 33 | NOPStocksCFD | numeric(38,6) | YES | Net Open Position value in CFD stock positions on @dateID. SUM from Fact_SnapshotEquity. (Tier 2 — SP_DDR) |
| 34 | TotalRealCryptoLoan | numeric(38,6) | YES | Total loan value against real crypto holdings on @dateID. SUM from Fact_SnapshotEquity. (Tier 2 — SP_DDR) |
| 35 | PositionPNL | numeric(38,6) | YES | Total unrealized P&L across all open positions on @dateID. SUM from Fact_SnapshotEquity. Component of Equity. (Tier 2 — SP_DDR) |
| 36 | NOP | numeric(38,6) | YES | Total Net Open Position value (all asset types combined) on @dateID. SUM from Fact_SnapshotEquity. (Tier 2 — SP_DDR) |
| 37 | PositionAmount | numeric(38,6) | YES | Total amount invested in open positions on @dateID. SUM from Fact_SnapshotEquity. Component of Equity. (Tier 2 — SP_DDR) |
| 38 | StockOrders | numeric(38,6) | YES | Value of pending/in-flight stock orders on @date. From BI_DB_Client_Balance_CID_Level_New. Component of Equity. (Tier 2 — SP_DDR #ClientBalance) |
| 39 | actualNWA | numeric(38,6) | YES | Net Worth Adjustment — regulatory capital adjustment on @dateID. SUM from Fact_SnapshotEquity. (Tier 2 — SP_DDR) |
| 150 | UnrealizedPnL | numeric(38,6) | YES | Total unrealized P&L snapshot for @dateID from Fact_CustomerUnrealized_PnL. (Tier 2 — SP_DDR #customerUnrealizedNewMetrics) |

### 4.7 Day-Over-Day P&L Change Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | UnrealizedPnLChange | numeric(38,6) | YES | Daily change in total unrealized P&L (@dateID minus @datePrevID) from Fact_CustomerUnrealized_PnL. (Tier 2 — SP_DDR) |
| 41 | UnrealizedPnLChangeCFD | numeric(38,6) | YES | Daily change in CFD unrealized P&L. (Tier 2 — SP_DDR) |
| 42 | UnrealizedPnLChangeCryptoReal | numeric(38,6) | YES | Daily change in real crypto unrealized P&L. (Tier 2 — SP_DDR) |
| 43 | UnrealizedPnLChangeStocksReal | numeric(38,6) | YES | Daily change in real stocks unrealized P&L. (Tier 2 — SP_DDR) |
| 100 | PnlChange | numeric(38,6) | YES | Day-over-day change in total unrealized P&L per CID (all positions). (Tier 2 — SP_DDR #customerUnrealizedNewMetrics) |
| 101 | CopyPnlChange | numeric(38,6) | YES | Day-over-day change in copy-trading unrealized P&L. (Tier 2 — SP_DDR) |
| 102 | StocksPnlChange | numeric(38,6) | YES | Day-over-day change in CFD stocks unrealized P&L. (Tier 2 — SP_DDR) |
| 103 | CryptoPnLChange | numeric(38,6) | YES | Day-over-day change in crypto unrealized P&L. (Tier 2 — SP_DDR) |
| 104 | ManualsPnlChange | numeric(38,6) | YES | Day-over-day change in manual-trading unrealized P&L. (Tier 2 — SP_DDR) |
| 105 | StocksRealPnlChange | numeric(38,6) | YES | Day-over-day change in real stocks unrealized P&L. (Tier 2 — SP_DDR) |
| 106 | CryptoRealPnlChange | numeric(38,6) | YES | Day-over-day change in real crypto unrealized P&L. (Tier 2 — SP_DDR) |

### 4.8 Commission Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 83 | TotalCommission | numeric(38,6) | YES | Total close-side spread/commission charged across all position types on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR) |
| 84 | FullTotalCommission | numeric(38,6) | YES | Full commission including both open and close sides across all position types. (Tier 2 — SP_DDR) |
| 85 | ManualCommission | numeric(38,6) | YES | Close-side commission from manually opened positions. (Tier 2 — SP_DDR) |
| 86 | CopyCommission | numeric(38,6) | YES | Commission from copy-traded positions. (Tier 2 — SP_DDR) |
| 87 | CurrenciesCommission | numeric(38,6) | YES | Commission from FX/currency positions. (Tier 2 — SP_DDR) |
| 88 | CommoditiesCommission | numeric(38,6) | YES | Commission from commodity positions. (Tier 2 — SP_DDR) |
| 89 | IndicesCommission | numeric(38,6) | YES | Commission from index CFD positions. (Tier 2 — SP_DDR) |
| 90 | StocksOnlyCommission | numeric(38,6) | YES | Commission from CFD stock positions only. (Tier 2 — SP_DDR) |
| 91 | ETFCommission | numeric(38,6) | YES | Commission from ETF positions. (Tier 2 — SP_DDR) |
| 92 | StocksAndETFsCommission | numeric(38,6) | YES | Combined commission from CFD stocks + ETFs. (Tier 2 — SP_DDR) |
| 93 | RealStocksCommission | numeric(38,6) | YES | Commission from real (non-CFD) stock trades. (Tier 2 — SP_DDR) |
| 94 | CryptoCommission | numeric(38,6) | YES | Commission from crypto positions (CFD + real). (Tier 2 — SP_DDR) |
| 95 | PnLAdjustment | numeric(38,6) | YES | P&L adjustment actions applied to the customer on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR) |
| 96 | FullManualCommission | numeric(38,6) | YES | Full open+close commission from manual positions. (Tier 2 — SP_DDR) |
| 97 | FullCopyCommission | numeric(38,6) | YES | Full open+close commission from copy positions. (Tier 2 — SP_DDR) |
| 98 | FullStocksCommission | numeric(38,6) | YES | Full commission from stocks positions (open+close). (Tier 2 — SP_DDR) |
| 99 | FullCryptoCommission | numeric(38,6) | YES | Full commission from crypto positions (open+close). (Tier 2 — SP_DDR) |
| 123 | Revenue | numeric(38,6) | YES | Total company revenue from this customer: FullTotalCommissionOnOpen + OvernightFee + CashoutFee + FullCommissionCloseAdjustment + TransferCoinFees. (Tier 2 — SP_DDR) |
| 146 | FullTotalCommissionFromBreakdown | numeric(38,6) | YES | FullTotalCommission cross-validated from position-level breakdown tables. (Tier 2 — SP_DDR) |
| 147 | TotalCommissionFromBreakdown | numeric(38,6) | YES | TotalCommission cross-validated from position-level breakdown tables. (Tier 2 — SP_DDR) |

### 4.9 Net Profit & Customer P&L Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 76 | TotalNetProfit | numeric(38,6) | YES | Total net profit from closed positions on @date across all types. (Tier 2 — SP_DDR) |
| 77 | ManualNetProfit | numeric(38,6) | YES | Net profit from manually opened positions closed on @date. (Tier 2 — SP_DDR) |
| 78 | CopyNetProfit | numeric(38,6) | YES | Net profit from copy-traded positions closed on @date. (Tier 2 — SP_DDR) |
| 79 | StocksNetProfit | numeric(38,6) | YES | Net profit from CFD stock positions closed on @date. (Tier 2 — SP_DDR) |
| 80 | StocksRealNetProfit | numeric(38,6) | YES | Net profit from real (non-CFD) stock positions closed on @date. (Tier 2 — SP_DDR) |
| 81 | CryptoNetProfit | numeric(38,6) | YES | Net profit from CFD crypto positions closed on @date. (Tier 2 — SP_DDR) |
| 82 | CryptoRealNetProfit | numeric(38,6) | YES | Net profit from real (non-CFD) crypto positions closed on @date. (Tier 2 — SP_DDR) |
| 139 | CustomerPnL | numeric(38,6) | YES | Total customer net profit from closed positions (all types). SUM from Fact_CustomerAction. (Tier 2 — SP_DDR) |
| 140 | CustomerPnLStocks | numeric(38,6) | YES | Customer net profit from stocks positions. (Tier 2 — SP_DDR) |
| 141 | CustomerPnLCopy | numeric(38,6) | YES | Customer net profit from copy-traded positions. (Tier 2 — SP_DDR) |
| 142 | CustomerPnLManual | numeric(38,6) | YES | Customer net profit from manual positions. (Tier 2 — SP_DDR) |
| 143 | CustomerPnLCrypto | numeric(38,6) | YES | Customer net profit from crypto positions. (Tier 2 — SP_DDR) |
| 144 | CustomerPnLStocksReal | numeric(38,6) | YES | Customer net profit from real stocks. (Tier 2 — SP_DDR) |
| 145 | CustomerPnLCryptoReal | numeric(38,6) | YES | Customer net profit from real crypto. (Tier 2 — SP_DDR) |
| 151 | CustomerZeroPnL | numeric(38,6) | YES | FLAG: 1 if CustomerPnL = 0 (customer broke even exactly). (Tier 2 — SP_DDR) |
| 152 | CustomerZeroPnLAdjusted | numeric(38,6) | YES | FLAG: 1 if CustomerPnLAdjusted = 0. (Tier 2 — SP_DDR) |
| 153 | CustomerCopyZeroPnL | numeric(38,6) | YES | FLAG: 1 if CustomerPnLCopy = 0. (Tier 2 — SP_DDR) |
| 154 | CustomerStocksZeroPnL | numeric(38,6) | YES | FLAG: 1 if CustomerPnLStocks = 0. (Tier 2 — SP_DDR) |
| 155 | CustomerPnLAdjusted | numeric(38,6) | YES | CustomerPnL adjusted for P&L adjustment actions. (Tier 2 — SP_DDR) |
| 158 | StockTraderWithProfit | numeric(38,6) | YES | FLAG: 1 if the customer is a stock trader with positive net profit on @date. (Tier 2 — SP_DDR) |
| 159 | StockTraderWithLoss | numeric(38,6) | YES | FLAG: 1 if the customer is a stock trader with negative net profit on @date. (Tier 2 — SP_DDR) |
| 160 | CopyTraderWithProfit | numeric(38,6) | YES | FLAG: 1 if the customer is a copy trader with positive net profit on @date. (Tier 2 — SP_DDR) |
| 161 | CopyTraderWithLoss | numeric(38,6) | YES | FLAG: 1 if the customer is a copy trader with negative net profit on @date. (Tier 2 — SP_DDR) |
| 162 | TraderWithProfit | numeric(38,6) | YES | FLAG: 1 if the customer (any type) had positive net profit on @date. (Tier 2 — SP_DDR) |
| 163 | TraderWithLoss | numeric(38,6) | YES | FLAG: 1 if the customer (any type) had negative net profit on @date. (Tier 2 — SP_DDR) |

### 4.10 Trading Activity Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 54 | NewTrades | numeric(38,6) | YES | Count of new position opens by the customer on @date. From Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 55 | NumberOfClosedPositions | numeric(38,6) | YES | Count of positions closed by the customer on @date. From Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 56 | EditStoplossAmounts | numeric(38,6) | YES | Sum of stop-loss edit amounts on @date. From Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 57 | TotalInvestmentAmountInNewTrades | numeric(38,6) | YES | Total amount invested in new positions opened on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 59 | LoggedIn | numeric(38,6) | YES | FLAG: 1 if the customer logged in on @date. From Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 60 | DepositorsLoggedIn | numeric(38,6) | YES | FLAG: 1 if the customer is a depositor who also logged in on @date. (Tier 2 — SP_DDR #fca) |
| 62 | Registrations | numeric(38,6) | YES | FLAG: 1 if the customer registered on @date (new registration event). (Tier 2 — SP_DDR #fca) |
| 75 | EngagedInFeed | numeric(38,6) | YES | FLAG: 1 if the customer had any social news feed engagement (post, comment, like) on @date. (Tier 2 — SP_DDR #fca) |
| 107 | ActiveCopy | numeric(38,6) | YES | FLAG: 1 if the customer had active copy relationships on @date. (Tier 2 — SP_DDR #tradersActive) |
| 108 | ActiveManualStocksETFs | numeric(38,6) | YES | FLAG: 1 if the customer had open manual stocks/ETF positions on @date. (Tier 2 — SP_DDR #tradersActive) |
| 109 | ActiveManualFXCommoditiesIndices | numeric(38,6) | YES | FLAG: 1 if the customer had open manual FX, commodities, or indices positions on @date. (Tier 2 — SP_DDR #tradersActive) |
| 110 | ActiveManualCrypto | numeric(38,6) | YES | FLAG: 1 if the customer had open manual crypto positions on @date. (Tier 2 — SP_DDR #tradersActive) |
| 111 | ActiveOpen | numeric(38,6) | YES | FLAG: 1 if the customer had any open position (manual or copy) on @date. (Tier 2 — SP_DDR #tradersActive) |
| 112 | ActiveOpenManual | numeric(38,6) | YES | FLAG: 1 if the customer had any open manual position on @date. (Tier 2 — SP_DDR #tradersActive) |
| 113 | ActiveFunded | numeric(38,6) | YES | FLAG: 1 if the customer had positive account balance on @date. (Tier 2 — SP_DDR #tradersActive) |
| 114 | ActiveTrader | numeric(38,6) | YES | FLAG: 1 if the customer opened or closed any position on @date. (Tier 2 — SP_DDR #tradersActive) |
| 125 | NetNewTrades | numeric(38,6) | YES | Net trades = NewTrades - NumberOfClosedPositions on @date. (Tier 2 — SP_DDR #CIDAgg) |
| 128 | InvestedInManualTradeing | numeric(38,6) | YES | Amount invested in manually opened trades on @date (note: column name has typo "Tradeing"). (Tier 2 — SP_DDR #fca) |
| 131 | InvestedInStocksManual | numeric(38,6) | YES | Amount invested in manual stocks positions on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 132 | InvestedInCryptoManual | numeric(38,6) | YES | Amount invested in manual crypto positions on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 172 | InvestedInCryptoTRS | numeric(38,6) | YES | Amount invested in crypto TRS (Total Return Swap) positions on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |

### 4.11 Copy Trading Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 66 | AccountBalanceToMirrorAmount | numeric(38,6) | YES | Amount moved from account balance into a copy (mirror) relationship on @date. (Tier 2 — SP_DDR #fca) |
| 67 | MirrorAmountToAccountBalance | numeric(38,6) | YES | Amount returned from a copy relationship back to account balance on @date. (Tier 2 — SP_DDR #fca) |
| 68 | NewCopyAmount | numeric(38,6) | YES | Total capital allocated to new copy relationships started on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 69 | StopCopyAmount | numeric(38,6) | YES | Total capital withdrawn from copy relationships stopped on @date. SUM from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 70 | NewCopyActions | numeric(38,6) | YES | Count of new copy relationships initiated on @date. COUNT from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 71 | StopCopyActions | numeric(38,6) | YES | Count of copy relationships terminated on @date. COUNT from Fact_CustomerAction. (Tier 2 — SP_DDR #fca) |
| 130 | NewCopyNetActions | numeric(38,6) | YES | Net copy actions = NewCopyActions - StopCopyActions on @date. (Tier 2 — SP_DDR #CIDAgg) |
| 133 | InvestedInCopyIncludingCash | numeric(38,6) | YES | Total amount allocated to copy trading including idle cash held in copy portfolios. (Tier 2 — SP_DDR #fca) |
| 134 | NewCopyUniqueUsers | numeric(38,6) | YES | Count of distinct popular investors this customer started copying on @date. (Tier 2 — SP_DDR #fca) |
| 135 | NetMoneyIntoExistingCopy | numeric(38,6) | YES | Net money added to or removed from already-existing copy relationships on @date. (Tier 2 — SP_DDR #fca) |
| 136 | MoneyIntoExistingCopy | numeric(38,6) | YES | Gross money added to existing copy relationships on @date. (Tier 2 — SP_DDR #fca) |
| 137 | NetMoneyIntoCopy | numeric(38,6) | YES | Net total money flow into all copy relationships (new + existing) on @date. (Tier 2 — SP_DDR #fca) |

### 4.12 Social Feed Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 72 | PublishPost | numeric(38,6) | YES | Count of news feed posts published by the customer on @date. (Tier 2 — SP_DDR #fca) |
| 73 | PublishComment | numeric(38,6) | YES | Count of comments published by the customer on @date. (Tier 2 — SP_DDR #fca) |
| 74 | PublishLike | numeric(38,6) | YES | Count of likes given by the customer on @date. (Tier 2 — SP_DDR #fca) |

### 4.13 First Action Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 115 | FirstDepositDate | date | YES | Calendar date of the customer's first-ever deposit. From #FirstActionsFinal. (Tier 2 — SP_DDR) |
| 116 | FirstDepositDateID | numeric(38,6) | YES | YYYYMMDD int of the customer's first-ever deposit date. From #FirstActionsFinal. (Tier 2 — SP_DDR) |
| 117 | PositionID | bigint | YES | Position ID of the customer's first trade action. From #FirstActionsFinal. (Tier 2 — SP_DDR) |
| 118 | ActionTypeID | numeric(38,6) | YES | ActionTypeID of the customer's first ever recorded action. From #FirstActionsFinal. (Tier 2 — SP_DDR) |
| 119 | FirstActionDateID | numeric(38,6) | YES | YYYYMMDD int of the customer's first-ever action date. From #FirstActionsFinal. (Tier 2 — SP_DDR) |
| 120 | InstrumentTypeID | numeric(38,6) | YES | InstrumentTypeID of the customer's first position (NULL if first action was not a trade). From #FirstActionsFinal. (Tier 2 — SP_DDR) |
| 121 | MirrorID | numeric(38,6) | YES | MirrorID of the customer's first copy relationship (NULL if first action was manual). From #FirstActionsFinal. (Tier 2 — SP_DDR) |
| 122 | FirstActionType | varchar(100) | YES | Label for the customer's first-ever action type: 'Copy', 'Manual', 'NoAction', etc. From #FirstActionsFinal. (Tier 2 — SP_DDR) |

---

## 5. Lineage

See `BI_DB_DDR_CID_Level.lineage.md` for full column-level source mapping.

### 5.1 Production Sources (Summary)

| Synapse Column Group | Primary Source | Transform |
|---------------------|----------------|-----------|
| CID, DateID, ReportDate/ID, UpdateDate | SP_DDR parameters | Computed from @date parameter |
| Regulation, IsBlocked, IsValidCustomer, IsCreditReportValidCB, IsDepositor, AccountType, Country, Label, MifidCategory, PlayerLevel, PlayerStatus, Region | Fact_SnapshotCustomer + Dim tables | Snapshot for @dateID; dim names resolved |
| IsGermanBaFin | V_GermanBaFin | LEFT JOIN |
| All deposit/cashout/bonus/compensation/fee metrics | Fact_CustomerAction | SUM/COUNT aggregations for @date |
| All commission metrics | Fact_CustomerAction | SUM by instrument/type |
| All net profit metrics | Fact_CustomerAction | SUM by instrument/type |
| All active/flag metrics | Fact_CustomerAction | FLAG aggregations |
| First action metadata | Fact_CustomerAction via #FirstActionsFinal | MIN/first row per CID |
| Copy trading metrics | Fact_CustomerAction | SUM/COUNT for copy ActionTypeIDs |
| PnL change metrics | Fact_CustomerUnrealized_PnL | @dateID diff vs @datePrevID |
| NOP/PositionPNL/PositionAmount metrics | Fact_SnapshotEquity | SUM snapshot for @dateID |
| InProcessCashout, Credit, StockOrders, TotalCash | BI_DB_Client_Balance_CID_Level_New | Passthrough from #ClientBalance |
| TotalLiability | V_Liabilities | LEFT JOIN per CID |
| FirstTimeFunded | Function_Population_First_Time_Funded() | 5-criteria FTF TVF result |
| Equity | Multiple (PositionPNL + InProcessCashout + PositionAmount + TotalCash + StockOrders) | Computed in #CIDAgg |
| Revenue | Multiple (commission + overnight + cashout + transfer fees) | Computed in #CIDAgg |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_* ─→ #fsc2days ─────────────────────────────────┐
DWH_dbo.Fact_CustomerAction ─────────→ #fca ────────────────────────────────────────┤
                                      → #FirstActionsFinal ────────────────────────┤
                                      → #tradersActive ────────────────────────────┤
DWH_dbo.Fact_CustomerUnrealized_PnL ─→ #customerUnrealizedNewMetrics ──────────────┤
DWH_dbo.V_Liabilities ───────────────→ #liabilities ──────────────────────────────→ #CIDAgg (174 cols)
DWH_dbo.Fact_SnapshotEquity ─────────→ #fse2days ─────────────────────────────────┤
BI_DB_Client_Balance_CID_Level_New ──→ #ClientBalance ─────────────────────────────┤
Function_Population_First_Time_Funded→ #FTF ──────────────────────────────────────┤
DWH_dbo.V_GermanBaFin ───────────────→ #GermanBaFin ──────────────────────────────┘

#fca ∪ #ClientBalance → #allUsers (CID universe for @date)
#allUsers LEFT JOIN all temp tables → #CIDAgg

DELETE FROM BI_DB_DDR_CID_Level WHERE DateID = @dateID
INSERT INTO BI_DB_DDR_CID_Level SELECT * FROM #CIDAgg

↓ (downstream, same SP_DDR run)
GROUP BY → BI_DB_DDR_Daily_Aggregated

↓ (separate SP)
SP_DDR_Auxiliary_Metrics reads BI_DB_DDR_CID_Level → BI_DB_DDR_CID_Level_Auxiliary_Metrics
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DateID | DWH_dbo.Dim_Date.DateKey | Date dimension lookup |
| CID | DWH_dbo.Dim_Customer.CID | Customer master |

### 6.2 Referenced By (other objects point to this)

| Object | Reference Type | Description |
|--------|---------------|-------------|
| BI_DB_dbo.BI_DB_DDR_Daily_Aggregated | Source data (via SP_DDR GROUP BY) | Daily aggregated totals |
| BI_DB_dbo.BI_DB_DDR_TimeRange_Aggregated_Country_Level | Aggregate source | Time-range country aggregations |
| BI_DB_dbo.BI_DB_DDR_CID_Level_Auxiliary_Metrics | Source (SP_DDR_Auxiliary_Metrics reads this) | 24 supplementary metrics |
| bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_cid_level | UC Gold target | Generic pipeline replication |

---

## 7. Sample Queries

### All metrics for a specific customer on a specific day

```sql
SELECT *
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level]
WHERE CID = 123456
  AND DateID = 20260101
```

### Daily FTF conversions count

```sql
SELECT DateID, COUNT(*) AS FTF_Count
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level]
WHERE DateID BETWEEN 20260101 AND 20260331
  AND FirstTimeFunded = 1
GROUP BY DateID
ORDER BY DateID
```

### Revenue by regulation for a date range

```sql
SELECT DateID, Regulation, SUM(Revenue) AS TotalRevenue
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level]
WHERE DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID, Regulation
ORDER BY DateID, TotalRevenue DESC
```

### Equity snapshot by country on a given date

```sql
SELECT Country, SUM(Equity) AS TotalEquity, COUNT(*) AS CustomerCount
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level]
WHERE DateID = 20260410
GROUP BY Country
ORDER BY TotalEquity DESC
```

### Funded customer funnel metrics for a date

```sql
SELECT
    DateID,
    COUNT(*)                              AS TotalCustomers,
    SUM(IsDepositor)                      AS Depositors,
    SUM(FirstTimeFunded)                  AS FirstTimeFunded,
    SUM(Funded_New_Def)                   AS FundedNewDef,
    SUM(FirstDepositors)                  AS NewFTDs,
    SUM(ISNULL(Revenue, 0))               AS TotalRevenue
FROM [BI_DB_dbo].[BI_DB_DDR_CID_Level]
WHERE DateID = 20260410
GROUP BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources were accessible during Phase 10 (MCP not available). SP_DDR code contains header comments indicating active maintenance by the BI team. The FTF logic change (2025-02-09) replacing BI_DB_FirstTimeFunded with Function_Population_First_Time_Funded() is documented in SP_DDR inline comments.

---

*Generated: 2026-04-21 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 0 T1, 174 T2, 0 T3, 0 T4 | Elements: 174/174, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_DDR_CID_Level | Type: Table | Production Source: SP_DDR via Fact_SnapshotCustomer + Fact_CustomerAction + Fact_SnapshotEquity + Fact_CustomerUnrealized_PnL + BI_DB_Client_Balance_CID_Level_New*
