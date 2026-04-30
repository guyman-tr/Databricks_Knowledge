# Hedge.UpdateActiveHedgingAccounts

> Bulk-merges the hedge engine's active-account roster: updates IsActive for existing accounts and inserts new ones from the TVP, without deleting absent accounts.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @activeAccountMapping (TVP keyed on LiquidityAccountID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.UpdateActiveHedgingAccounts` is the **MERGE writer** for `Hedge.ActiveHedgingAccounts` - the hedge engine's overlay table that tracks which liquidity accounts are currently enabled for hedge order routing. When the hedge server reconfigures its account roster (activating or deactivating accounts), it calls this procedure with the desired state as a TVP.

This procedure exists to allow the hedge engine to update its account activation state without modifying the shared `Trade.LiquidityAccounts` table. The `Hedge.ActiveHedgingAccounts` table acts as an independent overlay and this procedure is the single write path into it.

Data flows as follows: the calling application or hedge server process populates a `Hedge.ActiveAccountMapping` TVP with pairs of (LiquidityAccountID, IsActive), then calls this procedure. The MERGE statement reconciles the TVP against the live table: accounts already in the table have their IsActive updated; accounts new to the table are inserted. Accounts that are in the table but absent from the TVP are left unchanged (no DELETE branch).

---

## 2. Business Logic

### 2.1 MERGE: Update Existing + Insert New (No Delete)

**What**: The MERGE reconciles the TVP against `Hedge.ActiveHedgingAccounts` on LiquidityAccountID.

**Columns/Parameters Involved**: `@activeAccountMapping`, `LiquidityAccountID`, `IsActive`

**Rules**:
- `WHEN MATCHED THEN UPDATE SET target.IsActive = source.IsActive` - existing accounts have their activation state overwritten.
- `WHEN NOT MATCHED BY TARGET THEN INSERT (LiquidityAccountID, IsActive)` - accounts in the TVP but not yet in the table are inserted.
- No `WHEN NOT MATCHED BY SOURCE` branch - accounts in the table but absent from the TVP are retained unchanged.
- This means the procedure cannot remove accounts from the roster; deletions must be done directly or the account's IsActive is set to 0.
- The TVP has a PK on LiquidityAccountID (`IGNORE_DUP_KEY = OFF`), so the caller must not pass duplicates.

**Diagram**:
```
@activeAccountMapping TVP:
  {LiquidityAccountID=8,  IsActive=0}   -> MATCHED  -> UPDATE IsActive=0 (deactivate ZBFX Price1)
  {LiquidityAccountID=9,  IsActive=1}   -> MATCHED  -> UPDATE IsActive=1 (keep active)
  {LiquidityAccountID=99, IsActive=1}   -> NOT MATCHED BY TARGET -> INSERT new row

Accounts in table but not in TVP -> NO CHANGE (preserved)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @activeAccountMapping | Hedge.ActiveAccountMapping | NO | - | CODE-BACKED | Read-only TVP carrying the desired activation state for each liquidity account. Each row: LiquidityAccountID (PK in TVP, FK to Trade.LiquidityAccounts) + IsActive (bit). Passed directly to the MERGE as the source. Duplicates in the TVP will cause an error (IGNORE_DUP_KEY=OFF on TVP PK). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @activeAccountMapping | Hedge.ActiveAccountMapping | TVP (UDT) | Input TVP type carrying account-level activation state |
| (MERGE target) | Hedge.ActiveHedgingAccounts | MODIFIER + WRITER | Updates IsActive for existing accounts; inserts new account rows |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Called externally by the hedge server or operator tooling during account configuration changes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.UpdateActiveHedgingAccounts (procedure)
+-- Hedge.ActiveHedgingAccounts (table) [MERGE target]
+-- Hedge.ActiveAccountMapping (type) [@activeAccountMapping parameter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ActiveHedgingAccounts | Table | MERGE target - updated and extended with new rows from the TVP |
| Hedge.ActiveAccountMapping | User Defined Type | Parameter type for @activeAccountMapping - defines the TVP schema (LiquidityAccountID PK, IsActive) |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MERGE with no DELETE branch | Design | Absent accounts are preserved; the procedure cannot remove accounts from the roster via this call |
| TVP PK (IGNORE_DUP_KEY=OFF) | Input validation | Caller must not pass duplicate LiquidityAccountIDs - will error on duplicate input |

---

## 8. Sample Queries

### 8.1 Activate account 9 and deactivate account 8
```sql
DECLARE @Mapping [Hedge].[ActiveAccountMapping];
INSERT INTO @Mapping (LiquidityAccountID, IsActive) VALUES (8, 0), (9, 1);

EXEC [Hedge].[UpdateActiveHedgingAccounts]
    @activeAccountMapping = @Mapping;
```

### 8.2 Verify result after update
```sql
SELECT aha.LiquidityAccountID,
       aha.IsActive
FROM   [Hedge].[ActiveHedgingAccounts] aha WITH (NOLOCK)
ORDER BY aha.LiquidityAccountID;
```

### 8.3 Bulk activate all known accounts
```sql
DECLARE @AllActive [Hedge].[ActiveAccountMapping];
INSERT INTO @AllActive (LiquidityAccountID, IsActive)
SELECT LiquidityAccountID, 1
FROM   [Hedge].[ActiveHedgingAccounts] WITH (NOLOCK);

EXEC [Hedge].[UpdateActiveHedgingAccounts]
    @activeAccountMapping = @AllActive;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.UpdateActiveHedgingAccounts | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.UpdateActiveHedgingAccounts.sql*
