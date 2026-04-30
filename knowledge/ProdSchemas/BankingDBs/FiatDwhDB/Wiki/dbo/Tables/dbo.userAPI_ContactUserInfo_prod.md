# dbo.userAPI_ContactUserInfo_prod

> Staging table holding customer country and citizenship data imported from the UserAPI for eligibility and compliance processing.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | GCID (BIGINT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

userAPI_ContactUserInfo_prod is a staging/import table that holds customer geographic information sourced from the UserAPI (eToro's central user profile system). Each row contains a customer's country of residence, citizenship country, place-of-birth country, and ISO code. This data is used by the fiat platform for regulatory eligibility determination and compliance checks.

This table exists because the fiat DWH needs customer geographic data from the UserAPI to support eligibility rules and reporting. Rather than querying the UserAPI in real-time, this table caches a snapshot of the relevant customer fields. The "_prod" suffix indicates this contains production data.

Data is likely populated by an ETL process or scheduled job that queries the UserAPI and inserts/updates records here.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a flat staging table.

---

## 3. Data Overview

N/A - staging table with PII-adjacent data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Primary key. Identifies the customer across all eToro platforms. |
| 2 | CountryID | nvarchar(50) | NO | - | NAME-INFERRED | Customer's country of residence identifier from UserAPI. Format may be numeric ID or ISO code depending on the source system. |
| 3 | CitizenshipCountryID | nvarchar(50) | NO | - | NAME-INFERRED | Customer's citizenship/nationality country identifier. Used for regulatory classification and eligibility determination. |
| 4 | POBCountryID | nvarchar(50) | NO | - | NAME-INFERRED | Customer's place-of-birth country identifier. Required for certain compliance and KYC checks. |
| 5 | IsoCode | nvarchar(50) | NO | - | NAME-INFERRED | ISO country code associated with the customer. Likely the ISO 3166-1 code for the country of residence. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No stored procedures in the dbo schema reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_userAPI_ContactUserInfo_prod | CLUSTERED | GCID ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK).

---

## 8. Sample Queries

### 8.1 Look up a customer's country info
```sql
SELECT * FROM dbo.userAPI_ContactUserInfo_prod WITH (NOLOCK) WHERE GCID = 12345;
```

### 8.2 Count customers by country
```sql
SELECT CountryID, COUNT(*) AS CustomerCount
FROM dbo.userAPI_ContactUserInfo_prod WITH (NOLOCK)
GROUP BY CountryID ORDER BY CustomerCount DESC;
```

### 8.3 Find customers with different residence and citizenship countries
```sql
SELECT GCID, CountryID, CitizenshipCountryID
FROM dbo.userAPI_ContactUserInfo_prod WITH (NOLOCK)
WHERE CountryID <> CitizenshipCountryID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.2/10 (Elements: 6/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.userAPI_ContactUserInfo_prod | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.userAPI_ContactUserInfo_prod.sql*
