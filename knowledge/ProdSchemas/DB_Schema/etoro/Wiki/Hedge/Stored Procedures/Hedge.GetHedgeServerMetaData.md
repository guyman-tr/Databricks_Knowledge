# Hedge.GetHedgeServerMetaData

> Returns a full metadata profile of all operational hedge servers: maps each server to its liquidity account(s), provider type name, and Trade.HedgeServer strategy/system names. No parameters; excludes OMS pricing accounts (AccountTypeID != 4). Used by monitoring and configuration tooling to understand the complete hedge server topology.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all hedge servers ordered by HedgeServerID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHedgeServerMetaData provides a joined, human-readable view of the entire hedge server infrastructure. It combines four tables to answer: "For each hedge server, which liquidity account does it use, who is the liquidity provider, and what strategy/system name does the server run?"

This procedure is the closest thing to a "hedge server directory" - a single call that yields the full operational picture: server ID, provider identity (name + type), account identity, and server software configuration labels. HedgeAlertService calls this at startup and for monitoring dashboards.

The AccountTypeID != 4 filter (inherited from GetHedgeServerInfo) excludes OMS pricing accounts - only execution accounts (AccountTypeID=2) are operationally relevant for hedge routing.

The ORDER BY HedgeServerID groups all accounts for the same hedge server together, making it easy to see multi-account servers (a single hedge server can connect to multiple liquidity accounts).

No SQL callers within the Hedge schema; called externally by HedgeAlertService and tooling.

---

## 2. Business Logic

### 2.1 Four-Way Join: Server Topology Resolution

**What**: Combines HedgeServerToLiquidityAccount + Accounts + Trade.LiquidityProviderType + Trade.HedgeServer.

**Columns/Parameters Involved**: HSTLA.HedgeServerID, HA.ID, LPT.LiquidityProviderTypeID, THS.HedgeServerID

**Rules**:
- Step 1: `Hedge.HedgeServerToLiquidityAccount HSTLA` - maps each HedgeServerID to its LiquidityAccountIDs.
- Step 2: `Hedge.Accounts HA ON HSTLA.LiquidityAccountID = HA.ID` - gets account name and provider type ID.
- Step 3: `Trade.LiquidityProviderType LPT ON HA.LiquidityProviderTypeID = LPT.LiquidityProviderTypeID` - resolves the provider type to a human-readable name (e.g., FXCM, BMFN, eToro internal).
- Step 4: `Trade.HedgeServer THS ON THS.HedgeServerID = HSTLA.HedgeServerID` - adds StrategyName and SystemName from the server's own configuration row.
- All joins are INNER, meaning: only hedge servers with a liquidity account and a matching LiquidityProviderType entry appear. A hedge server with no entry in HedgeServerToLiquidityAccount would be excluded.

### 2.2 OMS Pricing Account Exclusion

**What**: AccountTypeID=4 accounts are excluded; only execution accounts appear.

**Rules**:
- WHERE `HA.AccountTypeID != 4` - same filter as GetHedgeServerInfo.
- AccountTypeID=4 = OMS IM Pricing Account: provides margin/price reference only; no real orders.
- AccountTypeID=2 = Execution Account: the relevant accounts for hedging.

### 2.3 Column Aliasing: LiquidityProviderID from LiquidityProviderType

**What**: Unlike GetHedgeServerInfo (which uses fc.ConnectionID as LiquidityProviderID), here the LiquidityProviderTypeID is used as the provider identifier.

**Rules**:
- `LPT.LiquidityProviderTypeID AS LiquidityProviderID` - note: this is the type ID, not a FIX connection ID.
- `LPT.Name AS LiquidityProviderName` - the type name (e.g., "eToro", "FXCM").
- Difference from GetHedgeServerInfo: that procedure returns fc.ConnectionID (a specific FIX channel ID). This procedure returns LiquidityProviderTypeID (a category type). Both are called LiquidityProviderID but represent different granularities.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server identifier. From HedgeServerToLiquidityAccount. Multiple rows per HedgeServerID if the server has multiple liquidity accounts. Ordered ascending. |
| 2 | LiquidityProviderID | int | NO | - | CODE-BACKED | Liquidity provider TYPE identifier (LPT.LiquidityProviderTypeID). Note: not a FIX connection ID (cf. GetHedgeServerInfo). Identifies the category of provider (e.g., 1=eToro, 2=FXCM). |
| 3 | LiquidityProviderName | nvarchar | NO | - | CODE-BACKED | Human-readable provider type name from Trade.LiquidityProviderType.Name. Examples: "eToro", "FXCM", "BMFN", "FD". |
| 4 | LiquidityAccountID | int | NO | - | CODE-BACKED | Specific liquidity account ID from Hedge.Accounts.ID. Multiple accounts can map to the same HedgeServerID. |
| 5 | LiquidityAccountName | nvarchar | YES | - | CODE-BACKED | Account name from Hedge.Accounts.Name. Human-readable label for the specific account (e.g., "eToro Europe", "Saxo Bank"). |
| 6 | StrategyName | nvarchar | YES | - | CODE-BACKED | Strategy label from Trade.HedgeServer.StrategyName. Identifies the hedging strategy this server runs (e.g., boundary-based, HBC). |
| 7 | SystemName | nvarchar | YES | - | CODE-BACKED | System label from Trade.HedgeServer.SystemName. The software or instance name for this hedge server deployment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HSTLA join | Hedge.HedgeServerToLiquidityAccount | Lookup / Read | Entry point: maps all HedgeServerIDs to their liquidity accounts. |
| HA join | Hedge.Accounts | Lookup / Read | Account name, AccountTypeID (filter != 4), LiquidityProviderTypeID. |
| LPT join | Trade.LiquidityProviderType | Cross-schema Lookup | Resolves LiquidityProviderTypeID to human-readable provider name. |
| THS join | Trade.HedgeServer | Cross-schema Lookup | Adds StrategyName and SystemName to each row. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeAlertService (external) | Result set | Caller | Loads full hedge server topology for monitoring dashboard and routing decisions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHedgeServerMetaData (procedure)
├── Hedge.HedgeServerToLiquidityAccount (table)
├── Hedge.Accounts (table)
├── Trade.LiquidityProviderType (table) [cross-schema]
└── Trade.HedgeServer (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | Starting point: all HedgeServerID -> LiquidityAccountID mappings. |
| Hedge.Accounts | Table | INNER JOIN: Name, AccountTypeID (filter != 4), LiquidityProviderTypeID. |
| Trade.LiquidityProviderType | Table | Cross-schema: INNER JOIN on LiquidityProviderTypeID -> Name. |
| Trade.HedgeServer | Table | Cross-schema: INNER JOIN on HedgeServerID -> StrategyName, SystemName. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeAlertService (external) | Application | Full topology read at startup and for monitoring. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No temp tables. Four-table INNER JOIN with NOLOCK on Hedge tables. ORDER BY HedgeServerID ensures logical grouping. Cross-schema read of Trade tables (LiquidityProviderType, HedgeServer).

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetHedgeServerMetaData;
```

### 8.2 Manually replicate for a specific server

```sql
SELECT  HSTLA.HedgeServerID,
        LPT.LiquidityProviderTypeID AS LiquidityProviderID,
        LPT.Name AS LiquidityProviderName,
        HA.ID AS LiquidityAccountID,
        HA.Name AS LiquidityAccountName,
        THS.StrategyName,
        THS.SystemName
FROM    Hedge.HedgeServerToLiquidityAccount HSTLA WITH (NOLOCK)
        INNER JOIN Hedge.Accounts HA WITH (NOLOCK) ON HSTLA.LiquidityAccountID = HA.ID
        INNER JOIN Trade.LiquidityProviderType LPT ON HA.LiquidityProviderTypeID = LPT.LiquidityProviderTypeID
        INNER JOIN Trade.HedgeServer THS WITH (NOLOCK) ON THS.HedgeServerID = HSTLA.HedgeServerID
WHERE   HA.AccountTypeID != 4
AND     HSTLA.HedgeServerID = 1
ORDER BY HSTLA.HedgeServerID;
```

### 8.3 Compare with GetHedgeServerInfo output

```sql
-- GetHedgeServerMetaData: LiquidityProviderID = LiquidityProviderTypeID (type category)
-- GetHedgeServerInfo:     LiquidityProviderID = fc.ConnectionID (specific FIX connection)
-- Both exclude AccountTypeID=4 but return different provider identifiers
EXEC Hedge.GetHedgeServerInfo @HedgeServerID = 1;
EXEC Hedge.GetHedgeServerMetaData; -- filter by HedgeServerID=1 in application
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Hedge server topology with liquidity provider types; metadata used by HedgeAlertService. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHedgeServerMetaData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHedgeServerMetaData.sql*
