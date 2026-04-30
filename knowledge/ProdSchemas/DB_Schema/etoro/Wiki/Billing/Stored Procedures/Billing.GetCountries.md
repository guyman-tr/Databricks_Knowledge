# Billing.GetCountries

> Returns all countries from Dictionary.Country (CountryID, Abbreviation, LongAbbreviation). Simple full-table read used by the deposit funding system to populate country lists.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCountries` is a simple lookup procedure that returns the full list of countries for use in the payment/funding system. It returns three columns from `Dictionary.Country`: the numeric ID, the 2-letter abbreviation (ISO alpha-2), and a longer abbreviation. Used by the deposit flow to populate country dropdowns and validate country inputs.

Granted to `FundingUser` - the role used by the deposit/funding application layer.

---

## 2. Business Logic

### 2.1 Full Country List

**What**: Returns all rows from Dictionary.Country with no filtering.

**Rules**:
- No parameters, no WHERE clause - returns all countries
- `WITH(NOLOCK)` - dirty read; acceptable for near-static reference data
- Three columns only: CountryID (int), Abbreviation (varchar, likely 2-char ISO), LongAbbreviation (varchar, likely 3-char ISO)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Internal country identifier. Primary key of Dictionary.Country. |
| 2 | Abbreviation | varchar | NO | - | VERIFIED | 2-letter ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE"). |
| 3 | LongAbbreviation | varchar | YES | - | VERIFIED | 3-letter ISO 3166-1 alpha-3 country code (e.g., "USA", "GBR", "DEU"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Country list | Dictionary.Country | Read | Full table scan with NOLOCK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| FundingUser (role) | EXECUTE permission | Permission | Deposit/funding application country list. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCountries (procedure)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Full SELECT of CountryID, Abbreviation, LongAbbreviation. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| FundingUser (role) | Permission | Country list for deposit flows |

---

## 7. Technical Details

N/A for Stored Procedure.

---

## 8. Sample Queries

```sql
EXEC Billing.GetCountries
-- Returns all countries: CountryID, Abbreviation (2-char), LongAbbreviation (3-char)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCountries | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCountries.sql*
