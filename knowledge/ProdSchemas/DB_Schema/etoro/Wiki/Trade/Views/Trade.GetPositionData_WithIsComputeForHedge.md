# Trade.GetPositionData_WithIsComputeForHedge

> Variant of GetPositionData that passes through the actual IsComputeForHedge value for closed positions (from History.PositionSlim), with StatusID=1 filter on the open branch and no partition-aligned PositionTreeInfo JOIN.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionTbl / History.PositionSlim) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetPositionData_WithIsComputeForHedge is a **variant of Trade.GetPositionData** designed for hedge-exposure-aware queries. Its key distinction is that the closed-position branch passes through the actual `IsComputeForHedge` value from `History.PositionSlim` (rather than hardcoding it to 0 as other variants do). This allows consumers to correctly assess whether a closed position was historically included in hedge exposure calculations.

This view uses `History.PositionSlim` (a lighter archive table) instead of the full `History.Position`, and has a slightly smaller column set than the base GetPositionData (no UnitsBaseValueCents, IsDiscounted, ReopenForPositionID, fee/tax columns, IsNoStopLoss, IsNoTakeProfit). The open branch applies `ISNULL(InitialUnits, AmountInUnitsDecimal) AS InitialUnits` as a computed fallback for legacy positions.

No stored procedures or other views in the current codebase reference this view. It may be accessed by external hedge calculation services or retained for backward compatibility.

---

## 2. Business Logic

### 2.1 True IsComputeForHedge Pass-Through

**What**: Unlike other GetPositionData variants that hardcode IsComputeForHedge=0 for closed positions, this view passes through the actual stored value.

**Columns/Parameters Involved**: `IsComputeForHedge`

**Rules**:
- Open branch: passes TPOS.IsComputeForHedge from Trade.PositionTbl.
- Closed branch: passes HPOS.IsComputeForHedge from History.PositionSlim (actual historical value).
- This enables accurate retrospective hedge exposure analysis that respects the original hedge inclusion flag.

### 2.2 InitialUnits Fallback (Open Branch)

**What**: Open-branch InitialUnits uses ISNULL fallback to AmountInUnitsDecimal.

**Columns/Parameters Involved**: `InitialUnits`, `AmountInUnitsDecimal`

**Rules**:
- Open branch: `ISNULL(InitialUnits, AmountInUnitsDecimal)` - for positions opened before InitialUnits was added, falls back to current unit count.
- Closed branch: passes through InitialUnits directly from History.PositionSlim.

---

## 3. Data Overview

N/A - no consumers reference this view. Output would be similar to Trade.GetPositionData but sourcing closed positions from History.PositionSlim and preserving IsComputeForHedge for closed rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID. References Customer.Customer. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. |
| 3 | ForexResultID | bigint | NO | - | CODE-BACKED | Deprecated. Set to -1 for new positions. |
| 4 | IsOpened | int | NO | - | CODE-BACKED | Computed: 1 = open (PositionTbl, StatusID=1), 0 = closed (History.PositionSlim). |
| 5 | Currency | int | NO | - | CODE-BACKED | Alias for CurrencyID. FK to Dictionary.Currency. |
| 6 | ProviderID | int | NO | - | CODE-BACKED | FK to Trade.Provider. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. JOIN key for forex pairs. |
| 8 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Alias for HedgeServerID. FK to Trade.HedgeServer. |
| 9 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier. |
| 10 | ForexBuy | int | YES | - | CODE-BACKED | From Trade.Instrument.BuyCurrencyID. |
| 11 | ForexSell | int | YES | - | CODE-BACKED | From Trade.Instrument.SellCurrencyID. |
| 12 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at open. |
| 13 | EndForexRate | float | YES | - | CODE-BACKED | Forex rate at close. NULL for open. |
| 14 | InitDateTime | datetime | YES | - | CODE-BACKED | Position open timestamp. |
| 15 | EndDateTime | datetime | YES | - | CODE-BACKED | Position close timestamp. NULL for open. |
| 16 | ActionType | tinyint | YES | - | CODE-BACKED | Close action type. NULL for open. FK to Dictionary.ClosePositionActionType. |
| 17 | NetProfit | money | YES | - | CODE-BACKED | Realized PnL. NULL for open. |
| 18 | LimitRate | float | YES | - | CODE-BACKED | Take-profit price from PositionTreeInfo (open) or History.PositionSlim (closed). |
| 19 | StopRate | float | YES | - | CODE-BACKED | Stop-loss price from PositionTreeInfo (open) or History.PositionSlim (closed). |
| 20 | Amount | money | NO | - | CODE-BACKED | Position size in denomination currency. |
| 21 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. |
| 22 | Commission | money | YES | - | CODE-BACKED | Open commission. |
| 23 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 24 | IsBuy | varchar | NO | - | CODE-BACKED | Computed: 'true' = buy/long, 'false' = sell/short. |
| 25 | CloseOnEndOfWeek | varchar | NO | - | CODE-BACKED | Computed: 'true' = weekend close, 'false' = stay open. |
| 26 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee. |
| 27 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. |
| 28 | AdditionalParam | nvarchar(max) | YES | - | CODE-BACKED | Free-form parameters. NULL for closed. |
| 29 | OpenOccurred | datetime | YES | - | CODE-BACKED | Open order execution timestamp. |
| 30 | CloseOccurred | datetime | YES | - | CODE-BACKED | Close order execution timestamp. NULL for open. |
| 31 | OrderID | int | YES | - | CODE-BACKED | FK to Trade.Orders. |
| 32 | TradeRange | int | YES | - | CODE-BACKED | Market range tolerance. |
| 33 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at open. |
| 34 | ParentPositionID | bigint | YES | - | CODE-BACKED | Copy-trade parent. 0/1 = root. |
| 35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before re-parenting. |
| 36 | LastOpPriceRate | float | YES | - | CODE-BACKED | Last operation's price rate. |
| 37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last operation price rate snapshot. |
| 38 | LastOpConversionRate | float | YES | - | CODE-BACKED | Last operation's forex conversion rate. |
| 39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last operation conversion rate snapshot. |
| 40 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Per-unit margin requirement. |
| 41 | Units | decimal(18,8) | YES | - | CODE-BACKED | From Trade.ProviderToInstrument.Unit. Standard lot size. |
| 42 | InstrumentPrecision | int | YES | - | CODE-BACKED | From Trade.ProviderToInstrument.Precision. |
| 43 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror. 0 = manual. FK to Trade.Mirror. |
| 44 | PositionRatio | decimal(16,8) | YES | - | CODE-BACKED | Copier allocation fraction. |
| 45 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Aggregated lot count for direct positions. |
| 46 | SpreadGroupID | int | YES | - | CODE-BACKED | FK to Trade.SpreadGroup. |
| 47 | InitialAmountCents | int | YES | - | CODE-BACKED | Original investment in cents. |
| 48 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server ID. |
| 49 | InitExecutionID | uniqueidentifier | YES | - | CODE-BACKED | Open execution correlation ID. |
| 50 | EndExecutionID | uniqueidentifier | YES | - | CODE-BACKED | Close execution correlation ID. 0 for open. |
| 51 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root position's hedge server. |
| 52 | IsOpenOpen | bit | YES | - | CODE-BACKED | 1 = async open-open flow. |
| 53 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree ID. Links to Trade.PositionTreeInfo. |
| 54 | IsComputeForHedge | bit | YES | - | CODE-BACKED | **KEY DIFFERENTIATOR**: Both branches pass through actual value (not hardcoded). 1 = included in hedge exposure, 0 = excluded. |
| 55 | ExitOrderID | int | YES | - | CODE-BACKED | Close order FK. NULL for open. |
| 56 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | 1 = trailing stop active, 0 = fixed. |
| 57 | IsMirrorActive | bit | NO | - | CODE-BACKED | Open: from Trade.Mirror. Closed: hardcoded 0. |
| 58 | SLManualVer | smallint | NO | - | CODE-BACKED | SL edit version. Open: from PositionTreeInfo. Closed: hardcoded -1. |
| 59 | FullCommission | money | YES | - | CODE-BACKED | Total commission. |
| 60 | FullCommissionOnClose | money | YES | - | CODE-BACKED | Close commission. NULL for open. |
| 61 | IsSettled | bit | YES | - | CODE-BACKED | Legacy: 1 = real stock, 0 = CFD. |
| 62 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Open: ISNULL fallback from IsSettled. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. (Dictionary.SettlementTypes) |
| 63 | RedeemStatus | tinyint | YES | - | CODE-BACKED | Redemption state. |
| 64 | RedeemID | bigint | YES | - | CODE-BACKED | Redemption operation ID. NULL for open. |
| 65 | CommissionOnClose | money | YES | - | CODE-BACKED | Close commission. NULL for open. |
| 66 | EndForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at close. NULL for open. |
| 67 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | Open: ISNULL(InitialUnits, AmountInUnitsDecimal) fallback. Closed: direct from History.PositionSlim. |
| 68 | OriginalPositionID | bigint | YES | - | CODE-BACKED | For reopened positions. NULL for open. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (open branch) | Trade.PositionTbl | Base Table | Open positions (StatusID=1). |
| (closed branch) | History.PositionSlim | Base Table | Closed positions from slim archive. |
| InstrumentID | Trade.Instrument | JOIN | Provides ForexBuy, ForexSell. |
| ProviderID + InstrumentID | Trade.ProviderToInstrument | JOIN | Provides Units, InstrumentPrecision. |
| TreeID | Trade.PositionTreeInfo | JOIN | Provides SL/TP/TSL (no partition-aligned join). |
| MirrorID | Trade.Mirror | LEFT JOIN | Provides IsMirrorActive. |

### 5.2 Referenced By (other objects point to this)

No consumers found in the current codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionData_WithIsComputeForHedge (view)
+-- Trade.PositionTbl (table)
+-- History.PositionSlim (table, cross-database)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.Mirror (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Open positions (WHERE StatusID=1) |
| History.PositionSlim | Table | Closed positions (cross-database) |
| Trade.Instrument | Table | JOIN on InstrumentID |
| Trade.ProviderToInstrument | Table | JOIN on ProviderID + InstrumentID |
| Trade.PositionTreeInfo | Table | JOIN on TreeID (no partition alignment) |
| Trade.Mirror | Table | LEFT JOIN on MirrorID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Positions with hedge exposure flag preserved

```sql
SELECT PositionID, CID, InstrumentID, IsOpened, IsComputeForHedge, Amount
FROM Trade.GetPositionData_WithIsComputeForHedge WITH (NOLOCK)
WHERE CID = @CID
```

### 8.2 Historical hedge exposure analysis

```sql
SELECT PositionID, InstrumentID, Amount, IsComputeForHedge, InitDateTime, EndDateTime
FROM Trade.GetPositionData_WithIsComputeForHedge WITH (NOLOCK)
WHERE IsComputeForHedge = 1 AND IsOpened = 0
```

### 8.3 Compare open and closed positions for an instrument

```sql
SELECT IsOpened, COUNT(*) AS PositionCount, SUM(Amount) AS TotalAmount
FROM Trade.GetPositionData_WithIsComputeForHedge WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
GROUP BY IsOpened
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 68 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionData_WithIsComputeForHedge | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionData_WithIsComputeForHedge.sql*
