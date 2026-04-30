# BackOffice.GetCustomerStatus

> Computes a bitmask integer encoding a customer's onboarding lifecycle stage, combining registration-age and first-login flags into a single queryable status value.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIGINT - bitmask of customer lifecycle flags |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomerStatus classifies a customer's current onboarding lifecycle position using a 3-bit bitmask. It combines three binary questions into a single integer: Is the customer brand new (registered in the last 24 hours)? Is the customer recently registered (1-30 days)? Is this their first ever login? Each question maps to a bit, and the resulting number from 0-6 uniquely identifies which lifecycle stage the customer is in.

Bitmask encoding is used so that consuming code can test individual flags with bitwise AND operations (e.g., `Status & 1 = 1` checks the 24-hour flag) or compare the full combined state (e.g., `Status = 5` means brand-new first-time login). This is more efficient than returning a multi-column result or making three separate function calls.

The function serves as the single entry point for customer lifecycle status classification in BackOffice operations. Rather than building the lifecycle logic inline wherever it is needed, procedures and application code call GetCustomerStatus and interpret the returned bitmask. It is the top of a three-function dependency chain: GetCustomerStatus -> IsRegisteredBeforeMonth -> IsRegisteredBefore24Hrs (with IsFirstLogin as a parallel branch).

---

## 2. Business Logic

### 2.1 Customer Lifecycle Bitmask

**What**: Three binary lifecycle flags combined via bitwise OR into a BIGINT, producing a value between 0 and 6 that encodes the customer's onboarding stage.

**Parameters Involved**: `@CID`

**Rules**:
- Bit 0 (value 1): `POWER(2,0) * IsRegisteredBefore24Hrs(@CID)` - 1 if customer registered within last 24 hours
- Bit 1 (value 2): `POWER(2,1) * IsRegisteredBeforeMonth(@CID)` - 1 if customer registered within 1-30 days
- Bit 2 (value 4): `POWER(2,2) * IsFirstLogin(@CID)` - 1 if this is the customer's first ever login
- Combined with bitwise OR operator `|`
- Bits 0 and 1 are mutually exclusive by design (IsRegisteredBeforeMonth returns 0 when IsRegisteredBefore24Hrs is 1). Values 3 (0b011) and 7 (0b111) are mathematically impossible.

**Diagram**:
```
Lifecycle Stage Mapping:

Value | Bit2(FirstLogin) | Bit1(Within30d) | Bit0(Within24h) | Meaning
------|-----------------|-----------------|-----------------|--------
  0   |        0        |        0        |        0        | Established customer (>30 days, not first login)
  1   |        0        |        0        |        1        | Brand new account (< 24 hrs), not first login*
  2   |        0        |        1        |        0        | Recent signup (1-30 days), returning login
  3   |        -        |        -        |        -        | IMPOSSIBLE (bits 0+1 mutually exclusive)
  4   |        1        |        0        |        0        | Long-time member, logging in for first time (dormant account)
  5   |        1        |        0        |        1        | Brand new account, first login (typical new signup + activation)
  6   |        1        |        1        |        0        | Recent signup (1-30 days), first login now
  7   |        -        |        -        |        -        | IMPOSSIBLE (bits 0+1 mutually exclusive)

*Value 1 (within 24h, not first login): Possible if user registered,
 logged in, logged out, and is logging in again within 24 hours.

Most common expected values:
  0 = Majority of customers (established users)
  5 = Newly registered + first login (new user activation event)
  6 = Recent signup now logging in for first time
```

### 2.2 Dependency Chain (Scalar Function Composition)

**What**: GetCustomerStatus orchestrates three subordinate functions, each responsible for one bit.

**Parameters Involved**: `@CID`

**Rules**:
- IsRegisteredBefore24Hrs is called twice (once directly for bit 0, once indirectly via IsRegisteredBeforeMonth for bit 1). This is a minor performance consideration for high-frequency callers.
- Customer.Customer is read twice (once by IsRegisteredBefore24Hrs, once by IsRegisteredBeforeMonth) because each function independently queries it.
- History.Login and Customer.Login are each read once by IsFirstLogin.
- Total DB reads per call: Customer.Customer x2, History.Login x1, Customer.Login x1.

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose lifecycle status is being computed. Passed through to all three subordinate functions (IsRegisteredBefore24Hrs, IsRegisteredBeforeMonth, IsFirstLogin). |
| 2 | Return value | BIGINT | NO | - | VERIFIED | Bitmask encoding customer onboarding lifecycle stage. Valid values 0-6 (3 and 7 impossible due to mutual exclusivity of bits 0 and 1). Bit 0 (value 1) = within 24hrs. Bit 1 (value 2) = within 30 days (not 24hrs). Bit 2 (value 4) = first login. Test individual bits with bitwise AND: e.g., `Status & 4 = 4` tests IsFirstLogin. Common values: 0=established, 5=brand-new first-timer, 6=recent-signup first-login. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (internal) | BackOffice.IsRegisteredBefore24Hrs | Function call | Computes bit 0 (value 1) of the bitmask |
| (internal) | BackOffice.IsRegisteredBeforeMonth | Function call | Computes bit 1 (value 2) of the bitmask; itself calls IsRegisteredBefore24Hrs |
| (internal) | BackOffice.IsFirstLogin | Function call | Computes bit 2 (value 4) of the bitmask |

### 5.2 Referenced By (other objects point to this)

No callers found in BackOffice stored procedures. Likely consumed by application code, JUNK reporting functions (BackOffice.JUNK_GetCustomerSegment), or analytics queries that need the combined lifecycle status.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerStatus (scalar function)
├── BackOffice.IsRegisteredBefore24Hrs (scalar function)
│     └── Customer.Customer (table) [cross-schema]
├── BackOffice.IsRegisteredBeforeMonth (scalar function)
│     ├── Customer.Customer (table) [cross-schema]
│     └── BackOffice.IsRegisteredBefore24Hrs (scalar function)
│           └── Customer.Customer (table) [cross-schema]
└── BackOffice.IsFirstLogin (scalar function)
      ├── History.Login (table) [cross-schema]
      └── Customer.Login (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IsRegisteredBefore24Hrs | Scalar Function | Provides bit 0 (24-hour flag) via POWER(2,0) multiplication |
| BackOffice.IsRegisteredBeforeMonth | Scalar Function | Provides bit 1 (30-day flag) via POWER(2,1) multiplication |
| BackOffice.IsFirstLogin | Scalar Function | Provides bit 2 (first-login flag) via POWER(2,2) multiplication |

### 6.2 Objects That Depend On This

No confirmed dependents in BackOffice stored procedures. See Business Meaning section for expected consumption patterns.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get lifecycle status for a single customer with interpretation
```sql
DECLARE @Status BIGINT = BackOffice.GetCustomerStatus(12345)
SELECT
    @Status AS StatusBitmask,
    CASE @Status
        WHEN 0 THEN 'Established (>30 days, not first login)'
        WHEN 1 THEN 'Brand new account, returning login'
        WHEN 2 THEN 'Recent signup (1-30 days), returning login'
        WHEN 4 THEN 'Long-time member, first login (dormant)'
        WHEN 5 THEN 'Brand new account, first login'
        WHEN 6 THEN 'Recent signup, first login'
        ELSE 'Unknown/Invalid'
    END AS LifecycleStage
```

### 8.2 Test individual lifecycle flags with bitwise AND
```sql
DECLARE @CID INT = 12345
DECLARE @Status BIGINT = BackOffice.GetCustomerStatus(@CID)
SELECT
    @Status AS FullBitmask,
    CASE WHEN @Status & 1 = 1 THEN 1 ELSE 0 END AS IsWithin24Hrs,
    CASE WHEN @Status & 2 = 2 THEN 1 ELSE 0 END AS IsWithin30Days,
    CASE WHEN @Status & 4 = 4 THEN 1 ELSE 0 END AS IsFirstLogin
```

### 8.3 Find all brand-new customers experiencing first login (status = 5)
```sql
SELECT
    cl.CID,
    cc.Registered,
    BackOffice.GetCustomerStatus(cl.CID) AS StatusBitmask
FROM Customer.Login cl WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cl.CID = cc.CID
WHERE BackOffice.GetCustomerStatus(cl.CID) = 5  -- Brand new + first login
  AND cc.Registered >= DATEADD(day, -1, GETDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 external callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerStatus | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetCustomerStatus.sql*
