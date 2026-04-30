# History.AccountRateSource

> Temporal history table for Price.AccountRateSource, capturing all changes to the price feed provider registry used by eToro's pricing engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (SysEndTime, SysStartTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime, PAGE compressed) |

---

## 1. Business Meaning

History.AccountRateSource is the SQL Server system-versioning history table for `Price.AccountRateSource`, which is the master registry of all price feed providers (rate sources) in eToro's pricing engine. Every time a rate source is added, renamed, or removed, the old version of that row is moved here automatically by the temporal mechanism, providing a complete audit trail of pricing infrastructure changes over time.

The source table `Price.AccountRateSource` defines named price data sources — from simulation feeds (for demo accounts) to real institutional feeds such as Bloomberg, ZBFX (FX broker), Xignite (stock market data), GDAX/Kraken (crypto exchanges), and FIX protocol connections to major liquidity providers. This history table answers "what was the name of rate source 555 in November 2024?" and "when was TalosCrypto added as a price provider?" — questions important for incident investigation and pricing infrastructure audits.

Data flows in automatically via SQL Server SYSTEM_VERSIONING: any INSERT, UPDATE, or DELETE on `Price.AccountRateSource` moves the old row version here. Additionally, INSERT/UPDATE/DELETE audit triggers write changes to `History.AuditHistory` (ASM-managed audit framework). With only 33 history rows across 29 distinct IDs, this is an infrequently changed configuration table — rate sources rarely change names once established.

---

## 2. Business Logic

### 2.1 Rate Source ID Numbering Scheme

**What**: AccountRateSourceIDs follow an informal numbering convention that groups providers by type.

**Columns/Parameters Involved**: `AccountRateSourceID`, `Name`

**Rules**:
- ID -1: Special sentinel ("US") for US-market-specific routing
- ID 0: "Do not use!" - disabled/invalid sentinel, blocked from active use
- IDs 1-6: Simulation price sources (non-stocks, stocks by exchange: BATS, DAX, FTSE)
- IDs 8-299: Legacy HTTP/WebSocket providers (Xignite, Goldman Sachs, ZBFX, Bloomberg, crypto exchanges)
- IDs 9001-9010: FIX protocol connections (9001=FIX_ZBFX, 9002=FIX_EXANTE, 9003=FIX_FD, 9004=FIX_FXCM, 9005=FIX_IG, 9006=FIX_BITA, 9010=TalosCrypto)
- IDs 100000+: OMS-integrated providers (100017=OMS Bloomberg, 100019=ICE Price Provider)

**Diagram**:
```
AccountRateSourceID ranges:
  -1         = US (special sentinel)
  0          = Do not use! (disabled)
  1-6        = Simulation feeds (demo/paper trading)
  5          = eToro Custom Price Provider
  8-299      = Real HTTP/WebSocket providers (Xignite, ZBFX, Bloomberg, crypto)
  9001-9010  = FIX protocol providers
  100000+    = OMS-integrated providers
```

### 2.2 Dual Audit Mechanism

**What**: Changes to Price.AccountRateSource are captured in two separate audit paths - temporal history here and row-level audit in History.AuditHistory.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- SQL Server temporal: captures ALL DML as row versions in this table (INSERT via TRG_T_AccountRateSource no-op trick, UPDATE and DELETE natively)
- ASM triggers (AuditInsert/AuditUpdate/AuditDelete_Price_AccountRateSource): write the changed Name value to History.AuditHistory with old/new values and operation type (I/U/D)
- The two mechanisms are complementary: temporal gives complete row snapshots; AuditHistory gives a flat log of specific field changes with user context

---

## 3. Data Overview

33 history rows for 29 distinct rate source IDs. Small change volume reflects stability of the price source registry. Most rows are INSERT-triggered captures (SysStartTime = SysEndTime). The ID=0 "Do not use!" entry had multiple changes in Dec 2025.

| AccountRateSourceID | Name | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|
| 0 | Do not use! | 2025-12-22 10:18:17 | 2025-12-22 11:29:31 | Version of the disabled sentinel entry that was active for ~71 minutes on 2025-12-22 - a transient state during a configuration change. |
| 555 | BBG Futures | 2024-11-18 12:27:34 | 2024-11-18 12:27:34 | INSERT-triggered capture of Bloomberg Futures feed provider being added. SysStart = SysEnd confirms this is an INSERT record (the no-op UPDATE trigger fires within the same transaction). |
| 9010 | TalosCrypto | 2024-11-02 10:30:21 | 2024-11-02 10:30:21 | INSERT-triggered capture of TalosCrypto (crypto price feed provider) being added on 2024-11-02. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountRateSourceID | int | NO | - | VERIFIED | The unique integer identifier for a price feed provider. Inherited from Price.AccountRateSource (PK). In history, multiple rows can share the same ID - one row per version of that provider's record. See Section 2.1 for the ID numbering scheme (-1=US, 0=Do not use!, 1-6=Simulation, 8-299=HTTP providers, 9001-9010=FIX, 100000+=OMS). |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable name of the price feed provider. The only substantive data column (all other columns are audit/temporal). Example values: "Bloomberg Price", "ZBFX2", "TalosCrypto", "Kraken Direct Book", "Simulation Stocks BATS", "Do not use!". Changes to this column are captured in both this history table and History.AuditHistory via ASM triggers. |
| 3 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | Database login name that made the change. Computed column in source (suser_name()), stored as literal in history. Identifies the service account or DBA that modified the rate source registry. Part of the audit trail for pricing infrastructure changes. |
| 4 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application-level session context at the time of change. Computed from context_info() in source table, stored as literal here. Identifies the application or admin tool responsible for the configuration change. NULL if context_info was not set by the application. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version became active in Price.AccountRateSource. Generated by SQL Server temporal system. For INSERT-captured rows: very close to SysEndTime (milliseconds). |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version was superseded in Price.AccountRateSource. First key in the clustered index (SysEndTime, SysStartTime), optimising FOR SYSTEM_TIME AS OF queries. For INSERT-captured rows: equals SysStartTime (both within same transaction). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Temporal history tables carry no FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.AccountRateSource | (temporal system) | Source Table | SQL Server SYSTEM_VERSIONING writes superseded row versions here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AccountRateSource (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. Temporal history tables have no FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.AccountRateSource | Table | Source - SQL Server temporal moves superseded rows here. FOR SYSTEM_TIME queries implicitly access this table. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_AccountRateSource | CLUSTERED (PAGE compressed) | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | Temporal history tables have no PK or FK constraints by SQL Server design. |

---

## 8. Sample Queries

### 8.1 Get full change history for a specific rate source
```sql
SELECT
    AccountRateSourceID,
    [Name],
    SysStartTime  AS ValidFrom,
    SysEndTime    AS ValidTo,
    DbLoginName,
    AppLoginName
FROM History.AccountRateSource WITH (NOLOCK)
WHERE AccountRateSourceID = 555
ORDER BY SysStartTime ASC;
```

### 8.2 Point-in-time state of all rate sources (use temporal syntax on source)
```sql
SELECT AccountRateSourceID, [Name]
FROM Price.AccountRateSource
FOR SYSTEM_TIME AS OF '2024-11-01T00:00:00.000'
ORDER BY AccountRateSourceID;
```

### 8.3 Find all rate source additions and renames with dates
```sql
SELECT
    AccountRateSourceID,
    [Name],
    SysStartTime  AS ChangedAt,
    CASE
        WHEN ABS(DATEDIFF(millisecond, SysStartTime, SysEndTime)) < 100 THEN 'INSERT (capture)'
        ELSE 'UPDATE/RENAME'
    END AS ChangeType,
    DbLoginName
FROM History.AccountRateSource WITH (NOLOCK)
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AccountRateSource | Type: Table | Source: etoro/etoro/History/Tables/History.AccountRateSource.sql*
