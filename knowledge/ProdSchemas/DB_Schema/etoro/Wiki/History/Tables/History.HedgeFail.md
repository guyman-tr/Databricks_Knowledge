# History.HedgeFail

> Append-only error log recording every failed hedge operation - open requests, close requests, opens, closes, edits, and system-level failures - capturing the full context of the failed trade at the moment of failure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PK_HHFL: CLUSTERED on HedgeFailID (IDENTITY int) |
| **Partition** | No (stored on [HISTORY] filegroup) |
| **Indexes** | 2 (CLUSTERED PK on HedgeFailID, NONCLUSTERED on HedgeID) |

---

## 1. Business Meaning

This table is eToro's hedging engine failure audit log. Unlike SQL Server temporal tables (which track row-level changes), `History.HedgeFail` is a purpose-built append-only error store: every time a hedge operation fails - whether opening a position with a liquidity provider, closing one, responding to a request, or an internal validation failure - one row is inserted here capturing the full context of the failure.

The hedging engine routes eToro customer positions to external liquidity providers via the FIX protocol. When those operations fail, `History.HedgeFailInfo` (the primary writer) captures the failed hedge's full state snapshot: what instrument and provider were involved, what the position parameters were (amount, leverage, rates), what FIX identifiers were assigned, and why it failed (both a structured `FailTypeID` from `Dictionary.FailType` and a free-text `FailReason`).

**Note**: This table is in the History schema by convention (audit/log data) but is NOT a SQL Server system-versioned temporal table. It is a standalone log table with no corresponding source temporal table.

0 rows in this environment - hedge failures only occur in live trading operations.

---

## 2. Business Logic

### 2.1 Hedge Failure Capture

**What**: When any hedge operation fails at any stage in its lifecycle, a row is inserted here to record the failure.

**Columns/Parameters Involved**: `HedgeID`, `FailTypeID`, `FailReason`, `FailOccurred`, `FailReasonID`

**Rules**:
- `FailTypeID` classifies the stage at which the failure occurred (see FailType values below)
- `FailReason` is a free-text human-readable description of the failure (varchar(max)) - may be system-generated ("Cannot find corresponding request") or an error message from the liquidity provider
- `FailOccurred` defaults to GETDATE() (local server time, not UTC) - the precise moment of failure
- `FailReasonID` provides a structured reason code from `Dictionary.HedgePositionFailReason` (24 codes including severity): e.g., 0=Unknown error (severity 6), 1=Market closed (severity 5), 2=Slippage breached (severity 5), 3=Liquidity breached (severity 5), 4=Insufficient margin (severity 5)

**FailType Values** (Dictionary.FailType, 17 types):

| FailTypeID | Name | Meaning |
|---|---|---|
| 1 | Request To Open | Failed at the request-to-open stage (before the open attempt) |
| 2 | Request To Close | Failed at the request-to-close stage (before the close attempt) |
| 3 | Open | Failed during the actual open attempt with the liquidity provider |
| 4 | Close | Failed during the actual close attempt |
| 5 | Edit | Failed during a position edit (e.g., stop loss modification) |
| 6 | External Error | Error returned by the external liquidity provider |
| 7 | Internal Error | Internal system error in the hedging engine |
| 8 | MM object disconnected from its parent | Market-making object hierarchy disconnect |
| 9 | MM Max StopLoss | Market-making maximum stop-loss threshold exceeded |
| 10 | Min Position Amount | Position amount below the minimum allowed |
| 11 | Mirror edit StopLoss insufficient funds | CopyTrader mirror stop-loss edit failed due to insufficient funds |
| 12 | Max position amount in units | Position unit count exceeds the maximum |
| 13 | Max Take Profit reached | Take-profit limit reached, position cannot be modified |
| 14 | PositionRedeemCancelFail | Position redeem cancel operation failed |
| 15 | PositionRedeemPendingFail | Position redeem pending state failure |
| 16 | PositionRedeemCloseFail | Position redeem close operation failed |
| 17 | Detach | Detach operation failed (e.g., mirror detach from parent) |

### 2.2 Position State Snapshot at Failure

**What**: The row captures the full state of the hedge position at the time of failure, including both what was requested and what the provider returned.

**Columns/Parameters Involved**: `Amount`, `AmountInUnitsDecimal`, `LotCountDecimal`, `InitForexRate`, `EndForexRate`, `RequestedEndForexRate`, `LimitRate`, `StopRate`, `IsBuy`, `Leverage`, `NetProfit`, `Commission`

**Rules**:
- `InitForexRate`: the opening rate at which the position was opened (dbo.dtPrice UDT)
- `EndForexRate`: the actual closing rate received from the provider
- `RequestedEndForexRate`: the rate that was requested for close (may differ from EndForexRate due to slippage)
- `LimitRate` / `StopRate`: take-profit and stop-loss rates configured on the position
- `NetProfit` / `Commission`: stored in actual currency units (the callers divide their cents-denominated values by 100 before INSERT)
- `AmountInUnitsDecimal` / `LotCountDecimal`: precise unit and lot quantities (decimal(16,6)) vs `Amount` (money, rounded)
- `IsBuy`: true=long position, false=short position

### 2.3 FIX Protocol Identifiers

**What**: When the failure occurs after FIX communication has begun, the FIX protocol trade identifiers are captured.

**Columns/Parameters Involved**: `TradeID`, `ParentTradeID`, `AccountID`, `OrderID`

**Rules**:
- `TradeID` / `ParentTradeID`: FIX ExecID and parent chain identifier for the trade
- `AccountID`: the liquidity provider's account identifier (FIX Account field)
- `OrderID`: the FIX ClOrdID or OrderID from the provider
- All four are varchar(50) and nullable - not populated by the main `History.HedgeFailInfo` procedure (those columns are commented out in that procedure's INSERT). They are populated by direct INSERTs from `Trade.HedgeOpen` in specific failure cases.

### 2.4 Write Path: Primary vs. Direct Insert

**What**: Two distinct write paths exist for this table.

**Rules**:
- **Primary path**: `History.HedgeFailInfo` is called by multiple hedge operation procedures when a failure occurs. It resolves `LiquidityAccountID` from `Hedge.HedgeServerToLiquidityAccount` using `@HedgeServerID`, then inserts all columns except the four FIX identifier columns (commented out in the procedure)
- **Direct path**: `Trade.HedgeOpen` (and likely other Trade SPs) directly INSERT into this table for specific well-known failure cases, populating the FIX identifier columns that the main procedure omits. Example: FailTypeID=3 (Open), FailReasonID=17 with FailReason='Cannot find corresponding request' when Trade.HedgeRequest has no matching record

---

## 3. Data Overview

| Scale | Value |
|-------|-------|
| Total rows | 0 (dev/test environment - no live trading) |
| Date range | N/A |
| Filegroup | [HISTORY] |

In production, this table accumulates hedge failure events over time with no TTL or cleanup. It serves as the permanent audit trail for hedging operation failures.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeFailID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-incrementing. NOT FOR REPLICATION prevents identity re-seeding during replication. One row per hedge failure event. |
| 2 | HedgeID | int | NO | - | CODE-BACKED | ID of the hedge position that failed. FK to Trade.Hedge or History.Hedge (the hedge may have been archived by the time this is queried). NONCLUSTERED index (HHFL_CURRENCY) on this column for efficient lookup of all failures for a specific hedge. |
| 3 | FailTypeID | int | NO | - | VERIFIED | Stage and type of failure. FK to Dictionary.FailType. 1=Request To Open, 2=Request To Close, 3=Open, 4=Close, 5=Edit, 6=External Error, 7=Internal Error, 8-17=specialized failure types. |
| 4 | CurrencyID | int | YES | - | CODE-BACKED | Currency denomination of the hedge position. Implicit FK to Dictionary.Currency (e.g., 1=USD). NULL when failure occurs before currency context is established. |
| 5 | ProviderID | int | YES | - | CODE-BACKED | The liquidity provider involved in the failed operation. Implicit FK to Trade.Provider. NULL when failure is purely internal (no provider communication attempted). |
| 6 | InstrumentID | int | YES | - | CODE-BACKED | The financial instrument of the hedge position. Implicit FK to Trade.Instrument. NULL in certain failure paths where instrument context is unavailable. |
| 7 | HedgeServerID | int | YES | - | CODE-BACKED | The hedging server that attempted the operation. Implicit FK to Hedge.HedgeServer. Used to resolve LiquidityAccountID in History.HedgeFailInfo. NULL if server context unavailable. |
| 8 | Leverage | int | YES | - | CODE-BACKED | The leverage multiplier configured on the failed hedge position. NULL when not applicable to the failure type. |
| 9 | Amount | money | YES | - | CODE-BACKED | The capital amount of the position in the position's currency. NULL when the failure occurs before amount is committed. |
| 10 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | The position size expressed in underlying asset units (e.g., barrels, shares, ounces). Higher precision than Amount. NULL when unit count is not relevant to the failure. |
| 11 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | The position size in standard lots. Lot sizes vary by instrument and provider convention. NULL when not applicable. |
| 12 | NetProfit | money | YES | - | CODE-BACKED | The unrealized or realized P&L at the time of failure, in actual currency units (callers divide their cents-denominated values by 100 before insert). NULL when no P&L is available at the time of failure. |
| 13 | Commission | money | YES | - | CODE-BACKED | Commission charged or accrued on the position at the time of failure. Same cents-to-dollars division applies. NULL when no commission context. |
| 14 | InitForexRate | dbo.dtPrice | YES | - | CODE-BACKED | The forex/instrument rate at which the position was opened (the initial entry price). dbo.dtPrice UDT. NULL for failures at the request stage (before open). |
| 15 | InitDateTime | datetime | YES | - | CODE-BACKED | The UTC datetime when the hedge position was originally opened. NULL for failures at the request stage. |
| 16 | LimitRate | dbo.dtPrice | YES | - | CODE-BACKED | The take-profit rate configured on the position. NULL if not set or not relevant to the failure. |
| 17 | StopRate | dbo.dtPrice | YES | - | CODE-BACKED | The stop-loss rate configured on the position. NULL if not set or not relevant to the failure. |
| 18 | IsBuy | bit | YES | - | CODE-BACKED | Trade direction: 1=long (buy), 0=short (sell). NULL when direction is not applicable to the failure type. |
| 19 | EndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | The actual rate received from the liquidity provider for close/exit. For open failures, this is the rate that was attempted. dbo.dtPrice UDT. NULL for non-close failures. |
| 20 | RequestedEndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | The rate that was requested for close, before provider confirmation. Compared to EndForexRate to assess slippage. NULL for non-close failures. |
| 21 | EndDateTime | datetime | YES | - | CODE-BACKED | The datetime of the close/exit attempt. NULL for non-close failures. |
| 22 | TradeID | varchar(50) | YES | - | CODE-BACKED | FIX ExecID or ClOrdID assigned to this trade by the liquidity provider. NULL for failures before FIX communication completes (not populated by History.HedgeFailInfo - set only by direct INSERTs from Trade SPs). |
| 23 | ParentTradeID | varchar(50) | YES | - | CODE-BACKED | FIX parent trade identifier for the position chain. NULL for same reasons as TradeID. |
| 24 | AccountID | varchar(50) | YES | - | CODE-BACKED | FIX Account field - the account identifier at the liquidity provider. NULL for same reasons as TradeID. |
| 25 | OrderID | varchar(50) | YES | - | CODE-BACKED | FIX OrderID or ClOrdID from the provider. NULL for same reasons as TradeID. |
| 26 | RequestOpenOccurred | datetime | YES | - | CODE-BACKED | When the open request was submitted to the hedging engine. NULL when failure occurs after this stage or context is unavailable. |
| 27 | RequestCloseOccurred | datetime | YES | - | CODE-BACKED | When the close request was submitted to the hedging engine. NULL for non-close failures. |
| 28 | OpenOccurred | datetime | YES | - | CODE-BACKED | When the position was confirmed opened with the provider. NULL if failure occurs at or before the open stage. |
| 29 | FailReason | varchar(max) | YES | - | CODE-BACKED | Free-text failure description. May be a system-generated message ('Cannot find corresponding request') or an error response from the liquidity provider. Stored in the TEXTIMAGE_ON [HISTORY] filegroup due to max-length type. |
| 30 | FailOccurred | datetime | NO | GETDATE() | CODE-BACKED | Local server datetime when the failure was recorded. DEFAULT GETDATE() (local time, not UTC - unlike most other timestamp columns in the schema). The definitive timestamp for when the failure occurred. |
| 31 | LiquidityAccountID | int | YES | - | CODE-BACKED | The liquidity account used for this hedge operation. Resolved by History.HedgeFailInfo via Hedge.HedgeServerToLiquidityAccount lookup on HedgeServerID. NULL if server has no associated liquidity account or if populated by a direct INSERT that omits this lookup. |
| 32 | FailReasonID | int | YES | - | CODE-BACKED | Structured reason code from Dictionary.HedgePositionFailReason (column named HedgeFailID in that table). 24 codes with FailText and HedgePositionFailSeverity: 0=Unknown error (sev 6), 1=Market closed (sev 5), 2=Slippage breached (sev 5), 3=Liquidity breached (sev 5), 4=Insufficient margin (sev 5), etc. NULL when a structured reason code is not available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FailTypeID | Dictionary.FailType | FK (FK_DFLT_HHFL) | Hedge operation failure stage/category. 17 types. |
| HedgeID | Trade.Hedge / History.Hedge | Implicit | The hedge position that failed. No FK constraint. |
| CurrencyID | Dictionary.Currency | Implicit | Position currency denomination. |
| ProviderID | Trade.Provider | Implicit | Liquidity provider involved in the failed operation. |
| InstrumentID | Trade.Instrument | Implicit | Financial instrument of the position. |
| HedgeServerID | Hedge.HedgeServer | Implicit | Hedging server that attempted the operation. |
| LiquidityAccountID | Hedge.HedgeServerToLiquidityAccount | Implicit | Resolved from HedgeServerID at insert time. |
| FailReasonID | Dictionary.HedgePositionFailReason | Implicit | Structured reason code (references HedgeFailID column in that table). 24 structured reasons with severity levels. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.HedgeFailInfo | - | Writer (primary) | Inserts failure records from all hedge operation SPs. Resolves LiquidityAccountID from HedgeServerToLiquidityAccount. |
| Trade.HedgeOpen | - | Writer (direct) | Direct INSERT for specific failure case: FailTypeID=3 when no HedgeRequest found. |
| Trade.HedgeClose | - | Writer (direct) | Direct INSERT for close operation failures. |
| Trade.HedgeRemove | - | Writer (direct) | Direct INSERT for hedge removal failures. |
| Trade.HedgeCloseRequestAdd | - | Writer (direct) | Direct INSERT for close request failures. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgeFail (table)
- written by History.HedgeFailInfo
  - called by Trade.HedgeOpen (on failure), Trade.HedgeClose (on failure), Trade.HedgeRemove (on failure)
  - reads Hedge.HedgeServerToLiquidityAccount to resolve LiquidityAccountID
- directly written by Trade.HedgeOpen, Trade.HedgeClose, Trade.HedgeRemove, Trade.HedgeCloseRequestAdd
```

### 6.1 Objects This Depends On

No code-level dependencies (leaf table).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.HedgeFailInfo | Stored Procedure | Primary writer |
| Trade.HedgeOpen | Stored Procedure | Direct writer for specific failure case |
| Trade.HedgeClose | Stored Procedure | Direct writer for close failures |
| Trade.HedgeRemove | Stored Procedure | Direct writer for remove failures |
| Trade.HedgeCloseRequestAdd | Stored Procedure | Direct writer for close request failures |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HHFL | CLUSTERED | HedgeFailID ASC | - | - | Active (DATA_COMPRESSION=PAGE, FILLFACTOR=90, on [HISTORY] filegroup) |
| HHFL_CURRENCY | NONCLUSTERED | HedgeID ASC | - | - | Active (FILLFACTOR=90, on [HISTORY] filegroup) - misnamed, used to look up all failures for a hedge |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HHFL | CLUSTERED PK | HedgeFailID IDENTITY - sequential append pattern |
| HHFL_FAILOCCURRED | DEFAULT | FailOccurred = GETDATE() (local server time) |
| FK_DFLT_HHFL | FK | FailTypeID -> Dictionary.FailType(FailTypeID) |

### 7.3 Notes

- Stored on [HISTORY] filegroup with TEXTIMAGE_ON [HISTORY] for the varchar(max) FailReason column
- FailOccurred uses GETDATE() (local time) rather than GETUTCDATE() - be aware of timezone offset when correlating with UTC-based timestamps in other tables
- Index named HHFL_CURRENCY despite being on HedgeID - likely a copy-paste naming artifact from a related table; the index supports per-hedge failure lookups
- The four FIX protocol columns (TradeID, ParentTradeID, AccountID, OrderID) are commented out in History.HedgeFailInfo but populated by some direct INSERT paths - expect NULLs for most rows
- NetProfit/Commission are stored in actual money values; callers that track these in cents divide by 100 before calling History.HedgeFailInfo or inserting directly
- NOT FOR REPLICATION on the IDENTITY prevents re-seeding during SQL Server replication synchronization

---

## 8. Sample Queries

### 8.1 Recent failures by type

```sql
SELECT TOP 100
    hf.HedgeFailID,
    hf.HedgeID,
    ft.Name AS FailType,
    hf.InstrumentID,
    hf.HedgeServerID,
    hf.Amount,
    hf.IsBuy,
    hf.FailReason,
    hfr.FailText AS StructuredReason,
    hfr.HedgePositionFailSeverity AS Severity,
    hf.FailOccurred
FROM History.HedgeFail hf WITH (NOLOCK)
JOIN Dictionary.FailType ft WITH (NOLOCK) ON ft.FailTypeID = hf.FailTypeID
LEFT JOIN Dictionary.HedgePositionFailReason hfr WITH (NOLOCK) ON hfr.HedgeFailID = hf.FailReasonID
ORDER BY hf.FailOccurred DESC;
```

### 8.2 All failures for a specific hedge

```sql
SELECT
    hf.HedgeFailID,
    hf.FailTypeID,
    ft.Name AS FailType,
    hf.FailReason,
    hf.FailOccurred
FROM History.HedgeFail hf WITH (NOLOCK)
JOIN Dictionary.FailType ft WITH (NOLOCK) ON ft.FailTypeID = hf.FailTypeID
WHERE hf.HedgeID = @HedgeID
ORDER BY hf.FailOccurred;
```

### 8.3 Failure count by type and instrument over time

```sql
SELECT
    ft.Name AS FailType,
    hf.InstrumentID,
    COUNT(*) AS FailCount,
    CAST(hf.FailOccurred AS DATE) AS FailDate
FROM History.HedgeFail hf WITH (NOLOCK)
JOIN Dictionary.FailType ft WITH (NOLOCK) ON ft.FailTypeID = hf.FailTypeID
WHERE hf.FailOccurred >= DATEADD(DAY, -7, GETDATE())
GROUP BY ft.Name, hf.InstrumentID, CAST(hf.FailOccurred AS DATE)
ORDER BY FailDate DESC, FailCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed (History.HedgeFailInfo, Trade.HedgeOpen, Trade.HedgeClose, Trade.HedgeRemove) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HedgeFail | Type: Table | Source: etoro/etoro/History/Tables/History.HedgeFail.sql*
