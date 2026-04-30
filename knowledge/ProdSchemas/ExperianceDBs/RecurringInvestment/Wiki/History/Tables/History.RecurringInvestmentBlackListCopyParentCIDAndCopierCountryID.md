# History.RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID

> System-versioned temporal history table storing previous row versions from RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID - tracks changes to trader+country blacklist combinations.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Parent Table** | RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID |
| **Partition** | No |
| **Indexes** | 1 clustered on (ValidTo, ValidFrom) |
| **Data Compression** | PAGE |

---

## 1. Business Meaning

This is the SQL Server system-versioned (temporal) history table for `RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID`. It automatically stores previous versions of rows from the parent table whenever a row is updated or deleted. Each row represents a past state of a trader+country blacklist combination, bounded by the ValidFrom and ValidTo period columns.

When a trader+country blacklist entry is removed (DELETE on the parent), or when an existing entry is modified (UPDATE on the parent), SQL Server automatically moves the previous version of the row into this history table. The ValidFrom/ValidTo columns define the exact time window during which that row version was "current" in the parent table.

This table is never written to directly by application code. All inserts are handled automatically by the SQL Server temporal table mechanism. It enables point-in-time queries using `FOR SYSTEM_TIME` syntax, providing a full audit trail of when specific trader+country copy restrictions were active. This granular combination tracking is important for compliance, as it shows exactly when a specific trader was blocked for copiers from a specific country.

---

## 2. Business Logic

No independent business logic. This table is a passive recipient of historical row versions managed entirely by SQL Server's SYSTEM_VERSIONING mechanism. The business meaning mirrors the parent table: each row represents a trader (CopyParentCID) who was blocked from being copied by users in a specific country (CopierCountryID) during the period defined by ValidFrom to ValidTo.

Rows appear here in two scenarios:
- **UPDATE on parent**: The pre-update version of the row is inserted here with ValidTo set to the update timestamp.
- **DELETE on parent**: The deleted row is inserted here with ValidTo set to the deletion timestamp.

---

## 3. Data Overview

Rows in this table represent trader+country blacklist combinations that were previously active but have since been removed or modified.

| CopyParentCID | CopierCountryID | ValidFrom | ValidTo | Meaning |
|---------------|-----------------|-----------|---------|---------|
| 5351549 | 19 | 2025-03-01 | 2025-08-15 | Trader 5351549 was blocked for copiers from country 19 during this window. |
| 6215327 | 218 | 2025-04-10 | 2025-11-20 | Trader 6215327 was blocked for country 218 during this period. Removed at ValidTo. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | CopyParentCID | bigint | NO | - | CID of the trader who was restricted from being copied. Same as parent table RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID.CopyParentCID. Identifies the trader in the restriction pair. |
| 2 | CopierCountryID | int | NO | - | Country ID of the copier. Same as parent table RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID.CopierCountryID. Users from this country were blocked from copying the specified trader during the validity period. |
| 3 | Trace | nvarchar(733) | NO | - | Audit trail information. Same as parent table RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID.Trace, but stored as nvarchar(733) NOT computed (unlike the parent's computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current. |
| 4 | ValidFrom | datetime2(7) | NO | - | Period start - the point in time when this row version became the "current" version in the parent table. |
| 5 | ValidTo | datetime2(7) | NO | - | Period end - the point in time when this row version was superseded by an update or deleted from the parent table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID | System-versioned history | System-versioned history for RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID |

### 5.2 Referenced By (other objects point to this)

No other tables reference this history table directly. History tables are queried via `FOR SYSTEM_TIME` clauses on the parent table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID (history table)
└── RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID (parent, system-versioned)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID | Table | Parent table - this history table receives rows automatically via SYSTEM_VERSIONING |

### 6.2 Objects That Depend On This

No objects depend directly on this history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| ix_RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | PAGE | Active |

### 7.2 Constraints

No primary key constraints. History tables do not enforce PK uniqueness because they may contain multiple historical versions of the same logical row (same CopyParentCID+CopierCountryID with different validity periods).

### 7.3 Storage

- DATA_COMPRESSION = PAGE on the table and clustered index for storage efficiency.
- The clustered index on (ValidTo, ValidFrom) is optimized for temporal query patterns, enabling efficient point-in-time lookups.

---

## 8. Sample Queries

### 8.1 View full history of a trader+country restriction
```sql
SELECT CopyParentCID, CopierCountryID, Trace, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListCopyParentCIDAndCopierCountryID]
FOR SYSTEM_TIME ALL
WHERE CopyParentCID = @CID AND CopierCountryID = @CountryID
ORDER BY ValidFrom
```

### 8.2 Find which trader+country combos were blacklisted at a specific point in time
```sql
SELECT CopyParentCID, CopierCountryID, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListCopyParentCIDAndCopierCountryID]
FOR SYSTEM_TIME AS OF '2025-06-01'
ORDER BY CopyParentCID, CopierCountryID
```

### 8.3 Query history table directly for removed entries
```sql
SELECT CopyParentCID, CopierCountryID, Trace, ValidFrom, ValidTo
FROM [History].[RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID] WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources specific to this history table. See parent table documentation for business context.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: History.RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID | Type: Table | Source: RecurringInvestment/History/Tables/History.RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID.sql*
