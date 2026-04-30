# Trade.PositionTbl_SetIsSettled

> Updates a position's settlement status (IsSettled and SettlementTypeID) and logs the change via History.PositionChangeLog_Insert with ChangeTypeID=13.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (the position being updated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionTbl_SetIsSettled changes the settlement status of an open position. In regulated markets (particularly stocks and ETFs), positions undergo T+2 settlement - transitioning from "unsettled" to "settled" after the settlement period. This procedure handles that transition by updating both IsSettled and SettlementTypeID, and creating a full audit trail via the position change log.

The procedure only performs the update if the settlement status actually changed (guards against no-op calls), and wraps the update + audit log insertion in a single transaction.

---

## 2. Business Logic

### 2.1 Settlement Status Update

**What**: Updates IsSettled and SettlementTypeID, logs the change.

**Columns/Parameters Involved**: `@PositionID`, `@NewIsSettled`, plus all position attributes read for the change log

**Rules**:
- Reads current position state from Trade.Position (view) by @PositionID
- Only proceeds if @PreviousIsSettled != @NewIsSettled (no-op guard)
- SET ChangeTypeID = 13 (settlement status change)
- Updates Trade.PositionTbl: IsSettled = @NewIsSettled, SettlementTypeID = @NewIsSettled
- Calls History.PositionChangeLog_Insert with full before/after snapshot
- All "previous" values passed to change log are identical to current values (only IsSettled/SettlementTypeID change)
- Wrapped in explicit transaction with ROLLBACK on error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The position whose settlement status is being changed. |
| 2 | @NewIsSettled | BIT | NO | - | CODE-BACKED | The new settlement status. 1=settled, 0=unsettled. Also used as SettlementTypeID value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.Position | READ | Reads current position state (view over Trade.PositionTbl) |
| @PositionID | Trade.PositionTbl | UPDATE | Updates IsSettled and SettlementTypeID |
| @PositionID | History.PositionChangeLog_Insert | EXEC | Creates audit record with ChangeTypeID=13 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Settlement processing service | External | EXEC | Called when positions complete T+2 settlement |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionTbl_SetIsSettled (procedure)
+-- Trade.Position (view)
+-- Trade.PositionTbl (table)
+-- History.PositionChangeLog_Insert (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | READ - current position state |
| Trade.PositionTbl | Table | UPDATE - IsSettled, SettlementTypeID |
| History.PositionChangeLog_Insert | Procedure | EXEC - audit trail (ChangeTypeID=13) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Settlement engine | External | EXEC - T+2 settlement transitions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No-op guard | Safety | Only updates when @PreviousIsSettled != @NewIsSettled |
| Explicit transaction | Atomicity | BEGIN TRAN / COMMIT with ROLLBACK on error |
| ChangeTypeID = 13 | Audit | Settlement change type constant |
| Error handling | Transaction | ROLLBACK if TRANCOUNT=1, COMMIT if >1 (nested transaction support) |

---

## 8. Sample Queries

### 8.1 Check settlement status of a position

```sql
SELECT PositionID, IsSettled, SettlementTypeID
FROM   Trade.PositionTbl WITH (NOLOCK)
WHERE  PositionID = 123456789;
```

### 8.2 View settlement change log entries

```sql
SELECT *
FROM   History.PositionChangeLog WITH (NOLOCK)
WHERE  PositionID = 123456789
  AND  ChangeTypeID = 13
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.PositionChangeLog_Insert) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionTbl_SetIsSettled | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionTbl_SetIsSettled.sql*
