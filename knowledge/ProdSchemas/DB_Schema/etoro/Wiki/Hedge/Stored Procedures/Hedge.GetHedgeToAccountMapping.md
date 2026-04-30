# Hedge.GetHedgeToAccountMapping

> Returns the complete hedge server to liquidity account mapping including ALL account types (no AccountTypeID filter). Unlike GetHedgeServerInfo and GetHedgeServerMetaData which exclude OMS pricing accounts, this procedure includes them - providing the raw unfiltered mapping used for full topology audit and OMS configuration tooling.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all hedge server -> account mappings |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHedgeToAccountMapping provides the complete, unfiltered mapping between hedge servers and their associated liquidity accounts. It is the simplest topology read in the Hedge schema: a two-table join with no parameters, no WHERE clause filtering, and no OMS pricing account exclusion.

The critical distinction from GetHedgeServerInfo and GetHedgeServerMetaData is the **absence of `AccountTypeID != 4`**. Those procedures are operational - they exclude OMS pricing accounts (AccountTypeID=4) because those accounts don't execute real trades. This procedure is a raw configuration view that includes ALL accounts, including OMS pricing accounts. This makes it appropriate for:
- Full topology audit (see which servers are linked to OMS pricing accounts)
- OMS configuration tooling (needs to see AccountTypeID=4 entries)
- Configuration validation (verify all expected mappings exist)

The `SET TRAN ISOLATION LEVEL READ UNCOMMITTED` directive applies dirty reads across the procedure - appropriate for config reads.

No SQL callers found within the Hedge schema; called externally by configuration tooling.

---

## 2. Business Logic

### 2.1 No Account Type Filtering (Key Difference from GetHedgeServerInfo)

**What**: All account types are returned including OMS pricing accounts (AccountTypeID=4).

**Columns/Parameters Involved**: N/A - no WHERE clause

**Rules**:
- No `AccountTypeID != 4` filter. Compare to GetHedgeServerInfo and GetHedgeServerMetaData which both explicitly filter out AccountTypeID=4.
- This means OMS IM Pricing Accounts appear in the result set alongside Execution Accounts.
- Callers must apply their own AccountTypeID filter if they only want operational execution accounts.
- The procedure intentionally provides the full picture for audit and configuration tooling scenarios.

### 2.2 Two-Table Join: Server -> Account

**What**: Maps each HedgeServerID to its account(s) with account metadata.

**Rules**:
- `Hedge.HedgeServerToLiquidityAccount HTLA JOIN Hedge.Accounts HA ON HTLA.LiquidityAccountID = HA.ID`
- Returns 4 columns: HedgeServerID, LiquidityAccountID, LiquidityProviderTypeID, LiquidityAccountName (HA.Name).
- No ORDER BY. Result order is undefined (physical/index order of HedgeServerToLiquidityAccount).
- A hedge server with multiple accounts produces multiple rows (same HedgeServerID, different LiquidityAccountID).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server identifier from HedgeServerToLiquidityAccount. All hedge servers that have at least one account mapping. |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | Liquidity account ID from HedgeServerToLiquidityAccount. ALL account types included (not filtered by AccountTypeID). |
| 3 | LiquidityProviderTypeID | int | YES | - | CODE-BACKED | Provider type identifier from Hedge.Accounts. Indicates the provider category (e.g., FXCM, BMFN, eToro). FK to Trade.LiquidityProviderType. |
| 4 | LiquidityAccountName | nvarchar | YES | - | CODE-BACKED | Human-readable account name from Hedge.Accounts.Name (aliased). Includes names of both execution and OMS pricing accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HTLA source | Hedge.HedgeServerToLiquidityAccount | Lookup / Read | All rows, no filter. Full server -> account mapping. |
| HA join | Hedge.Accounts | Lookup / Read | Name, LiquidityProviderTypeID. ALL account types including AccountTypeID=4. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Configuration tooling (external) | Result set | Caller | Full topology audit; OMS configuration that needs to see all account types. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHedgeToAccountMapping (procedure)
├── Hedge.HedgeServerToLiquidityAccount (table)
└── Hedge.Accounts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | All rows: HedgeServerID, LiquidityAccountID. No filter. |
| Hedge.Accounts | Table | JOIN ON LiquidityAccountID = ID. Name, LiquidityProviderTypeID. All AccountTypeIDs included. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Configuration tooling (external) | Application | Full server -> account mapping including OMS pricing accounts. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

`SET TRAN ISOLATION LEVEL READ UNCOMMITTED` - all reads are dirty reads. No temp tables. Simple two-table JOIN. No ORDER BY. Lightest possible read - simpler even than GetHedgeServerInfo which has a WHERE clause.

**Comparison with related procedures**:

| Procedure | AccountTypeID filter | Parameters | Provider info |
|-----------|---------------------|------------|---------------|
| GetHedgeToAccountMapping | NONE (all types) | None | LiquidityProviderTypeID only |
| GetHedgeServerInfo | != 4 (exec only) | @HedgeServerID | FIX connection (ConnectionID, Name) |
| GetHedgeServerMetaData | != 4 (exec only) | None | LiquidityProviderType Name + THS columns |

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetHedgeToAccountMapping;
```

### 8.2 Find OMS pricing account mappings

```sql
-- GetHedgeToAccountMapping returns ALL account types
-- Filter post-call to find OMS pricing accounts
SELECT HedgeServerID, LiquidityAccountID, LiquidityAccountName
FROM   Hedge.HedgeServerToLiquidityAccount HTLA
JOIN   Hedge.Accounts HA ON HTLA.LiquidityAccountID = HA.ID
WHERE  HA.AccountTypeID = 4;
```

### 8.3 Compare with GetHedgeServerInfo (execution accounts only)

```sql
-- GetHedgeToAccountMapping: ALL accounts
EXEC Hedge.GetHedgeToAccountMapping;

-- GetHedgeServerInfo: execution accounts only (AccountTypeID != 4) for one server
EXEC Hedge.GetHedgeServerInfo @HedgeServerID = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Full hedge server to account mapping topology; OMS pricing accounts included for configuration audit. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHedgeToAccountMapping | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHedgeToAccountMapping.sql*
