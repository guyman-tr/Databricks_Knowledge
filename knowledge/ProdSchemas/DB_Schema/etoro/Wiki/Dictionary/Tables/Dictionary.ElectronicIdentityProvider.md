# Dictionary.ElectronicIdentityProvider

## 1. Business Meaning

### What It Is
A lookup table identifying the third-party vendors that perform electronic identity verification checks for eToro customers.

### Why It Exists
eToro uses multiple identity verification providers across different markets and regulatory jurisdictions. This table catalogs which provider performed a given verification, enabling audit trails and provider-specific result interpretation.

### How It's Used
Referenced by `BackOffice.ElectronicIdentityCheck.ElectronicIdentityProviderID` (implicit FK). Set when EID results are recorded via `BackOffice.SetElectronicIdentityCheck` and read by `BackOffice.GetElectronicIdentityCheck`.

---

## 2. Business Logic

### Verification Providers

| ID | Provider | Description |
|----|----------|-------------|
| 1 | **GDC** | GDC (Global Data Consortium) — multinational identity verification network |
| 2 | **GB** | GB Group — UK-based identity data intelligence provider |
| 3 | **Au10tix** | Au10tix — ID document authentication and biometric verification platform |

Each provider specializes in different regions and verification methods. The provider used for a customer depends on their country of residence and the regulatory entity they fall under.

---

## 3. Data Overview

| ElectronicIdentityProviderID | Name |
|-----------------------------|------|
| 1 | GDC |
| 2 | GB |
| 3 | Au10tix |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **ElectronicIdentityProviderID** | `int` | NO | Primary key. Provider identifier. | `MCP` |
| **Name** | `varchar(30)` | YES | Provider name/abbreviation. Nullable but all current rows populated. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | Relationship |
|-------|--------|-------------|
| BackOffice.ElectronicIdentityCheck | ElectronicIdentityProviderID | Implicit FK — which provider performed the verification |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `BackOffice.ElectronicIdentityCheck` — stores which provider was used per customer
- `BackOffice.SetElectronicIdentityCheck` — records provider when writing EID results
- `BackOffice.GetElectronicIdentityCheck` — returns provider info in EID check queries

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `ElectronicIdentityProviderID` (clustered, PK_DictionaryElectronicIdentityProvider) |
| **Filegroup** | MAIN (not DICTIONARY — legacy placement) |
| **Row Count** | 3 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all EID verification providers
SELECT  ElectronicIdentityProviderID,
        Name
FROM    Dictionary.ElectronicIdentityProvider WITH (NOLOCK)
ORDER BY ElectronicIdentityProviderID;

-- Count verifications per provider
SELECT  ep.Name             AS Provider,
        COUNT(*)            AS VerificationCount
FROM    BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
JOIN    Dictionary.ElectronicIdentityProvider ep WITH (NOLOCK)
        ON eic.ElectronicIdentityProviderID = ep.ElectronicIdentityProviderID
GROUP BY ep.Name
ORDER BY VerificationCount DESC;

-- Get verification results for a specific provider
SELECT  eic.CustomerID,
        ec.Name             AS CheckResult
FROM    BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
JOIN    Dictionary.ElectronicIdentityCheck ec WITH (NOLOCK)
        ON eic.ElectronicIdentityCheckID = ec.ElectronicIdentityCheckID
WHERE   eic.ElectronicIdentityProviderID = 3;  -- Au10tix
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.0 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
