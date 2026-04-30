# Hedge.DelAccountStatus

> Rolling 30-day retention enforcer for Hedge.AccountStatus: batch-deletes LP account financial snapshots older than 30 days in 50,000-row chunks using a GOTO loop until no rows remain.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batch DELETE Hedge.AccountStatus WHERE OccurredAt < getdate()-30 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.DelAccountStatus` enforces the 30-day rolling retention policy on `Hedge.AccountStatus`, the high-frequency LP account financial status table. It is one of five Del* procedures in the Hedge schema sharing the same batch-delete GOTO pattern.

`Hedge.AccountStatus` receives writes from three procedures (`Hedge.AddAccountStatus`, `Hedge.AddHedgeAccountStatus`, and their variants) at high frequency - potentially every few seconds per LP account. This makes it one of the highest-volume tables in the Hedge schema. Without regular pruning, it would grow unbounded.

The 30-day window retains enough history for:
- Recent reconciliation with LP statements
- Short-term trend analysis of account balance/equity/margin
- Debugging recent hedge engine behavior

Older snapshots are archived via `Hedge.ArchiveHedgeTables` into `History.AccountStatus` before this procedure prunes them, ensuring historical data is preserved in the History schema.

The batch-delete approach (50,000 rows per iteration) is especially important here given the table's high row velocity.

---

## 2. Business Logic

### 2.1 30-Day Rolling Retention Cutoff

**What**: Deletes all AccountStatus snapshots older than 30 days from today.

**Rules**:
- `@DelFromDate = getdate() - 30`
- DELETE WHERE `OccurredAt < @DelFromDate`
- SET ROWCOUNT 50000 caps each batch; GOTO loop repeats until @@ROWCOUNT = 0

**Diagram**:
```
Hedge.DelAccountStatus
      |
      @DelFromDate = getdate() - 30
      SET ROWCOUNT 50000
      |
      delete_more:
          DELETE Hedge.AccountStatus WHERE OccurredAt < @DelFromDate
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
| (deletes from) | Hedge.AccountStatus | DELETE | Rolling retention target - removes snapshots older than 30 days |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Invoked by a scheduled SQL Agent job for periodic retention enforcement.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.DelAccountStatus (procedure)
+-- Hedge.AccountStatus (table) - DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountStatus | Table | DELETE rows WHERE OccurredAt < getdate()-30 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SQL Agent retention job) | External | Scheduled execution to enforce 30-day rolling window |
| Hedge.ArchiveHedgeTables | Procedure | Archives data to History.AccountStatus before Del* runs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Uses legacy `SET ROWCOUNT` syntax (deprecated; `TOP` in DELETE is the modern equivalent)
- No SET NOCOUNT ON, no TRY/CATCH
- No explicit transaction - each 50,000-row batch auto-commits
- `getdate()` not GETUTCDATE() - ensure archiving job runs before deletion to avoid gaps
- High row volume: multiple iterations likely; each iteration commits 50K rows

---

## 8. Sample Queries

### 8.1 Execute: Run retention cleanup

```sql
EXEC Hedge.DelAccountStatus
```

### 8.2 Preview: How many rows would be deleted?

```sql
DECLARE @DelFromDate DATETIME = GETDATE() - 30
SELECT COUNT(*) AS RowsToDelete FROM Hedge.AccountStatus WITH (NOLOCK)
WHERE OccurredAt < @DelFromDate
```

### 8.3 Monitor: Check retention boundary and table age

```sql
SELECT
    MIN(OccurredAt) AS OldestRow,
    MAX(OccurredAt) AS NewestRow,
    COUNT(*) AS TotalRows,
    DATEDIFF(DAY, MIN(OccurredAt), GETDATE()) AS OldestAgeInDays
FROM Hedge.AccountStatus WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 8.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.DelAccountStatus | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.DelAccountStatus.sql*
