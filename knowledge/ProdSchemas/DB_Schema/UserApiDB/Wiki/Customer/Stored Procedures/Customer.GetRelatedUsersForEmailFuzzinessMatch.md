# Customer.GetRelatedUsersForEmailFuzzinessMatch

> Legacy version of GetRelatedEmailsForFuzzinessMatch - finds customers by first name + birth date from dbo.Real_Customer for fuzzy email matching.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns GCID, FirstName, BirthDate, Email |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedUsersForEmailFuzzinessMatch is the legacy version of Customer.GetRelatedEmailsForFuzzinessMatch. It finds customers with matching first name and birth date from dbo.Real_Customer (which contains all fields in one denormalized table) instead of joining Customer.BasicUserInfo and Customer.ContactUserInfo.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Exact match on FirstName (case-insensitive) + BirthDate, filtering for non-NULL emails.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @firstName | varchar(max) | NO | - | CODE-BACKED | First name to match (case-insensitive). |
| 2 | @birthDate | datetime | NO | - | CODE-BACKED | Birth date to match (exact). |
| 3 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 4 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | First name. |
| 5 | BirthDate (output) | datetime | YES | - | CODE-BACKED | Birth date. |
| 6 | Email (output) | nvarchar | YES | - | CODE-BACKED | Email address (only non-NULL returned). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Real_Customer | FROM | Legacy denormalized customer table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy fuzzy email matching |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedUsersForEmailFuzzinessMatch (procedure)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - name, birth date, email |

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

### 8.1 Find emails for fuzzy matching (legacy)
```sql
EXEC Customer.GetRelatedUsersForEmailFuzzinessMatch @firstName='John', @birthDate='1990-01-15'
```

### 8.2 Direct query
```sql
SELECT GCID, FirstName, BirthDate, Email FROM dbo.Real_Customer WITH (NOLOCK)
WHERE Email IS NOT NULL AND BirthDate = '1990-01-15' AND LOWER(FirstName) = LOWER('John')
```

### 8.3 Prefer new version
```sql
-- Use Customer.GetRelatedEmailsForFuzzinessMatch for new development
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRelatedUsersForEmailFuzzinessMatch | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedUsersForEmailFuzzinessMatch.sql*
