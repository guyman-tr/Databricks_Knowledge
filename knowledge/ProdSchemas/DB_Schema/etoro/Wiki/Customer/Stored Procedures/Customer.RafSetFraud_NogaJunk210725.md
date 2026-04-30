# Customer.RafSetFraud_NogaJunk210725

> Marks a RAF fraud pair as handled by the RAF service: updates Customer.RafFraudCustomers.HandledByRafServiceTime to the current UTC time for the specified referring/referred CID pair.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReferringCID + @ReferredCID - uniquely identify the fraud pair to mark |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RafSetFraud_NogaJunk210725` is the acknowledgment write endpoint for the RAF fraud pipeline. After the RAF service has processed a fraud pair (detected by `Customer.RAFCompensationProcess_NogaJunk210725` via `Customer.CheckFraudUsers`), the service calls this procedure to stamp the pair with a `HandledByRafServiceTime` timestamp.

This timestamp serves as a processing fence: downstream jobs and reports can use `HandledByRafServiceTime IS NULL` vs. `IS NOT NULL` to distinguish unprocessed fraud pairs from those already actioned by the RAF service. It does not delete or modify the fraud classification - the pair remains in `Customer.RafFraudCustomers` permanently as an audit record.

Created May 2023 (Ran O.) as part of the initial RAF microservice implementation (PART series). The `_NogaJunk210725` suffix indicates the procedure was flagged for eventual cleanup by developer Noga in July 2025.

---

## 2. Business Logic

### 2.1 Fraud Pair Acknowledgment

**What**: Stamps the HandledByRafServiceTime on a specific fraud pair to mark it as processed.

**Columns/Parameters Involved**: `@ReferringCID`, `@ReferredCID`, `Customer.RafFraudCustomers.HandledByRafServiceTime`

**Rules**:
- UPDATE `Customer.RafFraudCustomers` SET `HandledByRafServiceTime = GETUTCDATE()`.
- WHERE `ReferringCID = @ReferringCID AND ReferredCID = @ReferredCID`.
- No INSERT, no DELETE - only stamps the timestamp on the existing fraud record.
- If the pair does not exist in `RafFraudCustomers`, the UPDATE affects 0 rows (no error, no side effect).

```
Customer.RafFraudCustomers (pair)
  -> SET HandledByRafServiceTime = GETUTCDATE()
  -> WHERE ReferringCID = @ReferringCID AND ReferredCID = @ReferredCID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferringCID | INT | NO | - | CODE-BACKED | The referring customer CID of the fraud pair to mark as handled. |
| 2 | @ReferredCID | INT | NO | - | CODE-BACKED | The referred customer CID of the fraud pair to mark as handled. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReferringCID + @ReferredCID | Customer.RafFraudCustomers | UPDATE | Sets HandledByRafServiceTime = GETUTCDATE() for the matching pair |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RAF microservice | External call | Caller | Called after the RAF service has processed a fraud pair to prevent re-processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafSetFraud_NogaJunk210725 (procedure)
└── Customer.RafFraudCustomers (table) [UPDATE - stamp HandledByRafServiceTime]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafFraudCustomers | Table | UPDATE - sets HandledByRafServiceTime on the specified fraud pair |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RAF microservice | External | Calls after processing each fraud pair |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No-op on missing pair | Application | UPDATE with no matching row affects 0 rows silently - callers should validate pair exists if needed |
| Idempotent | Application | Calling multiple times simply overwrites HandledByRafServiceTime with the latest timestamp - safe for retries |

---

## 8. Sample Queries

### 8.1 Check unhandled fraud pairs

```sql
SELECT
    rfc.ReferringCID,
    rfc.ReferredCID,
    rfc.HandledByRafServiceTime,
    rfc.InsertedDate
FROM Customer.RafFraudCustomers rfc WITH (NOLOCK)
WHERE rfc.HandledByRafServiceTime IS NULL
ORDER BY rfc.InsertedDate DESC
```

### 8.2 Audit recently handled fraud pairs

```sql
SELECT TOP 50
    rfc.ReferringCID,
    rfc.ReferredCID,
    rfc.HandledByRafServiceTime,
    rfc.InsertedDate,
    fu.Main_Scoring AS FraudScore
FROM Customer.RafFraudCustomers rfc WITH (NOLOCK)
LEFT JOIN Customer.FraudUsers fu WITH (NOLOCK) ON fu.CID = rfc.ReferringCID
WHERE rfc.HandledByRafServiceTime IS NOT NULL
ORDER BY rfc.HandledByRafServiceTime DESC
```

### 8.3 Mark a fraud pair manually (equivalent to calling this procedure)

```sql
UPDATE Customer.RafFraudCustomers
SET HandledByRafServiceTime = GETUTCDATE()
WHERE ReferringCID = 111111 AND ReferredCID = 222222
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RafSetFraud_NogaJunk210725 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RafSetFraud_NogaJunk210725.sql*
