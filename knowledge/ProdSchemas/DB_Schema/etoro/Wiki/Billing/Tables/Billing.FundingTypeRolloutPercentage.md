# Billing.FundingTypeRolloutPercentage

> Feature rollout configuration table that controls what percentage of customers see a new payment method (funding type); currently holds one row with FundingTypeID=38 at 0% (fully rolled back).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | FundingTypeID - PK CLUSTERED |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 (PK on FundingTypeID) |

---

## 1. Business Meaning

`Billing.FundingTypeRolloutPercentage` controls gradual feature rollout for new payment methods. When a new funding type is being introduced, rather than enabling it for all customers immediately, it can be rolled out to a configurable percentage of customers. This allows monitoring for issues before full deployment.

The table currently holds 1 row: FundingTypeID=38, Percentage=0 (fully rolled back / disabled). FundingTypeID=38 is a payment method that was either being piloted or has been temporarily disabled.

This table works together with `Billing.FundingTypeRolloutWhiteList`:
- `FundingTypeRolloutPercentage`: Sets the percentage (0-100) of ALL customers who see the payment method.
- `FundingTypeRolloutWhiteList`: Whitelists specific CIDs who always see the payment method regardless of the percentage setting.

No stored procedures in the SSDT repo reference this table - it is read by application-layer services.

---

## 2. Business Logic

### 2.1 Percentage-Based Rollout

**What**: The Percentage column determines what fraction of customers have access to a payment method.

**Columns/Parameters Involved**: `FundingTypeID`, `Percentage`

**Rules**:
```
Percentage = 0:   Payment method disabled / 0% of customers see it
Percentage = 10:  10% of customers (randomly or hash-based) see this payment method
Percentage = 100: All customers see this payment method (full rollout)

Current data: FundingTypeID=38 -> Percentage=0 (fully rolled back)
```

**Rollout Decision Pattern** (application-layer):
```
1. Check if CID is in FundingTypeRolloutWhiteList for this FundingTypeID -> always show
2. Else: deterministically hash CID % 100 -> if < Percentage, show the payment method
```

---

## 3. Data Overview

| FundingTypeID | Percentage | Meaning |
|--------------|-----------|---------|
| 38 | 0 | FundingTypeID=38 is fully rolled back (0% visibility) - no customers see this payment method |

Total: 1 row.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | VERIFIED | Primary key. Payment method type being rolled out. Implicit FK to Dictionary.FundingType(FundingTypeID). One row per payment method under rollout control. Currently only FundingTypeID=38. |
| 2 | Percentage | int | NO | - | VERIFIED | Rollout percentage (0-100). 0=disabled/no customers, 100=all customers. Current value: 0 (FundingTypeID=38 fully disabled). Integer percentage; application uses this to determine if a given customer (by CID hash or whitelist) should see the payment method. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method being rolled out |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.FundingTypeRolloutWhiteList | FundingTypeID | RELATED | Whitelist complement - specific CIDs who always see the payment method regardless of Percentage |
| (application code) | FundingTypeID, Percentage | READER | Application services read this to determine rollout eligibility |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeRolloutPercentage (table)
  (no FK constraints)
```

### 6.1 Objects This Depends On

No FK constraints.

### 6.2 Objects That Depend On This

No stored procedure dependents found in SSDT. Read by application-layer services.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FundingTypeRolloutPercentage | CLUSTERED PK | FundingTypeID ASC | - | - | Active (FILLFACTOR 95) on DICTIONARY |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FundingTypeRolloutPercentage | PRIMARY KEY CLUSTERED | FundingTypeID - one rollout percentage per payment method |

---

## 8. Sample Queries

### 8.1 Get current rollout percentages
```sql
SELECT  FTRP.FundingTypeID,
        FTRP.Percentage
FROM    Billing.FundingTypeRolloutPercentage FTRP WITH (NOLOCK)
ORDER BY FTRP.FundingTypeID;
```

### 8.2 Check if a customer is in rollout scope (percentage + whitelist)
```sql
DECLARE @CID INT = 12345, @FundingTypeID INT = 38;

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM Billing.FundingTypeRolloutWhiteList WITH (NOLOCK)
            WHERE FundingTypeID = @FundingTypeID AND CID = @CID
        ) THEN 1  -- Whitelisted: always show
        WHEN (
            SELECT Percentage FROM Billing.FundingTypeRolloutPercentage WITH (NOLOCK)
            WHERE FundingTypeID = @FundingTypeID
        ) > ABS(@CID % 100) THEN 1  -- Within percentage: show
        ELSE 0  -- Not in rollout
    END AS IsEligible;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeRolloutPercentage | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingTypeRolloutPercentage.sql*
