# History.PositionForExternalUse

> Sanitized closed-position view for external consumers (account statements, BI, reporting APIs) - wraps History.Position with legacy internal fields suppressed to NULL, and adds three computed columns: DLTOpen (position opened via Distributed Ledger Technology), DLTClose (position closed via DLT), and CommissionVersion (commission calculation algorithm indicator).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A (view - inherits History.Position's multi-source UNION ALL) |
| **Indexes** | N/A (view - base source indexes used) |

---

## 1. Business Meaning

`History.PositionForExternalUse` is the external-facing query interface for closed trading positions. It is built on top of `History.Position` (the full 124-column internal view spanning all of eToro's trading history from 2007 to present) but makes two key modifications for external consumer safety and clarity:

**1. Legacy/internal fields suppressed to NULL**: Columns that are internal to the hedging and price system (HedgeID, GameServerID, ForexResultID, EntryHedgeQuery, EndHedgeQuery, OrderPriceRateID, the "UnAdjusted" rate variants, StocksOrderID, exposure IDs, etc.) are set to NULL or a safe constant. This prevents external consumers from relying on internal technical fields that may change or be meaningless outside the hedging system context.

**2. DLT enrichment via LEFT JOIN**: The view adds a LEFT JOIN to `Trade.PositionOpenInDLT` to detect whether a position was opened or closed through eToro's Distributed Ledger Technology (DLT) infrastructure (HedgeServerID=86), and adds `DLTOpen`, `DLTClose`, and `CommissionVersion` computed columns that encode this information for downstream use.

The view is consumed by account statement procedures (providing customer-facing transaction history), BackOffice procedures (compliance reporting), and downstream views (`History.ClosePositionEndOfDay`, `History.Position_DataFactory`) that further aggregate or filter positions.

---

## 2. Business Logic

### 2.1 DLT Position Detection

**What**: Identifies positions that were executed through eToro's DLT (Distributed Ledger Technology / blockchain-based settlement) infrastructure during the DLT pilot period.

**Columns/Parameters Involved**: `DLTOpen`, `DLTClose`, `HedgeServerID`, `OpenOccurred`, `OpenMarkup`

**Rules**:
```sql
DLTOpen = CASE WHEN (
    (hp.HedgeServerID = 86 OR dlt.PositionID IS NOT NULL)
    AND hp.OpenOccurred BETWEEN '2024-09-24' AND '2025-10-30'
    AND OpenMarkup IS NOT NULL
) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END

DLTClose = CASE WHEN HedgeServerID = 86 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
```
- `DLTOpen = 1` when: position was routed via DLT hedge server (HedgeServerID=86) OR appears in Trade.PositionOpenInDLT (positions confirmed as opened via DLT), AND was opened during the DLT pilot window (2024-09-24 to 2025-10-30), AND has OpenMarkup data (not a legacy position)
- `DLTClose = 1` when: the position's closing hedge was routed via HedgeServerID=86 (the DLT hedge server)
- The comment in the DDL notes "TBD: End DLT date to be provided" suggesting the upper bound `2025-10-30` was an initial estimate that may be updated
- LEFT JOIN on Trade.PositionOpenInDLT catches positions confirmed as DLT-opened even if HedgeServerID differs

**Diagram**:
```
History.Position hp
    LEFT JOIN Trade.PositionOpenInDLT dlt ON hp.PositionID = dlt.PositionID

DLTOpen = 1 if:
    (HedgeServerID=86 OR dlt.PositionID IS NOT NULL)  <- DLT hedge server or confirmed DLT table
    AND OpenOccurred in [2024-09-24, 2025-10-30]       <- DLT pilot window
    AND OpenMarkup IS NOT NULL                          <- modern position (not legacy)

DLTClose = 1 if:
    HedgeServerID=86  <- closed via DLT hedge server
```

### 2.2 CommissionVersion Indicator

**What**: Encodes which version of commission calculation was used for the position, based on which spread-related columns are populated.

**Columns/Parameters Involved**: `CommissionVersion`, `CloseMarketSpread`, `OpenMarketSpread`

**Rules**:
```sql
CommissionVersion = CAST(
    CASE
        WHEN CloseMarketSpread IS NULL THEN 0
        WHEN OpenMarketSpread IS NULL THEN 1
        ELSE 2
    END AS TINYINT)
```
- `0`: Oldest commission calculation (pre-OpenMarketSpread/CloseMarketSpread era) - neither spread field populated
- `1`: Intermediate version - close spread captured but not open spread
- `2`: Current commission calculation - both OpenMarketSpread and CloseMarketSpread are populated

### 2.3 Legacy Field Suppression

**What**: Internal hedging system columns are set to NULL or constant to provide a clean external schema.

**Columns/Parameters Involved**: ForexResultID, GameServerID, HedgeID, EntryHedgeQuery, EndHedgeQuery, SpreadGroupID, LotCountGroupID, OrderPriceRateID, OrderPriceRate, StocksOrderID, OpenExposureID, CloseExposureID, AdditionalParam, CloseOnEndOfWeek, all "UnAdjusted" rate columns

**Rules**:
- `ForexResultID = NULL`: Legacy forex game link (ForexResultID=-1 in History.Position for all modern records) - suppressed since it's meaningless externally
- `GameServerID = NULL`: Legacy game server routing - suppressed
- `HedgeID = NULL`: Internal hedging assignment ID - suppressed
- `EntryHedgeQuery / EndHedgeQuery = NULL`: Internal hedge system query IDs - suppressed
- `SpreadGroupID / LotCountGroupID = NULL`: Internal spread/lot configuration IDs - suppressed
- `OrderPriceRateID / OrderPriceRate = NULL`: Overridden to NULL for external consumers
- `StocksOrderID = NULL`: Stock order link - suppressed
- `OpenExposureID / CloseExposureID = NULL`: Internal exposure tracking IDs - suppressed
- `CloseOnEndOfWeek = CAST(0 AS BIT)`: Always 0 for closed positions (this flag was for open position lifecycle, irrelevant after close)
- All "UnAdjusted" rate columns = NULL: The un-adjusted raw rates are internal computation details; external consumers use the adjusted values

---

## 3. Data Overview

Direct query blocked (History.Position cross-database access restriction for archive branches). Based on History.Position documentation, the most recent closed positions:

| PositionID | CID | InstrumentID | IsBuy | Amount | NetProfit | ActionType | CloseOccurred | DLTOpen | DLTClose | CommissionVersion | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 2152976743 | 14952810 | 100000 (BTC) | Buy | 99.97 | 0 | 0 | 2026-03-21 | 0 | 0 | 0 or 2 | Recent BTC settlement cycle position; DLTOpen=0 as OpenMarkup/HedgeServerID conditions not met for this test account |
| (DLT pilot) | (various) | (various) | (varies) | (varies) | (varies) | (varies) | 2024-2025 | 1 | 0 or 1 | 2 | DLT-opened position from the pilot window - OpenOccurred in [Sep 2024, Oct 2025], HedgeServerID=86 or in PositionOpenInDLT table |

---

## 4. Elements

126 total columns. Columns 1-124 correspond to History.Position; OriginalOpenActionType (column 123 of History.Position) is omitted; DLTOpen, DLTClose, CommissionVersion are added. See History.Position.md and History.Position_Active.md for full historical branch coverage notes.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Unique closed position identifier. From History.Position. Passthrough. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer account ID. From History.Position. Passthrough. |
| 3 | ForexResultID | bigint | YES | - | CODE-BACKED | Always NULL in this view. Suppressed legacy forex game session link (History.Position has -1 for all modern records). External consumers should not depend on this. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Account currency denomination. FK to Dictionary.Currency. Passthrough from History.Position. |
| 5 | ProviderID | int | NO | - | CODE-BACKED | Liquidity provider routing this position. Passthrough from History.Position. |
| 6 | GameServerID | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed legacy game server routing ID. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | Traded instrument. FK (implicit) to Trade.Instrument. Passthrough from History.Position. |
| 8 | HedgeID | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed internal hedging assignment ID. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server that executed this position. 86=DLT hedge server (drives DLTClose computation). Passthrough from History.Position. |
| 10 | OrderID | int | YES | - | CODE-BACKED | Pending order that generated this position (if created from an order). Passthrough from History.Position. |
| 11 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier (1=no leverage, 2=2x, etc.). Passthrough from History.Position. |
| 12 | Amount | money | NO | - | CODE-BACKED | Position invested amount in account currency (USD). Passthrough from History.Position. |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in fractional instrument units. Passthrough from History.Position. |
| 14 | UnitMargin | decimal(16,8) | NO | - | CODE-BACKED | Margin required per unit in account currency. Passthrough from History.Position. |
| 15 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in lots (decimal precision). Passthrough from History.Position. |
| 16 | InitForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate at position open (the opening price). Passthrough from History.Position. |
| 17 | InitDateTime | datetime | NO | - | CODE-BACKED | Timestamp when position was initiated (order placed or position opened). Passthrough from History.Position. |
| 18 | NetProfit | money | NO | - | CODE-BACKED | Position net P&L in account currency at close. Positive=profit, negative=loss. Passthrough from History.Position. |
| 19 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take-profit rate. Passthrough from History.Position. |
| 20 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop-loss rate. Passthrough from History.Position. |
| 21 | SpreadedPipBid | dbo.dtPrice | YES | - | CODE-BACKED | Spreaded Bid price at open. Passthrough from History.Position. |
| 22 | SpreadedPipAsk | dbo.dtPrice | YES | - | CODE-BACKED | Spreaded Ask price at open. Passthrough from History.Position. |
| 23 | IsBuy | bit | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. Passthrough from History.Position. |
| 24 | CloseOnEndOfWeek | bit | NO | - | CODE-BACKED | Always CAST(0 AS BIT) in this view. This flag was for open-position lifecycle (whether to auto-close on end-of-week); overridden to 0 as all positions here are already closed. |
| 25 | EndOfWeekFee | money | NO | - | CODE-BACKED | Total end-of-week financing fee accumulated over the position lifetime. Passthrough from History.Position. |
| 26 | Commission | money | NO | - | CODE-BACKED | Commission charged at position open. Passthrough from History.Position. |
| 27 | CommissionOnClose | money | NO | - | CODE-BACKED | Commission charged at position close. Passthrough from History.Position. |
| 28 | SpreadedCommission | int | NO | - | CODE-BACKED | Spread-based commission amount. Passthrough from History.Position. |
| 29 | EndForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate at position close (the closing price). Passthrough from History.Position. |
| 30 | RequestedEndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Client-requested close rate (may differ from actual EndForexRate for limit/stop triggers). Passthrough from History.Position. |
| 31 | EndDateTime | datetime | NO | - | CODE-BACKED | Timestamp when position was closed. Passthrough from History.Position. |
| 32 | ActionType | int | NO | - | CODE-BACKED | Why the position was closed. 1=ClientClose (68%), 0=auto (12%), 10=settlement (11%), 13=stop-loss (1.4%), 9=take-profit, 5=EOW. Passthrough from History.Position. |
| 33 | AdditionalParam | sql_variant | YES | - | CODE-BACKED | Always NULL in this view. Legacy additional parameter field - suppressed. |
| 34 | RequestOpenOccurred | datetime | YES | - | CODE-BACKED | Timestamp of the client's open request. NULL for Trade branch (recently closed positions). Passthrough from History.Position. |
| 35 | RequestCloseOccurred | datetime | YES | - | CODE-BACKED | Timestamp of the client's close request. NULL for Trade branch. Passthrough from History.Position. |
| 36 | OpenOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the position was actually opened. Primary date for DLTOpen calculation. Passthrough from History.Position. |
| 37 | CloseOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the position was actually closed. Passthrough from History.Position. |
| 38 | SpreadGroupID | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed internal spread group configuration ID. |
| 39 | LotCountGroupID | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed internal lot count group ID. |
| 40 | TradeRange | int | YES | - | CODE-BACKED | Maximum acceptable execution deviation from requested rate. Passthrough from History.Position. |
| 41 | InitForexPriceRateID | bigint | NO | - | CODE-BACKED | Price record ID for the rate at open. Enables exact price trace. Passthrough from History.Position. |
| 42 | OrderPriceRateID | bigint | YES | - | CODE-BACKED | Always NULL in this view. Suppressed (History.Position has the value but it's overridden here). |
| 43 | EndForexPriceRateID | bigint | NO | - | CODE-BACKED | Price record ID for the rate at close. Passthrough from History.Position. |
| 44 | OrderPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Overridden from History.Position value. |
| 45 | MarketPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | Market mid-price at open. Passthrough from History.Position. |
| 46 | MarketPriceRateID | bigint | NO | - | CODE-BACKED | Price record ID for MarketPriceRate. Passthrough from History.Position. |
| 47 | EntryHedgeQuery | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed internal hedge system query ID at open. |
| 48 | EndHedgeQuery | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed internal hedge system query ID at close. |
| 49 | ParentPositionID | bigint | YES | - | CODE-BACKED | For copy-trading: the leader position this copier position follows. Passthrough from History.Position. |
| 50 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent position before any copy hierarchy restructuring. Passthrough from History.Position. |
| 51 | LastOpPriceRate | dbo.dtPrice | YES | - | CODE-BACKED | Last recorded price rate at the time of the last position operation. Passthrough from History.Position. |
| 52 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Price record ID for LastOpPriceRate. Passthrough from History.Position. |
| 53 | LastOpConversionRate | dbo.dtPrice | YES | - | CODE-BACKED | USD conversion rate at last operation time. Passthrough from History.Position. |
| 54 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Price record ID for LastOpConversionRate. Passthrough from History.Position. |
| 55 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade portfolio this position belongs to. 0=not a copy. Passthrough from History.Position. |
| 56 | EndMarketRate | dbo.dtPrice | YES | - | CODE-BACKED | Market mid-price at position close. Passthrough from History.Position. |
| 57 | EndMarketPriceRateID | bigint | YES | - | CODE-BACKED | Price record ID for EndMarketRate. Passthrough from History.Position. |
| 58 | PositionRatio | decimal(7,6) | YES | - | CODE-BACKED | For copy-trading: the proportional ratio of this copier position relative to the leader. Passthrough from History.Position. |
| 59 | DirectAggLotCount | decimal(16,6) | YES | - | NAME-INFERRED | Aggregated direct lot count. Passthrough from History.Position. |
| 60 | StocksOrderID | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed stock order link (History.Position has the value but it's overridden here). |
| 61 | InitialAmountCents | money | NO | - | CODE-BACKED | Opening position value in cents. Passthrough from History.Position. |
| 62 | IsOpenOpen | bit | YES | - | CODE-BACKED | Copy-trading flag: whether the position was opened as an "open-open" (leader position already open when copier joined). Passthrough from History.Position. |
| 63 | OpenExposureID | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed internal exposure tracking ID at open. |
| 64 | CloseExposureID | int | YES | - | CODE-BACKED | Always NULL in this view. Suppressed internal exposure tracking ID at close. |
| 65 | OpenMarketPriceRateID | bigint | YES | - | CODE-BACKED | Price record ID for the market price at open. Passthrough from History.Position. |
| 66 | CloseMarketPriceRateID | bigint | YES | - | CODE-BACKED | Price record ID for the market price at close. Passthrough from History.Position. |
| 67 | AmountInUnitsDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Always NULL in this view. The un-adjusted (pre-split-correction) unit amount is suppressed for external consumers. |
| 68 | LotCountDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted lot count suppressed. |
| 69 | InitForexRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted open rate suppressed for external consumers. Use InitForexRate instead. |
| 70 | LimitRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted take-profit rate suppressed. Use LimitRate instead. |
| 71 | StopRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted stop-loss rate suppressed. Use StopRate instead. |
| 72 | EndForexRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted close rate suppressed. Use EndForexRate instead. |
| 73 | OrderPriceRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted order price rate suppressed. |
| 74 | MarketPriceRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted market price rate suppressed. |
| 75 | LastOpPriceRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted last-operation price rate suppressed. |
| 76 | EndMarketRateUnAdjusted | decimal(16,8) | YES | - | CODE-BACKED | Always NULL in this view. Un-adjusted close market rate suppressed. |
| 77 | InitExecutionID | bigint | YES | - | CODE-BACKED | Execution record ID at open. Passthrough from History.Position. |
| 78 | EndExecutionID | bigint | YES | - | CODE-BACKED | Execution record ID at close. Passthrough from History.Position. |
| 79 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root of the hedge server chain for this position. Passthrough from History.Position. |
| 80 | TreeID | bigint | NO | - | CODE-BACKED | Copy-trade tree root ID - groups all positions in the same copy hierarchy. Passthrough from History.Position. |
| 81 | ExitOrderID | int | YES | - | CODE-BACKED | Exit order that triggered close (for order-based closes). Passthrough from History.Position. |
| 82 | OrderType | int | YES | - | NAME-INFERRED | Type of order used to open/close this position. Passthrough from History.Position. |
| 83 | IsTslEnabled | tinyint | NO | - | CODE-BACKED | Trailing stop-loss flag: 0=disabled, 1=enabled. Passthrough from History.Position. |
| 84 | IsComputeForHedge | smallint | YES | - | NAME-INFERRED | Internal hedge computation flag. Passthrough from History.Position. |
| 85 | FullCommission | money | YES | - | CODE-BACKED | Total gross commission (before partial-close ratio adjustment). Passthrough from History.Position. |
| 86 | FullCommissionOnClose | money | YES | - | CODE-BACKED | Total gross commission on close. Passthrough from History.Position. |
| 87 | IsSettled | bit | NO | - | CODE-BACKED | Whether the position has been financially settled. 0 in pre-2021Q1 archive branches; native (91.6% true) in 2021+ branches. Passthrough from History.Position. |
| 88 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement method: 0=not settled, 1=standard settled. 2021Q1+: ISNULL(SettlementTypeID, cast(IsSettled as tinyint)). Passthrough from History.Position. |
| 89 | RedeemStatus | tinyint | YES | - | CODE-BACKED | Redemption lifecycle state. NULL for pre-2021 archive rows; 20=redeemed for 2021+ rows where applicable. Passthrough from History.Position. |
| 90 | RedeemID | int | YES | - | CODE-BACKED | Redemption event ID. NULL for pre-2021 archive rows. Passthrough from History.Position. |
| 91 | OriginalPositionID | bigint | YES | - | CODE-BACKED | For partial-close clones: the parent position's PositionID before the split. For regular positions: self-reference or NULL. Passthrough from History.Position. |
| 92 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | Original unit count at position open (before any partial close reduced it). Passthrough from History.Position. |
| 93 | SubCloseTypeID | decimal(16,6) | YES | - | NAME-INFERRED | Sub-type of close event. Passthrough from History.Position. |
| 94 | PartialCloseRatio | decimal(16,15) | YES | - | CODE-BACKED | Fraction of position closed in a partial close: 0.0-1.0. NULL=full close. Passthrough from History.Position. |
| 95 | ReopenForPositionID | bigint | YES | - | CODE-BACKED | If this position was closed and re-opened as a new position, links to the new PositionID. Passthrough from History.Position. |
| 96 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Position value in cents: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). Passthrough from History.Position. |
| 97 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether a discounted spread was applied (Free Stocks eligibility). Passthrough from History.Position. |
| 98 | CommissionByUnits | money | NO | - | CODE-BACKED | Commission proportionally adjusted for partial-close: (AmountInUnitsDecimal / InitialUnits) * Commission. Passthrough from History.Position. |
| 99 | FullCommissionByUnits | money | NO | - | CODE-BACKED | Full commission proportionally adjusted for partial-close. Passthrough from History.Position. |
| 100 | InitConversionRate | decimal(16,8) | YES | - | CODE-BACKED | USD conversion rate at open (for non-USD instruments). NULL for pre-2021Q2 archive rows. Passthrough from History.Position. |
| 101 | InitConversionRateID | bigint | YES | - | CODE-BACKED | Price record ID for InitConversionRate. Passthrough from History.Position. |
| 102 | ExitOrderType | int | YES | - | CODE-BACKED | Type of exit order that triggered close. NULL for pre-2021Q2 archive rows. Passthrough from History.Position. |
| 103 | MarketRangeValidationType | tinyint | YES | - | CODE-BACKED | Market range validation applied at execution. NULL for pre-2021Q2 rows. Passthrough from History.Position. |
| 104 | MarketRangePercentage | decimal(5,2) | YES | - | CODE-BACKED | Maximum acceptable deviation % for market-range orders. NULL for pre-2021Q2 rows. Passthrough from History.Position. |
| 105 | OpenActionType | int | NO | - | CODE-BACKED | How the position was opened. -1 for pre-2021Q2 archive rows; native for 2021Q2+ rows. Passthrough from History.Position. |
| 106 | OpenMarketSpread | dbo.dtPrice | YES | - | CODE-BACKED | Bid-ask spread at open. NULL for pre-2021Q2 rows. Drives CommissionVersion calculation. Passthrough from History.Position. |
| 107 | CloseMarketSpread | dbo.dtPrice | YES | - | CODE-BACKED | Bid-ask spread at close. NULL for pre-2021Q2 rows. Drives CommissionVersion calculation. Passthrough from History.Position. |
| 108 | PnLVersion | tinyint | YES | - | CODE-BACKED | P&L calculation algorithm version. 0 for pre-2021Q2 rows. Passthrough from History.Position. |
| 109 | CloseMarkupOnOpen | money | YES | - | CODE-BACKED | Estimated close markup calculated at open (for pre-computation). NULL for pre-2021Q2 rows. Passthrough from History.Position. |
| 110 | OpenMarkup | money | YES | - | CODE-BACKED | eToro revenue markup charged at open. NULL for pre-2021Q2 rows; also used in DLTOpen condition (must be NOT NULL). Passthrough from History.Position. |
| 111 | CloseMarkup | money | YES | - | CODE-BACKED | eToro revenue markup charged at close. NULL for pre-2021Q2 rows. Passthrough from History.Position. |
| 112 | OpenEtoroPrice | dbo.dtPrice | YES | - | CODE-BACKED | eToro-quoted execution price at open (market price + markup). NULL for pre-2021Q2 rows. Passthrough from History.Position. |
| 113 | CloseEtoroPrice | dbo.dtPrice | YES | - | CODE-BACKED | eToro-quoted execution price at close. NULL for pre-2021Q2 rows. Passthrough from History.Position. |
| 114 | EstimatedConversionMarkupRatio | decimal(20,4) | YES | - | CODE-BACKED | Estimated ratio of conversion markup on this position. Passthrough from History.Position. |
| 115 | EstimatedMarkupRatio | decimal(20,4) | YES | - | CODE-BACKED | Estimated total markup ratio. Passthrough from History.Position. |
| 116 | OpenTotalTaxes | money | YES | - | CODE-BACKED | Total taxes applied at open. 0 for pre-2022Q4 archive rows; native for 2022Q4+ rows. Passthrough from History.Position. |
| 117 | OpenTotalFees | money | YES | - | CODE-BACKED | Total fees applied at open (excluding commission). 0 for pre-2022Q4 rows. Passthrough from History.Position. |
| 118 | CloseTotalTaxes | money | YES | - | CODE-BACKED | Total taxes at close. 0 for pre-2022Q4 rows. Passthrough from History.Position. |
| 119 | CloseTotalFees | money | YES | - | CODE-BACKED | Total fees at close. 0 for pre-2022Q4 rows. Passthrough from History.Position. |
| 120 | DLTOpen | bit | NO | - | CODE-BACKED | Computed: 1 if position was opened via eToro's DLT infrastructure. Conditions: (HedgeServerID=86 OR in Trade.PositionOpenInDLT) AND OpenOccurred IN [2024-09-24, 2025-10-30] AND OpenMarkup IS NOT NULL. 0 otherwise. DLT pilot period indicator. |
| 121 | DLTClose | bit | NO | - | CODE-BACKED | Computed: 1 if position was closed via the DLT hedge server (HedgeServerID=86). 0 otherwise. Captures the close leg of DLT execution independently of DLTOpen. |
| 122 | OpenMarkupByUnits | money | YES | - | CODE-BACKED | Per-unit open markup (OpenMarkup proportionally adjusted for partial close). 0/NULL for pre-2022Q4 rows. Passthrough from History.Position. |
| 123 | CommissionVersion | tinyint | NO | - | CODE-BACKED | Computed: algorithm version indicator for commission calculation. 0=oldest (neither spread field populated), 1=intermediate (CloseMarketSpread present, OpenMarketSpread NULL), 2=current (both OpenMarketSpread and CloseMarketSpread populated). Enables downstream procedures to apply the correct commission interpretation logic. |
| 124 | IsNoStopLoss | bit | YES | - | CODE-BACKED | Explicit flag that no stop-loss was configured (vs. StopRate=0 which may be ambiguous). NULL for pre-2022Q4 rows. Passthrough from History.Position. |
| 125 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | Explicit flag that no take-profit was configured. NULL for pre-2022Q4 rows. Passthrough from History.Position. |
| 126 | InitialLotCount | decimal(16,6) | YES | - | CODE-BACKED | Original lot count at open (before any partial close). NULL for pre-2022Q4 rows. Passthrough from History.Position. |

**Note**: `OriginalOpenActionType` (column 123 of History.Position) is NOT exposed in this view.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | History.Position | View dependency (primary) | Full closed-position history UNION ALL - all 65+ source branches |
| PositionID | Trade.PositionOpenInDLT | LEFT JOIN (cross-schema) | Detects DLT-opened positions not identifiable via HedgeServerID alone; NULL join = position not DLT-opened |
| InstrumentID | Trade.Instrument | Implicit (inherited) | Traded instrument |
| HedgeServerID | (internal) | Implicit | 86=DLT hedge server; drives DLTClose and DLTOpen |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ClosePositionEndOfDay | PositionForExternalUse | View dependency | End-of-day close position reporting view |
| History.ClosePositionEndOfDay_Try | PositionForExternalUse | View dependency | Experimental version of ClosePositionEndOfDay |
| History.Position_DataFactory | PositionForExternalUse | View dependency | Data factory position output view |
| dbo.AccountStatement_GetTransactionsReport_v10 | PositionForExternalUse | Reader (SP) | Account statement v10 - latest transaction history |
| dbo.AccountStatement_GetUserStatementSummary | PositionForExternalUse | Reader (SP) | Account statement summary |
| dbo.AccountStatement_GetUserStatementSummary_v2 | PositionForExternalUse | Reader (SP) | Account statement summary v2 |
| dbo.AccountStatement_GetClosedPositionsReport_v2np | PositionForExternalUse | Reader (SP) | Closed positions report v2np |
| dbo.AccountStatement_GetClosedPositionsReport_v3 | PositionForExternalUse | Reader (SP) | Closed positions report v3 |
| dbo.AccountStatement_BPGetTransactions_v2 | PositionForExternalUse | Reader (SP) | BP (Business Partner) transactions v2 |
| BackOffice.GetCustomerClosedPositions | PositionForExternalUse | Reader (SP) | Back-office customer position lookup |
| Trade.GetPositionDataForExternalUse | PositionForExternalUse | View (cross-schema) | Trade schema counterpart view using this as source |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionForExternalUse (view)
|--> History.Position (view - full closed-position UNION ALL, 2007-present)
|       |--> dbo.HistoryPosition_2007Q3 ... dbo.HistoryPosition_2022Q4 (62 quarterly archives)
|       |--> History.Position_Active (table - 2021+ primary archive)
|       |--> Trade.PositionTbl + Trade.PositionTreeInfo (recently closed, WHERE StatusID=2)
|       +--> History.PositionClosePartial (table - partial-close records)
+--> Trade.PositionOpenInDLT (table, cross-schema, LEFT JOIN - DLT position detection)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | View | Primary source - full closed-position history; all 124 columns |
| Trade.PositionOpenInDLT | Table (cross-schema) | LEFT JOIN for DLT position detection (DLTOpen computation) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ClosePositionEndOfDay | View | Reads from this view for end-of-day position reports |
| History.ClosePositionEndOfDay_Try | View | Experimental variant of ClosePositionEndOfDay |
| History.Position_DataFactory | View | Data factory position view built on top of this |
| dbo.AccountStatement_GetTransactionsReport_v10 | Stored Procedure | Latest account statement with DLT indicators |
| dbo.AccountStatement_GetUserStatementSummary | Stored Procedure | Account statement summary reports |
| dbo.AccountStatement_GetUserStatementSummary_v2 | Stored Procedure | v2 summary variant |
| dbo.AccountStatement_GetClosedPositionsReport_v2np | Stored Procedure | Closed positions report |
| dbo.AccountStatement_GetClosedPositionsReport_v3 | Stored Procedure | Closed positions report v3 |
| dbo.AccountStatement_BPGetTransactions_v2 | Stored Procedure | Business partner transactions |
| BackOffice.GetCustomerClosedPositions | Stored Procedure | Back-office position lookup |
| Trade.GetPositionDataForExternalUse | View (cross-schema) | Trade schema counterpart |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance inherited from History.Position sources. For CID-filtered queries, History.Position_Active's clustered index (CID, CloseOccurred) is the primary index. The LEFT JOIN to Trade.PositionOpenInDLT adds a per-row lookup for DLT detection; this JOIN is cheap for targeted queries but may impact full-scan performance.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get recent closed positions for a customer with DLT indicators

```sql
SELECT
    pfeu.PositionID,
    pfeu.InstrumentID,
    pfeu.IsBuy,
    pfeu.Amount,
    pfeu.NetProfit,
    pfeu.ActionType,
    pfeu.OpenOccurred,
    pfeu.CloseOccurred,
    pfeu.DLTOpen,
    pfeu.DLTClose,
    pfeu.CommissionVersion,
    pfeu.Commission,
    pfeu.OpenMarkup
FROM History.PositionForExternalUse pfeu WITH (NOLOCK)
WHERE pfeu.CID = 14952810
ORDER BY pfeu.CloseOccurred DESC
```

### 8.2 Find all DLT-opened positions during the pilot period

```sql
SELECT
    pfeu.PositionID,
    pfeu.CID,
    pfeu.InstrumentID,
    pfeu.OpenOccurred,
    pfeu.CloseOccurred,
    pfeu.HedgeServerID,
    pfeu.DLTOpen,
    pfeu.DLTClose,
    pfeu.OpenMarkup
FROM History.PositionForExternalUse pfeu WITH (NOLOCK)
WHERE pfeu.DLTOpen = 1
ORDER BY pfeu.OpenOccurred DESC
```

### 8.3 Account statement closed positions (pattern used by AccountStatement procedures)

```sql
SELECT
    pfeu.PositionID,
    pfeu.CID,
    pfeu.InstrumentID,
    pfeu.IsBuy,
    pfeu.Amount,
    pfeu.NetProfit,
    pfeu.Commission + pfeu.CommissionOnClose AS TotalCommission,
    pfeu.OpenMarkup + ISNULL(pfeu.CloseMarkup, 0) AS TotalMarkup,
    pfeu.OpenTotalFees + pfeu.CloseTotalFees AS TotalFees,
    pfeu.OpenOccurred,
    pfeu.CloseOccurred,
    pfeu.ActionType,
    pfeu.IsSettled,
    pfeu.CommissionVersion
FROM History.PositionForExternalUse pfeu WITH (NOLOCK)
WHERE pfeu.CID = @CustomerID
  AND pfeu.CloseOccurred >= @FromDate
  AND pfeu.CloseOccurred < @ToDate
ORDER BY pfeu.CloseOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 9.7/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 124 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 11) - live data blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 consumers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionForExternalUse | Type: View | Source: etoro/etoro/History/Views/History.PositionForExternalUse.sql*
