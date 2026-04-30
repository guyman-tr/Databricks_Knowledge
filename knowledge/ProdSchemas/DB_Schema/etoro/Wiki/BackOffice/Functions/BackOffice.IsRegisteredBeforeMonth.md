# BackOffice.IsRegisteredBeforeMonth

> Identifies customers in the "recently registered" lifecycle segment: registered within the last 30 days but past the initial 24-hour brand-new window.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIT - 1=registered 1-30 days ago, 0=outside this window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.IsRegisteredBeforeMonth identifies customers who registered between 1 and 30 days ago - the "recently registered" or "new but not brand new" customer segment. It intentionally excludes customers who registered within the last 24 hours (those are covered by IsRegisteredBefore24Hrs) and customers older than 30 days (established users). The result is a clean, mutually exclusive segment between the two other registration-age functions.

This segmentation is important for targeted BackOffice actions. Customers in the 1-30 day window have passed the initial registration excitement but are still in the critical early conversion phase where they might make their first deposit, complete KYC verification, or start trading. Marketing and account management teams use this segment for retention campaigns, first-deposit incentives, and proactive customer outreach before new users go dormant.

The function depends on IsRegisteredBefore24Hrs to enforce the lower bound - rather than duplicating the 24-hour check, it calls the sibling function directly. This design means the three registration-age functions (IsRegisteredBefore24Hrs, IsRegisteredBeforeMonth, and the implicit "established" category from GetCustomerStatus value 0) form a complete, non-overlapping partition of all customers by account age.

---

## 2. Business Logic

### 2.1 Mutually Exclusive 30-Day Window (Excluding First 24 Hours)

**What**: Returns 1 only for the specific lifecycle window of 1-30 days post-registration, explicitly designed to not overlap with the 24-hour flag.

**Parameters Involved**: `@CID`

**Rules**:
- Reads Registered timestamp from Customer.Customer.
- Returns 1 if BOTH: (a) `DATEDIFF(dd, Registered, GETDATE()) <= 30` (within 30 days), AND (b) `BackOffice.IsRegisteredBefore24Hrs(@CID) = 0` (not in the first 24 hours).
- Uses DATEDIFF(dd, ...) which counts calendar day boundaries crossed, not elapsed hours. A customer registered 29 days and 23 hours ago passes the `<= 30` days check.
- The IsRegisteredBefore24Hrs check is the key: it makes this function's output mutually exclusive with IsRegisteredBefore24Hrs. A customer cannot have both flags = 1 simultaneously.
- Returns 0 for: customers older than 30 days, customers in their first 24 hours, and customers not found in Customer.Customer.

**Diagram**:
```
Account age:   0h               24h                    30d
               |-----------------|------------------------|
               | IsRegisteredBefore24Hrs = 1             |
                                 |IsRegisteredBeforeMonth=1|
                                                          | (established, both = 0)

GetCustomerStatus bitmask:
  Bit 0 = IsRegisteredBefore24Hrs (value 1)
  Bit 1 = IsRegisteredBeforeMonth (value 2)
  -> Bits 0 and 1 are mutually exclusive: can never both be 1
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose registration age is being evaluated. Looked up in Customer.Customer. FK to Customer.CustomerStatic.CID (cross-schema). |
| 2 | Return value | BIT | NO | - | CODE-BACKED | 1 = Customer is in the "recently registered" lifecycle window: registered between 1 day and 30 days ago (within 30 days total but past the first 24 hours). 0 = Customer is either brand new (within 24 hours), established (over 30 days), or not found. This bit contributes value 2 (2^1) to the GetCustomerStatus bitmask. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Table access (cross-schema) | Reads the Registered timestamp to compute account age in days |
| (internal) | BackOffice.IsRegisteredBefore24Hrs | Function call | Called to exclude the first-24-hours segment, enforcing mutual exclusivity with the 24-hour flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerStatus | Bit 1 (2^1 = 2) | Function call | Second bit of the customer status bitmask - value 2 when customer is in the 1-30 day window |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.IsRegisteredBeforeMonth (scalar function)
├── Customer.Customer (table) [cross-schema]
└── BackOffice.IsRegisteredBefore24Hrs (scalar function)
      └── Customer.Customer (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table (cross-schema) | SELECT Registered WHERE CID = @CID - reads account creation timestamp |
| BackOffice.IsRegisteredBefore24Hrs | Scalar Function | Called to check if customer is within the 24-hour window; must be 0 for this function to return 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerStatus | Scalar Function | Multiplied by POWER(2,1) = 2 and OR'd into customer status bitmask |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Check if a customer is in the 1-30 day recently-registered window
```sql
SELECT BackOffice.IsRegisteredBeforeMonth(12345) AS IsRecentlyRegistered
-- 1 = registered 1-30 days ago (past 24-hour new period)
-- 0 = brand new (< 24 hrs), established (> 30 days), or not found
```

### 8.2 Get the complete lifecycle stage flags for a customer
```sql
DECLARE @CID INT = 12345
SELECT
    BackOffice.IsRegisteredBefore24Hrs(@CID) AS BrandNew_Within24Hrs,
    BackOffice.IsRegisteredBeforeMonth(@CID)  AS Recent_1to30Days,
    CASE
        WHEN BackOffice.IsRegisteredBefore24Hrs(@CID) = 0
         AND BackOffice.IsRegisteredBeforeMonth(@CID) = 0
        THEN 1 ELSE 0
    END AS Established_Over30Days
```

### 8.3 Count customers currently in the recently-registered lifecycle segment
```sql
SELECT COUNT(*) AS RecentlyRegisteredCount
FROM Customer.Customer cc WITH (NOLOCK)
WHERE DATEDIFF(dd, cc.Registered, GETDATE()) BETWEEN 1 AND 30
  AND DATEDIFF(hh, cc.Registered, GETDATE()) > 24
-- Direct SQL equivalent of BackOffice.IsRegisteredBeforeMonth = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 external callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.IsRegisteredBeforeMonth | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.IsRegisteredBeforeMonth.sql*
