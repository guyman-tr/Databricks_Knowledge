# fiktivo.ChangePassword

> Stored procedure that changes an affiliate user's password by encrypting the new password and updating the user record in tblaff_User.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LoginName (identifies the user) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ChangePassword updates an affiliate user's encrypted password and records the password change timestamp. It is called when an affiliate changes their password through the affiliate portal, either voluntarily or after being prompted by IsPasswordExpired.

The procedure first encrypts the new password using fiktivo.EncryptPassword (which uses the SSN_Key_Password symmetric key), then updates the EncryptedLoginPassword column and sets ChangedPasswordDate to the current time in dbo.tblaff_User. Only active (non-deleted) users matching the login name (case-insensitive) are updated.

---

## 2. Business Logic

### 2.1 Password Change Flow

**What**: Encrypts new password and updates user record with new password and change timestamp.

**Columns/Parameters Involved**: `@LoginName`, `@NewPassword`

**Rules**:
- Step 1: EXEC fiktivo.EncryptPassword to encrypt @NewPassword into varbinary
- Step 2: UPDATE dbo.tblaff_User SET EncryptedLoginPassword = encrypted value, ChangedPasswordDate = GETDATE()
- WHERE: Lower(LoginName) = Lower(@LoginName) AND IsDeleted = 0
- Case-insensitive login name matching (Lower() on both sides)
- ChangedPasswordDate is set to current time - this resets the 3-month password expiry timer checked by IsPasswordExpired

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LoginName | nvarchar(50) (IN) | NO | - | CODE-BACKED | Login name of the affiliate user whose password is being changed. Matched case-insensitively against tblaff_User.LoginName. |
| 2 | @NewPassword | nvarchar(50) (IN) | NO | - | CODE-BACKED | The new plaintext password. Encrypted via fiktivo.EncryptPassword before storage. Maximum 50 characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NewPassword | fiktivo.EncryptPassword | EXEC call | Encrypts the new password before storage |
| @LoginName | dbo.tblaff_User | UPDATE | Updates EncryptedLoginPassword and ChangedPasswordDate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.ChangePassword (procedure)
├── fiktivo.EncryptPassword (procedure)
│     └── SSN_Key_Password (symmetric key)
└── dbo.tblaff_User (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.EncryptPassword | Stored Procedure | EXEC to encrypt new password |
| dbo.tblaff_User | Table (cross-schema) | UPDATE EncryptedLoginPassword and ChangedPasswordDate |

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

### 8.1 Change a user's password
```sql
EXEC fiktivo.ChangePassword @LoginName = 'admin', @NewPassword = 'NewSecurePass123'
```

### 8.2 Verify password was changed
```sql
SELECT LoginName, ChangedPasswordDate
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE Lower(LoginName) = Lower('admin') AND IsDeleted = 0
```

### 8.3 Find users who haven't changed password recently
```sql
SELECT LoginName, ChangedPasswordDate,
       DATEDIFF(day, ChangedPasswordDate, GETDATE()) AS DaysSinceChange
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE IsDeleted = 0
ORDER BY ChangedPasswordDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.ChangePassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.ChangePassword.sql*
