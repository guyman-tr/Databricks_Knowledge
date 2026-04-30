# History.TradeCashoutRange

> SQL Server system-versioned temporal history table for Trade.CashoutRange - automatically stores superseded cashout fee range configurations, enabling point-in-time queries on fee structures.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (ValidTo ASC, ValidFrom ASC) |
| **Partition** | No - stored on [PRIMARY] with PAGE compression |
| **Indexes** | 1 active (CLUSTERED on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.TradeCashoutRange is the temporal history backing table for Trade.CashoutRange, which defines the fee schedule for cashout (withdrawal) transactions. Each time a cashout fee range is created, updated, or deleted in Trade.CashoutRange, SQL Server's system-versioning mechanism automatically copies the old row version into this history table, stamped with the `ValidFrom`/`ValidTo` period during which that configuration was active.

Trade.CashoutRange structures cashout fees as banded ranges: a given fee group (Dictionary.CashoutFeeGroup) may define multiple rows, each covering a monetary range (FromValue to ToValue) with an associated flat fee. When the fee schedule changes - new ranges added, fees adjusted, or ranges removed - history rows accumulate here, allowing the full audit trail of every cashout fee configuration change to be retrieved.

SQL Server manages all writes to this table automatically - no stored procedures directly reference it. To query historical fee configurations, use the `FOR SYSTEM_TIME` temporal syntax on Trade.CashoutRange, which transparently joins to this history table.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Every change to Trade.CashoutRange produces a history row here, with ValidFrom/ValidTo capturing exactly when that configuration was active.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `RangeID`, `CashoutFeeGroupID`, `Fee`

**Rules**:
- ValidFrom = timestamp when this row version became active in Trade.CashoutRange
- ValidTo = timestamp when this row version was superseded (by update or delete)
- A row with ValidTo = '9999-12-31 23:59:59' would be the current version (but current rows live in Trade.CashoutRange, not here)
- The clustered index is on (ValidTo ASC, ValidFrom ASC) - optimized for temporal range queries
- SQL Server writes to this table automatically; no application code inserts directly
- PAGE compression reduces storage for accumulated historical versions

### 2.2 Cashout Fee Range Structure

**What**: Trade.CashoutRange (and thus this history) defines tiered fee bands for cashout transactions.

**Columns/Parameters Involved**: `CashoutFeeGroupID`, `FromValue`, `ToValue`, `Fee`, `IsDefault`

**Rules**:
- A fee group (Dictionary.CashoutFeeGroup) can have multiple range rows, each covering a dollar band
- The band matching a withdrawal amount determines the fee applied
- IsDefault = 1 flags the catch-all range used when no specific band matches
- FromValue/ToValue/Fee are all nullable - allows flexible configuration including flat fees (NULL range = applies always)
- CashoutFeeGroupID defaults to 0 in Trade.CashoutRange, indicating the base/ungrouped fee schedule

### 2.3 Trace Column - Change Audit Identity

**What**: The Trace column captures the database session context at the time of each change to Trade.CashoutRange.

**Columns/Parameters Involved**: `Trace`

**Rules**:
- Computed in Trade.CashoutRange as: `concat('{"HostName": "',host_name(),'","AppName": "',app_name(),'","SUserName": "',suser_name(),'","SPID": "',@@spid,'","DBName": "',db_name(),'","ObjectName": "',object_name(@@procid),'"}')`
- Produces JSON with: HostName, AppName, SUserName, SPID, DBName, ObjectName (stored procedure that made the change)
- Preserved here as a non-nullable varchar(733) - the computed expression is evaluated at DML time and the materialized value is stored in the history row
- Allows identifying which application, user, and procedure changed the configuration

---

## 3. Data Overview

Table is currently empty (0 rows) in this environment. In production, rows accumulate each time a cashout fee range configuration in Trade.CashoutRange is modified. High-frequency fee schedule changes would produce many history rows per RangeID.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RangeID | INT | NO | - | CODE-BACKED | The cashout range configuration ID from Trade.CashoutRange (IDENTITY in the source table). Identifies which range row was modified. Multiple history rows with the same RangeID show the evolution of that range over time. |
| 2 | CashoutFeeGroupID | INT | YES | NULL | CODE-BACKED | Fee group identifier linking this range to a fee schedule group. FK to Dictionary.CashoutFeeGroup in the source table (not enforced as FK in this history table). Default value in source = 0 (base fee schedule). NULL allowed. |
| 3 | FromValue | MONEY | YES | NULL | CODE-BACKED | Lower bound of the cashout amount band this fee range covers. NULL indicates no lower bound (fee applies from zero). Together with ToValue, defines which withdrawal amounts trigger this fee row. |
| 4 | ToValue | MONEY | YES | NULL | CODE-BACKED | Upper bound of the cashout amount band. NULL indicates no upper bound (fee applies up to any amount). When both FromValue and ToValue are NULL, the row acts as a universal fee. |
| 5 | Fee | MONEY | YES | NULL | CODE-BACKED | The fixed fee amount charged for withdrawals falling within this range band. Currency matches the fee group's configured currency. NULL may indicate a percentage-based fee handled in application logic. |
| 6 | IsDefault | BIT | YES | NULL | CODE-BACKED | Flags this range row as the default/catch-all fee for its group: 1 = default, 0/NULL = non-default. When no other range band matches a withdrawal amount, the default row's fee applies. |
| 7 | Trace | NVARCHAR(733) | NO | - | CODE-BACKED | JSON string capturing database session context when this row version was created in Trade.CashoutRange. Fields: HostName (server), AppName (application name), SUserName (SQL login), SPID (session ID), DBName, ObjectName (stored procedure). Used for change audit attribution. |
| 8 | ValidFrom | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became the active configuration in Trade.CashoutRange. Set automatically by SQL Server's system-versioning. Start of the temporal period for this version. |
| 9 | ValidTo | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded in Trade.CashoutRange (by an UPDATE or DELETE). Set automatically by SQL Server. End of the temporal period. Clustered index leading column for efficient temporal range queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RangeID | Trade.CashoutRange | Temporal history | Each row is a historical version of a Trade.CashoutRange row. SQL Server links them via RangeID and the temporal period. |
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | Implicit (inherited from source) | Fee group reference preserved from the Trade.CashoutRange version. No FK enforced in this history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CashoutRange | SYSTEM_VERSIONING | Temporal parent | Automatically writes superseded row versions here via SQL Server temporal versioning. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.TradeCashoutRange (table)
  (leaf - temporal history table; no code-level DDL dependencies)
```

### 6.1 Objects This Depends On

No hard DDL dependencies. The temporal relationship to Trade.CashoutRange is managed by SQL Server system-versioning, not by FK constraints in this table's DDL.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CashoutRange | Table | Temporal parent - SQL Server automatically writes to this history table on every UPDATE/DELETE to Trade.CashoutRange |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_TradeCashoutRange | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active (PAGE compression) |

Note: The clustered index leads with ValidTo (not ValidFrom). SQL Server temporal queries with `FOR SYSTEM_TIME AS OF @datetime` use ValidFrom <= @dt AND ValidTo > @dt, so leading with ValidTo narrows the scan efficiently for point-in-time lookups.

### 7.2 Constraints

None. Temporal history tables have no PK, FK, or CHECK constraints - SQL Server manages their content automatically.

---

## 8. Sample Queries

### 8.1 View current cashout fee ranges (live table)
```sql
SELECT
    cr.RangeID,
    cr.CashoutFeeGroupID,
    cr.FromValue,
    cr.ToValue,
    cr.Fee,
    cr.IsDefault,
    cr.ValidFrom
FROM Trade.CashoutRange cr WITH (NOLOCK)
ORDER BY cr.CashoutFeeGroupID, cr.FromValue;
```

### 8.2 View cashout fee configuration as it was at a point in time
```sql
SELECT
    cr.RangeID,
    cr.CashoutFeeGroupID,
    cr.FromValue,
    cr.ToValue,
    cr.Fee,
    cr.IsDefault,
    cr.ValidFrom,
    cr.ValidTo
FROM Trade.CashoutRange
FOR SYSTEM_TIME AS OF '2023-01-01T00:00:00'
ORDER BY cr.CashoutFeeGroupID, cr.FromValue;
```

### 8.3 Audit history of changes to a specific fee range
```sql
SELECT
    h.RangeID,
    h.CashoutFeeGroupID,
    h.FromValue,
    h.ToValue,
    h.Fee,
    h.ValidFrom,
    h.ValidTo,
    h.Trace
FROM History.TradeCashoutRange h WITH (NOLOCK)
WHERE h.RangeID = 1
ORDER BY h.ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal - SQL Server managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TradeCashoutRange | Type: Table | Source: etoro/etoro/History/Tables/History.TradeCashoutRange.sql*
