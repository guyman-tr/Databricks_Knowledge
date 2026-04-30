# History.KYPAffiliateCountriesOfOperation

> SQL Server temporal history table storing all historical versions of the countries where KYP-verified affiliates operate.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateID + CountryID (composite - maps one affiliate to one country of operation across versions) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.KYPAffiliateCountriesOfOperation is the system-versioned temporal history table for KYP.AffiliateCountriesOfOperation. It captures every historical version of the affiliate-to-country mapping, recording which countries a KYP-verified affiliate has declared as part of their marketing operations. Each row represents one affiliate-country pair at a specific point in time.

This table is critical for compliance and regulatory oversight. Financial regulators require firms to know the geographic scope of their affiliates' activities. When an affiliate adds or removes a country of operation, the prior state is preserved here, enabling compliance teams to reconstruct the affiliate's declared geographic footprint at any historical date. This is essential for jurisdiction-specific licensing, sanctions screening, and market-access controls.

Data flows in automatically via SQL Server's temporal mechanism whenever rows in the base table KYP.AffiliateCountriesOfOperation are updated or deleted. With 150 historical rows, country-of-operation changes are relatively infrequent, occurring mainly during initial KYP setup or periodic compliance reviews.

---

## 2. Business Logic

### 2.1 Geographic Operation Tracking

**What**: Tracks changes to the declared countries of operation for KYP-verified affiliates over time.

**Columns/Parameters Involved**: `AffiliateID`, `CountryID`, `ValidFrom`, `ValidTo`

**Rules**:
- AffiliateID + CountryID together identify a specific affiliate-country relationship
- CountryID references the country dictionary table
- When an affiliate removes a country from their operations, the row moves to this history table
- When an affiliate adds a new country, any prior removal/re-addition cycle is captured here
- Used for compliance to understand the geographic scope of the affiliate's marketing activities

---

## 3. Data Overview

The table contains 150 historical rows representing superseded versions of affiliate-country mappings. The relatively low row count indicates that affiliates rarely change their declared countries of operation after initial KYP setup.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | The affiliate whose country of operation is recorded. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | CountryID | int | NO | - | CODE-BACKED | The country where the affiliate operates. References the country dictionary. |
| 3 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. |
| 4 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 5 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | KYP.AffiliateCountriesOfOperation | Temporal History | Stores historical versions of the base table |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The affiliate whose country of operation is recorded |
| CountryID | (Country dictionary) | Implicit FK | The country where the affiliate operates |

### 5.2 Referenced By (other objects point to this)

Accessed implicitly via temporal queries on KYP.AffiliateCountriesOfOperation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.KYPAffiliateCountriesOfOperation (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.AffiliateCountriesOfOperation | Table | SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_KYPAffiliateCountriesOfOperation | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View full country-of-operation history for an affiliate
```sql
SELECT AffiliateID, CountryID, ValidFrom, ValidTo
FROM KYP.AffiliateCountriesOfOperation FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY CountryID, ValidFrom
```

### 8.2 Check which countries an affiliate operated in at a specific date
```sql
SELECT AffiliateID, CountryID
FROM KYP.AffiliateCountriesOfOperation FOR SYSTEM_TIME AS OF '2025-06-01' WITH (NOLOCK)
WHERE AffiliateID = 12345
ORDER BY CountryID
```

### 8.3 Find recently removed country-of-operation records
```sql
SELECT AffiliateID, CountryID, ValidFrom, ValidTo
FROM History.KYPAffiliateCountriesOfOperation WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.KYPAffiliateCountriesOfOperation | Type: Table | Source: fiktivo/History/Tables/History.KYPAffiliateCountriesOfOperation.sql*
