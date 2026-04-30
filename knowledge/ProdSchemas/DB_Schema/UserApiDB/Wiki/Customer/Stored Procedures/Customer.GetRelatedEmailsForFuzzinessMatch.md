# Customer.GetRelatedEmailsForFuzzinessMatch

> Finds customers with the same first name and birth date to retrieve their emails for fuzzy email matching - fraud detection from Customer schema tables.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns GCID, FirstName, BirthDate, Email |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedEmailsForFuzzinessMatch is a fraud detection procedure that finds customers sharing the same first name and birth date, returning their email addresses for subsequent fuzzy email comparison. This helps detect related accounts where users create multiple accounts with slight email variations but the same personal details.

The procedure joins Customer.BasicUserInfo (for name/birthdate) with Customer.ContactUserInfo (for email) and filters for exact matches on first name (case-insensitive) and birth date, excluding customers with no email.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple exact match on FirstName + BirthDate with email lookup.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @firstName | varchar(max) | NO | - | CODE-BACKED | First name to match (case-insensitive via LOWER comparison). |
| 2 | @birthDate | datetime | NO | - | CODE-BACKED | Birth date to match (exact). |
| 3 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 4 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | Customer first name. |
| 5 | BirthDate (output) | datetime | YES | - | CODE-BACKED | Customer birth date. |
| 6 | Email (output) | nvarchar | YES | - | CODE-BACKED | Customer email address. Only non-NULL emails returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @firstName, @birthDate | Customer.BasicUserInfo | JOIN | Name and birth date matching |
| GCID | Customer.ContactUserInfo | JOIN | Email retrieval |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Fuzzy email fraud detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedEmailsForFuzzinessMatch (procedure)
+-- Customer.BasicUserInfo (table)
+-- Customer.ContactUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | FROM - name and birth date |
| Customer.ContactUserInfo | Table | JOIN on GCID - email |

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

### 8.1 Find emails for fuzzy matching
```sql
EXEC Customer.GetRelatedEmailsForFuzzinessMatch @firstName = 'John', @birthDate = '1990-01-15'
```

### 8.2 Direct query equivalent
```sql
SELECT b.GCID, FirstName, BirthDate, Email
FROM Customer.BasicUserInfo b WITH (NOLOCK)
JOIN Customer.ContactUserInfo c WITH (NOLOCK) ON b.GCID = c.GCID
WHERE Email IS NOT NULL AND BirthDate = '1990-01-15' AND LOWER(FirstName) = LOWER('John')
```

### 8.3 Compare with legacy version
```sql
-- GetRelatedEmailsForFuzzinessMatch: Customer.BasicUserInfo + ContactUserInfo (new)
-- GetRelatedUsersForEmailFuzzinessMatch: dbo.Real_Customer (legacy)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetRelatedEmailsForFuzzinessMatch | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedEmailsForFuzzinessMatch.sql*
