# Billing.GetScheduledTaskDepositEntities

> Post-deposit scheduler fetch for TaskID=7 (general deposit entity processing): claims pending ScheduledTaskState rows, returns DepositID, GCID, CID, PaymentStatusID, FundingTypeID via INSERT...OUTPUT pattern, marks claimed rows as TaskState=3.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch (batch cap); returns one row per claimed deposit via OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetScheduledTaskDepositEntities` is the batch-fetch step for the generic deposit entity processing pipeline (TaskID=7). Unlike the specific AppsFlyer, Pixel, and Mixpanel schedulers, this procedure does not filter by PaymentStatusID - it claims all pending deposits regardless of outcome, returning the core identifiers and funding type needed for general-purpose deposit processing.

Uses the `INSERT INTO ... OUTPUT ...` pattern to return results while simultaneously inserting into the `#PostDepositTask` temp table for the subsequent UPDATE. The `OPTION(FAST 10)` hint instructs the optimizer to produce a plan optimized for the first 10 rows, suitable for interactive/low-latency processing scenarios.

---

## 2. Business Logic

### 2.1 TaskID=7 Batch Claim

**What**: Claims pending deposits for TaskID=7 without payment status filtering.

**Rules**:
- `WHERE STS.TaskState = 0 AND STS.TaskID = 7` - no PaymentStatusID filter (all payment outcomes)
- `INSERT INTO #PostDepositTask OUTPUT INSERTED.*` - returns results via OUTPUT clause while populating temp table
- `UPDATE STS SET TaskState=3 FROM #PostDepositTask` - atomic claim after SELECT
- `OPTION(FAST 10)` - query hint favoring first-10-row retrieval optimization

### 2.2 Minimal Result Set

**What**: Returns only the essential identifiers needed for downstream processing.

**Rules**:
- Returns 5 columns: DepositID, GCID, CID, PaymentStatusID, FundingTypeID
- Does not include amount, currency, IP, or attribution data (contrast with AppsFlyer/Pixel/Mixpanel procedures)
- Downstream processor determines what to do with the deposit based on PaymentStatusID and FundingTypeID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Maximum batch size. -1 = no limit. Typically loaded from ScheduledTaskConfig.MaxEntitiesToFetch for TaskID=7 (500). |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositID | INT | NO | - | CODE-BACKED | PK of the claimed deposit. |
| 3 | GCID | INT | YES | - | CODE-BACKED | Global customer identifier from `Customer.CustomerStatic`. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer identifier from `Customer.CustomerStatic`. |
| 5 | PaymentStatusID | INT | YES | - | CODE-BACKED | Deposit payment status. Not filtered - all outcomes returned. |
| 6 | FundingTypeID | INT | YES | - | CODE-BACKED | Payment method type from `Billing.Funding`. FK to `Dictionary.FundingType`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.ScheduledTaskState | SELECT + UPDATE | Claim TaskID=7 pending rows; mark TaskState=3 |
| DepositID | Billing.Deposit | INNER JOIN | DepositID, PaymentStatusID |
| D.CID | Customer.CustomerStatic | INNER JOIN | GCID, CID |
| D.FundingID | Billing.Funding | INNER JOIN | FundingTypeID |
| F.FundingTypeID | Dictionary.FundingType | INNER JOIN | FundingTypeID validation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit entity processing scheduler (TaskID=7) | @MaxEntitiesToFetch | EXEC | Generic deposit processing batch fetch |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskDepositEntities (procedure)
+-- Billing.ScheduledTaskState (table)
+-- Billing.Deposit (table)
+-- Customer.CustomerStatic (table, cross-schema)
+-- Billing.Funding (table)
+-- Dictionary.FundingType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | Claim pending TaskID=7 rows; mark TaskState=3 |
| Billing.Deposit | Table | DepositID, PaymentStatusID |
| Customer.CustomerStatic | Table | GCID, CID |
| Billing.Funding | Table | FundingTypeID |
| Dictionary.FundingType | Table | FundingTypeID JOIN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit entity processing worker | External | Generic deposit event processing |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INSERT...OUTPUT pattern | Design | Returns data via OUTPUT clause; differs from SELECT * used in other entity procedures |
| OPTION(FAST 10) | Performance hint | Optimizer targets low-latency first-10-row retrieval |
| No PaymentStatusID filter | Design | All deposit outcomes included (unlike AppsFlyer/Pixel/Mixpanel which require status=2) |
| No #STS pre-filter | Design | Does not use the two-stage #STS optimization (PAYUS-1254 pattern) |

---

## 8. Sample Queries

### 8.1 Fetch deposit entity batch
```sql
EXEC Billing.GetScheduledTaskDepositEntities @MaxEntitiesToFetch = 500;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskDepositEntities | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskDepositEntities.sql*
