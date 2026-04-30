# Billing.FundingTypeRolloutWhiteList

> Whitelist companion to FundingTypeRolloutPercentage; specific customer IDs (CIDs) listed here always see the whitelisted payment method regardless of the rollout percentage setting. Currently empty (no active whitelisted customers).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | No primary key - clustered on FundingTypeID, unique on (CID, FundingTypeID) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 (clustered on FundingTypeID + unique nonclustered on CID, FundingTypeID) |

---

## 1. Business Meaning

`Billing.FundingTypeRolloutWhiteList` is the whitelist companion to `Billing.FundingTypeRolloutPercentage`. While the percentage table controls what fraction of all customers see a new payment method, this table allows specific customers (by CID) to be opted in unconditionally - bypassing the percentage gate.

This is the standard feature flag pattern:
- **Percentage** = what fraction of the general population sees the feature
- **WhiteList** = specific users (typically QA testers, internal employees, beta users) who always see it

The table is currently empty (0 rows) - no active whitelist customers. This aligns with FundingTypeRolloutPercentage showing FundingTypeID=38 at Percentage=0 (fully rolled back).

No stored procedures in the SSDT repo reference this table directly - read by application-layer services.

---

## 2. Business Logic

### 2.1 Whitelist Bypass Pattern

**What**: A CID in this table always sees the whitelisted FundingTypeID regardless of the Percentage setting.

**Columns/Parameters Involved**: `FundingTypeID`, `CID`

**Rules**:
```
Rollout eligibility check (application-layer):
  IF (CID, FundingTypeID) in FundingTypeRolloutWhiteList:
    -> ALWAYS show this payment method (bypass percentage gate)
  ELSE:
    -> Apply FundingTypeRolloutPercentage check

Use case: Add internal QA testers to WhiteList during pilot,
          then gradually increase Percentage for general users.
```

---

## 3. Data Overview

Table is currently empty (0 rows). When active, rows would list specific customer IDs who should always see a specific payment method under rollout control.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | VERIFIED | Payment method being whitelisted. Implicit FK to Dictionary.FundingType(FundingTypeID). No FK constraint. Part of the unique index (CID, FundingTypeID). |
| 2 | CID | int | NO | - | VERIFIED | Customer always granted access to this payment method. Implicit FK to Customer.CustomerStatic(CID). No FK constraint. Part of the unique index (CID, FundingTypeID) ensuring each customer appears at most once per payment method. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method being whitelisted |
| CID | Customer.CustomerStatic | Implicit | Customer granted unconditional access |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.FundingTypeRolloutPercentage | FundingTypeID | RELATED | Percentage controls general rollout; WhiteList bypasses it for specific CIDs |
| (application code) | FundingTypeID, CID | READER | Application checks whitelist before applying percentage |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeRolloutWhiteList (table)
  (no FK constraints)
```

### 6.1 Objects This Depends On

No FK constraints.

### 6.2 Objects That Depend On This

No stored procedure dependents in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX_FundingTypeRolloutWhiteList_FundingTypeID | CLUSTERED | FundingTypeID ASC | - | - | Active (FILLFACTOR 95) on DICTIONARY |
| UIX_FundingTypeRolloutWhiteList_CID_FundingTypeID | UNIQUE NONCLUSTERED | CID ASC, FundingTypeID ASC | - | - | Active (FILLFACTOR 95) - enforces one whitelist entry per customer per payment method |

### 7.2 Constraints

No PK. No FK constraints. Uniqueness enforced by UIX.

---

## 8. Sample Queries

### 8.1 Check if a customer is whitelisted for a payment method
```sql
SELECT  1 AS IsWhitelisted
FROM    Billing.FundingTypeRolloutWhiteList WITH (NOLOCK)
WHERE   FundingTypeID = 38
        AND CID = 12345;
-- Returns row -> whitelisted; no rows -> not whitelisted
```

### 8.2 Get all whitelisted customers for a payment method
```sql
SELECT  CID, FundingTypeID
FROM    Billing.FundingTypeRolloutWhiteList WITH (NOLOCK)
WHERE   FundingTypeID = 38
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeRolloutWhiteList | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingTypeRolloutWhiteList.sql*
