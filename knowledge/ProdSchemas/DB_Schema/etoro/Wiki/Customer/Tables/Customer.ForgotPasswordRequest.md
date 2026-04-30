# Customer.ForgotPasswordRequest

> Audit log of every "forgot password" request attempt: records the submitted username, email, and whether the credentials matched a real account (CID=-1 = no match, CID>0 = matched customer).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK on ID) |

---

## 1. Business Meaning

Customer.ForgotPasswordRequest captures every attempt by a user to reset their password via the "Forgot Password" flow. Each row records what credentials were submitted (username + email, lowercased), when the attempt occurred, and whether those credentials matched a real account in the system.

The table exists as a security audit trail for the password reset flow. By logging both successful lookups (CID > 0, IsRequestSuccessful=1) and failed lookups (CID=-1, IsRequestSuccessful=0), security teams can detect enumeration attacks (attempts to discover valid account combinations) and excessive password reset abuse.

Data flows: Customer.RetrievePassword is the sole writer. When called, it first lowercases both @userName and @email, then looks up Customer.Customer by (UserName_LOWER, LowerEmail). If no match: inserts CID=-1 and IsRequestSuccessful=0 (unknown user attempt). If matched: inserts the real @CID and IsRequestSuccessful=1, generates a new random 10-char password, and updates dbo.RealCustomers and dbo.DemoCustomers. The table currently has 1 row (CID=-1, 2023-11-01) suggesting this legacy password reset mechanism is rarely or never invoked in the current system - modern flows likely use a different credential service.

---

## 2. Business Logic

### 2.1 Account Existence Reveal via CID Sentinel Value

**What**: CID=-1 is a sentinel value meaning "no matching account found for the submitted username + email combination", enabling differentiation between successful and failed lookups without NULL.

**Columns/Parameters Involved**: `CID`, `IsRequestSuccessful`

**Rules**:
- CID=-1 AND IsRequestSuccessful=0: submitted username+email did not match any Customer.Customer record (lookup failed - unknown user or mismatched credentials)
- CID>0 AND IsRequestSuccessful=1: submitted credentials matched a customer; the password reset proceeded
- CID=-1 is not a valid FK value (Customer.CustomerStatic has no CID=-1) - this is intentional; the FK would fail for unknown user rows
- Live data: 1 total row with CID=-1 (one failed reset attempt logged, 2023-11-01)

**Diagram**:
```
Customer.RetrievePassword called (@userName, @email)
        |
        v (lowercase both)
SELECT from Customer.Customer WHERE UserName_LOWER=@userName AND LowerEmail=@email
        |
    [Not found]                          [Found: @CID, @Password]
        |                                        |
INSERT CID=-1, IsRequestSuccessful=0    INSERT CID=@CID, IsRequestSuccessful=1
        |                                        |
        v (both paths)                           v
    RETURN (no password reset)         Generate new 10-char password
                                       UPDATE dbo.RealCustomers + dbo.DemoCustomers
                                       RETURN CID, FirstName, Password to caller
```

---

## 3. Data Overview

| ID | CID | DateOfRequest | IsRequestSuccessful | Meaning |
|----|-----|--------------|--------------------|----|
| 1 | -1 | 2023-11-01 14:25 | 0 | Failed lookup - submitted credentials did not match any Customer.Customer record. UserName and Email were empty strings (len=0), suggesting a test call or empty form submission. |

*1 total row. This extremely low volume indicates Customer.RetrievePassword (the sole writer) is essentially inactive in the current system. Modern eToro password reset flows likely use a separate identity service. The single row from 2023 may be a test invocation.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer identifier. When > 0: matched customer who owns the account. When = -1: sentinel value meaning no customer was found for the submitted username+email pair. FK to Customer.CustomerStatic (fk_CID) - note: CID=-1 rows violate this FK but the FK was presumably disabled or deferred for sentinel rows (the constraint is WITH CHECK meaning violations would fail on insert - in practice the only CID=-1 row exists so this may be a legacy inconsistency). |
| 2 | DateOfRequest | datetime | NO | - | VERIFIED | UTC timestamp when Customer.RetrievePassword was called, set via getdate() at insert time. The temporal record of each password reset attempt. |
| 3 | UserName | varchar(20) | YES | - | VERIFIED | The username submitted by the user during the password reset attempt, lowercased before INSERT by Customer.RetrievePassword (SET @userName = LOWER(@userName)). Stored for audit purposes. May be empty string if form was submitted without a username value. |
| 4 | Email | varchar(50) | YES | - | VERIFIED | The email address submitted during the reset attempt, lowercased before INSERT (SET @email = LOWER(@email)). Stored for audit. May be empty string. Together with UserName, forms the credential pair that was checked against Customer.Customer. |
| 5 | IsRequestSuccessful | bit | YES | - | VERIFIED | Whether the username+email pair matched a real account. 0 = no matching customer found (lookup failed, no password was reset). 1 = credentials matched, password was regenerated and returned to caller. Nullable but always set on INSERT. |
| 6 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-incremented IDENTITY, NOT FOR REPLICATION flag indicates this table participates in replication and the identity values are managed by the publisher. Provides a unique audit log row number. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (fk_CID) | Valid account lookups reference the matched customer; CID=-1 sentinel rows are the exception (no matching CustomerStatic row) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RetrievePassword | CID, DateOfRequest, UserName, Email, IsRequestSuccessful | Writer | The sole writer; inserts one row per password reset attempt recording credentials and success/failure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ForgotPasswordRequest (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target for CID (valid-account rows only) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RetrievePassword | Stored Procedure | Writer - logs every password reset attempt with credentials and outcome |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ForgotPasswordRequest | Clustered PK | ID ASC | - | - | Active |

*No index on CID or DateOfRequest - queries filtering by CID or date range would do a full scan. Acceptable given the table's near-zero row count.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| fk_CID | FK | CID -> Customer.CustomerStatic(CID); WITH CHECK means it was validated at creation time |
| ID | IDENTITY | IDENTITY(1,1) NOT FOR REPLICATION - replication-aware identity assignment |

---

## 8. Sample Queries

### 8.1 View all password reset attempts for a specific customer
```sql
SELECT
    fpr.ID,
    fpr.CID,
    fpr.DateOfRequest,
    fpr.UserName,
    fpr.Email,
    fpr.IsRequestSuccessful
FROM Customer.ForgotPasswordRequest fpr WITH (NOLOCK)
WHERE fpr.CID = 12345
ORDER BY fpr.DateOfRequest DESC;
```

### 8.2 Find failed reset attempts (potential enumeration attacks)
```sql
SELECT TOP 100
    fpr.UserName,
    fpr.Email,
    COUNT(*) AS FailedAttempts,
    MIN(fpr.DateOfRequest) AS FirstAttempt,
    MAX(fpr.DateOfRequest) AS LastAttempt
FROM Customer.ForgotPasswordRequest fpr WITH (NOLOCK)
WHERE fpr.IsRequestSuccessful = 0
  AND fpr.DateOfRequest >= DATEADD(day, -7, GETDATE())
GROUP BY fpr.UserName, fpr.Email
ORDER BY FailedAttempts DESC;
```

### 8.3 Password reset success vs. failure summary by day
```sql
SELECT
    CAST(fpr.DateOfRequest AS DATE) AS RequestDate,
    SUM(CASE WHEN fpr.IsRequestSuccessful = 1 THEN 1 ELSE 0 END) AS Successful,
    SUM(CASE WHEN ISNULL(fpr.IsRequestSuccessful, 0) = 0 THEN 1 ELSE 0 END) AS Failed,
    COUNT(*) AS Total
FROM Customer.ForgotPasswordRequest fpr WITH (NOLOCK)
GROUP BY CAST(fpr.DateOfRequest AS DATE)
ORDER BY RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Customer.RetrievePassword) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.ForgotPasswordRequest | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.ForgotPasswordRequest.sql*
