# AffiliateCommission.GetClosedPositionsFromEtoro

> Claims and returns a batch of unprocessed closed positions from the staging table, using an UPDATE TOP-OUTPUT locking pattern for concurrent-safe queue consumption.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns claimed ClosedPositionFromEtoro rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetClosedPositionsFromEtoro is the queue consumer for the closed position ingestion pipeline. When positions are closed on the trading platform, they are staged into the ClosedPositionFromEtoro table. This procedure claims a batch of unprocessed rows (up to @NumberOfMessages) by stamping them with a ProcessingDate and returns their data for downstream commission processing via InsertClosedPosition.

This procedure exists because closed position data arrives asynchronously from the trading platform. The staging table acts as a message queue, and this procedure implements the dequeue operation. The UPDATE TOP pattern with ProcessingDate provides at-least-once delivery: if processing fails, rows become re-eligible after 10 minutes (stale lock timeout).

The batch size parameter (@NumberOfMessages, default 100) allows tuning throughput vs memory usage. The 10-minute stale lock timeout ensures positions don't get stuck if a processing instance crashes.

---

## 2. Business Logic

### 2.1 Batch Claim with Stale Lock Recovery

**What**: Claims up to N unprocessed staging rows and auto-recovers stuck rows after 10 minutes.

**Columns/Parameters Involved**: `ProcessingDate`, `@NumberOfMessages`

**Rules**:
- UPDATE TOP(@NumberOfMessages) sets ProcessingDate = GETUTCDATE() to claim rows
- OUTPUT returns the claimed rows' position data
- Eligible rows: ProcessingDate IS NULL (never claimed) OR ProcessingDate < 10 minutes ago (stale claim, likely failed processing)
- The 10-minute window is hardcoded - allows failed processing to be retried automatically
- No NOLOCK hint - relies on row-level locking for correct concurrent access

**Diagram**:
```
Trading Platform -> ClosedPositionFromEtoro (staging)
                          |
                          v
       GetClosedPositionsFromEtoro (claim batch)
                          |
         +-- ProcessingDate IS NULL (new)
         +-- ProcessingDate < 10 min ago (stale/failed)
                          |
                          v
       OUTPUT -> Commission Engine -> InsertClosedPosition
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfMessages | int (IN) | YES | 100 | CODE-BACKED | Maximum number of staging rows to claim per call. Controls batch size for memory and throughput tuning. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | ClosedPositionID | bigint | - | - | CODE-BACKED | Unique position identifier from the trading platform. Becomes the PK in ClosedPosition. |
| 3 | CloseOccurred | datetime | - | - | CODE-BACKED | When the position was closed on the trading platform. |
| 4 | CID | bigint | - | - | CODE-BACKED | Customer ID who owned the position. |
| 5 | Commission | money | - | - | CODE-BACKED | Pre-calculated commission amount from the staging data. |
| 6 | NetProfit | money | - | - | CODE-BACKED | Position net profit/loss at close. |
| 7 | Lots | decimal | - | - | CODE-BACKED | Trade lot count. |
| 8 | OriginalProviderID | bigint | - | - | CODE-BACKED | Original broker/provider entity. |
| 9 | CountryID | int | - | - | CODE-BACKED | Customer's country. Added PART-2448. |
| 10 | ProviderID | bigint | - | - | CODE-BACKED | Current provider in the chain. |
| 11 | RealProviderID | bigint | - | - | CODE-BACKED | Actual executing provider. |
| 12 | GCID | bigint | - | - | CODE-BACKED | Global Customer ID. Added PART-3405. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPositionFromEtoro | READ+WRITE (UPDATE OUTPUT) | Claims unprocessed staging rows by setting ProcessingDate; outputs position data |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the closed position ingestion service to dequeue staged positions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetClosedPositionsFromEtoro (procedure)
+-- AffiliateCommission.ClosedPositionFromEtoro (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionFromEtoro | Table | UPDATE TOP + OUTPUT for batch claiming |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Position ingestion service) | External | Consumes staged positions for commission processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Claim a batch of 50 positions
```sql
EXEC [AffiliateCommission].[GetClosedPositionsFromEtoro] @NumberOfMessages = 50
```

### 8.2 Check for unprocessed staging rows
```sql
SELECT COUNT(*) AS UnprocessedCount
FROM [AffiliateCommission].[ClosedPositionFromEtoro] WITH (NOLOCK)
WHERE ProcessingDate IS NULL
    OR ProcessingDate < DATEADD(MINUTE, -10, GETUTCDATE())
```

### 8.3 View recent staging activity
```sql
SELECT TOP 10 ClosedPositionID, CID, CloseOccurred, ProcessingDate
FROM [AffiliateCommission].[ClosedPositionFromEtoro] WITH (NOLOCK)
ORDER BY ProcessingDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-3405: Added GCID to output (2025-02-23)
- PART-2448: CPA New Compensation Design + CountryID (2023-12-17)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetClosedPositionsFromEtoro | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetClosedPositionsFromEtoro.sql*
