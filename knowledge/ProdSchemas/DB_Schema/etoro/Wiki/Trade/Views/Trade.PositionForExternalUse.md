# Trade.PositionForExternalUse

> External-facing open positions view that wraps Trade.Position with DLT awareness, nullifying internal-only columns and adding blockchain-settlement and commission-version indicators.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.Position) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.PositionForExternalUse is an **external API / consumer-facing view** over open trading positions. It wraps the Trade.Position view (which itself joins PositionTbl + PositionTreeInfo for open positions only) and applies two transformations: (1) it **nullifies internal-only columns** that external consumers should not see or do not need, and (2) it **adds DLT (Distributed Ledger Technology) awareness** by LEFT JOINing to Trade.PositionOpenInDLT to flag positions that were opened on the blockchain.

This view exists because eToro exposes position data to external systems (billing, account statements, back-office reporting, NWA calculations) that require a stable column contract without internal hedge management details, spread group internals, overnight fee claim dates, or corporate-action adjustment columns. Rather than having each consumer individually filter out internal columns, this view provides a single sanitized interface. It also decouples external consumers from schema changes to internal columns - if a new internal column is added to Trade.Position, external consumers are unaffected.

Data flows through this view read-only. Trade.Position (filtered to StatusID=1 open positions) provides the base data. The LEFT JOIN to Trade.PositionOpenInDLT adds blockchain membership. Key consumers include BackOffice procedures (GetCustomerOpenPositions, GetRedeemsInfo), Billing procedures (GetPositionNetProfit, GetRedeemRecords), account statement procedures, and the Trade.PosionByRowVersion view which adds row-version change tracking on top.

---

## 2. Business Logic

### 2.1 Internal Column Nullification

**What**: Sensitive or internal-only columns are hardcoded to NULL (or zero) to prevent external exposure.

**Columns/Parameters Involved**: `ForexResultID`, `GameServerID`, `HedgeID`, `CloseOnEndOfWeek`, `AdditionalParam`, `ClamedOnDay`, `SpreadGroupID`, `LotCountGroupID`, `OrderPriceRateID`, `OrderPriceRate`, `EntryHedgeQuery`, `DirectAggLotCount`, `StocksOrderID`, `LastEOWClameDate`, `OpenExposureID`, all `*UnAdjusted` columns, `LastOverNightClameDate`, `SLManualVer`, `NextThresHold`

**Rules**:
- These columns exist in the SELECT list (maintaining column-position compatibility with Trade.Position) but always return NULL or a fixed value
- CloseOnEndOfWeek is hardcoded to 0 (false) rather than NULL - external systems should not see weekend-close flag
- HedgeID is cast to INT (from BIGINT in Position) and set to NULL - hedge linkage is internal
- The view preserves column ordinal positions so consumers using ordinal-based binding are not broken

### 2.2 DLT Open Detection

**What**: Computed flag indicating whether a position was opened on the blockchain (Distributed Ledger Technology).

**Columns/Parameters Involved**: `DLTOpen`, `HedgeServerID`, `PositionOpenInDLT.PositionID`, `Occurred`, `OpenMarkup`

**Rules**:
- DLTOpen = 1 when ALL of: (a) HedgeServerID = 86 (DLT hedge server) OR position exists in Trade.PositionOpenInDLT, AND (b) position Occurred between 2024-09-24 and 2025-10-30, AND (c) OpenMarkup IS NOT NULL
- The date range represents the DLT feature window; positions outside this range are not considered DLT even if on hedge server 86
- Code comment indicates the end date is TBD ("End DLT date to be provided")
- Live data confirms: DLTOpen=true positions consistently have HedgeServerID=86

**Diagram**:
```
Position data (Trade.Position, StatusID=1)
    |
    +-- LEFT JOIN Trade.PositionOpenInDLT on PositionID
    |
    +-- CASE: (HedgeServerID=86 OR DLT record exists)
    |         AND Occurred in [2024-09-24, 2025-10-30]
    |         AND OpenMarkup IS NOT NULL
    |         --> DLTOpen = 1
    |         ELSE --> DLTOpen = 0
```

### 2.3 Commission Version Derivation

**What**: Indicates which commission calculation model applies to the position.

**Columns/Parameters Involved**: `CommissionVersion`, `OpenMarketSpread`

**Rules**:
- CommissionVersion = 2 when OpenMarketSpread IS NOT NULL (new spread-based model)
- CommissionVersion = NULL when OpenMarketSpread IS NULL (legacy commission model)
- This allows downstream billing/statement procedures to branch on commission calculation logic

---

## 3. Data Overview

| PositionID | CID | InstrumentID | IsBuy | Amount | Leverage | DLTOpen | CommissionVersion | SettlementTypeID | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 2152547500 | 18 | 4212 | true | 0.10 | 1 | false | NULL | 1 | Legacy real-stock position (no OpenMarketSpread) from 2019 with minimal amount, pre-dating the DLT window |
| 2152042350 | 742577 | 100026 | true | 104.41 | 1 | false | NULL | 1 | Recent real-stock buy with OpenMarkup=1.8 but missing OpenMarketSpread, so CommissionVersion remains NULL |
| 2150964050 | 9340183 | 1046 | true | 13450.22 | 1 | true | 2 | 1 | DLT position on hedge server 86 with CommissionVersion=2, crypto instrument opened within the DLT date window |
| 2150926100 | 9340176 | 1107 | true | 823.10 | 1 | true | 2 | 1 | Another DLT crypto position, smaller amount, same DLT characteristics (HedgeServerID=86, CommissionVersion=2) |
| 2150969100 | 9340178 | 1113 | true | 4116.54 | 1 | true | 2 | 1 | DLT position on a different crypto instrument showing the DLT feature operates across multiple assets |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. From Trade.Position. PK for the position record. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID who owns this position. From Trade.Position. FK to Customer.Customer. |
| 3 | ForexResultID | bigint | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). In Trade.Position this tracks legacy forex result; hidden from external consumers. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Denomination currency of the position's account. From Trade.Position. FK to Dictionary.Currency (1=USD, 2=EUR, etc.). |
| 5 | ProviderID | int | NO | - | CODE-BACKED | Execution provider that filled the order. From Trade.Position. FK to Trade.Provider. |
| 6 | GameServerID | int | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). In Trade.Position this identifies the demo/game server; hidden from external consumers. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument traded. From Trade.Position. FK to Trade.Instrument. |
| 8 | HedgeID | int | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL AS int). In Trade.Position this links to the hedge record; hidden from external consumers. Note: type narrowed from bigint to int. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server managing this position. From Trade.Position. Used in DLTOpen computation (86 = DLT server). |
| 10 | OrderID | int | YES | - | CODE-BACKED | Originating order ID. From Trade.Position. FK to Trade.Orders. |
| 11 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier (1, 2, 5, 10, etc.). From Trade.Position. 1 = no leverage (real stock). |
| 12 | Amount | money | NO | - | CODE-BACKED | Position size in denomination currency. From Trade.Position. |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. From Trade.Position. |
| 14 | UnitMargin | money | YES | - | CODE-BACKED | Margin per unit for hedge/exposure calculations. From Trade.Position. |
| 15 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. From Trade.Position. |
| 16 | NetProfit | money | YES | - | CODE-BACKED | Unrealized PnL. From Trade.Position. Code comment: "Ask Pini if he want to put here pnl $/cents" - indicates PnL denomination was debated. |
| 17 | InitForexRate | float | YES | - | CODE-BACKED | Forex conversion rate at position open. From Trade.Position. |
| 18 | InitDateTime | datetime | YES | - | CODE-BACKED | Timestamp when position was opened. From Trade.Position. |
| 19 | LimitRate | float | YES | - | CODE-BACKED | Take-profit price level. From Trade.Position (sourced from PositionTreeInfo). |
| 20 | StopRate | float | YES | - | CODE-BACKED | Stop-loss price level. From Trade.Position (sourced from PositionTreeInfo). |
| 21 | SpreadedPipBid | float | YES | - | CODE-BACKED | Spread-adjusted pip bid at open. From Trade.Position. |
| 22 | SpreadedPipAsk | float | YES | - | CODE-BACKED | Spread-adjusted pip ask at open. From Trade.Position. |
| 23 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1 = buy/long, 0 = sell/short. From Trade.Position. |
| 24 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | **Hardcoded to 0 for external use**. In Trade.Position this indicates weekend-close preference; always false externally. |
| 25 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee. From Trade.Position. |
| 26 | Commission | money | YES | - | CODE-BACKED | Commission charged at open. From Trade.Position. |
| 27 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. From Trade.Position. |
| 28 | AdditionalParam | - | YES | - | CODE-BACKED | **Nullified for external use** (hardcoded NULL). Internal parameter hidden from external consumers. |
| 29 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the open request was submitted. From Trade.Position. |
| 30 | Occurred | datetime | YES | - | CODE-BACKED | When the position was actually executed/filled. From Trade.Position. Used in DLTOpen date-range check. |
| 31 | ClamedOnDay | int | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal overnight fee claim day counter; hidden from external consumers. |
| 32 | SpreadGroupID | int | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal spread group assignment; hidden from external consumers. |
| 33 | LotCountGroupID | int | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal lot count group; hidden from external consumers. |
| 34 | TradeRange | float | YES | - | CODE-BACKED | Market range tolerance at open. From Trade.Position. |
| 35 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot ID at open. From Trade.Position. |
| 36 | OrderPriceRateID | bigint | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal order price rate reference; hidden from external consumers. |
| 37 | OrderPriceRate | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal order price rate; hidden from external consumers. |
| 38 | MarketPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Market price rate at position open. From Trade.Position. |
| 39 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate snapshot ID. From Trade.Position. |
| 40 | EntryHedgeQuery | int | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal hedge query tracking; hidden from external consumers. |
| 41 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in add-to-position hierarchy. From Trade.Position. NULL for standalone positions. |
| 42 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before splits/merges. From Trade.Position. |
| 43 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Price rate from the last operation on this position. From Trade.Position. |
| 44 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Snapshot ID for last operation price rate. From Trade.Position. |
| 45 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Conversion rate from the last operation. From Trade.Position. |
| 46 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Snapshot ID for last operation conversion rate. From Trade.Position. |
| 47 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. 0 = manual/independent trade. From Trade.Position. |
| 48 | PositionRatio | decimal | YES | - | CODE-BACKED | Ratio of this position relative to the copied leader's position. From Trade.Position. |
| 49 | IsComputeForHedge | bit | YES | - | CODE-BACKED | Whether position participates in hedge exposure calculation. From Trade.Position. |
| 50 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal aggregated lot count; hidden from external consumers. |
| 51 | StocksOrderID | int | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal stocks order reference; hidden from external consumers. |
| 52 | InitialAmountCents | int | YES | - | CODE-BACKED | Initial position amount in cents. From Trade.Position. |
| 53 | LastEOWClameDate | datetime | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal end-of-week fee claim date; hidden from external consumers. |
| 54 | IsOpenOpen | bit | YES | - | CODE-BACKED | Whether position was opened via an "open-open" (market order executed immediately). From Trade.Position. |
| 55 | OpenExposureID | int | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal exposure tracking ID; hidden from external consumers. |
| 56 | OpenMarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate ID at open. From Trade.Position. |
| 57 | AmountInUnitsDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action unit amount; hidden from external consumers. |
| 58 | LotCountDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action lot count; hidden from external consumers. |
| 59 | InitForexRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action forex rate; hidden from external consumers. |
| 60 | LimitRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action take-profit rate; hidden from external consumers. |
| 61 | StopRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action stop-loss rate; hidden from external consumers. |
| 62 | SpreadedPipBidUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action spread pip bid; hidden from external consumers. |
| 63 | SpreadedPipAskUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action spread pip ask; hidden from external consumers. |
| 64 | OrderPriceRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action order price rate; hidden from external consumers. |
| 65 | MarketPriceRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action market price rate; hidden from external consumers. |
| 66 | LastOpPriceRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Pre-corporate-action last op price rate; hidden from external consumers. |
| 67 | InitExecutionID | bigint | YES | - | CODE-BACKED | Execution ID for the initial open. From Trade.Position. |
| 68 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server for this position. From Trade.Position. |
| 69 | PartitionCol | int | YES | - | CODE-BACKED | Partition column from PositionTbl. From Trade.Position. |
| 70 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree identifier for partition-aligned joins. From Trade.Position. |
| 71 | LastOverNightClameDate | datetime | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal overnight fee claim date; hidden from external consumers. |
| 72 | OrderType | tinyint | YES | - | CODE-BACKED | Type of order that opened this position. From Trade.Position. |
| 73 | IsTslEnabled | bit | YES | - | CODE-BACKED | Whether trailing stop-loss is enabled. From Trade.Position (sourced from PositionTreeInfo). |
| 74 | SLManualVer | smallint | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal stop-loss manual version counter; hidden from external consumers. |
| 75 | NextThresHold | decimal(16,8) | YES | - | CODE-BACKED | **Nullified for external use** (CAST NULL). Internal TSL next threshold; hidden from external consumers. |
| 76 | FullCommission | money | YES | - | CODE-BACKED | Full commission including extras. From Trade.Position. |
| 77 | IsSettled | bit | YES | - | CODE-BACKED | Legacy flag: 1 = real stock position, 0 = CFD. Predates SettlementTypeID. From Trade.Position. |
| 78 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type: 1=Real stocks, 2=CFD. Backward-compatible computed column in Trade.Position. See [Settlement Type](_glossary.md#settlement-type). |
| 79 | RedeemStatus | tinyint | YES | - | CODE-BACKED | Current redeem/settlement processing status. From Trade.Position. |
| 80 | RedeemID | bigint | YES | - | CODE-BACKED | Associated redeem operation ID. From Trade.Position. |
| 81 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | Computed in Trade.Position: ISNULL(InitialUnits, AmountInUnitsDecimal). Original unit count at open with backward-compatible fallback. |
| 82 | ReopenForPositionID | bigint | YES | - | CODE-BACKED | Links to original position if this was reopened from a corporate action. From Trade.Position. |
| 83 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Computed in Trade.Position: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). Base value in cents with backward-compatible fallback. |
| 84 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether position has discounted fees. From Trade.Position (sourced from PositionTreeInfo). |
| 85 | CommissionByUnits | money | YES | - | CODE-BACKED | Prorated commission for partial-close scenarios. Computed in Trade.Position. |
| 86 | FullCommissionByUnits | money | YES | - | CODE-BACKED | Prorated full commission for partial-close scenarios. Computed in Trade.Position. |
| 87 | InitConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Currency conversion rate at position open. From Trade.Position. |
| 88 | InitConversionRateID | bigint | YES | - | CODE-BACKED | Snapshot ID for initial conversion rate. From Trade.Position. |
| 89 | OpenActionType | tinyint | YES | - | CODE-BACKED | Type of open action (market, limit, etc.). From Trade.Position. |
| 90 | MarketRangeValidationType | tinyint | YES | - | CODE-BACKED | Market range validation mode at open. From Trade.Position. |
| 91 | MarketRangePercentage | decimal | YES | - | CODE-BACKED | Market range tolerance percentage. From Trade.Position. |
| 92 | PositionPartitionCol | int | YES | - | CODE-BACKED | Partition column alias from PositionTbl. From Trade.Position. |
| 93 | TreePartitionCol | int | YES | - | CODE-BACKED | Partition column alias from PositionTreeInfo. From Trade.Position. |
| 94 | RowVersionPosition | rowversion | YES | - | CODE-BACKED | Optimistic concurrency token from PositionTbl. From Trade.Position. Used by Trade.PosionByRowVersion for change detection. |
| 95 | RowVersionTree | rowversion | YES | - | CODE-BACKED | Optimistic concurrency token from PositionTreeInfo. From Trade.Position. Used by Trade.PosionByRowVersion for change detection. |
| 96 | IsNoStopLoss | bit | YES | - | CODE-BACKED | Whether stop-loss is disabled for this position. From Trade.Position (sourced from PositionTreeInfo). |
| 97 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | Whether take-profit is disabled for this position. From Trade.Position (sourced from PositionTreeInfo). |
| 98 | OpenMarketSpread | decimal | YES | - | CODE-BACKED | Market spread at open. From Trade.Position. NULL for legacy positions. Used to derive CommissionVersion. |
| 99 | PnLVersion | tinyint | YES | - | CODE-BACKED | PnL calculation version. From Trade.Position. |
| 100 | CloseMarkupOnOpen | money | YES | - | CODE-BACKED | Expected close markup captured at open time. From Trade.Position. |
| 101 | EstimatedConversionMarkupRatio | decimal | YES | - | CODE-BACKED | Estimated currency conversion markup ratio. From Trade.Position. |
| 102 | EstimatedMarkupRatio | decimal | YES | - | CODE-BACKED | Estimated total markup ratio. From Trade.Position. |
| 103 | OpenMarkup | money | YES | - | CODE-BACKED | Markup applied at position open. From Trade.Position. Used in DLTOpen check (must be NOT NULL). |
| 104 | OpenEtoroPrice | decimal | YES | - | CODE-BACKED | eToro's displayed price at open including spread/markup. From Trade.Position. |
| 105 | OpenTotalTaxes | money | YES | - | CODE-BACKED | Total taxes applied at open. From Trade.Position. |
| 106 | OpenTotalFees | money | YES | - | CODE-BACKED | Total fees applied at open. From Trade.Position. |
| 107 | DLTOpen | bit | NO | - | CODE-BACKED | **Computed in this view**: 1 when (HedgeServerID=86 OR position exists in Trade.PositionOpenInDLT) AND Occurred between 2024-09-24 and 2025-10-30 AND OpenMarkup IS NOT NULL. Indicates position was opened on the blockchain/DLT layer. |
| 108 | OpenMarkupByUnits | money | YES | - | CODE-BACKED | Prorated open markup for partial-close scenarios. Computed in Trade.Position. |
| 109 | CommissionVersion | tinyint | YES | - | CODE-BACKED | **Computed in this view**: 2 when OpenMarketSpread IS NOT NULL, else NULL. Indicates new spread-based commission model (2) vs legacy (NULL). |
| 110 | CloseMarkup | money | YES | - | CODE-BACKED | Close markup amount. From Trade.Position. |
| 111 | InitialLotCount | decimal | YES | - | CODE-BACKED | Initial lot count at position open. From Trade.Position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | Trade.Position | View dependency | Base view providing all open position data (StatusID=1 filter applied there) |
| PositionID | Trade.PositionOpenInDLT | LEFT JOIN | Checks blockchain membership for DLTOpen flag computation |
| CID | Customer.Customer | Implicit (via Position) | Customer who owns the position |
| InstrumentID | Trade.Instrument | Implicit (via Position) | Instrument being traded |
| ProviderID | Trade.Provider | Implicit (via Position) | Execution provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PosionByRowVersion | FROM | View consumer | Adds row-version change tracking on top for incremental feeds |
| Trade.PositionForExternalUseWithPnL | FROM | View consumer | Extends with PnL calculations |
| Trade.GetPositionDataForExternalUse | FROM | View consumer | Data extraction variant |
| Trade.OpenPositionEndOfDay | FROM | View consumer | End-of-day open position snapshot |
| BackOffice.GetCustomerOpenPositions | SELECT | Procedure reader | Returns customer open positions for back-office |
| BackOffice.GetRedeemsInfo | SELECT | Procedure reader | Reads position data for redeem info |
| BackOffice.GetCustomerOpenCopiedTraders | SELECT | Procedure reader | Gets open copied traders for a customer |
| Billing.GetPositionNetProfit | SELECT | Procedure reader | Calculates net profit per position |
| Billing.GetRedeemValidationData | SELECT | Procedure reader | Validates redeem eligibility using position data |
| Billing.GetRedeemRecords | SELECT | Procedure reader | Reads positions for redeem records |
| Billing.GetRedeemRecordsDynamic | SELECT | Procedure reader | Dynamic version of redeem records |
| BackOffice.GetUnrealizedPnL | SELECT | Function reader | Calculates unrealized PnL from positions |
| dbo.AccountStatement_BPGetTransactions_v2 | SELECT | Procedure reader | Account statement transaction extraction |
| dbo.AccountStatement_GetUserStatementSummary | SELECT | Procedure reader | User statement summary |
| dbo.AccountStatement_GetTransactionsReport_v10 | SELECT | Procedure reader | Transaction report |
| dbo.SSRS_NWA_Calc | SELECT | Procedure reader | NWA (Net Worth After) calculation for SSRS reporting |
| Trade.PosionByRowVersionID | SELECT | Procedure reader | Row version lookup by ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionForExternalUse (view)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.PositionOpenInDLT (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Base data source - all columns except DLTOpen and CommissionVersion pass through from here |
| Trade.PositionOpenInDLT | Table | LEFT JOIN on PositionID for DLT membership check in DLTOpen computation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PosionByRowVersion | View | Wraps this view with row-version change tracking via CTE + CROSS APPLY |
| Trade.PositionForExternalUseWithPnL | View | Extends with PnL calculations |
| Trade.GetPositionDataForExternalUse | View | Data extraction variant |
| Trade.OpenPositionEndOfDay | View | End-of-day snapshot |
| BackOffice.GetCustomerOpenPositions | Procedure | Reads open positions for back-office UI |
| BackOffice.GetRedeemsInfo | Procedure | Reads for redeem info |
| BackOffice.GetCustomerOpenCopiedTraders | Procedure | Reads for copied traders |
| Billing.GetPositionNetProfit | Procedure | Reads for net profit calc |
| Billing.GetRedeemValidationData | Procedure | Reads for redeem validation |
| Billing.GetRedeemRecords | Procedure | Reads for redeem records |
| Billing.GetRedeemRecordsDynamic | Procedure | Reads for dynamic redeem records |
| BackOffice.GetUnrealizedPnL | Function | Reads for unrealized PnL |
| dbo.AccountStatement_BPGetTransactions_v2 | Procedure | Transaction extraction |
| dbo.AccountStatement_GetUserStatementSummary | Procedure | Statement summary |
| dbo.AccountStatement_GetTransactionsReport_v10 | Procedure | Transaction report |
| dbo.SSRS_NWA_Calc | Procedure | NWA calculation |
| Trade.PosionByRowVersionID | Procedure | Row version lookup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Open positions for a customer (external-safe)

```sql
SELECT PositionID, InstrumentID, IsBuy, Amount, Leverage, InitDateTime,
       SettlementTypeID, DLTOpen, CommissionVersion
FROM   Trade.PositionForExternalUse WITH (NOLOCK)
WHERE  CID = 12345;
```

### 8.2 All DLT positions currently open

```sql
SELECT PositionID, CID, InstrumentID, Amount, HedgeServerID,
       OpenMarkup, CommissionVersion
FROM   Trade.PositionForExternalUse WITH (NOLOCK)
WHERE  DLTOpen = 1;
```

### 8.3 Positions with new commission model

```sql
SELECT PositionID, CID, InstrumentID, Amount,
       Commission, OpenMarkup, CloseMarkup, OpenMarketSpread, CommissionVersion
FROM   Trade.PositionForExternalUse WITH (NOLOCK)
WHERE  CommissionVersion = 2
ORDER BY InitDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 111 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionForExternalUse | Type: View | Source: etoro/etoro/Trade/Views/Trade.PositionForExternalUse.sql*
