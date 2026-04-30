# Customer.GetRelatedPersonalDetails

> Finds customers matching personal details (birth date, country, gender) from Customer schema tables - fraud/compliance related account detection.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns GCID, FirstName, MiddleName, LastName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedPersonalDetails finds customers matching a combination of birth date, country, and gender. This is a fraud detection procedure used to identify potentially related accounts based on personal demographic data. By finding customers with the same demographics, compliance teams can investigate whether multiple accounts belong to the same person.

The procedure reads from Customer.ContactUserInfo (for CountryID) and Customer.BasicUserInfo (for BirthDate, Gender, names). BirthDate comparison uses ISNULL to make it optional (if NULL is passed, all birth dates match).

---

## 2. Business Logic

### 2.1 Optional Birth Date Filtering

**What**: Birth date is optional via ISNULL pattern.

**Columns/Parameters Involved**: `@birthDay`, `BirthDate`

**Rules**:
- `BirthDate = ISNULL(@birthDay, BirthDate)` - when @birthDay is NULL, the condition always matches (returns all)
- When @birthDay has a value, only exact matches are returned
- CountryID and Gender are always required exact matches

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @birthDay | datetime | YES | - | CODE-BACKED | Birth date to match. NULL = match all birth dates (optional filter). |
| 2 | @countryId | int | NO | - | CODE-BACKED | Country ID to match (required). FK to Dictionary.Country. |
| 3 | @gender | char(1) | NO | - | CODE-BACKED | Gender to match (required). |
| 4 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 5 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | First name. |
| 6 | MiddleName (output) | nvarchar | YES | - | CODE-BACKED | Middle name. |
| 7 | LastName (output) | nvarchar | YES | - | CODE-BACKED | Last name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @countryId | Customer.ContactUserInfo | JOIN | Country matching |
| @birthDay, @gender | Customer.BasicUserInfo | JOIN | Demographics matching |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Related account detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedPersonalDetails (procedure)
+-- Customer.ContactUserInfo (table)
+-- Customer.BasicUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ContactUserInfo | Table | FROM - CountryID |
| Customer.BasicUserInfo | Table | JOIN on GCID - BirthDate, Gender, names |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find by all criteria
```sql
EXEC Customer.GetRelatedPersonalDetails @birthDay='1990-01-15', @countryId=106, @gender='M'
```

### 8.2 Find by country and gender only (any birth date)
```sql
EXEC Customer.GetRelatedPersonalDetails @birthDay=NULL, @countryId=106, @gender='F'
```

### 8.3 Compare with legacy version
```sql
-- GetRelatedPersonalDetails: Customer.ContactUserInfo + BasicUserInfo (new)
-- GetRelatedUsersPersonalDetails: dbo.Real_Customer (legacy)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetRelatedPersonalDetails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedPersonalDetails.sql*
