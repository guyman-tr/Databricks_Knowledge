# History.LiquidityAccounts

> SQL Server temporal history table storing prior row versions of Trade.LiquidityAccounts, preserving the full audit trail for changes to liquidity provider connection accounts used in trading execution and price feed routing.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.LiquidityAccounts is the SQL Server system-versioning history table for Trade.LiquidityAccounts. It is declared as `HISTORY_TABLE = [History].[LiquidityAccounts]` in the Trade.LiquidityAccounts DDL. Whenever a row in Trade.LiquidityAccounts is updated or deleted, the prior version is automatically written here by the SQL Server temporal engine.

Trade.LiquidityAccounts represents the brokerage connection accounts to external liquidity providers (LPs). Each account has a type (Price Account, Execution Account, etc.), is linked to a specific LP, and may have connection credentials and XML configuration. These accounts are the operational connections through which eToro routes price feeds and trade execution to external markets. The history table captures every configuration change to these connections over time.

The active table (Trade.LiquidityAccounts) has an INSERT trigger (Tr_T_LiquidityAccounts_INSERT) that performs a no-op UPDATE on the newly inserted row, forcing SQL Server temporal versioning to generate an immediate history record on every INSERT. This means every new liquidity account produces an INSERT artifact row in this history table where SysStartTime = SysEndTime. Genuine updates produce history rows with SysStartTime < SysEndTime. The table currently holds 226 rows.

The duplicate AuditDelete/AuditInsert/AuditUpdate triggers on the active table also write to History.AuditHistory for a field-by-field audit trail, providing two complementary mechanisms for tracking changes.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server writes superseded row versions from Trade.LiquidityAccounts into this table when rows are updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, all data columns

**Rules**:
- When Trade.LiquidityAccounts is INSERTed: Tr_T_LiquidityAccounts_INSERT trigger does a no-op UPDATE on the inserted row, causing SQL Server to immediately close that first version and open a new one. This creates an INSERT artifact row here with SysStartTime = SysEndTime.
- When Trade.LiquidityAccounts row is genuinely UPDATEd: the old version is written here with SysStartTime = original row creation time, SysEndTime = update timestamp
- When Trade.LiquidityAccounts row is DELETEd: the deleted version is written here with SysEndTime = deletion timestamp

**Diagram**:
```
Trade.LiquidityAccounts INSERT (new account):
  Trigger fires -> no-op UPDATE -> SysVersioning closes & reopens immediately
  HistoryLiquidityAccounts row: SysStart = SysEnd = insert_time (artifact)

Trade.LiquidityAccounts UPDATE (e.g., account renamed):
  Old version -> HistoryLiquidityAccounts: SysStart = prior_start, SysEnd = update_time
  New active row: SysStart = update_time, SysEnd = 9999-12-31
```

### 2.2 Computed Columns Materialized in History

**What**: DbLoginName and AppLoginName are computed (non-persisted) columns in the active table. In this history table they are stored as regular nullable columns.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- DbLoginName captures the SQL Server login name (suser_name()) at version-close time
- AppLoginName captures the application context_info() at version-close time
- Both become stored snapshot values here, preserving which user/application made each change

### 2.3 Dual Audit Mechanism

**What**: Trade.LiquidityAccounts has both SYSTEM_VERSIONING (temporal history) AND dedicated Audit triggers (AuditInsert/Update/Delete) that write to History.AuditHistory.

**Rules**:
- SYSTEM_VERSIONING captures the full row state at each version change (this table)
- AuditHistory captures field-by-field old/new values for each changed column
- Both run on every INSERT/UPDATE/DELETE - they complement each other

---

## 3. Data Overview

226 rows total. Sample history versions (most recent changes first):

| LiquidityAccountID | LiquidityAccountName | LiquidityProviderID | IsActive | LiquidityAccountTypeID | SysStartTime | SysEndTime | Meaning |
|-------------------|---------------------|--------------------|---------|-----------------------|-------------|------------|---------|
| 14 | TRAFIX UAT Fract - Obsolete! | 67 | true | 2 (Execution) | 2026-02-25 | 2026-03-18 | This execution account was updated between Feb 25 and Mar 18 - captures the state between those two modifications |
| 8 | ZBFX Price1 Execution | 69 | true | 2 (Execution) | 2023-09-15 | 2026-03-18 | ZBFX execution account was active from Sept 2023 until it was modified on Mar 18 2026 |
| 14 | TRAFIX UAT Fract - Obsolete! | 67 | true | 2 (Execution) | 2026-02-25 | 2026-02-25 | INSERT artifact (Tr_T_LiquidityAccounts_INSERT trigger) - zero-duration version created on insert |

LiquidityAccountTypeID distribution in history: 1 (Price Account) = 134 rows, 2 (Execution Account) = 89 rows, 4 (OMS IM Pricing Account) = 3 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | VERIFIED | Unique identifier for the liquidity account. Implicit FK back to Trade.LiquidityAccounts.LiquidityAccountID. Identifies which account configuration this historical version belongs to. |
| 2 | LiquidityAccountName | varchar(50) | YES | - | VERIFIED | Human-readable name of the liquidity account at this version. Examples: "ZBFX Price1 Execution", "TRAFIX UAT Fract - Obsolete! Use Hedge Account". Name changes are tracked as history rows. |
| 3 | LiquidityProviderID | int | YES | - | VERIFIED | ID of the liquidity provider (broker/LP) this account connects to. Implicit FK to Trade.LiquidityProviders. Observed provider IDs: 66, 67, 69. NULL if not assigned. |
| 4 | Username | varchar(50) | YES | - | CODE-BACKED | Connection username for authenticating with the liquidity provider's API/FIX feed at this version. Captured in history to track credential changes. |
| 5 | Password | varchar(50) | YES | - | CODE-BACKED | Connection password for authenticating with the LP's API at this version. Stored in plaintext. Captured in history for audit purposes. |
| 6 | SettingsXML | xml | YES | - | CODE-BACKED | XML configuration blob for the LP connection at this version (connection parameters, routing rules, session settings). Changes to the XML trigger a new history row. |
| 7 | IsActive | bit | NO | - | VERIFIED | Whether the liquidity account was active at this version: 1=active (routing trades/prices through this account), 0=inactive. DEFAULT 1 in active table. Deactivation of an account creates a history row capturing the active state before deactivation. |
| 8 | LiquidityAccountTypeID | int | NO | - | VERIFIED | Type of liquidity account at this version: 0=NONE, 1=Price Account (receives price feed only), 2=Execution Account (sends orders for execution), 3=Price and Execution Account, 4=OMS IM Pricing Account. FK to Dictionary.LiquidityAccountType. DEFAULT 1 in active table. |
| 9 | AccountRateSourceID | int | YES | - | CODE-BACKED | ID of the rate source associated with this account at this version. FK to Price.AccountRateSource. Determines which price feed the account subscribes to. -1 observed (possibly sentinel for "managed rate source"). NULL if no rate source assigned. |
| 10 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | Materialized SQL Server login name (suser_name()) at the time this row version was closed. In the active table this is a computed column; stored here as a snapshot. Identifies which DB login modified the account. |
| 11 | AppLoginName | varchar(500) | YES | - | VERIFIED | Materialized application identity (context_info()) at version close time. Stored here as a snapshot. NULL if not set by the writing application. |
| 12 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this row version. Set by SQL Server temporal engine. For INSERT artifacts (trigger-generated): equals SysEndTime. For genuine history: the time the prior UPDATE took effect. |
| 13 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window for this row version. Set by SQL Server temporal engine to the UTC time of the UPDATE or DELETE that closed this version. CLUSTERED INDEX is ordered by (SysEndTime, SysStartTime) for optimal temporal range scans. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | The account whose historical version this row represents. |
| LiquidityProviderID | Trade.LiquidityProviders | Implicit | The LP this account connects to at this version. |
| LiquidityAccountTypeID | Dictionary.LiquidityAccountType | Implicit | Account type at this version: 1=Price, 2=Execution, 3=P&E, 4=OMS IM Pricing. |
| AccountRateSourceID | Price.AccountRateSource | Implicit | The price feed rate source at this version. FK mirrors active table's FK_LiquidityAccounts_AccountRateSourceID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityAccounts | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | Declares this as its HISTORY_TABLE. All closed row versions flow here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LiquidityAccounts (table)
  - leaf node: no code-level dependencies
  - auto-populated by SQL Server from: Trade.LiquidityAccounts (temporal parent)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | Declares this as its HISTORY_TABLE for SYSTEM_VERSIONING. All temporal version rows flow here. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_LiquidityAccounts | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

DATA_COMPRESSION=PAGE on [MAIN] filegroup. TEXTIMAGE_ON [MAIN] (for xml column storage).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION=PAGE | Storage option | Page-level compression applied to all data and index pages. |

No explicit FKs or check constraints. Integrity is maintained through the SYSTEM_VERSIONING contract with Trade.LiquidityAccounts.

---

## 8. Sample Queries

### 8.1 Get all historical versions of a specific liquidity account
```sql
SELECT LiquidityAccountID, LiquidityAccountName, LiquidityProviderID, IsActive,
       LiquidityAccountTypeID, AccountRateSourceID, SysStartTime, SysEndTime,
       CASE WHEN SysStartTime = SysEndTime THEN 'INSERT artifact' ELSE 'Genuine change' END AS VersionType
FROM History.LiquidityAccounts WITH (NOLOCK)
WHERE LiquidityAccountID = 8
ORDER BY SysStartTime;
```

### 8.2 Use FOR SYSTEM_TIME ALL to query full account history via active table
```sql
SELECT LiquidityAccountID, LiquidityAccountName, LiquidityProviderID, IsActive,
       LiquidityAccountTypeID, SysStartTime, SysEndTime
FROM Trade.LiquidityAccounts WITH (NOLOCK)
FOR SYSTEM_TIME ALL
WHERE LiquidityAccountID = 8
ORDER BY SysStartTime;
```

### 8.3 Find all accounts that changed type (LiquidityAccountTypeID changed)
```sql
SELECT h.LiquidityAccountID, h.LiquidityAccountName,
       h.LiquidityAccountTypeID AS OldTypeID,
       la.LiquidityAccountTypeID AS CurrentTypeID,
       h.SysEndTime AS ChangedAt
FROM History.LiquidityAccounts h WITH (NOLOCK)
JOIN Trade.LiquidityAccounts la WITH (NOLOCK) ON h.LiquidityAccountID = la.LiquidityAccountID
WHERE h.LiquidityAccountTypeID <> la.LiquidityAccountTypeID
  AND h.SysStartTime <> h.SysEndTime  -- exclude INSERT artifacts
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 trigger analyzed + 3 audit triggers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LiquidityAccounts | Type: Table | Source: etoro/etoro/History/Tables/History.LiquidityAccounts.sql*
