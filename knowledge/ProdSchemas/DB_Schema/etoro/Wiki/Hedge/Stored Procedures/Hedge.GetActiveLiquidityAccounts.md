# Hedge.GetActiveLiquidityAccounts

> Returns active liquidity accounts of a specified type from the Trade schema, providing the hedge engine with the current set of operational accounts for a given account type category.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityAccountType - account type filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all active liquidity accounts of a specified type from `Trade.LiquidityAccounts`. It provides the hedge engine with a filtered list of currently active accounts in a given category, along with the key metadata needed for routing: account ID, name, provider ID, type, and rate source.

Despite being in the `Hedge` schema, this procedure reads exclusively from `Trade.LiquidityAccounts` - a cross-schema query reflecting the fact that liquidity account configuration is owned by the Trade schema but consumed by the hedge engine.

The `LiquidityAccountTypeID` parameter enables the caller to retrieve specific subsets: execution accounts, pricing accounts, or other categories, avoiding the need to filter client-side.

---

## 2. Business Logic

### 2.1 Active Account Filter by Type

**What**: The procedure applies two filters: `IsActive=1` (operational accounts only) and `LiquidityAccountTypeID=@LiquidityAccountType` (specific category).

**Columns/Parameters Involved**: `@LiquidityAccountType`, `IsActive`, `LiquidityAccountTypeID`

**Rules**:
- `IsActive = 1` - hardcoded filter, deactivated accounts are always excluded
- `LiquidityAccountTypeID = @LiquidityAccountType` - exactly one type returned per call
- Known account type values (from `Hedge.Accounts` doc and codebase context):
  - 2: Execution Account (used for real hedge orders)
  - 4: OMS IM Pricing Account (pricing/margin calculations only)
- Returns 5 columns sufficient for hedge engine initialization: LiquidityAccountID, LiquidityAccountName, LiquidityProviderID, LiquidityAccountTypeID, AccountRateSourceID

### 2.2 Cross-Schema Configuration Access

**What**: Despite being a Hedge schema procedure, it reads from Trade schema - reflecting the ownership boundary of liquidity account configuration.

**Rules**:
- `Trade.LiquidityAccounts` owns the liquidity account registry
- The Hedge schema provides a filtered view via this procedure
- `(nolock)` hint is applied directly on the table reference (inline syntax, not WITH keyword)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountType | int | NO | - | CODE-BACKED | The account type to filter by (LiquidityAccountTypeID). All active accounts of this type are returned. Common values: 2=Execution accounts (for hedge order placement), 4=OMS IM Pricing accounts (for margin calculations). FK to the account type lookup. |

**Output Columns** (from `Trade.LiquidityAccounts`):

| Column | Description |
|--------|-------------|
| LiquidityAccountID | Primary key of the liquidity account |
| LiquidityAccountName | Human-readable name of the account (e.g., "ZBFX Server 1") |
| LiquidityProviderID | FK to Trade.LiquidityProviders - identifies the broker |
| LiquidityAccountTypeID | Account category (matches @LiquidityAccountType filter) |
| AccountRateSourceID | The rate source used for this account's pricing |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Trade.LiquidityAccounts | Direct read (SELECT) | Source of all liquidity account configuration data |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine application to load account configuration on startup or refresh.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetActiveLiquidityAccounts (procedure)
└── Trade.LiquidityAccounts (table) - SELECT source [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | SELECT with filters IsActive=1 AND LiquidityAccountTypeID=@LiquidityAccountType |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hint | Isolation | `(nolock)` applied inline (older T-SQL syntax without WITH keyword) - dirty reads acceptable for configuration |
| IsActive hardcoded | Business Rule | Always filters to IsActive=1 - inactive accounts cannot be retrieved via this SP |

---

## 8. Sample Queries

### 8.1 Get all active execution accounts

```sql
SELECT LiquidityAccountID, LiquidityAccountName, LiquidityProviderID,
       LiquidityAccountTypeID, AccountRateSourceID
FROM Trade.LiquidityAccounts WITH (NOLOCK)
WHERE IsActive = 1
  AND LiquidityAccountTypeID = 2  -- Execution accounts
ORDER BY LiquidityAccountID
```

### 8.2 Get active OMS pricing accounts

```sql
SELECT LiquidityAccountID, LiquidityAccountName, LiquidityProviderID,
       LiquidityAccountTypeID, AccountRateSourceID
FROM Trade.LiquidityAccounts WITH (NOLOCK)
WHERE IsActive = 1
  AND LiquidityAccountTypeID = 4  -- OMS IM Pricing
ORDER BY LiquidityAccountID
```

### 8.3 Count active accounts by type

```sql
SELECT LiquidityAccountTypeID, COUNT(*) AS ActiveAccountCount
FROM Trade.LiquidityAccounts WITH (NOLOCK)
WHERE IsActive = 1
GROUP BY LiquidityAccountTypeID
ORDER BY LiquidityAccountTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetActiveLiquidityAccounts | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetActiveLiquidityAccounts.sql*
