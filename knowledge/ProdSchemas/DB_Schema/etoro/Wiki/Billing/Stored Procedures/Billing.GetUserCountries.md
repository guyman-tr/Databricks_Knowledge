# Billing.GetUserCountries

> Returns a customer's declared country (CountryID), IP-detected registration country (CountryIDByIP), and province (RegionID), with optional country name resolution via Dictionary.Country; used by billing services for regulatory routing and country-based payment decisions.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID; returns one row with UserDeclarationCountryId, UserRegistrationCountryId, ProvinceID, and optional country names |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetUserCountries retrieves the two authoritative country identifiers for a customer, plus their province, and optionally resolves human-readable country names. In the eToro data model, a customer has two distinct country associations:

- **Declaration country** (`Customer.Customer.CountryID`): The country the customer declared during registration (self-reported)
- **Registration country** (`Customer.Customer.CountryIDByIP`): The country detected from the customer's IP address at registration time

The distinction matters for billing because:
- Regulatory jurisdiction may differ between declared and detected country
- Payment method availability and routing rules may use different country sources
- Risk scoring considers both declared and IP-detected location

`@IncludeCountryName` (default=1) controls whether the procedure joins to `Dictionary.Country` twice to resolve human-readable names. Setting it to 0 skips the joins for performance when only IDs are needed.

Referenced in "Billing Service Database Readonly Separation" (Confluence MG space) - indicating this SP is part of the read-only billing service API.

---

## 2. Business Logic

### 2.1 Country Name Resolution Toggle

**What**: @IncludeCountryName controls whether country names are resolved via Dictionary.Country joins.

**Columns/Parameters Involved**: `@IncludeCountryName`, `Dictionary.Country.Name`

**Rules**:
- `IF @IncludeCountryName = 1`: queries Customer.Customer with LEFT JOIN to Dictionary.Country (twice - once for declaration, once for registration country)
- `ELSE`: queries Customer.Customer only (no joins); country name variables remain NULL, resolved to 'Not Identified' by COALESCE in the final SELECT
- Both branches populate the same scalar variables (@UserDeclarationCountryId, @RegCountryId, @ProvinceID, @DecCountryName, @RegCountryName)
- Final SELECT always returns all 5 columns regardless of branch

### 2.2 Dual Country Source

**What**: Returns both self-declared and IP-detected country for regulatory and routing decisions.

**Columns/Parameters Involved**: `Customer.Customer.CountryID`, `Customer.Customer.CountryIDByIP`, `Customer.Customer.RegionID`

**Rules**:
- `CountryID` -> `@UserDeclarationCountryId`: self-reported country from registration form
- `CountryIDByIP` -> `@RegCountryId`: country inferred from IP geolocation at registration
- `RegionID` -> `@ProvinceID`: state/province within the country
- LEFT JOIN to Dictionary.Country aliased `decCountry` for declaration country name
- LEFT JOIN to Dictionary.Country aliased `regCountry` for registration country name

### 2.3 COALESCE Defaults

**What**: Ensures no NULL values in the result; applies safe defaults.

**Rules**:
- `COALESCE(@UserDeclarationCountryId, 0)` - 0 if country not set
- `COALESCE(@DecCountryName, 'Not Identified')` - 'Not Identified' if no country or @IncludeCountryName=0
- `COALESCE(@RegCountryId, 0)` - 0 if IP country not detected
- `COALESCE(@ProvinceID, 0)` - 0 if no province set
- `COALESCE(@RegCountryName, 'Not Identified')` - 'Not Identified' if no IP country or @IncludeCountryName=0

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters Customer.Customer to this single customer. |
| 2 | @IncludeCountryName | BIT | YES | 1 | CODE-BACKED | When 1 (default), resolves country names via Dictionary.Country JOIN. When 0, skips joins for performance - country name columns return 'Not Identified'. |
| - | UserDeclarationCountryId | INT | NO | 0 | CODE-BACKED | Customer's self-declared country at registration. From Customer.Customer.CountryID. COALESCE to 0 if not set. Drives regulatory jurisdiction in many billing workflows. |
| - | UserDeclarationCountryName | VARCHAR(50) | NO | 'Not Identified' | CODE-BACKED | Human-readable name for UserDeclarationCountryId. From Dictionary.Country.Name via LEFT JOIN. Returns 'Not Identified' if CountryID is NULL or @IncludeCountryName=0. |
| - | UserRegistrationCountryId | INT | NO | 0 | CODE-BACKED | Customer's country as detected from IP address at registration. From Customer.Customer.CountryIDByIP. COALESCE to 0 if not detected. Used for geo-based risk and routing. |
| - | ProvinceID | INT | NO | 0 | CODE-BACKED | State or province within the customer's country. From Customer.Customer.RegionID. COALESCE to 0 if not set. Used for sub-national regulatory rules (e.g., US state-level compliance). |
| - | UserRegistrationCountryName | VARCHAR(50) | NO | 'Not Identified' | CODE-BACKED | Human-readable name for UserRegistrationCountryId. From Dictionary.Country.Name via LEFT JOIN. Returns 'Not Identified' if CountryIDByIP is NULL or @IncludeCountryName=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, CountryID, CountryIDByIP, RegionID | Customer.Customer | SELECT | Source of both country IDs and province |
| CountryID | Dictionary.Country (as decCountry) | LEFT JOIN (conditional) | Resolves declaration country name (when @IncludeCountryName=1) |
| CountryIDByIP | Dictionary.Country (as regCountry) | LEFT JOIN (conditional) | Resolves registration country name (when @IncludeCountryName=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing service (read-only API) | @CID | EXEC | Country data for payment routing and regulatory decisions (Billing Service Database Readonly Separation, Confluence MG) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetUserCountries (procedure)
+-- Customer.Customer (table) [CountryID + CountryIDByIP + RegionID]
+-- Dictionary.Country (table) [country name resolution - conditional]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Source of CountryID, CountryIDByIP, RegionID for the given CID |
| Dictionary.Country | Table | LEFT JOIN (twice) for country name resolution when @IncludeCountryName=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing service (read-only API) | External | Country lookup for payment routing, regulatory jurisdiction, and risk scoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Two Dictionary.Country joins | Performance | When @IncludeCountryName=1, two LEFT JOINs to Dictionary.Country are executed; use @IncludeCountryName=0 when only IDs are needed |
| NOLOCK throughout | Concurrency | All reads use WITH (NOLOCK) - appropriate for read-only billing service queries |
| Scalar variable pattern | Design | Uses scalar variables populated via SELECT, then a single final SELECT - not a direct query pattern |
| 'Not Identified' sentinel | Behavior | Country name of 'Not Identified' (not NULL) when country is unknown; callers must handle this string sentinel |

---

## 8. Sample Queries

### 8.1 Get customer countries with names (default)

```sql
EXEC [Billing].[GetUserCountries] @CID = 12345
-- Returns: UserDeclarationCountryId, UserDeclarationCountryName,
--          UserRegistrationCountryId, ProvinceID, UserRegistrationCountryName
```

### 8.2 Get customer countries IDs only (no name joins)

```sql
EXEC [Billing].[GetUserCountries] @CID = 12345, @IncludeCountryName = 0
-- Returns same columns; country names = 'Not Identified'
-- Faster: skips both Dictionary.Country joins
```

### 8.3 Equivalent direct query

```sql
SELECT
    COALESCE(c.CountryID, 0)       AS UserDeclarationCountryId,
    COALESCE(dc.Name, 'Not Identified') AS UserDeclarationCountryName,
    COALESCE(c.CountryIDByIP, 0)   AS UserRegistrationCountryId,
    COALESCE(c.RegionID, 0)        AS ProvinceID,
    COALESCE(rc.Name, 'Not Identified') AS UserRegistrationCountryName
FROM [Customer].[Customer] c WITH (NOLOCK)
LEFT JOIN [Dictionary].[Country] dc WITH (NOLOCK) ON c.CountryID = dc.CountryID
LEFT JOIN [Dictionary].[Country] rc WITH (NOLOCK) ON c.CountryIDByIP = rc.CountryID
WHERE c.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

**Confluence**: "Billing Service Database Readonly Separation" (/spaces/MG) - references this procedure as part of the read-only billing service query layer.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 1 Confluence (Billing Service Database Readonly Separation) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetUserCountries | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetUserCountries.sql*
