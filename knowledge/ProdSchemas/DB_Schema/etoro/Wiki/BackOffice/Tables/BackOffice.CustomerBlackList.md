# BackOffice.CustomerBlackList

> Data-value blacklist registry used to block registrations and deposits by specific usernames, email addresses, original CIDs, credit card numbers, and PayPal accounts. Prevents banned accounts from re-registering or funding under new identities.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | BlackListID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 2 active (1 clustered PK + 1 unique NC on (BlockedDataTypeID, Data)) |

---

## 1. Business Meaning

BackOffice.CustomerBlackList is a platform-level block registry keyed on data values (not customer IDs). When a customer is banned, their identifying data - email address, username, credit card number, PayPal email, and original CID - can be added here to prevent re-registration or re-funding under a new identity.

The table is intentionally a data-value store, not a CID list: someone who was banned and tries to register again with the same email will be caught before a new CID is even created, because the email value appears in the blacklist. This design enables pre-registration blocking at the boundary.

1,769 entries across 5 data types as of 2026-03-17. All Data values are stored in lowercase (enforced by CustomerBlackListAdd which calls LOWER(@Data) before insert).

---

## 2. Business Logic

### 2.1 Data-Value Blocking by Type

**What**: Entries are classified by what type of data is being blocked, enabling type-specific matching at registration and funding.

**Columns Involved**: `BlockedDataTypeID`, `Data`

**Rules**:
- BlockedDataTypeID=1 (User Name): 529 entries - blocked display names / usernames.
- BlockedDataTypeID=2 (Email): 475 entries - blocked email addresses. Prevents re-registration with the same email.
- BlockedDataTypeID=3 (OriginalCID): 430 entries - original CID values of banned accounts. Stored as varchar to match the CID string representation. Prevents detection via linked account CID references.
- BlockedDataTypeID=4 (Credit Card): 261 entries - blocked credit card numbers. Prevents deposit with the same card on a new account.
- BlockedDataTypeID=5 (Pay Pal Email): 74 entries - blocked PayPal account emails. Prevents PayPal deposits from banned accounts.
- Data is ALWAYS stored lowercase: CustomerBlackListAdd calls LOWER(@Data) on insert. Lookups must use LOWER() or case-insensitive collation.
- The unique NC index on (BlockedDataTypeID, Data) enforces one entry per type/value combination - no duplicates.

### 2.2 Lookup Pattern

**What**: Application code (not stored procedures) checks the blacklist at registration and deposit entry points.

**Rules**:
- Pattern: `WHERE BlockedDataTypeID = @type AND Data = LOWER(@value)`
- Only CustomerBlackListAdd procedure exists in the SSDT repo - reads are done directly by application code or middleware.
- The unique index on (BlockedDataTypeID, Data) makes these lookups efficient.

---

## 3. Data Overview

| BlockedDataTypeID | Type Name | Count | Usage |
|-----------------|-----------|-------|-------|
| 1 | User Name | 529 | Blocked display names |
| 2 | Email | 475 | Blocked email addresses |
| 3 | OriginalCID | 430 | Banned account CIDs |
| 4 | Credit Card | 261 | Blocked card numbers |
| 5 | Pay Pal Email | 74 | Blocked PayPal accounts |
| **Total** | | **1,769** | BlackListID range: 1-2205 (gaps from deletions) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BlackListID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing row identifier. Clustered PK. NOT FOR REPLICATION flag set. Gaps in the range (1-2205 with 1,769 rows) indicate historical deletions. |
| 2 | BlockedDataTypeID | int | NO | - | VERIFIED | Type of data being blocked. FK to Dictionary.BlockedDataType (WITH CHECK). Values: 1=User Name, 2=Email, 3=OriginalCID, 4=Credit Card, 5=Pay Pal Email. |
| 3 | Data | varchar(250) | NO | - | VERIFIED | The blocked data value. Always stored in lowercase (CustomerBlackListAdd applies LOWER() on insert). Examples: email address, username, credit card number, PayPal email, CID as string. The unique NC index on (BlockedDataTypeID, Data) prevents duplicate entries per type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BlockedDataTypeID | Dictionary.BlockedDataType | FK (WITH CHECK) | Classifies the type of blocked data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerBlackListAdd | (BlockedDataTypeID, Data) | WRITER | Adds entries to the blacklist |
| Application code | (BlockedDataTypeID, Data) | READER | Registration and deposit blocking checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerBlackList (table)
- FK target: Dictionary.BlockedDataType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.BlockedDataType | Table | FK constraint on BlockedDataTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerBlackListAdd | Procedure | WRITER - adds blocked data entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BCBL | CLUSTERED PK | BlackListID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BCBL_DATA | UNIQUE NC | BlockedDataTypeID ASC, Data ASC | - | - | Active (FILLFACTOR=90, ON [MAIN], ANSI_PADDING ON) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BCBL | PK | BlackListID uniqueness |
| BCBL_DATA | UNIQUE | One entry per (BlockedDataTypeID, Data) combination |
| FK_DBDT_BCBL | FK (WITH CHECK) | BlockedDataTypeID -> Dictionary.BlockedDataType |

---

## 8. Sample Queries

### 8.1 Check if a value is blacklisted
```sql
SELECT BlackListID, BlockedDataTypeID
FROM BackOffice.CustomerBlackList WITH (NOLOCK)
WHERE BlockedDataTypeID = 2       -- Email
  AND Data = LOWER('user@example.com')
```

### 8.2 Get all blocked entries by type
```sql
SELECT
    bdt.Name AS BlockedType,
    bl.Data,
    bl.BlackListID
FROM BackOffice.CustomerBlackList bl WITH (NOLOCK)
JOIN Dictionary.BlockedDataType bdt WITH (NOLOCK)
    ON bdt.BlockedDataTypeID = bl.BlockedDataTypeID
WHERE bl.BlockedDataTypeID = 2  -- Email
ORDER BY bl.BlackListID
```

### 8.3 Count entries by type
```sql
SELECT
    bdt.Name AS BlockedType,
    COUNT(*) AS EntryCount
FROM BackOffice.CustomerBlackList bl WITH (NOLOCK)
JOIN Dictionary.BlockedDataType bdt WITH (NOLOCK)
    ON bdt.BlockedDataTypeID = bl.BlockedDataTypeID
GROUP BY bdt.Name
ORDER BY EntryCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.2/10, Relationships: 8.8/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerBlackList | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerBlackList.sql*
