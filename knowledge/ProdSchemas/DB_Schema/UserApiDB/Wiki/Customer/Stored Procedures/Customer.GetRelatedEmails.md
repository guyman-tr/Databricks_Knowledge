# Customer.GetRelatedEmails

> Finds customers with email addresses sharing the same local part (before @) as the given email - used for duplicate/related account detection from Customer schema tables.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns GCID + Email for matching customers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedEmails finds all customers whose email addresses share the same local part (the portion before the @ symbol) as a given email address. This is a fraud detection tool - users sometimes create multiple accounts with the same email prefix but different domains (e.g., john.doe@gmail.com and john.doe@yahoo.com).

The procedure validates the input email contains an @ character (throws error 50010 if not), extracts the local part + @, and performs a LIKE search against Customer.ContactUserInfo. This is the Customer schema version; GetRelatedUserEmails does the same against the legacy dbo.Real_Customer table.

---

## 2. Business Logic

### 2.1 Email Local Part Matching

**What**: Matches emails by local part (before @) using LIKE pattern.

**Columns/Parameters Involved**: `@email`, `Email`

**Rules**:
- Extracts substring from position 1 to @ character position: `SUBSTRING(@email, 1, CHARINDEX('@', @email))`
- Converts to lowercase for case-insensitive matching
- Appends '%' wildcard to match any domain
- Result: `lower('john.doe@') + '%'` matches john.doe@gmail.com, john.doe@yahoo.com, etc.
- Throws error 50010 ('Invalid email') if @ not found in input

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @email | varchar(max) | NO | - | CODE-BACKED | Email address to search for related accounts. Must contain @ character. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID of matching customer. |
| 3 | Email (output) | nvarchar | YES | - | CODE-BACKED | Full email address of matching customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @email | Customer.ContactUserInfo | LIKE search | Email local-part matching |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Fraud detection / related account search |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedEmails (procedure)
+-- Customer.ContactUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ContactUserInfo | Table | FROM - email LIKE search |

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
| THROW 50010 | Validation | 'Invalid email' if @ not found in input |

---

## 8. Sample Queries

### 8.1 Find accounts with same email prefix
```sql
EXEC Customer.GetRelatedEmails @email = 'john.doe@gmail.com'
-- Returns all customers with emails like john.doe@*
```

### 8.2 Direct query equivalent
```sql
SELECT GCID, Email
FROM Customer.ContactUserInfo WITH (NOLOCK)
WHERE LOWER(Email) LIKE LOWER(SUBSTRING('john.doe@gmail.com', 1, CHARINDEX('@', 'john.doe@gmail.com'))) + '%'
```

### 8.3 Compare with legacy version
```sql
-- GetRelatedEmails: reads from Customer.ContactUserInfo (new)
-- GetRelatedUserEmails: reads from dbo.Real_Customer (legacy, uses LowerEmail column)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetRelatedEmails | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedEmails.sql*
