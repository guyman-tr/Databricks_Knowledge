# Hedge.SyncLiquidityAccounts

> Corrects provider-type mismatches in Trade.LiquidityAccounts: for each liquidity account whose assigned provider type or account type no longer matches what Hedge.Accounts expects, updates it to the first available provider of the correct type (smallest LiquidityProviderID).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - operates on all mismatched accounts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.SyncLiquidityAccounts` is a **data-reconciliation procedure** that keeps `Trade.LiquidityAccounts` aligned with the configuration in `Hedge.Accounts`. Over time, the assigned liquidity provider for an account may become stale - for example, if the provider changes its type, or if the expected account type is updated in `Hedge.Accounts` but the corresponding row in `Trade.LiquidityAccounts` is not immediately updated. This procedure detects those gaps and corrects them automatically.

The procedure exists to maintain referential consistency between the Hedge schema's account registry (`Hedge.Accounts`, which stores the expected `LiquidityProviderTypeID` and `AccountTypeID`) and the Trade schema's liquidity account table (`Trade.LiquidityAccounts`, which stores the currently assigned `LiquidityProviderID` and `LiquidityAccountTypeID`). Without this sync, hedge servers could try to route orders through providers of the wrong type.

Data flows through this object as follows: the procedure runs a single CTE-based UPDATE with no parameters. It finds all `Trade.LiquidityAccounts` rows where the provider type or account type is out of sync with `Hedge.Accounts`, then assigns the first valid provider (by smallest LiquidityProviderID) for the correct type. Rows where the sync candidate's `NewLiquidityProviderID` is NULL (no matching provider found) are skipped.

---

## 2. Business Logic

### 2.1 Provider-Type Mismatch Detection

**What**: Two conditions trigger a sync for a LiquidityAccount row.

**Columns/Parameters Involved**: `LiquidityProviderTypeID` (LA vs LP), `AccountTypeID` (A vs LA.LiquidityAccountTypeID)

**Rules**:
- Condition 1: `LP.LiquidityProviderTypeID IS NULL OR LP.LiquidityProviderTypeID <> A.LiquidityProviderTypeID` - the current LiquidityProviderID assigned to the account references a provider of the wrong type (or references no provider at all / LEFT JOIN missed).
- Condition 2: `LA.LiquidityAccountTypeID <> A.AccountTypeID` - the account type in Trade.LiquidityAccounts doesn't match what Hedge.Accounts specifies.
- Either condition is sufficient to trigger the update (OR logic).
- If both provider type and account type are already correct, the row is excluded from the update.

### 2.2 "First Provider" Assignment (Deterministic)

**What**: When a mismatch is found, the procedure assigns the provider with the smallest LiquidityProviderID for the expected type.

**Columns/Parameters Involved**: `LiquidityProviderID`, `LiquidityProviderTypeID`

**Rules**:
- Uses `CROSS APPLY (SELECT TOP 1 ... FROM Trade.LiquidityProviders WHERE LiquidityProviderTypeID = A.LiquidityProviderTypeID ORDER BY LiquidityProviderID ASC)` to deterministically select the "first" provider.
- "First" = smallest LiquidityProviderID for the expected type - not necessarily the "best" or "primary" provider, just the one with the lowest ID.
- If no provider exists for the expected type, `NewLiquidityProviderID` is NULL and the WHERE clause (`WHERE C.NewLiquidityProviderID IS NOT NULL`) skips the update for that account.

**Diagram**:
```
Hedge.Accounts (expected):     A.LiquidityProviderTypeID = 3, A.AccountTypeID = 2
Trade.LiquidityAccounts (has): LA.LiquidityProviderID = 99 -> LP.LiquidityProviderTypeID = 5  [MISMATCH]

CROSS APPLY finds:  LP2 WHERE LiquidityProviderTypeID = 3 ORDER BY ID -> LP2.ID = 12

UPDATE Trade.LiquidityAccounts
  SET LiquidityProviderID  = 12  [corrected]
      LiquidityAccountTypeID = 2  [synced]
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|

No input parameters. The procedure takes no arguments and operates on all mismatched accounts automatically.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (join) | Trade.LiquidityAccounts | MODIFIER | Target of UPDATE - corrects LiquidityProviderID and LiquidityAccountTypeID |
| (join) | Hedge.Accounts | READER | Source of truth for expected LiquidityProviderTypeID and AccountTypeID |
| (join) | Trade.LiquidityProviders | READER | Used twice: to check current provider type (LEFT JOIN) and to find the new provider (CROSS APPLY TOP 1) |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Called externally by the hedge configuration or operational tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.SyncLiquidityAccounts (procedure)
+-- Trade.LiquidityAccounts (table) [MODIFIER - cross-schema]
+-- Hedge.Accounts (table) [READER]
+-- Trade.LiquidityProviders (table) [READER x2 - cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | Target of UPDATE (LiquidityProviderID, LiquidityAccountTypeID corrected) and source of current state |
| Hedge.Accounts | Table | Source of expected LiquidityProviderTypeID and AccountTypeID per account |
| Trade.LiquidityProviders | Table | Used to validate current provider type (LEFT JOIN) and find new correct provider (CROSS APPLY TOP 1 by smallest ID) |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE NewLiquidityProviderID IS NOT NULL | Safety guard | Skips accounts where no provider of the correct type exists - prevents NULL overwrites |
| No transaction wrapper | Atomicity | The UPDATE is a single statement and implicitly transactional at the statement level |
| No parameters | Design | The procedure always processes all mismatched accounts - no scoping by server or account |

---

## 8. Sample Queries

### 8.1 Preview which accounts would be updated (dry run)
```sql
;WITH Candidates AS (
    SELECT  LA.LiquidityAccountID,
            LA.LiquidityProviderID         AS CurrentProviderID,
            A.LiquidityProviderTypeID      AS ExpectedProviderTypeID,
            LP.LiquidityProviderTypeID     AS CurrentProviderTypeID,
            A.AccountTypeID                AS ExpectedAccountTypeID,
            LA.LiquidityAccountTypeID      AS CurrentAccountTypeID,
            CA.NewLiquidityProviderID
    FROM    Trade.LiquidityAccounts  AS LA WITH (NOLOCK)
    INNER JOIN Hedge.Accounts        AS A  WITH (NOLOCK) ON A.ID = LA.LiquidityAccountID
    LEFT  JOIN Trade.LiquidityProviders AS LP WITH (NOLOCK) ON LP.LiquidityProviderID = LA.LiquidityProviderID
    CROSS APPLY (
        SELECT TOP (1) LP2.LiquidityProviderID AS NewLiquidityProviderID
        FROM Trade.LiquidityProviders AS LP2 WITH (NOLOCK)
        WHERE LP2.LiquidityProviderTypeID = A.LiquidityProviderTypeID
        ORDER BY LP2.LiquidityProviderID ASC
    ) AS CA
    WHERE   (LP.LiquidityProviderTypeID IS NULL OR LP.LiquidityProviderTypeID <> A.LiquidityProviderTypeID)
         OR (LA.LiquidityAccountTypeID <> A.AccountTypeID)
)
SELECT * FROM Candidates WHERE NewLiquidityProviderID IS NOT NULL;
```

### 8.2 Verify sync result: check for remaining mismatches after executing
```sql
SELECT  LA.LiquidityAccountID,
        LA.LiquidityProviderID,
        A.LiquidityProviderTypeID AS ExpectedTypeID,
        LP.LiquidityProviderTypeID AS ActualTypeID
FROM    Trade.LiquidityAccounts  LA WITH (NOLOCK)
INNER JOIN Hedge.Accounts         A  WITH (NOLOCK) ON A.ID = LA.LiquidityAccountID
LEFT  JOIN Trade.LiquidityProviders LP WITH (NOLOCK) ON LP.LiquidityProviderID = LA.LiquidityProviderID
WHERE   LP.LiquidityProviderTypeID IS NULL
     OR LP.LiquidityProviderTypeID <> A.LiquidityProviderTypeID
     OR LA.LiquidityAccountTypeID <> A.AccountTypeID;
-- Should return 0 rows after a successful sync
```

### 8.3 Execute the sync
```sql
EXEC [Hedge].[SyncLiquidityAccounts];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.SyncLiquidityAccounts | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.SyncLiquidityAccounts.sql*
