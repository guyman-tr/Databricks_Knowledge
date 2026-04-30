# Customer.InsertEmailVerificationToken

> Stores a new email verification token for a customer with its issued timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Real_EmailVerificationTokens |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertEmailVerificationToken creates a new email verification token record. When a customer needs to verify their email (during registration or email change), the system generates a unique token and stores it with a timestamp. The customer receives the token via email and must present it to verify ownership.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple INSERT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @token | varchar(50) | NO | - | CODE-BACKED | Unique verification token string. |
| 3 | @issuedOn | datetime | NO | - | CODE-BACKED | When the token was generated. Used for expiry checking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Real_EmailVerificationTokens | INSERT | Token storage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Email verification flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertEmailVerificationToken (procedure)
+-- dbo.Real_EmailVerificationTokens (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_EmailVerificationTokens | Table | INSERT INTO |

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

### 8.1 Insert a verification token
```sql
EXEC Customer.InsertEmailVerificationToken @gcid=12345, @token='abc123', @issuedOn='2026-04-12T10:00:00'
```

### 8.2 Verify token was stored
```sql
SELECT * FROM dbo.Real_EmailVerificationTokens WITH (NOLOCK)
WHERE GCID = 12345 AND Token = 'abc123'
```

### 8.3 Read token back
```sql
EXEC Customer.GetVerificationTokenIssuedTime @gcid=12345, @token='abc123'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.InsertEmailVerificationToken | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.InsertEmailVerificationToken.sql*
