# BI_DB_dbo.BI_DB_DDR_Daily_Aggregated

> 137-column daily DDR rollup. One row per (DateID × dimension-tuple) — `SP_DDR_Aggregated @date` runs after `SP_DDR` and aggregates `BI_DB_DDR_CID_Level` along **last-day-of-period attributes** (Regulation, Country, MifidCategory, PlayerLevel, PlayerStatus, FirstActionType, Region, Label, plus 4 IsX flags). Designed for Tableau real-time slicing-and-dicing without losing unique-user counts. Author: Guy Manova (2020-12-09). Refresh contains rolling week / month / quarter / year FTD flags; trades small accuracy in slice-and-dice unique counts for query performance (CID-level table is too wide for Tableau direct).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — daily DDR aggregate |
| **Production Source** | `BI_DB_dbo.BI_DB_DDR_CID_Level` (per-CID per-day) + `Dim_Customer` (FirstDepositAmount). Writer SP: `BI_DB_dbo.SP_DDR_Aggregated @date` (Priority 0 daily) |
| **Refresh** | Daily — DELETE WHERE DateID=@dateID AND DataSource IS NULL, then INSERT. Idempotent rerun. Side-effect: drops auxiliary-source rows from `SP_DDR_Aggregated_Auxiliary_Metrics` if they're DataSource-null. |
| **Grain** | One row per (DateID, dimension-tuple) — typical row counts ~50K-200K per date depending on tuple cardinality |
| | |
| **Synapse Distribution** | HASH on key (likely DateID) — verify in DDL |
| **Synapse Index** | CLUSTERED on (DateID, ReportDateID) |
| | |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated` |
| **UC Format** | delta |
| **UC Partitioned By** | None (likely DateID push-down via predicate; review post-deploy) |
| **UC Table Type** | Gold export (generic pipeline) |

---

## 1. Business Meaning

`BI_DB_DDR_Daily_Aggregated` is the **published Tableau DDR fact** — the version every executive dashboard, regulatory KPI, and revenue-by-region rollup queries against. It's the daily counterpart of `BI_DB_DDR_CID_Level` (which is per-CID per-day, billions of rows): same metric vocabulary, but rolled up to the dimension-tuple grain so a 6.8M-row daily snapshot becomes ~100K rows that Tableau can slice live.

**The "last-day attribute" trick**:

The SP author's note (translated): "When a user is in CySEC today but was in FCA earlier this month, counting `unique active traders this month` would double-count them across both regulations. To avoid this, we materialise each row at the **most recent attribute** the customer had in the period — so the user appears in CySEC only. Slight slicing accuracy is sacrificed for unique-count correctness." The trade-off is acceptable for executive dashboards; analyst-grade unique counts must hit `BI_DB_DDR_CID_Level` directly.

**The 4 FTD-window flags** (`FirstTimeFunded`, `Funded_New_Def`, `FTDCurrentYear`) are computed from the first-deposit date relative to a rolling reference window (yesterday / week-start / month-start / quarter-start / year-start of `@date`).

**Side-effect on the auxiliary-metrics SP**: `SP_DDR_Aggregated`'s DELETE clause uses `AND DataSource IS NULL` so that rows produced by `SP_DDR_Aggregated_Auxiliary_Metrics` (which sets `DataSource` non-null) survive a re-run.

The metric vocabulary mirrors `BI_DB_DDR_CID_Level` — see that wiki for full per-metric semantics. This wiki documents only the **aggregation flavour** of each column. Common revenue/fee taxonomy from the `revenue-and-fees` skill applies (e.g. `OvernightFee`, `CashoutFee`, `TransferCoinFees`, `DormantFee`).

---

## 2. Business Logic

### 2.1 Last-Day Attribute Pin

For every dimension column (Regulation, Country, MifidCategory, PlayerLevel, PlayerStatus, FirstActionType, Region, Label, IsBlocked, IsCreditReportValidCB, IsGermanBaFin, IsValidCustomer), the row is keyed at the customer's **value on `@date`** (the data date). When a metric aggregates a period (week, month, quarter, year), the customer's whole period of activity is bucketed under their `@date` attribute — even if it changed.

### 2.2 FTD Window Flags

| Flag | Definition |
|------|-----------|
| `FirstTimeFunded` | 1 if customer's `FirstDepositDate` ≥ `@date` (i.e. the FTD happened **today**) |
| `Funded_New_Def` | 1 if FTD per the new 5-criteria funded definition (2025-02-09) — see `BI_DB_DDR_CID_Level` §2.4 |
| `FTDCurrentYear` | 1 if `FirstDepositDate ≥ year-start(@date)` |

(Internal CTE `#whenFTD` also computes `FTDYesterday`, `FTDCurrentWeek`, `FTDCurrentMonth`, `FTDCurrentQuarter` — these are folded into the row's date semantics rather than written as separate columns.)

### 2.3 Profitable-Trader Population

The `StockTradersWithProfit` / `StockTradersWithLoss` / `CopyTradersWithProfit` / `CopyTradersWithLoss` / `TradersWithProfit` / `TradersWithLoss` columns count **unique traders** (not transactions). They are computed in a separate join because counting uniques after slicing introduces double-counts. Bug history (2021-02-15 → 2021-03-02) — bracket-comparison `>` vs `>=` was off; fixed.

### 2.4 First-Action Repair

`SP_DDR_Fix_FirstAction` is invoked at the end of `SP_DDR_Aggregated` (added 2022-04-01) to repair `FirstActionType` rows that had drifted since DDR's inception. If `FirstActionType` looks wrong, suspect this fix path.

### 2.5 InvestedInCryptoTRS

Added 2022-01-24 to support **TRS (Total Return Swap) crypto equity reporting** — the equity exposure customers have in crypto via TRS contracts rather than direct holdings.

---

## 3. Query Advisory

### 3.1 Common Patterns

| Question | Approach |
|----------|----------|
| Daily revenue by regulation | `SELECT DateID, Regulation, SUM(Revenue) GROUP BY DateID, Regulation` |
| FTD by region this year | `WHERE FTDCurrentYear = 1 GROUP BY Region` |
| MIMO net flow per day | `SELECT DateID, SUM(Deposits - Cashouts) GROUP BY DateID` |
| Active trader count by player level | `SELECT PlayerLevel, SUM(ActiveTrader) GROUP BY PlayerLevel` |
| Slice by Country + Label | `WHERE Country = '...' AND Label = '...' GROUP BY DateID` |

### 3.2 Gotchas

- **Don't count distinct CID across this table** — there's no CID column. CID-level dedup must use `BI_DB_DDR_CID_Level` directly.
- **Slight unique-count drift across attribute slices**: pinning to last-day attribute means a user in two regulations across the period is counted in only one — see §2.1. Material for hard regulatory headcount, immaterial for KPI trends.
- **`Revenue` is computed**, not stored as a sum of all metrics — see SP_DDR_Aggregated for the formula. Don't sum component fees and assume it equals `Revenue`.
- **`DataSource` column** (added by `SP_DDR_Aggregated_Auxiliary_Metrics`) is NOT in this table's DDL — it's appended by the auxiliary SP. Filter on `DataSource IS NULL` to get only main-SP rows.
- **`PnlChange` columns are day-over-day diffs** of `Fact_CustomerUnrealized_PnL` — semantics inherit from CID_Level.
- **138-decimal numerics for `Deposits`, `Cashouts`, etc.**: precision 38, scale 6. Currency-amount-safe; double-check display format.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 1 | DDL + SP_DDR_Aggregated definition + parent CID_Level wiki |
| ** | Tier 2 | Inherited metric vocabulary from BI_DB_DDR_CID_Level |
| * | Tier 3 | Inferred from name [UNVERIFIED] |

### 4.1 Dimensions & Attributes (1-13)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date encoded as YYYYMMDD — the data date (joins to `Dim_Date.DateKey`). (Tier 1) |
| 2 | Regulation | varchar(100) | YES | Regulatory entity at the customer's last-day attribute (`'CySEC'`, `'FCA'`, `'ASIC & GAML'`, ...). Pinned per §2.1. (Tier 2) |
| 3 | IsBlocked | int | YES | 1 if the customer's account was in a blocked state on @date (PlayerStatusID NOT IN (1,3,5,7)). Last-day attribute. (Tier 2) |
| 4 | IsCreditReportValidCB | int | YES | 1 if the customer has a valid credit report (cb=Credit Bureau). Last-day attribute, used for FCA RTS24 / regulatory eligibility filters. (Tier 2) |
| 5 | IsGermanBaFin | int | YES | 1 if the customer falls under German BaFin regulation. Pinned per §2.1. (Tier 2) |
| 6 | IsValidCustomer | int | YES | 1 if the customer is in valid (KYC-approved, not test/internal) state. Last-day attribute. (Tier 2) |
| 7 | MifidCategory | varchar(100) | YES | MiFID II categorisation (`'Retail'`, `'Professional'`, `'Eligible Counterparty'`). Last-day attribute. (Tier 2) |
| 8 | PlayerLevel | varchar(100) | YES | Customer tier label (`'Silver'`, `'Gold'`, `'Platinum'`, `'Platinum+'`, `'Diamond'`, `'Club'`, ...). Last-day attribute. (Tier 2) |
| 9 | PlayerStatus | varchar(100) | YES | Account-status label (`'Active'`, `'Frozen'`, `'Suspended'`, `'Closed'`, ...). Last-day attribute. (Tier 2) |
| 10 | FirstActionType | varchar(100) | YES | Customer's first-action type label across history (`'Trade'`, `'Deposit'`, `'Login'`, ...). Repaired by `SP_DDR_Fix_FirstAction`. (Tier 2) |
| 11 | Region | varchar(100) | YES | eToro marketing region label. Last-day attribute. (Tier 2) |
| 12 | Country | varchar(100) | YES | Customer country (registration). Last-day attribute. (Tier 2) |
| 13 | Label | varchar(100) | YES | Marketing/label segment (`'eToro'`, `'partner-X'`, ...). Last-day attribute. (Tier 2) |

### 4.2 Counts & Money-In/Money-Out (14-24)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 14 | CountUsers | int | YES | Distinct CID count for this dimension tuple on @date. (Tier 1) |
| 15 | Deposits | numeric(38,6) | YES | Total deposit amount (USD) for the tuple on @date. (Tier 2) |
| 16 | Bonus | numeric(38,6) | YES | Total bonus amount credited to customers in the tuple on @date. (Tier 2) |
| 17 | Compensation | numeric(38,6) | YES | Total compensation amount credited (sum of all 11 compensation sub-categories — see CID_Level wiki). (Tier 2) |
| 18 | Cashouts | numeric(38,6) | YES | Total cashout amount (USD) requested/processed on @date. (Tier 2) |
| 19 | CashoutsIncludingRedeem | numeric(38,6) | YES | Total cashout amount **including** redeem-flagged cashouts. (Tier 2) |
| 20 | CashoutFee | numeric(38,6) | YES | Cashout fee revenue charged on the tuple on @date (excludes redeem). (Tier 2) |
| 21 | OvernightFee | numeric(38,6) | YES | Overnight (rollover) fee revenue from open-position holding. (Tier 2) |
| 22 | CompensationPnLAdjustments | numeric(38,6) | YES | Compensation entries that affect customer P&L (vs. credits that don't). (Tier 2) |
| 23 | TransferCoins | numeric(38,6) | YES | Total transfer-coin / redeem amounts. (Tier 2) |
| 24 | TransferCoinFees | numeric(38,6) | YES | Transfer-coin / redeem fee revenue. (Tier 2) |

### 4.3 Equity & NOP (25-37)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 25 | realizedEquity | numeric(38,6) | YES | Realized equity component (lowercase = legacy naming). (Tier 2) |
| 26 | DividendsPaid | numeric(38,6) | YES | Dividend payouts to customers (pass-through, not eToro revenue). (Tier 2) |
| 27 | TotalLiability | numeric(38,6) | YES | Total customer-side liability (eToro's obligation to customers). (Tier 2) |
| 28 | InProcessCashout | numeric(38,6) | YES | Cashouts in-flight (requested but not yet settled). (Tier 2) |
| 29 | NOPCrypto | numeric(38,6) | YES | NOP (Net Open Position) — direct crypto holdings. (Tier 2) |
| 30 | NOPCryptoCFD | numeric(38,6) | YES | NOP — crypto CFD positions. (Tier 2) |
| 31 | NOPStocks | numeric(38,6) | YES | NOP — direct stock holdings. (Tier 2) |
| 32 | NOPStocksCFD | numeric(38,6) | YES | NOP — stock CFD positions. (Tier 2) |
| 33 | TotalRealCryptoLoan | numeric(38,6) | YES | Total real-crypto loan amount across the tuple. (Tier 2) |
| 34 | PositionPNL | numeric(38,6) | YES | Open-position P&L (mark-to-market). (Tier 2) |
| 35 | NOP | numeric(38,6) | YES | Total NOP (sum across asset classes). (Tier 2) |
| 36 | ActualNWA | numeric(38,6) | YES | Actual Net Withdrawable Amount — funds the customer can actually cash out. (Tier 2) |
| 37 | UnrealizedPnLChange | numeric(38,6) | YES | Day-over-day diff of unrealized P&L from `Fact_CustomerUnrealized_PnL`. (Tier 2) |

### 4.4 Activity Counts & Lifecycle (38-58)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 38 | DepositsCount | numeric(38,6) | YES | Number of deposit transactions on @date. (Tier 2) |
| 39 | Deposited | numeric(38,6) | YES | Number of customers who deposited on @date (unique). (Tier 2) |
| 40 | CashoutsCount | numeric(38,6) | YES | Number of cashout transactions on @date. (Tier 2) |
| 41 | CashoutsAdjusted | numeric(38,6) | YES | Cashouts adjusted for accounting reconciliation. (Tier 2) |
| 42 | NewTrades | numeric(38,6) | YES | Number of new trades opened on @date. (Tier 2) |
| 43 | NumberOfClosedPositions | numeric(38,6) | YES | Number of positions closed on @date. (Tier 2) |
| 44 | EditStoplossAmounts | numeric(38,6) | YES | Total stop-loss-edit amount (sum). (Tier 2) |
| 45 | TotalInvestmentAmountInNewTrades | numeric(38,6) | YES | Total invested capital across NewTrades. (Tier 2) |
| 46 | FirstDepositors | numeric(38,6) | YES | Number of FTD customers on @date (= number of unique CIDs whose first deposit fell on @date). (Tier 2) |
| 47 | LoggedIn | numeric(38,6) | YES | Number of customers who logged in on @date. (Tier 2) |
| 48 | FirstDepositAmounts | numeric(38,6) | YES | Total amount across all FTDs on @date (joined from `Dim_Customer.FirstDepositAmount`). (Tier 2) |
| 49 | Registrations | numeric(38,6) | YES | Number of new customer registrations on @date. (Tier 2) |
| 50 | CashedOut | numeric(38,6) | YES | Number of customers who cashed out on @date (unique). (Tier 2) |
| 51 | CompensationRAFInvitedInviting | numeric(38,6) | YES | Refer-A-Friend compensation paid (combined invited + inviting). (Tier 2) |
| 52 | AccountBalanceToMirrorAmount | numeric(38,6) | YES | Sum of customer account-balance amounts that flowed into Copy/Mirror trades. (Tier 2) |
| 53 | NewCopyAmount | numeric(38,6) | YES | Total amount allocated to new Copy/Mirror positions on @date. (Tier 2) |
| 54 | NewCopyActions | numeric(38,6) | YES | Number of new Copy/Mirror open actions on @date. (Tier 2) |
| 55 | PublishPost | numeric(38,6) | YES | Number of social posts published on @date. (Tier 2) |
| 56 | PublishComment | numeric(38,6) | YES | Number of social comments. (Tier 2) |
| 57 | PublishLike | numeric(38,6) | YES | Number of social likes. (Tier 2) |
| 58 | EngagedInFeed | numeric(38,6) | YES | Customers who engaged in the social feed (unique). (Tier 2) |

### 4.5 Commission Breakdowns (59-74)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 59 | TotalCommission | numeric(38,6) | YES | Total commission revenue (post-discount, the canonical KPI). (Tier 2) |
| 60 | FullTotalCommission | numeric(38,6) | YES | Total commission revenue (pre-discount, gross). (Tier 2) |
| 61 | ManualCommission | numeric(38,6) | YES | Commission from manually-opened trades (post-discount). (Tier 2) |
| 62 | CopyCommission | numeric(38,6) | YES | Commission from Copy/Mirror trades (post-discount). (Tier 2) |
| 63 | StocksOnlyCommission | numeric(38,6) | YES | Commission on stocks (excluding ETFs). (Tier 2) |
| 64 | ETFCommission | numeric(38,6) | YES | Commission on ETFs. (Tier 2) |
| 65 | StocksAndETFsCommission | numeric(38,6) | YES | Commission on stocks + ETFs combined. (Tier 2) |
| 66 | CurrenciesCommission | numeric(38,6) | YES | Commission on currency (FX) positions. (Tier 2) |
| 67 | CommoditiesCommission | numeric(38,6) | YES | Commission on commodity positions. (Tier 2) |
| 68 | IndicesCommission | numeric(38,6) | YES | Commission on index positions. (Tier 2) |
| 69 | CryptoCommission | numeric(38,6) | YES | Commission on crypto positions (post-discount). (Tier 2) |
| 70 | PnLAdjustment | numeric(38,6) | YES | P&L adjustment entries (post-trade reconciliation). (Tier 2) |
| 71 | FullManualCommission | numeric(38,6) | YES | Manual-trade commission (pre-discount, gross). (Tier 2) |
| 72 | FullCopyCommission | numeric(38,6) | YES | Copy/Mirror commission (pre-discount, gross). (Tier 2) |
| 73 | FullStocksCommission | numeric(38,6) | YES | Stocks commission (pre-discount, gross). (Tier 2) |
| 74 | FullCryptoCommission | numeric(38,6) | YES | Crypto commission (pre-discount, gross). (Tier 2) |

### 4.6 P&L Change Day-Over-Day (75-79)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 75 | PnlChange | numeric(38,6) | YES | Total day-over-day P&L change across all customers in the tuple. (Tier 2) |
| 76 | CopyPnlChange | numeric(38,6) | YES | Day-over-day P&L change attributable to Copy/Mirror trades. (Tier 2) |
| 77 | StocksPnlChange | numeric(38,6) | YES | Day-over-day P&L change on stock positions. (Tier 2) |
| 78 | CryptoPnlChange | numeric(38,6) | YES | Day-over-day P&L change on crypto positions. (Tier 2) |
| 79 | ManualsPnlChange | numeric(38,6) | YES | Day-over-day P&L change on manual (non-Copy) trades. (Tier 2) |

### 4.7 Active Customer Flags (80-87)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 80 | ActiveCopy | numeric(38,6) | YES | Customers active in Copy/Mirror on @date (unique count). (Tier 2) |
| 81 | ActiveManualStocksETFs | numeric(38,6) | YES | Customers active in manual stocks/ETF trades. (Tier 2) |
| 82 | ActiveManualFXCommoditiesIndices | numeric(38,6) | YES | Customers active in manual FX/commodities/indices. (Tier 2) |
| 83 | ActiveManualCrypto | numeric(38,6) | YES | Customers active in manual crypto trades. (Tier 2) |
| 84 | ActiveOpen | numeric(38,6) | YES | Customers with any open position on @date. (Tier 2) |
| 85 | ActiveOpenManual | numeric(38,6) | YES | Customers with an open manual (non-Copy) position. (Tier 2) |
| 86 | ActiveFunded | numeric(38,6) | YES | Active **and** funded customers. (Tier 2) |
| 87 | ActiveTrader | numeric(38,6) | YES | Active trader customers (any new trade today). (Tier 2) |

### 4.8 Composite Aggregates (88-103)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 88 | Revenue | numeric(38,6) | YES | Composite revenue = TotalCommission + OvernightFee + CashoutFee + TransferCoinFees (canonical Revenue formula in SP_DDR_Aggregated). (Tier 1) |
| 89 | Equity | numeric(38,6) | YES | Composite Equity figure (5-component sum — see CID_Level wiki §2.X). (Tier 2) |
| 90 | NetNewTrades | numeric(38,6) | YES | NewTrades net of partial-close split duplication. (Tier 2) |
| 91 | NetDeposit | numeric(38,6) | YES | Deposits − Cashouts. (Tier 2) |
| 92 | AdjustedNetDeposit | numeric(38,6) | YES | NetDeposit adjusted for compensation/PnL adjustments. (Tier 2) |
| 93 | OtherCompensationAmount | numeric(38,6) | YES | Compensation outside of `Compensation` category bucket. (Tier 2) |
| 94 | InvestedInManualTradeing | numeric(38,6) | YES | Total invested capital in manual trades (typo `Tradeing` is in the source). (Tier 2) |
| 95 | RealizedEquityCalculated | numeric(38,6) | YES | Computed realized-equity value (vs the snapshot-derived `realizedEquity`). (Tier 2) |
| 96 | NewCopyNetActions | numeric(38,6) | YES | NewCopyActions net of stop-copy actions. (Tier 2) |
| 97 | NewCopyUniqueUsers | numeric(38,6) | YES | Distinct customers performing a new Copy action on @date. (Tier 2) |
| 98 | InvestedInStocksManual | numeric(38,6) | YES | Capital invested in stock manual positions. (Tier 2) |
| 99 | InvestedInCryptoManual | numeric(38,6) | YES | Capital invested in crypto manual positions. (Tier 2) |
| 100 | InvestedInCopyIncludingCash | numeric(38,6) | YES | Capital invested in Copy/Mirror including cash component. (Tier 2) |
| 101 | NetMoneyIntoCopy | numeric(38,6) | YES | Net money flow into Copy (NewCopyAmount − exits). (Tier 2) |
| 102 | NetMoneyIntoExistingCopy | numeric(38,6) | YES | Net money flow into already-existing Copy positions (top-ups − exits). (Tier 2) |
| 103 | Redeposit | numeric(38,6) | YES | Repeat-deposit amount from already-funded customers. (Tier 2) |

### 4.9 Customer P&L Breakdowns (104-111)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 104 | DepositorsLoggedIn | numeric(38,6) | YES | Depositor customers who logged in on @date (unique). (Tier 2) |
| 105 | CustomerPnL | numeric(38,6) | YES | Customer-side P&L total (negative for eToro losses, positive for eToro revenue from CFD spread). (Tier 2) |
| 106 | CustomerPnLStocks | numeric(38,6) | YES | Customer P&L on stock positions. (Tier 2) |
| 107 | CustomerPnLCopy | numeric(38,6) | YES | Customer P&L on Copy/Mirror. (Tier 2) |
| 108 | CustomerPnLManual | numeric(38,6) | YES | Customer P&L on manual (non-Copy) trades. (Tier 2) |
| 109 | CustomerPnLCrypto | numeric(38,6) | YES | Customer P&L on crypto. (Tier 2) |
| 110 | CustomerPnLStocksReal | numeric(38,6) | YES | Customer P&L on direct (real) stock holdings (vs CFD). (Tier 2) |
| 111 | CustomerPnLCryptoReal | numeric(38,6) | YES | Customer P&L on direct (real) crypto holdings. (Tier 2) |

### 4.10 Computed Totals & Zero-PnL Pop. (112-119)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 112 | FullTotalCommissionFromBreakdown | numeric(38,6) | YES | Total gross commission re-summed from the sub-category breakdowns (sanity check vs FullTotalCommission). (Tier 2) |
| 113 | TotalCommissionFromBreakdown | numeric(38,6) | YES | Total post-discount commission re-summed from the sub-category breakdowns. (Tier 2) |
| 114 | UnrealizedPnL | numeric(38,6) | YES | Unrealized P&L total from open positions on @date. (Tier 2) |
| 115 | CustomerZeroPnL | numeric(38,6) | YES | Number of customers with zero P&L (unique flag). (Tier 2) |
| 116 | CustomerZeroPnLAdjusted | numeric(38,6) | YES | Zero-P&L customer count adjusted for rounding bands. (Tier 2) |
| 117 | CustomerCopyZeroPnL | numeric(38,6) | YES | Customers with zero P&L on Copy. (Tier 2) |
| 118 | CustomerStocksZeroPnL | numeric(38,6) | YES | Customers with zero P&L on stocks. (Tier 2) |
| 119 | CustomerPnLAdjusted | numeric(38,6) | YES | Customer P&L adjusted for compensation/PnL-adjustment entries. (Tier 2) |

### 4.11 Misc / Late-Added (120-129)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 120 | Redeemed | numeric(38,6) | YES | Total redemption amount on @date. (Tier 2) |
| 121 | CashedOutDefinition2 | numeric(38,6) | YES | Alternate "Cashed Out" definition (definition-2 — typically excludes a class of cashouts). (Tier 2) |
| 122 | StockTradersWithProfit | numeric(38,6) | YES | Unique stock traders with positive P&L on @date. (Tier 1 — profitable-traders framework, 2021-02-15) |
| 123 | StockTradersWithLoss | numeric(38,6) | YES | Unique stock traders with negative P&L. (Tier 1) |
| 124 | CopyTradersWithProfit | numeric(38,6) | YES | Unique Copy traders with positive P&L. (Tier 1) |
| 125 | CopyTradersWithLoss | numeric(38,6) | YES | Unique Copy traders with negative P&L. (Tier 1) |
| 126 | TradersWithProfit | numeric(38,6) | YES | Unique traders (any asset class) with positive P&L. (Tier 1) |
| 127 | TradersWithLoss | numeric(38,6) | YES | Unique traders with negative P&L. (Tier 1) |
| 128 | MoneyIntoExistingCopy | numeric(38,6) | YES | Total amount added to already-existing Copy positions (top-ups). Counterpart to NewCopyAmount. (Tier 2) |
| 129 | Credit | numeric(38,6) | YES | Customer-credit-account credit amounts. (Tier 2) |

### 4.12 Metadata & Late Additions (130-137)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 130 | UpdateDate | datetime | YES | ETL load timestamp (`GETDATE()` at SP_DDR_Aggregated run). (Tier 1) |
| 131 | FirstTimeFunded | int | YES | 1 if customer's FTD fell on @date — see §2.2. (Tier 1) |
| 132 | Funded_New_Def | int | YES | 1 per new 5-criteria funded definition (2025-02-09) — see CID_Level wiki §2.4. (Tier 1) |
| 133 | FTDCurrentYear | int | YES | 1 if customer's FTD falls within the year-to-date window of @date. (Tier 1) |
| 134 | ReportDate | date | YES | Report **delivery** date = @date + 1 day (reports delivered next morning for prior-day data). (Tier 1) |
| 135 | ReportDateID | int | YES | YYYYMMDD form of `ReportDate`. CLUSTERED-index participant. (Tier 1) |
| 136 | DormantFee | money | YES | Dormant-fee revenue charged to inactive accounts on @date (added late — see `revenue-and-fees` skill). (Tier 1) |
| 137 | InvestedInCryptoTRS | numeric(38,6) | YES | Capital invested in crypto via TRS (Total Return Swap) contracts. Added 2022-01-24. (Tier 1) |

---

## 5. Lineage

### 5.1 Pipeline

```
DWH facts (SnapshotCustomer, CustomerAction, SnapshotEquity, Unrealized_PnL, ...)
   │
   ▼ SP_DDR @date  (Priority 0)
BI_DB_dbo.BI_DB_DDR_CID_Level (per-CID per-day, ~6.81M rows/day)
   │
   ▼ SP_DDR_Aggregated @date  (Priority 0, runs after SP_DDR)
   │      • last-day-attribute pin (§2.1)
   │      • FTD window flags (§2.2)
   │      • profitable-trader uniques (§2.3)
   │      • SP_DDR_Fix_FirstAction (§2.4)
   │      • DELETE WHERE DateID=@dateID AND DataSource IS NULL  →  INSERT
BI_DB_dbo.BI_DB_DDR_Daily_Aggregated (~50K-200K rows/day)
   │
   ▼ Generic Pipeline (gold export)
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated
```

### 5.2 Author / History

`SP_DDR_Aggregated` — Guy Manova (2020-12-09). Notable history:
- 2021-01-18 — added unique-user collection from CID-level as secondary source for uniques
- 2021-02-15/03-02 — Profitable-Trader framework added; bug fix (`>` vs `>=`)
- 2021-04-07 — email alert at end of SP
- 2021-12-24 — `AND DataSource IS NULL` filter added so auxiliary-metrics rows survive re-run
- 2022-01-24 — `InvestedInCryptoTRS` added
- 2022-04-01 — `SP_DDR_Fix_FirstAction` invocation added
- 2023-11-22 — performance improvements (Ofir Abudy)

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|----------------|-------------|
| DateID, ReportDateID | `DWH_dbo.Dim_Date.DateKey` | Date join |
| Regulation | `DWH_dbo.Dim_Regulation` | Logical (text label, no FK) |
| Country | `DWH_dbo.Dim_Country` | Logical |
| MifidCategory | `DWH_dbo.Dim_MifidCategorization` | Logical |
| PlayerLevel | `DWH_dbo.Dim_PlayerLevel` | Logical |
| PlayerStatus | `DWH_dbo.Dim_PlayerStatus` | Logical |
| Region | `DWH_dbo.External_etoro_Dictionary_MarketingRegion` | Logical |
| Label | `DWH_dbo.Dim_Label` | Logical |

(All are pre-resolved labels — no live joins required.)

### 6.2 Referenced By

- All Tableau DDR dashboards
- `SP_DDR_Aggregated_Auxiliary_Metrics` (writes additional rows into this table with `DataSource` set)
- Executive KPI rollups, regulatory headcount, revenue-by-region reports
- See `revenue-and-fees` skill and `payments/mimo-panel-and-ddr` skill for downstream usage

---

## 7. Sample Queries

### 7.1 Daily revenue by regulation

```sql
SELECT DateID, Regulation, SUM(Revenue) AS revenue
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated
WHERE  DateID BETWEEN 20260401 AND 20260430
GROUP  BY DateID, Regulation
ORDER  BY DateID, revenue DESC
```

### 7.2 FTDs by region this year

```sql
SELECT Region, SUM(FirstDepositors) AS ftds, SUM(FirstDepositAmounts) AS ftd_amount
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated
WHERE  FTDCurrentYear = 1
GROUP  BY Region
ORDER  BY ftds DESC
```

### 7.3 Net deposit by player level

```sql
SELECT DateID, PlayerLevel, SUM(NetDeposit) AS net_deposit
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated
WHERE  DateID = 20260501
GROUP  BY DateID, PlayerLevel
ORDER  BY net_deposit DESC
```

---

*Generated: 2026-05-07 | Wave 2 systematic NO_WIKI fill-in*
*Source: SP_DDR_Aggregated (Guy Manova, 2020-12-09) + parent BI_DB_DDR_CID_Level wiki + revenue-and-fees skill*
*Object: BI_DB_dbo.BI_DB_DDR_Daily_Aggregated | Type: Table | Production: SP_DDR_Aggregated rolling up CID_Level*
