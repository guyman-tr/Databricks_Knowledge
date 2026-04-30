# Compliance.GetCountryLongAbbreviation

> Returns the ISO 3166-1 alpha-3 country code for every country in the platform, used by WorldCheck integration for KYC/AML screening.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CountryID (output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a simple data feed for the WorldCheck integration. WorldCheck (a Thomson Reuters/Refinitiv risk intelligence platform) uses standardized ISO 3166-1 alpha-3 country codes for all country references, while eToro's internal system uses integer `CountryID` values. This SP provides the mapping between eToro's CountryID and the corresponding three-character international code (e.g., CountryID 1 = 'AFG', CountryID 9 = 'ARG').

Without this mapping, the WorldCheck screening service could not match eToro country identifiers to its own country-coded risk database. Every customer's country of residence or nationality passed to WorldCheck for sanctions/PEP screening must be translated from eToro's integer IDs to ISO alpha-3 codes.

The procedure was created on 29/04/2018 by Geri Reshef as part of ticket 51236 ("DB EtoroDB WorldCheck Integration"). The `SQL_Compliance` service account (used by the compliance application) has EXECUTE permission on this SP, confirming it is called by the compliance service rather than interactively.

---

## 2. Business Logic

### 2.1 CountryID-to-ISO Mapping for WorldCheck

**What**: Maps eToro's internal country integer IDs to internationally recognized ISO 3166-1 alpha-3 codes required by the WorldCheck screening platform.

**Columns/Parameters Involved**: `CountryID`, `LongAbbreviation`

**Rules**:
- All 251 countries in `Dictionary.Country` are returned (no filter)
- `LongAbbreviation` contains the ISO 3166-1 alpha-3 code (3 uppercase characters) for all real countries
- CountryID=0 is a special "unknown/none" placeholder with a blank LongAbbreviation
- The consumer (WorldCheck integration) uses CountryID to look up the code and sends the alpha-3 value to WorldCheck APIs

**Diagram**:
```
eToro Customer record
  CountryID = 3 (integer)
        |
        v
GetCountryLongAbbreviation
  returns full mapping table
        |
        v
WorldCheck integration
  looks up CountryID 3 -> 'DZA' (Algeria ISO alpha-3)
        |
        v
WorldCheck API call with country code 'DZA'
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters.

**Return Result Set** (SELECT on success):

| # | Column | Type | Nullable | Default | Confidence | Description |
|---|--------|------|----------|---------|------------|-------------|
| R1 | CountryID | INT | NO | - | CODE-BACKED | eToro's internal integer identifier for the country. FK to `Dictionary.Country.CountryID`. CountryID=0 is a special "unknown/none" placeholder. |
| R2 | LongAbbreviation | NVARCHAR | YES | - | CODE-BACKED | ISO 3166-1 alpha-3 country code (3 uppercase characters, e.g., 'AFG'=Afghanistan, 'ALB'=Albania, 'GBR'=United Kingdom). Used by WorldCheck to identify countries in sanctions/PEP screening. CountryID=0 returns spaces (blank). 250 of 251 rows have a valid 3-character code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID, LongAbbreviation | Dictionary.Country | Lookup (SELECT) | Reads country-to-ISO-code mapping from the central country dictionary |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_Compliance (service account) | - | EXECUTE permission | Called by the compliance application/service for WorldCheck KYC/AML integration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.GetCountryLongAbbreviation (procedure)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | SELECT source - returns CountryID and LongAbbreviation for all 251 countries |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_Compliance service | External application | Calls this SP to get country-to-ISO-code mapping for WorldCheck screening requests |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC [Compliance].[GetCountryLongAbbreviation];
```

### 8.2 Preview the country-to-ISO mapping

```sql
SELECT TOP 20 CountryID, LongAbbreviation
FROM [Dictionary].[Country] WITH (NOLOCK)
WHERE LEN(LTRIM(RTRIM(LongAbbreviation))) = 3
ORDER BY CountryID;
```

### 8.3 Find eToro CountryID for a known ISO alpha-3 code

```sql
SELECT CountryID, LongAbbreviation, Name
FROM [Dictionary].[Country] WITH (NOLOCK)
WHERE LongAbbreviation IN ('GBR', 'USA', 'DEU', 'AUS')
ORDER BY LongAbbreviation;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. DDL comment identifies origin: ticket 51236 "DB EtoroDB WorldCheck Integration" (2018-04-29, Geri Reshef).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.GetCountryLongAbbreviation | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.GetCountryLongAbbreviation.sql*
