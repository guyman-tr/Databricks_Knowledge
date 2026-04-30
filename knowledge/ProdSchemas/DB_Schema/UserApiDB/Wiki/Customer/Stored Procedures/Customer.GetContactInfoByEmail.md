# Customer.GetContactInfoByEmail

> Retrieves full contact information for a user by email address (case-insensitive) from Customer.ContactUserInfo using the optimized LowerEmail column.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @email (email lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetContactInfoByEmail retrieves a user's complete contact information by their email address. It reads directly from Customer.ContactUserInfo, using the pre-computed LowerEmail column for efficient case-insensitive matching. Can return multiple rows if the same email is used by multiple accounts (though this is unusual).

This procedure serves email-based user lookup scenarios: password reset flows, email verification, customer support by email, and duplicate detection. It returns all contact fields including country, address, phone numbers, email verification status, and geographic region data.

---

## 2. Business Logic

### 2.1 Case-Insensitive Email Matching via LowerEmail

**What**: Uses the pre-computed LowerEmail column for efficient email lookup.

**Columns/Parameters Involved**: `@email`, `LowerEmail`

**Rules**:
- The input @email is lowered via LOWER() and compared against the stored LowerEmail column
- LowerEmail is a pre-computed column in ContactUserInfo, enabling indexed lookups
- Returns all contact fields for any matching GCID(s)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @email | varchar(50) | NO | - | CODE-BACKED | Email address to search for. Case-insensitive via LOWER() against LowerEmail column. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | ContactUserInfo | CODE-BACKED | Global Customer ID. |
| 2 | CountryID | ContactUserInfo | CODE-BACKED | Country of residence. FK to Dictionary.Country. |
| 3 | Email | ContactUserInfo | CODE-BACKED | Email address (original casing). |
| 4 | Address | ContactUserInfo | CODE-BACKED | Street address. |
| 5 | City | ContactUserInfo | CODE-BACKED | City. |
| 6 | Zip | ContactUserInfo | CODE-BACKED | Postal/zip code. |
| 7 | Phone | ContactUserInfo | CODE-BACKED | Phone number. |
| 8 | Mobile | ContactUserInfo | CODE-BACKED | Mobile number. |
| 9 | Fax | ContactUserInfo | CODE-BACKED | Fax number. |
| 10 | StateID | ContactUserInfo | CODE-BACKED | State/province. FK to Dictionary.State. |
| 11 | CountryIDByIP | ContactUserInfo | CODE-BACKED | IP-detected country. |
| 12 | BuildingNumber | ContactUserInfo | CODE-BACKED | Building/house number. |
| 13 | PhonePrefix | ContactUserInfo | CODE-BACKED | Phone country prefix. |
| 14 | PhoneBody | ContactUserInfo | CODE-BACKED | Phone number body. |
| 15 | RegionID | ContactUserInfo | CODE-BACKED | Geographic region. |
| 16 | RegionByIP_ID | ContactUserInfo | CODE-BACKED | IP-detected region. |
| 17 | CitizenshipCountryID | ContactUserInfo | CODE-BACKED | Citizenship country. FK to Dictionary.Country. |
| 18 | POBCountryID | ContactUserInfo | CODE-BACKED | Place of birth country. FK to Dictionary.Country. |
| 19 | IsEmailVerified | ContactUserInfo | CODE-BACKED | Email verification status. |
| 20 | SubRegionID | ContactUserInfo | CODE-BACKED | Sub-region. FK to Dictionary.SubRegion. |
| 21 | EmailVerificationProviderID | ContactUserInfo | CODE-BACKED | Email verification provider. FK to Dictionary.EmailVerificationProvider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.ContactUserInfo | SELECT (READER) | All contact fields by email lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by email-based user lookup services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetContactInfoByEmail (procedure)
+-- Customer.ContactUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ContactUserInfo | Table | SELECT - email lookup and contact data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Look up contact info by email
```sql
EXEC Customer.GetContactInfoByEmail @email = 'user@example.com'
```

### 8.2 Verify email lookup
```sql
SELECT GCID, Email, CountryID, IsEmailVerified
FROM Customer.ContactUserInfo WITH (NOLOCK)
WHERE LowerEmail = LOWER('user@example.com')
```

### 8.3 Find duplicate emails
```sql
SELECT LowerEmail, COUNT(*) AS AccountCount
FROM Customer.ContactUserInfo WITH (NOLOCK)
GROUP BY LowerEmail
HAVING COUNT(*) > 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetContactInfoByEmail | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetContactInfoByEmail.sql*
