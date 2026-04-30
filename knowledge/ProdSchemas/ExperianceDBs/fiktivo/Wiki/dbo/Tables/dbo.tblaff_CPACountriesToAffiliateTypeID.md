# dbo.tblaff_CPACountriesToAffiliateTypeID

> Configuration table mapping which countries are eligible for CPA commissions under each affiliate type, with system-versioning for temporal audit trail.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (AffiliateTypeID, CountryID) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.tblaff_CPACountriesToAffiliateTypeID defines which countries are eligible for CPA (Cost Per Acquisition) commissions under each affiliate type. Not all affiliate types earn CPA commissions from all countries - regulatory restrictions and business rules limit which country-affiliate type combinations qualify.

Without this table, the CPA commission engine would need to apply uniform rates globally, ignoring country-specific regulatory and business constraints. This enables granular control over CPA eligibility per affiliate program tier and geography.

The table is system-versioned (temporal) with history in `History.tblaff_CPACountriesToAffiliateTypeID`, providing a full audit trail of country eligibility changes. Explicit FKs reference tblaff_AffiliateTypes and tblaff_Country. The `SaveCountriesPerAffiliateTypeId` procedure manages these mappings. Contains 13 active records.

---

## 2. Business Logic

### 2.1 Country-Based CPA Eligibility

**What**: Controls which countries qualify for CPA commissions per affiliate type.

**Columns/Parameters Involved**: `AffiliateTypeID`, `CountryID`

**Rules**:
- Composite PK ensures each affiliate type/country pair is unique
- An affiliate type with NO entries means CPA applies to all countries (default behavior)
- An affiliate type WITH entries means CPA is restricted to only listed countries
- AffiliateTypeID 2205 has the most country entries (4 countries), suggesting a geographically restricted program
- System-versioning tracks when countries are added/removed from eligibility

---

## 3. Data Overview

| AffiliateTypeID | CountryID | ValidFrom | Meaning |
|---|---|---|---|
| 741 | 74 | 2026-03-03 | Affiliate type 741 eligible for CPA in country 74 only. |
| 928 | 5, 6 | 2026-03-03 | Affiliate type 928 eligible for CPA in countries 5 and 6. |
| 2205 | 1, 2, 3, 243 | 2026-03-03 | Affiliate type 2205 has the widest geographic CPA eligibility (4 countries). |
| 2233 | 15 | 2026-03-03 | Affiliate type 2233 restricted to single country (15). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateTypeID | int | NO | - | VERIFIED | References tblaff_AffiliateTypes.AffiliateTypeID (explicit FK). The affiliate program type this eligibility rule applies to. |
| 2 | CountryID | int | NO | - | VERIFIED | References tblaff_Country.CountryID (explicit FK). The country eligible for CPA under this affiliate type. |
| 3 | ValidFrom | datetime2(7) | NO | - | VERIFIED | System-versioned temporal column. Row creation/modification timestamp. GENERATED ALWAYS AS ROW START. |
| 4 | ValidTo | datetime2(7) | NO | - | VERIFIED | System-versioned temporal column. Row expiration timestamp. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | FK (explicit) | The affiliate program type |
| CountryID | dbo.tblaff_Country | FK (explicit) | The eligible country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.SaveCountriesPerAffiliateTypeId | INSERT/DELETE | Procedure (WRITER) | Manages country eligibility mappings |
| dbo.CPAPerCountrySaveDepositSlab | FROM | Procedure (READER) | Reads eligible countries for CPA slab configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.SaveCountriesPerAffiliateTypeId | Stored Procedure | WRITER |
| dbo.CPAPerCountrySaveDepositSlab | Stored Procedure | READER |
| History.tblaff_CPACountriesToAffiliateTypeID | Table | System-versioned history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CPACountriesToAffiliateTypeID | CLUSTERED PK | AffiliateTypeID, CountryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_tblaff_CPACountriesToAffiliateTypeID_tblaff_AffiliateTypes | FOREIGN KEY | AffiliateTypeID -> tblaff_AffiliateTypes |
| FK_tblaff_CPACountriesToAffiliateTypeID_tblaff_Country | FOREIGN KEY | CountryID -> tblaff_Country |
| SYSTEM_VERSIONING | TEMPORAL | History: History.tblaff_CPACountriesToAffiliateTypeID |

---

## 8. Sample Queries

### 8.1 Get eligible countries for an affiliate type
```sql
SELECT c.CountryID, c.CountryName
FROM dbo.tblaff_CPACountriesToAffiliateTypeID cc WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON cc.CountryID = c.CountryID
WHERE cc.AffiliateTypeID = @AffiliateTypeID
```

### 8.2 Affiliate types with country restrictions
```sql
SELECT AffiliateTypeID, COUNT(*) AS EligibleCountries
FROM dbo.tblaff_CPACountriesToAffiliateTypeID WITH (NOLOCK)
GROUP BY AffiliateTypeID ORDER BY EligibleCountries DESC
```

### 8.3 Historical country eligibility changes
```sql
SELECT AffiliateTypeID, CountryID, ValidFrom, ValidTo
FROM dbo.tblaff_CPACountriesToAffiliateTypeID
FOR SYSTEM_TIME ALL
WHERE AffiliateTypeID = @AffiliateTypeID
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_CPACountriesToAffiliateTypeID | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_CPACountriesToAffiliateTypeID.sql*
