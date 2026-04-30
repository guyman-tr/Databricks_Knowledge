# Customer.GetContactUserInfoByEmail

> Legacy variant: retrieves contact information by email (case-insensitive) from the Customer.vContactUserInfo view using the LowerEmail column.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @email (email lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetContactUserInfoByEmail retrieves a user's contact information by email, reading from the Customer.vContactUserInfo view rather than the table directly. This is the legacy variant of GetContactInfoByEmail.

The procedure uses the pre-computed LowerEmail column for efficient case-insensitive matching. Unlike GetContactInfoByEmail, it reads from the view (vContactUserInfo) and does not return the EmailVerificationProviderID column.

---

## 2. Business Logic

### 2.1 Case-Insensitive Email Matching via LowerEmail

**What**: Uses the LowerEmail column for efficient email lookup.

**Columns/Parameters Involved**: `@email`, `LowerEmail`

**Rules**:
- Input lowered via LOWER() and compared against LowerEmail in the view
- Reads from vContactUserInfo view instead of ContactUserInfo table directly

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @email | varchar(50) | NO | - | CODE-BACKED | Email address to search for. Case-insensitive via LOWER() against LowerEmail. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | vContactUserInfo | CODE-BACKED | Global Customer ID. |
| 2 | CountryID | vContactUserInfo | CODE-BACKED | Country of residence. FK to Dictionary.Country. |
| 3 | Email | vContactUserInfo | CODE-BACKED | Email address. |
| 4 | Address | vContactUserInfo | CODE-BACKED | Street address. |
| 5 | City | vContactUserInfo | CODE-BACKED | City. |
| 6 | Zip | vContactUserInfo | CODE-BACKED | Postal/zip code. |
| 7 | Phone | vContactUserInfo | CODE-BACKED | Phone number. |
| 8 | Mobile | vContactUserInfo | CODE-BACKED | Mobile number. |
| 9 | Fax | vContactUserInfo | CODE-BACKED | Fax number. |
| 10 | StateID | vContactUserInfo | CODE-BACKED | State/province. FK to Dictionary.State. |
| 11 | CountryIDByIP | vContactUserInfo | CODE-BACKED | IP-detected country. |
| 12 | BuildingNumber | vContactUserInfo | CODE-BACKED | Building/house number. |
| 13 | PhonePrefix | vContactUserInfo | CODE-BACKED | Phone country prefix. |
| 14 | PhoneBody | vContactUserInfo | CODE-BACKED | Phone number body. |
| 15 | RegionID | vContactUserInfo | CODE-BACKED | Geographic region. |
| 16 | RegionByIP_ID | vContactUserInfo | CODE-BACKED | IP-detected region. |
| 17 | CitizenshipCountryID | vContactUserInfo | CODE-BACKED | Citizenship country. |
| 18 | POBCountryID | vContactUserInfo | CODE-BACKED | Place of birth country. |
| 19 | IsEmailVerified | vContactUserInfo | CODE-BACKED | Email verification status. |
| 20 | SubRegionID | vContactUserInfo | CODE-BACKED | Sub-region. FK to Dictionary.SubRegion. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.vContactUserInfo | SELECT (READER) | Contact data via view (email lookup) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by legacy email-based lookup services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetContactUserInfoByEmail (procedure)
+-- Customer.vContactUserInfo (view)
      +-- Customer.ContactUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.vContactUserInfo | View | SELECT - contact data by email |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up contact by email (via view)
```sql
EXEC Customer.GetContactUserInfoByEmail @email = 'user@example.com'
```

### 8.2 Compare with newer direct-table variant
```sql
EXEC Customer.GetContactInfoByEmail @email = 'user@example.com'
EXEC Customer.GetContactUserInfoByEmail @email = 'user@example.com'
-- GetContactInfoByEmail also returns EmailVerificationProviderID
```

### 8.3 Query the view directly
```sql
SELECT GCID, Email, CountryID, IsEmailVerified
FROM Customer.vContactUserInfo WITH (NOLOCK)
WHERE LowerEmail = LOWER('user@example.com')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetContactUserInfoByEmail | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetContactUserInfoByEmail.sql*
