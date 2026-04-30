# History.RecurringInvestmentBlackListInstrumentIDCountryID

> System-versioned temporal history table storing previous row versions from RecurringInvestment.BlackListInstrumentIDCountryID - tracks changes to instrument+country blacklist entries.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Parent Table** | RecurringInvestment.BlackListInstrumentIDCountryID |
| **Partition** | No |
| **Indexes** | 1 clustered on (ValidTo, ValidFrom) |
| **Data Compression** | PAGE |

---

## 1. Business Meaning

This is the SQL Server system-versioned (temporal) history table for `RecurringInvestment.BlackListInstrumentIDCountryID`. It automatically stores previous versions of rows from the parent table whenever a row is updated or deleted. Each row represents a past state of an instrument+country blacklist entry, bounded by the ValidFrom and ValidTo period columns.

When an instrument+country restriction is removed (DELETE on the parent), or when an existing entry is modified (UPDATE on the parent), SQL Server automatically moves the previous version of the row into this history table. The ValidFrom/ValidTo columns define the exact time window during which that row version was "current" in the parent table.

The parent table is the largest blacklist table with 8,127 entries, reflecting extensive per-country instrument restrictions. This history table captures the full audit trail of regulatory changes - when instruments were restricted or unrestricted for specific countries, which is critical for compliance and for investigating past eligibility decisions.

This table is never written to directly by application code. All inserts are handled automatically by the SQL Server temporal table mechanism.

---

## 2. Business Logic

No independent business logic. This table is a passive recipient of historical row versions managed entirely by SQL Server's SYSTEM_VERSIONING mechanism. The business meaning mirrors the parent table: each row represents an instrument (InstrumentID) that was blocked for users in a specific country (CountryID) during the period defined by ValidFrom to ValidTo.

Rows appear here in two scenarios:
- **UPDATE on parent**: The pre-update version of the row is inserted here with ValidTo set to the update timestamp. This captures changes to the UpdateDate column or other modifications.
- **DELETE on parent**: The deleted row is inserted here with ValidTo set to the deletion timestamp (instrument un-blacklisted for that country).

---

## 3. Data Overview

Rows in this table represent instrument+country blacklist entries that were previously active but have since been removed or modified.

| InstrumentID | CountryID | UpdateDate | ValidFrom | ValidTo | Meaning |
|--------------|-----------|------------|-----------|---------|---------|
| 9031 | 188 | 2024-06-15 | 2024-06-15 12:00:00 | 2024-09-03 10:00:00 | Instrument 9031 was previously restricted for country 188 with an earlier UpdateDate. The entry was later modified (new UpdateDate), moving this version to history. |
| 3050 | 96 | 2024-03-01 | 2024-03-01 08:00:00 | 2025-01-15 14:00:00 | Instrument 3050 was blacklisted for country 96 during this period. Later removed from the blacklist, indicating a regulatory change. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | InstrumentID | int | NO | - | ID of the instrument that was restricted. Same as parent table RecurringInvestment.BlackListInstrumentIDCountryID.InstrumentID. References the external instrument system. |
| 2 | CountryID | int | NO | - | Country ID of the user. Same as parent table RecurringInvestment.BlackListInstrumentIDCountryID.CountryID. Users from this country were blocked from creating recurring investment plans for this instrument during the validity period. |
| 3 | UpdateDate | datetime | NO | - | When this restriction was last added or modified, captured at the time this row version was current. Same as parent table RecurringInvestment.BlackListInstrumentIDCountryID.UpdateDate. Used for compliance audit trails. |
| 4 | Trace | nvarchar(733) | NO | - | Audit trail information. Same as parent table RecurringInvestment.BlackListInstrumentIDCountryID.Trace, but stored as nvarchar(733) NOT computed (unlike the parent's computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current. |
| 5 | ValidFrom | datetime2(7) | NO | - | Period start - the point in time when this row version became the "current" version in the parent table. |
| 6 | ValidTo | datetime2(7) | NO | - | Period end - the point in time when this row version was superseded by an update or deleted from the parent table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | RecurringInvestment.BlackListInstrumentIDCountryID | System-versioned history | System-versioned history for RecurringInvestment.BlackListInstrumentIDCountryID |

### 5.2 Referenced By (other objects point to this)

No other tables reference this history table directly. History tables are queried via `FOR SYSTEM_TIME` clauses on the parent table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RecurringInvestmentBlackListInstrumentIDCountryID (history table)
└── RecurringInvestment.BlackListInstrumentIDCountryID (parent, system-versioned)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListInstrumentIDCountryID | Table | Parent table - this history table receives rows automatically via SYSTEM_VERSIONING |

### 6.2 Objects That Depend On This

No objects depend directly on this history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| ix_RecurringInvestmentBlackListInstrumentIDCountryID | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | PAGE | Active |

### 7.2 Constraints

No primary key constraints. History tables do not enforce PK uniqueness because they may contain multiple historical versions of the same logical row (same InstrumentID+CountryID with different validity periods).

### 7.3 Storage

- DATA_COMPRESSION = PAGE on the table and clustered index for storage efficiency.
- The clustered index on (ValidTo, ValidFrom) is optimized for temporal query patterns, enabling efficient point-in-time lookups.

---

## 8. Sample Queries

### 8.1 View full history of an instrument+country restriction
```sql
SELECT InstrumentID, CountryID, UpdateDate, Trace, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListInstrumentIDCountryID]
FOR SYSTEM_TIME ALL
WHERE InstrumentID = @InstrumentID AND CountryID = @CountryID
ORDER BY ValidFrom
```

### 8.2 Find which instrument+country combos were blacklisted at a specific point in time
```sql
SELECT InstrumentID, CountryID, UpdateDate, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListInstrumentIDCountryID]
FOR SYSTEM_TIME AS OF '2025-06-01'
WHERE CountryID = @CountryID
ORDER BY InstrumentID
```

### 8.3 Query history table directly for removed restrictions
```sql
SELECT InstrumentID, CountryID, UpdateDate, Trace, ValidFrom, ValidTo
FROM [History].[RecurringInvestmentBlackListInstrumentIDCountryID] WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources specific to this history table. See parent table documentation for business context.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: History.RecurringInvestmentBlackListInstrumentIDCountryID | Type: Table | Source: RecurringInvestment/History/Tables/History.RecurringInvestmentBlackListInstrumentIDCountryID.sql*
