# Hedge.ActiveAccountMapping

> Table-valued parameter type carrying per-liquidity-account activation state for bulk update operations on the active hedging account roster.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | LiquidityAccountID (PRIMARY KEY CLUSTERED) |
| **Partition** | N/A |
| **Indexes** | 1 (PK CLUSTERED on LiquidityAccountID) |

---

## 1. Business Meaning

`Hedge.ActiveAccountMapping` is a SQL Table-Valued Parameter (TVP) type used to pass a set of liquidity account IDs together with their desired active/inactive state into a stored procedure in a single call. It acts as an in-memory batch payload rather than a persistent table.

Without this type, callers would need to pass account states one at a time or construct dynamic SQL. The TVP lets the hedge server reconcile its full account roster in one atomic operation, which is critical for correctness during hedging account reconfiguration events.

Data flows into this type from the calling application or orchestration service when it needs to activate or deactivate a set of liquidity accounts on a hedge server. The populated TVP is passed as a parameter to `Hedge.UpdateActiveHedgingAccounts`, which reconciles it against `Hedge.ActiveHedgingAccounts`.

---

## 2. Business Logic

### 2.1 Active/Inactive Toggle Semantics

**What**: Each row in the TVP represents a directive - "set this liquidity account to active/inactive."

**Columns/Parameters Involved**: `LiquidityAccountID`, `IsActive`

**Rules**:
- `IsActive = 1`: the account should be considered active for hedging operations on this hedge server.
- `IsActive = 0`: the account should be deactivated - the hedge server stops routing orders through it.
- The PK constraint (`IGNORE_DUP_KEY = OFF`) means the caller must not pass duplicate `LiquidityAccountID` values; the operation will fail if duplicates are present.
- The consumer (`UpdateActiveHedgingAccounts`) uses this TVP to reconcile the live `Hedge.ActiveHedgingAccounts` table.

**Diagram**:
```
Caller (app/service)
  |
  | passes Hedge.ActiveAccountMapping TVP
  v
Hedge.UpdateActiveHedgingAccounts (SP)
  |
  +-- MERGE / UPDATE --> Hedge.ActiveHedgingAccounts (table)
```

---

## 3. Data Overview

N/A for User Defined Type. This type is an in-memory parameter container - no rows are stored persistently.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | CODE-BACKED | Identifier of the liquidity (broker) account whose active state is being set. FK pattern to `Hedge.Accounts.LiquidityAccountID` (Trade.LiquidityAccounts). PK of this TVP - duplicate account IDs in the same batch are rejected (IGNORE_DUP_KEY = OFF). |
| 2 | IsActive | bit | NO | - | CODE-BACKED | Desired activation state for this account: 1 = account is active and eligible for hedge order routing, 0 = account is deactivated and should be excluded from routing. Passed to `Hedge.UpdateActiveHedgingAccounts` to reconcile `Hedge.ActiveHedgingAccounts`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Hedge.ActiveHedgingAccounts | Implicit | Values correspond to LiquidityAccountID rows in the active hedging accounts table that will be updated |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.UpdateActiveHedgingAccounts | @ActiveAccounts parameter | TVP parameter | Consumes this type to reconcile the active hedging account roster |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (leaf TVP type, no FROM/JOIN in its definition).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.UpdateActiveHedgingAccounts | Stored Procedure | Declares a parameter of this type to receive the batch of account activation states |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (inline) | CLUSTERED | LiquidityAccountID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (inline) | PRIMARY KEY | IGNORE_DUP_KEY = OFF - duplicate LiquidityAccountID entries in the same TVP call cause an error |

---

## 8. Sample Queries

### 8.1 Declare and populate the TVP
```sql
DECLARE @Accounts [Hedge].[ActiveAccountMapping]
INSERT INTO @Accounts (LiquidityAccountID, IsActive)
VALUES (101, 1), (102, 0), (103, 1)

EXEC [Hedge].[UpdateActiveHedgingAccounts] @ActiveAccounts = @Accounts
```

### 8.2 Check which accounts are currently active
```sql
SELECT LiquidityAccountID, IsActive
FROM [Hedge].[ActiveHedgingAccounts] WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY LiquidityAccountID
```

### 8.3 Find the SP that consumes this TVP
```sql
SELECT name, type_desc
FROM sys.objects WITH (NOLOCK)
WHERE name = 'UpdateActiveHedgingAccounts'
  AND schema_id = SCHEMA_ID('Hedge')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ActiveAccountMapping | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.ActiveAccountMapping.sql*
