# History.Address

> Temporal history table for Customer.Address, capturing all changes to customer mailing addresses over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (GCID, BeginTime) - customer-centric temporal access pattern |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on GCID ASC, BeginTime ASC, PAGE compressed, FILLFACTOR 90) |

---

## 1. Business Meaning

History.Address is the SQL Server system-versioning history table for `Customer.Address`, which stores the current mailing address for each eToro customer. Every time a customer updates their address, the previous version is moved here automatically by the temporal mechanism, providing a full address change audit trail.

This history table answers "what was this customer's address on a specific date?" - essential for regulatory compliance (AML/KYC requirements often require point-in-time address records), dispute resolution, and fraud investigation. The address data covers street, city, zip code, building number, country, and optional geographic sub-division (region, sub-region).

**Clustering design**: Unlike most temporal history tables (which cluster on SysEndTime first), this table clusters on `(GCID, BeginTime)` - prioritizing customer-centric queries ("all address versions for customer X over time") over point-in-time system queries. This reflects the primary operational use case: looking up address history for a specific customer.

With only 56 rows for 20 distinct customers since April 2023, `Customer.Address` is an infrequently-changing table - customers rarely update their address. The short BeginTime-EndTime spans (seconds or minutes) visible in recent data reflect users editing their address in quick succession during onboarding or profile update flows in the query/test environment.

No stored procedures directly reference this history table - it is accessed exclusively via `FOR SYSTEM_TIME` temporal queries on the source `Customer.Address` table.

---

## 2. Business Logic

### 2.1 Slowly-Changing Customer Address

**What**: Stores previous address versions when a customer updates their address in their profile.

**Columns/Parameters Involved**: `GCID`, `AddressTypeID`, `CountryID`, `Address`, `City`, `Zip`, `BeginTime`, `EndTime`

**Rules**:
- Source PK is (GCID, AddressTypeID) - one active address per customer per address type
- Only AddressTypeID=1 (Mailing) exists in data - no other address types currently in use
- When a customer updates their address (any field), the previous row moves here with EndTime = timestamp of the update
- BeginTime/EndTime are the temporal system-time period columns (GENERATED ALWAYS AS ROW START/END in source)
- Point-in-time reconstruction uses: `SELECT FROM Customer.Address FOR SYSTEM_TIME AS OF @date`

### 2.2 Geographic Hierarchy

**What**: Addresses can optionally include sub-national geographic units for regions that require them.

**Columns/Parameters Involved**: `CountryID`, `RegionID`, `SubRegionID`

**Rules**:
- CountryID is always required (NOT NULL in source FK to Dictionary.Country)
- RegionID is optional - maps to Dictionary.RegionByIP (the regional subdivision, e.g., US state)
- SubRegionID is optional - maps to Dictionary.SubRegion (finer subdivision below region)
- RegionID/SubRegionID are populated for countries with mandatory sub-national address validation (e.g., US, Australia, Canada)

---

## 3. Data Overview

56 rows for 20 distinct customers, April 2023 to March 2026. All records are AddressTypeID=1 (Mailing). Short BeginTime-EndTime spans (seconds to minutes in test/dev data) indicate rapid successive edits.

| GCID | AddressTypeID | CountryID | City | BeginTime | EndTime | Meaning |
|---|---|---|---|---|---|---|
| 27998087 | 1 | 216 | Kyiv | 2026-03-18 09:02:16 | 2026-03-18 09:02:32 | Previous version of customer's mailing address in Kyiv (CountryID=216 = Ukraine). Active for 16 seconds before being updated again - rapid edit during profile update. |
| 27978609 | 1 | 102 | jhgfgh | 2026-03-16 13:46:09 | 2026-03-17 10:00:55 | Address with SubRegionID=38, RegionID=795 set. CountryID=102 requires regional fields. Active ~20 hours before another update. |
| 27933996 | 1 | 102 | jhg | 2026-03-11 10:12:30 | 2026-03-11 10:17:21 | Same country with sub-region. Active ~5 minutes - test data showing rapid edit pattern. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID - the eToro customer account identifier. Part of the clustered index (first column). In the source table, this is the first PK column. References Customer.CustomerStatic (implicit). |
| 2 | AddressTypeID | int | NO | - | VERIFIED | Type of address stored. FK to Dictionary.AddressType in the source. Currently only AddressTypeID=1 (Mailing) is used. The schema supports multiple address types per customer. |
| 3 | CountryID | int | NO | - | VERIFIED | Country of the address. FK to Dictionary.Country(CountryID) in the source. Always required. CountryID=216=Ukraine, CountryID=102 and CountryID=140 also visible in data. |
| 4 | Address | nvarchar(255) | YES | - | VERIFIED | Street address (free text). NULL allowed. In test/dev data, values like "Street" or "plkojihugyf" appear - test entries. In production: customer's actual street address as entered during registration or profile update. |
| 5 | City | nvarchar(50) | YES | - | VERIFIED | City name (free text). NULL allowed. Max 50 characters. |
| 6 | Zip | nvarchar(50) | YES | - | VERIFIED | Postal/ZIP code (free text, not validated). NULL allowed. Max 50 characters - accommodates international postal code formats. |
| 7 | BuildingNumber | nvarchar(30) | YES | - | VERIFIED | Building or apartment number, separate from the street address line. NULL allowed. Used in countries where building number is a separate field (e.g., many European countries). |
| 8 | SubRegionID | int | YES | - | VERIFIED | Optional sub-national region below the main region (e.g., county, district). FK to Dictionary.SubRegion(SubRegionID) in source. NULL for countries without sub-region requirements. |
| 9 | BeginTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this address version became active in Customer.Address (temporal system start). Clustered index second column - enables efficient "all addresses for customer X after date Y" queries. Named BeginTime to match the temporal period name in the source DDL. |
| 10 | EndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this address version was superseded in Customer.Address (temporal system end). Named EndTime to match the source temporal period. For point-in-time queries, use FOR SYSTEM_TIME AS OF on the source table. |
| 11 | RegionID | int | YES | - | VERIFIED | Optional region/state identifier (e.g., US state, Australian state). FK to Dictionary.RegionByIP(RegionByIP_ID) in source - reuses the IP-geolocation region table. NULL for countries without mandatory regional address fields. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Temporal history tables carry no FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.Address | (temporal system) | Source Table | SQL Server SYSTEM_VERSIONING writes superseded row versions here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Address (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. Temporal history tables have no FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.Address | Table | Source - SQL Server temporal moves superseded rows here. FOR SYSTEM_TIME queries implicitly access this table. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Idx_History_Address | CLUSTERED (PAGE compressed, FILLFACTOR 90) | GCID ASC, BeginTime ASC | - | - | Active |

**Note**: Unlike the standard temporal history pattern (SysEndTime, SysStartTime), this table clusters on (GCID, BeginTime). This prioritizes customer-centric lookups ("all address history for GCID X") over system-generated point-in-time queries. The trade-off: FOR SYSTEM_TIME AS OF queries will require a full scan or non-clustered index seek rather than the optimized SysEndTime-first pattern.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | Temporal history tables have no PK or FK constraints by SQL Server design. |

---

## 8. Sample Queries

### 8.1 Full address history for a specific customer
```sql
SELECT
    GCID,
    AddressTypeID,
    CountryID,
    [Address],
    City,
    Zip,
    BuildingNumber,
    SubRegionID,
    RegionID,
    BeginTime AS ValidFrom,
    EndTime   AS ValidTo
FROM History.Address WITH (NOLOCK)
WHERE GCID = 27998087
ORDER BY BeginTime ASC;
```

### 8.2 Point-in-time address lookup (preferred - uses temporal syntax on source)
```sql
SELECT
    GCID,
    AddressTypeID,
    CountryID,
    [Address],
    City,
    Zip,
    BeginTime,
    EndTime
FROM Customer.Address
FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00.000'
WHERE GCID = @CustomerGCID;
```

### 8.3 Customers with multiple address changes (change frequency audit)
```sql
SELECT
    GCID,
    COUNT(*) AS ChangeCount,
    MIN(BeginTime) AS FirstAddress,
    MAX(BeginTime) AS LatestChange
FROM History.Address WITH (NOLOCK)
GROUP BY GCID
HAVING COUNT(*) > 3
ORDER BY ChangeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.9/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 11 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Address | Type: Table | Source: etoro/etoro/History/Tables/History.Address.sql*
