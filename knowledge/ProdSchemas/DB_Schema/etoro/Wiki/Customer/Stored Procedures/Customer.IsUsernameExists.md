# Customer.IsUsernameExists

> Returns a BIT output parameter indicating whether a given username (case-insensitive) already exists in Customer.Customer, used for username availability checks during registration.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Username -> @Result (OUTPUT BIT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.IsUsernameExists checks whether a username is already taken on the eToro platform, returning the result via an OUTPUT BIT parameter. It uses the UserName_LOWER column (the pre-lowercased stored version) for case-insensitive matching - so "JohnDoe", "JOHNDOE", and "johndoe" all match the same registration. This is the canonical username uniqueness check used before or during customer registration to prevent duplicate usernames.

The case-insensitive pattern (LOWER(@Username) against UserName_LOWER) matches the same approach used by Customer.GetUsersPrivacyPoliciesByUserNames and the Customer.IsUniqueName function, ensuring consistent behavior across all username checks.

---

## 2. Business Logic

### 2.1 Case-Insensitive Username Uniqueness Check

**What**: Uses the pre-lowercased UserName_LOWER column for efficient, case-insensitive username existence checking.

**Columns/Parameters Involved**: `@Username`, `Customer.Customer.UserName_LOWER`

**Rules**:
- Input username is lowercased via LOWER(@Username) before comparison
- Compared against Customer.Customer.UserName_LOWER (stored lowercase)
- @Result = 1: at least one customer has this username (regardless of case)
- @Result = 0: no customer has this username - it is available for registration
- Example: input "JohnDoe" -> LOWER = "johndoe" -> matches UserName_LOWER = "johndoe" -> @Result = 1

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Username | varchar(20) | NO | - | VERIFIED | Username to check for availability. Applied case-insensitively via LOWER(@Username) against Customer.Customer.UserName_LOWER. Maximum length 20 characters. |
| 2 | @Result | bit (OUTPUT) | NO | 0 | VERIFIED | Output parameter: 1 = username is already taken (case-insensitive match found); 0 = username is available (default, not found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LOWER(@Username) | Customer.Customer.UserName_LOWER | Reader (EXISTS) | Case-insensitive username uniqueness check |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by the registration and username availability check service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsUsernameExists (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | EXISTS check - WHERE UserName_LOWER = LOWER(@Username) |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if a username is already taken
```sql
DECLARE @taken BIT = 0;
EXEC Customer.IsUsernameExists @Username = 'johndoe', @Result = @taken OUTPUT;
SELECT @taken AS UsernameExists;  -- 1 = taken, 0 = available
```

### 8.2 Case-insensitive nature demonstration
```sql
-- These all return the same result for the same registered username
DECLARE @r1 BIT = 0, @r2 BIT = 0, @r3 BIT = 0;
EXEC Customer.IsUsernameExists @Username = 'JohnDoe', @Result = @r1 OUTPUT;
EXEC Customer.IsUsernameExists @Username = 'JOHNDOE', @Result = @r2 OUTPUT;
EXEC Customer.IsUsernameExists @Username = 'johndoe', @Result = @r3 OUTPUT;
SELECT @r1 AS R1, @r2 AS R2, @r3 AS R3;  -- All same value
```

### 8.3 Direct equivalent query for debugging
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Customer.Customer WITH (NOLOCK)
    WHERE UserName_LOWER = LOWER('johndoe')
) THEN 1 ELSE 0 END AS UsernameExists;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsUsernameExists | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.IsUsernameExists.sql*
