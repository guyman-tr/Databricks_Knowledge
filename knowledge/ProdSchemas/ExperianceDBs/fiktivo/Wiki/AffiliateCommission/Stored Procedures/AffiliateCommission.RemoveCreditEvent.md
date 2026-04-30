# AffiliateCommission.RemoveCreditEvent

> Deletes a single credit event by ID after commission calculation has completed, preventing reprocessing of already-handled credit events.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from CreditEvent by ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveCreditEvent is the cleanup counterpart to the credit commission pipeline. When a credit event (deposit, chargeback, or other financial transaction) triggers commission calculation, it is first picked up by GetCreditTriggeredEvents, evaluated against the affiliate agreement, and the resulting commission is persisted via SaveCreditCommission. Once that entire flow completes successfully, this procedure removes the event so it will not be re-evaluated.

The credit event lifecycle follows a produce-consume-delete pattern. InsertCreditEvent creates the record, GetCreditTriggeredEvents reads it, the commission engine processes it, and RemoveCreditEvent finalizes it. This explicit deletion step - rather than a status flag - keeps the CreditEvent table small and fast for the triggered-events query that powers the next processing cycle.

The single-ID deletion model ensures the calling service has full control over which events are removed. If a batch of events is being processed and one fails, only the successfully processed events are deleted while the failed one remains for retry.

---

## 2. Business Logic

### 2.1 Single-Row Event Deletion

**What**: Removes exactly one processed credit event by its primary key.

**Columns/Parameters Involved**: `@ID`, `CreditEvent.ID`

**Rules**:
- DELETE FROM CreditEvent WHERE ID = @ID
- Only one row is affected per call (ID is the primary key)
- Called only after commission calculation and persistence complete
- If the ID does not exist, the DELETE is a no-op (no error raised)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint (IN) | NO | - | CODE-BACKED | Primary key of the CreditEvent row to delete. Corresponds to the ID returned by GetCreditTriggeredEvents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | AffiliateCommission.CreditEvent | WRITE (DELETE) | Removes the event row by primary key |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline after SaveCreditCommission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveCreditEvent (procedure)
+-- AffiliateCommission.CreditEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEvent | Table | DELETE by primary key |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Removes processed credit events after commission is saved |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove a processed credit event
```sql
EXEC [AffiliateCommission].[RemoveCreditEvent] @ID = 78500
```

### 8.2 Verify the event was removed
```sql
SELECT ID, CreditID, AffiliateID, CreditDate, [Source]
FROM [AffiliateCommission].[CreditEvent] WITH (NOLOCK)
WHERE ID = 78500
```

### 8.3 Count remaining unprocessed credit events by source
```sql
SELECT [Source], COUNT(*) AS RemainingEvents
FROM [AffiliateCommission].[CreditEvent] WITH (NOLOCK)
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveCreditEvent | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveCreditEvent.sql*
