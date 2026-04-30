# Hedge.GetAllLiquidityAccountsMetadata

> Returns display metadata for all liquidity accounts - account ID, name, and provider type name - by joining three Trade schema tables. Used for account labeling and reporting where human-readable provider names are needed.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns metadata for ALL liquidity accounts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves the display names for all liquidity accounts by traversing the three-level account-provider-providertype hierarchy in the Trade schema. It returns the minimum metadata needed to label accounts in monitoring dashboards and reports: the account identifier, its configured name, and the human-readable provider type name.

The join chain is:
- `Trade.LiquidityAccounts` - holds the account ID, name, and FK to its provider instance
- `Trade.LiquidityProviders` - bridge table linking accounts to provider types
- `Trade.LiquidityProviderType` - defines the provider type name (e.g., "FXCM", "ZBFX", "Saxo")

The result allows the hedge monitoring system to display provider names alongside account identifiers without requiring callers to know the Trade schema join path. This abstracts the three-table lookup behind a single procedure call.

Key characteristics:
- No WHERE clause - returns ALL accounts, including inactive ones
- No `WITH (NOLOCK)` - uses default READ COMMITTED isolation (unlike most Hedge schema reads)
- No IsActive filter - returns the full account registry, not just active accounts

For active-account-only reads, use `Hedge.GetActiveLiquidityAccounts` (filters by IsActive=1 and a specific account type).

---

## 2. Business Logic

### 2.1 Three-Table Provider Name Resolution

**What**: Resolves the provider type name for each liquidity account through the account -> provider -> provider type join chain.

**Columns/Parameters Involved**: `LiquidityAccountID`, `LiquidityAccountName`, `LiquidityProviderID`, `LiquidityProviderTypeID`, `Name`

**Rules**:
- `Trade.LiquidityAccounts.LiquidityProviderID` -> `Trade.LiquidityProviders.LiquidityProviderID` (INNER JOIN)
- `Trade.LiquidityProviders.LiquidityProviderTypeID` -> `Trade.LiquidityProviderType.LiquidityProviderTypeID` (INNER JOIN)
- Result column `LiquidityAccountProvider` is aliased from `Trade.LiquidityProviderType.Name`
- Both JOINs are INNER JOINs - accounts without a provider or provider without a type are excluded from results
- No IsActive filter - inactive accounts are included as long as their provider chain resolves

### 2.2 No Active Filter (All Accounts)

**What**: Unlike `GetActiveLiquidityAccounts` which filters to IsActive=1, this procedure returns all accounts.

**Rules**:
- Inactive accounts (IsActive=0) are included
- All account types are included (Price, Execution, OMS IM Pricing, etc.)
- The full account registry is exposed - caller is responsible for filtering by status or type if needed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Returns all rows from `Trade.LiquidityAccounts` joined to provider name. No filtering by active status or account type. |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts.LiquidityAccountID | The unique identifier for the liquidity account. FK to Hedge.Accounts (mirror). Used as the join key for most Hedge schema queries. |
| LiquidityAccountName | Trade.LiquidityAccounts.LiquidityAccountName | Human-readable name for the account (e.g., "ZBFX Price1 Rates", "FXCM Production Execution"). Used for display in monitoring UIs. |
| LiquidityAccountProvider | Trade.LiquidityProviderType.Name | The provider type name (e.g., "ZBFX", "FXCM", "Saxo"). Resolved via the LiquidityProviders bridge table. Multiple accounts may share the same provider type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM source | Trade.LiquidityAccounts | Direct read (INNER JOIN base) | Account identifiers and names |
| JOIN | Trade.LiquidityProviders | INNER JOIN | Bridge from account to provider type via LiquidityProviderID |
| JOIN | Trade.LiquidityProviderType | INNER JOIN | Resolves provider type name via LiquidityProviderTypeID |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by hedge monitoring or reporting components that need provider-labeled account metadata.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAllLiquidityAccountsMetadata (procedure)
├── Trade.LiquidityAccounts (table) - base account data
├── Trade.LiquidityProviders (table) - provider bridge (JOIN on LiquidityProviderID)
└── Trade.LiquidityProviderType (table) - provider type name (JOIN on LiquidityProviderTypeID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FROM clause base; provides LiquidityAccountID, LiquidityAccountName, LiquidityProviderID |
| Trade.LiquidityProviders | Table | INNER JOIN bridge; resolves LiquidityProviderID to LiquidityProviderTypeID |
| Trade.LiquidityProviderType | Table | INNER JOIN; provides the `Name` column returned as LiquidityAccountProvider |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK | Isolation | Uses default READ COMMITTED (no WITH NOLOCK hint) - stricter than most Hedge schema reads |
| INNER JOINs | Design | Accounts without a provider or provider types without a name are excluded from results |
| No active filter | Design | Returns ALL accounts regardless of IsActive status - includes inactive/decommissioned accounts |
| No type filter | Design | Returns all LiquidityAccountTypeIDs - Price, Execution, OMS IM Pricing, etc. |

---

## 8. Sample Queries

### 8.1 Equivalent query with active filter

```sql
SELECT tla.LiquidityAccountID, tla.LiquidityAccountName, tlpt.Name AS LiquidityAccountProvider
FROM Trade.LiquidityAccounts tla WITH (NOLOCK)
JOIN Trade.LiquidityProviders tlp ON tla.LiquidityProviderID = tlp.LiquidityProviderID
JOIN Trade.LiquidityProviderType tlpt ON tlp.LiquidityProviderTypeID = tlpt.LiquidityProviderTypeID
WHERE tla.IsActive = 1
ORDER BY tlpt.Name, tla.LiquidityAccountName
```

### 8.2 Accounts grouped by provider type

```sql
SELECT tlpt.Name AS ProviderType,
       COUNT(*) AS AccountCount,
       STRING_AGG(tla.LiquidityAccountName, ', ') AS AccountNames
FROM Trade.LiquidityAccounts tla WITH (NOLOCK)
JOIN Trade.LiquidityProviders tlp ON tla.LiquidityProviderID = tlp.LiquidityProviderID
JOIN Trade.LiquidityProviderType tlpt ON tlp.LiquidityProviderTypeID = tlpt.LiquidityProviderTypeID
GROUP BY tlpt.Name
ORDER BY AccountCount DESC
```

### 8.3 Check accounts by type (execution vs price)

```sql
SELECT tla.LiquidityAccountID, tla.LiquidityAccountName,
       tlpt.Name AS ProviderType,
       tla.LiquidityAccountTypeID
FROM Trade.LiquidityAccounts tla WITH (NOLOCK)
JOIN Trade.LiquidityProviders tlp ON tla.LiquidityProviderID = tlp.LiquidityProviderID
JOIN Trade.LiquidityProviderType tlpt ON tlp.LiquidityProviderTypeID = tlpt.LiquidityProviderTypeID
WHERE tla.LiquidityAccountTypeID = 2  -- Execution accounts
ORDER BY tlpt.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAllLiquidityAccountsMetadata | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAllLiquidityAccountsMetadata.sql*
