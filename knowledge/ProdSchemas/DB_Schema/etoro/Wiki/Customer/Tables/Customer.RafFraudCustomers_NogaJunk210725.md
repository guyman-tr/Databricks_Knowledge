# Customer.RafFraudCustomers_NogaJunk210725

> Temporary RAF fraud detection staging table (Noga Rozen, July 2025): records (referring, referred) pairs identified as fraudulent RAF attempts, with a timestamp for when the RAF service processed each fraud case.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (ReferringCID, ReferredCID) composite PK |
| **Partition** | No (DICTIONARY filegroup, PAGE compression) |
| **Indexes** | 2 (clustered PK + NC on HandledByRafServiceTime) |

---

## 1. Business Meaning

Customer.RafFraudCustomers_NogaJunk210725 is a temporary fraud detection output table for the July 2025 RAF project. Each row represents a (referring customer, referred customer) pair that has been flagged as fraudulent by the RAF fraud detection process - meaning the referral was identified as ineligible due to fraudulent activity such as self-referral, coordinated account creation, or other abuse patterns.

The _NogaJunk210725 suffix indicates this is a temporary working table. Customer.RafSetFraud_NogaJunk210725 and Customer.CheckFraudUsers_NogaJunk210725 are the procedures that write to and read from this table. The RAF compensation pipeline (RAFCompensationProcess) checks this table to skip fraudulent pairs.

HandledByRafServiceTime tracks when the RAF service actually processed/handled the fraud case, allowing the pipeline to distinguish between detected-but-not-yet-processed (NULL) and fully handled fraud cases.

---

## 2. Business Logic

### 2.1 Fraud Detection Pipeline State

**What**: HandledByRafServiceTime distinguishes fraud cases that have been actioned from those still pending handling.

**Columns/Parameters Involved**: `HandledByRafServiceTime`

**Rules**:
- NULL: fraud detected but not yet processed by the RAF service
- Non-NULL: RAF service has handled this fraud case (blocked compensation, possibly flagged the customer)
- NC index on HandledByRafServiceTime supports the pipeline query: WHERE HandledByRafServiceTime IS NULL (unhandled fraud queue)
- Code comment in RAFCompensationProcess (June 2019 entry): "Added the part that sends mail in case of RAF and in case of fraud" - fraud cases trigger email notifications
- Note: Platinum, Platinum Plus, and Diamond customers are excluded from fraud procedures (PART-3907, Jan 2025)

---

## 3. Data Overview

*Row count not queried in this session (query batched with other tables). Table stores fraud-flagged RAF pairs from the July 2025 project. Likely very small in this environment.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReferringCID | bigint | NO | - | VERIFIED | CID of the customer who made the fraudulent referral claim. Part of composite PK. Bigint for data lake compatibility. |
| 2 | ReferredCID | bigint | NO | - | VERIFIED | CID of the referred customer in the fraudulent pair. Part of composite PK. |
| 3 | CreatedDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when this pair was flagged as fraudulent and inserted. Default = getutcdate(). |
| 4 | HandledByRafServiceTime | datetime | YES | - | VERIFIED | UTC timestamp when the RAF service processed this fraud case (blocked compensation, sent notifications). NULL = pending processing. Indexed to support queue-style processing (fetch WHERE HandledByRafServiceTime IS NULL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReferringCID, ReferredCID | Customer.CustomerStatic | Implicit | No FK enforced; fraudulent CIDs reference registered customers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RafSetFraud_NogaJunk210725 | ReferringCID, ReferredCID | Writer | Inserts fraud-flagged pairs |
| Customer.CheckFraudUsers_NogaJunk210725 | ReferringCID, ReferredCID | Reader | Checks/queries fraud records |
| Customer.RAFCompensationProcess_NogaJunk210725 | ReferringCID, ReferredCID | Reader | Skips compensation for fraud-flagged pairs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafFraudCustomers_NogaJunk210725 (table)
```
No structural dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafSetFraud_NogaJunk210725 | Stored Procedure | Writer |
| Customer.CheckFraudUsers_NogaJunk210725 | Stored Procedure | Reader |
| Customer.RAFCompensationProcess_NogaJunk210725 | Stored Procedure | Reader - fraud check gate |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RafFraudCustomers | Clustered PK | ReferringCID ASC, ReferredCID ASC | - | - | Active |
| IDX_Customer_RafFraudCustomers_HandledByRafServiceTime | NC | HandledByRafServiceTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_RafFraudCustomers_CreatedDate | DEFAULT | CreatedDate = getutcdate() |

---

## 8. Sample Queries

### 8.1 View unhandled fraud cases (pending RAF service processing)
```sql
SELECT ReferringCID, ReferredCID, CreatedDate
FROM Customer.RafFraudCustomers_NogaJunk210725 WITH (NOLOCK)
WHERE HandledByRafServiceTime IS NULL
ORDER BY CreatedDate;
```

### 8.2 View handled fraud cases
```sql
SELECT ReferringCID, ReferredCID, CreatedDate, HandledByRafServiceTime,
       DATEDIFF(hour, CreatedDate, HandledByRafServiceTime) AS HoursToHandle
FROM Customer.RafFraudCustomers_NogaJunk210725 WITH (NOLOCK)
WHERE HandledByRafServiceTime IS NOT NULL
ORDER BY HandledByRafServiceTime DESC;
```

### 8.3 Check if a specific pair is flagged as fraud
```sql
SELECT ReferringCID, ReferredCID, CreatedDate, HandledByRafServiceTime
FROM Customer.RafFraudCustomers_NogaJunk210725 WITH (NOLOCK)
WHERE ReferringCID = 12345 AND ReferredCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 identified (RafSetFraud, RAFCompensationProcess) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.RafFraudCustomers_NogaJunk210725 | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.RafFraudCustomers_NogaJunk210725.sql*
