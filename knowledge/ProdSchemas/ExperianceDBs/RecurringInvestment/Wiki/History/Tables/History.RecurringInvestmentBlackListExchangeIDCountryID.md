# History.RecurringInvestmentBlackListExchangeIDCountryID

> System-versioned temporal history table storing previous row versions from RecurringInvestment.BlackListExchangeIDCountryID - tracks changes to exchange+country blacklist entries (parent currently empty).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Parent Table** | RecurringInvestment.BlackListExchangeIDCountryID |
| **Partition** | No |
| **Indexes** | 1 clustered on (ValidTo, ValidFrom) |
| **Data Compression** | PAGE |

---

## 1. Business Meaning

This is the SQL Server system-versioned (temporal) history table for `RecurringInvestment.BlackListExchangeIDCountryID`. It automatically stores previous versions of rows from the parent table whenever a row is updated or deleted. Each row represents a past state of an exchange+country blacklist entry, bounded by the ValidFrom and ValidTo period columns.

When an exchange+country blacklist entry is removed (DELETE on the parent), or when an existing entry is modified (UPDATE on the parent), SQL Server automatically moves the previous version of the row into this history table. The ValidFrom/ValidTo columns define the exact time window during which that row version was "current" in the parent table.

The parent table is currently empty (0 rows), meaning this history table would only contain data if entries were previously added and then removed. The infrastructure exists for future regulatory needs where specific exchange+country combinations may need to be blocked from recurring investment plans.

This table is never written to directly by application code. All inserts are handled automatically by the SQL Server temporal table mechanism.

---

## 2. Business Logic

No independent business logic. This table is a passive recipient of historical row versions managed entirely by SQL Server's SYSTEM_VERSIONING mechanism. The business meaning mirrors the parent table: each row represents an exchange+country combination (ExchangeID + CountryID) that was on the blacklist during the period defined by ValidFrom to ValidTo.

Rows appear here in two scenarios:
- **UPDATE on parent**: The pre-update version of the row is inserted here with ValidTo set to the update timestamp.
- **DELETE on parent**: The deleted row is inserted here with ValidTo set to the deletion timestamp.

Since the parent table is currently empty, this history table may contain entries for exchange+country combinations that were temporarily blacklisted during testing or regulatory evaluation and subsequently removed.

---

## 3. Data Overview

The parent table is currently empty. This history table would contain rows only if exchange+country blacklist entries were added and then removed at some point. Any rows present represent past restrictions that are no longer in effect.

| ExchangeID | CountryID | ValidFrom | ValidTo | Meaning |
|------------|-----------|-----------|---------|---------|
| (example) | (example) | - | - | Exchange+country combination that was previously blacklisted and then removed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | ExchangeID | int | NO | - | ID of the exchange/market. Same as parent table RecurringInvestment.BlackListExchangeIDCountryID.ExchangeID. Instruments traded on this exchange were blocked for the specified country during the validity period. |
| 2 | CountryID | int | NO | - | Country ID of the user. Same as parent table RecurringInvestment.BlackListExchangeIDCountryID.CountryID. Users from this country were blocked from creating recurring investment plans for instruments on the specified exchange during the validity period. |
| 3 | Trace | nvarchar(733) | NO | - | Audit trail information. Same as parent table RecurringInvestment.BlackListExchangeIDCountryID.Trace, but stored as nvarchar(733) NOT computed (unlike the parent's computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current. |
| 4 | ValidFrom | datetime2(7) | NO | - | Period start - the point in time when this row version became the "current" version in the parent table. |
| 5 | ValidTo | datetime2(7) | NO | - | Period end - the point in time when this row version was superseded by an update or deleted from the parent table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | RecurringInvestment.BlackListExchangeIDCountryID | System-versioned history | System-versioned history for RecurringInvestment.BlackListExchangeIDCountryID |

### 5.2 Referenced By (other objects point to this)

No other tables reference this history table directly. History tables are queried via `FOR SYSTEM_TIME` clauses on the parent table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RecurringInvestmentBlackListExchangeIDCountryID (history table)
└── RecurringInvestment.BlackListExchangeIDCountryID (parent, system-versioned)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListExchangeIDCountryID | Table | Parent table - this history table receives rows automatically via SYSTEM_VERSIONING |

### 6.2 Objects That Depend On This

No objects depend directly on this history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| ix_RecurringInvestmentBlackListExchangeIDCountryID | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | PAGE | Active |

### 7.2 Constraints

No primary key constraints. History tables do not enforce PK uniqueness because they may contain multiple historical versions of the same logical row (same ExchangeID+CountryID with different validity periods).

### 7.3 Storage

- DATA_COMPRESSION = PAGE on the table and clustered index for storage efficiency.
- The clustered index on (ValidTo, ValidFrom) is optimized for temporal query patterns, enabling efficient point-in-time lookups.

---

## 8. Sample Queries

### 8.1 View full history of an exchange+country restriction
```sql
SELECT ExchangeID, CountryID, Trace, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListExchangeIDCountryID]
FOR SYSTEM_TIME ALL
WHERE ExchangeID = @ExchangeID AND CountryID = @CountryID
ORDER BY ValidFrom
```

### 8.2 Find which exchange+country combos were blacklisted at a specific point in time
```sql
SELECT ExchangeID, CountryID, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListExchangeIDCountryID]
FOR SYSTEM_TIME AS OF '2025-06-01'
ORDER BY ExchangeID, CountryID
```

### 8.3 Query history table directly for any past entries
```sql
SELECT ExchangeID, CountryID, Trace, ValidFrom, ValidTo
FROM [History].[RecurringInvestmentBlackListExchangeIDCountryID] WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources specific to this history table. See parent table documentation for business context.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: History.RecurringInvestmentBlackListExchangeIDCountryID | Type: Table | Source: RecurringInvestment/History/Tables/History.RecurringInvestmentBlackListExchangeIDCountryID.sql*
