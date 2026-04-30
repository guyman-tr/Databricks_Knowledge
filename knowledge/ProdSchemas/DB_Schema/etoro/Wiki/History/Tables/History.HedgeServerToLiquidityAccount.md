# History.HedgeServerToLiquidityAccount

> SQL Server system-versioned temporal history table for Hedge.HedgeServerToLiquidityAccount, recording every change to the mapping between hedge servers and their assigned liquidity provider accounts.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (LiquidityAccountID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Hedge.HedgeServerToLiquidityAccount`. SQL Server's system-versioning manages this table transparently: whenever a row in `Hedge.HedgeServerToLiquidityAccount` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Hedge.HedgeServerToLiquidityAccount` is the critical routing bridge between eToro's internal hedging engine instances (hedge servers) and the external liquidity provider accounts they trade through. When the hedging engine opens or closes a position with a liquidity provider, this mapping determines:

1. **Which liquidity account** is used for the transaction - a specific account at an external broker/prime broker representing eToro's trading relationship
2. **Optionally, which alternative liquidity account** is used for rate data when the primary account's rates differ (AltRatesLiquidityAccountID)

The PK is on `LiquidityAccountID` alone (not a composite of HedgeServerID + LiquidityAccountID), enforcing that each liquidity account is assigned to exactly one hedge server at a time. A hedge server can have multiple liquidity accounts (via the NONCLUSTERED index on HedgeServerID), but a liquidity account belongs to only one server.

This mapping is referenced at failure time by `History.HedgeFailInfo` to resolve the LiquidityAccountID from the HedgeServerID when recording hedge failures.

42 history rows span September 2021 to February 2026, covering 12 distinct hedge servers. Changes are operational routing events managed via the ConfigurationManager tool.

---

## 2. Business Logic

### 2.1 Hedge Server to Liquidity Account Binding

**What**: Each hedge server routes its trades through a specific liquidity account at an external provider. This binding determines the execution account for all hedged positions on that server.

**Columns/Parameters Involved**: `HedgeServerID`, `LiquidityAccountID`

**Rules**:
- FK: HedgeServerID -> Trade.HedgeServer(HedgeServerID)
- FK: LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID)
- PK on LiquidityAccountID alone: each liquidity account can be assigned to at most one hedge server at a time (enforces one-to-one uniqueness per account)
- NONCLUSTERED index on HedgeServerID: a single hedge server can be associated with multiple liquidity accounts (one-to-many)
- FILLFACTOR=90 on both PK and UNIQUE index: operational table with occasional reassignments
- Reassigning a liquidity account to a different hedge server requires deleting the old row and inserting a new one, generating history rows for both events

### 2.2 Alternative Rates Liquidity Account

**What**: An optional secondary liquidity account used specifically for rate/price data, distinct from the primary execution account.

**Columns/Parameters Involved**: `AltRatesLiquidityAccountID`

**Rules**:
- FK: AltRatesLiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID), DEFAULT NULL
- NULL in all 42 observed history rows - this is a rarely-used or reserved feature
- When set, the alternative account's rate quotes are used instead of the primary LiquidityAccountID's rates for pricing decisions on this hedge server

### 2.3 Dual Audit Pattern (Temporal + AuditHistory)

**What**: Changes are captured both in temporal history (this table) and in the per-column History.AuditHistory log via triggers.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `TRG_T_HedgeServerToLiquidityAccount` fires no-op UPDATE (SET HedgeServerID=HedgeServerID) joining on LiquidityAccountID to force SQL Server to capture the newly inserted row in temporal history
- Zero-duration rows (SysStartTime = SysEndTime) mark INSERT trigger captures
- INSERT/UPDATE/DELETE triggers (`AuditInsert/AuditUpdate/AuditDelete_Hedge_HedgeServerToLiquidityAccount`) additionally write individual column changes to History.AuditHistory with PK_Value = 'HedgeServerID,LiquidityAccountID' (same dual-audit pattern as Hedge.InstrumentConfiguration and Hedge.HedgeServerToLiquidityAccount)
- DbLoginName: "TRAD\dotanva", "TRAD\Noah", "TRAD\ranlev", "TRAD\rivkaya" (Active Directory domain accounts), "DevTradingSTG" (direct SQL in staging)
- AppLoginName: "username;ConfigurationManager\0\0..." - null-byte padded varchar (context_info written as UTF-16 from a .NET application, parsed before the first semicolon for the username, after for the tool name)

---

## 3. Data Overview

| Scale | Value |
|-------|-------|
| Total rows | 42 |
| Date range | 2021-09-13 to 2026-02-25 (~4.5 years) |
| Distinct hedge servers | 12 |
| AltRatesLiquidityAccountID set | 0 (all NULL in observed data) |

Sample versioned data:

| HedgeServerID | LiquidityAccountID | DbLoginName | SysStartTime | SysEndTime | Notes |
|---|---|---|---|---|---|
| 3 | 14 | TRAD\dotanva | 2026-02-25 20:15:52 | 2026-02-25 20:15:52 | INSERT trigger capture (zero-duration) |
| 5 | 439 | TRAD\Noah | 2024-12-16 12:53:26 | 2025-12-21 12:45:41 | ~1 year version before reassignment |
| 8 | 8 | TRAD\rivkaya | 2023-12-26 10:38:59 | 2025-06-29 09:17:50 | ~18 months |
| 5454 | 354541 | DevTradingSTG | 2025-08-13 08:36:38 | 2025-08-13 08:36:38 | Test/synthetic IDs |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | The hedging engine server instance. FK to Trade.HedgeServer(HedgeServerID). One server can have multiple liquidity accounts. NONCLUSTERED index on source for fast lookup of all accounts per server. 12 distinct servers in history. |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | The external liquidity provider account used for hedge execution. FK to Trade.LiquidityAccounts(LiquidityAccountID). PK in source - each liquidity account belongs to exactly one hedge server. Used by History.HedgeFailInfo to resolve the account when recording failures. |
| 3 | AltRatesLiquidityAccountID | int | YES | NULL | CODE-BACKED | Optional alternative liquidity account used for rate/price data (distinct from execution). FK to Trade.LiquidityAccounts(LiquidityAccountID). NULL in all 42 observed history rows - reserved for multi-rate scenarios. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Computed column in source, materialized here. Observed values: domain accounts ("TRAD\dotanva", "TRAD\Noah", "TRAD\ranlev", "TRAD\rivkaya") and "DevTradingSTG" for direct SQL. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info() at time of change. Format: "username;ConfigurationManager\0\0..." with null-byte padding (context_info written as Unicode from a .NET application). The tool name after the semicolon is "ConfigurationManager". |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this server-to-account mapping version became active. Source DEFAULT=getutcdate(). For INSERT-trigger-captured rows, equals SysEndTime. Earliest observed: 2021-09-13. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping version was superseded. CLUSTERED index leading column. Source DEFAULT='9999-12-31'. Latest observed: 2026-02-25. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | Implicit | Hedging engine server. FK enforced on source as FK_HedgeServerToLiquidityAccount_HedgeServer. |
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | Primary execution account at the liquidity provider. FK enforced on source as FK_HedgeServerToLiquidityAccount_LiquidityAccounts. |
| AltRatesLiquidityAccountID | Trade.LiquidityAccounts | Implicit | Alternative rate source account. FK enforced on source as FK_HedgeServerToLiquidityAccountAlt_LiquidityAccounts. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HedgeServerToLiquidityAccount | SYSTEM_VERSIONING | Temporal history source | All superseded mapping versions routed here; INSERT trigger captures creations. |
| History.HedgeFailInfo | HedgeServerID | Reader | Resolves LiquidityAccountID from HedgeServerID when recording hedge failures. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgeServerToLiquidityAccount (table)
- no code-level dependencies (leaf table, temporal history)
- referenced by History.HedgeFailInfo for LiquidityAccountID resolution
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerToLiquidityAccount | Table | Source temporal table |
| History.HedgeFailInfo | Stored Procedure | Resolves LiquidityAccountID: SELECT LiquidityAccountID WHERE HedgeServerID = @HedgeServerID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_HedgeServerToLiquidityAccount | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

Source table additionally has:
- CLUSTERED PK on LiquidityAccountID (FILLFACTOR=90, DATA_COMPRESSION=PAGE) - unique per account
- IXHedgeServerID: NONCLUSTERED on HedgeServerID - lookup all accounts for a server
- Idx_Hedge_HedgeServerToLiquidityAccount_LiquidityAccountID: UNIQUE NONCLUSTERED on LiquidityAccountID (FILLFACTOR=90) - redundant with PK but explicit uniqueness constraint

### 7.2 Constraints

None on history table. Source table has:
- CLUSTERED PK on LiquidityAccountID (FILLFACTOR=90)
- UNIQUE NONCLUSTERED on LiquidityAccountID (FILLFACTOR=90) - redundant uniqueness enforcement
- Three FK constraints (HedgeServerID, LiquidityAccountID, AltRatesLiquidityAccountID)
- DEFAULT NULL for AltRatesLiquidityAccountID

### 7.3 Notes

- Dual audit pattern: temporal versioning (this table) + per-column History.AuditHistory writes via INSERT/UPDATE/DELETE triggers (same as Hedge.InstrumentConfiguration)
- PK on LiquidityAccountID only (not composite): a given liquidity account can only be on one hedge server at a time, but a hedge server can have multiple accounts
- Note: History.HedgeFailInfo reads from the live `Hedge.HedgeServerToLiquidityAccount` (not this history table) at failure-recording time
- AppLoginName null-byte padding: the .NET ConfigurationManager application writes context_info as a Unicode (UTF-16) string, resulting in null bytes between characters and null-byte padding to fill the 128-byte context_info buffer

---

## 8. Sample Queries

### 8.1 Current liquidity account assignments per hedge server

```sql
SELECT
    hstla.HedgeServerID,
    hs.Name AS HedgeServerName,
    hstla.LiquidityAccountID,
    la.Name AS LiquidityAccountName,
    hstla.AltRatesLiquidityAccountID
FROM Hedge.HedgeServerToLiquidityAccount hstla WITH (NOLOCK)
JOIN Trade.HedgeServer hs WITH (NOLOCK) ON hs.HedgeServerID = hstla.HedgeServerID
JOIN Trade.LiquidityAccounts la WITH (NOLOCK) ON la.LiquidityAccountID = hstla.LiquidityAccountID
ORDER BY hstla.HedgeServerID;
```

### 8.2 History of liquidity account reassignments for a hedge server

```sql
SELECT
    h.HedgeServerID,
    h.LiquidityAccountID,
    LEFT(h.AppLoginName, CHARINDEX(';', h.AppLoginName + ';') - 1) AS Operator,
    h.DbLoginName,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    DATEDIFF(DAY, h.SysStartTime, h.SysEndTime) AS DaysActive
FROM History.HedgeServerToLiquidityAccount h WITH (NOLOCK)
WHERE h.HedgeServerID = @HedgeServerID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysStartTime;
```

### 8.3 Which hedge server was using a liquidity account on a specific date

```sql
SELECT
    hstla.HedgeServerID,
    hstla.LiquidityAccountID,
    hstla.SysStartTime,
    hstla.SysEndTime
FROM Hedge.HedgeServerToLiquidityAccount
    FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' hstla WITH (NOLOCK)
WHERE hstla.LiquidityAccountID = @LiquidityAccountID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.HedgeFailInfo) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HedgeServerToLiquidityAccount | Type: Table | Source: etoro/etoro/History/Tables/History.HedgeServerToLiquidityAccount.sql*
