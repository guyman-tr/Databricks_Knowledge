# Billing.GetCountryAndRank

> Returns the full mapping of rank IDs to countries (RankID, CountryID, CountryName, Abbreviation) by joining Dictionary.RankToCountry with Dictionary.Country. Used to retrieve country-rank eligibility configurations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCountryAndRank` returns the complete list of rank-to-country mappings with human-readable country names. In eToro's payment system, "Rank" represents a country-level risk or regulatory classification that determines what deposit/withdrawal options are available to customers from that country. This procedure is used to populate or display the full rank-to-country mapping table.

---

## 2. Business Logic

### 2.1 Rank-Country JOIN

**What**: Joins rank-country assignment table with country name lookup.

**Rules**:
- `Dictionary.RankToCountry` contains the RankID-CountryID mapping
- `INNER JOIN Dictionary.Country` on CountryID to add CountryName (aliased Name -> CountryName) and Abbreviation
- No filtering - returns all mappings
- No parameters

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RankID | int | NO | - | VERIFIED | Country risk/regulatory rank identifier. From Dictionary.RankToCountry. Determines payment method eligibility. |
| 2 | CountryID | int | NO | - | VERIFIED | Internal country identifier. From Dictionary.RankToCountry. FK to Dictionary.Country. |
| 3 | CountryName | varchar | NO | - | VERIFIED | Full country name. Aliased from Dictionary.Country.Name. |
| 4 | Abbreviation | varchar | NO | - | VERIFIED | 2-letter ISO country code. From Dictionary.Country.Abbreviation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RankID, CountryID | Dictionary.RankToCountry | Read | Rank-to-country assignment data. |
| CountryName, Abbreviation | Dictionary.Country | Lookup (INNER JOIN) | Adds country name and abbreviation to the rank mapping. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No explicit GRANT EXECUTE found) | - | Likely internal admin/routing use |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCountryAndRank (procedure)
├── Dictionary.RankToCountry (table)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RankToCountry | Table | Source of RankID-CountryID mappings. |
| Dictionary.Country | Table | INNER JOIN for CountryName and Abbreviation. |

---

## 7. Technical Details

N/A for Stored Procedure.

---

## 8. Sample Queries

```sql
EXEC Billing.GetCountryAndRank
-- Returns all country-rank pairs with names
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCountryAndRank | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCountryAndRank.sql*
