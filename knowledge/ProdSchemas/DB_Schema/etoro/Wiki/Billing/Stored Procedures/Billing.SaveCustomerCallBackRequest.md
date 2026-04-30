# Billing.SaveCustomerCallBackRequest

> Records a customer's request to be called back by a sales or support agent, capturing the customer ID, requested callback time, and intended deposit amount.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into Billing.CustomerCallBack |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer who has not yet deposited requests a callback from eToro's sales or onboarding team, `Billing.SaveCustomerCallBackRequest` records that request. The callback feature allows potential depositors to signal their intent along with a deposit amount they're considering, enabling the sales team to follow up with targeted conversations.

The `DepositAmount` parameter captures the intended deposit size at the time of the callback request, not an actual deposit. This information helps the sales team prioritize callbacks and prepare for the conversation.

---

## 2. Business Logic

### 2.1 Callback Request Logging

**What**: Simple INSERT of a callback request record.

**Rules**:
- Unconditional INSERT. No duplicate checking.
- RequestDate is passed in (not set server-side) - caller controls the timestamp.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID requesting the callback. |
| 2 | @RequestDate | SMALLDATETIME | NO | - | CODE-BACKED | Desired callback date/time provided by the customer. Caller-supplied (not server GETUTCDATE). |
| 3 | @DepositAmount | DECIMAL(18,2) | NO | - | CODE-BACKED | Intended deposit amount the customer is considering. Stored for sales team context; not an actual deposit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Billing.CustomerCallBack | Direct write (INSERT) | Creates the callback request record |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the customer-facing application when a callback is requested.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveCustomerCallBackRequest (procedure)
└── Billing.CustomerCallBack (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerCallBack | Table | INSERT target |

### 6.2 Objects That Depend On This

No SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None beyond the target table's own constraints.

---

## 8. Sample Queries

### 8.1 Record a callback request

```sql
EXEC Billing.SaveCustomerCallBackRequest
    @CID = 123456,
    @RequestDate = '2026-03-18 14:00:00',
    @DepositAmount = 500.00
```

### 8.2 View recent callback requests

```sql
SELECT cb.CID, cb.RequestDate, cb.DepositAmount
FROM Billing.CustomerCallBack cb WITH (NOLOCK)
WHERE cb.RequestDate >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY cb.RequestDate DESC
```

### 8.3 View callback requests by deposit amount range

```sql
SELECT cb.CID, cb.RequestDate, cb.DepositAmount
FROM Billing.CustomerCallBack cb WITH (NOLOCK)
WHERE cb.DepositAmount >= 1000
ORDER BY cb.DepositAmount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 10/10, Logic: 3/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.SaveCustomerCallBackRequest | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.SaveCustomerCallBackRequest.sql*
