# Trade.GetDividendsPaidAmount

> Returns the previously paid amount for a batch of position-dividend pairs, enabling the payment service to calculate the remaining amount for corrections or retake dividends.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @paidDividends (TVP of PositionID + DividendID pairs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDividendsPaidAmount looks up how much has already been paid for specific position-dividend combinations. This is needed when processing correction dividends or retake dividends - the payment service needs to know the prior payment amount to calculate the difference (top-up or reclaim).

This procedure exists because dividend corrections require knowing the original payment. If a dividend amount changes after initial payment (e.g., tax rate correction), the system pays the difference, not the full amount. This procedure retrieves the original PaymentAmount from Trade.PositionsProcessedForIndexDividnds.

Data flows: The @paidDividends TVP (PositionID + DividendID pairs) is loaded into a temp table with an index for performance, then joined to Trade.PositionsProcessedForIndexDividnds on both PositionID and DividendID.

---

## 2. Business Logic

### 2.1 Previous Payment Lookup

**What**: Retrieves prior payment amounts for correction/retake calculations.

**Columns/Parameters Involved**: `@paidDividends`, `PaymentAmount`, `PositionID`, `DividendID`

**Rules**:
- IIF(PaymentAmount IS NULL, 0, PaymentAmount): returns 0 if no previous payment exists
- Joined on both PositionID AND DividendID (composite key lookup)
- Temp table #TempPaid with nonclustered index on (DividendID, PositionID) for optimal join

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @paidDividends | Trade.DividendsPaidTbl (TVP) | NO | - | CODE-BACKED | Table-valued parameter with PositionID + DividendID pairs to look up. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PreviousPaid | money | NO | - | CODE-BACKED | Amount previously paid for this position-dividend pair. 0 if no prior payment. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Position the payment was for. |
| 3 | DividendID | int | NO | - | CODE-BACKED | Dividend the payment was for. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID, DividendID | Trade.PositionsProcessedForIndexDividnds | JOIN | Prior payment records |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDividendsPaidAmount (procedure)
+-- Trade.PositionsProcessedForIndexDividnds (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsProcessedForIndexDividnds | Table | JOIN - prior payment lookup |
| Trade.DividendsPaidTbl | User Defined Type | TVP for input pairs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by dividend correction service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Creates temp table index: IX_PositionID_DividendID on #TempPaid (DividendID, PositionID).

### 7.2 Constraints

None. Uses SET NOCOUNT ON.

---

## 8. Sample Queries

### 8.1 Look up previous payments for position-dividend pairs

```sql
DECLARE @paid Trade.DividendsPaidTbl;
INSERT INTO @paid (PositionID, DividendID) VALUES (100001, 42), (100002, 42);
EXEC Trade.GetDividendsPaidAmount @paidDividends = @paid;
```

### 8.2 Direct query for a specific position's dividend history

```sql
SELECT PositionID, DividendID, PaymentAmount
FROM   Trade.PositionsProcessedForIndexDividnds WITH (NOLOCK)
WHERE  PositionID = 100001;
```

### 8.3 Check total paid for a dividend

```sql
SELECT DividendID, SUM(PaymentAmount) AS TotalPaid, COUNT(*) AS PositionsPaid
FROM   Trade.PositionsProcessedForIndexDividnds WITH (NOLOCK)
WHERE  DividendID = 42
GROUP BY DividendID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDividendsPaidAmount | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDividendsPaidAmount.sql*
