# Trade.PositionAnsDividendTbl

> A table-valued parameter type for marking positions as having answered (received) dividend payments - pairs PositionID with DividendID for audit and payment tracking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID, DividendID |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.PositionAnsDividendTbl is a TVP type for passing batches of position-dividend pairs to Trade.MarkDividendPositionAsPaid. When a dividend is paid to a position holder, the system records that the position has "answered" (received) that dividend. Each row links a PositionID to a DividendID.

This type exists to support dividend payment tracking and audit. After PayDividendsForPositions or similar logic pays dividends, MarkDividendPositionAsPaid is called with this TVP to record which positions received which dividends. This prevents double-payment and supports reconciliation.

The dividend payment flow builds this TVP from payment results and passes it to MarkDividendPositionAsPaid.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. PositionID+DividendID form a logical pair for marking paid status.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position that received the dividend payment. |
| 2 | DividendID | int | NO | - | CODE-BACKED | Dividend record identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID references Trade.PositionTbl; DividendID references dividend master data.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.MarkDividendPositionAsPaid | @positiondividendTbl | Parameter (TVP) | Marks positions as having received the specified dividends |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.MarkDividendPositionAsPaid | Stored Procedure | READONLY parameter for marking dividend-paid status |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate after dividend payment

```sql
DECLARE @Paid Trade.PositionAnsDividendTbl;
INSERT INTO @Paid (PositionID, DividendID)
VALUES (900000001, 100), (900000002, 100);

EXEC Trade.MarkDividendPositionAsPaid @positiondividendTbl = @Paid;
```

### 8.2 Build from payment results

```sql
DECLARE @Paid Trade.PositionAnsDividendTbl;
INSERT INTO @Paid (PositionID, DividendID)
SELECT  PositionID, @DividendID
FROM    @PositionsForDividendPaymentTbl
WHERE   -- filter to successfully paid positions
;

EXEC Trade.MarkDividendPositionAsPaid @positiondividendTbl = @Paid;
```

### 8.3 Inspect structure

```sql
SELECT c.name, t.name AS type_name
FROM   sys.table_types tt
       JOIN sys.columns c ON c.object_id = tt.type_table_object_id
       JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE  tt.name = 'PositionAnsDividendTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionAnsDividendTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionAnsDividendTbl.sql*
