# AffiliateCommission.LoadAffiliateTraderCreditQueue

> Dequeues a credit message from the Service Broker queue via Broker.actAffiliateTraderCredit and inserts it into the AffiliateTraderCreditQueue staging table with deduplication against both the queue and the Credit table.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateTraderCreditInfo XML OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

LoadAffiliateTraderCreditQueue bridges the Service Broker messaging system to the commission processing queue. It calls Broker.actAffiliateTraderCredit to dequeue one XML credit message from the Service Broker, then inserts it into AffiliateTraderCreditQueue for processing by the commission engine.

The procedure implements dual deduplication: it checks both the queue table AND the Credit table before inserting, ensuring neither in-flight nor already-processed credits are re-queued. The full XML message is returned as an OUTPUT parameter so the caller can also process it directly.

---

## 2. Business Logic

### 2.1 Service Broker Dequeue with Dual Deduplication

**What**: Dequeues a credit message and stages it with duplicate prevention.

**Columns/Parameters Involved**: `@AffiliateTraderCreditInfo`, `CreditID`

**Rules**:
- EXEC Broker.actAffiliateTraderCredit to dequeue one XML message
- If message is NOT NULL: extract CreditID from XML
- INSERT into AffiliateTraderCreditQueue WHERE NOT EXISTS in both queue AND Credit tables
- Transaction wraps the entire operation for atomicity
- The commented-out WHILE loop suggests this once filtered for first deposits only (IsFirstDeposit = 1)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateTraderCreditInfo | xml (OUTPUT) | YES | - | CODE-BACKED | The dequeued XML credit message from Service Broker. Contains all credit event data. Also returned to caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Broker.actAffiliateTraderCredit | EXEC | Dequeues message from Service Broker |
| - | AffiliateCommission.AffiliateTraderCreditQueue | WRITE (INSERT) + READ (EXISTS check) | Stages message with dedup |
| - | AffiliateCommission.Credit | READ (EXISTS check) | Checks if credit already processed |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by a SQL Agent job or service loop.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.LoadAffiliateTraderCreditQueue (procedure)
+-- Broker.actAffiliateTraderCredit (procedure, external)
+-- AffiliateCommission.AffiliateTraderCreditQueue (table)
+-- AffiliateCommission.Credit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Broker.actAffiliateTraderCredit | Procedure (external) | EXEC to dequeue Service Broker message |
| AffiliateCommission.AffiliateTraderCreditQueue | Table | INSERT with dedup check |
| AffiliateCommission.Credit | Table | EXISTS check to skip already-processed credits |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit processing loop) | External | Loads messages from Service Broker |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | TRAN | Atomic dequeue + stage with error handling |

---

## 8. Sample Queries

### 8.1 Load one credit message from Service Broker
```sql
DECLARE @Msg XML
EXEC [AffiliateCommission].[LoadAffiliateTraderCreditQueue] @AffiliateTraderCreditInfo = @Msg OUTPUT
SELECT @Msg AS DequeuedMessage
```

### 8.2 Check queue depth
```sql
SELECT COUNT(*) AS QueueDepth
FROM [AffiliateCommission].[AffiliateTraderCreditQueue] WITH (NOLOCK)
```

### 8.3 View recent queue entries
```sql
SELECT TOP 10 CreditID, DateCreated, DateModified
FROM [AffiliateCommission].[AffiliateTraderCreditQueue] WITH (NOLOCK)
ORDER BY DateCreated DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.LoadAffiliateTraderCreditQueue | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.LoadAffiliateTraderCreditQueue.sql*
