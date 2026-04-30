# Billing.LoadResponses

> Data loader that returns all rows from Dictionary.Response, providing the billing engine with the complete mapping of payment provider response codes to payment status outcomes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full Dictionary.Response table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadResponses is a bulk data loader that returns all rows from Dictionary.Response. This critical reference table maps the raw response codes returned by payment processors (e.g., "000", "001", "002") to eToro's internal payment statuses (PaymentStatusID) and response semantics. Each row defines one provider response code for a specific protocol and action type, specifying what the billing engine should do when that code is received.

The ShouldTerminate flag is particularly important: when true, the billing engine stops processing and marks the payment with the corresponding PaymentStatusID without retrying. Response codes indicating fraud, stolen cards, or hard declines (ShouldTerminate=1) prevent further processing attempts.

The billing engine loads this entire table at startup to avoid round-trips during live transaction processing. When a payment processor returns a response code, the engine looks up the code in this cache to determine the resulting payment status.

---

## 2. Business Logic

### 2.1 Response Code to Status Mapping

**What**: Maps raw provider response codes to eToro payment statuses and processing decisions.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns from Dictionary.Response via SELECT * WITH (NOLOCK).
- Lookup key: (ProtocolID, PaymentActionTypeID, ResponseCode) -> PaymentStatusID + ShouldTerminate.
- ShouldTerminate=1: hard stop - mark payment with PaymentStatusID, no retries. Example: "001" (card blocked), "002" (card stolen).
- ShouldTerminate=0: soft outcome - can potentially retry or review. Example: "000" (permitted transaction -> PaymentStatusID=2 Approved).
- ResponseCode is stored as a fixed-length padded field (e.g., "000       " with trailing spaces).
- GatewayID: optional gateway-specific override (NULL for most rows means applies to all gateways for this protocol).
- TerminalID: optional terminal-specific response (NULL means applies to all terminals for this protocol).
- Meaning field: typically NULL - the ResponseName contains the business description.

**Diagram**:
```
Payment Provider Returns ResponseCode="000"
    |
    v
Dictionary.Response [ProtocolID=1, ResponseCode="000", PaymentActionTypeID=2]
    |
    v
PaymentStatusID=2 (Approved) + ShouldTerminate=0
    |
    v
Billing.Payment.PaymentStatusID updated to 2 (Approved)

Payment Provider Returns ResponseCode="001"
    |
    v
Dictionary.Response [ProtocolID=1, ResponseCode="001"]
    |
    v
PaymentStatusID=3 (Decline) + ShouldTerminate=1
    |
    v
Billing.Payment.PaymentStatusID = 3, card blocked - no retry
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| RETURN | int | NO | - | CODE-BACKED | Returns 0 on successful execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | Dictionary.Response | READ | Reads all payment provider response code mappings. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during initialization to cache provider response code mappings. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadResponses (procedure)
└── Dictionary.Response (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Response | Table | SELECT * - reads all provider response code to payment status mappings. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - loads response code mappings at startup for transaction outcome processing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the loader
```sql
EXEC Billing.LoadResponses;
```

### 8.2 Find all hard-decline responses (ShouldTerminate=1) for a protocol
```sql
SELECT ResponseID, ResponseCode, ResponseName, PaymentStatusID
FROM Dictionary.Response WITH (NOLOCK)
WHERE ProtocolID = 1 AND ShouldTerminate = 1
ORDER BY ResponseCode;
```

### 8.3 Response codes that result in card-blocking status
```sql
SELECT r.ResponseCode, r.ResponseName, r.ProtocolID,
       ps.Name AS ResultingStatus
FROM Dictionary.Response r WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK)
    ON r.PaymentStatusID = ps.PaymentStatusID
WHERE r.PaymentStatusID = 8  -- DeclineBlockCard
ORDER BY r.ProtocolID, r.ResponseCode;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadResponses | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadResponses.sql*
