# Revenue Business Logic Skill

## Overview

This skill documents the complete revenue business logic for eToro's trading platform, derived from table/column comments and view definitions in `main.etoro_kpi` and `main.etoro_kpi_prep` schemas.

## Revenue Architecture (3 Layers)

```
Layer 1: Atomic Revenue Views (etoro_kpi_prep)
    └── 19 individual fee-type views
          │
Layer 2: Materialized Trading Revenue (etoro_kpi_prep)
    └── mv_revenue_trading — unions 8 trading components + enriches with position/instrument dims
          │
Layer 3: DDR Revenue View (etoro_kpi)
    └── vg_ddr_revenue — final reporting view with revenue metric categories
```

---

## Layer 1: Atomic Revenue Views (`main.etoro_kpi_prep`)

### Trading Revenue — Included in Total Revenue (`IncludedInTotalRevenue = 1`)

#### 1. FullCommission — `main.etoro_kpi_prep.v_revenue_fullcommission`
- **Description**: Full commission components on open and close (eToro's full spread markup including partner share).
- **Synapse Legacy**: `Function_Revenue_FullCommissions`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- **Filter**: `ActionTypeID IN (1,2,3,39)` for Opens; `ActionTypeID IN (4,5,6,28,40)` for Closes
- **Calculation**:
  - On **Open**: `TotalFullCommission = FullCommission`
  - On **Close**: `TotalFullCommission = FullCommissionOnClose - FullCommissionByUnits`
- **Key Column**: `TotalFullCommission` (DECIMAL 38,6) — the aggregatable revenue amount
- **Active Trade Logic**: `IsActiveTrade = 1` when `MirrorID > 0 AND IsAirdrop = 0`
- **Example**: `SELECT SUM(TotalFullCommission) FROM main.etoro_kpi_prep.v_revenue_fullcommission WHERE DateID = 20251231`

#### 2. TicketFeeFixed — `main.etoro_kpi_prep.v_revenue_ticketfee_fixed`
- **Description**: Fixed ticket fee per trade.
- **Synapse Legacy**: `Function_Revenue_TicketFee`
- **Source**: Multiple sources depending on time period:
  - **Before 2025-05-25**: `bi_db_fact_customer_action_position_distribution` (ActionTypeID=35, IsFeeDividend=4), Amount * -1
  - **2025-05-25 to 2026-03-08**: `bronze_historycosts_history_costs` joined with distribution table, CostSubTypeID IN (2,6), CalculationTypeID IN (3,8)
  - **After 2026-03-08**: Distribution table again, but with instrument type filters (InstrumentTypeID 5,6 settled non-margin only)
- **Key Column**: `TicketFeeFixed` (DECIMAL 38,6)
- **Example**: `SELECT SUM(TicketFeeFixed) FROM main.etoro_kpi_prep.v_revenue_ticketfee_fixed WHERE DateID = 20251231`

#### 3. TicketFeeByPercent — `main.etoro_kpi_prep.v_revenue_ticketfee_bypercent`
- **Description**: Percent-based ticket fee on notional value.
- **Synapse Legacy**: `Function_Revenue_TicketFeeByPercent`
- **Source**: Multiple sources depending on time period:
  - **Before 2026-03-08**: `bronze_historycosts_history_costs`, CostSubTypeID=4, CalculationTypeID IN (4,7). Note: before 2025-05-25 the value is set to 0.
  - **After 2026-03-08**: Distribution table, ActionTypeID=35, IsFeeDividend=4, EXCLUDING settled non-margin InstrumentTypeID 5,6
- **Key Column**: `TicketFeeByPercent` (DECIMAL 38,6)
- **Example**: `SELECT SUM(TicketFeeByPercent) FROM main.etoro_kpi_prep.v_revenue_ticketfee_bypercent WHERE DateID = 20251231`

#### 4. RolloverFee — `main.etoro_kpi_prep.v_revenue_rollover`
- **Description**: Overnight rollover fee on CFD or FX positions.
- **Synapse Legacy**: `Function_Revenue_Rollover`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- **Filter**: `ActionTypeID = 35 AND IsFeeDividend = 1`
- **Calculation**: `RolloverFee = -1 * Amount`
- **Key Column**: `RolloverFee` (DECIMAL 38,6)
- **Example**: `SELECT SUM(RolloverFee) FROM main.etoro_kpi_prep.v_revenue_rollover WHERE DateID = 20251231`

#### 5. AdminFee — `main.etoro_kpi_prep.v_revenue_adminfee`
- **Description**: Admin fee revenue from Fact_CustomerAction.
- **Synapse Legacy**: `Function_Revenue_AdminFee`
- **Source**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`
- **Filter**: `ActionTypeID = 36 AND CompensationReasonID = 117`
- **Calculation**: `AdminFee = -1 * Amount`
- **Key Column**: `AdminFee` (DECIMAL 38,6)
- **Note**: For valid-customer filtering, join with snapshot (`IsValidCustomer` not in this view — join externally)
- **Example**: `SELECT SUM(AdminFee) FROM main.etoro_kpi_prep.v_revenue_adminfee WHERE DateID = 20251231`

#### 6. SpotAdjustFee — `main.etoro_kpi_prep.v_revenue_spotadjustfee`
- **Description**: Spot price adjustment fee component.
- **Synapse Legacy**: `Function_Revenue_SpotPriceAdjustment`
- **Source**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution`
- **Filter**: `ActionTypeID = 36 AND CompensationReasonID = 118`
- **Calculation**: `SpotAdjustFee = -1 * Amount`
- **Key Column**: `SpotAdjustFee` (DECIMAL 38,6)
- **Example**: `SELECT SUM(SpotAdjustFee) FROM main.etoro_kpi_prep.v_revenue_spotadjustfee WHERE DateID = 20251231`

### Trading Revenue — NOT Included in Total Revenue (`IncludedInTotalRevenue = 0`)

#### 7. Commission — `main.etoro_kpi_prep.v_revenue_commission`
- **Description**: Trading commission (eToro's spread markup — subset of FullCommission, excludes partner share).
- **Synapse Legacy**: `Function_Revenue_Commissions`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- **Filter**: Same ActionTypeIDs as FullCommission
- **Calculation**:
  - On **Open**: `TotalCommission = Commission`
  - On **Close**: `TotalCommission = CommissionOnClose - CommissionByUnits`
- **Key Column**: `TotalCommission` (DECIMAL 38,6)
- **Note**: `IncludedInTotalRevenue = 0` — informational, NOT in top-line revenue
- **Example**: `SELECT SUM(TotalCommission) FROM main.etoro_kpi_prep.v_revenue_commission WHERE DateID = 20251231`

#### 8. Dividend — `main.etoro_kpi_prep.v_revenue_dividend`
- **Description**: Dividend-related revenue or fee lines by position and day.
- **Synapse Legacy**: `Function_Revenue_Dividend`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- **Filter**: `ActionTypeID = 35 AND IsFeeDividend = 2`
- **Calculation**: `Dividend = Amount` (no sign flip)
- **Key Column**: `Dividend` (DECIMAL 38,6)
- **Note**: `IncludedInTotalRevenue = 0` — NOT in top-line revenue
- **Example**: `SELECT SUM(Dividend) FROM main.etoro_kpi_prep.v_revenue_dividend WHERE DateID = 20251231`

### Non-Trading Revenue

#### 9. ConversionFee — `main.etoro_kpi_prep.v_revenue_conversionfee`
- **Description**: Conversion fee (FX PIP) on deposit or withdraw currency conversion vs USD.
- **Synapse Legacy**: `Function_Revenue_ConversionFee`
- **Source**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` joined with snapshot and billing tables
- **Key Column**: `ConversionFee` (DECIMAL 38,8) — the `PIPsCalculation` field
- **Dimensions**: `TransactionType` (Deposit/Withdraw), `PaymentMethod`, `Currency`, `IsIBANTrade`, `IsRecurring`
- **Example**: `SELECT TransactionType, SUM(ConversionFee) FROM main.etoro_kpi_prep.v_revenue_conversionfee WHERE DateID = 20251231 GROUP BY TransactionType`

#### 10. DormantFee — `main.etoro_kpi_prep.v_revenue_dormantfee`
- **Description**: Monthly inactivity or dormant fee for funded but inactive users.
- **Synapse Legacy**: `Function_Revenue_DormantFee`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` joined with snapshot
- **Filter**: `ActionTypeID = 36 AND CompensationReasonID = 30`
- **Calculation**: `DormantFee = -1 * Amount`
- **Key Column**: `DormantFee` (DECIMAL 13,2)
- **Example**: `SELECT SUM(DormantFee) FROM main.etoro_kpi_prep.v_revenue_dormantfee WHERE DateID = 20251231`

#### 11. InterestFee — `main.etoro_kpi_prep.v_revenue_interestfee`
- **Description**: Historical margin interest fee (largely discontinued after Jul 2023).
- **Synapse Legacy**: `Function_Revenue_InterestFee`
- **Source**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline` joined with snapshot
- **Key Column**: `InterestFee` (DECIMAL 11,2) — the `DailyFee` field
- **Example**: `SELECT SUM(InterestFee) FROM main.etoro_kpi_prep.v_revenue_interestfee WHERE DateID = 20251231`

#### 12. CashoutFee (Exclude Redeem) — `main.etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem`
- **Description**: Withdraw or cashout fee excluding crypto redeem transfer-coin path.
- **Synapse Legacy**: `Function_Revenue_CashoutFee_ExcludeRedeem`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` joined with snapshot
- **Filter**: `ActionTypeID = 30 AND COALESCE(IsRedeem, 0) = 0`
- **Key Column**: `CashoutFeeExcludeRedeem` (DECIMAL 19,4) — the `Commission` field
- **Example**: `SELECT SUM(CashoutFeeExcludeRedeem) FROM main.etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem WHERE DateID = 20251231`

#### 13. CashoutFee (Include Redeem) — `main.etoro_kpi_prep.v_revenue_cashoutfee_incredeem`
- **Description**: Withdraw fee including redeem transfer-coin treated as cashout.
- **Synapse Legacy**: `Function_Revenue_CashoutFee_IncRedeem`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` joined with snapshot
- **Filter**: `ActionTypeID = 30` (no IsRedeem filter)
- **Key Column**: `CashoutFeeIncRedeem` (DECIMAL 19,4) — the `Commission` field
- **Example**: `SELECT SUM(CashoutFeeIncRedeem) FROM main.etoro_kpi_prep.v_revenue_cashoutfee_incredeem WHERE DateID = 20251231`

#### 14. SDRT — `main.etoro_kpi_prep.v_revenue_sdrt`
- **Description**: UK SDRT (Stamp Duty Reserve Tax) style revenue lines.
- **Synapse Legacy**: `Function_Revenue_SDRT`
- **Source**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` joined with `dim_instrument`
- **Filter**: `IsFeeDividend = 5`
- **Calculation**: `SDRT = -1 * Amount`
- **Dimensions**: `InstrumentID`, `IsBuy`, `IsSettled`, `SettlementTypeID`, `IsMarginTrade` (SettlementTypeID=5), `IsCopy` (MirrorID<>0)
- **Key Column**: `SDRT` (DECIMAL 18,6)
- **Example**: `SELECT SUM(SDRT) FROM main.etoro_kpi_prep.v_revenue_sdrt WHERE DateID = 20251231`

#### 15. ShareLending — `main.etoro_kpi_prep.v_revenue_share_lending`
- **Description**: Securities lending revenue split between eToro, user, and broker.
- **Synapse Legacy**: `Function_Revenue_Share_Lending`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` joined with snapshot
- **Filter**: `ActionTypeID = 36 AND CompensationReasonID = 119`
- **Revenue Split Calculation**:
  - `ShareLendingFeeEtoroShare = Amount` (eToro's portion)
  - `ShareLendingFeeUserShare = Amount` (user's portion = same as eToro's)
  - `ShareLendingGrossAmount = Amount / 0.4` (total gross)
  - `ShareLendingFeeBrokerShare = Amount / 0.4 - 2 * Amount` (broker's portion)
- **Key Column**: `ShareLendingFeeEtoroShare` (DECIMAL 11,2) for eToro revenue
- **Example**: `SELECT SUM(ShareLendingFeeEtoroShare) FROM main.etoro_kpi_prep.v_revenue_share_lending WHERE DateID = 20251231`

#### 16. StakingFee — `main.etoro_kpi_prep.v_revenue_stakingfee`
- **Description**: Staking compensation and rev-share by customer and instrument-month.
- **Synapse Legacy**: `Function_Revenue_StakingFee`
- **Source**: `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` joined with `dim_instrument` and snapshot
- **Key Columns**:
  - `EtoroUSDDistributed` — primary eToro-side USD revenue
  - `RevShareCommission` — rev-share commission
  - `ClientPercent` / `EtoroPercent` — distribution percentages
  - `IsEligible` — customer eligibility flag
  - `IneligibleCustomerRewards` — rewards from ineligible customers (goes to eToro)
- **Example**: `SELECT SUM(EtoroUSDDistributed) FROM main.etoro_kpi_prep.v_revenue_stakingfee WHERE DateID = 20251231`

#### 17. CryptoToFiat (C2F) — `main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f`
- **Description**: Crypto-to-fiat conversion fee rows from billing or eMoney linkage.
- **Synapse Legacy**: `Function_Revenue_CryptoToFiat_C2F`
- **Source**: `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` joined with snapshot
- **Filter**: `ConversionCycle = 'Full Cycle'` only
- **Date Logic**: Uses `GREATEST(eMoneyLastStatusTime, ConversionDateTime, ConversionStatusDateTime, CryptoTransactionDateTime)` as activity date
- **Key Column**: `TotalFeeUSD` (DECIMAL 36,18) — fee in USD; `TotalFeePercentage` for rate
- **Filter Column**: `LastModificationDateID` (not `DateID`)
- **Example**: `SELECT SUM(TotalFeeUSD) FROM main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f WHERE LastModificationDateID = 20251231`

#### 18. TransferCoinFee — `main.etoro_kpi_prep.v_revenue_transfercoinfee`
- **Description**: Transfer coin or crypto transfer fee (distinct from cashout bucket in some reports).
- **Synapse Legacy**: `Function_Revenue_TransferCoinFee`
- **Source**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` joined with snapshot
- **Filter**: `ActionTypeID = 30 AND IsRedeem = 1`
- **Key Column**: `TransferCoinFee` (DECIMAL 19,4) — the `Commission` field
- **Example**: `SELECT SUM(TransferCoinFee) FROM main.etoro_kpi_prep.v_revenue_transfercoinfee WHERE DateID = 20251231`

#### 19. OptionsPlatform — `main.etoro_kpi_prep.v_revenue_optionsplatform`
- **Description**: Options platform metrics by DateID with Metric and Amount columns (wide fact).
- **Synapse Legacy**: `Function_Revenue_OptionsPlatform`
- **Source**: `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports` and `main.general.bronze_usabroker_apex_options`
- **Key Columns**: `Metric` (string), `Amount` (DECIMAL), `CountTransactions`, `IncludedInTotalRevenue`, `CountAsActiveTrade`
- **Example**: `SELECT Metric, SUM(Amount) FROM main.etoro_kpi_prep.v_revenue_optionsplatform WHERE DateID = 20251231 GROUP BY Metric`

---

## Layer 2: Materialized Trading Revenue — `main.etoro_kpi_prep.mv_revenue_trading`

- **Description**: Materialized trading revenue at instrument/day grain. Combines 8 trading components into a single unified table enriched with position and instrument dimensions.
- **Synapse Legacy**: `BI_DB_dbo.Function_Revenue_Trading_Instrument_Level`
- **Type**: MATERIALIZED_VIEW (auto-refreshed via pipeline)

### Components Unioned (BASEDATA CTE)

| Metric | Source View | IncludedInTotalRevenue |
|---|---|---|
| FullCommission | v_revenue_fullcommission | 1 |
| Commission | v_revenue_commission | 0 |
| TicketFeeFixed | v_revenue_ticketfee_fixed | 1 |
| TicketFeeByPercent | v_revenue_ticketfee_bypercent | 1 |
| RolloverFee | v_revenue_rollover | 1 |
| Dividend | v_revenue_dividend | 0 |
| AdminFee | v_revenue_adminfee | 1 |
| SpotAdjustFee | v_revenue_spotadjustfee | 1 |

### Enrichment Joins

| Join | Table | Purpose |
|---|---|---|
| dim_Position | `main.dwh.dim_Position` | Get InstrumentID, MirrorID, IsSettled, SettlementTypeID for the position |
| dim_mirror | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | Determine `IsCopyFund` (MirrorTypeID = 4) |
| IBAN Open | `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` | Flag `IsOpenFromIBAN` |
| IBAN Close | `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` | Flag `IsClosedToIBAN` |
| dim_instrument | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Get InstrumentTypeID, InstrumentType, InstrumentName, Symbol |
| SQF Group | `main.trading.bronze_etoro_trade_instrumentgroups` (GroupID=59) | Flag `IsSQF` (special qualifying flag) |

### Key Output Columns
- `IsSettled_Final = COALESCE(view.IsSettled, position.IsSettled)`
- `MirrorID_Final = COALESCE(view.MirrorID, position.MirrorID)`
- `SettlementTypeID_Final = COALESCE(view.SettlementTypeID, position.SettlementTypeID)`
- `IsCopyFund` — 1 if MirrorTypeID = 4
- `IsOpenFromIBAN`, `IsClosedToIBAN` — IBAN trade flags
- `IsSQF` — 1 if instrument is in SQF group (GroupID 59)

---

## Layer 3: DDR Revenue View — `main.etoro_kpi.vg_ddr_revenue`

- **Description**: Final revenue reporting view used for DDR (Daily Data Report) and dashboards.
- **Source Tables**:
  - `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` (main fact)
  - `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` (metric category lookup)
  - `main.bi_output.bi_ouput_v_dim_instrumenttype` (instrument type lookup)

### Key Columns

| Column | Description |
|---|---|
| `DateID` | INT — date as YYYYMMDD |
| `Date` | TIMESTAMP |
| `RealCID` | INT — customer identifier |
| `ActionTypeID` / `ActionType` | Type of revenue-generating action |
| `InstrumentTypeID` | Asset class ID |
| `InstrumentType` | Human-readable asset class (Stocks, Crypto, Indices, Currencies) |
| `IsSettled` | 1 = real ownership, 0 = CFD |
| `IsCopy` | 1 = copy-trade, 0 = manual |
| `Metric` | Revenue metric name (FullCommission, RollOverFee, Commission, TicketFeeFixed, etc.) |
| `Amount` | DECIMAL(16,6) — revenue amount in USD |
| `CountTransactions` | Number of transactions |
| `IncludedInTotalRevenue` | 1 = counts toward top-line Net Revenue, 0 = informational only |
| `CountAsActiveTrade` | 1 = qualifies user as "Active Trader" for the period |
| `RevenueMetricCategory` | Broad category: "Trading Revenue" or "Non-Trading Revenue" |
| `RevenueMetricID` / `RevenueMetricCategoryID` | FK to dim_revenue_metrics |
| `IsICC` | 1 when `IsFuture = 1` OR `InstrumentTypeID IN (1, 2, 4)` |
| `IsBuy`, `IsLeveraged`, `IsFuture`, `IsCopyFund`, `IsOpenedFromIBAN`, `IsClosedToIBAN`, `IsRecurring`, `IsAirDrop`, `IsSQF`, `IsMarginTrade`, `IsC2P` | Various trade classification flags |

---

## Key Business Rules

### Total Net Revenue
```sql
-- Total Net Revenue = sum of Amount where IncludedInTotalRevenue = 1
SELECT SUM(Amount) AS TotalNetRevenue
FROM main.etoro_kpi.vg_ddr_revenue
WHERE IncludedInTotalRevenue = 1
  AND DateID BETWEEN <start> AND <end>
```

### Revenue Metric Categories
- **Trading Revenue**: FullCommission, RolloverFee, TicketFeeFixed, TicketFeeByPercent, AdminFee, SpotAdjustFee
- **Non-Trading Revenue**: ConversionFee, DormantFee, CashoutFee, SDRT, ShareLending, StakingFee, etc.
- **Informational (NOT in Total Revenue)**: Commission (spread only), Dividend

### ActionTypeID Reference
| ActionTypeID | Meaning |
|---|---|
| 1, 2, 3, 39 | Position Opens |
| 4, 5, 6, 28, 40 | Position Closes |
| 30 | Cashout / Withdraw |
| 35 | Fee/Dividend (use IsFeeDividend to distinguish) |
| 36 | Compensation/Admin (use CompensationReasonID to distinguish) |

### IsFeeDividend Reference (for ActionTypeID = 35)
| IsFeeDividend | Revenue Type |
|---|---|
| 1 | RolloverFee |
| 2 | Dividend |
| 4 | TicketFee (Fixed or ByPercent) |
| 5 | SDRT |

### CompensationReasonID Reference (for ActionTypeID = 36)
| CompensationReasonID | Revenue Type |
|---|---|
| 30 | DormantFee |
| 117 | AdminFee |
| 118 | SpotAdjustFee |
| 119 | ShareLending |

### Settlement Types
| SettlementTypeID | Meaning |
|---|---|
| 0 | CFD |
| 1 | Real asset |
| 2 | TRS |
| 3 | CMT (crypto settled) |
| 4 | REAL_FUTURES |
| 5 | MARGIN_TRADE |

### Copy vs Manual Trade
- `IsCopy = 1` when `MirrorID > 0` (copy-trade)
- `IsCopy = 0` when `MirrorID = 0` (manual trade)
- `IsCopyFund = 1` when `MirrorTypeID = 4`

### IsSettled (Real Ownership)
- `IsSettled = 1`: Customer owns the real underlying asset
- `IsSettled = 0`: CFD (Contract for Difference)
- ETL fallback: `IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => IsSettled=1`

### Amount Sign Convention
- Most fee views apply `-1 * Amount` to make fees positive revenue
- Exceptions: Dividend uses raw Amount; FullCommission/Commission use pre-calculated fields

---

## Common Join Keys

| Key | Description | Used In |
|---|---|---|
| `RealCID` | Primary customer ID | All views |
| `GCID` | Global customer ID (cross-platform) | Non-trading views, snapshot joins |
| `DateID` | YYYYMMDD integer — **always filter on this** | All views |
| `PositionID` | Position-level identifier | Trading revenue views |
| `InstrumentID` | Financial instrument FK | mv_revenue_trading, SDRT |

### Customer Snapshot Join Pattern
Many non-trading views join to the customer snapshot for `IsValidCustomer` and `GCID`:
```sql
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON fca.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
```

---

## Performance Notes
- **Always filter on `DateID`** — it is the primary performance filter across all views
- `RealCID` is the HASH distribution key — always include in WHERE/JOIN for optimal performance
- `mv_revenue_trading` is a materialized view — prefer it over querying individual atomic views for trading revenue
- `vg_ddr_revenue` is the recommended entry point for revenue reporting queries
