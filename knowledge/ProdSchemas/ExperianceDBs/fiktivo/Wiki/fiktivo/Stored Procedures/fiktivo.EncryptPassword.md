# fiktivo.EncryptPassword

> Encrypts a plaintext password using SQL Server symmetric key encryption, returning the encrypted binary value for secure storage.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @result OUTPUT (encrypted password) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure encrypts a plaintext password using SQL Server's symmetric key infrastructure (SSN_Key_Password). It converts an nvarchar(50) password into a varbinary(128) encrypted value suitable for storage in the EncryptedLoginPassword column of dbo.tblaff_User.

This is the encryption counterpart to `fiktivo.DecryptPassword`. Together they form the affiliate portal's password encryption layer. Called by `fiktivo.ChangePassword` when an affiliate changes their password.

No tables are referenced - this is a pure cryptographic operation.

---

## 2. Business Logic

### 2.1 Symmetric Key Encryption

**What**: Encrypts a password using SQL Server's built-in symmetric key infrastructure.

**Columns/Parameters Involved**: `@Password` (input), `@result` (output)

**Rules**:
- Opens the symmetric key SSN_Key_Password using DECRYPTION BY PASSWORD
- Applies EncryptByKey with the key GUID to produce varbinary(128) encrypted output
- The same key must be used for both encryption and decryption (symmetric)
- Output is stored in dbo.tblaff_User.EncryptedLoginPassword by the calling procedure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Password (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | Plaintext password to encrypt. Max 50 characters matching the affiliate login password length. |
| 2 | @result (OUT) | VARBINARY(128) | YES | - | CODE-BACKED | Encrypted password as binary. Stored in dbo.tblaff_User.EncryptedLoginPassword. Decrypted by fiktivo.DecryptPassword. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Pure cryptographic operation.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.ChangePassword | (EXEC) | Procedure call | Called to encrypt the new password before storing it. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.ChangePassword | Stored Procedure | Calls EncryptPassword to encrypt the new password |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Encrypt a password
```sql
DECLARE @encrypted VARBINARY(128)
EXEC fiktivo.EncryptPassword @Password = N'MySecurePassword', @result = @encrypted OUTPUT
SELECT @encrypted AS EncryptedValue
```

### 8.2 Encrypt-then-decrypt roundtrip test
```sql
DECLARE @encrypted VARBINARY(128), @decrypted NVARCHAR(50)
EXEC fiktivo.EncryptPassword @Password = N'TestPassword', @result = @encrypted OUTPUT
EXEC fiktivo.DecryptPassword @Password = @encrypted, @result = @decrypted OUTPUT
SELECT @decrypted AS RoundtripResult -- Should return 'TestPassword'
```

### 8.3 Typical usage in password change flow
```sql
-- Called internally by fiktivo.ChangePassword:
DECLARE @newEncrypted VARBINARY(128)
EXEC fiktivo.EncryptPassword @Password = N'NewPassword123', @result = @newEncrypted OUTPUT
-- @newEncrypted is then stored in dbo.tblaff_User.EncryptedLoginPassword
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.EncryptPassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.EncryptPassword.sql*
