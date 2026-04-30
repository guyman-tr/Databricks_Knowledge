# Monitoring.GetMismatchedAmountBounceBackTransactions

> Detects bounceback transactions where the amount specified in the bounceback request's JSON payload does not match the sum of received transaction amounts, using CorrelatedRequests to link parent receives to child bouncebacks.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns mismatched bounceback amounts with receive/send correlation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetMismatchedAmountBounceBackTransactions is a financial integrity alert that compares the BounceBackAmount (extracted from the request's DetailsJson via JSON_VALUE) against the total ReceivedAmount for the linked receive transaction. Unlike GetBounceBackAmountDiscrepancies which compares sent vs received amounts at the transaction level, this procedure compares the request-level bounceback amount against what was actually received.

Without this procedure, discrepancies between the requested bounceback amount and the actual received amount would go undetected, potentially resulting in incorrect refund amounts being sent back to customers.

The procedure identifies bounceback requests by looking for requests with RequestTypeId=1 (send transactions) that have bounceback status IDs (36, 37, or 38), then extracts the Amount from the request's JSON payload and compares it against the sum of received transaction amounts via CorrelatedRequests linking.

---

## 2. Business Logic

### 2.1 JSON Amount vs Received Amount Comparison

**What**: Validates that the bounceback amount in the request JSON matches what was actually received.

**Columns/Parameters Involved**: `DetailsJson`, `Amount`, `BounceBackAmount`, `ReceivedAmount`

**Rules**:
- BounceBackAmount = JSON_VALUE(r.DetailsJson, '$.Amount') parsed as DECIMAL(36,18)
- ReceivedAmount = SUM(rt.Amount) from ReceivedTransactions for the parent correlation
- Mismatch threshold: ABS(ReceivedAmount - BounceBackAmount) > 0.000000000000000001 (accounts for floating-point precision)
- Only requests with DetailsJson containing 'Amount' field are checked
- Default lookback: 2 weeks from current UTC time

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartFrom | DATETIME | YES | NULL (defaults to 2 weeks ago) | CODE-BACKED | Start of analysis window. If NULL, defaults to DATEADD(WEEK, -2, GETUTCDATE()). |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReceiveRequestCorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Parent receive correlation ID. |
| 2 | BounceBackRequestCorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Child bounceback send correlation ID. |
| 3 | ReceivedAmount | DECIMAL | NO | - | CODE-BACKED | Total amount from ReceivedTransactions for the parent. |
| 4 | BounceBackAmount | DECIMAL | NO | - | CODE-BACKED | Amount from the bounceback request's JSON payload. |
| 5 | Timestamp | DATETIME2 | NO | - | CODE-BACKED | When the bounceback request was created. |
| 6 | Gcid | INT | NO | - | CODE-BACKED | Customer ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Source of bounceback request details and JSON amounts |
| Query body | Wallet.RequestStatuses | JOIN | Identifies bounceback statuses (36, 37, 38) |
| Query body | Wallet.CorrelatedRequests | JOIN | Links child bounceback to parent receive |
| Query body | Wallet.ReceivedTransactions | GROUP BY/SUM | Calculates total received amount |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetMismatchedAmountBounceBackTransactions (procedure)
  ├── Wallet.Requests (table)
  ├── Wallet.RequestStatuses (table)
  ├── Wallet.CorrelatedRequests (table)
  └── Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - request metadata and JSON payload |
| Wallet.RequestStatuses | Table | JOIN - bounceback status detection |
| Wallet.CorrelatedRequests | Table | JOIN - parent/child correlation |
| Wallet.ReceivedTransactions | Table | SUM - received amount calculation |

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

### 8.1 Check last 2 weeks (default)
```sql
EXEC Monitoring.GetMismatchedAmountBounceBackTransactions;
```

### 8.2 Check specific date range
```sql
EXEC Monitoring.GetMismatchedAmountBounceBackTransactions @StartFrom = '2026-04-01';
```

### 8.3 View recent bounceback requests with their JSON amounts
```sql
SELECT TOP 10 r.Id, r.CorrelationId, r.Gcid,
  JSON_VALUE(r.DetailsJson, '$.Amount') AS JsonAmount, r.Timestamp
FROM Wallet.Requests r WITH (NOLOCK)
INNER JOIN Wallet.RequestStatuses rs WITH (NOLOCK) ON r.Id = rs.RequestId
WHERE rs.RequestStatusId IN (36, 37, 38) AND r.DetailsJson LIKE '%Amount%'
ORDER BY r.Timestamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetMismatchedAmountBounceBackTransactions | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetMismatchedAmountBounceBackTransactions.sql*
