# Dictionary.EmailVerificationProvider

## 1. Business Meaning

### What It Is
A lookup table identifying the authentication provider through which a customer's email address was verified — whether through eToro's own email verification flow or via social login (Facebook, Google, Apple, UAEPass).

### Why It Exists
Customers can register and verify their identity through multiple channels. When a customer logs in via a social provider (Google, Facebook, Apple), their email is considered verified by that provider without requiring a separate eToro verification email. This table tracks which method was used, relevant for security auditing and re-verification decisions.

### How It's Used
Referenced by `Customer.CustomerStatic.EmailVerificationProviderID` and `Customer.ContactUserInfo` (UserApiDB). Set during registration or social login binding via `Customer.UpdateContactUserInfo` and `Customer.SetEmailVerified`. Read by `Customer.GetContactInfo`, `Customer.GetContactInfoByEmail`, `Customer.GetEmailVerificationProvider`, and various aggregated info procedures.

---

## 2. Business Logic

### Provider Types

| ID | Provider | Verification Method |
|----|----------|-------------------|
| 1 | **eToro** | Traditional email verification (confirmation link sent to customer email) |
| 3 | **Facebook** | Email verified via Facebook OAuth — Facebook confirms the email ownership |
| 5 | **Google** | Email verified via Google OAuth — Google confirms the email ownership |
| 6 | **Apple** | Email verified via Apple Sign In — Apple confirms the email ownership |
| 7 | **UAEPass** | Email verified via UAE national digital identity platform |

> **Note**: IDs 2 and 4 are not used (gaps in sequence suggest removed or reserved providers).

### Social Login Verification Flow
When a customer authenticates via a social provider, the provider confirms email ownership as part of the OAuth flow. This is equivalent to email verification — the customer does not need to click a separate confirmation link.

---

## 3. Data Overview

| EmailVerificationProviderID | EmailVerificationProviderName |
|----------------------------|-------------------------------|
| 1 | eToro |
| 3 | Facebook |
| 5 | Google |
| 6 | Apple |
| 7 | UAEPass |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **EmailVerificationProviderID** | `int` | NO | Primary key. Provider identifier. | `MCP` |
| **EmailVerificationProviderName** | `varchar(50)` | YES | Provider name. Nullable but all current rows populated. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | Relationship |
|-------|--------|-------------|
| Customer.CustomerStatic (etoro) | EmailVerificationProviderID | Implicit FK — which provider verified the customer's email |
| Customer.ContactUserInfo (UserApiDB) | EmailVerificationProviderID | Implicit FK — same purpose in UserApiDB |
| History.Customer (etoro) | EmailVerificationProviderID | Historical record of verification provider |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `Customer.CustomerStatic` / `Customer.Customer` view — stores email verification source
- `Customer.UpdateContactUserInfo` — sets the provider when email is verified
- `Customer.SetEmailVerified` (UserApiDB) — records verification provider
- `Customer.GetContactInfo` / `GetContactInfoByEmail` (UserApiDB) — returns provider info
- `Customer.GetEmailVerificationProvider` (UserApiDB) — dedicated provider lookup
- `Customer.GetAggregatedInfoManyUsers` / `GetAggregatedInfoByGCID` (UserApiDB) — includes in aggregated data
- `Customer.CustomerSafty` view — includes in schema-bound view

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `EmailVerificationProviderID` (clustered, PK_Dictionary_EmailVerificationProvider) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 5 |
| **Identity** | No — manually assigned with gaps (1, 3, 5, 6, 7) |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all email verification providers
SELECT  EmailVerificationProviderID,
        EmailVerificationProviderName
FROM    Dictionary.EmailVerificationProvider WITH (NOLOCK)
ORDER BY EmailVerificationProviderID;

-- Count customers by verification provider
SELECT  evp.EmailVerificationProviderName AS Provider,
        COUNT(*)                          AS CustomerCount
FROM    Customer.CustomerStatic cs WITH (NOLOCK)
JOIN    Dictionary.EmailVerificationProvider evp WITH (NOLOCK)
        ON cs.EmailVerificationProviderID = evp.EmailVerificationProviderID
GROUP BY evp.EmailVerificationProviderName
ORDER BY CustomerCount DESC;

-- Find customers verified via social login
SELECT  cs.CustomerID,
        evp.EmailVerificationProviderName AS Provider
FROM    Customer.CustomerStatic cs WITH (NOLOCK)
JOIN    Dictionary.EmailVerificationProvider evp WITH (NOLOCK)
        ON cs.EmailVerificationProviderID = evp.EmailVerificationProviderID
WHERE   cs.EmailVerificationProviderID <> 1;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
