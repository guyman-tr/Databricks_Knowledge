# fiktivo.CheckPassword

> Validates an affiliate portal user's credentials by decrypting the stored encrypted password and comparing it to the provided password. Returns the UserID on success.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure authenticates admin users of the affiliate management portal. Given a login name and plaintext password, it decrypts the stored encrypted password from dbo.tblaff_User using the SSN_Key_Password symmetric key, compares it to the provided password (case-sensitive via SQL_Latin1_General_CP1_CS_AS collation), and returns the UserID if they match.

This is used during affiliate portal login. If credentials are invalid, @UserID remains NULL (the procedure does not explicitly return 0 for failure - the caller must check for NULL). Only non-deleted users (IsDeleted = 0) are considered.

---

## 2. Business Logic

### 2.1 Encrypted Password Authentication

**What**: Case-sensitive password comparison using symmetric key decryption.

**Columns/Parameters Involved**: `@LoginName`, `@Password`, `@UserID`

**Rules**:
- Step 1: Decrypt EncryptedLoginPassword from dbo.tblaff_User WHERE LoginName matches (case-sensitive) AND IsDeleted=0
- Step 2: Compare decrypted password to @Password
- Step 3: If match, set @UserID from the same user record
- Case-sensitive matching via COLLATE SQL_Latin1_General_CP1_CS_AS
- Only active users (IsDeleted=0) can authenticate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LoginName (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | Admin user login name. Matched case-sensitively against dbo.tblaff_User.LoginName. |
| 2 | @Password (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | Plaintext password to verify. Compared against the decrypted EncryptedLoginPassword from tblaff_User. |
| 3 | @UserID (OUT) | INTEGER | YES | NULL | CODE-BACKED | Authenticated user's ID on success. Remains NULL if authentication fails (wrong password, user not found, or user deleted). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | dbo.tblaff_User | Table read | Reads EncryptedLoginPassword and UserID for authentication. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.CheckPassword (procedure)
    └── dbo.tblaff_User (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_User | Table | SELECT for password verification and UserID retrieval |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Authenticate a user
```sql
DECLARE @uid INT
EXEC fiktivo.CheckPassword @LoginName = N'admin', @Password = N'test123', @UserID = @uid OUTPUT
SELECT CASE WHEN @uid IS NOT NULL THEN 'Authenticated: UserID=' + CAST(@uid AS VARCHAR) ELSE 'Failed' END
```

### 8.2 Check if user exists and is active
```sql
SELECT UserID, LoginName, IsDeleted
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE LoginName = 'admin' COLLATE SQL_Latin1_General_CP1_CS_AS
AND IsDeleted = 0
```

### 8.3 Verify encrypted password column exists
```sql
SELECT UserID, LoginName, EncryptedLoginPassword
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE EncryptedLoginPassword IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.CheckPassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.CheckPassword.sql*
