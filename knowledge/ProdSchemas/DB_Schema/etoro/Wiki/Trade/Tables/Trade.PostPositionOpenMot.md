# Trade.PostPositionOpenMot

> Memory-optimized queue for MOT (Message on Transaction) post-position-open processing; stores full position snapshot after open for async notifications, mirror propagation, and compliance checks.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PositionID |
| **Partition** | No (Memory-Optimized) |
| **Indexes** | 3 (1 PK nonclustered, 2 NC on CID and StatusID) |

---

## 1. Business Meaning

**WHAT:** Trade.PostPositionOpenMot is a memory-optimized In-Memory OLTP queue table for MOT (Message on Transaction) processing. After a position opens, this table stores a full snapshot of the position and its context for async post-open actions.

**WHY:** Position-open is latency-sensitive. Post-open actions (notifications, mirror propagation, compliance checks) can be deferred. This table decouples the fast open path from the slower MOT processing. Without it, every position open would block on notifications and downstream systems.

**HOW:** When a position opens, a row is inserted with PositionID, CID, Amount, rates, mirror info, settlement type, leverage, and other context. A background job or procedure reads from this queue (by StatusID), performs MOT actions (e.g. notify external systems, propagate to mirrors), and consumes the row. The table is typically EMPTY when idle because rows are consumed after processing.

---

## 2. Business Logic

### 2.1 MOT Snapshot Contents

**What**: Full position snapshot at open for downstream consumers.

**Columns Involved**: All columns capture position state at open - Amount, LimitRate, StopRate, Occurred, MirrorID, TreeID, SessionID, IsTslEnabled, IsSettled, SettlementTypeID, InstrumentID, OpenActionType, MirrorIsActive, Leverage, IsBuy, IsNoStopLoss, IsNoTakeProfit, LotCountDecimal, PriceType.

**Rules**:
- Snapshot is immutable; changes to the live position do not update this row
- StatusID 0 = Pending (default); processed rows are consumed
- SnapshotTimestamp records when the snapshot was taken

**Diagram**:
```
Position Open
    |
    v
INSERT full snapshot into PostPositionOpenMot
    | (StatusID = 0)
    v
MOT Job reads by StatusID
    |
    +-> Notifications
    +-> Mirror propagation
    +-> Compliance checks
    |
    v
DELETE or update StatusID, consume row
```

### 2.2 Mirror and Copy-Trade Context

**What**: Mirror-related columns support copy-trade post-open processing.

**Columns Involved**: `MirrorID`, `MirrorRealizedEquity`, `MirrorIsActive`, `ParentPositionID`, `TreeID`

**Rules**:
- MirrorID and MirrorIsActive indicate if position is from CopyTrader
- MirrorRealizedEquity captures account state at open for mirror calculations
- TreeID identifies the copy-trade tree

### 2.3 Rate and Settlement Context

**What**: Rates and settlement type for PnL and compliance.

**Columns Involved**: `LimitRate`, `StopRate`, `LastOpPriceRate`, `LastOpConversionRate`, `ClientViewRate`, `ClientRateForCalc`, `SettlementTypeID`, `IsSettled`

**Rules**:
- SettlementTypeID and IsSettled distinguish CFD vs real stock
- ClientViewRate and ClientRateForCalc support client-facing calculations

---

## 3. Data Overview

| PositionID | CID | StatusID | InstrumentID | Meaning |
|------------|-----|----------|--------------|---------|
| (empty) | - | - | - | Table is EMPTY (queue table - rows consumed after processing). |

**Selection criteria**: Queue table. Rows exist only briefly between position open and MOT processing. Idle state is empty.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID who opened the position. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Primary key. Position that opened. |
| 3 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | Close-on-end-of-week flag. |
| 4 | Amount | money | YES | - | CODE-BACKED | Position amount at open. |
| 5 | LimitRate | decimal(16,8) | YES | - | CODE-BACKED | Take-profit rate at open. |
| 6 | StopRate | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss rate at open. |
| 7 | Occurred | datetime | YES | - | CODE-BACKED | When position opened. |
| 8 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position if copied. |
| 9 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation price rate. |
| 10 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last operation price rate ID. |
| 11 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation conversion rate. |
| 12 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last operation conversion rate ID. |
| 13 | MirrorID | int | YES | - | CODE-BACKED | Mirror ID if copy-trade position. |
| 14 | MirrorRealizedEquity | money | YES | - | CODE-BACKED | Mirror realized equity at open. |
| 15 | AccountRealizedEquity | money | YES | - | CODE-BACKED | Account realized equity at open. |
| 16 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree ID. |
| 17 | SessionID | bigint | YES | - | CODE-BACKED | Session ID. |
| 18 | IsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing stop-loss enabled. |
| 19 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request correlation ID. |
| 20 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Units base value in cents. |
| 21 | IsSettled | bit | YES | - | CODE-BACKED | 1 = real stock, 0 = CFD. |
| 22 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Amount in units. |
| 23 | ClientViewRateID | bigint | YES | - | CODE-BACKED | Client view rate ID. |
| 24 | ClientViewRate | decimal(16,6) | YES | - | CODE-BACKED | Client view rate. |
| 25 | ClientRateForCalcID | bigint | YES | - | CODE-BACKED | Client rate for calc ID. |
| 26 | ClientRateForCalc | decimal(16,6) | YES | - | CODE-BACKED | Client rate for calculations. |
| 27 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type (CFD vs real). |
| 28 | StatusID | tinyint | YES | 0 | CODE-BACKED | 0 = Pending (default); processed rows consumed. |
| 29 | InstrumentID | int | YES | - | CODE-BACKED | Instrument. References Trade.Instrument. |
| 30 | OpenActionType | int | YES | - | CODE-BACKED | How position was opened. |
| 31 | MirrorIsActive | tinyint | YES | - | CODE-BACKED | Mirror active at open. |
| 32 | Leverage | int | YES | - | CODE-BACKED | Leverage at open. |
| 33 | IsBuy | bit | YES | - | CODE-BACKED | 1 = buy (long), 0 = sell (short). |
| 34 | IsNoStopLoss | bit | YES | - | CODE-BACKED | No stop-loss flag. |
| 35 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | No take-profit flag. |
| 36 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count. |
| 37 | SnapshotTimestamp | datetime | YES | - | CODE-BACKED | When snapshot was taken. |
| 38 | PriceType | int | YES | - | CODE-BACKED | Price type for the position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | Position that opened. |
| CID | Customer.CustomerStatic | Implicit | Customer who opened. |
| InstrumentID | Trade.Instrument | Implicit | Instrument. |
| MirrorID | Trade.Mirror | Implicit | Copy-trade mirror if applicable. |
| ParentPositionID | Trade.PositionTbl | Implicit | Parent position if copied. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PostOpenPositionActions | Procedure | Consumes | MOT processing after position open. |
| Trade.PortfolioForApiInnerMot | Procedure | Reads | May read for API/MOT context. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PostPositionOpenMot (table)
(No code-level dependencies - CREATE TABLE has no FROM/JOIN)
```

### 6.1 Objects This Depends On

No code-level dependencies. Logical references to Trade.Instrument, Trade.PositionTbl, Trade.Mirror are in Section 5.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PostOpenPositionActions | Procedure | Consumes queue for MOT processing. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (implicit) | NONCLUSTERED PK | PositionID ASC | - | - | Active |
| ixCID | NONCLUSTERED | CID ASC | - | - | Active |
| ixStatusID | NONCLUSTERED | PositionID ASC | - | - | Active |

Note: ixStatusID key is PositionID per DDL; typically StatusID would be used for batch selection - verify in procedures. Memory-optimized: MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | PositionID ASC (nonclustered) |
| DEFAULT | DEFAULT | StatusID = 0 |

---

## 8. Sample Queries

### 8.1 Check pending MOT queue

```sql
SELECT TOP 10 PositionID, CID, InstrumentID, Occurred, StatusID
FROM   Trade.PostPositionOpenMot WITH (NOLOCK)
WHERE  StatusID = 0;
```

### 8.2 Count by status

```sql
SELECT StatusID, COUNT(*) AS Cnt
FROM   Trade.PostPositionOpenMot WITH (NOLOCK)
GROUP BY StatusID;
```

### 8.3 Resolve instrument names for pending rows

```sql
SELECT p.PositionID, p.CID, p.Amount, p.Occurred, i.Symbol
FROM   Trade.PostPositionOpenMot p WITH (NOLOCK)
JOIN   Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = p.InstrumentID
WHERE  p.StatusID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 38 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + context*
*Sources: DDL, Trade.Instrument doc, Trade.PositionTbl doc, PostOpenPositionActions | Corrections: 0 applied*
*Object: Trade.PostPositionOpenMot | Type: Table | Source: etoro/Trade/Tables/PostPositionOpenMot.sql*
