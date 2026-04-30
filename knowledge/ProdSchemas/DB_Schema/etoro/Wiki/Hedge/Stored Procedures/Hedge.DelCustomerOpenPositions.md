# Hedge.DelCustomerOpenPositions

> Rolling 30-day retention enforcer for Hedge.CustomerOpenPositions: batch-deletes customer open position records older than 30 days in 50,000-row chunks using a GOTO loop until no rows remain.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batch DELETE Hedge.CustomerOpenPositions WHERE OccurredAt < getdate()-30 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.DelCustomerOpenPositions` enforces the 30-day rolling retention policy on `Hedge.CustomerOpenPositions`, the customer-side open position snapshot table. It is the fifth and final member of the five Del* retention procedures in the Hedge schema.

`Hedge.CustomerOpenPositions` captures periodic snapshots of customer open positions as recorded by the hedge engine. These snapshots drive the hedge engine's exposure view - how much customer exposure exists per instrument. The 30-day rolling window retains enough history for recent reconciliation, debugging, and regulatory lookback without requiring indefinite storage.

Together, the five Del* procedures cover the complete set of rolling Hedge tables:
- **Open positions**: `DelCustomerOpenPositions` + `DelAccountOpenPositions`
- **Closed positions**: `DelCustomerClosedPositions` + `DelAccountClosedPositions`
- **Account status**: `DelAccountStatus`

Data older than 30 days is archived by `Hedge.ArchiveHedgeTables` or `Hedge.ArchiveHedgeTables_SS` into `History.CustomerOpenPositions` before deletion, ensuring the historical record is preserved in the archive schema.

---

## 2. Business Logic

### 2.1 30-Day Rolling Retention Cutoff

**What**: Deletes all CustomerOpenPositions snapshots older than 30 days.

**Rules**:
- `@DelFromDate = getdate() - 30`
- DELETE WHERE `OccurredAt < @DelFromDate`
- SET ROWCOUNT 50000 caps each batch; GOTO loop repeats until @@ROWCOUNT = 0

**Diagram**:
```
Hedge.DelCustomerOpenPositions
      |
      @DelFromDate = getdate() - 30
      SET ROWCOUNT 50000
      |
      delete_more:
          DELETE Hedge.CustomerOpenPositions WHERE OccurredAt < @DelFromDate
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
| (deletes from) | Hedge.CustomerOpenPositions | DELETE | Rolling retention target - removes rows older than 30 days |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Invoked by a scheduled SQL Agent job for periodic retention enforcement.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.DelCustomerOpenPositions (procedure)
+-- Hedge.CustomerOpenPositions (table) - DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerOpenPositions | Table | DELETE rows WHERE OccurredAt < getdate()-30 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SQL Agent retention job) | External | Scheduled execution to enforce 30-day rolling window |
| Hedge.ArchiveHedgeTables / Hedge.ArchiveHedgeTables_SS | Procedure | Archives data to History.CustomerOpenPositions before Del* runs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Uses legacy `SET ROWCOUNT` syntax (deprecated; `TOP` in DELETE is the modern equivalent)
- No SET NOCOUNT ON, no TRY/CATCH
- No explicit transaction - each 50,000-row batch auto-commits
- `getdate()` not GETUTCDATE() - ensure archiving job runs before deletion
- CustomerOpenPositions is NOT in the SSDT project - this procedure references a table managed outside of SSDT

---

## 8. Sample Queries

### 8.1 Execute: Run retention cleanup

```sql
EXEC Hedge.DelCustomerOpenPositions
```

### 8.2 Preview: How many rows would be deleted?

```sql
DECLARE @DelFromDate DATETIME = GETDATE() - 30
SELECT COUNT(*) AS RowsToDelete FROM Hedge.CustomerOpenPositions WITH (NOLOCK)
WHERE OccurredAt < @DelFromDate
```

### 8.3 Monitor: Check all five rolling tables' age windows together

```sql
SELECT 'CustomerOpenPositions' AS TableName, MIN(OccurredAt) AS OldestRow, MAX(OccurredAt) AS NewestRow, COUNT(*) AS TotalRows
FROM Hedge.CustomerOpenPositions WITH (NOLOCK)
UNION ALL
SELECT 'CustomerClosedPositions', MIN(OccurredAt), MAX(OccurredAt), COUNT(*)
FROM Hedge.CustomerClosedPositions WITH (NOLOCK)
UNION ALL
SELECT 'AccountOpenPositions', MIN(OccurredAt), MAX(OccurredAt), COUNT(*)
FROM Hedge.AccountOpenPositions WITH (NOLOCK)
UNION ALL
SELECT 'AccountClosedPositions', MIN(OccurredAt), MAX(OccurredAt), COUNT(*)
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
UNION ALL
SELECT 'AccountStatus', MIN(OccurredAt), MAX(OccurredAt), COUNT(*)
FROM Hedge.AccountStatus WITH (NOLOCK)
ORDER BY TableName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 8.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.DelCustomerOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.DelCustomerOpenPositions.sql*
