# Hedge.RemoveBadNetting

> Deletes all Hedge.Netting rows for a given HedgeServerID where LiquidityAccountID does NOT match the expected account, returning deleted rows via OUTPUT DELETED.*. Used to clean up stale netting positions from an incorrect or previous LP assignment for a single-LP server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DELETE from Hedge.Netting WHERE HedgeServerID=X AND LiquidityAccountID!=Y; OUTPUT DELETED.* |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.RemoveBadNetting` is a data integrity cleanup procedure for single-LP hedge server configurations. When a hedge server should be connected to exactly one liquidity provider account, any netting rows in `Hedge.Netting` that belong to OTHER LP accounts (for the same server ID) are "bad" - they represent stale data from a previous configuration, a misconfiguration, or a leftover from a failover event.

Created on 2015-09-07 by Geri Reshef (Case 26716) to address the specific scenario where netting rows accumulate under the wrong LP account ID and need to be cleaned out.

The procedure deletes all netting rows for the given `@HedgeServerID` that have a `LiquidityAccountID` OTHER than `@LiquidityAccountID`, and returns the deleted rows to the caller via `OUTPUT DELETED.*`. This output allows the caller to log what was removed or take corrective action.

For multi-LP servers (where a hedge server is legitimately configured with multiple LP accounts), use `Hedge.RemoveMultiBadNetting` instead - which validates against the full set of valid LP accounts from `Hedge.HedgeServerToLiquidityAccount`.

---

## 2. Business Logic

### 2.1 Cross-Account Netting Cleanup (Inequality Filter)

**What**: Removes all netting rows for a server that do NOT belong to the expected LP account.

**Columns/Parameters Involved**: `@HedgeServerID`, `@LiquidityAccountID`

**Rules**:
- Filter: `HedgeServerID = @HedgeServerID AND LiquidityAccountID != @LiquidityAccountID`.
- Keeps all rows WHERE LiquidityAccountID = @LiquidityAccountID (the correct account).
- Deletes all other rows for the same HedgeServerID (rows from other LP accounts).
- This is the "single expected LP" assumption: for a server that should only have one LP account, any row with a different LP account ID is incorrect.
- Use case example: HedgeServerID=1 was previously connected to LiquidityAccountID=5 but is now configured for LiquidityAccountID=10. Calling with `@HedgeServerID=1, @LiquidityAccountID=10` removes all LiquidityAccountID=5 (and any other non-10) rows for server 1.

### 2.2 OUTPUT DELETED.* Return Semantics

**What**: The procedure returns all deleted rows to the caller for audit and downstream action.

**Rules**:
- `OUTPUT Deleted.*`: returns all columns of each deleted Netting row in the result set.
- Caller can log the removed positions, send alerts, or audit the cleanup.
- Since `Hedge.Netting` uses system-versioning, the deleted rows are also automatically captured in `History.Netting_History` with their deletion timestamp.

**Diagram**:
```
HedgeServer reconnects with new LP configuration
  |
  | EXEC Hedge.RemoveBadNetting @HedgeServerID=1, @LiquidityAccountID=10
  |
  | DELETE FROM Hedge.Netting OUTPUT Deleted.*
  | WHERE HedgeServerID=1 AND LiquidityAccountID != 10
  |
  v
Returns result set: all deleted netting rows (LiquidityAccountID=5, etc.)
  |
  +-> History.Netting_History: rows auto-captured with deletion timestamp
  +-> Hedge.Netting: only LiquidityAccountID=10 rows remain for server 1
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server whose netting positions are being cleaned. Only rows WITH this HedgeServerID are considered; rows for other servers are unaffected. Maps to Hedge.Netting.HedgeServerID filter. |
| 2 | @LiquidityAccountID | INT | NO | - | CODE-BACKED | The CORRECT/expected LP account for this server. Rows with this LiquidityAccountID are KEPT. Rows with any other LiquidityAccountID are deleted. This is the LP account the server should currently be using. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.Netting | DELETER | Removes cross-account netting rows; OUTPUT returns deleted rows |

### 5.2 Referenced By (other objects point to this)

Not found in SQL repo. Called from the hedge server application during LP reconnect/reconfiguration.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.RemoveBadNetting (procedure)
+-- Hedge.Netting (table) [DELETE WHERE HedgeServerID=X AND LiquidityAccountID!=Y]
    +-- History.Netting_History (system-versioned history) [receives deleted rows automatically]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Netting | Table | DELETE target with OUTPUT DELETED.* for cross-account row cleanup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from hedge server application during LP configuration changes. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with PRINT + THROW | Error handling | On error: prints detailed diagnostic string (ServerName, DB, Procedure, Line, Error_Message, Severity) then re-throws. The PRINT allows error context to be captured in SQL Server error logs. |
| System versioning | Automatic history | Deleted rows are captured in History.Netting_History automatically. |
| LiquidityAccountID != filter | Inequality predicate | Keeps correct LP rows, removes all others. If @LiquidityAccountID does not exist for this server, ALL rows for the server would be deleted. |

---

## 8. Sample Queries

### 8.1 Clean netting rows for server 1 that are not on LP account 10
```sql
EXEC [Hedge].[RemoveBadNetting]
    @HedgeServerID       = 1,
    @LiquidityAccountID  = 10
-- Returns: all deleted netting rows (if any)
```

### 8.2 Check what would be removed before running (preview)
```sql
SELECT *
FROM [Hedge].[Netting] WITH (NOLOCK)
WHERE HedgeServerID = 1
  AND LiquidityAccountID != 10
```

### 8.3 Verify only the correct LP account's rows remain after cleanup
```sql
SELECT LiquidityAccountID, COUNT(1) AS RowCount
FROM [Hedge].[Netting] WITH (NOLOCK)
WHERE HedgeServerID = 1
GROUP BY LiquidityAccountID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.RemoveBadNetting | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.RemoveBadNetting.sql*
