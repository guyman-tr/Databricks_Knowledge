# Billing.FundingTypeDailyReport_Status

> Returns yesterday's deposit count grouped by payment status for a given payment type, as JSON - used to monitor approval rates and deposit outcomes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns JSON array of {Count, Status} sorted by Count DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingTypeDailyReport_Status` is the payment status dimension slice of the daily funding type monitoring suite. Payment status (from `Dictionary.PaymentStatus`) captures the outcome of each deposit transaction: Approved, Pending, Declined, Chargeback, etc. Operations teams use this to quickly see the success/failure breakdown for a specific payment method yesterday - the primary measure of payment method health.

A sudden drop in "Approved" count or spike in "Declined" is the key signal that something is wrong with a payment method's routing or processing.

See `Billing.FundingTypeDailyReport_All` for full suite documentation.

---

## 2. Business Logic

### 2.1 Payment Status Distribution

**What**: Counts deposits yesterday grouped by their terminal payment status.

**Columns/Parameters Involved**: `@fundingTypeID`, `Status` (from BASE - Dictionary.PaymentStatus.Name via Billing.Deposit.PaymentStatusID)

**Rules**:
- Status is the deposit's payment status name (from Dictionary.PaymentStatus.Name).
- INNER JOIN in BASE function - deposits with no PaymentStatusID are excluded (should not happen).
- Ordered by Count DESC - most common status (typically "Approved") first.
- Key statuses: "Approved" (successful deposit), "Pending" (awaiting confirmation), "Declined" (rejected by processor), "ChargeBack" (disputed by cardholder).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fundingTypeID | INT | NO | 35 | CODE-BACKED | Payment instrument type to report on. Default 35. |

**Return columns** (FOR JSON AUTO):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | Count | int | CODE-BACKED | Number of deposits with this status yesterday. |
| R2 | Status | nvarchar | CODE-BACKED | Payment status name (from Dictionary.PaymentStatus.Name via Billing.Deposit.PaymentStatusID). Examples: "Approved", "Pending", "Declined", "ChargeBack". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fundingTypeID | Billing.FundingTypeDailyReport_BASE | Function call | All data retrieval delegated to this inline TVF |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations dashboards | External | Caller | Payment approval rate monitoring for payment methods |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeDailyReport_Status (procedure)
└── Billing.FundingTypeDailyReport_BASE (inline TVF)
      ├── Billing.Deposit (table)
      ├── Billing.Funding (table)
      ├── Dictionary.PaymentStatus (table)
      └── [other BASE dependencies - see FundingTypeDailyReport_All.md]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeDailyReport_BASE | Inline TVF | Provides base dataset; this proc adds GROUP BY Status + COUNT + FOR JSON AUTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations dashboards | External | Payment status monitoring for payment methods |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. FOR JSON AUTO output. Status column name reserved word - wrapped in square brackets `[Status]` in the DDL.

---

## 8. Sample Queries

### 8.1 Get status breakdown for funding type 35

```sql
EXEC [Billing].[FundingTypeDailyReport_Status] @fundingTypeID = 35;
-- Returns JSON: [{"Count":380,"Status":"Approved"},{"Count":40,"Status":"Pending"},{"Count":10,"Status":"Declined"}]
```

### 8.2 Ad-hoc status breakdown without JSON

```sql
SELECT COUNT(*) AS [Count], [Status]
FROM [Billing].[FundingTypeDailyReport_BASE](35)
GROUP BY [Status]
ORDER BY COUNT(*) DESC;
```

### 8.3 Calculate approval rate for a payment type

```sql
SELECT
    SUM(CASE WHEN [Status] = 'Approved' THEN 1 ELSE 0 END) AS ApprovedCount,
    COUNT(*) AS TotalCount,
    100.0 * SUM(CASE WHEN [Status] = 'Approved' THEN 1 ELSE 0 END) / COUNT(*) AS ApprovalRate
FROM [Billing].[FundingTypeDailyReport_BASE](35) WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeDailyReport_Status | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingTypeDailyReport_Status.sql*
