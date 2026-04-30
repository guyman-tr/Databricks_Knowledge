# Customer.SetEmailVerified

> Sets a customer's email verification status and provider in dbo.Real_Customer - called after successful email verification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE dbo.Real_Customer SET IsEmailVerified + EmailVerificationProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetEmailVerified updates a customer's email verification status after they complete the email verification process. It sets both the verified flag (IsEmailVerified) and which third-party provider performed the verification (EmailVerificationProviderID). The @Verified parameter defaults to 1 (verified), allowing the procedure to also be used for un-verification if needed.

Added Sep 2020: EmailVerificationProviderID parameter to track which provider verified the email (MIMOPS-3213 era).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple UPDATE of two columns.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @Verified | bit | YES | 1 | CODE-BACKED | Verification status: 1=verified (default), 0=unverified. |
| 3 | @EmailVerificationProviderID | int | YES | NULL | CODE-BACKED | Which provider verified the email. FK to Dictionary.EmailVerificationProvider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | UPDATE | Sets verification flags |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Email verification completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetEmailVerified (procedure)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Email verification service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Mark email as verified
```sql
EXEC Customer.SetEmailVerified @gcid=12345, @Verified=1, @EmailVerificationProviderID=2
```

### 8.2 Mark email as unverified
```sql
EXEC Customer.SetEmailVerified @gcid=12345, @Verified=0
```

### 8.3 Check verification status
```sql
SELECT GCID, IsEmailVerified, EmailVerificationProviderID
FROM dbo.Real_Customer WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.SetEmailVerified | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.SetEmailVerified.sql*
