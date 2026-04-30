# fiktivo.EncryptPassword

> Utility stored procedure that encrypts a plaintext password into varbinary format using SQL Server's symmetric key encryption for secure storage.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @result (OUTPUT - encrypted password) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

EncryptPassword converts a plaintext password string into an encrypted varbinary(128) value using SQL Server's EncryptByKey function with the SSN_Key_Password symmetric key. This encrypted form is what gets stored in dbo.tblaff_User.EncryptedLoginPassword.

This procedure is called by ChangePassword to encrypt the new password before writing it to the database. It provides a reusable encryption interface that pairs with DecryptPassword for the encrypt/decrypt lifecycle.

The procedure has no table dependencies - it purely operates on the provided plaintext value using SQL Server's built-in encryption functions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The procedure is a single-purpose encryption wrapper.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Password | nvarchar(50) (IN) | NO | - | CODE-BACKED | The plaintext password to encrypt. Maximum 50 characters. |
| 2 | @result | varbinary(128) (OUTPUT) | YES | - | CODE-BACKED | The encrypted password value suitable for storage in tblaff_User.EncryptedLoginPassword. NULL if encryption fails. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | SSN_Key_Password | Symmetric Key | Opens for encryption using Key_GUID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.ChangePassword | @NewPassword | EXEC call | Called to encrypt the new password before storing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no table/view dependencies. It uses the SSN_Key_Password symmetric key.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| SSN_Key_Password | Symmetric Key (DB-level) | Opened for encryption via EncryptByKey(Key_GUID()) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.ChangePassword | Stored Procedure | Calls to encrypt new password before storing in tblaff_User |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Encrypt a password
```sql
DECLARE @encrypted VARBINARY(128)
EXEC fiktivo.EncryptPassword 'MyNewPassword', @encrypted OUTPUT
SELECT @encrypted AS EncryptedValue
```

### 8.2 Encrypt and verify roundtrip
```sql
DECLARE @encrypted VARBINARY(128), @decrypted NVARCHAR(50)
EXEC fiktivo.EncryptPassword 'TestPass123', @encrypted OUTPUT
EXEC fiktivo.DecryptPassword @encrypted, @decrypted OUTPUT
SELECT CASE WHEN @decrypted = 'TestPass123' THEN 'Roundtrip OK' ELSE 'FAILED' END AS Status
```

### 8.3 Check encryption key availability
```sql
OPEN SYMMETRIC KEY SSN_Key_Password DECRYPTION BY PASSWORD = N'Oh My G0d th3y k!lled K3nny';
SELECT CASE WHEN Key_GUID('SSN_Key_Password') IS NOT NULL THEN 'Key Available' ELSE 'Key Missing' END AS KeyStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.EncryptPassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.EncryptPassword.sql*
