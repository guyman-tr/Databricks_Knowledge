# Billing.GetScheduledTaskRabbitMqFtdEntitiesReadOnly

> Read-only variant of the RabbitMQ FTD batch-fetch procedure: returns the same FTD deposit data as GetScheduledTaskRabbitMqFtdEntities but does NOT mark rows as TaskState=3, making it safe for monitoring, debugging, and queue inspection without side effects.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch (batch cap); returns one row per pending FTD deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetScheduledTaskRabbitMqFtdEntitiesReadOnly is the non-destructive inspection variant of the RabbitMQ FTD scheduled task batch-fetch framework. It returns exactly the same FTD deposit data that `Billing.GetScheduledTaskRabbitMqFtdEntities` would return, but crucially does NOT execute the UPDATE that marks rows as `TaskState=3` (In Progress) in `Billing.ScheduledTaskState`.

The procedure was added per PAYUS-2570 (Shay Oren, 28 Feb 2020) with the explicit intent "Do not update Billing.ScheduledTaskState." Use cases for this read-only variant include:

- **Queue monitoring**: Inspect pending FTD rows without consuming them - tools and dashboards can check queue depth and data quality without triggering the scheduler
- **Debugging**: Replay or inspect what a scheduler run would process without affecting the TaskState
- **Testing/QA**: Validate filter and data logic in non-production pipelines without advancing the queue
- **Read replica deployment**: Can safely run on a read-only AlwaysOn replica where the UPDATE would fail

All the core logic is identical to the original: two-stage #STS pre-selection, INNER JOIN for IsFTD=1 + PaymentStatusID=2 + 7-day recency, BIN-based MopCountry resolution, and Stage 2 GCID/MopCountry fallback UPDATE on `#PostDepositTask`. Only the final `UPDATE Billing.ScheduledTaskState SET TaskState=3` is absent.

---

## 2. Business Logic

### 2.1 No-Claim Pattern (Key Difference from Non-ReadOnly Version)

**What**: The TaskState UPDATE is commented out entirely, making this procedure safe to call without advancing the queue.

**Columns/Parameters Involved**: `Billing.ScheduledTaskState.TaskState`

**Rules**:
- The original procedure ends with: `UPDATE STS SET TaskState=3, Created=GetDate() FROM Billing.ScheduledTaskState INNER JOIN #PostDepositTask`
- This procedure has that block commented out (PAYUS-2570): `/*-- use dynamic SQL to verify update on Read Write server ... */`
- Rows returned remain at TaskState=0 (Pending) - will be returned again on next call
- Callers MUST NOT use this procedure for production scheduler processing - it will result in infinite re-processing of the same rows

**Diagram**:
```
GetScheduledTaskRabbitMqFtdEntities (standard)       GetScheduledTaskRabbitMqFtdEntitiesReadOnly
+-- #STS pre-select (TaskState=0, TaskID=2)          +-- #STS pre-select (TaskState=0, TaskID=2)
+-- INSERT #PostDepositTask (data)                   +-- INSERT #PostDepositTask (data)
+-- UPDATE #PostDepositTask (GCID + MopCountry)      +-- UPDATE #PostDepositTask (GCID + MopCountry)
+-- SELECT from #PostDepositTask                     +-- SELECT from #PostDepositTask
+-- UPDATE ScheduledTaskState SET TaskState=3   <--- THIS IS ABSENT IN READONLY VARIANT
```

### 2.2 FTD Data Logic (Inherited from Parent Procedure)

**What**: Identical filtering and data assembly as the non-ReadOnly variant.

**Rules** (same as `GetScheduledTaskRabbitMqFtdEntities` Section 2.1-2.3):
- TaskState=0, TaskID=2, PaymentStatusID=2, ModificationDate within 7 days
- IsFTD=1 filter on Stage 2 JOIN
- MopCountry: PayPal XML -> BIN country -> customer country fallback
- BankName: from Dictionary.CountryBin.IssuingBank
- GCID: filled in Stage 2 UPDATE from Customer.CustomerStatic

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Batch size cap. -1 means unlimited (internally converted to 2147483647 via IIF). Applied as TOP in the INSERT SELECT. Typically loaded from Billing.ScheduledTaskConfig.MaxEntitiesToFetch by the caller. |
| - | DepositID | INT | NO | - | CODE-BACKED | Primary key of the qualifying FTD deposit. From Billing.Deposit. |
| - | IsFTD | BIT | NO | - | CODE-BACKED | Always 1 in this result set - the INNER JOIN filters on IsFTD=1. Included for caller compatibility with the original procedure's schema. |
| - | GCID | INT | YES | - | CODE-BACKED | Global customer identifier from Customer.CustomerStatic. Populated in Stage 2 UPDATE. NULL if Customer.CustomerStatic has no row for this CID (edge case). |
| - | PaymentStatusID | INT | NO | - | CODE-BACKED | Always 2 (Approved) in this result set - filtered in both #STS and Stage 2 JOIN. Included for caller compatibility. |
| - | CID | INT | NO | - | CODE-BACKED | Customer ID who made the FTD. |
| - | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type used for this deposit. From Billing.Funding via FundingID JOIN. |
| - | IsRefundable | BIT | YES | - | CODE-BACKED | Whether this funding type supports refunds. From Dictionary.FundingType.IsRefundable. Used by RabbitMQ consumers for post-FTD bonus eligibility decisions. |
| - | MopCountry | VARCHAR(50) | YES | - | CODE-BACKED | Method of Payment Country - geographic origin of the payment. Resolution: PayPal XML country -> BIN issuing country -> customer's registered country (Stage 2 fallback). NULL only if customer has no country record. |
| - | BankName | VARCHAR(100) | YES | - | CODE-BACKED | Issuing bank name from Dictionary.CountryBin.IssuingBank (BIN lookup). NULL for non-card payment methods. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TaskID=2, TaskState=0 | Billing.ScheduledTaskState | SELECT (read-only) | Reads pending FTD task rows for data assembly. Does NOT update TaskState. |
| DepositID | Billing.Deposit | JOIN | Filters IsFTD=1, PaymentStatusID=2, within 7 days; source of CID, FundingID |
| FundingID | Billing.Funding | JOIN | Resolves FundingTypeID and FundingData XML |
| FundingTypeID | Dictionary.FundingType | JOIN | IsRefundable flag |
| FundingData XML | Dictionary.CountryBin | LEFT JOIN | BIN code lookup for issuing country and bank name |
| CID | Customer.CustomerStatic | JOIN (Stage 2) | GCID and fallback country |
| CountryID | Dictionary.Country | LEFT JOIN | Country name for MopCountry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitoring/diagnostic tools | @MaxEntitiesToFetch | EXEC | Queue inspection and debugging without claiming rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskRabbitMqFtdEntitiesReadOnly (procedure)
+-- Billing.ScheduledTaskState (table) [read-only: TaskID=2, TaskState=0]
+-- Billing.Deposit (table) [IsFTD=1, PaymentStatusID=2, 7-day filter]
+-- Billing.Funding (table) [FundingTypeID + FundingData XML]
+-- Dictionary.FundingType (table) [IsRefundable]
+-- Dictionary.CountryBin (table) [BIN->country + bank name]
+-- Dictionary.Country (table) [country name for MopCountry]
+-- Customer.CustomerStatic (table) [GCID + fallback country - Stage 2]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | SELECT pending rows (TaskState=0, TaskID=2) - NOT updated |
| Billing.Deposit | Table | IsFTD + PaymentStatusID + recency filter; CID, FundingID |
| Billing.Funding | Table | FundingTypeID + FundingData XML for BIN and PayPal lookups |
| Dictionary.FundingType | Table | IsRefundable flag |
| Dictionary.CountryBin | Table | BIN code -> issuing country + bank name |
| Dictionary.Country | Table | CountryID -> country name |
| Customer.CustomerStatic | Table | GCID + registered country (Stage 2 UPDATE) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No production callers identified | - | Intended for monitoring/debugging use; production uses GetScheduledTaskRabbitMqFtdEntities |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No TaskState update | Design | Rows remain at TaskState=0 after this call. Calling in a production loop would cause infinite re-processing of same rows. |
| PAYUS-2570 | Change history | UPDATE was deliberately removed to create a safe read-only inspection variant |
| NOLOCK throughout | Concurrency | All table reads use NOLOCK - consistent with the read-only intent |

---

## 8. Sample Queries

### 8.1 Inspect pending FTD queue without consuming it

```sql
-- Safe queue inspection - rows stay at TaskState=0
EXEC [Billing].[GetScheduledTaskRabbitMqFtdEntitiesReadOnly] @MaxEntitiesToFetch = 10
-- Returns up to 10 pending FTD rows without marking them as In Progress
```

### 8.2 Count pending FTD tasks directly

```sql
SELECT COUNT(*) AS PendingFtdTasks
FROM [Billing].[ScheduledTaskState] WITH (NOLOCK)
WHERE TaskState = 0
  AND TaskID = 2
```

### 8.3 Compare pending queue vs recently claimed (production vs read-only)

```sql
-- Pending (would be returned by ReadOnly procedure)
SELECT COUNT(*) AS Pending FROM [Billing].[ScheduledTaskState] WITH (NOLOCK) WHERE TaskState = 0 AND TaskID = 2

-- In Progress (claimed by production procedure)
SELECT COUNT(*) AS InProgress FROM [Billing].[ScheduledTaskState] WITH (NOLOCK) WHERE TaskState = 3 AND TaskID = 2

-- Completed
SELECT COUNT(*) AS Done FROM [Billing].[ScheduledTaskState] WITH (NOLOCK) WHERE TaskState = 2 AND TaskID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskRabbitMqFtdEntitiesReadOnly | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskRabbitMqFtdEntitiesReadOnly.sql*
