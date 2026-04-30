# Trade.DividendsPaidTbl

> Simple TVP pairing PositionIDs with DividendIDs to query paid dividend amounts in batch.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID, DividendID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.DividendsPaidTbl is a table-valued parameter that pairs positions with dividends. It is used when the application needs to look up how much was paid for a set of position/dividend combinations in a single call. The procedure Trade.GetDividendsPaidAmount accepts this TVP via the @paidDividends parameter and returns paid amounts for each pair.

Each row represents one position-dividend combination. The procedure uses these pairs to query stored dividend payment data and return the corresponding paid amounts.

---

## 2. Business Logic

### 2.1 Position-dividend pair lookup

**What**: The TVP carries position and dividend pairs. The consuming procedure looks up paid amounts for each pair in one batch instead of multiple round trips.

**Columns/Parameters Involved**: PositionID, DividendID

**Rules**: Both columns are NOT NULL. Each pair should represent a valid position and dividend combination for which paid amount lookup is needed.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | No | - | 10 | Position identifier |
| 2 | DividendID | int | No | - | 10 | Dividend identifier (Trade.IndexDividends) |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.PositionTbl (PositionID) | Implicit reference to position |
| Trade.IndexDividends (DividendID) | Implicit reference to dividend |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.GetDividendsPaidAmount | Parameter @paidDividends |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.GetDividendsPaidAmount

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Call GetDividendsPaidAmount with TVP

```sql
DECLARE @paidDividends Trade.DividendsPaidTbl;
INSERT INTO @paidDividends (PositionID, DividendID)
VALUES (1001, 42), (1002, 42), (1003, 43);
EXEC Trade.GetDividendsPaidAmount @paidDividends = @paidDividends;
```

### 8.2 Build TVP from open positions and dividend

```sql
DECLARE @paid Trade.DividendsPaidTbl;
INSERT INTO @paid (PositionID, DividendID)
SELECT p.PositionID, @DividendID
FROM Trade.PositionTbl p
WHERE p.InstrumentID = @InstrumentID AND p.Status = 1;
```

### 8.3 Inspect type definition

```sql
SELECT c.name, t.name AS type_name
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'DividendsPaidTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.GetDividendsPaidAmount procedure*
*Object: Trade.DividendsPaidTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DividendsPaidTbl.sql*
