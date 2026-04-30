# Customer.GetRelatedUsersPersonalDetails

> Legacy version of GetRelatedPersonalDetails - finds customers by birth date, country, and gender from dbo.Real_Customer.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns GCID, FirstName, MiddleName, LastName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedUsersPersonalDetails is the legacy version of Customer.GetRelatedPersonalDetails. It finds customers matching personal demographics (birth date, country, gender) from dbo.Real_Customer instead of the Customer schema tables. Birth date uses ISNULL for optional matching (same pattern as the new version).

---

## 2. Business Logic

### 2.1 Optional Birth Date Filtering

**What**: Same ISNULL pattern as GetRelatedPersonalDetails.

**Rules**:
- `BirthDate = ISNULL(@birthDay, BirthDate)` - NULL means match all
- CountryID and Gender are always required

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @birthDay | datetime | YES | - | CODE-BACKED | Birth date (optional). |
| 2 | @countryId | int | NO | - | CODE-BACKED | Country ID (required). |
| 3 | @gender | char(1) | NO | - | CODE-BACKED | Gender (required). |
| 4 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 5 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | First name. |
| 6 | MiddleName (output) | nvarchar | YES | - | CODE-BACKED | Middle name. |
| 7 | LastName (output) | nvarchar | YES | - | CODE-BACKED | Last name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Real_Customer | FROM | Legacy customer table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy demographics matching |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedUsersPersonalDetails (procedure)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - demographics matching |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Legacy callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find by demographics (legacy)
```sql
EXEC Customer.GetRelatedUsersPersonalDetails @birthDay='1990-01-15', @countryId=106, @gender='M'
```

### 8.2 Direct query
```sql
SELECT GCID, FirstName, MiddleName, LastName FROM dbo.Real_Customer WITH (NOLOCK)
WHERE BirthDate = ISNULL(@birthDay, BirthDate) AND CountryID = @countryId AND Gender = @gender
```

### 8.3 Prefer new version
```sql
-- Use Customer.GetRelatedPersonalDetails for new development
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRelatedUsersPersonalDetails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedUsersPersonalDetails.sql*
