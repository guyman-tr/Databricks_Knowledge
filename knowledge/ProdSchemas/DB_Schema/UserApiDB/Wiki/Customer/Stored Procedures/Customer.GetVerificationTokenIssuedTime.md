# Customer.GetVerificationTokenIssuedTime

> Returns the issued timestamp of an email verification token - used to check token age/validity.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns IssuedOn for a GCID + token |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetVerificationTokenIssuedTime retrieves when an email verification token was issued. This is used to validate token age - tokens older than a certain threshold are considered expired and the user must request a new one.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple lookup by GCID + Token.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @token | varchar(50) | NO | - | CODE-BACKED | The verification token string. |
| 3 | IssuedOn (output) | datetime | YES | - | CODE-BACKED | When the token was issued. NULL if token not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid, @token | dbo.Real_EmailVerificationTokens | FROM | Token data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Token validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetVerificationTokenIssuedTime (procedure)
+-- dbo.Real_EmailVerificationTokens (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_EmailVerificationTokens | Table | FROM - token lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Email verification flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check token age
```sql
EXEC Customer.GetVerificationTokenIssuedTime @gcid=12345, @token='abc123def456'
```

### 8.2 Direct query
```sql
SELECT IssuedOn FROM dbo.Real_EmailVerificationTokens WITH (NOLOCK)
WHERE GCID = @gcid AND Token = @token
```

### 8.3 Check if token is older than 24 hours
```sql
SELECT CASE WHEN IssuedOn < DATEADD(HOUR, -24, GETUTCDATE()) THEN 1 ELSE 0 END AS IsExpired
FROM dbo.Real_EmailVerificationTokens WITH (NOLOCK)
WHERE GCID = @gcid AND Token = @token
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetVerificationTokenIssuedTime | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetVerificationTokenIssuedTime.sql*
