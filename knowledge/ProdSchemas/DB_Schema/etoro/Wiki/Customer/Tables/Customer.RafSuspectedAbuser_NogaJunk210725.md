# Customer.RafSuspectedAbuser_NogaJunk210725

> Temporary RAF suspected-abuse staging table (Noga Rozen, July 2025): records (referring, referred) pairs suspected of gaming the RAF program, capturing the equity balance of each party at the time of detection to quantify the financial scale.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (ReferringCID, ReferredCID) composite PK |
| **Partition** | No (DICTIONARY filegroup, FILLFACTOR=100) |
| **Indexes** | 1 (clustered composite PK only) |

---

## 1. Business Meaning

Customer.RafSuspectedAbuser_NogaJunk210725 is a temporary working table for the July 2025 RAF project. Each row records a (referring, referred) pair where one or both parties are suspected of abusing the RAF program - meaning they may be exploiting the referral bonus through coordinated fake referrals, rather than genuine customer acquisition.

The key differentiator from RafFraudCustomers_NogaJunk210725 (confirmed fraud) is that this table holds SUSPECTED cases - pairs that have raised red flags but not yet been confirmed as fraudulent. The equity balances (ReferringSelfEquity, ReferredSelfEquity) are captured to provide financial context: large equity balances suggest active traders using the referral legitimately; very small or zero equity balances may indicate accounts created solely to collect RAF bonuses.

Customer.RafMarkSuspectedAbuser_NogaJunk210725 is the procedure that writes to this table.

---

## 2. Business Logic

### 2.1 Equity-Based Abuse Signal

**What**: Capturing the equity balance of both parties at detection time provides a financial signal to differentiate genuine referrals from suspected abuse.

**Columns/Parameters Involved**: `ReferringSelfEquity`, `ReferredSelfEquity`

**Rules**:
- Very low equity (near zero) for both parties suggests accounts created only for RAF bonus collection
- High equity values indicate actively funded trading accounts, consistent with genuine customers
- Both nullable - NULL means equity was not captured or not available at detection time
- Money type (up to 4 decimal places in SQL Server) - stores actual equity in account currency

---

## 3. Data Overview

*Row count not queried in this session. Table stores RAF suspected-abuse pairs flagged by RafMarkSuspectedAbuser_NogaJunk210725 during the July 2025 project.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReferringCID | int | NO | - | VERIFIED | CID of the suspected abuser who claimed to refer a new customer. Part of composite PK. Note: int (not bigint) unlike the other NogaJunk RAF tables - int is consistent with Customer.RAFGiven. |
| 2 | ReferredCID | int | NO | - | VERIFIED | CID of the referred customer in the suspected pair. Part of composite PK. |
| 3 | ReferringSelfEquity | money | YES | - | CODE-BACKED | Equity balance of the referring customer at the time this record was created. Captured to assess whether the referring party is a genuine trader (higher equity) or a potential fake account (near-zero equity). |
| 4 | ReferredSelfEquity | money | YES | - | CODE-BACKED | Equity balance of the referred customer at detection time. Similarly used to assess account legitimacy. Low equity on a new referred account combined with immediate RAF bonus claim is a fraud signal. |
| 5 | CreatedDate | datetime | YES | - | CODE-BACKED | Timestamp when this pair was flagged as suspected abuser. Nullable (no DEFAULT constraint) - may be NULL for records inserted without a date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReferringCID, ReferredCID | Customer.CustomerStatic | Implicit | No FK enforced |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RafMarkSuspectedAbuser_NogaJunk210725 | ReferringCID, ReferredCID | Writer | Inserts suspected abuse pairs with equity snapshot |
| Customer.RafViewCustomerStatus_NogaJunk210725 | ReferringCID, ReferredCID | View | Reads suspected abuser status as part of RAF status display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafSuspectedAbuser_NogaJunk210725 (table)
```
No structural dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafMarkSuspectedAbuser_NogaJunk210725 | Stored Procedure | Writer - marks suspected abusers with equity snapshot |
| Customer.RafViewCustomerStatus_NogaJunk210725 | View | Reader - status display |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RafSuspectedAbuser | Clustered PK | ReferringCID ASC, ReferredCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none beyond PK) | - | No DEFAULT constraints, no FKs |

---

## 8. Sample Queries

### 8.1 View all suspected abusers with equity context
```sql
SELECT
    rsa.ReferringCID,
    rsa.ReferredCID,
    rsa.ReferringSelfEquity,
    rsa.ReferredSelfEquity,
    rsa.CreatedDate
FROM Customer.RafSuspectedAbuser_NogaJunk210725 rsa WITH (NOLOCK)
ORDER BY rsa.CreatedDate DESC;
```

### 8.2 Flag pairs with very low equity (high abuse risk)
```sql
SELECT ReferringCID, ReferredCID, ReferringSelfEquity, ReferredSelfEquity, CreatedDate
FROM Customer.RafSuspectedAbuser_NogaJunk210725 WITH (NOLOCK)
WHERE ISNULL(ReferringSelfEquity, 0) < 100
  AND ISNULL(ReferredSelfEquity, 0) < 100
ORDER BY CreatedDate DESC;
```

### 8.3 Cross-reference with confirmed fraud table
```sql
SELECT
    rsa.ReferringCID,
    rsa.ReferredCID,
    rsa.ReferringSelfEquity,
    rfc.CreatedDate AS FraudConfirmedDate,
    rfc.HandledByRafServiceTime
FROM Customer.RafSuspectedAbuser_NogaJunk210725 rsa WITH (NOLOCK)
LEFT JOIN Customer.RafFraudCustomers_NogaJunk210725 rfc WITH (NOLOCK)
    ON rfc.ReferringCID = rsa.ReferringCID AND rfc.ReferredCID = rsa.ReferredCID
ORDER BY rsa.ReferringCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 identified (RafMarkSuspectedAbuser) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.RafSuspectedAbuser_NogaJunk210725 | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.RafSuspectedAbuser_NogaJunk210725.sql*
