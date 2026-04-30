# Trade.ArchiveAccountLiquidationSaga

> Archives a completed account liquidation saga by atomically deleting it from the active table and inserting it into the history table using DELETE...OUTPUT...INTO.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (INT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure moves a completed account liquidation saga from the active queue (`Trade.AccountLiquidationSaga`) to the history table (`History.AccountLiquidationSaga`). Account liquidation is the process of closing all positions and blocking an account, typically triggered by BSL (Balance Stop Loss) threshold breaches, compliance actions, or account closure requests.

Each liquidation saga tracks a multi-step process (identified by CID and `CurrentStepIndex`). Once the saga completes (all positions closed, account blocked), this procedure archives it so the active table only contains in-progress liquidations. The DELETE...OUTPUT...INTO pattern ensures atomicity - the row is never in both tables or neither.

---

## 2. Business Logic

### 2.1 Atomic Archive Pattern

**What**: DELETE from active table with OUTPUT INTO history table.

**Columns/Parameters Involved**: `CID`, `CurrentStepIndex`, `InitialRequestGuid`, `AccountLiquidationAcionTypeID`, `CreateTime`

**Rules**:
- DELETE WHERE CID = @CID removes all saga rows for the customer from the active table
- OUTPUT DELETED.* captures the deleted columns and inserts into History with an added `CloseTime = GETUTCDATE()`
- History table renames `CurrentStepIndex` to `LastStepIndex` to reflect it's the final state
- This is a single atomic operation - no gap between delete and insert

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose liquidation saga is complete and ready for archival. Matches Trade.AccountLiquidationSaga.CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | Trade.AccountLiquidationSaga | DELETER | Removes completed saga from active table |
| OUTPUT INTO | History.AccountLiquidationSaga | WRITER | Archives the completed saga with CloseTime |

### 5.2 Referenced By (other objects point to this)

Called by the liquidation orchestration service after saga completion.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ArchiveAccountLiquidationSaga (procedure)
+-- Trade.AccountLiquidationSaga (table)
+-- History.AccountLiquidationSaga (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AccountLiquidationSaga | Table | DELETE - removes completed saga |
| History.AccountLiquidationSaga | Table | INSERT via OUTPUT - archives with CloseTime |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Archive a completed liquidation

```sql
EXEC Trade.ArchiveAccountLiquidationSaga @CID = 12345;
```

### 8.2 Check active liquidation sagas

```sql
SELECT * FROM Trade.AccountLiquidationSaga WITH (NOLOCK) ORDER BY CreateTime DESC;
```

### 8.3 Check archived liquidation history

```sql
SELECT  TOP 20 CID, LastStepIndex, CreateTime, CloseTime,
        DATEDIFF(SECOND, CreateTime, CloseTime) AS DurationSeconds
FROM    History.AccountLiquidationSaga WITH (NOLOCK)
ORDER BY CloseTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ArchiveAccountLiquidationSaga | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ArchiveAccountLiquidationSaga.sql*
