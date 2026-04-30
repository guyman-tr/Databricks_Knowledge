# fiktivo.IsPasswordExpired

> Checks whether an affiliate admin user's password has expired by verifying the password, then checking if more than 3 months have passed since the last password change.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsPasswordExpired OUTPUT (expiration status) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs two functions: password verification and expiration checking. It first decrypts the stored password for a given login name using `fiktivo.DecryptPassword`, compares it with the provided `@LoginPassword`, and then checks whether the password has expired. A password is considered expired if the `ChangedPasswordDate` is NULL (password was never changed) or if more than 3 months have elapsed since the last password change.

Password expiration is a security compliance requirement. Organizations commonly mandate that administrative passwords be rotated on a regular schedule (typically 90 days). This procedure enforces that policy for the affiliate portal's admin users. If the password is expired, the portal forces the user to change it before proceeding.

The procedure is called during the affiliate portal login flow. After standard authentication, this check determines whether the user needs to be redirected to a password change screen. It depends on `fiktivo.DecryptPassword` for reading the stored encrypted password. The password reset itself is handled by `fiktivo.ChangePassword`, which also resets the expiration clock.

---

## 2. Business Logic

### 2.1 Password Verification

**What**: Decrypts the stored password and compares it with the provided login password.

**Columns/Parameters Involved**: `@LoginName`, `@LoginPassword`, `EncryptedLoginPassword`

**Rules**:
- Retrieves the EncryptedLoginPassword from dbo.tblaff_User for the given LoginName
- Calls fiktivo.DecryptPassword to decrypt the stored value to plaintext
- Compares the decrypted password with the provided @LoginPassword
- If passwords do not match, the procedure behavior is undefined for expiration (the upstream authentication would have already failed)

### 2.2 Expiration Check (3-Month Policy)

**What**: Determines if the password has exceeded the 3-month maximum age.

**Columns/Parameters Involved**: `@LoginName`, `ChangedPasswordDate`, `@IsPasswordExpired`

**Rules**:
- If ChangedPasswordDate IS NULL: password was never changed after initial setup, @IsPasswordExpired = 1
- If DATEDIFF(MONTH, ChangedPasswordDate, GETDATE()) > 3: password is older than 3 months, @IsPasswordExpired = 1
- Otherwise: password is current, @IsPasswordExpired = 0
- The 3-month threshold is hardcoded in the procedure

**Diagram**:
```
Login Flow
    |
    v
fiktivo.IsPasswordExpired(@LoginName, @LoginPassword)
    |
    +--> SELECT EncryptedLoginPassword FROM dbo.tblaff_User
    |        WHERE LoginName = @LoginName
    |
    +--> EXEC fiktivo.DecryptPassword(@EncryptedPassword) --> @DecryptedPassword
    |
    +--> Compare @DecryptedPassword with @LoginPassword
    |
    +--> CHECK ChangedPasswordDate:
    |       |
    |       +-- IS NULL      --> @IsPasswordExpired = 1 (never changed)
    |       +-- > 3 months   --> @IsPasswordExpired = 1 (expired)
    |       +-- <= 3 months  --> @IsPasswordExpired = 0 (current)
    |
    v
Return @IsPasswordExpired to caller
    |
    +-- 1 --> Redirect to fiktivo.ChangePassword flow
    +-- 0 --> Proceed to affiliate portal
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LoginName (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | The login name of the affiliate admin user to check. Matched against dbo.tblaff_User.LoginName. |
| 2 | @LoginPassword (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | The plaintext password provided by the user during login. Compared against the decrypted stored password to verify identity before checking expiration. |
| 3 | @IsPasswordExpired (OUT) | BIT | NO | - | CODE-BACKED | The expiration check result: 1 = password is expired (never changed or older than 3 months), 0 = password is current (changed within the last 3 months). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LoginName | dbo.tblaff_User | Lookup | Reads the user's EncryptedLoginPassword and ChangedPasswordDate |
| EXEC call | fiktivo.DecryptPassword | Procedure call | Decrypts the stored password for comparison |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.IsPasswordExpired (procedure)
├── fiktivo.DecryptPassword (procedure)
└── dbo.tblaff_User (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.DecryptPassword | Stored Procedure | Called to decrypt the stored password for comparison |
| dbo.tblaff_User | Table | Read to get EncryptedLoginPassword and ChangedPasswordDate |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check if a user's password is expired
```sql
DECLARE @IsExpired BIT
EXEC fiktivo.IsPasswordExpired
    @LoginName = N'admin.user',
    @LoginPassword = N'CurrentPassword123',
    @IsPasswordExpired = @IsExpired OUTPUT
SELECT @IsExpired AS IsPasswordExpired
```

### 8.2 Check password age for all active users
```sql
SELECT LoginName, ChangedPasswordDate,
       DATEDIFF(MONTH, ChangedPasswordDate, GETDATE()) AS MonthsSinceChange,
       CASE
           WHEN ChangedPasswordDate IS NULL THEN 'EXPIRED (never changed)'
           WHEN DATEDIFF(MONTH, ChangedPasswordDate, GETDATE()) > 3 THEN 'EXPIRED'
           ELSE 'CURRENT'
       END AS PasswordStatus
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE IsDeleted = 0
ORDER BY ChangedPasswordDate ASC
```

### 8.3 Find users whose passwords will expire within 2 weeks
```sql
SELECT LoginName, ChangedPasswordDate,
       DATEADD(MONTH, 3, ChangedPasswordDate) AS ExpirationDate,
       DATEDIFF(DAY, GETDATE(), DATEADD(MONTH, 3, ChangedPasswordDate)) AS DaysUntilExpiration
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE IsDeleted = 0
  AND ChangedPasswordDate IS NOT NULL
  AND DATEDIFF(DAY, GETDATE(), DATEADD(MONTH, 3, ChangedPasswordDate)) BETWEEN 0 AND 14
ORDER BY ExpirationDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.IsPasswordExpired | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.IsPasswordExpired.sql*
