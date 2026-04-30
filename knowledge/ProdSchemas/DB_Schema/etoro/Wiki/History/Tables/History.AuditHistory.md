# History.AuditHistory

> Centralized column-level audit log maintained by the ASM (Audit Security Manager) trigger framework, recording every INSERT, UPDATE, and DELETE on tracked configuration tables across 26 tables in 6 schemas, from March 2014 to present.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | AuditHistoryID (PK, INT IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK) |

---

## 1. Business Meaning

History.AuditHistory is the centralized audit trail for all tracked configuration and operational table changes within the eToro database. It captures every INSERT, UPDATE, and DELETE on 26 tables across 6 schemas, recording the exact column changed, its old and new values, the user who made the change, and when it happened.

The audit entries are written by **ASM (Audit Security Manager) auto-generated triggers** - the pattern `AuditInsert_`, `AuditUpdate_`, `AuditDelete_` prefixed triggers visible in Trade.ActiveFeatureThreshold, History.AccountRateSource, and dozens of other tables. Each trigger:
1. Calls `Internal.GetUserAndAppName` to resolve the DB login and application context
2. INSERTs one row per changed column (for UPDATEs) or one row per tracked column (for I/D)
3. Records: schema, table, column, old value, new value, operation code, PK value (comma-delimited)

**Column-level granularity**: Each row represents ONE column change on ONE row. A single UPDATE affecting 3 columns on 1 table row generates 3 rows in this table. This provides precise change tracing but results in high volume.

**Scale**: 7.74 million rows from March 2014 to March 2026. The top audited tables are trading configuration tables that change frequently: `Trade.LiquidityProviderContracts` (3.5M rows), `Hedge.HBCAccountConfiguration` (1.2M), `Trade.ProviderToInstrument` (761K).

**Operations distribution**: Insert (65%, 4.99M) > Delete (26%, 1.98M) > Update (10%, 765K). The high INSERT and DELETE count (relative to UPDATE) suggests many configuration changes are add/remove operations rather than in-place edits.

**ExistingFeedID**: Populated only for `Trade.InstrumentSpread` rows (107K rows with values 1 or 2) - identifies which price feed the spread change applies to. NULL for all other audited tables.

---

## 2. Business Logic

### 2.1 ASM Trigger Write Pattern

**What**: Auto-generated ASM triggers write one column-level audit row per changed column per table row.

**Columns/Parameters Involved**: All columns

**Rules**:
- Trigger naming: `AuditInsert_{Schema}_{Table}`, `AuditUpdate_{Schema}_{Table}`, `AuditDelete_{Schema}_{Table}`
- Each trigger calls `Internal.GetUserAndAppName` (which returns SUSER_SNAME() and app_name() as fallbacks)
- UPDATE trigger: joins INSERTED and DELETED to find changed columns, inserts one row per changed column with OldValue/NewValue
- INSERT trigger: inserts one row per tracked column with OldValue=NULL, NewValue=new data
- DELETE trigger: inserts one row per tracked column with OldValue=old data, NewValue=NULL
- PK_Value: composite primary key values concatenated with comma (e.g., "1,4" = InstrumentID=1, ProviderID=4)
- AuditDate is always GETDATE() (local server time, NOT UTC - important for timestamp interpretation)

**Diagram**:
```
DBA or Application changes Trade.ProviderToInstrument
   |
   AuditUpdate_Trade_ProviderToInstrument trigger fires
   |
   Internal.GetUserAndAppName -> @UserName = 'DevTradingSTG', @Application = 'SSMS'
   |
   INSERT History.AuditHistory one row per changed column:
   {AuditDate=NOW, Operation='U', UserName='DevTradingSTG', SchemaName='Trade',
    TableName='ProviderToInstrument', ColumnName='AllowSell',
    OldValue='0', NewValue='1', PK_Value='1,4'}
```

### 2.2 Tracked Tables (Current Data)

**What**: 26 distinct schema.table combinations have ASM audit triggers writing to this table.

**Top tables by audit volume**:
- Trade.LiquidityProviderContracts: 3,547,302 rows (46%) - highest-frequency configuration changes
- Hedge.HBCAccountConfiguration: 1,231,893 rows (16%) - hedge booking configuration
- Trade.ProviderToInstrument: 761,570 rows (10%) - provider/instrument mapping changes
- Trade.ProviderInstrumentToLeverage: 481,364 rows (6%) - leverage configuration
- Trade.FeatureThresholdValues: 363,766 rows (5%) - execution feature threshold values

### 2.3 AuditDate vs UTC

**What**: AuditDate is local server time (GETDATE()), not UTC.

**Rules**:
- All AsyncExecuter and other pipeline tables use GETUTCDATE() for Occurred columns
- AuditHistory uses GETDATE() - local server time
- When correlating audit events with other tables (which use UTC), account for the server timezone offset
- This is a known inconsistency in the ASM trigger framework

---

## 3. Data Overview

7,744,170 rows, March 2014 to March 2026. Operations: 65% INSERT, 26% DELETE, 10% UPDATE. 26 audited tables across 6 schemas (Trade, Hedge, BackOffice, Dictionary, Price, and others).

| AuditHistoryID | AuditDate | Operation | UserName | SchemaName | TableName | ColumnName | OldValue | NewValue | PK_Value | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 7915640 | 2026-03-18 19:37:46 | U | DevTradingSTG | Trade | ProviderToInstrument | AllowSell | 0 | 1 | 1,4 | Column AllowSell changed from 0 to 1 for the row with PK (ProviderID=1, InstrumentID=4). User DevTradingSTG (a staging service account) made this change. The '1,4' composite PK format is specific to this table's trigger. |
| (typical) | 2026-03-18 | I | (user) | Trade | LiquidityProviderContracts | ContractValue | NULL | 1.25 | 42,7 | New row INSERTed into LiquidityProviderContracts. OldValue=NULL for INSERT operations. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AuditHistoryID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-generated IDENTITY, NOT FOR REPLICATION (independent sequence per replica). Clustered PK. |
| 2 | AuditDate | datetime | NO | - | CODE-BACKED | Local server timestamp when the change was recorded (GETDATE(), NOT UTC). Marks when the ASM trigger fired. Note: NOT UTC - see Section 2.3. |
| 3 | Operation | char(1) | NO | - | CODE-BACKED | Change type: 'I'=Insert (4.99M, 65%), 'U'=Update (765K, 10%), 'D'=Delete (1.98M, 26%). Single-character code from the ASM trigger pattern. |
| 4 | UserName | varchar(128) | NO | - | CODE-BACKED | Database login name that made the change. Resolved by Internal.GetUserAndAppName, fallback to SUSER_SNAME(). May be a service account (e.g., "DevTradingSTG"), a DBA login, or an application pool identity. |
| 5 | AppName | varchar(128) | NO | - | CODE-BACKED | Application name that made the change. Resolved by Internal.GetUserAndAppName, fallback to app_name(). Examples: "SSMS" (direct DBA access), application service names, stored procedure names. |
| 6 | HostName | varchar(128) | NO | - | CODE-BACKED | Hostname of the connection that triggered the change. From host_name() SQL Server function. Identifies the server or workstation that initiated the DML. |
| 7 | SchemaName | varchar(128) | NO | - | CODE-BACKED | SQL Server schema of the changed table. Known values from data: Trade, Hedge, BackOffice, Dictionary, Price, History. |
| 8 | TableName | varchar(128) | NO | - | CODE-BACKED | Name of the changed table (without schema). Combined with SchemaName uniquely identifies the audited object. 26 distinct tables in current data. |
| 9 | PK_Value | varchar(1000) | YES | - | CODE-BACKED | Primary key value(s) of the changed row, concatenated with commas. Format varies by table (each trigger hardcodes its own PK columns). Example: "1,4" for a 2-column PK (ProviderID=1, InstrumentID=4). NULL-able but always populated in practice. |
| 10 | ColumnName | varchar(128) | NO | - | CODE-BACKED | The specific column that changed. One row in this table represents ONE column change. An UPDATE to 5 columns generates 5 rows with the same AuditDate, PK_Value, and UserName but different ColumnName/OldValue/NewValue. |
| 11 | OldValue | varchar(max) | YES | - | CODE-BACKED | Previous value of the column, cast to VARCHAR(MAX). NULL for INSERT operations. For UPDATE: the value before the change. For DELETE: the value before deletion. |
| 12 | NewValue | varchar(max) | YES | - | CODE-BACKED | New value of the column, cast to VARCHAR(MAX). NULL for DELETE operations. For INSERT: the value after insertion. For UPDATE: the value after the change. |
| 13 | ExistingFeedID | smallint | YES | - | CODE-BACKED | Price feed identifier, populated ONLY for Trade.InstrumentSpread rows (107K records with values 1 or 2). Identifies which price feed source the spread configuration applies to. NULL for all other audited tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. SchemaName+TableName references are soft strings (not enforced).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AuditInsert_*/AuditUpdate_*/AuditDelete_* triggers | INSERT | Writers (many) | ASM-generated triggers on 26+ tables across 6 schemas. Each trigger writes column-level change records here. |
| (BackOffice admin tools) | - | Reader | Back-office and DBA tools query this table for change auditing and compliance reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AuditHistory (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

None. Receives data from triggers on many tables but has no structural dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AuditInsert/Update/Delete_Trade_ActiveFeatureThreshold | Trigger | Writer - column-level audit of ActiveThresholdID changes |
| AuditInsert/Update/Delete_Trade_ProviderToInstrument | Trigger | Writer - provider/instrument mapping changes |
| AuditInsert/Update/Delete_Hedge_HBCAccountConfiguration | Trigger | Writer - hedge booking config changes |
| AuditInsert/Update/Delete_Price_AccountRateSource | Trigger | Writer - price feed provider changes |
| (22+ additional ASM-generated triggers) | Triggers | Writers - all follow same ASM pattern |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AuditHistory | CLUSTERED PK | AuditHistoryID ASC | - | - | Active |

**Performance note**: Only the clustered PK index exists. Queries filtering by AuditDate, SchemaName+TableName, or UserName require full table scans. For large ad-hoc audit queries, consider filtering on AuditHistoryID ranges (which correlate with time order) before adding additional filters.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AuditHistory | PRIMARY KEY CLUSTERED | AuditHistoryID - surrogate PK |
| NOT FOR REPLICATION on AuditHistoryID | Identity option | Independent IDENTITY sequence per replica |

---

## 8. Sample Queries

### 8.1 Recent changes to a specific table
```sql
SELECT
    AuditHistoryID,
    AuditDate,
    Operation,
    UserName,
    ColumnName,
    OldValue,
    NewValue,
    PK_Value
FROM History.AuditHistory WITH (NOLOCK)
WHERE SchemaName = 'Trade'
  AND TableName = 'ProviderToInstrument'
  AND AuditDate >= DATEADD(day, -7, GETDATE())
ORDER BY AuditDate DESC;
```

### 8.2 All changes by a specific user (DBA investigation)
```sql
SELECT
    AuditDate,
    Operation,
    SchemaName,
    TableName,
    ColumnName,
    OldValue,
    NewValue,
    PK_Value
FROM History.AuditHistory WITH (NOLOCK)
WHERE UserName = 'DevTradingSTG'
  AND AuditDate >= '2026-03-18'
ORDER BY AuditDate DESC;
```

### 8.3 Full change history for a specific row (by PK value)
```sql
SELECT
    AuditDate,
    Operation,
    ColumnName,
    OldValue,
    NewValue,
    UserName
FROM History.AuditHistory WITH (NOLOCK)
WHERE SchemaName = 'Trade'
  AND TableName = 'LiquidityProviderContracts'
  AND PK_Value = '42,7'
ORDER BY AuditDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AuditHistory | Type: Table | Source: etoro/etoro/History/Tables/History.AuditHistory.sql*
