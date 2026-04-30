# History.PlayerLevelToCashoutFeeGroup

> SQL Server temporal history table storing prior row versions of Billing.PlayerLevelToCashoutFeeGroup, capturing changes to the mapping that determines which cashout fee group applies to each customer Club Group (player level).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (ValidTo ASC, ValidFrom ASC) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 (clustered on temporal period columns) |

---

## 1. Business Meaning

History.PlayerLevelToCashoutFeeGroup is the SQL Server system-versioning history table for Billing.PlayerLevelToCashoutFeeGroup (declared as `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[PlayerLevelToCashoutFeeGroup])`). Whenever a mapping row is updated or deleted, the prior version is automatically written here.

Billing.PlayerLevelToCashoutFeeGroup defines which cashout fee group applies to customers at each Club Group (player level). The mapping drives whether customers pay a withdrawal fee and how much, with higher-tier members (Platinum and above) mapped to fee-exempt or discounted groups. When a customer's Club Group changes (upgrade or downgrade), Billing.ProcessCashoutFeeGroupUpdate reads this table to determine the new CashoutFeeGroupID and updates BackOffice.Customer accordingly.

The source table uses non-standard temporal column names: `ValidFrom` and `ValidTo` (named as the PERIOD FOR SYSTEM_TIME columns) instead of the SQL Server standard `SysStartTime`/`SysEndTime`. The history table inherits these column names.

The history table currently has 0 rows - the mapping configuration has been stable since initial setup in September 2021. The source table has 6 active rows (one per tier, except Internal which is not mapped).

---

## 2. Business Logic

### 2.1 Club Group to Cashout Fee Group Mapping

**What**: Each player level (Club Group) maps to a cashout fee group that governs the fee charged on withdrawals.

**Columns/Parameters Involved**: `PlayerLevelID`, `CashoutFeeGroupID`, `ValidFrom`, `ValidTo`

**Rules**:
- Each PlayerLevelID has at most one active mapping row in the source table.
- CashoutFeeGroup 1=Default: standard withdrawal fees apply.
- CashoutFeeGroup 2=Exempt: no withdrawal fee (premium benefit for Platinum and above).
- CashoutFeeGroup 3=Discount: reduced fee (not currently assigned to any player level).
- Current active mapping (from source table, established Sep 2021):
  - Bronze (1) -> Default (1): standard fees
  - Platinum (2) -> Exempt (2): fee-free withdrawals
  - Gold (3) -> Default (1): standard fees
  - Silver (5) -> Default (1): standard fees
  - Platinum Plus (6) -> Exempt (2): fee-free withdrawals
  - Diamond (7) -> Exempt (2): fee-free withdrawals
  - Internal (4): not mapped in this table

### 2.2 Fee Group Resolution Logic (MAX Wins)

**What**: When assigning a customer's cashout fee group, both their player level AND their guru/popular investor status are considered; the higher (more favorable) group ID wins.

**Columns/Parameters Involved**: `CashoutFeeGroupID`, `PlayerLevelID`

**Rules**:
- Billing.ProcessCashoutFeeGroupUpdate queries both this table (by PlayerLevelID) and Billing.GuruStatusToCashoutFeeGroup (by GuruStatusID).
- `SELECT MAX(CashoutFeeGroupID)` across both results determines the effective fee group.
- A higher CashoutFeeGroupID wins - if a Bronze-level customer is also a Popular Investor exempt by guru status, they get the Exempt fee group.
- Country exclusion list can override: if customer's country is in the exclusion list, no update is made.
- The fee group update only writes to BackOffice.Customer if CashoutFeeGroupID actually changes (@@ROWCOUNT check).

### 2.3 Trace Audit Column

**What**: The Trace column captures the application context at the time of each write for operational audit.

**Columns/Parameters Involved**: `Trace`

**Rules**:
- Computed column in source table: `concat('{"HostName": "',host_name(),'","AppName": "',app_name(),'","SUserName": "',suser_name(),'","SPID": "',@@spid,'","DBName": "',db_name(),'","ObjectName": "',object_name(@@procid),'"}')`
- Captured at write time and stored as nvarchar(733) in the history table.
- ObjectName will be the stored procedure name if called from a proc, or empty string if executed ad-hoc.

---

## 3. Data Overview

History table is currently empty (0 rows) - the mapping configuration has not changed since initial setup in September 2021.

Current source table state (for reference):

| ID | PlayerLevelID | PlayerLevel | CashoutFeeGroupID | CashoutFeeGroup | ValidFrom |
|----|---------------|-------------|-------------------|-----------------|-----------|
| 1 | 1 | Bronze | 1 | Default | 2021-09-19 |
| 2 | 2 | Platinum | 2 | Exempt | 2021-09-19 |
| 3 | 3 | Gold | 1 | Default | 2021-09-19 |
| 4 | 5 | Silver | 1 | Default | 2021-09-19 |
| 5 | 6 | Platinum Plus | 2 | Exempt | 2021-09-19 |
| 6 | 7 | Diamond | 2 | Exempt | 2021-09-19 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | IDENTITY from source table (Billing.PlayerLevelToCashoutFeeGroup.ID). Not unique in history table (same ID may appear multiple times across version windows). |
| 2 | PlayerLevelID | int | NO | NULL | CODE-BACKED | The customer Club Group tier. FK to Dictionary.PlayerLevel. Values: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Bronze/Gold/Silver use Default fees; Platinum/PlatinumPlus/Diamond are Exempt. |
| 3 | CashoutFeeGroupID | int | NO | NULL | CODE-BACKED | The cashout fee group assigned to this player level. FK to Dictionary.CashoutFeeGroup. Values: 1=Default (standard fee), 2=Exempt (no fee), 3=Discount (reduced fee, unused). |
| 4 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON audit string computed at write time from host_name(), app_name(), suser_name(), @@spid, db_name(), object_name(@@procid). Format: {"HostName":"...","AppName":"...","SUserName":"...","SPID":"...","DBName":"...","ObjectName":"..."}. ObjectName identifies the calling stored procedure. |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active. SQL Server temporal period start column (named ValidFrom instead of standard SysStartTime in Billing.PlayerLevelToCashoutFeeGroup). |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded. SQL Server temporal period end column (named ValidTo instead of standard SysEndTime). ValidFrom=ValidTo indicates an INSERT-capture record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Billing.PlayerLevelToCashoutFeeGroup | Temporal History | This table is the declared HISTORY_TABLE for Billing.PlayerLevelToCashoutFeeGroup. |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit | Club Group tier lookup. FK enforced in source table. |
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | Implicit | Cashout fee group lookup. FK enforced in source table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PlayerLevelToCashoutFeeGroup | HISTORY_TABLE | Temporal system versioning | All row version changes are automatically written here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PlayerLevelToCashoutFeeGroup | Table | Source of all history writes via SQL Server temporal system versioning |
| Billing.ProcessCashoutFeeGroupUpdate | Stored Procedure | READER of source table - looks up CashoutFeeGroupID by PlayerLevelID to determine customer's effective fee group on level change |
| Billing.UpdateCashoutFeeGroupID | Stored Procedure | READER of source table - updates customer cashout fee group |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PlayerLevelToCashoutFeeGroup | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints.

### 7.3 Storage

| Property | Value |
|----------|-------|
| Filegroup | PRIMARY |
| Data Compression | PAGE |

---

## 8. Sample Queries

### 8.1 Check history table for any configuration changes

```sql
SELECT ID, PlayerLevelID, CashoutFeeGroupID, ValidFrom, ValidTo,
       DATEDIFF(DAY, ValidFrom, ValidTo) AS ActiveDays
FROM History.PlayerLevelToCashoutFeeGroup WITH (NOLOCK)
ORDER BY ValidFrom;
```

### 8.2 View full version history for a specific player level mapping

```sql
SELECT 'History' AS Version, ID, PlayerLevelID, CashoutFeeGroupID, ValidFrom, ValidTo
FROM History.PlayerLevelToCashoutFeeGroup WITH (NOLOCK)
WHERE PlayerLevelID = 2  -- Platinum
UNION ALL
SELECT 'Current', ID, PlayerLevelID, CashoutFeeGroupID, ValidFrom, ValidTo
FROM Billing.PlayerLevelToCashoutFeeGroup WITH (NOLOCK)
WHERE PlayerLevelID = 2
ORDER BY ValidFrom;
```

### 8.3 Temporal query - mapping state at a point in time

```sql
-- SQL Server temporal FOR SYSTEM_TIME AS OF (uses ValidFrom/ValidTo period)
SELECT ID, PlayerLevelID, CashoutFeeGroupID, ValidFrom, ValidTo
FROM Billing.PlayerLevelToCashoutFeeGroup
FOR SYSTEM_TIME AS OF '2022-01-01T00:00:00'
ORDER BY PlayerLevelID;
```

---

## 9. Atlassian Knowledge Sources

### 9.1 Confluence

| Page | Relevance |
|------|-----------|
| Cashout Fee Groups Auto Assignment Design | Design doc for automatic CashoutFeeGroup assignment based on Club Group (PlayerLevel) and GuruStatus changes. Confirms the MAX-wins logic and Routing Tool management pattern. |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PlayerLevelToCashoutFeeGroup | Type: Table | Source: etoro/etoro/History/Tables/History.PlayerLevelToCashoutFeeGroup.sql*
