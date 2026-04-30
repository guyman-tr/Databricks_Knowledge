# Hedge.RemoveMultiBadNetting

> Multi-LP variant of RemoveBadNetting: deletes all Hedge.Netting rows for a HedgeServerID where the LiquidityAccountID is NOT in the server's currently configured valid accounts (from Hedge.HedgeServerToLiquidityAccount). Used when a server is connected to multiple LP accounts and stale rows from removed/expired LP assignments must be purged.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DELETE from Hedge.Netting WHERE HedgeServerID=X AND LiquidityAccountID NOT IN (valid set from HedgeServerToLiquidityAccount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.RemoveMultiBadNetting` is the multi-LP upgrade of `Hedge.RemoveBadNetting`. Where `RemoveBadNetting` enforces a single expected LP account (inequality against one value), this procedure enforces the FULL SET of valid LP accounts for a hedge server - fetching that set dynamically from `Hedge.HedgeServerToLiquidityAccount`.

Use case: a hedge server may be legitimately connected to multiple LP accounts (e.g., LP account 10 for standard instruments, LP account 12 for crypto, LP account 15 for FX forwards). Any netting row under a LiquidityAccountID not in this set is "bad" - it belongs to a LP account that has been removed from the server's configuration, or was created in error.

This procedure is the correct cleanup path when `RemoveBadNetting` would be too aggressive (removing all rows except one specific LP account), which would incorrectly purge valid positions on other configured accounts.

Unlike `RemoveBadNetting`, this procedure does NOT have an `OUTPUT DELETED.*` clause - the deleted rows are not returned to the caller.

---

## 2. Business Logic

### 2.1 Dynamic Valid LP Set from HedgeServerToLiquidityAccount

**What**: The set of valid LP accounts is computed at execution time from the configuration table, not hardcoded.

**Columns/Parameters Involved**: `@HedgeServerID`, `Hedge.HedgeServerToLiquidityAccount`

**Rules**:
- Subquery: `SELECT LiquidityAccountID FROM Hedge.HedgeServerToLiquidityAccount WHERE HedgeServerID = @HedgeServerID`.
- The NOT IN filter excludes rows from any LP account NOT in this subquery result.
- If `HedgeServerToLiquidityAccount` has no entries for the server (e.g., during initial setup), the NOT IN becomes NOT IN (empty set) = ALL rows would be deleted. Caller should verify the configuration table is populated before running.
- If the subquery returns 1, 2, or N accounts, the procedure correctly handles each case - unlike RemoveBadNetting which only supports a single valid account.

**Diagram**:
```
HedgeServerID=1 is configured for LP accounts 10, 12 in HedgeServerToLiquidityAccount
  |
  | EXEC Hedge.RemoveMultiBadNetting @HedgeServerID=1
  |
  | DELETE FROM Hedge.Netting
  | WHERE HedgeServerID=1
  |   AND LiquidityAccountID NOT IN (
  |     SELECT LiquidityAccountID FROM Hedge.HedgeServerToLiquidityAccount
  |     WHERE HedgeServerID=1
  |   )
  |
  v
Deleted: rows with LiquidityAccountID=5 (old LP, removed from config)
Kept: rows with LiquidityAccountID=10, 12 (currently configured)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server whose netting positions are being cleaned. Used both as the filter on Hedge.Netting and as the parameter to the HedgeServerToLiquidityAccount subquery that determines the valid LP set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.Netting | DELETER | Removes netting rows for LP accounts not in the valid configuration set |
| - | Hedge.HedgeServerToLiquidityAccount | Reader | Provides the dynamic set of valid LP accounts for the given server |

### 5.2 Referenced By (other objects point to this)

Not found in SQL repo. Called from the hedge server application during LP configuration changes or recovery.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.RemoveMultiBadNetting (procedure)
|-- Hedge.HedgeServerToLiquidityAccount (table) [READ - valid LP accounts for the server]
+-- Hedge.Netting (table) [DELETE WHERE LiquidityAccountID NOT IN valid set]
    +-- History.Netting_History (system-versioned) [receives deleted rows automatically]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | Read: valid LP account IDs for the server (the NOT IN set) |
| Hedge.Netting | Table | DELETE target for stale LP account netting rows |

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
| TRY/CATCH with THROW | Error handling | Exceptions re-thrown to caller. |
| NOT IN (subquery) | Dynamic set exclusion | If HedgeServerToLiquidityAccount is empty for the server, ALL netting rows for that server are deleted. Caller should verify configuration before running. |
| No OUTPUT clause | Difference from RemoveBadNetting | Deleted rows are not returned to the caller (only captured in History.Netting_History via system versioning). |
| System versioning | Automatic history | Deleted rows captured in History.Netting_History automatically. |

---

## 8. Sample Queries

### 8.1 Clean netting rows for server 1 that are not in its valid LP set
```sql
EXEC [Hedge].[RemoveMultiBadNetting]
    @HedgeServerID = 1
```

### 8.2 Preview what would be deleted (verify before running)
```sql
SELECT n.*
FROM [Hedge].[Netting] n WITH (NOLOCK)
WHERE n.HedgeServerID = 1
  AND n.LiquidityAccountID NOT IN (
      SELECT LiquidityAccountID
      FROM [Hedge].[HedgeServerToLiquidityAccount] WITH (NOLOCK)
      WHERE HedgeServerID = 1
  )
```

### 8.3 Verify valid LP accounts for a server before cleanup
```sql
SELECT HedgeServerID, LiquidityAccountID
FROM [Hedge].[HedgeServerToLiquidityAccount] WITH (NOLOCK)
WHERE HedgeServerID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.RemoveMultiBadNetting | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.RemoveMultiBadNetting.sql*
