# Trade.ClosePositionsGetRecoveryItemsDemo

> Identifies demo copy-trade positions whose parent (leader) positions have been closed in history, pairing each child position's open data with the parent's close rates for MM recovery processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.GetPositionData) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.ClosePositionsGetRecoveryItemsDemo finds open **demo/copy-trade positions** that need to be closed because their parent (leader) position has already been closed. In eToro's CopyTrader system, when a leader closes a position, all copier positions linked to it should also be closed. If the close propagation fails (e.g., due to a timeout or service outage), these "orphaned" copier positions remain open. This view identifies them for recovery.

This view is essential for the Market Maker (MM) recovery flow. Without it, copier positions could remain open indefinitely after the leader has closed, creating incorrect exposure calculations, inaccurate PnL for the copier, and hedge mismatches. The recovery process uses this data to close the orphaned positions using the parent's close rates.

The view works by: (1) finding positions in Trade.Position whose ParentPositionID exists in RealHistoryPosition (closed parent), (2) filtering to active mirrors only (MirrorID=0 or active Mirror record), (3) excluding positions already flagged as failed recovery (History.MMLog FailTypeID=8), (4) joining to Trade.GetPositionData for full position details, and (5) appending the parent's close rate columns for close execution.

---

## 2. Business Logic

### 2.1 Orphaned Copier Detection

**What**: Identifies open positions whose parent has been closed in history.

**Columns/Parameters Involved**: `PositionID`, `ParentPositionID`, `MirrorID`, `ParentCID`

**Rules**:
- A position qualifies when its ParentPositionID matches a PositionID in RealHistoryPosition (closed)
- Mirror must be active: MirrorID=0 (manual) OR Mirror.IsActive=1
- Position must NOT have a History.MMLog entry with FailTypeID=8 (already failed recovery)

**Diagram**:
```
Trade.Position (open, has ParentPositionID)
    |
    +-- ParentPositionID --> RealHistoryPosition (closed parent)
    |                           |
    |                           +-- Parent close rates (EndForexRate, etc.)
    |
    +-- MirrorID --> Trade.Mirror (must be active or 0)
    |
    +-- NOT IN History.MMLog (FailTypeID=8)
    |
    +-- JOIN Trade.GetPositionData --> full position details
    |
    = Recovery item: child position data + parent close rates
```

### 2.2 Parent Close Rate Inheritance

**What**: Passes the parent's close rates to the recovery process so the child can be closed at the same rates.

**Columns/Parameters Involved**: `ParentCID`, `ParentLastOpPriceRate`, `ParentLastOpPriceRateID`, `ParentLastOpConversionRate`, `ParentLastOpConversionRateID`, `ParentEndForexRate`, `ParentEndForexPriceRateID`

**Rules**:
- Parent rates come from RealHistoryPosition (the closed parent record)
- These rates are used by the recovery procedure to close the copier position at consistent rates

---

## 3. Data Overview

View references RealHistoryPosition (EtoroArchive database) which is not accessible from the current MCP connection. When populated, each row represents an open copier position whose leader has closed, paired with the leader's close rates for recovery.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID of the copier (child position owner). From Trade.GetPositionData. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Copier's open position ID that needs recovery closure. From Trade.GetPositionData. |
| 3 | ForexResultID | bigint | YES | - | CODE-BACKED | Legacy forex result ID. From Trade.GetPositionData. |
| 4 | IsOpened | bit | YES | - | CODE-BACKED | Whether position is open. From Trade.GetPositionData. Always true in this context. |
| 5 | Currency | int | YES | - | CODE-BACKED | Denomination currency ID. From Trade.GetPositionData. |
| 6 | ProviderID | int | YES | - | CODE-BACKED | Execution provider. From Trade.GetPositionData. |
| 7 | InstrumentID | int | YES | - | CODE-BACKED | Instrument traded. From Trade.GetPositionData. |
| 8 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Hedge server managing this position. From Trade.GetPositionData. |
| 9 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier. From Trade.GetPositionData. |
| 10 | ForexBuy | int | YES | - | CODE-BACKED | Buy-side currency ID. From Trade.GetPositionData. |
| 11 | ForexSell | int | YES | - | CODE-BACKED | Sell-side currency ID. From Trade.GetPositionData. |
| 12 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at position open. From Trade.GetPositionData. |
| 13 | EndForexRate | float | YES | - | CODE-BACKED | End forex rate (NULL for open positions). From Trade.GetPositionData. |
| 14 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. From Trade.GetPositionData. |
| 15 | EndDateTime | datetime | YES | - | CODE-BACKED | When position was closed (NULL for open). From Trade.GetPositionData. |
| 16 | ActionType | int | YES | - | CODE-BACKED | Close action type. From Trade.GetPositionData. |
| 17 | NetProfit | money | YES | - | CODE-BACKED | Unrealized PnL. From Trade.GetPositionData. |
| 18 | LimitRate | float | YES | - | CODE-BACKED | Take-profit rate. From Trade.GetPositionData. |
| 19 | StopRate | float | YES | - | CODE-BACKED | Stop-loss rate. From Trade.GetPositionData. |
| 20 | Amount | money | YES | - | CODE-BACKED | Position amount in denomination currency. From Trade.GetPositionData. |
| 21 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position amount in units/shares. From Trade.GetPositionData. |
| 22 | Commission | money | YES | - | CODE-BACKED | Commission at open. From Trade.GetPositionData. |
| 23 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. From Trade.GetPositionData. |
| 24 | IsBuy | bit | YES | - | CODE-BACKED | Direction: 1=buy/long, 0=sell/short. From Trade.GetPositionData. |
| 25 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | Whether to close before weekend. From Trade.GetPositionData. |
| 26 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee. From Trade.GetPositionData. |
| 27 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. From Trade.GetPositionData. |
| 28 | AdditionalParam | varchar | YES | - | CODE-BACKED | Additional parameters. From Trade.GetPositionData. |
| 29 | OpenOccurred | datetime | YES | - | CODE-BACKED | When open was executed. From Trade.GetPositionData. |
| 30 | CloseOccurred | datetime | YES | - | CODE-BACKED | When close was executed (NULL for open). From Trade.GetPositionData. |
| 31 | OrderID | int | YES | - | CODE-BACKED | Originating order. From Trade.GetPositionData. |
| 32 | TradeRange | float | YES | - | CODE-BACKED | Market range tolerance. From Trade.GetPositionData. |
| 33 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at open. From Trade.GetPositionData. |
| 34 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position ID (the closed leader). From Trade.GetPositionData. Key for the recovery logic. |
| 35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before splits. From Trade.GetPositionData. |
| 36 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation price rate for the child. From Trade.GetPositionData. |
| 37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Snapshot ID for child's last op price. From Trade.GetPositionData. |
| 38 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation conversion rate for child. From Trade.GetPositionData. |
| 39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Snapshot ID for child's last op conversion. From Trade.GetPositionData. |
| 40 | UnitMargin | money | YES | - | CODE-BACKED | Unit margin. From Trade.GetPositionData. |
| 41 | Units | decimal | YES | - | CODE-BACKED | Number of units. From Trade.GetPositionData. |
| 42 | InstrumentPrecision | int | YES | - | CODE-BACKED | Instrument decimal precision. From Trade.GetPositionData. |
| 43 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. 0=manual. From Trade.GetPositionData. |
| 44 | PositionRatio | decimal | YES | - | CODE-BACKED | Copy ratio relative to leader. From Trade.GetPositionData. |
| 45 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Aggregated lot count. From Trade.GetPositionData. |
| 46 | SpreadGroupID | int | YES | - | CODE-BACKED | Spread group assignment. From Trade.GetPositionData. |
| 47 | InitialAmountCents | int | YES | - | CODE-BACKED | Initial amount in cents. From Trade.GetPositionData. |
| 48 | ParentCID | int | YES | - | CODE-BACKED | Customer ID of the parent (leader). From RealHistoryPosition. Identifies who the copier was following. |
| 49 | ParentLastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Parent's last operation price rate at close. From RealHistoryPosition. Used to close child at consistent rate. |
| 50 | ParentLastOpPriceRateID | bigint | YES | - | CODE-BACKED | Parent's last op price rate snapshot ID. From RealHistoryPosition. |
| 51 | ParentLastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Parent's last operation conversion rate at close. From RealHistoryPosition. |
| 52 | ParentLastOpConversionRateID | bigint | YES | - | CODE-BACKED | Parent's last op conversion rate snapshot ID. From RealHistoryPosition. |
| 53 | ParentEndForexRate | float | YES | - | CODE-BACKED | Parent's end forex rate at close. From RealHistoryPosition. |
| 54 | ParentEndForexPriceRateID | bigint | YES | - | CODE-BACKED | Parent's end forex price rate snapshot ID. From RealHistoryPosition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position | JOIN | Open copier positions |
| ParentPositionID | RealHistoryPosition | JOIN | Closed parent positions (via synonym to archive) |
| MirrorID | Trade.Mirror | LEFT JOIN | Mirror/copy-trade relationship validation |
| PositionID | History.MMLog | NOT EXISTS | Excludes already-failed recovery items (FailTypeID=8) |
| PositionID | Trade.GetPositionData | JOIN | Full position data for output |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No direct consumers found) | - | - | Likely consumed by MM recovery orchestration procedures not in Trade schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ClosePositionsGetRecoveryItemsDemo (view)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.GetPositionData (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.Mirror (table)
+-- RealHistoryPosition (synonym - archive)
+-- History.MMLog (x-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Source of open positions with ParentPositionID for matching |
| Trade.GetPositionData | View | Full position data for output columns |
| Trade.Mirror | Table | Validates mirror is active for copy-trade positions |
| RealHistoryPosition | Synonym | Closed parent positions from archive |
| History.MMLog | Table | Exclusion filter for already-failed recovery (FailTypeID=8) |

### 6.2 Objects That Depend On This

No direct dependents found in the Trade schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All recovery items pending

```sql
SELECT PositionID, CID, InstrumentID, ParentCID, ParentPositionID, Amount
FROM   Trade.ClosePositionsGetRecoveryItemsDemo WITH (NOLOCK);
```

### 8.2 Recovery items with parent close rates

```sql
SELECT PositionID, CID, ParentCID,
       ParentEndForexRate, ParentLastOpPriceRate, ParentLastOpConversionRate
FROM   Trade.ClosePositionsGetRecoveryItemsDemo WITH (NOLOCK)
WHERE  MirrorID > 0;
```

### 8.3 Count recovery items by instrument

```sql
SELECT InstrumentID, COUNT(*) AS RecoveryCount
FROM   Trade.ClosePositionsGetRecoveryItemsDemo WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY RecoveryCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 54 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ClosePositionsGetRecoveryItemsDemo | Type: View | Source: etoro/etoro/Trade/Views/Trade.ClosePositionsGetRecoveryItemsDemo.sql*
