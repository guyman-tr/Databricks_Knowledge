# fiktivo.DecryptPassword

> Utility stored procedure that decrypts a varbinary-encoded encrypted password back to plaintext using SQL Server's symmetric key encryption.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @result (OUTPUT - decrypted password) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DecryptPassword is a utility procedure that converts an encrypted password (stored as varbinary(128)) back to its plaintext nvarchar(50) form. It opens the SSN_Key_Password symmetric key and uses DecryptByKey to perform the decryption.

This procedure is called by IsPasswordExpired to check the current password against the user-provided password during expiration validation. It provides a reusable decryption interface so that the symmetric key opening logic doesn't need to be duplicated across procedures.

The procedure has no table dependencies - it purely operates on the provided encrypted value using SQL Server's built-in encryption functions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The procedure is a single-purpose decryption wrapper.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Password | varbinary(128) (IN) | NO | - | CODE-BACKED | The encrypted password value to decrypt. Typically read from dbo.tblaff_User.EncryptedLoginPassword. |
| 2 | @result | nvarchar(50) (OUTPUT) | YES | - | CODE-BACKED | The decrypted plaintext password. NULL if decryption fails (wrong key or corrupted data). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | SSN_Key_Password | Symmetric Key | Opens for decryption |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.IsPasswordExpired | @encryptPassword | EXEC call | Called to decrypt stored password for expiration check |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no table/view dependencies. It uses the SSN_Key_Password symmetric key.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| SSN_Key_Password | Symmetric Key (DB-level) | Opened for password decryption |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.IsPasswordExpired | Stored Procedure | Calls to decrypt stored password for comparison |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Decrypt a stored password
```sql
DECLARE @result NVARCHAR(50)
DECLARE @enc VARBINARY(128)
SELECT @enc = EncryptedLoginPassword FROM dbo.tblaff_User WITH (NOLOCK) WHERE UserID = 1
EXEC fiktivo.DecryptPassword @enc, @result OUTPUT
SELECT @result AS DecryptedPassword
```

### 8.2 Verify decryption roundtrip
```sql
DECLARE @encrypted VARBINARY(128), @decrypted NVARCHAR(50)
EXEC fiktivo.EncryptPassword 'TestPassword', @encrypted OUTPUT
EXEC fiktivo.DecryptPassword @encrypted, @decrypted OUTPUT
SELECT @decrypted AS ShouldBeTestPassword
```

### 8.3 Check if decryption works for a user
```sql
DECLARE @enc VARBINARY(128), @result NVARCHAR(50)
SELECT TOP 1 @enc = EncryptedLoginPassword FROM dbo.tblaff_User WITH (NOLOCK) WHERE IsDeleted = 0
EXEC fiktivo.DecryptPassword @enc, @result OUTPUT
SELECT CASE WHEN @result IS NOT NULL THEN 'Decryption OK' ELSE 'Decryption Failed' END AS Status
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.DecryptPassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.DecryptPassword.sql*
