# Hedge.GetHedgeServerInfo

> Returns the full connectivity profile of a hedge server: all operational liquidity accounts (excluding OMS pricing accounts) linked to it, with their FIX connection identifiers and provider type. Used by HedgeAlertService and the hedge engine to resolve the liquidity topology for a given server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeServerID int - required; identifies the hedge server to query |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHedgeServerInfo answers the question: "For hedge server X, which liquidity accounts is it connected to, and how do those accounts connect to the market?" It joins three tables - HedgeServerToLiquidityAccount, Accounts, and FIXConnections - to produce a result row per FIX connection, with account and provider details.

The AccountTypeID != 4 filter is essential: it excludes OMS IM (Initial Margin) pricing accounts, which are present in Accounts but do not participate in actual trade execution. Only AccountTypeID=2 (Execution Accounts) are relevant for operational routing and connectivity.

The returned data set is used by HedgeAlertService to understand which FIX connections belong to a hedge server (for connection health monitoring) and by the hedge engine itself when resolving where to route hedge orders.

No SQL callers found within the Hedge schema; called externally.

---

## 2. Business Logic

### 2.1 OMS Pricing Account Exclusion

**What**: AccountTypeID=4 accounts are filtered out; only execution accounts are included.

**Columns/Parameters Involved**: `ha.AccountTypeID`, @HedgeServerID

**Rules**:
- WHERE `hsla.HedgeServerID = @HedgeServerID AND ha.AccountTypeID != 4`.
- AccountTypeID=4 = OMS IM Pricing Account: used by Order Management System for margin calculations only; these accounts never place real trades.
- AccountTypeID=2 = Execution Account: actual hedge order placement. This is the relevant set.
- The filter is documented in Hedge.Accounts: "Operational procedures filter AccountTypeID != 4 to exclude pricing accounts from routing."

### 2.2 Three-Way Join: Server -> Account -> FIX Connection

**What**: A hedge server connects to the market via liquidity accounts, each of which has a FIX connection. This join chain resolves the full path.

**Columns/Parameters Involved**: `HedgeServerToLiquidityAccount.LiquidityAccountID`, `Accounts.ID`, `FIXConnections.LiquidityAccountID`

**Rules**:
- Step 1: HedgeServerToLiquidityAccount (hsla) maps HedgeServerID to one or more LiquidityAccountIDs.
- Step 2: Accounts (ha) joined ON hsla.LiquidityAccountID = ha.ID; provides account name, AccountTypeID, LiquidityProviderTypeID.
- Step 3: FIXConnections (fc) joined ON fc.LiquidityAccountID = ha.ID; provides ConnectionID (fc.ConnectionID = LiquidityProviderID), and fc.Name (LiquidityProviderName).
- A liquidity account can have multiple FIX connections (e.g., primary + failover). Each produces a separate result row.
- Column aliasing: fc.ConnectionID -> LiquidityProviderID, fc.Name -> LiquidityProviderName, ha.Name -> LiquidityAccountName.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | int | NO | - | CODE-BACKED | Required. Identifies the hedge server to query. Matched against HedgeServerToLiquidityAccount.HedgeServerID. No default; must be supplied by caller. |

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity account ID. PK of Hedge.Accounts. One row per FIX connection linked to this account. From hsla.LiquidityAccountID (= ha.ID). |
| 3 | LiquidityAccountName | nvarchar | YES | - | CODE-BACKED | Human-readable account name from Hedge.Accounts.Name. Identifies the brokerage or venue (e.g., "eToro Europe", "Saxo Bank"). Aliased from ha.Name. |
| 4 | LiquidityProviderID | int | NO | - | CODE-BACKED | The FIX connection ID (fc.ConnectionID). Acts as the liquidity provider identifier - the specific FIX channel to the market. Aliased from fc.ConnectionID. |
| 5 | LiquidityProviderName | nvarchar | YES | - | CODE-BACKED | Name of the FIX connection from Hedge.FIXConnections.Name. Identifies the market-facing connection (e.g., broker name or feed name). Aliased from fc.Name. |
| 6 | LiquidityProviderTypeID | int | YES | - | CODE-BACKED | Provider type classification from Hedge.Accounts.LiquidityProviderTypeID. Indicates the category of liquidity provider (e.g., bank, ECN, exchange). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID filter + LiquidityAccountID join | Hedge.HedgeServerToLiquidityAccount | Lookup / Read | Maps the hedge server to its operational liquidity accounts. |
| ha JOIN | Hedge.Accounts | Lookup / Read | Provides account name, type, and provider type. AccountTypeID != 4 filter applied. |
| fc JOIN | Hedge.FIXConnections | Lookup / Read | Provides FIX connection ID and name per liquidity account. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeAlertService (external) | @HedgeServerID | Caller | Connection health monitoring and routing topology resolution for a specific hedge server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHedgeServerInfo (procedure)
├── Hedge.HedgeServerToLiquidityAccount (table)
├── Hedge.Accounts (table)
└── Hedge.FIXConnections (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | Starting point: maps @HedgeServerID to one or more LiquidityAccountIDs. |
| Hedge.Accounts | Table | Joined ON LiquidityAccountID = ID. Provides Name, AccountTypeID (filter != 4), LiquidityProviderTypeID. |
| Hedge.FIXConnections | Table | Joined ON LiquidityAccountID = ha.ID. Provides ConnectionID (= LiquidityProviderID) and Name (= LiquidityProviderName). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeAlertService (external) | Application | Reads FIX connection topology for a hedge server during startup and monitoring. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No temp tables. Simple three-table INNER JOIN. No OPTION(RECOMPILE). Lightweight read. One result row per FIX connection linked to the hedge server's operational accounts.

---

## 8. Sample Queries

### 8.1 Get connectivity info for a specific hedge server

```sql
EXEC Hedge.GetHedgeServerInfo @HedgeServerID = 1;
```

### 8.2 Manually replicate the join

```sql
SELECT hsla.LiquidityAccountID,
       ha.Name           AS LiquidityAccountName,
       fc.ConnectionID   AS LiquidityProviderID,
       fc.Name           AS LiquidityProviderName,
       ha.LiquidityProviderTypeID
FROM   Hedge.HedgeServerToLiquidityAccount hsla
JOIN   Hedge.Accounts ha ON hsla.LiquidityAccountID = ha.ID
JOIN   Hedge.FIXConnections fc ON fc.LiquidityAccountID = ha.ID
WHERE  hsla.HedgeServerID = 1
AND    ha.AccountTypeID != 4;
```

### 8.3 Identify which hedge servers share a liquidity account

```sql
SELECT hsla.HedgeServerID, hsla.LiquidityAccountID, ha.Name
FROM   Hedge.HedgeServerToLiquidityAccount hsla
JOIN   Hedge.Accounts ha ON hsla.LiquidityAccountID = ha.ID
WHERE  ha.AccountTypeID != 4
ORDER BY hsla.LiquidityAccountID, hsla.HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | HedgeServer connectivity topology; FIX connections per liquidity account; OMS pricing account exclusion pattern. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHedgeServerInfo | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHedgeServerInfo.sql*
