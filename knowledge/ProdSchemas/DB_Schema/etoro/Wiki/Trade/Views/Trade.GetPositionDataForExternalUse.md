# Trade.GetPositionDataForExternalUse

> Unified position view that combines open positions (from Trade.PositionForExternalUseWithPnL) and closed positions (from History.PositionForExternalUse) into a single schema for external consumption, back-office reporting, tax reports, and redeem validation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Active / core infrastructure view |

---

## 1. Business Meaning

Trade.GetPositionDataForExternalUse is the **universal position view** that unifies open and closed positions into a single result set. It uses `UNION ALL` to combine:

1. **Open positions**: From `Trade.PositionForExternalUseWithPnL` joined with `Trade.Instrument`, `Trade.ProviderToInstrument`, `Trade.PositionTreeInfo`, and `Trade.Mirror`. These have `IsOpened = 1` and live PnL.
2. **Closed positions**: From `History.PositionForExternalUse` joined with `Trade.Instrument` and `Trade.ProviderToInstrument`. These have `IsOpened = 0` and historical PnL stored in `NetProfit`.

This view normalizes both halves into a ~95-column common schema, making it the go-to source for any consumer that needs to query "all positions" regardless of open/closed status. Key consumers include tax reporting, account statements, position history displays, and withdrawal validation.

---

## 2. Business Logic

### 2.1 Open vs Closed Column Mapping

**What**: Several columns are sourced differently depending on position status.

**Rules**:
- **IsOpened**: 1 for open, 0 for closed
- **EndDateTime**: NULL for open, actual close time for closed
- **ActionType**: NULL for open, close action type for closed
- **NetProfit**: PnLInDollars (live) for open, NetProfit (stored) for closed
- **EndForexRate**: CurrentClosingRate (live) for open, EndForexRate (stored) for closed
- **EndConversionRate**: ConversionRate from PnL (live) for open, LastOpConversionRate for closed
- **IsBuy**: Cast as 'true'/'false' string (not bit) for external compatibility
- **CloseOnEndOfWeek**: Cast as 'true'/'false' string for external compatibility
- **IsMirrorActive**: ISNULL(TM.IsActive, 0) for open, always 0 for closed
- **SLManualVer**: From PositionTreeInfo for open, always -1 for closed
- **SettlementTypeID**: `ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint))` for open (backward compat)
- **UnitsBaseValueCents**: `ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents))` for open

### 2.2 Instrument Enrichment

**What**: Both halves join Trade.Instrument for ForexBuy/ForexSell and Trade.ProviderToInstrument for Unit/Precision.

**Rules**:
- `Trade.Instrument` provides BuyCurrencyID (as ForexBuy) and SellCurrencyID (as ForexSell)
- `Trade.ProviderToInstrument` provides Unit (as Units) and Precision (as InstrumentPrecision)
- Open positions additionally join `Trade.PositionTreeInfo` (for tree-level settings) and `Trade.Mirror` (for copy status)

---

## 3. Data Overview

Returns all open + all closed positions for any customer, with ~95 columns in a normalized schema.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. |
| 2 | PositionID | bigint | NO | - | VERIFIED | Unique position identifier. |
| 3 | ForexResultID | bigint | YES | - | VERIFIED | Forex result reference. |
| 4 | IsOpened | int | NO | - | CODE-BACKED | 1=open (live PnL), 0=closed (historical). |
| 5 | Currency | int | NO | - | VERIFIED | Position reporting currency (CurrencyID). |
| 6 | ProviderID | int | NO | - | VERIFIED | Liquidity provider. |
| 7 | InstrumentID | int | NO | - | VERIFIED | Trading instrument. |
| 8 | PositionHedgeServerID | int | YES | - | VERIFIED | Hedge server for position routing. |
| 9 | Leverage | int | YES | - | VERIFIED | Position leverage multiplier. |
| 10 | ForexBuy | int | YES | - | CODE-BACKED | Buy currency from Instrument (BuyCurrencyID). |
| 11 | ForexSell | int | YES | - | CODE-BACKED | Sell currency from Instrument (SellCurrencyID). |
| 12 | InitForexRate | decimal | NO | - | VERIFIED | Opening execution rate. |
| 13 | EndForexRate | decimal | YES | - | CODE-BACKED | Live closing rate (open) or final rate (closed). |
| 14 | InitDateTime | datetime | NO | - | VERIFIED | Position open timestamp. |
| 15 | EndDateTime | datetime | YES | - | CODE-BACKED | NULL (open) or close timestamp (closed). |
| 16 | ActionType | int | YES | - | CODE-BACKED | NULL (open) or close action (closed). |
| 17 | NetProfit | money | YES | - | CODE-BACKED | Live PnLInDollars (open) or stored NetProfit (closed). |
| 18 | LimitRate | decimal | YES | - | VERIFIED | Take-profit rate. |
| 19 | StopRate | decimal | YES | - | VERIFIED | Stop-loss rate. |
| 20 | Amount | money | YES | - | VERIFIED | Position amount in base currency. |
| 21 | AmountInUnitsDecimal | decimal | YES | - | VERIFIED | Position size in units. |
| 22 | Commission | money | YES | - | VERIFIED | Open commission. |
| 23 | SpreadedCommission | money | YES | - | VERIFIED | Commission with spread. |
| 24 | IsBuy | varchar | NO | - | CODE-BACKED | 'true'/'false' string (not bit). |
| 25 | CloseOnEndOfWeek | varchar | YES | - | CODE-BACKED | 'true'/'false' string. |
| 26 | EndOfWeekFee | money | YES | - | VERIFIED | Weekend/overnight fee. |
| 27 | LotCountDecimal | decimal | YES | - | VERIFIED | Position size in lots. |
| 28 | AdditionalParam | nvarchar | YES | - | VERIFIED | Extra parameters (NULL for closed). |
| 29 | OpenOccurred | datetime | YES | - | VERIFIED | Open operation occurred timestamp. |
| 30 | CloseOccurred | datetime | YES | - | CODE-BACKED | NULL (open) or close occurred (closed). |
| 31 | OrderID | bigint | YES | - | VERIFIED | Associated order ID. |
| 32 | TradeRange | decimal | YES | - | VERIFIED | Trade execution range. |
| 33 | InitForexPriceRateID | bigint | YES | - | VERIFIED | PriceRateID at open. |
| 34 | ParentPositionID | bigint | YES | - | VERIFIED | Parent position (for partial closes). |
| 35 | OrigParentPositionID | bigint | YES | - | VERIFIED | Original parent (for chain tracking). |
| 36 | LastOpPriceRate | decimal | YES | - | VERIFIED | Last operation's price rate. |
| 37 | LastOpPriceRateID | bigint | YES | - | VERIFIED | Last operation's PriceRateID. |
| 38 | LastOpConversionRate | money | YES | - | VERIFIED | Last operation's conversion rate. |
| 39 | LastOpConversionRateID | bigint | YES | - | VERIFIED | Last operation's conversion PriceRateID. |
| 40 | UnitMargin | money | YES | - | VERIFIED | Margin per unit. |
| 41 | Units | decimal | YES | - | CODE-BACKED | Instrument unit from ProviderToInstrument. |
| 42 | InstrumentPrecision | int | YES | - | CODE-BACKED | Instrument precision from ProviderToInstrument. |
| 43 | MirrorID | bigint | YES | - | VERIFIED | Copy trading mirror ID. |
| 44 | PositionRatio | decimal | YES | - | VERIFIED | Copy ratio. |
| 45 | DirectAggLotCount | decimal | YES | - | VERIFIED | Direct aggregate lot count. |
| 46 | SpreadGroupID | int | YES | - | VERIFIED | Spread group assignment. |
| 47 | InitialAmountCents | bigint | YES | - | VERIFIED | Original investment in cents. |
| 48 | HedgeServerID | int | YES | - | VERIFIED | Hedge server. |
| 49 | InitExecutionID | bigint | YES | - | VERIFIED | Open execution ID. |
| 50 | EndExecutionID | bigint | NO | - | CODE-BACKED | 0 (open) or actual (closed). |
| 51 | RootHedgeServerID | int | YES | - | VERIFIED | Root hedge server. |
| 52 | IsOpenOpen | bit | YES | - | VERIFIED | Open-open flag. |
| 53 | TreeID | bigint | YES | - | VERIFIED | Position tree ID. |
| 54 | IsComputeForHedge | bit | YES | - | VERIFIED | Include in hedge computation. |
| 55 | ExitOrderID | bigint | YES | - | CODE-BACKED | NULL (open) or exit order (closed). |
| 56 | IsTslEnabled | bit | YES | - | VERIFIED | Trailing stop loss enabled. |
| 57 | IsMirrorActive | bit | NO | - | CODE-BACKED | Is copy-from trader active. 0 for closed. |
| 58 | SLManualVer | int | NO | - | CODE-BACKED | SL manual version from TreeInfo. -1 for closed. |
| 59 | FullCommission | money | YES | - | VERIFIED | Full commission on open. |
| 60 | FullCommissionOnClose | money | YES | - | CODE-BACKED | NULL (open) or close commission (closed). |
| 61 | IsSettled | bit | YES | - | VERIFIED | Real stock (settled) flag. |
| 62 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type with backward compat fallback. |
| 63 | RedeemStatus | int | YES | - | VERIFIED | Redeem status code. |
| 64 | RedeemID | bigint | YES | - | CODE-BACKED | NULL (open) or redeem reference (closed). |
| 65 | CommissionOnClose | money | YES | - | CODE-BACKED | NULL (open) or close commission (closed). |
| 66 | EndForexPriceRateID | bigint | YES | - | CODE-BACKED | Current closing rate ID (open) or end rate ID (closed). |
| 67 | InitialUnits | decimal | YES | - | VERIFIED | Original unit count before partial closes. |
| 68 | OriginalPositionID | bigint | YES | - | CODE-BACKED | NULL (open) or original position (closed). |
| 69 | UnitsBaseValueCents | bigint | YES | - | CODE-BACKED | Base value with fallback to InitialAmountCents. |
| 70 | IsDiscounted | bit | YES | - | VERIFIED | Discounted instrument flag. |
| 71 | ReopenForPositionID | bigint | YES | - | VERIFIED | Reopened-from position reference. |
| 72 | PnLInDollars | money | YES | - | CODE-BACKED | Live PnL (open) or NetProfit (closed). |
| 73 | PnLVersion | int | YES | - | VERIFIED | PnL calculation version. |
| 74 | InitConversionRate | money | YES | - | VERIFIED | Conversion rate at open. |
| 75 | EndConversionRate | money | YES | - | CODE-BACKED | Live conversion (open) or LastOpConversionRate (closed). |
| 76 | OpenTotalTaxes | money | YES | - | VERIFIED | Total taxes on open. |
| 77 | OpenTotalFees | money | YES | - | VERIFIED | Total fees on open. |
| 78 | CloseTotalTaxes | money | NO | - | CODE-BACKED | 0 (open) or actual (closed). |
| 79 | CloseTotalFees | money | NO | - | CODE-BACKED | 0 (open) or actual (closed). |
| 80 | IsNoStopLoss | bit | YES | - | VERIFIED | SL disabled flag. |
| 81 | IsNoTakeProfit | bit | YES | - | VERIFIED | TP disabled flag. |
| 82 | DLTOpen | money | YES | - | VERIFIED | DLT open value. |
| 83 | DLTClose | money | YES | - | CODE-BACKED | NULL (open) or DLT close value (closed). |
| 84 | CloseMarkup | money | YES | - | VERIFIED | Close markup amount. |
| 85 | OpenMarkupByUnits | money | YES | - | VERIFIED | Open markup proportional to units. |
| 86 | CommissionByUnits | money | YES | - | VERIFIED | Commission proportional to units. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (open) | Trade.PositionForExternalUseWithPnL | INNER JOIN (NOLOCK) | Open positions with live PnL |
| (open) | Trade.Instrument | INNER JOIN (NOLOCK) | ForexBuy/ForexSell |
| (open) | Trade.ProviderToInstrument | INNER JOIN (NOLOCK) | Unit/Precision |
| (open) | Trade.PositionTreeInfo | INNER JOIN (NOLOCK) | Tree-level settings |
| (open) | Trade.Mirror | LEFT JOIN | Copy trading status |
| (closed) | History.PositionForExternalUse | INNER JOIN (NOLOCK) | Closed positions |
| (closed) | Trade.Instrument | INNER JOIN (NOLOCK) | ForexBuy/ForexSell |
| (closed) | Trade.ProviderToInstrument | INNER JOIN (NOLOCK) | Unit/Precision |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AccountStatement_GetTaxReport_v3 | Stored Procedure | Tax report data |
| BackOffice.AccountStatement_GetTaxReport_v2 | Stored Procedure | Tax report data |
| BackOffice.AllPositionsByCID_Lite | Stored Procedure | All positions display |
| BackOffice.GetAllPositionsByCID | Stored Procedure | All positions display |
| BackOffice.GetPNLVersion | Stored Procedure | PnL version check |
| Billing.GetRedeemValidationData | Stored Procedure | Withdrawal validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionDataForExternalUse (view)
+-- Trade.PositionForExternalUseWithPnL (view) [open positions]
|   +-- Trade.PositionForExternalUse (view)
|   +-- Trade.PnL (view)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.Mirror (table)
+-- History.PositionForExternalUse (table) [closed positions, cross-schema]
```

---

## 7. Technical Details

### 7.1 UNION ALL Pattern

The view uses UNION ALL (not UNION) between open and closed halves, which is correct since PositionIDs are unique and there's no overlap. NOLOCK hints are applied to all tables.

### 7.2 Performance

The open-positions half benefits from the partition-aligned join in PositionForExternalUseWithPnL. The closed-positions half queries History.PositionForExternalUse which may be very large. Consumers should always filter by CID.

---

## 8. Sample Queries

### 8.1 All positions for a customer
```sql
SELECT  PositionID, IsOpened, InstrumentID, IsBuy, Amount, NetProfit, InitDateTime, EndDateTime
FROM    Trade.GetPositionDataForExternalUse WITH (NOLOCK)
WHERE   CID = 12345
ORDER BY InitDateTime DESC;
```

### 8.2 Open positions only
```sql
SELECT  * FROM Trade.GetPositionDataForExternalUse WITH (NOLOCK)
WHERE   CID = 12345 AND IsOpened = 1;
```

### 8.3 Closed positions for tax reporting
```sql
SELECT  PositionID, InstrumentID, InitDateTime, EndDateTime, NetProfit, CloseTotalTaxes
FROM    Trade.GetPositionDataForExternalUse WITH (NOLOCK)
WHERE   CID = 12345 AND IsOpened = 0 AND EndDateTime >= '2025-01-01'
ORDER BY EndDateTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Core infrastructure view for unified position access.

---

*Generated: 2026-03-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 45 VERIFIED, 41 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 referencing | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionDataForExternalUse | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionDataForExternalUse.sql*
