# History.Accounts

> Temporal history table capturing every past configuration state of Hedge.Accounts - the liquidity provider execution and pricing accounts used by eToro's hedging infrastructure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID + SysStartTime + SysEndTime (temporal period) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered on SysEndTime/SysStartTime, 1 NC on SysStartTime) |

---

## 1. Business Meaning

History.Accounts is the SQL Server system-versioned temporal history table for Hedge.Accounts. It automatically stores every superseded configuration of eToro's liquidity provider accounts - the hedge execution and pricing accounts connected to external brokers such as APEX, BMFN, FXCM, IB, and others.

Without this table, there would be no record of when a liquidity provider account was renamed, switched provider type, activated, or deactivated. It supports audit queries ("what was the configuration of account 14 on date X?"), change tracking for compliance, and operational forensics when hedge execution anomalies need to be correlated with account configuration changes.

Data flows into this table exclusively via SQL Server's temporal system-versioning mechanism - rows are automatically written here by the database engine whenever a row in Hedge.Accounts is modified or deleted. No application code writes directly to History.Accounts. To query historical states, consumers use `Hedge.Accounts FOR SYSTEM_TIME AS OF @date` or `FOR SYSTEM_TIME BETWEEN @start AND @end`, which transparently reads from both Hedge.Accounts (current) and History.Accounts (past).

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Each row represents one completed configuration period for a hedge account - the exact attribute values that were active between SysStartTime and SysEndTime.

**Columns/Parameters Involved**: `ID`, `SysStartTime`, `SysEndTime`

**Rules**:
- When a row in Hedge.Accounts is UPDATE'd, the old values are moved to History.Accounts with SysEndTime set to the current UTC time
- When a row in Hedge.Accounts is DELETE'd, the final version is moved to History.Accounts with SysEndTime set to the deletion timestamp
- A row with SysEndTime = SysStartTime represents an account that was inserted and then immediately modified in the same instant (rare, typically a trigger-induced double-write)
- Rows are never updated or deleted from History.Accounts - it is an immutable audit trail managed entirely by SQL Server

**Diagram**:
```
Hedge.Accounts (current state):
  ID=14, Name="TRAFIX UAT Fract", LiquidityProviderTypeID=40, SysStartTime=2026-03-18

History.Accounts (past states for ID=14):
  [Period 1] SysStart=2026-02-25 -> SysEnd=2026-02-25  (brief initial insert, same-instant change)
  [Period 2] SysStart=2026-02-25 -> SysEnd=2026-03-18  (stable period before latest change)
  ...

Query: SELECT * FROM Hedge.Accounts FOR SYSTEM_TIME AS OF '2026-03-01'
  -> Returns Period 2 row from History.Accounts (SysStart <= 2026-03-01 < SysEnd)
```

### 2.2 Change Audit via DbLoginName and AppLoginName

**What**: Every historical row captures WHO made the change that ended that version - the SQL Server login and the application-layer caller identity.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- DbLoginName is populated from `suser_name()` (a computed column in Hedge.Accounts, materialised into History.Accounts at change time)
- AppLoginName is populated from `CONVERT(varchar(500), context_info())` - the application sets `context_info` before executing DML, embedding the service/user identity
- These two columns together identify both the database-layer actor and the application-layer caller, providing a two-tier audit chain

---

## 3. Data Overview

| ID | Name | LiquidityProviderTypeID | AccountTypeID | IsActive | SysStartTime | SysEndTime | Meaning |
|----|------|------------------------|--------------|----------|-------------|-----------|---------|
| 14 | TRAFIX UAT Fract | 40 (APEX) | 2 (Execution Account) | true | 2026-02-25 | 2026-03-18 | A completed stable period for the APEX execution account used in UAT fractional hedging. This configuration was active for ~3 weeks before being superseded by a change on March 18. |
| 14 | TRAFIX UAT Fract | 40 (APEX) | 2 (Execution Account) | true | 2026-02-25 | 2026-02-25 | A same-instant period for account 14 on Feb 25 - the row was inserted and immediately modified (likely by the INSERT trigger in Hedge.Accounts that updates the Name field after INSERT). |
| 13 | sdf | 7 (GFT) | 2 (Execution Account) | true | 2025-12-22 | 2025-12-22 | Test/development record - name "sdf" indicates manual test data for account ID 13 connected to the GFT liquidity provider. |
| 13 | sdfsdf | 7 (GFT) | 2 (Execution Account) | true | 2025-12-22 | 2025-12-22 | An earlier version of the test account 13 name before it was updated to "sdf". Shows the temporal trail even for test data modifications. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key of the Hedge.Accounts live table. Identifies which liquidity provider account this historical row describes. Multiple rows with the same ID represent successive configuration periods for the same account. |
| 2 | Name | varchar(256) | YES | - | CODE-BACKED | Display name of the liquidity provider account (e.g., "TRAFIX UAT Fract", "APEX Production"). Set initially via the TRG_INSERT_Accounts trigger in Hedge.Accounts which copies the Name from the Inserted pseudo-table after INSERT. |
| 3 | LiquidityProviderTypeID | int | YES | - | VERIFIED | Identifies which external liquidity provider/broker this account belongs to. FK to Trade.LiquidityProviderType. Sample values: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 4=CNX, 7=GFT, 8=BitStamp, 11=IB, 12=IG Execution, 40=APEX. Determines which broker connection this account maps to in the hedging system. |
| 4 | AccountTypeID | int | YES | - | VERIFIED | Classification of the account's role in eToro's hedging infrastructure. FK to Dictionary.HedgeAccountType: 2=Execution Account (used for actual hedge order execution), 4=OMS IM Pricing Account (used for pricing in the Order Management System). Only two types exist in the current system. |
| 5 | Username | varchar(256) | YES | - | NAME-INFERRED | Credential username for connecting to the liquidity provider's trading system or API. Not referenced by name in discovered stored procedures - likely used by the hedging application layer when authenticating to the external broker. |
| 6 | IsActive | bit | NO | - | CODE-BACKED | Whether the account was active during this historical period. 1=active (eligible for hedge order routing), 0=inactive (disabled, not used for hedging). Referenced in Hedge.GetActiveAccountByProviderAndAccountType which filters WHERE IsActive = 1. |
| 7 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login name of the database principal who made the change that ended this version. Materialised from the computed column `suser_name()` in Hedge.Accounts. Identifies the database-layer actor in the two-tier audit chain (e.g., a service account login). |
| 8 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-layer caller identity who initiated the change. Materialised from the computed column `CONVERT(varchar(500), context_info())` in Hedge.Accounts. The calling application sets `SET CONTEXT_INFO` before DML operations to embed its identity. Complements DbLoginName to show both the application and DB actor. |
| 9 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version of the account row became active in Hedge.Accounts. Set automatically by SQL Server temporal system-versioning. Together with SysEndTime defines the validity window of this historical configuration. |
| 10 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded (by an UPDATE or DELETE in Hedge.Accounts). Set automatically by SQL Server. The clustered index leads with SysEndTime to optimise FOR SYSTEM_TIME range queries which filter by period end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderTypeID | Trade.LiquidityProviderType | Implicit (no FK on history table) | Identifies the external broker/LP. FK enforced on Hedge.Accounts; History.Accounts carries no constraint by design. |
| AccountTypeID | Dictionary.HedgeAccountType | Implicit (no FK on history table) | Classifies the account role (Execution vs OMS Pricing). FK enforced on Hedge.Accounts. |
| ID | Hedge.Accounts | Temporal relationship | Each history row belongs to the current account record in Hedge.Accounts. Query via FOR SYSTEM_TIME clause to join current and historical states. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.Accounts | SYSTEM_VERSIONING | Temporal (auto) | SQL Server writes to History.Accounts automatically when Hedge.Accounts rows change. No direct references in application code. |
| Hedge.GetHedgeServerInfo | Hedge.Accounts FOR SYSTEM_TIME | Temporal read | Consumers query Hedge.Accounts with FOR SYSTEM_TIME, which transparently reads History.Accounts for past states. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Accounts (table)
  - leaf node: temporal history table, no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. Temporal history tables carry no FK constraints, computed columns, or code references. All structural dependencies are in the live table Hedge.Accounts.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Accounts | Table | Live table whose history is stored here via SYSTEM_VERSIONING |
| Hedge.SyncLiquidityAccounts | Stored Procedure | Reads/writes Hedge.Accounts (which manages this history table indirectly) |
| Hedge.GetActiveAccountByProviderAndAccountType | Stored Procedure | Reads Hedge.Accounts (live); historical versions archived here |
| Hedge.GetHedgeServerInfo | Stored Procedure | Reads Hedge.Accounts; past states available via History.Accounts |
| Hedge.GetHedgeServerMetaData | Stored Procedure | Reads Hedge.Accounts; historical configs stored here |
| Hedge.CheckAccountUsernameExists | Stored Procedure | Reads Hedge.Accounts.Username; historical Username values stored here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Accounts | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |
| IX_SysStartTime | NONCLUSTERED | SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page-level compression applied at table and clustered index level to reduce storage for this potentially large history table. |

---

## 8. Sample Queries

### 8.1 Retrieve full configuration history for a specific hedge account
```sql
SELECT
    ha.ID,
    ha.Name,
    lpt.Name            AS LiquidityProvider,
    hat.Name            AS AccountType,
    ha.Username,
    ha.IsActive,
    ha.DbLoginName,
    ha.AppLoginName,
    ha.SysStartTime,
    ha.SysEndTime,
    DATEDIFF(MINUTE, ha.SysStartTime, ha.SysEndTime) AS DurationMinutes
FROM History.Accounts ha WITH (NOLOCK)
LEFT JOIN Trade.LiquidityProviderType lpt WITH (NOLOCK)
    ON ha.LiquidityProviderTypeID = lpt.LiquidityProviderTypeID
LEFT JOIN Dictionary.HedgeAccountType hat WITH (NOLOCK)
    ON ha.AccountTypeID = hat.AccountTypeID
WHERE ha.ID = 14
ORDER BY ha.SysStartTime ASC;
```

### 8.2 Retrieve the active configuration of all hedge accounts at a point in time
```sql
-- Uses the live table with FOR SYSTEM_TIME which reads History.Accounts transparently
SELECT
    a.ID,
    a.Name,
    a.LiquidityProviderTypeID,
    a.AccountTypeID,
    a.IsActive,
    a.SysStartTime,
    a.SysEndTime
FROM Hedge.Accounts FOR SYSTEM_TIME AS OF '2025-06-01'
    WITH (NOLOCK) AS a
ORDER BY a.ID;
```

### 8.3 Find all configuration changes in the last 30 days and who made them
```sql
SELECT
    ha.ID,
    ha.Name,
    ha.IsActive,
    ha.DbLoginName,
    ha.AppLoginName,
    ha.SysStartTime    AS ChangeTime,
    ha.SysEndTime      AS SupersededAt
FROM History.Accounts ha WITH (NOLOCK)
WHERE ha.SysStartTime >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY ha.SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Accounts | Type: Table | Source: etoro/etoro/History/Tables/History.Accounts.sql*
