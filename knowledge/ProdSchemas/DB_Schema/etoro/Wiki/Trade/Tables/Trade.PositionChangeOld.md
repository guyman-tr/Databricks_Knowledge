# Trade.PositionChangeOld

> Legacy audit table that tracked every modification to a position (SL/TP edits, amount changes, hedge reassignments). Replaced by the current PositionChange view or partitioned version. Uses pre-migration int PositionID and custom dbo.dtPrice UDT.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PositionChangeID (int IDENTITY, PK) |
| **Partition** | No (MAIN filegroup for PK/index) |
| **Indexes** | 2 (PK CLUSTERED + TPSC_OCCURRED) |

---

## 1. Business Meaning

**WHAT**: Trade.PositionChangeOld is the legacy version of the position change audit table. It recorded every modification made to a position: edits to stop-loss, take-profit, amount, hedge server assignment, end-of-week fee settings, and related rate fields. Each row stored "Previous" and current values side-by-side for before/after comparison, plus Occurred timestamp and MirrorID for copy-trade context.

**WHY**: Position change history is critical for support (proving what changed and when), compliance (audit trail), and debugging (understanding sequence of edits). The "Old" suffix indicates this table was superseded when the system migrated to a new audit mechanism-either the Trade.PositionChange view (which may derive from Trade.PositionTbl history) or a partitioned table. The table is empty (0 rows), suggesting historical data was migrated out or the table is kept only for schema reference.

**HOW**: Procedures that modified positions (e.g., PositionEditStopLoss, PositionEditTakeProfit) would have inserted into this table on each update. The migration from int to bigint PositionID is evident: this table uses PositionID int, while Trade.PositionTbl uses bigint. The custom UDT dbo.dtPrice is used for rate columns (LimitRate, StopRate, etc.). NOT FOR REPLICATION on IDENTITY prevents replication conflicts.

---

## 2. Business Logic

### 2.1 Before/After Change Capture

**What**: Each row captures the previous and new values for key position attributes.

**Columns/Parameters Involved**: PreviousAmount/Amount, PreviousStopRate/StopRate, PreviousLimitRate/LimitRate, PreviousHedgeID/HedgeID, PreviousCloseOnEndOfWeek/CloseOnEndOfWeek, PreviousEndOfWeekFee/EndOfWeekFee

**Rules**:
- Previous* columns held the value before the change.
- Current columns held the value after the change.
- Occurred: When the change was recorded (default getdate()).
- ParentPositionID, OrigParentPositionID, MirrorID: Copy-trade hierarchy context.

### 2.2 Pre-Adjusted vs Adjusted Rates

**What**: Unadjusted rates track values before corporate action adjustments.

**Columns/Parameters Involved**: PreviousLimitRateUnAdjusted, PreviousStopRateUnAdjusted, StopRateUnAdjusted, LimitRateUnAdjusted

**Rules**:
- Used when positions underwent splits or other corporate actions; allows comparison of pre-adjustment and post-adjustment rates.

### 2.3 Legacy PositionID Type

**What**: PositionID is int (not bigint), indicating pre-migration schema.

**Rules**:
- Trade.PositionTbl now uses bigint PositionID. This table's PositionID would not accommodate current PositionID values above 2,147,483,647.
- OrderID, ParentPositionID, OrigParentPositionID, MirrorID also int.

---

## 3. Data Overview

| PositionChangeID | PositionID | HedgeID | Amount | StopRate | LimitRate | Occurred | Meaning |
|-----------------|------------|---------|--------|----------|-----------|----------|---------|
| (empty) | - | - | - | - | - | - | Table has 0 rows. Legacy structure only. |

**Selection criteria**: Table is empty. Historical rows would have shown PositionID, Previous* vs current values, Occurred, TradeRange, MirrorID.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionChangeID | int | NO | IDENTITY | CODE-BACKED | PK. Surrogate key. NOT FOR REPLICATION. |
| 2 | PositionID | int | NO | - | CODE-BACKED | Legacy: int (not bigint). FK to Trade.PositionTbl. The position that was modified. |
| 3 | PreviousHedgeID | int | YES | - | CODE-BACKED | HedgeID before change. |
| 4 | HedgeID | int | YES | - | CODE-BACKED | HedgeID after change. |
| 5 | OrderID | int | YES | - | CODE-BACKED | Order context. |
| 6 | PreviousCloseOnEndOfWeek | bit | NO | - | CODE-BACKED | CloseOnEndOfWeek before change. |
| 7 | CloseOnEndOfWeek | bit | NO | - | CODE-BACKED | CloseOnEndOfWeek after change. |
| 8 | PreviousEndOfWeekFee | money | NO | - | CODE-BACKED | EndOfWeekFee before change. |
| 9 | EndOfWeekFee | money | NO | - | CODE-BACKED | EndOfWeekFee after change. |
| 10 | PreviousAmount | money | NO | - | CODE-BACKED | Amount before change. |
| 11 | Amount | money | NO | - | CODE-BACKED | Amount after change. |
| 12 | PreviousLimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take-profit rate before change. |
| 13 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take-profit rate after change. |
| 14 | PreviousStopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop-loss rate before change. |
| 15 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop-loss rate after change. |
| 16 | Occurred | datetime | NO | getdate() | CODE-BACKED | When change was recorded. Indexed (PositionID, Occurred). |
| 17 | TradeRange | int | YES | - | CODE-BACKED | Market range tolerance. |
| 18 | ParentPositionID | int | YES | 1 | CODE-BACKED | Copy-trade parent. 0/1 = root. |
| 19 | OrigParentPositionID | int | YES | 1 | CODE-BACKED | Original parent before detachment. |
| 20 | LastOpPriceRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Last operation price. |
| 21 | LastOpPriceRateID | bigint | YES | 0 | CODE-BACKED | Last op price rate ID. |
| 22 | LastOpConversionRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Last op conversion rate. |
| 23 | LastOpConversionRateID | bigint | YES | 0 | CODE-BACKED | Last op conversion rate ID. |
| 24 | MirrorID | int | YES | 0 | CODE-BACKED | FK to Trade.Mirror. Copy-trade context. |
| 25 | PreviousLimitRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Limit rate before corporate action adjustment. |
| 26 | PreviousStopRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Stop rate before adjustment. |
| 27 | StopRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Stop rate (unadjusted). |
| 28 | LimitRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Limit rate (unadjusted). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | Position that was modified |
| HedgeID | Trade.Hedge | Implicit | Hedge after change |
| OrderID | Trade.Orders | Implicit | Order context |
| MirrorID | Trade.Mirror | Implicit | Copy-trade relationship |
| ParentPositionID, OrigParentPositionID | Trade.PositionTbl | Implicit | Copy-trade parent |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Legacy) | - | - | Replaced by PositionChange view or partitioned table. No active writers. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionChangeOld (table)
├── Trade.PositionTbl (implicit via PositionID)
├── Trade.Mirror (implicit via MirrorID)
├── Trade.Hedge (implicit via HedgeID)
└── dbo.dtPrice (UDT for rate columns)
```

### 6.1 Objects This Depends On

No explicit FKs. Implicit: Trade.PositionTbl, Trade.Mirror, Trade.Hedge, Trade.Orders, dbo.dtPrice (UDT).

### 6.2 Objects That Depend On This

Legacy table. Replaced by Trade.PositionChange view or partitioned audit table. No active dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TPSC | CLUSTERED PK | PositionChangeID | - | - | Active (DATA_COMPRESSION=PAGE, MAIN) |
| TPSC_OCCURRED | NC | PositionID, Occurred | - | - | Active (MAIN) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TPSC | PRIMARY KEY | PositionChangeID |
| DF (Occurred) | DEFAULT | getdate() |
| DF (ParentPositionID) | DEFAULT | 1 |
| DF (OrigParentPositionID) | DEFAULT | 1 |
| DF (LastOpPriceRate) | DEFAULT | 0 |
| DF (LastOpPriceRateID) | DEFAULT | 0 |
| DF (LastOpConversionRate) | DEFAULT | 0 |
| DF (LastOpConversionRateID) | DEFAULT | 0 |
| DF (MirrorID) | DEFAULT | 0 |

### 7.3 Type Notes

- PositionID, HedgeID, OrderID, ParentPositionID, OrigParentPositionID, MirrorID: int (legacy; PositionTbl uses bigint for PositionID).
- Rate columns: dbo.dtPrice (custom UDT).

---

## 8. Sample Queries

### 8.1 Position change history (when data existed)
```sql
SELECT pc.PositionChangeID, pc.PositionID, pc.PreviousAmount, pc.Amount,
       pc.PreviousStopRate, pc.StopRate, pc.PreviousLimitRate, pc.LimitRate,
       pc.Occurred, pc.MirrorID
FROM   Trade.PositionChangeOld pc WITH (NOLOCK)
WHERE  pc.PositionID = @PositionID
ORDER BY pc.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Object: Trade.PositionChangeOld | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionChangeOld.sql*
