# Hedge.HedgeServerToLiquidityAccount

> Mapping table assigning liquidity accounts to hedge servers, defining which account a hedge server uses for execution and optionally a separate account for alternative rates/pricing.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | LiquidityAccountID (int, PK CLUSTERED) - one row per account |
| **Partition** | No (on [PRIMARY] filegroup, FILLFACTOR=90, PAGE compression) |
| **Indexes** | 3 (PK + IXHedgeServerID + unique nonclustered on LiquidityAccountID) |

---

## 1. Business Meaning

`Hedge.HedgeServerToLiquidityAccount` connects hedge servers to their liquidity accounts. Each row says: "this liquidity account belongs to this hedge server." The PK is on `LiquidityAccountID` - meaning each account can belong to only one hedge server, but a single hedge server can own multiple accounts (IXHedgeServerID supports efficient lookup by server).

The `AltRatesLiquidityAccountID` column allows a hedge server to use a separate account for rate/price data versus actual order execution. This supports architectures where a dedicated "pricing account" provides real-time quotes while a different "execution account" submits orders.

This table is the central routing registry: procedures like `GetHedgeServerInfo`, `GetHedgeServerMetaData`, `GetHedgeToAccountMapping`, and `GetActiveAccountByProviderAndAccountType` all JOIN through this table to resolve the hedge server <-> liquidity account relationship.

**Current data** (11 rows): Each active hedge server has exactly one primary account. HedgeServerID=8 (OMS) has two accounts (IM3 pricing + IM4 hedging - both mapped to the same server).

---

## 2. Business Logic

### 2.1 One-to-Many: Server to Accounts

**What**: Each liquidity account belongs to exactly one server (PK on LiquidityAccountID). Each hedge server can own multiple accounts (queried via IXHedgeServerID).

**Columns/Parameters Involved**: `HedgeServerID`, `LiquidityAccountID`

**Rules**:
- PK on LiquidityAccountID: one account -> one server (exclusive assignment)
- IXHedgeServerID enables efficient lookup of all accounts for a given server
- A server with one Execution Account + one OMS Pricing Account (AccountTypeID=4) appears as two rows with the same HedgeServerID
- Example: HedgeServerID=8 has LiquidityAccountID=2147 (IM Pricing) and 2148 (IM Hedging)

### 2.2 Alternative Rates Account

**What**: `AltRatesLiquidityAccountID` designates a secondary account used for alternative rate/price discovery while the primary account handles execution.

**Columns/Parameters Involved**: `AltRatesLiquidityAccountID`

**Rules**:
- NULL = no alternative rates account configured (current data: all 11 rows have AltRatesLiquidityAccountID NULL)
- Non-NULL = a separate liquidity account whose price feed is used for rate calculation rather than the primary account
- FK to Trade.LiquidityAccounts - the alt rates account must exist in the platform account registry

---

## 3. Data Overview

| HedgeServerID | LiquidityAccountID | LiquidityAccountName | AltRatesAccountID | Meaning |
|---|---|---|---|---|
| 1 | 10 | ZBFX Price2 Execution | NULL | Primary ZBFX hedge server uses Price2 account |
| 2 | 8 | ZBFX Price1 Execution | NULL | Secondary ZBFX hedge server uses Price1 account |
| 3 | 14 | TRAFIX UAT Fract - Obsolete! | NULL | TRAFIX server - marked Obsolete in account name |
| 8 | 2147 | OMS UAT IM3 IM Pricing | NULL | OMS server's IM pricing account (AccountTypeID=4) |
| 8 | 2148 | OMS UAT IM4 IM Hedging | NULL | OMS server's execution/hedging account |
| 9 | 2150 | OMS UAT DMA Virtu | NULL | OMS DMA server routes to Virtu |
| 10 | 346 | Talos | NULL | Talos hedge server |
| 125 | 12566 | MM Direct STG | NULL | MM Direct staging server |
| 222 | 2151 | OMS UAT DMA Marex | NULL | OMS DMA server routes to Marex |
| 1100 | 11 | ZBFX Price3 Execution | NULL | Inactive ZBFX Price3 server |
| 5454 | 354541 | FD Provider UAT Account | NULL | FD Provider UAT server |

Total: 11 rows. All AltRatesLiquidityAccountIDs are NULL.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | VERIFIED | FK to Trade.HedgeServer(HedgeServerID). The hedge server that owns this liquidity account. Non-unique (a server can have multiple account rows, e.g., HedgeServerID=8 has 2 accounts). Indexed via IXHedgeServerID for per-server account lookups. |
| 2 | LiquidityAccountID | int | NO | - | VERIFIED | PK and FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity account assigned to the hedge server. Each account belongs to exactly one server (PK enforces this). |
| 3 | AltRatesLiquidityAccountID | int | YES | NULL | VERIFIED | FK to Trade.LiquidityAccounts(LiquidityAccountID). Optional second account used for alternative rate/price discovery. Currently NULL for all 11 rows - feature defined but not yet configured. |
| 4 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 5 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 6 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 7 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.HedgeServerToLiquidityAccount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_HedgeServerToLiquidityAccount_HedgeServer) | The hedge server that owns this liquidity account |
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_HedgeServerToLiquidityAccount_LiquidityAccounts) | The primary liquidity account for this server |
| AltRatesLiquidityAccountID | Trade.LiquidityAccounts | FK (FK_HedgeServerToLiquidityAccountAlt_LiquidityAccounts) | Optional secondary account for alternative rates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetHedgeServerInfo | HedgeServerID | JOIN | Returns account name + provider for a given hedge server |
| Hedge.GetHedgeServerMetaData | HedgeServerID | JOIN | Returns full server + account + provider metadata |
| Hedge.GetHedgeToAccountMapping | HedgeServerID | JOIN | Returns server-to-account-to-provider mapping |
| Hedge.GetActiveAccountByProviderAndAccountType | LiquidityAccountID | JOIN | Finds active accounts by provider + type via this table |
| Hedge.GetHedgeSupportedInstruments | (chain) | JOIN | Part of server-account-instrument lookup chain |
| Hedge.GetHSUnitConversionRatio | (chain) | JOIN | Part of server-account conversion ratio chain |
| Hedge.GetHedgeServerLiquidityProviderDetails | (view) | JOIN | View providing server + provider details |
| History.HedgeServerToLiquidityAccount | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |
| History.AuditHistory | (trigger) | Audit Log | DML triggers track LiquidityAccountID and AltRatesLiquidityAccountID changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeServerToLiquidityAccount (table)
  ├── Trade.HedgeServer (table) [FK - HedgeServerID]
  └── Trade.LiquidityAccounts (table) [FK - LiquidityAccountID, AltRatesLiquidityAccountID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK_HedgeServerToLiquidityAccount_HedgeServer - server must exist |
| Trade.LiquidityAccounts | Table | FK (x2) - primary and alt rates accounts must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetHedgeServerInfo | Stored Procedure | READER - resolves server ID to account details |
| Hedge.GetHedgeServerMetaData | Stored Procedure | READER - full server + account + provider metadata |
| Hedge.GetHedgeToAccountMapping | Stored Procedure | READER - server-to-account mapping |
| Hedge.GetActiveAccountByProviderAndAccountType | Stored Procedure | READER - active account lookup |
| Hedge.GetHedgeSupportedInstruments | Stored Procedure | READER - part of server instrument chain |
| Hedge.GetHSUnitConversionRatio | Stored Procedure | READER - part of conversion ratio chain |
| Hedge.GetHedgeServerLiquidityProviderDetails | View | JOIN - enriches server with provider details |
| History.HedgeServerToLiquidityAccount | Table | Temporal shadow table |
| History.AuditHistory | Table | Audit log via DML triggers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LiquidityAccountsToHedgeServer | CLUSTERED PK | LiquidityAccountID ASC | - | PAGE compression | Active (FILLFACTOR=90) |
| IXHedgeServerID | NONCLUSTERED | HedgeServerID ASC | - | - | Active |
| Idx_Hedge_HedgeServerToLiquidityAccount_LiquidityAccountID | UNIQUE NONCLUSTERED | LiquidityAccountID ASC | - | - | Active (FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_LiquidityAccountsToHedgeServer | PRIMARY KEY | LiquidityAccountID - each account belongs to one server |
| FK_HedgeServerToLiquidityAccount_HedgeServer | FOREIGN KEY | HedgeServerID must reference Trade.HedgeServer |
| FK_HedgeServerToLiquidityAccount_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID must reference Trade.LiquidityAccounts |
| FK_HedgeServerToLiquidityAccountAlt_LiquidityAccounts | FOREIGN KEY | AltRatesLiquidityAccountID (when not NULL) must reference Trade.LiquidityAccounts |
| DEFAULT AltRatesLiquidityAccountID | DEFAULT | NULL |
| DF_HedgeServerToLiquidityAccount_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_HedgeServerToLiquidityAccount_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.HedgeServerToLiquidityAccount |

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| AuditDelete_Hedge_HedgeServerToLiquidityAccount | DELETE | Writes LiquidityAccountID + AltRatesLiquidityAccountID DELETE records to History.AuditHistory |
| AuditInsert_Hedge_HedgeServerToLiquidityAccount | INSERT | Writes LiquidityAccountID + AltRatesLiquidityAccountID INSERT records to History.AuditHistory |
| AuditUpdate_Hedge_HedgeServerToLiquidityAccount | UPDATE | Writes UPDATE records for changed columns to History.AuditHistory |
| TRG_T_HedgeServerToLiquidityAccount | INSERT | No-op self-UPDATE to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 View all hedge server to account assignments

```sql
SELECT
    hsla.HedgeServerID,
    hs.StrategyName AS HedgeServerName,
    hsla.LiquidityAccountID,
    la.LiquidityAccountName,
    hsla.AltRatesLiquidityAccountID
FROM Hedge.HedgeServerToLiquidityAccount hsla WITH (NOLOCK)
JOIN Trade.HedgeServer hs WITH (NOLOCK)
    ON hsla.HedgeServerID = hs.HedgeServerID
JOIN Trade.LiquidityAccounts la WITH (NOLOCK)
    ON hsla.LiquidityAccountID = la.LiquidityAccountID
ORDER BY hsla.HedgeServerID, hsla.LiquidityAccountID
```

### 8.2 Find all accounts for a specific hedge server

```sql
SELECT
    hsla.LiquidityAccountID,
    la.LiquidityAccountName
FROM Hedge.HedgeServerToLiquidityAccount hsla WITH (NOLOCK)
JOIN Trade.LiquidityAccounts la WITH (NOLOCK)
    ON hsla.LiquidityAccountID = la.LiquidityAccountID
WHERE hsla.HedgeServerID = 8  -- OMS server (has two accounts)
ORDER BY hsla.LiquidityAccountID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeServerToLiquidityAccount | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.sql*
