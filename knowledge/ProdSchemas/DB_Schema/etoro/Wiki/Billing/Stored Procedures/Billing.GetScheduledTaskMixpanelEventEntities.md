# Billing.GetScheduledTaskMixpanelEventEntities

> Post-deposit scheduler fetch for TaskID=4 (Mixpanel analytics): claims pending deposits with PaymentStatusID IN (2,3,4), returns deposit amount in USD, GCID, FundingType, IsFTD for Mixpanel event construction, then marks claimed rows as TaskState=3.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch (batch cap); returns one row per claimed deposit via OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetScheduledTaskMixpanelEventEntities` is the batch-fetch step for the Mixpanel analytics event pipeline (TaskID=4). Mixpanel is the product analytics platform used to track customer deposit events. This procedure selects and claims deposits with PaymentStatusID IN (2, 3, 4) - not just approved ones - so that multiple deposit outcomes can be tracked in Mixpanel for funnel analytics.

Created 11 Jun 2017 (Menchem, ticket 45543). Note: per ScheduledTaskConfig data, TaskID=4 has `LastProcessDate = 2017-07-12` suggesting this scheduler may have been discontinued. The task queue may have a large backlog (7.6M pending rows per ScheduledTaskState data overview) from deposits created when DepositAdd continued enqueuing rows.

---

## 2. Business Logic

### 2.1 Multi-Status Deposit Filter

**What**: Unlike the AppsFlyer and Pixel schedulers (status=2 only), this procedure includes multiple payment outcomes.

**Rules**:
- `D.PaymentStatusID IN (2, 3, 4)` - captures:
  - Status 2: Approved/Successful
  - Status 3: (additional completion status)
  - Status 4: (additional completion status)
- Allows Mixpanel to track deposit success AND non-success outcomes for complete funnel analysis

### 2.2 USD Amount Calculation

**What**: Amount is converted to USD using the deposit's exchange rate.

**Rules**:
- `Amount = D.Amount * D.ExchangeRate` - converts from deposit currency to USD
- Stored in `#PostDepositTask.Amount` as MONEY type
- The Mixpanel event uses the USD value for consistent cross-currency analytics

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Maximum batch size. -1 = no limit. Typically loaded from ScheduledTaskConfig.MaxEntitiesToFetch for TaskID=4 (1000). |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositID | INT | NO | - | CODE-BACKED | PK of the claimed deposit. |
| 3 | Amount | MONEY | YES | - | CODE-BACKED | `D.Amount * D.ExchangeRate` - deposit amount converted to USD. |
| 4 | PaymentStatusID | INT | YES | - | CODE-BACKED | Deposit payment status. Values 2, 3, or 4. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer identifier. |
| 6 | GCID | INT | YES | - | CODE-BACKED | Global customer identifier from `Customer.CustomerStatic`. |
| 7 | FundingType | INT | YES | - | CODE-BACKED | `Billing.Funding.FundingTypeID` - payment method type identifier. |
| 8 | IsFTD | BIT | YES | - | CODE-BACKED | First-time deposit flag from `Billing.Deposit.IsFTD`. Key Mixpanel event property. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.ScheduledTaskState | SELECT + UPDATE | Claim TaskID=4 pending rows; mark TaskState=3 |
| DepositID | Billing.Deposit | INNER JOIN | Amount, PaymentStatusID, CID, IsFTD |
| D.FundingID | Billing.Funding | INNER JOIN | FundingTypeID |
| F.FundingTypeID | Dictionary.FundingType | INNER JOIN | FundingType validation |
| D.CID | Customer.CustomerStatic | INNER JOIN | GCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Mixpanel event scheduler (TaskID=4) | @MaxEntitiesToFetch | EXEC | Batch fetch for Mixpanel analytics event sending |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskMixpanelEventEntities (procedure)
+-- Billing.ScheduledTaskState (table)
+-- Billing.Deposit (table)
+-- Billing.Funding (table)
+-- Dictionary.FundingType (table)
+-- Customer.CustomerStatic (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | Claim pending TaskID=4 rows; mark TaskState=3 |
| Billing.Deposit | Table | Amount, PaymentStatusID, CID, IsFTD |
| Billing.Funding | Table | FundingTypeID |
| Dictionary.FundingType | Table | FundingType JOIN validation |
| Customer.CustomerStatic | Table | GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Mixpanel analytics scheduler | External | Deposit event batch fetch (possibly inactive - TaskID=4 last ran Jul 2017) |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PaymentStatusID IN (2,3,4) | Design | Broader than AppsFlyer/Pixel (status=2 only); includes multiple completion states |
| INSERT...OUTPUT pattern | Design | Returns results via OUTPUT clause while inserting into #PostDepositTask |
| Possibly inactive | Operational | ScheduledTaskConfig shows TaskID=4 LastProcessDate = 2017; 7.6M pending rows may be abandoned backlog |

---

## 8. Sample Queries

### 8.1 Fetch Mixpanel event batch
```sql
EXEC Billing.GetScheduledTaskMixpanelEventEntities @MaxEntitiesToFetch = 1000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskMixpanelEventEntities | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskMixpanelEventEntities.sql*
