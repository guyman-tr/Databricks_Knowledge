# Hedge.GetHedgeSupportedInstruments

> Returns the set of instruments tradeable by a specific hedge server, resolved via the server's liquidity provider type and its contract listings. Applies two-path logic: single-account servers return all provider contracts (full universe); multi-account servers additionally filter to Hedge.SupportedInstrumentsAccount (explicit per-account allow-list).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeServerID int - required; identifies the hedge server |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHedgeSupportedInstruments answers: "Which instruments can hedge server X actually trade?" This is not a simple config lookup - the answer depends on both the provider type contracts and, for multi-account servers, an explicit per-account instrument allow-list.

**Why two paths?** A single-account server connects to exactly one liquidity provider account. That provider's full contract universe (Trade.LiquidityProviderContracts) is available - all instruments for which the provider has a ticker. A multi-account server, however, connects to multiple liquidity accounts, each potentially covering a subset of instruments. Without the SupportedInstrumentsAccount filter, the UNION of all accounts' provider contracts might return instruments that are not routable to a specific account. The SupportedInstrumentsAccount join enforces the explicit per-account routing assignment.

The isolation level is set to READ UNCOMMITTED (same as NOLOCK) via `SET TRAN ISOLATION LEVEL READ UNCOMMITTED` at the procedure level - appropriate for a startup read of configuration data.

Called externally by the hedge engine at startup to populate its tradeable instrument set; no SQL callers found in the Hedge schema.

---

## 2. Business Logic

### 2.1 Account Count Check (Single vs Multi)

**What**: Counts the number of operational liquidity accounts linked to the hedge server to select the correct data path.

**Columns/Parameters Involved**: `@Accounts`, Hedge.HedgeServerToLiquidityAccount, Trade.LiquidityAccounts

**Rules**:
- `@Accounts = COUNT(*) FROM Hedge.HedgeServerToLiquidityAccount hsla JOIN Trade.LiquidityAccounts tla ON hsla.LiquidityAccountID = tla.LiquidityAccountID WHERE hsla.HedgeServerID = @HedgeServerID AND tla.LiquidityAccountTypeID != 4`
- The filter `LiquidityAccountTypeID != 4` matches the operational pattern from GetHedgeServerInfo - excludes OMS pricing accounts from the count.
- Trade.LiquidityAccounts is a cross-schema table tracking account metadata; LiquidityAccountTypeID=4 = OMS pricing.
- If @Accounts = 1: single-account path. If @Accounts > 1 (or 0): multi-account path (the ELSE branch handles 0 gracefully - returns empty set).

### 2.2 Single-Account Path: Full Provider Contract Universe

**What**: Returns all instruments for which the provider type has a contract listed.

**Rules**:
- Joins: HedgeServerToLiquidityAccount -> Accounts -> Trade.LiquidityProviderContracts (ON LiquidityProviderTypeID = LiquidityProviderID)
- WHERE `HedgeServerID = @HedgeServerID AND HA.AccountTypeID != 4`
- SELECT DISTINCT InstrumentID, Ticker, LiquidityAccountID
- LiquidityProviderContracts.InstrumentID and Ticker are the instrument-level contract data from Trade.

### 2.3 Multi-Account Path: Filtered by SupportedInstrumentsAccount

**What**: Same join but additionally restricts to instruments explicitly assigned to each account.

**Rules**:
- Same base joins as single-account path, PLUS:
- `JOIN Hedge.SupportedInstrumentsAccount SIA ON HSTLA.LiquidityAccountID = SIA.LiquidityAccountID AND LPC.InstrumentID = SIA.InstrumentID`
- This ensures only instruments in the explicit allow-list (SupportedInstrumentsAccount) are returned for each account.
- Without SupportedInstrumentsAccount, a multi-account server might return instruments that belong to a different account's provider.
- SELECT DISTINCT InstrumentID, Ticker, LiquidityAccountID - same output columns.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | NO | - | CODE-BACKED | Required. Identifies the hedge server whose supported instruments to retrieve. Used in WHERE HedgeServerID = @HedgeServerID and in the @Accounts count subquery. |

**Output Columns** (returned resultset - same for both paths):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. From Trade.LiquidityProviderContracts.InstrumentID (single path) or Hedge.SupportedInstrumentsAccount.InstrumentID (multi path). DISTINCT ensures no duplicates. |
| 3 | Ticker | nvarchar | YES | - | CODE-BACKED | Provider-specific ticker symbol from Trade.LiquidityProviderContracts. The external symbol used when sending orders to the liquidity provider (e.g., "EURUSD", "AAPL"). |
| 4 | LiquidityAccountID | int | NO | - | CODE-BACKED | The specific liquidity account through which this instrument can be traded. From HSTLA.LiquidityAccountID. In multi-account servers, distinguishes which account handles which instruments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Accounts count | Hedge.HedgeServerToLiquidityAccount | Count Query | Determines single vs multi-account path. |
| @Accounts count join | Trade.LiquidityAccounts | Cross-schema Count | LiquidityAccountTypeID filter for account count. |
| Main join | Hedge.HedgeServerToLiquidityAccount | Lookup / Read | Maps server to account(s). |
| HA join | Hedge.Accounts | Lookup / Read | LiquidityProviderTypeID, AccountTypeID filter. |
| LPC join | Trade.LiquidityProviderContracts | Cross-schema Lookup | InstrumentID, Ticker per provider type. |
| SIA join (multi only) | Hedge.SupportedInstrumentsAccount | Lookup / Read | Explicit per-account instrument allow-list (multi-account path only). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | @HedgeServerID | Caller | Loads the tradeable instrument universe at startup for a specific server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHedgeSupportedInstruments (procedure)
├── Hedge.HedgeServerToLiquidityAccount (table)
├── Hedge.Accounts (table)
├── Hedge.SupportedInstrumentsAccount (table) [multi-account path only]
├── Trade.LiquidityAccounts (table) [cross-schema, count check only]
└── Trade.LiquidityProviderContracts (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | Maps @HedgeServerID to LiquidityAccountID(s). Both count and main query. |
| Hedge.Accounts | Table | JOIN for LiquidityProviderTypeID and AccountTypeID (filter != 4). |
| Hedge.SupportedInstrumentsAccount | Table | Multi-account path: instrument allow-list per account. |
| Trade.LiquidityAccounts | Table | Cross-schema: count check only (LiquidityAccountTypeID != 4). |
| Trade.LiquidityProviderContracts | Table | Cross-schema: InstrumentID and Ticker per liquidity provider type. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Startup: loads tradeable instrument universe for routing decisions. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

`SET TRAN ISOLATION LEVEL READ UNCOMMITTED` at the top - all reads in this procedure are dirty reads (equivalent to NOLOCK on all tables). This is appropriate for startup config reads. No temp tables. Branching IF/ELSE based on account count. SELECT DISTINCT on both paths.

---

## 8. Sample Queries

### 8.1 Get supported instruments for a specific server

```sql
EXEC Hedge.GetHedgeSupportedInstruments @HedgeServerID = 1;
```

### 8.2 Check if a server is single or multi account

```sql
SELECT COUNT(*) AS AccountCount
FROM   Hedge.HedgeServerToLiquidityAccount hsla
JOIN   Trade.LiquidityAccounts tla ON hsla.LiquidityAccountID = tla.LiquidityAccountID
WHERE  hsla.HedgeServerID = 1
AND    tla.LiquidityAccountTypeID != 4;
-- 1 = single path (all provider contracts); >1 = multi path (SupportedInstrumentsAccount filtered)
```

### 8.3 Check SupportedInstrumentsAccount content for a server

```sql
SELECT SIA.LiquidityAccountID, SIA.InstrumentID
FROM   Hedge.SupportedInstrumentsAccount SIA
JOIN   Hedge.HedgeServerToLiquidityAccount HSTLA ON SIA.LiquidityAccountID = HSTLA.LiquidityAccountID
WHERE  HSTLA.HedgeServerID = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Supported instruments resolution for single vs multi-account hedge server configurations. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHedgeSupportedInstruments | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHedgeSupportedInstruments.sql*
