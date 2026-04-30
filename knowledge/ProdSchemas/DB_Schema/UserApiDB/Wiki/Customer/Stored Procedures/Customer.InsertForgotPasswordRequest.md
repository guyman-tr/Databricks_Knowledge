# Customer.InsertForgotPasswordRequest

> Records a forgot-password request for audit tracking - logs the CID, username, email, timestamp, and whether the request was successful.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Real_ForgotPasswordRequest |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertForgotPasswordRequest logs a password reset request for security auditing. Every time a user requests a password reset, this procedure records who requested it, when, and whether the request was processed successfully. This supports security investigations (detecting brute-force password reset attempts) and compliance auditing.

Note: The @isReal parameter exists in the signature but both branches (real=1, real=0) insert into the same table (dbo.Real_ForgotPasswordRequest), making the flag currently unused in practice.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple audit INSERT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | CODE-BACKED | Customer ID (CID). |
| 2 | @requestDate | datetime | NO | - | CODE-BACKED | When the reset was requested. |
| 3 | @userName | varchar(50) | NO | - | CODE-BACKED | Username of the requester. |
| 4 | @email | varchar(150) | NO | - | CODE-BACKED | Email address used for the request. |
| 5 | @isRequestSuccessful | bit | NO | - | CODE-BACKED | Whether the password reset was successfully processed. |
| 6 | @isReal | bit | NO | - | CODE-BACKED | Real (1) vs demo (0) account flag. Currently both paths insert into the same table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Real_ForgotPasswordRequest | INSERT | Audit log table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Password reset flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertForgotPasswordRequest (procedure)
+-- dbo.Real_ForgotPasswordRequest (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_ForgotPasswordRequest | Table | INSERT INTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Password reset service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Log a password reset request
```sql
EXEC Customer.InsertForgotPasswordRequest @cid=100001, @requestDate=GETUTCDATE(),
    @userName='johndoe', @email='john@example.com', @isRequestSuccessful=1, @isReal=1
```

### 8.2 Check recent reset requests
```sql
SELECT * FROM dbo.Real_ForgotPasswordRequest WITH (NOLOCK)
WHERE CID = 100001 ORDER BY DateOfRequest DESC
```

### 8.3 Count failed requests in last hour
```sql
SELECT COUNT(*) FROM dbo.Real_ForgotPasswordRequest WITH (NOLOCK)
WHERE CID = 100001 AND IsRequestSuccessful = 0
    AND DateOfRequest > DATEADD(HOUR, -1, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.InsertForgotPasswordRequest | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.InsertForgotPasswordRequest.sql*
