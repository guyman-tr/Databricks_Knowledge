# Dictionary.RegionByIP

> Mapping table with 4,206 IP-based geographic region codes per country — used for sub-country geolocation of customers during registration and regulatory compliance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RegionByIP_ID (INT IDENTITY, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RegionByIP maps numeric region codes to countries, enabling sub-country geolocation from IP address lookups. When a customer registers or logs in, their IP address is resolved to a country and region. The region code stored here represents the geographic subdivision (state, province, territory) identified by IP geolocation services.

This table is populated from IP geolocation databases and is referenced by Customer.CustomerStatic (RegionByIP_ID column), Customer.Address, Customer.Customer and Customer.IsCustomerFund views, registration procedures (Customer.InsertRealCustomer, Customer.RegisterReal, Customer.RegisterDemo), History.Customer, and reporting (BackOffice.GetRegistrationReport). Also referenced by Dictionary.SubRegion for further sub-division.

---

## 2. Business Logic

### 2.1 IP-to-Region Resolution

**What**: Each row maps a numeric region code to a specific country, representing a geographic subdivision detected by IP geolocation.

**Columns/Parameters Involved**: `RegionByIP_ID`, `CountryID`, `Name`

**Rules**:
- The Name field contains short numeric codes (e.g., "64", "01", "09") that correspond to IP geolocation provider region codes.
- Some entries have blank/whitespace names for countries where region-level data is unavailable.
- CountryID references Dictionary.Country.
- 4,206 entries covering hundreds of countries with varying granularity.
- Used primarily during registration to capture the customer's detected region for compliance and analytics.

---

## 3. Data Overview

| RegionByIP_ID | CountryID | Name | Meaning |
|---|---|---|---|
| 1 | 73 | 64 | Region code "64" in country 73 — a specific geographic subdivision |
| 2 | 28 | 01 | Region code "01" in country 28 |
| 4 | 154 | 09 | Region code "09" in country 154 |
| 7 | 164 | 36 | Region code "36" in country 164 |
| 8 | 112 | 21 | Region code "21" in country 112 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegionByIP_ID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing surrogate primary key. IDENTITY NOT FOR REPLICATION. Stored in Customer.CustomerStatic and Customer.Address. Referenced by 10+ consumers. |
| 2 | CountryID | int | NO | - | VERIFIED | FK → Dictionary.Country (implicit). The country this region belongs to. |
| 3 | Name | nvarchar(50) | YES | - | VERIFIED | IP geolocation provider region code. Short numeric or alpha codes representing sub-country divisions. May be blank/whitespace for countries without region data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | Relationship Type | Description |
|-------------------|---------|-------------------|-------------|
| Dictionary.Country | CountryID | Implicit | Parent country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | RegionByIP_ID | Implicit | Stores detected region per customer |
| Customer.Address | RegionByIP_ID | Implicit | Address region reference |
| Customer.Customer | RegionByIP_ID | View | Exposes region in customer view |
| Customer.IsCustomerFund | RegionByIP_ID | View | Fund customer view with region |
| History.Customer | RegionByIP_ID | Implicit | Historical customer region audit |
| Dictionary.SubRegion | RegionByIP_ID | Implicit | Sub-region further division |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object references Dictionary.Country implicitly.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Implicit — parent country |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Stores RegionByIP_ID per customer |
| Customer.Address | Table | Address region reference |
| Dictionary.SubRegion | Table | Sub-region division |
| Customer.InsertRealCustomer | Stored Procedure | Writer — sets region during registration |
| Customer.RegisterReal | Stored Procedure | Writer — registration with region |
| Customer.RegisterDemo | Stored Procedure | Writer — demo registration with region |
| BackOffice.GetRegistrationReport | Stored Procedure | Reader — registration reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RegionByIP_RegionID | CLUSTERED PK | RegionByIP_ID ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RegionByIP_RegionID | PRIMARY KEY | Unique region identifier |

---

## 8. Sample Queries

### 8.1 List regions for a specific country
```sql
SELECT  RegionByIP_ID,
        Name
FROM    [Dictionary].[RegionByIP] WITH (NOLOCK)
WHERE   CountryID = 218
ORDER BY Name;
```

### 8.2 Count regions per country
```sql
SELECT  c.Name AS CountryName,
        COUNT(*) AS RegionCount
FROM    [Dictionary].[RegionByIP] r WITH (NOLOCK)
JOIN    [Dictionary].[Country] c WITH (NOLOCK) ON r.CountryID = c.CountryID
GROUP BY c.Name
ORDER BY RegionCount DESC;
```

### 8.3 Find customer's detected region
```sql
SELECT  cs.CID,
        r.Name AS RegionCode,
        c.Name AS Country
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[RegionByIP] r WITH (NOLOCK) ON cs.RegionByIP_ID = r.RegionByIP_ID
JOIN    [Dictionary].[Country] c WITH (NOLOCK) ON r.CountryID = c.CountryID
WHERE   cs.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RegionByIP | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RegionByIP.sql*
