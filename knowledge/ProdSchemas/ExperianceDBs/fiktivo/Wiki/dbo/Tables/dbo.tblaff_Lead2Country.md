# dbo.tblaff_Lead2Country

> Rate configuration table mapping lead commission rates per country for each affiliate type, enabling geographic-based lead pricing.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (AffiliateTypeID, CountryID) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.tblaff_Lead2Country defines country-specific lead commission rates per affiliate type. Different countries have different lead values - a lead from a high-value market (e.g., Western Europe) may pay $10 while a lead from a lower-value market may pay $1. This table enables fine-grained geographic pricing of lead commissions.

Without this table, all leads would pay the same rate regardless of the customer's country. Geographic differentiation is critical for profitable affiliate programs as customer lifetime value varies significantly by region.

The table has explicit FKs to tblaff_AffiliateTypes and tblaff_Country. Contains 181 rate configurations. The Rate column specifies the commission amount per lead for each affiliate type/country combination.

---

## 2. Business Logic

### 2.1 Country-Based Lead Rate

**What**: Lead commission rates vary by country and affiliate type.

**Columns/Parameters Involved**: `AffiliateTypeID`, `CountryID`, `Rate`

**Rules**:
- Rate specifies the per-lead commission amount for the given affiliate type in the given country
- AffiliateTypeID 195 has multiple countries with varying rates: Country 1 = $1, Country 2 = $2, Country 5 = $3
- AffiliateTypeID 212 shows higher differentiation: Country 12 = $10, Country 74 = $5
- Higher rates for more valuable markets incentivize affiliates to target those regions

---

## 3. Data Overview

| AffiliateTypeID | CountryID | Rate | Meaning |
|---|---|---|---|
| 195 | 1 | 1 | Affiliate type 195 pays $1 per lead from country 1 (low-value market). |
| 195 | 2 | 2 | Same type, country 2 pays $2 (moderate value). |
| 195 | 5 | 3 | Same type, country 5 pays $3 (higher value). |
| 212 | 12 | 10 | Affiliate type 212 pays $10 per lead from country 12 (premium market). |
| 212 | 74 | 5 | Same type, country 74 pays $5 (mid-tier market). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateTypeID | int | NO | - | VERIFIED | References tblaff_AffiliateTypes.AffiliateTypeID (explicit FK). The affiliate program type this rate applies to. |
| 2 | CountryID | int | NO | - | VERIFIED | References tblaff_Country.CountryID (explicit FK). The country this rate applies to. |
| 3 | Rate | float | NO | 0 | VERIFIED | Lead commission rate for this affiliate type/country combination. Amount paid per qualifying lead from this country. |

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

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_Lead2Country | NC PK | AffiliateTypeID, CountryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_tblaff_Lead2Country_tblaff_AffiliateTypes | FOREIGN KEY | AffiliateTypeID -> tblaff_AffiliateTypes |
| FK_tblaff_Lead2Country_tblaff_Country | FOREIGN KEY | CountryID -> tblaff_Country |
| DF_tblaff_Lead2Country_Rate | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Rates for a specific affiliate type
```sql
SELECT c.CountryName, lc.Rate
FROM dbo.tblaff_Lead2Country lc WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON lc.CountryID = c.CountryID
WHERE lc.AffiliateTypeID = @AffiliateTypeID
ORDER BY lc.Rate DESC
```

### 8.2 Highest-rate countries across all types
```sql
SELECT TOP 10 at.AffiliateTypeName, c.CountryName, lc.Rate
FROM dbo.tblaff_Lead2Country lc WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON lc.CountryID = c.CountryID
JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON lc.AffiliateTypeID = at.AffiliateTypeID
ORDER BY lc.Rate DESC
```

### 8.3 Count of country rates per affiliate type
```sql
SELECT AffiliateTypeID, COUNT(*) AS CountryCount, AVG(Rate) AS AvgRate
FROM dbo.tblaff_Lead2Country WITH (NOLOCK)
GROUP BY AffiliateTypeID ORDER BY CountryCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Lead2Country | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Lead2Country.sql*
