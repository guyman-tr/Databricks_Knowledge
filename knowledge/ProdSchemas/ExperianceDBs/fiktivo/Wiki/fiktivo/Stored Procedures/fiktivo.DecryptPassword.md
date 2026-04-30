# fiktivo.DecryptPassword

> Decrypts an encrypted password using SQL Server symmetric key encryption, returning the original plaintext password.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @result OUTPUT (decrypted password) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure decrypts a password that was previously encrypted using `fiktivo.EncryptPassword`. It opens a SQL Server symmetric key (SSN_Key_Password) and uses DecryptByKey to convert the encrypted varbinary(128) value back to the original plaintext nvarchar(50) password.

This is a core security utility used by the affiliate authentication system. It is called by `fiktivo.IsPasswordExpired` to verify whether an affiliate's stored password matches during login. The symmetric key uses password-based decryption for key access.

No tables are referenced - this is a pure cryptographic operation.

---

## 2. Business Logic

### 2.1 Symmetric Key Decryption

**What**: Decrypts a password using SQL Server's built-in symmetric key infrastructure.

**Columns/Parameters Involved**: `@Password` (input), `@result` (output)

**Rules**:
- Opens the symmetric key SSN_Key_Password using DECRYPTION BY PASSWORD
- Applies DecryptByKey to convert varbinary(128) encrypted value to nvarchar(50) plaintext
- Returns NULL if the key cannot decrypt the value (wrong key or corrupted data)
- Key must be opened in the session scope before DecryptByKey works

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Password (IN) | VARBINARY(128) | NO | - | CODE-BACKED | Encrypted password value to decrypt. Previously produced by fiktivo.EncryptPassword using the same symmetric key. |
| 2 | @result (OUT) | NVARCHAR(50) | YES | - | CODE-BACKED | Decrypted plaintext password. NULL if decryption fails. Max 50 characters matching the affiliate login password length. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Pure cryptographic operation using SQL Server symmetric key.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.IsPasswordExpired | (EXEC) | Procedure call | Called to decrypt stored password for expiration check. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies (uses SQL Server symmetric key infrastructure only).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.IsPasswordExpired | Stored Procedure | Calls DecryptPassword to decrypt stored password for comparison |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Decrypt a password value
```sql
DECLARE @result NVARCHAR(50)
EXEC fiktivo.DecryptPassword @Password = 0x00A1B2C3..., @result = @result OUTPUT
SELECT @result AS DecryptedPassword
```

### 8.2 Decrypt and compare (typical usage pattern)
```sql
DECLARE @decrypted NVARCHAR(50)
DECLARE @storedPassword VARBINARY(128)
SELECT @storedPassword = EncryptedLoginPassword FROM dbo.tblaff_User WITH (NOLOCK) WHERE LoginName = 'admin'
EXEC fiktivo.DecryptPassword @Password = @storedPassword, @result = @decrypted OUTPUT
SELECT CASE WHEN @decrypted = 'test_password' THEN 'Match' ELSE 'No Match' END
```

### 8.3 Verify symmetric key is accessible
```sql
SELECT name, key_length, algorithm_desc
FROM sys.symmetric_keys
WHERE name = 'SSN_Key_Password'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.DecryptPassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.DecryptPassword.sql*
