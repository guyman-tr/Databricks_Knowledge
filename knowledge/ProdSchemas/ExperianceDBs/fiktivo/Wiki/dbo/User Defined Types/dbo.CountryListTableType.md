# dbo.CountryListTableType

> Table-valued parameter type for passing a list of Country IDs to stored procedures for country-based filtering operations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | CountryID (INT, no PK) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This table type enables stored procedures to accept a batch of country identifiers as a single table-valued parameter. It is typically used for filtering affiliate data by multiple countries simultaneously - for example, when an admin wants to view affiliates from a selected set of countries.

Unlike dbo.CIDs, this type has no primary key constraint, which means duplicate CountryIDs are permitted. This design allows flexible input from UI multi-select controls where duplicates might inadvertently occur.

The CountryID values correspond to `dbo.tblaff_Country.CountryID`. No active stored procedure consumers were found in the current dbo schema, suggesting cross-schema usage (e.g., AffiliateAdmin or Affiliate schemas).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Country identifier. References dbo.tblaff_Country.CountryID. Used to pass a list of countries for multi-country filtering in stored procedures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | dbo.tblaff_Country | Implicit | Country identifier from the affiliate country lookup table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in dbo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate the type
```sql
DECLARE @countries dbo.CountryListTableType
INSERT INTO @countries (CountryID) VALUES (1), (2), (5), (10)
```

### 8.2 Use to filter affiliates by country
```sql
DECLARE @countries dbo.CountryListTableType
INSERT INTO @countries (CountryID) VALUES (1), (2)
SELECT a.AffiliateID, a.LoginName, c.CountryName
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON a.CountryID = c.CountryID
JOIN @countries p ON p.CountryID = c.CountryID
```

### 8.3 Count affiliates per selected country
```sql
DECLARE @countries dbo.CountryListTableType
INSERT INTO @countries (CountryID) VALUES (1), (2), (3)
SELECT c.CountryName, COUNT(*) AS AffiliateCount
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON a.CountryID = c.CountryID
JOIN @countries p ON p.CountryID = c.CountryID
GROUP BY c.CountryName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CountryListTableType | Type: User Defined Type | Source: fiktivo/dbo/User Defined Types/dbo.CountryListTableType.sql*
