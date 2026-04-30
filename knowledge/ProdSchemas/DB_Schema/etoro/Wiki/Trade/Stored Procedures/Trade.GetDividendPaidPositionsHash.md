# Trade.GetDividendPaidPositionsHash

> Computes a hash of all position IDs paid for a specific dividend, enabling integrity comparison between snapshot and payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDividendPaidPositionsHash computes a numeric hash of all position IDs that have been paid for a given dividend. By multiplying each PositionID by 0.000000001 and summing, it produces a lightweight fingerprint that can be compared between the snapshot positions and the paid positions to detect discrepancies (missing or extra payments).

This procedure is the companion to Trade.GetDividendNumPaidPositions. Together they provide a count + hash reconciliation: if both count and hash match the expected values, the payment is complete and correct.

---

## 2. Business Logic

### 2.1 Position Hash Calculation

**What**: Produces a deterministic fingerprint from the set of paid position IDs.

**Columns/Parameters Involved**: `@DividendID`, `PositionID`

**Rules**:
- Hash = SUM(PositionID * 0.000000001) across all rows for the dividend
- The multiplier converts large bigint PositionIDs into a manageable decimal sum
- If the same set of positions is paid, the hash will always match
- Uses OPTION(RECOMPILE) to avoid parameter sniffing issues

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DividendID | int | NO | - | CODE-BACKED | Dividend to compute the hash for. FK to Trade.IndexDividends. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendsPositionsHash | decimal | YES | - | CODE-BACKED | Sum of (PositionID * 0.000000001) for all paid positions. Used as a reconciliation fingerprint. |

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
Trade.GetDividendPaidPositionsHash (procedure)
+-- Trade.PositionsProcessedForIndexDividnds (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsProcessedForIndexDividnds | Table | SUM aggregation for hash |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by dividend payment service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses OPTION(RECOMPILE).

### 7.2 Constraints

None. Created 15-Mar-2022 by Adam Porat.

---

## 8. Sample Queries

### 8.1 Get paid positions hash

```sql
EXEC Trade.GetDividendPaidPositionsHash @DividendID = 42;
```

### 8.2 Full reconciliation check

```sql
EXEC Trade.GetDividendNumPaidPositions @DividendID = 42;
EXEC Trade.GetDividendPaidPositionsHash @DividendID = 42;
```

### 8.3 Direct hash computation

```sql
SELECT SUM(PositionID * 0.000000001) AS DividendsPositionsHash
FROM   Trade.PositionsProcessedForIndexDividnds WITH (NOLOCK)
WHERE  DividendID = 42
OPTION (RECOMPILE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDividendPaidPositionsHash | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDividendPaidPositionsHash.sql*
