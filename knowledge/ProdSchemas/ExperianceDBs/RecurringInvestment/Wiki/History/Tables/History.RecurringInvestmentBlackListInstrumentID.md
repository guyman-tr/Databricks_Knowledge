# History.RecurringInvestmentBlackListInstrumentID

> System-versioned temporal history table storing previous row versions from RecurringInvestment.BlackListInstrumentID - tracks when instruments were globally blacklisted or unblacklisted from recurring investment.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Parent Table** | RecurringInvestment.BlackListInstrumentID |
| **Partition** | No |
| **Indexes** | 1 clustered on (ValidTo, ValidFrom) |
| **Data Compression** | PAGE |

---

## 1. Business Meaning

This is the SQL Server system-versioned (temporal) history table for `RecurringInvestment.BlackListInstrumentID`. It automatically stores previous versions of rows from the parent table whenever a row is updated or deleted. Each row represents a past state of a global instrument blacklist entry, bounded by the ValidFrom and ValidTo period columns.

When an instrument is removed from the global blacklist (DELETE on the parent), or when an existing entry is modified (UPDATE on the parent), SQL Server automatically moves the previous version of the row into this history table. The ValidFrom/ValidTo columns define the exact time window during which that row version was "current" in the parent table.

This table is never written to directly by application code. All inserts are handled automatically by the SQL Server temporal table mechanism. It enables point-in-time queries using `FOR SYSTEM_TIME` syntax, providing a full audit trail of when specific instruments were globally blocked from recurring investment plans. This is valuable for compliance and for understanding why an instrument may have been temporarily unavailable for recurring investment.

---

## 2. Business Logic

No independent business logic. This table is a passive recipient of historical row versions managed entirely by SQL Server's SYSTEM_VERSIONING mechanism. The business meaning mirrors the parent table: each row represents an instrument (InstrumentID) that was on the global blacklist during the period defined by ValidFrom to ValidTo.

Rows appear here in two scenarios:
- **UPDATE on parent**: The pre-update version of the row is inserted here with ValidTo set to the update timestamp.
- **DELETE on parent**: The deleted row is inserted here with ValidTo set to the deletion timestamp (instrument un-blacklisted).

---

## 3. Data Overview

Rows in this table represent instruments that were previously globally blacklisted from recurring investment but have since been removed from the blacklist, or previous versions of entries that were modified.

| InstrumentID | ValidFrom | ValidTo | Meaning |
|--------------|-----------|---------|---------|
| 1437 | 2025-02-10 09:00:00 | 2025-07-15 14:00:00 | Instrument 1437 was globally blocked from recurring investment during this period. It was un-blacklisted at ValidTo. |
| 2192 | 2025-03-20 11:00:00 | 2025-10-01 08:00:00 | Instrument 2192 was blacklisted during this window. May have been under regulatory review or delisting evaluation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | InstrumentID | int | NO | - | ID of the instrument that was globally blocked. Same as parent table RecurringInvestment.BlackListInstrumentID.InstrumentID. Identifies the instrument that was on the blacklist during the ValidFrom-ValidTo period. |
| 2 | Trace | nvarchar(733) | NO | - | Audit trail information. Same as parent table RecurringInvestment.BlackListInstrumentID.Trace, but stored as nvarchar(733) NOT computed (unlike the parent's computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current. |
| 3 | ValidFrom | datetime2(7) | NO | - | Period start - the point in time when this row version became the "current" version in the parent table. |
| 4 | ValidTo | datetime2(7) | NO | - | Period end - the point in time when this row version was superseded by an update or deleted from the parent table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | RecurringInvestment.BlackListInstrumentID | System-versioned history | System-versioned history for RecurringInvestment.BlackListInstrumentID |

### 5.2 Referenced By (other objects point to this)

No other tables reference this history table directly. History tables are queried via `FOR SYSTEM_TIME` clauses on the parent table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RecurringInvestmentBlackListInstrumentID (history table)
└── RecurringInvestment.BlackListInstrumentID (parent, system-versioned)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListInstrumentID | Table | Parent table - this history table receives rows automatically via SYSTEM_VERSIONING |

### 6.2 Objects That Depend On This

No objects depend directly on this history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| ix_RecurringInvestmentBlackListInstrumentID | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | PAGE | Active |

### 7.2 Constraints

No primary key constraints. History tables do not enforce PK uniqueness because they may contain multiple historical versions of the same logical row (same InstrumentID with different validity periods).

### 7.3 Storage

- DATA_COMPRESSION = PAGE on the table and clustered index for storage efficiency.
- The clustered index on (ValidTo, ValidFrom) is optimized for temporal query patterns, enabling efficient point-in-time lookups.

---

## 8. Sample Queries

### 8.1 View full history of an instrument's blacklist status
```sql
SELECT InstrumentID, Trace, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListInstrumentID]
FOR SYSTEM_TIME ALL
WHERE InstrumentID = @InstrumentID
ORDER BY ValidFrom
```

### 8.2 Find which instruments were blacklisted at a specific point in time
```sql
SELECT InstrumentID, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListInstrumentID]
FOR SYSTEM_TIME AS OF '2025-06-01'
ORDER BY InstrumentID
```

### 8.3 Query history table directly for un-blacklisted instruments
```sql
SELECT InstrumentID, Trace, ValidFrom, ValidTo
FROM [History].[RecurringInvestmentBlackListInstrumentID] WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources specific to this history table. See parent table documentation for business context.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: History.RecurringInvestmentBlackListInstrumentID | Type: Table | Source: RecurringInvestment/History/Tables/History.RecurringInvestmentBlackListInstrumentID.sql*
