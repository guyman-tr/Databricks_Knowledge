# Trade.GetDividendNumPaidPositions

> Returns the count of positions that have been processed (paid) for a specific dividend, used for dividend payment reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDividendNumPaidPositions counts how many positions have already received payment for a given dividend ID. This is used by the dividend payment pipeline to track processing progress and for reconciliation - comparing the number of paid positions against the expected snapshot count.

This procedure exists because dividends are paid to individual positions (not customers), and processing happens in batches. The service needs to know how many positions have been paid so far for a given dividend to track completion and detect issues.

Data flows from Trade.PositionsProcessedForIndexDividnds, which records each position that has been paid for a given dividend. COUNT_BIG returns the total count.

---

## 2. Business Logic

### 2.1 Paid Position Count

**What**: Simple aggregate count of positions paid for a dividend.

**Columns/Parameters Involved**: `@DividendID`, `DividendID`

**Rules**:
- COUNT_BIG(1) counts all rows in PositionsProcessedForIndexDividnds where DividendID matches
- Returns a single scalar value: NumPaidPositions
- Used alongside GetDividendPaidPositionsHash for integrity verification

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DividendID | int | NO | - | CODE-BACKED | Dividend to count paid positions for. FK to Trade.IndexDividends. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NumPaidPositions | bigint | NO | - | CODE-BACKED | Total count of positions that have been paid for this dividend. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DividendID | Trade.PositionsProcessedForIndexDividnds | FROM | Paid positions tracking table |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDividendNumPaidPositions (procedure)
+-- Trade.PositionsProcessedForIndexDividnds (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsProcessedForIndexDividnds | Table | COUNT_BIG - paid positions count |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by dividend payment service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Created 15-Mar-2022 by Adam Porat.

---

## 8. Sample Queries

### 8.1 Get paid position count for a dividend

```sql
EXEC Trade.GetDividendNumPaidPositions @DividendID = 42;
```

### 8.2 Compare count with hash for reconciliation

```sql
EXEC Trade.GetDividendNumPaidPositions @DividendID = 42;
EXEC Trade.GetDividendPaidPositionsHash @DividendID = 42;
```

### 8.3 Direct count query

```sql
SELECT COUNT_BIG(1) AS NumPaidPositions
FROM   Trade.PositionsProcessedForIndexDividnds WITH (NOLOCK)
WHERE  DividendID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDividendNumPaidPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDividendNumPaidPositions.sql*
