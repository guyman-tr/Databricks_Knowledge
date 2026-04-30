# dbo.PaymentSpecificationDueStatuses

> Event-sourced status table tracking the outcome of individual payment due collections (direct debit payments), including the collected amount and correlation context.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (+ PK + unique) |

---

## 1. Business Meaning

PaymentSpecificationDueStatuses records the outcome of each individual direct debit collection event. When a payment due (from PaymentSpecificationDues) is collected, fails, or is otherwise processed, a status record is created here with the amount, correlation ID, and timestamp. Multiple statuses per due allow tracking retries and state changes.

Data is created by dbo.AddPaymentSpecificationDueStatusBulk via the PaymentSpecificationDueStatusType TVP for efficient batch processing of multiple due statuses.

---

## 2. Business Logic

### 2.1 Due Collection Outcome Tracking

**What**: Tracks the result of each direct debit collection attempt with financial details.

**Columns/Parameters Involved**: `DueId`, `DueStatusId`, `Amount`, `CorrelationId`, `EventTimestamp`

**Rules**:
- DueStatusId represents the collection outcome (specific values defined by the payment specification system)
- Amount captures the payment amount at the time of the status event
- CorrelationId links the collection to the triggering business operation
- Unique constraint on (DueId, DueStatusId, CorrelationId, EventTimestamp) prevents duplicate status events

---

## 3. Data Overview

N/A - querying live payment due status data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | DueId | bigint | NO | - | CODE-BACKED | FK to dbo.PaymentSpecificationDues.Id. The payment due this status belongs to. |
| 3 | DueStatusId | tinyint | NO | - | CODE-BACKED | Status of the payment due collection. Business meaning defined by the payment specification system. |
| 4 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Unique ID linking this status event to the business operation that triggered it. |
| 5 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the status event occurred in the source system. |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | When this record was written to the DWH. |
| 7 | Amount | decimal(36,18) | NO | - | CODE-BACKED | Payment amount at the time of this status event. High precision supports multi-currency calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DueId | dbo.PaymentSpecificationDues | FK | The payment due this status belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddPaymentSpecificationDueStatusBulk | INSERT | Writer | Bulk inserts due statuses via TVP |
| dbo.GetPaymentSpecificationDueStatusesMapping | SELECT | Reader | Maps due statuses for provider reconciliation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.PaymentSpecificationDueStatuses (table)
└── dbo.PaymentSpecificationDues (table)
    └── dbo.PaymentSpecifications (table)
        └── dbo.FiatCurrencyBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecificationDues | Table | FK from DueId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddPaymentSpecificationDueStatusBulk | Stored Procedure | Bulk writes statuses |
| dbo.GetPaymentSpecificationDueStatusesMapping | Stored Procedure | Reads for mapping |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentSpecificationDueStatuses | CLUSTERED | Id ASC | - | - | Active |
| IX_PaymentSpecificationDueStatuses | NC UNIQUE | DueId, DueStatusId, CorrelationId, EventTimestamp | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PaymentSpecificationDueStatuses_DueId_PaymentSpecificationDues_Id | FK | DueId -> dbo.PaymentSpecificationDues.Id |

---

## 8. Sample Queries

### 8.1 Get status history for a payment due
```sql
SELECT DueStatusId, Amount, CorrelationId, EventTimestamp, Created
FROM dbo.PaymentSpecificationDueStatuses WITH (NOLOCK)
WHERE DueId = 100 ORDER BY EventTimestamp;
```

### 8.2 Find recent due statuses
```sql
SELECT ds.DueId, d.PaymentSpecificationDueGuid, ds.DueStatusId, ds.Amount, ds.EventTimestamp
FROM dbo.PaymentSpecificationDueStatuses ds WITH (NOLOCK)
JOIN dbo.PaymentSpecificationDues d WITH (NOLOCK) ON d.Id = ds.DueId
WHERE ds.Created >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY ds.Created DESC;
```

### 8.3 Total collected amount per specification
```sql
SELECT ps.PaymentSpecificationGuid, SUM(ds.Amount) AS TotalCollected
FROM dbo.PaymentSpecificationDueStatuses ds WITH (NOLOCK)
JOIN dbo.PaymentSpecificationDues d WITH (NOLOCK) ON d.Id = ds.DueId
JOIN dbo.PaymentSpecifications ps WITH (NOLOCK) ON ps.Id = d.PaymentSpecificationId
GROUP BY ps.PaymentSpecificationGuid
ORDER BY TotalCollected DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentSpecificationDueStatuses | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.PaymentSpecificationDueStatuses.sql*
