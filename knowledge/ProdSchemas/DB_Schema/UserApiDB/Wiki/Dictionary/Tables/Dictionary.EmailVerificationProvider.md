# Dictionary.EmailVerificationProvider

> Lookup table defining identity providers used to verify user email addresses during registration, including direct email and social login OAuth providers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | EmailVerificationProviderID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.EmailVerificationProvider identifies the method or third-party provider through which a user's email address was verified. This supports both direct email verification (eToro sends a confirmation link) and social login verification (email implicitly verified via OAuth with Facebook, Google, or Apple).

Email verification is a mandatory registration step. The provider tells the system whether the user verified via a traditional email link or through a trusted social identity provider. Social login providers are considered pre-verified because OAuth guarantees the user controls the email. This distinction matters for security auditing and fraud analysis.

The provider is recorded during registration when the user completes email verification. Users who register via social login skip the email verification step since the OAuth provider has already confirmed email ownership.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| EmailVerificationProviderID | EmailVerificationProviderName | Meaning |
|---|---|---|
| 1 | eToro | User verified email via eToro's own confirmation link sent to the email address |
| 3 | Facebook | Email verified through Facebook OAuth - user registered via Facebook social login |
| 5 | Google | Email verified through Google OAuth - user registered via Google social login |
| 6 | Apple | Email verified through Apple Sign-In - user registered via Apple ID |

*Note: IDs 2 and 4 are absent - likely deprecated providers removed from the system.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EmailVerificationProviderID | int | NO | - | CODE-BACKED | Primary key. Provider identifier: 1=eToro (direct email), 3=Facebook, 5=Google, 6=Apple. IDs 2 and 4 are unused/deprecated. See [Email Verification Provider](_glossary.md#email-verification-provider). |
| 2 | EmailVerificationProviderName | varchar(50) | YES | - | CODE-BACKED | Provider display name. Used in admin tools and audit logs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user tables | EmailVerificationProviderID | Lookup | Records which provider verified each user's email |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | EmailVerificationProviderID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all email verification providers
```sql
SELECT EmailVerificationProviderID, EmailVerificationProviderName
FROM Dictionary.EmailVerificationProvider WITH (NOLOCK)
ORDER BY EmailVerificationProviderID
```

### 8.2 Find users by verification method
```sql
SELECT u.CustomerID, evp.EmailVerificationProviderName
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.EmailVerificationProvider evp WITH (NOLOCK) ON u.EmailVerificationProviderID = evp.EmailVerificationProviderID
WHERE evp.EmailVerificationProviderName = 'Google'
```

### 8.3 Registration method distribution
```sql
SELECT evp.EmailVerificationProviderName, COUNT(*) AS UserCount
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.EmailVerificationProvider evp WITH (NOLOCK) ON u.EmailVerificationProviderID = evp.EmailVerificationProviderID
GROUP BY evp.EmailVerificationProviderName
ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.EmailVerificationProvider | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.EmailVerificationProvider.sql*
