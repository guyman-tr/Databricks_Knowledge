# History.Hedge

> Archive table storing closed hedge positions from eToro's institutional hedging system - each row is a completed hedge trade migrated from Trade.Hedge at close time, capturing full lifecycle data (open rates, close rates, PnL, external broker identifiers) as an immutable permanent record.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | HedgeID (int, CLUSTERED PK - not IDENTITY) |
| **Partition** | No |
| **Indexes** | 4 (1 CLUSTERED PK + 3 NC: CloseOccurred, CurrencyID, TradeID) |

---

## 1. Business Meaning

This table is the permanent archive for closed hedge positions in eToro's institutional hedging system. eToro hedges its net customer exposure with liquidity providers (external brokers) by opening positions via hedge servers. When the hedge server closes one of those positions (either normally or due to a stop/limit event), `Trade.HedgeClose` migrates the completed hedge record from the active `Trade.Hedge` table into this table and deletes the live row. Each row here represents a single completed hedge trade: the instrument, direction, size, open/close rates, PnL, commissions, fees, and timestamps.

Without this table, the audit history of closed hedge positions would be lost - it would be impossible to reconcile hedge PnL, investigate failed hedges, or audit the positions that were covered by institutional counterparties. The table captures both eToro-internal data (HedgeServerID, InstrumentID, Leverage) and external broker data (TradeID, ParentTradeID, AccountID, OrderID) from the liquidity provider's trading platform, enabling cross-system reconciliation.

Data enters this table exclusively via `Trade.HedgeClose`, which executes atomically: INSERT into History.Hedge (from Trade.Hedge + Trade.HedgeRequest), UPDATE Trade.Position to reassign HedgeID, DELETE from Trade.Hedge. If the source row is not found, the failure is logged to `History.HedgeFail` instead. The table is currently empty in the accessed environment (0 rows), indicating hedging is either not active in this environment or hedge records are managed elsewhere.

---

## 2. Business Logic

### 2.1 Close-and-Archive Pattern

**What**: When a hedge position closes, its complete lifecycle record is atomically migrated from the active Trade.Hedge table into History.Hedge, and the live row is deleted.

**Columns/Parameters Involved**: `HedgeID`, `OpenOccurred`, `CloseOccurred`, `InitForexRate`, `EndForexRate`, `NetProfit`

**Rules**:
- `Trade.HedgeClose` performs: INSERT INTO History.Hedge (SELECT FROM Trade.Hedge + Trade.HedgeRequest) -> UPDATE Trade.Position SET HedgeID=@ReplaceHedgeID -> DELETE FROM Trade.Hedge - all in one transaction
- HedgeID is not an IDENTITY - it is inherited directly from Trade.Hedge (which in turn gets it from the global action ID sequence via Internal.GetActionID at hedge open)
- If the Trade.Hedge row for the given HedgeID is not found at close time, `Trade.HedgeClose` inserts into `History.HedgeFail` (FailTypeID=2, "request to close") instead of History.Hedge - this is the error fallback path
- After migration, Trade.Position rows previously linked to this HedgeID are repointed to @ReplaceHedgeID (the replacement hedge), maintaining coverage continuity
- CloseOccurred is auto-stamped via DEFAULT (getutcdate()) at INSERT time since it is not passed explicitly

**Diagram**:
```
Trade.HedgeClose(@HedgeID, @NetProfit, @EndForexRate, ...) called
         |
         v
SELECT FROM Trade.Hedge (open-time data) + Trade.HedgeRequest (close request data)
         |
         +-- Row found? YES ->
         |       INSERT INTO History.Hedge (all open + close data merged)
         |       UPDATE Trade.Position SET HedgeID = @ReplaceHedgeID
         |       DELETE FROM Trade.Hedge
         |       COMMIT
         |
         +-- Row found? NO ->
                 INSERT INTO History.HedgeFail (FailTypeID=2)
                 COMMIT (with RAISERROR 60004)
```

### 2.2 External Broker Identifier Chain

**What**: Multiple varchar(50) columns store the external broker's identifiers for the hedge trade, enabling cross-system reconciliation with the liquidity provider's platform.

**Columns/Parameters Involved**: `TradeID`, `ParentTradeID`, `AccountID`, `OrderID`

**Rules**:
- These four fields contain the hedge server's (external broker's) native identifiers, not eToro internal IDs
- `TradeID` is the primary external trade reference, indexed via `ix_HistoryHedge_TradeID` for lookup by broker trade ID
- `ParentTradeID` links to a parent trade if the hedge was split or derived from a larger position
- `AccountID` identifies the external trading account at the liquidity provider used for this hedge
- `OrderID` is the specific order ID within the external broker's system
- All four can be NULL if the external system did not provide these identifiers

### 2.3 Computed PnL Verification Column

**What**: A persisted-in-query computed column that independently calculates NetProfit from rates and direction, providing a database-side cross-check against the hedge server-reported NetProfit.

**Columns/Parameters Involved**: `DB_CalculatedNetProfit`, `InitForexRate`, `EndForexRate`, `IsBuy`, `InstrumentID`

**Rules**:
- Formula: `(EndForexRate - InitForexRate) * direction_multiplier * instrument_multiplier` where direction_multiplier = +1 if IsBuy=1 (long), -1 if IsBuy=0 (short)
- Instrument multiplier by InstrumentID:
  - IDs 1, 2, 3, 7: multiplier = 1.0 (direct quote pairs - e.g., EUR/USD, profit is in USD per unit)
  - IDs 4, 5, 6: multiplier = 1.0 / EndForexRate (inverse quote pairs - e.g., USD/JPY, profit must be converted back to USD)
- If EndForexRate = 0 (division guard): result = 0
- This is a non-PERSISTED computed column (recalculated on read) - stored in DDL as a formula, not precomputed
- Serves as an audit cross-check: comparing DB_CalculatedNetProfit to NetProfit reveals discrepancies between the DB-calculated and hedge server-reported PnL

**Diagram**:
```
Long position (IsBuy=1), EUR/USD (InstrumentID=1 or 2):
  DB_CalculatedNetProfit = (EndForexRate - InitForexRate) * 1 * 1
  Example: InitForexRate=1.08000, EndForexRate=1.09000 -> profit = +0.01000 per unit

Short position (IsBuy=0), USD/JPY (InstrumentID=4):
  DB_CalculatedNetProfit = (EndForexRate - InitForexRate) * -1 * (1/EndForexRate)
  Example: EndForexRate<InitForexRate on a short -> positive PnL
```

---

## 3. Data Overview

No data available - History.Hedge contains 0 rows in the current environment. The table structure is fully defined and `Trade.HedgeClose` is the active writer, but no hedge positions have been closed and archived in this environment. See Section 4 (Elements) for column meanings derived from code analysis.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeID | int | NO | - | CODE-BACKED | Primary key. The hedge position identifier, inherited from Trade.Hedge (and ultimately from Internal.GetActionID global action sequence). NOT an IDENTITY column. The same HedgeID exists in Trade.Hedge while the position is open; migrated here at close and deleted from Trade.Hedge. |
| 2 | CurrencyID | int | NO | - | CODE-BACKED | Settlement currency of the hedge position. FK to `Dictionary.Currency.CurrencyID` (WITH CHECK). Copied from Trade.Hedge.CurrencyID at close time. Indexed via `i_CureenyID` for filtering by currency. |
| 3 | ProviderID | int | NO | - | CODE-BACKED | Liquidity provider ID for this hedge. Part of the composite FK to `Trade.ProviderToInstrument(ProviderID, InstrumentID)` (WITH CHECK). Identifies which external counterparty executed this hedge. Copied from Trade.Hedge.ProviderID. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument (currency pair, stock, etc.) being hedged. Part of the composite FK to `Trade.ProviderToInstrument(ProviderID, InstrumentID)` (WITH CHECK). Also used in DB_CalculatedNetProfit to determine quote type (direct vs inverse). Copied from Trade.Hedge.InstrumentID. |
| 5 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server instance that managed this position. FK to `Trade.HedgeServer.HedgeServerID` (WITH CHECK). Identifies which server node opened and subsequently closed this hedge. Copied from Trade.Hedge.HedgeServerID. |
| 6 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier applied to this hedge position. Copied from Trade.Hedge.Leverage at close time. |
| 7 | Amount | money | NO | - | CODE-BACKED | Notional amount of the hedge position in the settlement currency. Set from `ISNULL(@Amount, Trade.Hedge.Amount)` - the caller can override with a new amount (used for partial close scenarios), otherwise the original amount is used. |
| 8 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Hedge position size expressed in instrument units as a decimal. Set from `ISNULL(@AmountInUnitsDecimal, Trade.Hedge.AmountInUnitsDecimal)` - overridable by caller. NULL if not populated at open time. |
| 9 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Hedge position size expressed in lots as a decimal. Set from `ISNULL(@LotCountDecimal, Trade.Hedge.LotCountDecimal)` - overridable by caller. NULL if not populated at open time. |
| 10 | InitForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate at which the hedge position was opened. Copied from Trade.Hedge.InitForexRate. Uses the `dbo.dtPrice` UDT (decimal precision rate type). Combined with EndForexRate in DB_CalculatedNetProfit to compute raw PnL. |
| 11 | InitDateTime | datetime | NO | - | CODE-BACKED | Timestamp when the hedge position was opened on the external broker's platform. Copied from Trade.Hedge.InitDateTime. Distinct from OpenOccurred (which is when the Trade.Hedge row was created in eToro's DB). |
| 12 | NetProfit | money | NO | - | CODE-BACKED | Net profit/loss of the hedge position as reported by the hedge server, in the settlement currency. Stored as `@NetProfit / 100` - the parameter is passed in cents but stored as money (dollars). Compare to DB_CalculatedNetProfit for reconciliation. |
| 13 | Commission | money | YES | - | CODE-BACKED | Commission charged by the liquidity provider on this hedge trade. Stored as `@Commission / 100` (cents to money conversion). NULL if not charged. |
| 14 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take-profit rate for the hedge position at the time it was opened. Copied from Trade.Hedge.LimitRate. Uses `dbo.dtPrice` UDT. |
| 15 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop-loss rate for the hedge position at the time it was opened. Copied from Trade.Hedge.StopRate. Uses `dbo.dtPrice` UDT. |
| 16 | IsBuy | bit | NO | - | CODE-BACKED | Direction of the hedge: 1 = buy/long (hedging net short customer exposure), 0 = sell/short (hedging net long customer exposure). Used in DB_CalculatedNetProfit with multiplier +1 (buy) or -1 (sell). Copied from Trade.Hedge.IsBuy. |
| 17 | TradeID | varchar(50) | YES | - | CODE-BACKED | The external liquidity provider's trade identifier for this hedge. Indexed via `ix_HistoryHedge_TradeID` for cross-system reconciliation lookups. Copied from Trade.Hedge.TradeID. NULL if not provided by the external system. |
| 18 | ParentTradeID | varchar(50) | YES | - | CODE-BACKED | The external broker's identifier for the parent trade, if this hedge was derived from or split from a larger position. Copied from Trade.Hedge.ParentTradeID. NULL for standalone hedges. |
| 19 | AccountID | varchar(50) | YES | - | CODE-BACKED | The trading account identifier at the external liquidity provider used for this hedge. Copied from Trade.Hedge.AccountID. NULL if not provided. |
| 20 | OrderID | varchar(50) | YES | - | CODE-BACKED | The specific order identifier in the external broker's system for this hedge trade. Copied from Trade.Hedge.OrderID. NULL if not provided. |
| 21 | EndForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate at which the hedge position was closed. Passed as @EndForexRate parameter to Trade.HedgeClose. Used in DB_CalculatedNetProfit as the closing rate. Uses `dbo.dtPrice` UDT. |
| 22 | RequestedEndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | The rate originally requested for closing this hedge (from Trade.HedgeRequest where RequestType=2). Copied from Trade.HedgeRequest.RequestedEndForexRate. NULL if no explicit close request rate was recorded. Uses `dbo.dtPrice` UDT. |
| 23 | EndDateTime | datetime | NO | getutcdate() | CODE-BACKED | Timestamp of the hedge close event. Passed as @EndDateTime parameter to Trade.HedgeClose. Defaults to GETUTCDATE() if not provided. Represents when the external broker closed the position. |
| 24 | ActionType | int | NO | - | CODE-BACKED | Type of close action that triggered this archive. Code comment in Trade.HedgeClose: `@ActionType INTEGER = 0 -- REGULAR CLOSE BY HEDGE SERVER`. Value 0 = regular close; other values represent stop-loss, take-profit, or administrative close types. |
| 25 | RequestOpenOccurred | datetime | YES | - | CODE-BACKED | Timestamp when eToro requested the hedge to be opened on the external broker. Copied from Trade.Hedge.RequestOccurred. NULL if no explicit open request was tracked. |
| 26 | RequestCloseOccurred | datetime | YES | - | CODE-BACKED | Timestamp when eToro requested the hedge to be closed. Copied from Trade.HedgeRequest.Occurred (where RequestType=2 = close request). NULL if no explicit close request was tracked. |
| 27 | OpenOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the Trade.Hedge row was created in eToro's database (i.e., when the hedge open was confirmed). Copied from Trade.Hedge.Occurred. Distinct from InitDateTime (external broker open time). |
| 28 | CloseOccurred | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when Trade.HedgeClose inserted this row into History.Hedge. Auto-set via DEFAULT (getutcdate()) at INSERT - not passed explicitly in the INSERT column list of Trade.HedgeClose. Indexed via `IX_History_Hedge_CloseOccurred` (PAGE compressed) for date-range queries on closed hedges. |
| 29 | Fee | money | YES | - | CODE-BACKED | Regulatory or processing fee charged on this hedge trade. Copied from Trade.Hedge.Fee. NULL if no fee was charged. |
| 30 | NfaFee | money | YES | - | CODE-BACKED | National Futures Association (NFA) regulatory fee, applicable to US-regulated instruments. Copied from Trade.Hedge.NfaFee. NULL for non-NFA instruments or environments where NFA fees are not charged. |
| 31 | OrigAmountInUnits | int | YES | - | CODE-BACKED | The original position size in integer units at the time the hedge was opened. Copied from Trade.Hedge.OrigAmountInUnits. NULL if not populated. Stored alongside the decimal AmountInUnitsDecimal to support legacy integer-precision systems. |
| 32 | FirstParentOpenOccured | datetime | YES | - | CODE-BACKED | Timestamp of the first parent hedge position's open event, for tracking roll-up or replacement hedge chains. Copied from Trade.Hedge.FirstParentOpenOccured (note typo: "Occured" not "Occurred" - matches Trade.Hedge column name). NULL for first-generation hedges. |
| 33 | Premium | money | YES | - | CODE-BACKED | Premium paid for option-style or structured hedge products. Copied from Trade.Hedge.Premium. NULL for standard spot hedges. |
| 34 | OpenCharge | money | YES | - | CODE-BACKED | Charge applied when the hedge position was opened (e.g., spread cost, open commission). Copied from Trade.Hedge.OpenCharge. NULL if no open charge was incurred. |
| 35 | CloseCharge | money | YES | - | CODE-BACKED | Charge applied when the hedge position was closed. Passed as @CloseCharge parameter to Trade.HedgeClose. NULL if no close charge was incurred. |
| 36 | LiquidityAccountID | int | YES | - | CODE-BACKED | Internal identifier for the liquidity account at the external provider used for this hedge. Copied from Trade.Hedge.LiquidityAccountID. NULL if not tracked for this hedge. |
| 37 | DB_CalculatedNetProfit | computed | YES | - | CODE-BACKED | Computed (non-persisted) PnL cross-check column. Formula: `(EndForexRate - InitForexRate) * (IsBuy=1 ? +1 : -1) * instrument_multiplier`, where InstrumentIDs 1,2,3,7 use multiplier=1 (direct pairs) and IDs 4,5,6 use multiplier=1/EndForexRate (inverse pairs). Returns 0 if EndForexRate=0. Use alongside NetProfit for reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | FK (WITH CHECK) | Settlement currency of the hedge. |
| HedgeServerID | Trade.HedgeServer | FK (WITH CHECK) | The hedge server that managed this position. |
| (ProviderID, InstrumentID) | Trade.ProviderToInstrument | FK (WITH CHECK) | Composite FK identifying the liquidity provider and instrument pair for this hedge. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeClose | INSERT | WRITER | Archives closed hedge positions here; the sole writer for this table |
| History.GetPosition | JOIN/reference | VIEW | Reads hedge archive to enrich position history with hedge data |
| History.GetPositionInfo | JOIN/reference | VIEW | Joins to History.Hedge for full position details including hedge info |
| Internal.GetHedgeCost | SELECT | FUNCTION | Reads closed hedge cost data for PnL calculations |
| Trade.GetHedgeCost | SELECT | READER | Returns hedge cost for a given hedge ID |
| Maintenance.PositionFix | SELECT/reference | READER | References closed hedge data during position reconciliation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Hedge (table)
- no code-level dependencies (leaf table)
```

This object has no code-level dependencies (it is a target table, not a view or procedure with FROM/JOIN logic).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FK target - CurrencyID references Dictionary.Currency.CurrencyID |
| Trade.HedgeServer | Table | FK target - HedgeServerID references Trade.HedgeServer.HedgeServerID |
| Trade.ProviderToInstrument | Table | FK target (composite) - (ProviderID, InstrumentID) references Trade.ProviderToInstrument |
| dbo.dtPrice | User Defined Type | InitForexRate, LimitRate, StopRate, EndForexRate, RequestedEndForexRate all use this UDT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeClose | Stored Procedure | WRITER - sole writer; archives hedge records at close time |
| History.GetPosition | View | READER - joins to History.Hedge for hedge-linked position history |
| History.GetPositionInfo | View | READER - enriches position data with hedge archive info |
| History.GetPositionForXML | View | READER - includes hedge archive data in XML position export |
| Internal.GetHedgeCost | Function | READER - computes hedge costs from closed records |
| Trade.GetHedgeCost | Stored Procedure | READER - retrieves hedge cost for a given HedgeID |
| Maintenance.PositionFix | Stored Procedure | READER - references hedge archive during position reconciliation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HHDG | CLUSTERED PK | HedgeID ASC | - | - | Active |
| IX_History_Hedge_CloseOccurred | NONCLUSTERED | CloseOccurred ASC | - | - | Active (PAGE compressed) |
| i_CureenyID | NONCLUSTERED | CurrencyID ASC | - | - | Active (note: index name has typo - "Cureeny" not "Currency") |
| ix_HistoryHedge_TradeID | NONCLUSTERED | TradeID ASC | - | - | Active |

Clustered PK uses FILLFACTOR=90 and DATA_COMPRESSION=PAGE. IX_History_Hedge_CloseOccurred also uses DATA_COMPRESSION=PAGE. The `i_CureenyID` index does not specify DATA_COMPRESSION, defaulting to NONE.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HHDG | PRIMARY KEY | CLUSTERED on HedgeID - uniqueness inherited from Trade.Hedge action ID |
| HHDG_ENDDATETIME | DEFAULT | EndDateTime = getutcdate() at INSERT |
| HHDG_CLOSEOCCURRED | DEFAULT | CloseOccurred = getutcdate() at INSERT |
| FK_DCUR_HHDG | FOREIGN KEY (WITH CHECK) | CurrencyID -> Dictionary.Currency(CurrencyID) |
| FK_THSV_HHDG | FOREIGN KEY (WITH CHECK) | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_TPVI_HHDG | FOREIGN KEY (WITH CHECK) | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument(ProviderID, InstrumentID) |

---

## 8. Sample Queries

### 8.1 Find all closed hedges for a specific instrument and date range

```sql
SELECT
    h.HedgeID,
    h.InstrumentID,
    h.IsBuy,
    h.Amount,
    h.InitForexRate,
    h.EndForexRate,
    h.NetProfit,
    h.DB_CalculatedNetProfit,
    h.ActionType,
    h.OpenOccurred,
    h.CloseOccurred
FROM History.Hedge h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
  AND h.CloseOccurred >= @StartDate
  AND h.CloseOccurred <  @EndDate
ORDER BY h.CloseOccurred DESC;
```

### 8.2 Reconcile hedge server PnL against DB-calculated PnL

```sql
SELECT
    h.HedgeID,
    h.TradeID,
    h.NetProfit AS ServerReportedPnL,
    h.DB_CalculatedNetProfit AS DBCalculatedPnL,
    h.NetProfit - h.DB_CalculatedNetProfit AS Discrepancy,
    h.InitForexRate,
    h.EndForexRate,
    h.IsBuy,
    h.InstrumentID
FROM History.Hedge h WITH (NOLOCK)
WHERE ABS(h.NetProfit - ISNULL(h.DB_CalculatedNetProfit, 0)) > 0.001
ORDER BY ABS(h.NetProfit - ISNULL(h.DB_CalculatedNetProfit, 0)) DESC;
```

### 8.3 Lookup a closed hedge by external broker TradeID

```sql
SELECT
    h.HedgeID,
    h.TradeID,
    h.ParentTradeID,
    h.AccountID,
    h.OrderID,
    dc.Name AS Currency,
    h.Amount,
    h.NetProfit,
    h.OpenOccurred,
    h.CloseOccurred,
    h.ActionType
FROM History.Hedge h WITH (NOLOCK)
JOIN Dictionary.Currency dc WITH (NOLOCK) ON h.CurrencyID = dc.CurrencyID
WHERE h.TradeID = @ExternalTradeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 37 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Hedge | Type: Table | Source: etoro/etoro/History/Tables/History.Hedge.sql*
