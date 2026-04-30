# fiktivo.ChangePassword

> Changes an affiliate user's login password by encrypting the new password and updating the user record with the encrypted value and a fresh change timestamp.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LoginName (identifies the user whose password is changed) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure changes the login password for an affiliate portal user. It takes a plaintext new password, encrypts it using `fiktivo.EncryptPassword` (which uses SQL Server symmetric key encryption), and updates the user's record in `dbo.tblaff_User` with the encrypted password and the current date/time as the password change timestamp.

Password changes are a core security requirement. Affiliates may need to change their passwords voluntarily (security best practice) or may be forced to change them when their password expires (see `fiktivo.IsPasswordExpired`). Without this procedure, there would be no way to update affiliate credentials in the encrypted password store.

The procedure is called from the affiliate portal when a user initiates a password change. It performs a case-insensitive match on LoginName and only updates non-deleted users (IsDeleted=0). The ChangedPasswordDate column is set to the current timestamp, which resets the password expiration clock tracked by `fiktivo.IsPasswordExpired`.

---

## 2. Business Logic

### 2.1 Password Encryption and Update

**What**: Encrypts the new password and updates the user record with the encrypted value and change timestamp.

**Columns/Parameters Involved**: `@LoginName`, `@NewPassword`, `EncryptedLoginPassword`, `ChangedPasswordDate`

**Rules**:
- Calls fiktivo.EncryptPassword to encrypt @NewPassword into a varbinary(128) value
- Updates dbo.tblaff_User SET EncryptedLoginPassword = encrypted value, ChangedPasswordDate = GETDATE()
- WHERE clause uses case-insensitive comparison on LoginName (LOWER(@LoginName) = LOWER(LoginName))
- Only active users are affected: WHERE IsDeleted = 0
- The ChangedPasswordDate reset is critical -- it resets the 3-month expiration window checked by IsPasswordExpired

**Diagram**:
```
Affiliate Portal: User requests password change
    |
    v
fiktivo.ChangePassword(@LoginName, @NewPassword)
    |
    +--> EXEC fiktivo.EncryptPassword(@NewPassword) --> @EncryptedPassword
    |
    +--> UPDATE dbo.tblaff_User
    |        SET EncryptedLoginPassword = @EncryptedPassword,
    |            ChangedPasswordDate = GETDATE()
    |        WHERE LOWER(LoginName) = LOWER(@LoginName)
    |          AND IsDeleted = 0
    |
    v
Password changed, expiration clock reset
```

### 2.2 Security: Case-Insensitive Login Matching

**What**: Ensures login name matching is case-insensitive for user convenience.

**Columns/Parameters Involved**: `@LoginName`, `LoginName` (column)

**Rules**:
- LOWER() applied to both @LoginName parameter and LoginName column for comparison
- Prevents issues where a user types their login name in different case than originally registered
- IsDeleted=0 filter prevents reactivating deleted user accounts through password change

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LoginName (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | The login name of the affiliate user whose password is being changed. Matched case-insensitively against dbo.tblaff_User.LoginName. |
| 2 | @NewPassword (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | The new plaintext password. Encrypted by fiktivo.EncryptPassword before storage. Max 50 characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LoginName | dbo.tblaff_User | Lookup / Update | Finds and updates the user record matching the login name |
| EXEC call | fiktivo.EncryptPassword | Procedure call | Encrypts the new password using symmetric key encryption |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.ChangePassword (procedure)
├── fiktivo.EncryptPassword (procedure)
└── dbo.tblaff_User (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.EncryptPassword | Stored Procedure | Called to encrypt the new password |
| dbo.tblaff_User | Table | UPDATE target for the user's encrypted password and change date |

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

### 8.1 Change a user's password
```sql
EXEC fiktivo.ChangePassword
    @LoginName = N'john.smith',
    @NewPassword = N'NewSecurePassword123'
```

### 8.2 Verify the password change timestamp was updated
```sql
SELECT LoginName, ChangedPasswordDate
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE LOWER(LoginName) = LOWER('john.smith') AND IsDeleted = 0
```

### 8.3 Check password change history for security audit
```sql
SELECT LoginName, ChangedPasswordDate,
       DATEDIFF(DAY, ChangedPasswordDate, GETDATE()) AS DaysSinceChange
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE IsDeleted = 0
ORDER BY ChangedPasswordDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.ChangePassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.ChangePassword.sql*
