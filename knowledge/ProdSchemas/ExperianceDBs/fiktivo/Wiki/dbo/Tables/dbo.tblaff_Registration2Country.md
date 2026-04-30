# dbo.tblaff_Registration2Country

> Rate configuration table mapping registration commission rates per country for each affiliate type, enabling geographic-based registration pricing.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | No explicit PK (heap with FKs) |
| **Partition** | No |
| **Indexes** | 0 (heap table) |

---

## 1. Business Meaning

dbo.tblaff_Registration2Country defines country-specific registration commission rates per affiliate type. Similar to tblaff_Lead2Country, this table enables geographic pricing of registration commissions - affiliates earn different amounts for registrations from different countries based on the market value of customers from those regions.

This table has explicit FKs to tblaff_AffiliateTypes and tblaff_Country but notably has NO primary key or indexes (heap table), suggesting it may be a configuration table with low read frequency or was designed as a simple lookup. Contains 633 rate configurations - significantly more than Lead2Country (181), reflecting broader country coverage for registration rates.

---

## 2. Business Logic

### 2.1 Country-Based Registration Rate

**What**: Registration commission rates vary by country and affiliate type.

**Columns/Parameters Involved**: `AffiliateTypeID`, `CountryID`, `Rate`

**Rules**:
- Rate specifies the per-registration commission for the given affiliate type in the given country
- 633 configurations across multiple affiliate types and countries
- No PK means duplicate AffiliateTypeID/CountryID combinations are technically possible (data quality risk)
- Same geographic pricing model as Lead2Country but for registration events

---

## 3. Data Overview

Table contains 633 rate configurations. Registration rates have broader country coverage than lead rates (633 vs 181).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateTypeID | int | NO | - | VERIFIED | References tblaff_AffiliateTypes.AffiliateTypeID (explicit FK). The affiliate program type. |
| 2 | CountryID | int | NO | - | VERIFIED | References tblaff_Country.CountryID (explicit FK). The country for rate lookup. |
| 3 | Rate | float | NO | 0 | VERIFIED | Registration commission rate for this combination. Amount paid per qualifying registration from this country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | FK (explicit) | The affiliate program type |
| CountryID | dbo.tblaff_Country | FK (explicit) | The country for rate lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

No indexes. This is a heap table.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_tblaff_Registration2Country_tblaff_AffiliateTypes | FOREIGN KEY | AffiliateTypeID -> tblaff_AffiliateTypes |
| FK_tblaff_Registration2Country_tblaff_Country | FOREIGN KEY | CountryID -> tblaff_Country |
| DF_tblaff_Registration2Country_Rate | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Rates for a specific affiliate type
```sql
SELECT c.CountryName, rc.Rate
FROM dbo.tblaff_Registration2Country rc WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON rc.CountryID = c.CountryID
WHERE rc.AffiliateTypeID = @AffiliateTypeID
ORDER BY rc.Rate DESC
```

### 8.2 Compare lead vs registration rates
```sql
SELECT lc.AffiliateTypeID, lc.CountryID,
       lc.Rate AS LeadRate, rc.Rate AS RegistrationRate
FROM dbo.tblaff_Lead2Country lc WITH (NOLOCK)
JOIN dbo.tblaff_Registration2Country rc WITH (NOLOCK)
  ON lc.AffiliateTypeID = rc.AffiliateTypeID AND lc.CountryID = rc.CountryID
ORDER BY lc.AffiliateTypeID, lc.CountryID
```

### 8.3 Check for duplicate configurations
```sql
SELECT AffiliateTypeID, CountryID, COUNT(*) AS Duplicates
FROM dbo.tblaff_Registration2Country WITH (NOLOCK)
GROUP BY AffiliateTypeID, CountryID
HAVING COUNT(*) > 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Registration2Country | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Registration2Country.sql*
