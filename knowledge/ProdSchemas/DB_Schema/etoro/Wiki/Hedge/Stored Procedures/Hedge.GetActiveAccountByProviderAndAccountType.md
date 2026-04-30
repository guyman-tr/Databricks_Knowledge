# Hedge.GetActiveAccountByProviderAndAccountType

> Returns active hedge server and liquidity account pairings filtered by liquidity provider type and account type, used to resolve which server handles a specific provider/account-type combination.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityProviderTypeID, @LiquidityAccountTypeID - provider and account type filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the (HedgeServerID, LiquidityAccountID) pairs that are active and match a specific combination of liquidity provider type and account type. It is used by the hedge engine to discover which hedge server and account handle a particular provider/account-type pairing - for example, to find the OMS hedge server (HedgeServerID) for IM pricing accounts.

The procedure queries through three objects to enrich and filter the result:
- `Hedge.Accounts` - the base account registry, filtered to `IsActive=1` and the requested `AccountTypeID`
- `Hedge.GetActiveProviderLiquidityAccounts` - the view of all active LP accounts with their hedge server assignments, filtered to the requested `LiquidityProviderTypeID`
- `Hedge.GetHedgeServerLiquidityProviderDetails` - provides the `HedgeServerID` for each active LP account

This layered approach leverages pre-built views to avoid duplicating the complex join logic needed to resolve hedge server-to-account assignments.

---

## 2. Business Logic

### 2.1 Triple-Join Filtering Pattern

**What**: Three objects are joined to simultaneously filter by active status, provider type, and account type, returning only the most specific routing combinations.

**Columns/Parameters Involved**: `@LiquidityProviderTypeID`, `@LiquidityAccountTypeID`, `IsActive`, `AccountTypeID`

**Rules**:
- `Hedge.Accounts.IsActive = 1` - only live, operational accounts are returned (hardcoded filter)
- `Hedge.Accounts.AccountTypeID = @LiquidityAccountTypeID` - filter by account type (e.g., 2=Execution, 4=OMS IM Pricing)
- `Hedge.GetActiveProviderLiquidityAccounts.LiquidityProviderTypeID = @LiquidityProviderTypeID` - filter by LP type (already filters to IsActive=1 in the view)
- All three JOINs are on `LiquidityAccountID` - the common key linking accounts to their hedge server assignments
- Returns (HedgeServerID, LiquidityAccountID) - minimum needed for routing decisions

**Diagram**:
```
Hedge.Accounts (IsActive=1, AccountTypeID=@LiquidityAccountTypeID)
  |
  +--[LiquidityAccountID JOIN]--> Hedge.GetActiveProviderLiquidityAccounts (LiquidityProviderTypeID=@LiquidityProviderTypeID)
  |
  +--[LiquidityAccountID JOIN]--> Hedge.GetHedgeServerLiquidityProviderDetails --> HedgeServerID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityProviderTypeID | int | NO | - | CODE-BACKED | Identifies the liquidity provider type to filter by (e.g., ZBFX, OMS, Talos). Filters `Hedge.GetActiveProviderLiquidityAccounts.LiquidityProviderTypeID`. Only accounts belonging to this LP type are returned. FK to `Trade.LiquidityProviderType`. |
| 2 | @LiquidityAccountTypeID | int | NO | - | CODE-BACKED | Identifies the account type to filter by. Filters `Hedge.Accounts.AccountTypeID`. Typical values: 2=Execution Account (used for real hedge orders), 4=OMS IM Pricing Account (used for IM calculations only). Combined with @LiquidityProviderTypeID, this uniquely identifies the routing intent. |

**Output Columns**:

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.GetHedgeServerLiquidityProviderDetails | The hedge server managing this account |
| LiquidityAccountID | Hedge.Accounts.ID | The liquidity account matching both filter criteria |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INNER JOIN | Hedge.Accounts | Direct read + filter | Base account registry, filtered to IsActive=1 and @LiquidityAccountTypeID |
| INNER JOIN | Hedge.GetActiveProviderLiquidityAccounts | View JOIN | Active LP accounts with hedge server assignments, filtered to @LiquidityProviderTypeID |
| INNER JOIN | Hedge.GetHedgeServerLiquidityProviderDetails | View JOIN | Provides HedgeServerID for each active LP account |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by hedge engine application for server/account routing discovery.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetActiveAccountByProviderAndAccountType (procedure)
├── Hedge.Accounts (table) - base account registry with type and active filters
├── Hedge.GetActiveProviderLiquidityAccounts (view) - active LP accounts by provider type
│     ├── Hedge.Accounts (table)
│     ├── Trade.LiquidityProviderType (table)
│     └── Hedge.HedgeServerToLiquidityAccount (table)
└── Hedge.GetHedgeServerLiquidityProviderDetails (view) - hedge server ID resolution
      ├── Hedge.Accounts (table)
      └── Hedge.HedgeServerToLiquidityAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Accounts | Table | INNER JOIN - filters to IsActive=1 and AccountTypeID=@LiquidityAccountTypeID |
| Hedge.GetActiveProviderLiquidityAccounts | View | INNER JOIN - provides active LP account list filtered to @LiquidityProviderTypeID |
| Hedge.GetHedgeServerLiquidityProviderDetails | View | INNER JOIN - provides HedgeServerID for each matching account |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Isolation | All tables joined with NOLOCK hints - dirty reads acceptable for configuration queries |
| IsActive hardcoded | Business Rule | `HA.IsActive = 1` is hardcoded - callers cannot override to include inactive accounts |

---

## 8. Sample Queries

### 8.1 Find all execution accounts for a specific LP type

```sql
SELECT ha.ID AS LiquidityAccountID, ha.Name, ha.AccountTypeID, ha.IsActive
FROM Hedge.Accounts ha WITH (NOLOCK)
WHERE ha.IsActive = 1
  AND ha.AccountTypeID = 2  -- Execution accounts only
ORDER BY ha.ID
```

### 8.2 Equivalent filtered view of active LP accounts by type

```sql
SELECT LiquidityAccountID, LiquidityProviderTypeID, HedgeServerID
FROM Hedge.GetActiveProviderLiquidityAccounts WITH (NOLOCK)
WHERE LiquidityProviderTypeID = 1  -- Example: ZBFX
ORDER BY HedgeServerID
```

### 8.3 Cross-reference accounts with hedge server details

```sql
SELECT apla.LiquidityAccountID, apla.HedgeServerID,
       ha.Name AS AccountName, ha.AccountTypeID
FROM Hedge.GetActiveProviderLiquidityAccounts apla WITH (NOLOCK)
INNER JOIN Hedge.Accounts ha WITH (NOLOCK) ON ha.ID = apla.LiquidityAccountID
WHERE ha.IsActive = 1
ORDER BY apla.HedgeServerID, apla.LiquidityAccountID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetActiveAccountByProviderAndAccountType | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetActiveAccountByProviderAndAccountType.sql*
