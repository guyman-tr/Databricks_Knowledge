# fiktivo.CheckPassword

> Stored procedure that validates an affiliate user's login credentials by decrypting the stored password using a symmetric encryption key and comparing it to the provided password.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserID (OUTPUT - returns matched user ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CheckPassword authenticates affiliate users during login. It decrypts the stored encrypted password from dbo.tblaff_User using a symmetric key (SSN_Key_Password) and compares it against the provided plaintext password. If they match, it returns the UserID; if not, it returns NULL.

This procedure is part of the affiliate portal authentication flow. The password encryption uses SQL Server's built-in symmetric key encryption (DecryptByKey) with a hardcoded decryption password. The use of COLLATE SQL_Latin1_General_CP1_CS_AS ensures case-sensitive login name matching.

The procedure reads from dbo.tblaff_User (cross-schema) with NOLOCK hints for non-blocking reads during authentication.

---

## 2. Business Logic

### 2.1 Password Decryption and Validation

**What**: Decrypts stored password using symmetric key and performs case-sensitive comparison.

**Columns/Parameters Involved**: `@LoginName`, `@Password`, `@UserID`

**Rules**:
- Opens symmetric key SSN_Key_Password with a hardcoded decryption password
- Decrypts EncryptedLoginPassword from tblaff_User for the given LoginName
- LoginName comparison uses SQL_Latin1_General_CP1_CS_AS collation (case-sensitive)
- Only non-deleted users checked (IsDeleted = 0)
- If decrypted password matches @Password, sets @UserID to the matching user's ID
- If no match, @UserID remains NULL

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LoginName | NVARCHAR(50) (IN) | NO | - | CODE-BACKED | Affiliate user's login name. Compared case-sensitively against tblaff_User.LoginName using SQL_Latin1_General_CP1_CS_AS collation. |
| 2 | @Password | NVARCHAR(50) (IN) | NO | - | CODE-BACKED | Plaintext password to validate. Compared against the decrypted version of EncryptedLoginPassword from tblaff_User. |
| 3 | @UserID | INTEGER (OUTPUT) | YES | NULL | CODE-BACKED | Returns the authenticated user's UserID if credentials are valid. Remains NULL if authentication fails (wrong password, user not found, or user is deleted). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LoginName, @UserID | dbo.tblaff_User | SELECT | Reads EncryptedLoginPassword and UserID for authentication |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.CheckPassword (procedure)
└── dbo.tblaff_User (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_User | Table (cross-schema) | SELECT for password decryption and UserID retrieval |
| SSN_Key_Password | Symmetric Key (DB-level) | Opened for password decryption |

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

### 8.1 Authenticate an affiliate user
```sql
DECLARE @UserID INT
EXEC fiktivo.CheckPassword @LoginName = 'admin', @Password = 'secret', @UserID = @UserID OUTPUT
SELECT @UserID AS AuthenticatedUserID
```

### 8.2 Check if a specific user exists and is active
```sql
SELECT UserID, LoginName, IsDeleted
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE LoginName = 'admin' COLLATE SQL_Latin1_General_CP1_CS_AS
  AND IsDeleted = 0
```

### 8.3 List users with encrypted passwords
```sql
SELECT UserID, LoginName, EncryptedLoginPassword
FROM dbo.tblaff_User WITH (NOLOCK)
WHERE IsDeleted = 0 AND EncryptedLoginPassword IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.CheckPassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.CheckPassword.sql*
