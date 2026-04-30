# Monitoring.GetBounceBackAmountDiscrepancies

> Detects bounceback transactions where the sent amount does not match the originally received amount, indicating potential data integrity issues in the receive-then-bounceback flow.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns mismatched receive/send amount pairs with correlation IDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetBounceBackAmountDiscrepancies is an alert procedure that validates the financial integrity of bounceback transactions. A bounceback occurs when a received crypto transaction is returned to the sender (e.g., due to travel rule rejection, compliance issues, or failed AML checks). In a correct bounceback, the sent amount should exactly equal the received amount - any discrepancy indicates a potential bug or data corruption.

Without this procedure, amount mismatches in bouncebacks would go undetected, potentially resulting in customers receiving incorrect refund amounts or the platform losing/gaining crypto unintentionally. This is a critical financial reconciliation alert.

The procedure uses CorrelatedRequests to link parent (receive) and child (bounceback send) transactions via their correlation IDs. It sums amounts from ReceivedTransactions and SentTransactionOutputs independently, then returns only pairs where the amounts differ.

---

## 2. Business Logic

### 2.1 Bounceback Amount Matching

**What**: Validates that bounceback send amounts equal the original receive amounts.

**Columns/Parameters Involved**: `@FromHoursBack`, `@ToHoursBack`, `ReceiveAmount`, `SendAmount`, `Delta`

**Rules**:
- CorrelatedRequestsTypeId = 1 identifies bounceback correlations
- ReceiveAmount = SUM of amounts from ReceivedTransactions for the parent correlation ID
- SendAmount = SUM of amounts from SentTransactionOutputs for the child correlation ID
- Delta = ReceiveAmount - SendAmount (positive = sent less than received, negative = sent more)
- Only transactions created within the specified time window are checked
- Default window: last 12 hours, excluding the most recent 1 hour (allows processing time)

**Diagram**:
```
Receive Transaction (Parent)          Bounceback Send (Child)
  ReceiveRequestCorrelationId           CorrelationId
            |                                  |
            +--- CorrelatedRequests ---+
            |   (TypeId=1)             |
            v                          v
  SUM(ReceivedTransactions.Amount)   SUM(SentTransactionOutputs.Amount)
            |                          |
            +---- Compare ----+
                     |
              Delta != 0 -> ALERT
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromHoursBack | INT | NO | 12 | CODE-BACKED | Start of the lookback window (hours before current UTC time). Default 12 hours provides a full half-day of bounceback activity. |
| 2 | @ToHoursBack | INT | NO | 1 | CODE-BACKED | End of the lookback window (hours before current UTC time). Default 1 hour excludes very recent transactions that may still be in flight. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReceiveCorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID of the original receive transaction (parent). Used to trace back to the inbound crypto transfer. |
| 2 | SendCorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID of the bounceback send transaction (child). Used to trace the outbound return transfer. |
| 3 | ReceiveAmount | DECIMAL | NO | - | CODE-BACKED | Total amount received in the original transaction. Summed from ReceivedTransactions. |
| 4 | SendAmount | DECIMAL | NO | - | CODE-BACKED | Total amount sent in the bounceback. Summed from SentTransactionOutputs (may include multiple outputs per transaction). |
| 5 | Delta | DECIMAL | NO | - | CODE-BACKED | ReceiveAmount - SendAmount. Positive means less was sent back than received; negative means more was sent than received. Any non-zero value is a discrepancy. |
| 6 | ReceiveTime | DATETIME2 | YES | - | CODE-BACKED | Timestamp of the most recent receive transaction event. |
| 7 | SendTime | DATETIME2 | YES | - | CODE-BACKED | Timestamp of the most recent send transaction event. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.CorrelatedRequests | FROM (read) | Links parent receive to child bounceback send via CorrelatedRequestsTypeId = 1 |
| Query body | Wallet.ReceivedTransactions | LEFT JOIN | Sums received amounts by ReceiveRequestCorrelationId |
| Query body | Wallet.SentTransactions | LEFT JOIN | Finds send transactions for the child correlation ID |
| Query body | Wallet.SentTransactionOutputs | LEFT JOIN | Sums sent amounts per send transaction |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetBounceBackAmountDiscrepancies (procedure)
  ├── Wallet.CorrelatedRequests (table)
  ├── Wallet.ReceivedTransactions (table)
  ├── Wallet.SentTransactions (table)
  └── Wallet.SentTransactionOutputs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CorrelatedRequests | Table | FROM - correlates receive and bounceback requests |
| Wallet.ReceivedTransactions | Table | LEFT JOIN - receive amounts |
| Wallet.SentTransactions | Table | LEFT JOIN - send transactions for child correlation |
| Wallet.SentTransactionOutputs | Table | LEFT JOIN - individual output amounts per send |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run with default window (last 12 hours, excluding last 1 hour)
```sql
EXEC Monitoring.GetBounceBackAmountDiscrepancies;
```

### 8.2 Check wider window for retrospective analysis
```sql
EXEC Monitoring.GetBounceBackAmountDiscrepancies @FromHoursBack = 168, @ToHoursBack = 0;
```

### 8.3 Investigate a specific bounceback correlation chain
```sql
SELECT cr.ParentRequestCorrelationId, cr.ChildRequestCorrelationId, cr.Created
FROM Wallet.CorrelatedRequests cr WITH (NOLOCK)
WHERE cr.CorrelatedRequestsTypeId = 1
  AND cr.ParentRequestCorrelationId = '00000000-0000-0000-0000-000000000000';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetBounceBackAmountDiscrepancies | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetBounceBackAmountDiscrepancies.sql*
