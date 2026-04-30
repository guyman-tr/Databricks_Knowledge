# Dictionary.PositionStatus

> Lookup table defining the 2 possible states of a trading position: Open or Closed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusID (INT, CLUSTERED PK) |
| **Row Count** | 2 rows |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only, PAGE compressed) |

---

## 1. Business Meaning

Dictionary.PositionStatus is deceptively simple — just two rows — but it defines the most fundamental state in the entire trading system. Every position in Trade.PositionTbl is either Open (actively held, accumulating PnL) or Closed (terminated, PnL realized).

The transition from Open→Closed is irreversible under normal circumstances. Once closed, a position's PnL is crystallized and added to the user's available balance. The only exception is the "Reopen" operation type (OperationType ID=25), which creates a new Open position to reverse an erroneous closure.

This is the foundation of all portfolio reporting, equity calculations, margin requirements, and risk management. The `IsClosed` bit flag in Trade.PositionTbl is the fast-path equivalent of this lookup.

---

## 2. Business Logic

### 2.1 Position Lifecycle

**What**: Binary state machine — positions can only be Open or Closed.

**Columns/Parameters Involved**: `StatusID`, `Status`

**Diagram**:
```
[Trade Placed] ──► [1: Open] ──► [2: Closed]
                      │                │
                      │          (Irreversible)
                      │
               Accumulating PnL,
               Overnight fees,
               Margin reserved
```

**Rules**:
- **Open (1)**: Position is live. Market exposure active. Margin locked. PnL fluctuating with market price. Overnight fees accruing. User can modify SL/TP. Counted in equity and margin calculations.
- **Closed (2)**: Position terminated. PnL realized and credited/debited to balance. Margin released. No further market exposure. Moved to history for reporting. Cannot be modified.

---

## 3. Data Overview

| StatusID | Status | Meaning |
|---|---|---|
| 1 | Open | Position is active — the user holds market exposure. The instrument's live price determines unrealized PnL. Margin is reserved. The position appears in the user's active portfolio. Overnight fees are charged daily. |
| 2 | Close | Position is terminated — PnL has been realized and added to/subtracted from the user's available balance. Margin is released. The position moves to the closed positions history. No further fees or PnL changes. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusID | int | NO | - | VERIFIED | Primary key. 1=Open (live position), 2=Close (terminated). Referenced by Trade.PositionTbl and all position management procedures. In practice, Trade.PositionTbl uses a denormalized `IsClosed` BIT column (0=Open, 1=Closed) for query performance rather than joining to this table. |
| 2 | Status | varchar(50) | NO | - | VERIFIED | Status label. "Open" or "Close". Used in API responses and reporting. |

---

## 5. Relationships

### 5.1 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionTbl | IsClosed (denormalized) | Implicit | 0=Open(1), 1=Close(2) — avoids JOIN for performance |
| BackOffice position procedures | StatusID | Read | Position state filtering |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression | Status |
|-----------|------|-------------|-------------|--------|
| PK_Dictionary_PositionStatus | CLUSTERED PK | StatusID ASC | PAGE | Active |

---

## 8. Sample Queries

### 8.1 List position statuses
```sql
SELECT StatusID, Status FROM [Dictionary].[PositionStatus] WITH (NOLOCK) ORDER BY StatusID;
```

### 8.2 Count open vs closed positions
```sql
SELECT  CASE WHEN IsClosed = 0 THEN 'Open' ELSE 'Closed' END AS Status,
        COUNT(*) AS PositionCount
FROM    [Trade].[PositionTbl] WITH (NOLOCK)
GROUP BY IsClosed;
```

---

*Generated: 2026-03-13 | Enriched: MCP live data | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Object: Dictionary.PositionStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PositionStatus.sql*
