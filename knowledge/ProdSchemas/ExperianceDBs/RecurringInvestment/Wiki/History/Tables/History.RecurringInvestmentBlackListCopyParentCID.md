# History.RecurringInvestmentBlackListCopyParentCID

> System-versioned temporal history table storing previous row versions from RecurringInvestment.BlackListCopyParentCID - tracks when traders were added to or removed from the copy parent blacklist.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Parent Table** | RecurringInvestment.BlackListCopyParentCID |
| **Partition** | No |
| **Indexes** | 1 clustered on (ValidTo, ValidFrom) |
| **Data Compression** | PAGE |

---

## 1. Business Meaning

This is the SQL Server system-versioned (temporal) history table for `RecurringInvestment.BlackListCopyParentCID`. It automatically stores previous versions of rows from the parent table whenever a row is updated or deleted. Each row represents a past state of a copy parent (trader) blacklist entry, bounded by the ValidFrom and ValidTo period columns.

When a trader is removed from the copy parent blacklist (DELETE on the parent), or when an existing entry is modified (UPDATE on the parent), SQL Server automatically moves the previous version of the row into this history table. The ValidFrom/ValidTo columns define the exact time window during which that row version was "current" in the parent table.

This table is never written to directly by application code. All inserts are handled automatically by the SQL Server temporal table mechanism. It enables point-in-time queries using `FOR SYSTEM_TIME` syntax, providing a full audit trail of which traders were blocked from being copied via recurring investment and when those restrictions were active.

---

## 2. Business Logic

No independent business logic. This table is a passive recipient of historical row versions managed entirely by SQL Server's SYSTEM_VERSIONING mechanism. The business meaning mirrors the parent table: each row represents a trader (CopyParentCID) who was on the copy parent blacklist during the period defined by ValidFrom to ValidTo.

Rows appear here in two scenarios:
- **UPDATE on parent**: The pre-update version of the row is inserted here with ValidTo set to the update timestamp.
- **DELETE on parent**: The deleted row is inserted here with ValidTo set to the deletion timestamp.

---

## 3. Data Overview

Rows in this table represent traders who were previously blacklisted from being copied via recurring investment but have since been removed, or previous versions of entries that were modified.

| CopyParentCID | ValidFrom | ValidTo | Meaning |
|---------------|-----------|---------|---------|
| 2988943 | 2025-05-29 12:00:00 | 2025-09-17 10:00:00 | Trader 2988943 was on the copy parent blacklist during this window. Removed or replaced at ValidTo. |
| 4657429 | 2025-05-29 12:00:00 | 2025-08-01 08:00:00 | Trader 4657429 was blocked from being a copy target during this period. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | CopyParentCID | bigint | NO | - | CID of the trader who was blocked from being copied. Same as parent table RecurringInvestment.BlackListCopyParentCID.CopyParentCID. Identifies the trader who was on the blacklist during the ValidFrom-ValidTo period. |
| 2 | Trace | nvarchar(733) | NO | - | Audit trail information. Same as parent table RecurringInvestment.BlackListCopyParentCID.Trace, but stored as nvarchar(733) NOT computed (unlike the parent's computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current. |
| 3 | ValidFrom | datetime2(7) | NO | - | Period start - the point in time when this row version became the "current" version in the parent table. |
| 4 | ValidTo | datetime2(7) | NO | - | Period end - the point in time when this row version was superseded by an update or deleted from the parent table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | RecurringInvestment.BlackListCopyParentCID | System-versioned history | System-versioned history for RecurringInvestment.BlackListCopyParentCID |

### 5.2 Referenced By (other objects point to this)

No other tables reference this history table directly. History tables are queried via `FOR SYSTEM_TIME` clauses on the parent table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RecurringInvestmentBlackListCopyParentCID (history table)
└── RecurringInvestment.BlackListCopyParentCID (parent, system-versioned)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListCopyParentCID | Table | Parent table - this history table receives rows automatically via SYSTEM_VERSIONING |

### 6.2 Objects That Depend On This

No objects depend directly on this history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| ix_RecurringInvestmentBlackListCopyParentCID | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | PAGE | Active |

### 7.2 Constraints

No primary key constraints. History tables do not enforce PK uniqueness because they may contain multiple historical versions of the same logical row (same CopyParentCID with different validity periods).

### 7.3 Storage

- DATA_COMPRESSION = PAGE on the table and clustered index for storage efficiency.
- The clustered index on (ValidTo, ValidFrom) is optimized for temporal query patterns, enabling efficient point-in-time lookups.

---

## 8. Sample Queries

### 8.1 View full history of a trader's blacklist status
```sql
SELECT CopyParentCID, Trace, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListCopyParentCID]
FOR SYSTEM_TIME ALL
WHERE CopyParentCID = @CID
ORDER BY ValidFrom
```

### 8.2 Find which traders were blacklisted at a specific point in time
```sql
SELECT CopyParentCID, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListCopyParentCID]
FOR SYSTEM_TIME AS OF '2025-06-01'
ORDER BY CopyParentCID
```

### 8.3 Query history table directly for removed entries
```sql
SELECT CopyParentCID, Trace, ValidFrom, ValidTo
FROM [History].[RecurringInvestmentBlackListCopyParentCID] WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources specific to this history table. See parent table documentation for business context.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: History.RecurringInvestmentBlackListCopyParentCID | Type: Table | Source: RecurringInvestment/History/Tables/History.RecurringInvestmentBlackListCopyParentCID.sql*
