# BackOffice.IsRegisteredBefore24Hrs

> Identifies whether a customer registered (signed up) within the last 24 hours, flagging brand-new accounts in their first day on the platform.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIT - 1=registered within 24 hours, 0=older account |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.IsRegisteredBefore24Hrs determines whether a customer's account was created within the last 24 hours. It reads the Registered timestamp from Customer.Customer and compares the elapsed hours against the current server time. A return value of 1 means the customer is in their first 24-hour window since registration - a "brand new" account.

This function is one of three registration-age segmentation functions that together classify customers by their onboarding lifecycle stage. The 24-hour boundary is the tightest segment: customers at this stage are most likely still in the registration and onboarding flow, haven't yet made their first deposit, and may be candidates for immediate welcome actions. The function feeds into BackOffice.GetCustomerStatus as the "bit 0" component of the customer status bitmask.

Notably, IsRegisteredBefore24Hrs is also called by IsRegisteredBeforeMonth to create a mutually exclusive "between 24 hours and 30 days" segment - the month-window function returns 1 only when the customer is NOT in the 24-hour window, ensuring the two flags never both equal 1 for the same customer at the same time.

---

## 2. Business Logic

### 2.1 24-Hour Registration Window

**What**: Computes the elapsed time since registration and returns true if within the 24-hour new-account window.

**Parameters Involved**: `@CID`

**Rules**:
- Retrieves the Registered timestamp from Customer.Customer WHERE CID = @CID.
- Returns 1 if `DATEDIFF(hh, Registered, GETDATE()) <= 24`. Uses hour-granularity (hh), not minute or second - a customer registered 24 hours and 30 minutes ago would still return 1 (DATEDIFF counts whole hour boundaries crossed).
- Returns 0 if the customer registered more than 24 hours ago, or if the customer is not found (NULL @Registered causes DATEDIFF to return NULL, which fails the <= 24 check, defaulting @Result to 0).
- Time zone: GETDATE() returns the SQL Server local time (typically UTC in eToro's infrastructure). The Registered column is assumed to be in the same time zone.

**Diagram**:
```
Customer.Customer.Registered = T0
GETDATE() = T_now

DATEDIFF(hours, T0, T_now) <= 24?
    YES -> Return 1 (brand new account, within first day)
    NO  -> Return 0 (established account, past 24-hour window)

Note: Used by IsRegisteredBeforeMonth as exclusion gate:
  IsRegisteredBeforeMonth returns 1 ONLY IF IsRegisteredBefore24Hrs = 0
  -> The two flags are mutually exclusive by design
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose registration age is being evaluated. Looked up in Customer.Customer. FK to Customer.CustomerStatic.CID (cross-schema). |
| 2 | Return value | BIT | NO | - | CODE-BACKED | 1 = Customer registered within the last 24 hours (brand new account, first day on platform). 0 = Customer registered more than 24 hours ago, or CID not found. This bit contributes value 1 (2^0) to the GetCustomerStatus bitmask. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Table access (cross-schema) | Reads the Registered timestamp to compute account age |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.IsRegisteredBeforeMonth | (exclusion check) | Function call | IsRegisteredBeforeMonth calls this function to exclude the 24-hour segment - returns 1 only when IsRegisteredBefore24Hrs returns 0 |
| BackOffice.GetCustomerStatus | Bit 0 (2^0 = 1) | Function call | First bit of the customer status bitmask - value 1 when customer is within first 24 hours |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.IsRegisteredBefore24Hrs (scalar function)
└── Customer.Customer (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table (cross-schema) | SELECT Registered WHERE CID = @CID - reads account creation timestamp |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IsRegisteredBeforeMonth | Scalar Function | Called as exclusion condition - month window requires this to be 0 |
| BackOffice.GetCustomerStatus | Scalar Function | Multiplied by POWER(2,0) = 1 and OR'd into customer status bitmask |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Check if a customer is within their first 24 hours
```sql
SELECT BackOffice.IsRegisteredBefore24Hrs(12345) AS IsNewWithin24Hrs
-- 1 = registered within last 24 hours
-- 0 = account older than 24 hours
```

### 8.2 Get the registration age breakdown for a customer
```sql
DECLARE @CID INT = 12345
SELECT
    cc.CID,
    cc.Registered,
    DATEDIFF(hh, cc.Registered, GETDATE()) AS HoursSinceRegistration,
    BackOffice.IsRegisteredBefore24Hrs(@CID) AS Within24Hrs,
    BackOffice.IsRegisteredBeforeMonth(@CID) AS Within30Days,
    BackOffice.GetCustomerStatus(@CID) AS StatusBitmask
FROM Customer.Customer cc WITH (NOLOCK)
WHERE cc.CID = @CID
```

### 8.3 Find all customers currently in their first 24 hours
```sql
SELECT
    cc.CID,
    cc.Registered,
    DATEDIFF(hh, cc.Registered, GETDATE()) AS HoursOld
FROM Customer.Customer cc WITH (NOLOCK)
WHERE DATEDIFF(hh, cc.Registered, GETDATE()) <= 24
  AND cc.Registered >= DATEADD(day, -2, GETDATE())  -- optimization: limit scan
ORDER BY cc.Registered DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 external callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.IsRegisteredBefore24Hrs | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.IsRegisteredBefore24Hrs.sql*
