# fiktivo.IsPasswordExpired

> Stored procedure that checks whether an affiliate user's password has expired based on a 3-month rotation policy, returning a flag indicating if the user must change their password.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsPasswordExpired (OUTPUT - expiration flag) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

IsPasswordExpired enforces the affiliate portal's password rotation policy. It checks whether an affiliate user needs to change their password based on two criteria: (1) the password has never been changed (ChangedPasswordDate IS NULL), or (2) the password was last changed more than 3 months ago.

This procedure is called during affiliate login to determine if the user should be redirected to the password change screen before accessing the portal. It first validates the provided password by decrypting the stored password via fiktivo.DecryptPassword, then checks the ChangedPasswordDate.

---

## 2. Business Logic

### 2.1 Password Expiration Check

**What**: Determines if the user's password has expired based on a 3-month rotation policy.

**Columns/Parameters Involved**: `@LoginName`, `@LoginPassword`, `@IsPasswordExpired`

**Rules**:
- Step 1: Read EncryptedLoginPassword from tblaff_User for the given LoginName
- Step 2: EXEC fiktivo.DecryptPassword to get the plaintext stored password
- Step 3: Verify the decrypted password matches @LoginPassword (authentication check)
- Step 4a: If ChangedPasswordDate IS NULL -> @IsPasswordExpired = 1 (user has NEVER changed password - must change now)
- Step 4b: If ChangedPasswordDate < (current date minus 3 months) -> @IsPasswordExpired = 1 (password is stale)
- Step 4c: If ChangedPasswordDate >= (current date minus 3 months) -> @IsPasswordExpired = 0 (password is fresh)
- Only active users checked (IsDeleted = 0)
- Case-insensitive login name matching using Lower()

**Diagram**:
```
Login attempt
    |
    v
Decrypt stored password
    |
    v
Does decrypted == provided?
    |-- No --> (procedure returns, @IsPasswordExpired undefined)
    |-- Yes --> Check ChangedPasswordDate
                    |
                    v
                Is NULL? --> @IsPasswordExpired = 1 (never changed)
                    |
                    v
                < 3 months ago? --> @IsPasswordExpired = 1 (expired)
                    |
                    v
                >= 3 months ago? --> @IsPasswordExpired = 0 (valid)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LoginName | nvarchar(50) (IN) | NO | - | CODE-BACKED | Affiliate user's login name. Matched case-insensitively against tblaff_User.LoginName. |
| 2 | @LoginPassword | nvarchar(50) (IN) | NO | - | CODE-BACKED | Plaintext password for authentication verification. Compared against the decrypted stored password to ensure the check is only performed for authenticated users. |
| 3 | @IsPasswordExpired | bit (OUTPUT) | NO | - | CODE-BACKED | Password expiration flag. 1 = password must be changed (never changed or older than 3 months). 0 = password is still valid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | fiktivo.DecryptPassword | EXEC call | Decrypts stored password for comparison |
| @LoginName | dbo.tblaff_User | SELECT | Reads EncryptedLoginPassword and ChangedPasswordDate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.IsPasswordExpired (procedure)
├── fiktivo.DecryptPassword (procedure)
│     └── SSN_Key_Password (symmetric key)
└── dbo.tblaff_User (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.DecryptPassword | Stored Procedure | EXEC to decrypt stored password for comparison |
| dbo.tblaff_User | Table (cross-schema) | SELECT EncryptedLoginPassword and ChangedPasswordDate |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if a user's password is expired
```sql
DECLARE @IsExpired BIT
EXEC fiktivo.IsPasswordExpired @LoginName = 'admin', @LoginPassword = 'secret', @IsPasswordExpired = @IsExpired OUTPUT
SELECT @IsExpired AS PasswordExpired
```

### 8.2 Find users with never-changed passwords
```sql
SELECT LoginName, ChangedPasswordDate
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE ChangedPasswordDate IS NULL AND IsDeleted = 0
```

### 8.3 Find users with passwords older than 3 months
```sql
SELECT LoginName, ChangedPasswordDate,
       DATEDIFF(month, ChangedPasswordDate, GETDATE()) AS MonthsSinceChange
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE ChangedPasswordDate < DATEADD(month, -3, GETDATE())
  AND IsDeleted = 0
ORDER BY ChangedPasswordDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.IsPasswordExpired | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.IsPasswordExpired.sql*
