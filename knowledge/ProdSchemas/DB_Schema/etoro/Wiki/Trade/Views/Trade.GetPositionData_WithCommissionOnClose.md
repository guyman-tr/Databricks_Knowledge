# Trade.GetPositionData_WithCommissionOnClose

> Variant of GetPositionData that includes all PositionTbl rows (not just open) and exposes CommissionOnClose for closed positions from History.Position, with fewer output columns and no partition-aligned PositionTreeInfo JOIN.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionTbl / History.Position) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetPositionData_WithCommissionOnClose is a **variant of Trade.GetPositionData** that differs in three significant ways: (1) the open-positions branch does NOT filter `WHERE StatusID = 1`, meaning it includes ALL rows from Trade.PositionTbl (open and closed-but-not-yet-archived), (2) the closed branch hardcodes `IsComputeForHedge = 0` rather than passing through the actual value, and (3) it has a reduced column set (no EndForexPriceRateID, InitialUnits, OriginalPositionID, UnitsBaseValueCents, IsDiscounted, ReopenForPositionID, fee/tax columns, IsNoStopLoss, IsNoTakeProfit).

This view appears to be a **legacy or transitional variant** that was created to expose CommissionOnClose before the base GetPositionData view was updated with the full column set. It includes the `--with schemabinding` comment (commented out), suggesting early design exploration.

No stored procedures or other views in the current codebase reference this view. It exists only in the SSDT project (etoro and tradonomi databases). It may be retained for backward compatibility or external consumer access.

---

## 2. Business Logic

### 2.1 No StatusID Filter on Open Branch

**What**: Unlike GetPositionData (which filters StatusID=1), this variant returns ALL rows from PositionTbl regardless of status.

**Columns/Parameters Involved**: (implicit StatusID)

**Rules**:
- Open branch includes StatusID=1 (open) AND StatusID=2 (closed-but-not-archived). This means rows appear twice during the brief window between close and history archival: once from PositionTbl and once from History.Position.
- Consumers must be aware of potential duplicates during this window.

### 2.2 Hardcoded IsComputeForHedge for Closed

**What**: Closed positions always return IsComputeForHedge = 0.

**Columns/Parameters Involved**: `IsComputeForHedge`

**Rules**:
- Open branch: passes through TPOS.IsComputeForHedge (real value).
- Closed branch: hardcoded 0 (excludes all closed positions from hedge exposure). This differs from the base GetPositionData which passes through the actual value.

---

## 3. Data Overview

N/A - no consumers reference this view and the MCP cannot access History.Position (EtoroArchive). The open-branch output would be identical to Trade.GetPositionData for open positions, with additional closed-but-not-archived rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID. From Trade.PositionTbl or History.Position. References Customer.Customer. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier. Primary key in base tables. |
| 3 | ForexResultID | bigint | NO | - | CODE-BACKED | Deprecated. Set to -1 for new positions. Retained for backward compatibility. |
| 4 | IsOpened | int | NO | - | CODE-BACKED | Computed: 1 = from PositionTbl (includes all statuses), 0 = from History.Position. |
| 5 | Currency | int | NO | - | CODE-BACKED | Alias for CurrencyID. Denomination currency. FK to Dictionary.Currency. |
| 6 | ProviderID | int | NO | - | CODE-BACKED | Execution provider. FK to Trade.Provider. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument. FK to Trade.Instrument. JOIN key for forex pairs and precision. |
| 8 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Alias for HedgeServerID. FK to Trade.HedgeServer. |
| 9 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier (1, 2, 5, 10, etc.). |
| 10 | ForexBuy | int | YES | - | CODE-BACKED | From Trade.Instrument.BuyCurrencyID. Buy-side currency of instrument's forex pair. |
| 11 | ForexSell | int | YES | - | CODE-BACKED | From Trade.Instrument.SellCurrencyID. Sell-side currency of instrument's forex pair. |
| 12 | InitForexRate | float | YES | - | CODE-BACKED | Forex conversion rate at position open. |
| 13 | EndForexRate | float | YES | - | CODE-BACKED | Forex conversion rate at close. NULL for PositionTbl branch. |
| 14 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. |
| 15 | EndDateTime | datetime | YES | - | CODE-BACKED | When position was closed. NULL for PositionTbl branch. |
| 16 | ActionType | tinyint | YES | - | CODE-BACKED | Close action type. NULL for PositionTbl branch. FK to Dictionary.ClosePositionActionType. |
| 17 | NetProfit | money | YES | - | CODE-BACKED | Realized PnL. NULL for PositionTbl branch. |
| 18 | LimitRate | float | YES | - | CODE-BACKED | Take-profit price from PositionTreeInfo (PositionTbl branch) or History.Position. |
| 19 | StopRate | float | YES | - | CODE-BACKED | Stop-loss price from PositionTreeInfo (PositionTbl branch) or History.Position. |
| 20 | Amount | money | NO | - | CODE-BACKED | Position size in denomination currency. |
| 21 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. |
| 22 | Commission | money | YES | - | CODE-BACKED | Commission charged at open. |
| 23 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 24 | IsBuy | varchar | NO | - | CODE-BACKED | Computed: 'true' = buy/long, 'false' = sell/short. |
| 25 | CloseOnEndOfWeek | varchar | NO | - | CODE-BACKED | Computed: 'true' = close before weekend, 'false' = stay open. |
| 26 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee charged. |
| 27 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. |
| 28 | AdditionalParam | nvarchar(max) | YES | - | CODE-BACKED | Free-form additional parameters. NULL for closed branch. |
| 29 | OpenOccurred | datetime | YES | - | CODE-BACKED | Timestamp when open order executed. |
| 30 | CloseOccurred | datetime | YES | - | CODE-BACKED | Timestamp when close order executed. NULL for PositionTbl branch. |
| 31 | OrderID | int | YES | - | CODE-BACKED | FK to Trade.Orders. Originating order. |
| 32 | TradeRange | int | YES | - | CODE-BACKED | Market range tolerance at open. |
| 33 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot ID at open. |
| 34 | ParentPositionID | bigint | YES | - | CODE-BACKED | Copy-trade parent. 0/1 = root/manual. |
| 35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before re-parenting. |
| 36 | LastOpPriceRate | float | YES | - | CODE-BACKED | Last operation's price rate. |
| 37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot ID for last operation. |
| 38 | LastOpConversionRate | float | YES | - | CODE-BACKED | Last operation's forex conversion rate. |
| 39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Conversion rate snapshot ID for last operation. |
| 40 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Per-unit margin requirement. |
| 41 | Units | decimal(18,8) | YES | - | CODE-BACKED | From Trade.ProviderToInstrument.Unit. Instrument standard lot size. |
| 42 | InstrumentPrecision | int | YES | - | CODE-BACKED | From Trade.ProviderToInstrument.Precision. Decimal places for price display. |
| 43 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror relationship. 0 = manual. FK to Trade.Mirror. |
| 44 | PositionRatio | decimal(16,8) | YES | - | CODE-BACKED | Copier's allocation fraction. |
| 45 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Aggregated lot count for direct positions. |
| 46 | SpreadGroupID | int | YES | - | CODE-BACKED | FK to Trade.SpreadGroup. Spread tier. |
| 47 | InitialAmountCents | int | YES | - | CODE-BACKED | Original investment in cents. |
| 48 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server ID. |
| 49 | InitExecutionID | uniqueidentifier | YES | - | CODE-BACKED | Open execution correlation ID. |
| 50 | EndExecutionID | uniqueidentifier | YES | - | CODE-BACKED | Close execution correlation ID. 0 for PositionTbl branch. |
| 51 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root position's hedge server for copy-trade. |
| 52 | IsOpenOpen | bit | YES | - | CODE-BACKED | 1 = async open-open flow, 0 = synchronous. |
| 53 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree ID. Links to Trade.PositionTreeInfo. |
| 54 | IsComputeForHedge | bit | YES | - | CODE-BACKED | PositionTbl branch: actual value. History branch: hardcoded 0 (all closed excluded from hedge). |
| 55 | ExitOrderID | int | YES | - | CODE-BACKED | Close order FK. NULL for PositionTbl branch. |
| 56 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing stop-loss: 1 = active, 0 = fixed. |
| 57 | IsMirrorActive | bit | NO | - | CODE-BACKED | PositionTbl branch: live check from Trade.Mirror. History branch: hardcoded 0. |
| 58 | SLManualVer | smallint | NO | - | CODE-BACKED | SL manual edit version. PositionTbl: from PositionTreeInfo. History: hardcoded -1. |
| 59 | FullCommission | money | YES | - | CODE-BACKED | Total commission including all components. |
| 60 | FullCommissionOnClose | money | YES | - | CODE-BACKED | Commission at close. NULL for PositionTbl branch. |
| 61 | IsSettled | bit | YES | - | CODE-BACKED | Legacy: 1 = real stock, 0 = CFD. Fallback for SettlementTypeID. |
| 62 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement classification with ISNULL fallback on open branch. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. (Dictionary.SettlementTypes) |
| 63 | RedeemStatus | tinyint | YES | - | CODE-BACKED | Redemption state: 0=NotRedeemed, 1=RedeemPending, 2=Redeemed. |
| 64 | RedeemID | bigint | YES | - | CODE-BACKED | Redemption operation ID. NULL for PositionTbl branch. |
| 65 | CommissionOnClose | money | YES | - | CODE-BACKED | Close commission. NULL for PositionTbl branch. Populated from History.Position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (open branch) | Trade.PositionTbl | Base Table | ALL rows (no StatusID filter). |
| (closed branch) | History.Position | Base Table | Closed positions from archive. |
| InstrumentID | Trade.Instrument | JOIN | Provides ForexBuy, ForexSell. |
| ProviderID + InstrumentID | Trade.ProviderToInstrument | JOIN | Provides Units, InstrumentPrecision. |
| TreeID | Trade.PositionTreeInfo | JOIN | Provides LimitRate, StopRate, CloseOnEndOfWeek, IsTslEnabled, SLManualVer (no partition-aligned join). |
| MirrorID | Trade.Mirror | LEFT JOIN | Provides IsMirrorActive for PositionTbl branch. |

### 5.2 Referenced By (other objects point to this)

No consumers found in the current codebase. This view may be deprecated or accessed by external systems not in the SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionData_WithCommissionOnClose (view)
+-- Trade.PositionTbl (table)
+-- History.Position (table, cross-database)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.Mirror (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | INNER JOIN - all rows (no StatusID filter) |
| History.Position | Table | INNER JOIN - closed positions (cross-database) |
| Trade.Instrument | Table | INNER JOIN on InstrumentID |
| Trade.ProviderToInstrument | Table | INNER JOIN on ProviderID + InstrumentID |
| Trade.PositionTreeInfo | Table | INNER JOIN on TreeID (no partition alignment) |
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

### 8.1 Get position with commission breakdown

```sql
SELECT PositionID, CID, InstrumentID, Commission, FullCommission, CommissionOnClose, FullCommissionOnClose
FROM Trade.GetPositionData_WithCommissionOnClose WITH (NOLOCK)
WHERE CID = @CID
```

### 8.2 Compare open and closed commission for a position

```sql
SELECT PositionID, IsOpened, Commission, FullCommission, CommissionOnClose
FROM Trade.GetPositionData_WithCommissionOnClose WITH (NOLOCK)
WHERE PositionID = @PositionID
```

### 8.3 All positions for a customer with settlement type

```sql
SELECT PositionID, InstrumentID, IsOpened, SettlementTypeID, Amount, IsBuy,
       ds.Name AS SettlementTypeName
FROM Trade.GetPositionData_WithCommissionOnClose gpd WITH (NOLOCK)
LEFT JOIN Dictionary.SettlementTypes ds WITH (NOLOCK) ON gpd.SettlementTypeID = ds.SettlementTypeID
WHERE gpd.CID = @CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this variant view.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 65 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionData_WithCommissionOnClose | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionData_WithCommissionOnClose.sql*
