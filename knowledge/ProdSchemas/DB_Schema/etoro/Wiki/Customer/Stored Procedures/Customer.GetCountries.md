# Customer.GetCountries

> Returns the full reference list of supported countries (CountryID, Name, PhonePrefix, Abbreviation) from Dictionary.Country, ordered by CountryID - a parameterless country reference data loader. Multiple schema variants exist (dbo.GetCountries, Billing.GetCountries, BackOffice.KycGetCountries).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - returns full list) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCountries is a reference data loader that returns the complete list of countries available in the eToro system. It reads from Dictionary.Country (the canonical country reference table) and returns all countries with CountryID > 0, ordered by CountryID.

The procedure exists for client-side population of country dropdowns and server-side validation contexts in the Customer domain. When a registration form, profile update, or KYC flow needs to display or validate country choices, it calls this procedure to get the current supported list.

CountryID > 0 filter excludes a sentinel value (CountryID = 0 represents "unknown/unassigned" in Dictionary.Country). ISNULL(PhonePrefix, 0) normalizes countries without international phone dialing codes to 0 rather than NULL, simplifying caller parsing.

Multiple variants of GetCountries exist across schemas:
- `Customer.GetCountries` (this procedure): Customer domain usage
- `dbo.GetCountries`: Legacy/global variant
- `Billing.GetCountries` (GRANT EXECUTE to FundingUser): Payment flow country validation
- `BackOffice.KycGetCountries`: KYC-specific variant

---

## 2. Business Logic

### 2.1 Country Reference List

**What**: Returns all valid countries with their display, phone, and abbreviation fields.

**Columns/Parameters Involved**: `Dictionary.Country.CountryID`, `Dictionary.Country.Name`, `Dictionary.Country.PhonePrefix`, `Dictionary.Country.Abbreviation`

**Rules**:
- WHERE CountryID > 0: excludes CountryID=0 sentinel (unknown/unassigned country)
- ISNULL(PhonePrefix, 0): normalizes NULL phone prefixes to 0
- ORDER BY CountryID: deterministic ordering for client-side display
- WITH (NOLOCK): non-blocking reference data read

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Result set:**

| Column | Type | Description |
|--------|------|-------------|
| CountryID | INT | Country identifier. FK used throughout the system (Customer.CustomerStatic.CountryID, etc.). |
| Name | VARCHAR | Country display name (e.g., "United States", "United Kingdom"). |
| PhonePrefix | INT | International dialing code (e.g., 1 for US, 44 for UK). ISNULL defaulted to 0 for countries without a known prefix. |
| Abbreviation | VARCHAR | ISO or system abbreviation (e.g., "US", "GB"). Used for flags, locale mapping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | Dictionary.Country | Read | Full country reference data source |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No callers found in SSDT repo. | - | Called by registration/profile/KYC application services. | |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCountries (procedure)
+-- Dictionary.Country (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Full country list; filtered CountryID > 0, ordered by CountryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called by application services for country reference data. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CountryID > 0 | Filter | Excludes CountryID=0 sentinel (unknown country) |
| ISNULL(PhonePrefix, 0) | Normalization | Null phone prefixes normalized to 0 for consistent caller handling |
| ORDER BY CountryID | Ordering | Deterministic list order for UI dropdowns |
| Schema variants | Architecture | Multiple copies across schemas (Customer, dbo, Billing, BackOffice) - each serves its domain context |

---

## 8. Sample Queries

### 8.1 Load country list

```sql
EXEC Customer.GetCountries
```

### 8.2 Equivalent inline query

```sql
SELECT CountryID, Name, ISNULL(PhonePrefix, 0) AS PhonePrefix, Abbreviation
FROM Dictionary.Country WITH (NOLOCK)
WHERE CountryID > 0
ORDER BY CountryID
```

### 8.3 Find a country by abbreviation

```sql
SELECT CountryID, Name, ISNULL(PhonePrefix, 0) AS PhonePrefix
FROM Dictionary.Country WITH (NOLOCK)
WHERE Abbreviation = 'US'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCountries | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCountries.sql*
