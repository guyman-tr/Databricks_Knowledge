# Customer.GetRelatedUserEmails

> Legacy version of GetRelatedEmails - finds customers with same email local part from dbo.Real_Customer using the pre-computed LowerEmail column.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns GCID + Email |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedUserEmails is the legacy version of Customer.GetRelatedEmails. It performs the same email local-part matching but reads from dbo.Real_Customer using the pre-computed LowerEmail column (already lowercase), which is faster than applying LOWER() at query time. The Customer schema version (GetRelatedEmails) uses Customer.ContactUserInfo instead.

---

## 2. Business Logic

### 2.1 Email Local Part Matching (Legacy)

**What**: Same logic as GetRelatedEmails but uses LowerEmail column.

**Rules**:
- Extracts local part + @ from input, converts to lowercase
- Searches Real_Customer.LowerEmail with LIKE pattern
- Throws error 50010 if @ not found in input

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @email | varchar(max) | NO | - | CODE-BACKED | Email address to search by local part. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | Email (output) | nvarchar | YES | - | CODE-BACKED | Full email address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @email | dbo.Real_Customer | LIKE search | LowerEmail column matching |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy fraud detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedUserEmails (procedure)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - LowerEmail LIKE search |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| THROW 50010 | Validation | 'Invalid email' if @ not found |

---

## 8. Sample Queries

### 8.1 Find related emails (legacy)
```sql
EXEC Customer.GetRelatedUserEmails @email = 'john.doe@gmail.com'
```

### 8.2 Direct query equivalent
```sql
SELECT GCID, Email FROM dbo.Real_Customer WITH (NOLOCK)
WHERE LowerEmail LIKE LOWER(SUBSTRING('john.doe@gmail.com', 1, CHARINDEX('@', 'john.doe@gmail.com'))) + '%'
```

### 8.3 Prefer new version
```sql
-- Use Customer.GetRelatedEmails (reads from Customer.ContactUserInfo) for new development
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRelatedUserEmails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedUserEmails.sql*
