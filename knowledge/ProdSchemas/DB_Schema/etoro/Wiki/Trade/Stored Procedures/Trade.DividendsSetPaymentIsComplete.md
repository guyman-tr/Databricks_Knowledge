# Trade.DividendsSetPaymentIsComplete

> Marks dividend records as payment-complete (Status=2) in the production Trade.IndexDividends table after dividend payments have been successfully distributed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the **dividend payment lifecycle pipeline**. After dividend payments have been calculated and distributed to position holders, this procedure transitions the dividend records from Status=1 (Payment In Progress) to Status=2 (Payment Complete). This signals that all financial distributions for these dividends have been finalized and no further payment processing is needed.

The dividend lifecycle in Trade.IndexDividends follows this state machine:
- **Status 3** → Snapshot Pending
- **Status 4** → Snapshot Ready (set by Trade.DividendsSetSnapshotIsReady)
- **Status 1** → Payment In Progress
- **Status 2** → Payment Complete (set by **this procedure**)

---

## 2. Business Logic

### 2.1 Payment Completion Update

**What**: Transitions dividend records to payment-complete status.

**Columns/Parameters Involved**: `Trade.IndexDividends.Status`, `Trade.IndexDividends.DividendID`

**Rules**:
- UPDATE Trade.IndexDividends SET Status = 2
- JOIN @DividendIDs TVP on DividendID = Id
- WHERE Status = 1 (only updates records currently in "Payment In Progress")
- Guard clause prevents accidental re-processing of already-completed dividends

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DividendIDs | Trade.IdIntList (TVP) | READONLY | - | CODE-BACKED | List of DividendID values to mark as payment-complete. Only those currently at Status=1 will be updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DividendIDs | Trade.IndexDividends | Write | Updates Status from 1 → 2 |
| @DividendIDs | Trade.IdIntList | UDT (TVP) | Integer list table type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Dividends service) | N/A | Application caller | Called after all dividend payments are distributed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendsSetPaymentIsComplete (procedure)
+-- Trade.IndexDividends (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | Dividend state tracking |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Simple status transition procedure. The WHERE Status=1 guard ensures idempotency — calling it twice for the same DividendIDs has no effect. Created by Adam Porat on 16/03/2022. See also `Trade.DividendsSetPaymentIsComplete_DryRun` for the sandbox equivalent.

---

## 8. Sample Queries

### 8.1 Check dividend payment status

```sql
SELECT  DividendID, Status, InstrumentID
FROM    Trade.IndexDividends WITH (NOLOCK)
WHERE   Status IN (1, 2)
ORDER BY DividendID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DividendsSetPaymentIsComplete | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DividendsSetPaymentIsComplete.sql*
