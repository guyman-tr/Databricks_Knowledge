# Dictionary.ElectronicIdentityCheck

## 1. Business Meaning

### What It Is
A lookup table defining the outcome levels of electronic identity verification checks — how many independent data sources confirmed a customer's identity.

### Why It Exists
Electronic identity verification works by cross-referencing customer information against external databases (credit agencies, electoral rolls, utility records, etc.). The number of matching sources determines the verification strength. This table classifies the outcome from zero matches to two-source confirmation.

### How It's Used
Referenced by `BackOffice.ElectronicIdentityCheck.ElectronicIdentityCheckID` (implicit FK) and read by `BackOffice.GetElectronicIdentityCheck`, `BackOffice.SetElectronicIdentityCheck`, `BackOffice.GetCustomerByCID`, and multiple UserApiDB aggregation procedures.

---

## 2. Business Logic

### Verification Outcomes
```
None (0) ──────── No verification attempted or provider returned no data
    │
One Source (1) ── Identity confirmed by 1 external data source
    │
Two Sources (2) ─ Identity confirmed by 2 independent sources (strongest)
    │
No Match (3) ──── Verification attempted but no sources could confirm identity
```

- **One Source** and **Two Sources** represent successful identity confirmation at different confidence levels
- **No Match** is a failed verification — the identity could not be confirmed against any database
- Higher source count = stronger KYC evidence for regulatory compliance

---

## 3. Data Overview

| ElectronicIdentityCheckID | Name |
|--------------------------|------|
| 0 | None |
| 1 | One Source |
| 2 | Two Sources |
| 3 | No Match |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **ElectronicIdentityCheckID** | `int` | NO | Primary key. Verification outcome level (0=None, 1=One Source, 2=Two Sources, 3=No Match). | `MCP` |
| **Name** | `varchar(30)` | YES | Outcome label. Nullable but all current rows populated. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | Relationship |
|-------|--------|-------------|
| BackOffice.ElectronicIdentityCheck | ElectronicIdentityCheckID | Implicit FK — stores EID check outcome per customer |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `BackOffice.ElectronicIdentityCheck` — fact table storing per-customer EID check results
- `BackOffice.GetElectronicIdentityCheck` — reads EID check results with this lookup
- `BackOffice.SetElectronicIdentityCheck` — writes EID check outcomes
- `BackOffice.GetCustomerByCID` — includes EID check level in customer profile
- `Customer.GetRiskUserInfo` (etoro) — risk assessment includes EID check level
- `Customer.GetManyRiskUserInfo` (UserApiDB) — batch risk user info
- Various `Customer.GetSingleAggregatedInfo` / `GetManyAggregatedInfo` variants (UserApiDB)

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `ElectronicIdentityCheckID` (clustered, PK_DictionaryElectronicIdentityCheck) |
| **Filegroup** | MAIN (not DICTIONARY — legacy placement) |
| **Row Count** | 4 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all EID check outcomes
SELECT  ElectronicIdentityCheckID,
        Name
FROM    Dictionary.ElectronicIdentityCheck WITH (NOLOCK)
ORDER BY ElectronicIdentityCheckID;

-- Count customers by verification level
SELECT  ec.Name             AS VerificationLevel,
        COUNT(*)            AS CustomerCount
FROM    BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
JOIN    Dictionary.ElectronicIdentityCheck ec WITH (NOLOCK)
        ON eic.ElectronicIdentityCheckID = ec.ElectronicIdentityCheckID
GROUP BY ec.Name
ORDER BY ec.ElectronicIdentityCheckID;

-- Find customers with no identity match
SELECT  eic.CustomerID
FROM    BackOffice.ElectronicIdentityCheck eic WITH (NOLOCK)
WHERE   eic.ElectronicIdentityCheckID = 3;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
