# Hedge.DelAccountOpenPositions

> Rolling 30-day retention enforcer for Hedge.AccountOpenPositions: batch-deletes records older than 30 days in 50,000-row chunks using a GOTO loop until no rows remain.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batch DELETE Hedge.AccountOpenPositions WHERE OccurredAt < getdate()-30 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.DelAccountOpenPositions` enforces the 30-day rolling retention policy on `Hedge.AccountOpenPositions`, the LP-account-level open position snapshot log. It is one of five Del* procedures in the Hedge schema that share identical retention logic, each targeting a different rolling table.

`Hedge.AccountOpenPositions` captures periodic snapshots of open positions at the LP account level (by LiquidityAccountID). These snapshots have a finite operational life - after 30 days, they are too old to be useful for current reconciliation or risk reporting and are purged by this procedure.

The batch-delete approach (50,000 rows per iteration, GOTO loop) prevents the large lock footprint and transaction log explosion that a single unbounded DELETE would cause on a high-volume table.

See `Hedge.DelAccountClosedPositions` for the companion procedure and detailed pattern documentation.

---

## 2. Business Logic

### 2.1 30-Day Rolling Retention Cutoff

**What**: Computes the cutoff date once; deletes all rows older than 30 days from Hedge.AccountOpenPositions.

**Rules**:
- `@DelFromDate = getdate() - 30`
- DELETE WHERE `OccurredAt < @DelFromDate`
- SET ROWCOUNT 50000 caps each batch; GOTO loop repeats until @@ROWCOUNT = 0

**Diagram**:
```
Hedge.DelAccountOpenPositions
      |
      @DelFromDate = getdate() - 30
      SET ROWCOUNT 50000
      |
      delete_more:
          DELETE Hedge.AccountOpenPositions WHERE OccurredAt < @DelFromDate
          IF @@ROWCOUNT > 0 -> GOTO delete_more
      |
      SET ROWCOUNT 0
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters - the 30-day retention window is hardcoded.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (deletes from) | Hedge.AccountOpenPositions | DELETE | Rolling retention target - removes rows older than 30 days |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Invoked by a scheduled SQL Agent job for periodic retention enforcement.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.DelAccountOpenPositions (procedure)
+-- Hedge.AccountOpenPositions (table) - DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountOpenPositions | Table | DELETE rows WHERE OccurredAt < getdate()-30 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SQL Agent retention job) | External | Scheduled execution to enforce 30-day rolling window |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Uses legacy `SET ROWCOUNT` syntax (deprecated; `TOP` in DELETE is the modern equivalent)
- No SET NOCOUNT ON, no TRY/CATCH
- No explicit transaction - each 50,000-row batch auto-commits
- `getdate()` not GETUTCDATE() - cutoff based on local server time

---

## 8. Sample Queries

### 8.1 Execute: Run retention cleanup

```sql
EXEC Hedge.DelAccountOpenPositions
```

### 8.2 Preview: How many rows would be deleted?

```sql
DECLARE @DelFromDate DATETIME = GETDATE() - 30
SELECT COUNT(*) AS RowsToDelete FROM Hedge.AccountOpenPositions WITH (NOLOCK)
WHERE OccurredAt < @DelFromDate
```

### 8.3 Monitor: Check table age distribution

```sql
SELECT MIN(OccurredAt) AS OldestRow, MAX(OccurredAt) AS NewestRow, COUNT(*) AS TotalRows
FROM Hedge.AccountOpenPositions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.6/10 (Elements: 8.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.DelAccountOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.DelAccountOpenPositions.sql*
