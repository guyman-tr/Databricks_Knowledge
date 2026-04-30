# KYP.AffiliateCountriesOfOperation

> Junction table storing the countries where an affiliate entity operates, as declared during KYP (Know Your Partner) compliance verification.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID + CountryID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

KYP.AffiliateCountriesOfOperation records which countries an affiliate entity operates in. This is a regulatory requirement - compliance needs to know the geographic footprint of each partner to assess jurisdictional risk (high-risk countries, sanctioned territories) and ensure the affiliate's operations align with local regulations.

Without this table, the platform could not perform geographic risk assessment during KYP review. An affiliate operating in high-risk jurisdictions triggers enhanced due diligence procedures. The many-to-many relationship (one affiliate can operate in multiple countries) requires this junction table.

Rows are created by `KYP.CreateAffiliate` (INSERT from @CountriesOfOperationIDs table-valued parameter) during initial KYP setup. Updates are handled by `KYP.UpdateAffiliateData` using a MERGE statement that adds new countries, removes deselected ones, and preserves unchanged entries. `KYP.GetAffiliateData` reads the country list for display. The table uses temporal versioning (History.KYPAffiliateCountriesOfOperation) to maintain a full audit trail of country changes.

---

## 2. Business Logic

### 2.1 Country Selection Management via MERGE

**What**: Countries of operation are managed as a set - the application sends the complete list and MERGE synchronizes the table.

**Columns/Parameters Involved**: `AffiliateID`, `CountryID`

**Rules**:
- CreateAffiliate: bulk INSERT from @CountriesOfOperationIDs (initial setup with promoted countries)
- UpdateAffiliateData: MERGE pattern - NOT MATCHED BY TARGET = INSERT new countries, NOT MATCHED BY SOURCE (for same AffiliateID) = DELETE removed countries
- This ensures the table always reflects the current complete set of operating countries
- Average ~2.8 countries per affiliate (7,950 rows / 2,795 affiliates)

---

## 3. Data Overview

N/A - Junction table with only IDs. Sample would show (AffiliateID, CountryID) pairs.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | FK to KYP.Affiliate. Identifies the affiliate entity. Part of composite PK. |
| 2 | CountryID | int | NO | - | CODE-BACKED | FK to dbo.tblaff_Country. Identifies a country where the affiliate operates. Part of composite PK. One row per country per affiliate. |
| 3 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with session/connection details. Inherited pattern from KYP.Affiliate. |
| 4 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning row start. GENERATED ALWAYS AS ROW START. |
| 5 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning row end. History in History.KYPAffiliateCountriesOfOperation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | KYP.Affiliate | FK | Parent affiliate's KYP record |
| CountryID | dbo.tblaff_Country | FK | Country reference |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.CreateAffiliate | AffiliateID, CountryID | INSERT (WRITER) | Bulk inserts initial countries |
| KYP.GetAffiliateData | AffiliateID | SELECT (READER) | Reads country list for affiliate |
| KYP.UpdateAffiliateData | AffiliateID, CountryID | MERGE (WRITER) | Synchronizes countries via MERGE |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.AffiliateCountriesOfOperation (table)
├── KYP.Affiliate (table)
└── dbo.tblaff_Country (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | FK on AffiliateID |
| dbo.tblaff_Country | Table (cross-schema) | FK on CountryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.CreateAffiliate | SP | INSERT writer |
| KYP.GetAffiliateData | SP | SELECT reader |
| KYP.UpdateAffiliateData | SP | MERGE writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYP_AffiliateCountriesOfOperation | CLUSTERED PK | AffiliateID ASC, CountryID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_KYP_AffiliateCountriesOfOperation | PRIMARY KEY | Composite (AffiliateID, CountryID) - one row per country per affiliate |
| FK_KYP_AffiliateCountriesOfOperation_AffiliateID | FOREIGN KEY | AffiliateID -> KYP.Affiliate(AffiliateID) |
| FK_KYP_AffiliateCountriesOfOperation_CountryID | FOREIGN KEY | CountryID -> dbo.tblaff_Country(CountryID) |

Temporal: SYSTEM_VERSIONING ON with History.KYPAffiliateCountriesOfOperation.

---

## 8. Sample Queries

### 8.1 Get all operating countries for an affiliate
```sql
SELECT c.CountryID
FROM KYP.AffiliateCountriesOfOperation c WITH (NOLOCK)
WHERE c.AffiliateID = 60062
```

### 8.2 Affiliates with the most operating countries
```sql
SELECT AffiliateID, COUNT(*) AS CountryCount
FROM KYP.AffiliateCountriesOfOperation WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Most common operating countries
```sql
SELECT CountryID, COUNT(*) AS AffiliateCount
FROM KYP.AffiliateCountriesOfOperation WITH (NOLOCK)
GROUP BY CountryID
ORDER BY COUNT(*) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.AffiliateCountriesOfOperation | Type: Table | Source: fiktivo/KYP/Tables/KYP.AffiliateCountriesOfOperation.sql*
