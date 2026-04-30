# Hedge.RemoveNetting

> Deletes Hedge.Netting rows for a specific (LiquidityAccountID, InstrumentID) combination, with an optional ValueDate filter - when @ValueDate is NULL, all value dates are removed; when specified, only that date's row is removed. Called when a hedge position is closed or squared.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DELETE from Hedge.Netting WHERE LiquidityAccountID=X AND InstrumentID=Y AND (ValueDate=Z OR Z IS NULL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.RemoveNetting` is the standard lifecycle close operation for hedge positions. When the hedge server fully closes a position for a specific instrument on a specific LP account - either because the customer book is now flat, the position was rolled off, or the server is shutting down - this procedure removes the corresponding row(s) from `Hedge.Netting`.

The optional `@ValueDate` parameter provides two modes:
- **@ValueDate = NULL (default)**: removes ALL value date rows for the (LiquidityAccountID, InstrumentID) pair - used for full position termination.
- **@ValueDate = specific date**: removes only the row for that specific value date - used for forward position roll-offs where only a specific settlement date is being closed.

Note that `Hedge.Netting` maintains at most one active position per (LiquidityAccountID, InstrumentID) at a time (the ValueDate is an attribute of the position, not a multi-position dimension). So the @ValueDate filter is mainly useful for precision when rolling forward positions to a new settlement date.

Deleted rows are automatically captured in `History.Netting_History` via SQL Server system versioning, providing a complete audit trail without any additional code.

Compare with:
- `Hedge.RemoveBadNetting`: removes WRONG-LP rows for a server (cleanup for single-LP config changes)
- `Hedge.RemoveMultiBadNetting`: removes WRONG-LP rows for a server (cleanup for multi-LP config changes)
- `Hedge.RemoveNetting`: removes a CLOSED position (normal lifecycle termination)

---

## 2. Business Logic

### 2.1 Position Closure (Instrument-Level Delete)

**What**: Removes the netting position for a specific instrument on a specific LP account.

**Columns/Parameters Involved**: `@LiquidityAccountID`, `@InstrumentID`, `@ValueDate`

**Rules**:
- Filter: `LiquidityAccountID = @LiquidityAccountID AND InstrumentID = @InstrumentID AND (ValueDate = @ValueDate OR @ValueDate IS NULL)`.
- `@ValueDate IS NULL`: the OR clause evaluates to TRUE for any ValueDate, so ALL rows matching the LP+instrument pair are deleted.
- `@ValueDate = specific date`: only the row with exactly that ValueDate is deleted; other ValueDate rows for the same instrument/account are kept (though in practice there is normally only one).
- If no matching rows exist, the DELETE is a no-op (0 rows affected, no error).

**Diagram**:
```
Hedge position for (LiquidityAccountID=10, InstrumentID=5) is closed
  |
  | EXEC Hedge.RemoveNetting @LiquidityAccountID=10, @InstrumentID=5
  |   (or with @ValueDate='2026-03-19' for date-specific removal)
  |
  | DELETE FROM Hedge.Netting
  | WHERE LiquidityAccountID=10 AND InstrumentID=5
  |   AND (ValueDate='2026-03-19' OR NULL IS NULL)
  |
  v
Hedge.Netting: row (10, 5, '2026-03-19') removed
  |
  +-> History.Netting_History: deleted row captured with SysEndTime = now
  +-> Any future Hedge.CalculateAccountStatusFromNetting excludes this instrument
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | INT | NO | - | CODE-BACKED | The LP account for which the position is being closed. Maps to Hedge.Netting.LiquidityAccountID (part of PK). |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument whose hedge position is being closed. Maps to Hedge.Netting.InstrumentID (part of PK). |
| 3 | @ValueDate | DATE | YES | NULL | CODE-BACKED | Optional settlement/value date filter. NULL (default) = remove all value dates for this LP+instrument combination. Specific date = remove only that date's row. Maps to Hedge.Netting.ValueDate (part of PK). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.Netting | DELETER | Removes closed hedge position row(s) |

### 5.2 Referenced By (other objects point to this)

Not found in SQL repo. Called from the hedge server application when a hedge position is fully closed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.RemoveNetting (procedure)
+-- Hedge.Netting (table) [DELETE WHERE LiquidityAccountID=X AND InstrumentID=Y AND ValueDate filter]
    +-- History.Netting_History (system-versioned) [receives deleted rows automatically]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Netting | Table | DELETE target for closed hedge positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from hedge server application when a hedge position is closed. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with THROW | Error handling | Exceptions re-thrown to caller. |
| (ValueDate = @ValueDate OR @ValueDate IS NULL) | Nullable filter pattern | When @ValueDate=NULL, the OR is always TRUE (removes all value dates). When provided, restricts to exact date match. Avoids two separate code paths for the two use cases. |
| System versioning | Automatic history | Deleted rows captured in History.Netting_History automatically with SysEndTime = deletion timestamp. |

---

## 8. Sample Queries

### 8.1 Close all value-date rows for an instrument on an account
```sql
EXEC [Hedge].[RemoveNetting]
    @LiquidityAccountID = 10,
    @InstrumentID       = 5
    -- @ValueDate defaults to NULL: removes all ValueDate rows
```

### 8.2 Close a specific value-date row (forward roll-off)
```sql
EXEC [Hedge].[RemoveNetting]
    @LiquidityAccountID = 10,
    @InstrumentID       = 5,
    @ValueDate          = '2026-03-19'
```

### 8.3 Verify the position before removal
```sql
SELECT LiquidityAccountID, InstrumentID, ValueDate,
       Units, IsBuy, AvgRate, ExecTime
FROM [Hedge].[Netting] WITH (NOLOCK)
WHERE LiquidityAccountID = 10
  AND InstrumentID = 5
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.RemoveNetting | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.RemoveNetting.sql*
