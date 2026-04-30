# Billing.CustomerCallBack

> Customer callback request log - records when a customer has requested a phone callback from eToro support, including the requested time slot and the deposit amount they expressed interest in.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | Id (IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.CustomerCallBack` records customer-initiated callback requests for the Billing/deposit domain. When a prospective or existing customer requests a phone callback - typically because they need assistance completing a deposit or want to discuss funding options - the request is logged here with the customer ID, their requested callback time, and the deposit amount they expressed interest in.

This table exists to support the sales/support workflow of proactive outreach to customers interested in depositing. The data enables support teams or BI to see who requested callbacks, when, and for what deposit amount - supporting conversion tracking and quality monitoring.

The table currently has 0 rows - it may be a newly provisioned feature not yet in active use, or the feature was deprecated and data purged. The `NOT FOR REPLICATION` flag on IDENTITY indicates it participates in SQL Server replication. BI admins (PROD_BIadmins permission group) have read access for reporting.

---

## 2. Business Logic

No complex multi-column business logic. See `Billing.SaveCustomerCallBackRequest` for the insert flow.

### 2.1 Callback Request Capture

**What**: A single insert operation captures all context of a customer's callback request.

**Columns/Parameters Involved**: `CID`, `RequestDate`, `DepositAmount`

**Rules**:
- `Billing.SaveCustomerCallBackRequest(@CID, @RequestDate, @DepositAmount)` is the only write path.
- No deduplication logic in the procedure - a customer can have multiple callback requests.
- `RequestDate` uses `smalldatetime` (minute-level precision) - sufficient for scheduling purposes.
- `DepositAmount` captures the self-reported deposit intent, not a confirmed deposit.

---

## 3. Data Overview

Table currently contains 0 rows - no callback requests recorded in the current environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate primary key. NOT FOR REPLICATION - identity not consumed on replication subscribers. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer requesting the callback. Implicit FK to Customer.CustomerStatic.CID. Links the callback request to a specific eToro customer account. |
| 3 | RequestDate | smalldatetime | NO | - | CODE-BACKED | Date and time the customer requested to be called back (minute precision). Set by the caller passing @RequestDate - this is the customer's PREFERRED callback time, not the time the request was logged. |
| 4 | DepositAmount | decimal(18,2) | NO | - | CODE-BACKED | Deposit amount the customer expressed interest in (in their account currency). Captured to help the support agent prepare for the call with context on the customer's deposit intent. Not a confirmed or reserved amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Identifies the customer requesting the callback. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.SaveCustomerCallBackRequest | @CID, @RequestDate, @DepositAmount | WRITER | Inserts a new callback request. Only write path to this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.SaveCustomerCallBackRequest | Stored Procedure | WRITER - inserts callback request records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing.CustomerCallBack | CLUSTERED PK | Id ASC | - | - | Active |

PRIMARY filegroup. No index on CID - customer lookups do full scan (acceptable given expected low volume).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing.CustomerCallBack | PRIMARY KEY | Id - unique callback request identifier |

---

## 8. Sample Queries

### 8.1 Get all callback requests for a customer

```sql
SELECT Id, CID, RequestDate, DepositAmount
FROM [Billing].[CustomerCallBack] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY RequestDate DESC;
```

### 8.2 View upcoming callback requests

```sql
SELECT Id, CID, RequestDate, DepositAmount
FROM [Billing].[CustomerCallBack] WITH (NOLOCK)
WHERE RequestDate >= GETUTCDATE()
ORDER BY RequestDate ASC;
```

### 8.3 Callback requests by deposit amount tier

```sql
SELECT
    CASE
        WHEN DepositAmount < 500 THEN 'Under $500'
        WHEN DepositAmount < 2000 THEN '$500-$2000'
        ELSE 'Over $2000'
    END AS AmountTier,
    COUNT(*) AS RequestCount
FROM [Billing].[CustomerCallBack] WITH (NOLOCK)
GROUP BY
    CASE
        WHEN DepositAmount < 500 THEN 'Under $500'
        WHEN DepositAmount < 2000 THEN '$500-$2000'
        ELSE 'Over $2000'
    END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CustomerCallBack | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CustomerCallBack.sql*
