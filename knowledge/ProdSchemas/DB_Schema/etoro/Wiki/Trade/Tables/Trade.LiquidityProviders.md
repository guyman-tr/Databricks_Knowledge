# Trade.LiquidityProviders

> Registry of liquidity provider instances (e.g., FXCM Real, FXCM Demo, FD Production) that pair provider type configurations with instance-specific names and settings, used for hedging, price feeds, and liquidity account routing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | LiquidityProviderID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.LiquidityProviders is the registry of **concrete liquidity provider instances** in eToro's trading infrastructure. While Trade.LiquidityProviderType defines provider **types** (e.g., FXCM, FD, BMFN) with their pluggable assembly and class configurations, this table stores the **instances** - each row is a specific deployment such as "FXCM Real", "FXCM Demo", or "FD RealStream Production REAL 208.100.16.161". Each instance references its type via LiquidityProviderTypeID and can have instance-specific settings in LiquidityProviderSettingsXML.

This table exists because the hedge subsystem needs to route orders to specific provider environments (real vs demo, production vs backup). Hedge.Accounts.LiquidityProviderID points here. Trade.LiquidityAccounts links liquidity accounts (login credentials for external brokers) to a provider instance. Without this table, the system cannot distinguish between multiple FXCM environments or map hedge accounts to the correct execution endpoint.

Data flows as follows: rows are created by Trade.SetNextLiquidityProviderID (for ID allocation and legacy "Obsolete! Use Hedge Account" placeholders), by Internal.Newcurrency/instrument setup flows, and by admin/deployment scripts when adding new provider instances. The table is read by Trade.GetLiquidityProviders, Trade.GetLiquidityAccountsDetails, Trade.GetInstrumentRateSources, Trade.GetLiquidityProviderContracts, Trade.GetAvailableLiquidityProviderContracts, and Trade.CheckValidInstruments. System versioning records all changes to History.LiquidityProviders.

---

## 2. Business Logic

### 2.1 Provider Instance vs Provider Type

**What**: Each liquidity provider instance belongs to exactly one provider type. Multiple instances can share the same type (e.g., FXCM Real and FXCM Demo both have LiquidityProviderTypeID=2).

**Columns/Parameters Involved**: `LiquidityProviderID`, `LiquidityProviderName`, `LiquidityProviderTypeID`

**Rules**:
- LiquidityProviderTypeID references Trade.LiquidityProviderType - the type defines price/execution assemblies; the instance is the deployment target
- Trade.SetNextLiquidityProviderID allocates IDs per type: it first looks for an existing row with LiquidityProviderName='Obsolete! Use Hedge Account' and LiquidityProviderTypeID=@ProviderTypeID; if found, reuses that ID; otherwise finds the lowest missing ID or MAX+1
- Hedge accounts (Trade.LiquidityAccounts) reference LiquidityProviderID - each account is tied to one provider instance
- Trade.LiquidityProviderContracts links instrument contracts to LiquidityProviderID (provider instance)

**Diagram**:
```
Trade.LiquidityProviderType (e.g., FXCM)
  -> Trade.LiquidityProviders (FXCM Real, FXCM Demo)
        -> Trade.LiquidityAccounts (login credentials)
        -> Trade.LiquidityProviderContracts (ticker mappings)
```

### 2.2 System Versioning for Instance History

**What**: All changes to provider instances are retained for auditing via PERIOD FOR SYSTEM_TIME.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- History.LiquidityProviders holds superseded rows when LiquidityProviderName or LiquidityProviderSettingsXML changes
- Enables point-in-time queries for configuration rollback or forensics

---

## 3. Data Overview

| LiquidityProviderID | LiquidityProviderName | LiquidityProviderTypeID | Meaning |
|---------------------|----------------------|-------------------------|---------|
| 0 | ACT | 1 | BMFN-type provider instance. ACT (BMFN) used for forex hedging. |
| 1 | Log files | 0 | eToro internal provider. "Log files" indicates internal/logging use rather than live hedging. |
| 2 | FXCM Real | 2 | FXCM production environment for real forex hedging. |
| 3 | FXCM Demo | 2 | FXCM demo environment - same type as FXCM Real but separate instance for testing. |
| 4 | FD RealStream Production REAL 208.100.16.161 | 3 | First Derivatives production instance with server IP in name. Used for specific hedge routing. |

**Selection criteria for the 5 rows:**
- ACT, FXCM Real, FXCM Demo, FD Production: representative of external provider instances (BMFN, FXCM, FD)
- Log files: edge case showing eToro internal (type 0) usage

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderID | int | NO | - | CODE-BACKED | Primary key. Unique identifier for this provider instance. Allocated by Trade.SetNextLiquidityProviderID using gap-fill (lowest missing ID) or MAX+1. Referenced by Trade.LiquidityAccounts, Trade.LiquidityProviderContracts, Trade.LiquidityProviderInstuments. |
| 2 | LiquidityProviderName | varchar(250) | YES | - | CODE-BACKED | Human-readable instance name (e.g., FXCM Real, FD RealStream Production REAL 208.100.16.161). SetNextLiquidityProviderID uses 'Obsolete! Use Hedge Account' for placeholder rows. Used in views and reports. |
| 3 | LiquidityProviderSettingsXML | xml | YES | - | CODE-BACKED | Instance-specific XML settings. Can override or extend type-level TypeSettingsXML from Trade.LiquidityProviderType. SetNextLiquidityProviderID inserts '<settings />' for placeholder rows. |
| 4 | LiquidityProviderTypeID | int | YES | - | CODE-BACKED | FK to Trade.LiquidityProviderType. Provider type: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 4=CNX, 5=XIGNITE, 6=MT_GOX, 7=GFT, 8=BitStamp, 11=IB. (Source: Trade.LiquidityProviderType) |
| 5 | DbLoginName | varchar(128) | NO | computed | CODE-BACKED | Computed: suser_name(). SQL login that last modified the row. Audit context. |
| 6 | AppLoginName | varchar(500) | NO | computed | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context from context_info. Often NULL when not set by caller. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning start. When this row became effective. GENERATED ALWAYS AS ROW START. |
| 8 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning end. When this row was superseded. GENERATED ALWAYS AS ROW END. 9999-12-31 means current. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderTypeID | Trade.LiquidityProviderType | FK | Each provider instance references its type (e.g., FXCM, FD) for assembly and class configuration. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityAccounts | LiquidityProviderID | FK | Hedge/login accounts link to provider instance for execution routing. |
| Trade.LiquidityProviderContracts | LiquidityProviderID | FK | Instrument-to-ticker contract mappings per provider instance. |
| Trade.LiquidityProviderInstuments | LiquidityProviderID | FK | Instrument availability per provider instance. |
| Trade.GetLiquidityProviders | - | JOIN | View JOINs for provider details. |
| Trade.GetLiquidityAccountsDetails | - | JOIN | Resolves provider name in account details. |
| Trade.GetInstrumentRateSources | - | JOIN | Resolves provider name for rate source display. |
| Trade.GetLiquidityProviderContracts | - | JOIN | Returns contracts with provider name. |
| Trade.GetAvailableLiquidityProviderContracts | - | JOIN | Returns available contracts by provider. |
| Trade.SetNextLiquidityProviderID | - | INSERT/SELECT | Allocates and reuses LiquidityProviderID. |
| Trade.CheckValidInstruments | - | EXISTS | Validates LiquidityProviderID exists. |
| Trade.SetNextLiquidityAccountID | - | EXEC | Calls SetNextLiquidityProviderID for account creation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.LiquidityProviders (table)
  -> Trade.LiquidityProviderType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderType | Table | FK LiquidityProviderTypeID references LiquidityProviderTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK LiquidityProviderID |
| Trade.LiquidityProviderContracts | Table | FK LiquidityProviderID |
| Trade.LiquidityProviderInstuments | Table | FK LiquidityProviderID |
| Trade.GetLiquidityProviders | View | FROM/JOIN |
| Trade.GetLiquidityAccountsDetails | View | INNER JOIN |
| Trade.GetInstrumentRateSources | View | LEFT JOIN |
| Trade.GetLiquidityProviderContracts | View | INNER JOIN |
| Trade.GetAvailableLiquidityProviderContracts | Function | INNER JOIN |
| Trade.GetLiguidityProviderContractsForTradonomiContract | Function | INNER JOIN |
| Trade.SetNextLiquidityProviderID | Procedure | SELECT, INSERT |
| Trade.SetNextLiquidityAccountID | Procedure | Calls SetNextLiquidityProviderID |
| Trade.CheckValidInstruments | Procedure | EXISTS validation |
| Trade.CheckValidInstruments_bck | Procedure | EXISTS validation |
| Trade.InsertInstrumentRealTable | Procedure | LiquidityProviderContracts insert |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | Procedure | INSERT into related tables |
| Trade.MatchInstrumentIDToTickerName | Procedure | WHERE LiquidityProviderID |
| Trade.GetInstrumentsForDataApi | Procedure | WHERE LiquidityProviderID |
| Trade.FunGetInstrumentConfiguration | Procedure | JOIN on LiquidityProviderID |
| Trade.Alert_LiquidityProviderContracts | Procedure | SELECT from LiquidityProviderContracts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TRLP | CLUSTERED | LiquidityProviderID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TRLP | PRIMARY KEY | LiquidityProviderID - unique identifier |
| FK_LiquidityProviders_LiquidityProviderTypeID | FOREIGN KEY | LiquidityProviderTypeID -> Trade.LiquidityProviderType(LiquidityProviderTypeID) |
| DF_LiquidityProviders_SysStart | DEFAULT | getutcdate() for SysStartTime |
| DF_LiquidityProviders_SysEnd | DEFAULT | 9999-12-31 23:59:59.9999999 for SysEndTime |
| PERIOD FOR SYSTEM_TIME | SYSTEM VERSIONING | SysStartTime, SysEndTime -> History.LiquidityProviders |

---

## 8. Sample Queries

### 8.1 List all provider instances with type name
```sql
SELECT LP.LiquidityProviderID,
       LP.LiquidityProviderName,
       LP.LiquidityProviderTypeID,
       LPT.Name AS ProviderTypeName
FROM Trade.LiquidityProviders LP WITH (NOLOCK)
LEFT JOIN Trade.LiquidityProviderType LPT WITH (NOLOCK)
  ON LP.LiquidityProviderTypeID = LPT.LiquidityProviderTypeID
ORDER BY LP.LiquidityProviderTypeID, LP.LiquidityProviderID;
```

### 8.2 Provider instances used by liquidity accounts
```sql
SELECT LP.LiquidityProviderID,
       LP.LiquidityProviderName,
       COUNT(LA.LiquidityAccountID) AS AccountCount
FROM Trade.LiquidityProviders LP WITH (NOLOCK)
LEFT JOIN Trade.LiquidityAccounts LA WITH (NOLOCK)
  ON LA.LiquidityProviderID = LP.LiquidityProviderID
GROUP BY LP.LiquidityProviderID, LP.LiquidityProviderName
ORDER BY AccountCount DESC;
```

### 8.3 Resolve LiquidityProviderID to human-readable names
```sql
SELECT LP.LiquidityProviderID,
       LP.LiquidityProviderName,
       LPT.Name AS ProviderTypeName,
       LP.LiquidityProviderSettingsXML
FROM Trade.LiquidityProviders LP WITH (NOLOCK)
INNER JOIN Trade.LiquidityProviderType LPT WITH (NOLOCK)
  ON LP.LiquidityProviderTypeID = LPT.LiquidityProviderTypeID
WHERE LP.LiquidityProviderID IN (0, 2, 4);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL, LiveData, Grep, Atlassian*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.LiquidityProviders | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.LiquidityProviders.sql*
