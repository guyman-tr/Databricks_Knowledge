# Customer.RetrievePassword

> Forgot-password handler: validates username/email match in Customer.Customer, logs the request to ForgotPasswordRequest (success or failure), generates a new 10-character random password, updates it in dbo.RealCustomers and dbo.DemoCustomers, and returns CID, FirstName, and new Password to the caller.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @userName + @email - must match existing Customer.Customer record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RetrievePassword` implements the "forgot password" flow. Given a username and email, it verifies the customer exists (matching by `UserName_LOWER` and `LowerEmail` - both pre-computed lowercase columns), generates a new random password, updates it in both the real and demo customer tables, logs the attempt to `Customer.ForgotPasswordRequest`, and returns the new password to the caller for delivery (typically by email).

The procedure logs both successful and failed attempts:
- Successful match: `ForgotPasswordRequest` row with the customer's real CID and `IsRequestSuccessful=1`.
- No match: `ForgotPasswordRequest` row with `CID=-1` and `IsRequestSuccessful=0`.

Password generation uses `NEWID()` to produce a random 10-character lowercase string: first 8 chars from a GUID slice, last 2 chars from another GUID slice. The new password is written directly to `dbo.RealCustomers` and `dbo.DemoCustomers` (cross-DB tables in the trading environment) keyed by GCID.

**Note**: This procedure stores and returns a plain-text password, consistent with the historical eToro architecture (legacy comment: "Case 7.plain_text_passwords"). Modern authentication flows use the STS system instead.

---

## 2. Business Logic

### 2.1 Username/Email Validation

**What**: Looks up the customer by the lowercase-indexed username and email columns.

**Rules**:
- SET @email = LOWER(@email), SET @userName = LOWER(@userName) (client-side normalization before the query).
- SELECT from Customer.Customer WHERE `UserName_LOWER = @userName AND LowerEmail = @email`.
- If no match: @CID = NULL.

### 2.2 Audit Logging (Both Outcomes)

**What**: Records every forgot-password attempt regardless of outcome.

**Rules**:
- No match: INSERT ForgotPasswordRequest (CID=-1, DateOfRequest=GETDATE(), UserName, Email, IsRequestSuccessful=0).
- Match found: INSERT ForgotPasswordRequest (CID=@CID, DateOfRequest=GETDATE(), UserName, Email, IsRequestSuccessful=1).

### 2.3 New Password Generation and Distribution

**What**: Generates a 10-char random password and writes it to both customer environments.

**Rules**:
- Password generation: `LOWER(LEFT(CONVERT(VARCHAR(MAX), NEWID()), 8) + RIGHT(CONVERT(VARCHAR(MAX), NEWID()), 2))` - two separate NEWID() calls.
- UPDATE `dbo.RealCustomers SET Password = @Password WHERE GCID = @GCID AND @GCID IS NOT NULL`.
- UPDATE `dbo.DemoCustomers SET Password = @Password WHERE GCID = @GCID AND @GCID IS NOT NULL`.
- If @GCID is NULL, no update occurs (GCID guard prevents orphan updates).

### 2.4 Return Value

**What**: Returns the result of the forgot-password flow to the caller.

**Rules**:
- SELECT @CID AS CID, @FirstName AS FirstName, CASE WHEN @CID IS NULL THEN NULL ELSE @Password END AS Password.
- Caller receives NULL password if the username/email was not found.

```
Normalize inputs: LOWER(@email), LOWER(@userName)
SELECT CID, FirstName, Password, GCID from Customer.Customer WHERE UserName_LOWER + LowerEmail
INSERT ForgotPasswordRequest (CID=-1/real, IsRequestSuccessful=0/1)
Generate new Password (10 char NEWID-based)
UPDATE dbo.RealCustomers SET Password WHERE GCID
UPDATE dbo.DemoCustomers SET Password WHERE GCID
SELECT CID, FirstName, Password (null if not found)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @userName | VARCHAR(50) | NO | - | CODE-BACKED | Username to look up; converted to LOWER before matching UserName_LOWER index. |
| 2 | @email | VARCHAR(200) | NO | - | CODE-BACKED | Email address to match; converted to LOWER before matching LowerEmail index. |

**Returned Result Set:**

| # | Column | Description |
|---|--------|-------------|
| 1 | CID | Customer's CID; NULL if username/email not found |
| 2 | FirstName | Customer's first name; NULL if not found |
| 3 | Password | New generated password; NULL if not found |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @userName + @email | Customer.Customer | READ | Validates username/email match; gets CID, FirstName, GCID |
| (log) | Customer.ForgotPasswordRequest | INSERT | Audit log of every attempt (success or failure) |
| (update) | dbo.RealCustomers | UPDATE (cross-DB) | Sets new password for real account |
| (update) | dbo.DemoCustomers | UPDATE (cross-DB) | Sets new password for demo account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Password recovery API | External | Caller | "Forgot Password" flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RetrievePassword (procedure)
├── Customer.Customer (view) [READ - username/email match]
├── Customer.ForgotPasswordRequest (table) [INSERT - audit log]
├── dbo.RealCustomers (cross-DB table) [UPDATE - new password]
└── dbo.DemoCustomers (cross-DB table) [UPDATE - new password]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | READ - UserName_LOWER + LowerEmail match |
| Customer.ForgotPasswordRequest | Table | INSERT - audit log (success + failure) |
| dbo.RealCustomers | Cross-DB Table | UPDATE - new password by GCID |
| dbo.DemoCustomers | Cross-DB Table | UPDATE - new password by GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Password recovery API | External | "Forgot password" endpoint |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Case-insensitive matching | Design | Uses pre-computed UserName_LOWER and LowerEmail columns (indexed) |
| GCID guard | Application | Cross-DB updates only execute if @GCID IS NOT NULL - prevents updating all records |
| Plain-text password | Legacy | Password generated and returned as plain text - historical architecture |
| Both environments updated | Design | Same password written to both RealCustomers and DemoCustomers atomically |

---

## 8. Sample Queries

### 8.1 Check forgot-password request history for a customer

```sql
SELECT TOP 20
    fpr.CID,
    fpr.UserName,
    fpr.Email,
    fpr.DateOfRequest,
    fpr.IsRequestSuccessful
FROM Customer.ForgotPasswordRequest fpr WITH (NOLOCK)
WHERE fpr.CID = 12345
ORDER BY fpr.DateOfRequest DESC
```

### 8.2 Count failed password requests (potential abuse detection)

```sql
SELECT TOP 20
    fpr.UserName,
    fpr.Email,
    COUNT(*) AS FailedAttempts,
    MAX(fpr.DateOfRequest) AS LastAttempt
FROM Customer.ForgotPasswordRequest fpr WITH (NOLOCK)
WHERE fpr.IsRequestSuccessful = 0
  AND fpr.DateOfRequest >= DATEADD(HOUR, -24, GETUTCDATE())
GROUP BY fpr.UserName, fpr.Email
ORDER BY FailedAttempts DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RetrievePassword | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RetrievePassword.sql*
