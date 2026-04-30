# Customer.GetEmailVerificationProvider

> Returns the email verification provider ID for a customer, indicating which third-party service verified their email address.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns EmailVerificationProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetEmailVerificationProvider retrieves the identifier of the third-party service that was used to verify a customer's email address. Different verification providers may be used depending on the customer's region, regulation, or onboarding flow.

This procedure was created in January 2021 as part of MIMOPS-3213 to support multiple email verification providers. The system needs to know which provider verified the email to determine applicable verification rules and to route re-verification requests to the correct provider.

The procedure performs a simple read from dbo.Real_Customer where the EmailVerificationProviderID is stored.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-value lookup.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID to look up the email verification provider for. |
| 2 | EmailVerificationProviderID (output) | int | YES | - | CODE-BACKED | Identifies which third-party email verification service verified this customer's email. FK to Dictionary.EmailVerificationProvider. See [Email Verification Provider](_glossary.md#email-verification-provider). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | Lookup | Reads EmailVerificationProviderID from customer record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called to determine which email verification provider to use |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetEmailVerificationProvider (procedure)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - reads EmailVerificationProviderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get email verification provider
```sql
EXEC Customer.GetEmailVerificationProvider @gcid = 12345
```

### 8.2 Direct query equivalent
```sql
SELECT EmailVerificationProviderID
FROM dbo.Real_Customer WITH (NOLOCK)
WHERE GCID = @gcid
```

### 8.3 Get provider with name
```sql
SELECT rc.EmailVerificationProviderID, evp.Name AS ProviderName
FROM dbo.Real_Customer rc WITH (NOLOCK)
LEFT JOIN Dictionary.EmailVerificationProvider evp WITH (NOLOCK) ON rc.EmailVerificationProviderID = evp.EmailVerificationProviderID
WHERE rc.GCID = @gcid
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetEmailVerificationProvider | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetEmailVerificationProvider.sql*
