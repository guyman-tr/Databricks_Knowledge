# Trade.InstrumentHedgeServerPairData

> TVP for querying commissions by instrument-and-hedge-server pairs. Each row specifies one instrument/server combination.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID, HedgeServerID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.InstrumentHedgeServerPairData is a table-valued parameter for querying commissions by instrument-and-hedge-server pairs. Each row specifies an instrument/hedge server combination for which commission data is needed. InstrumentID references Trade.Instrument, HedgeServerID references Trade.HedgeServer. Used by dealing/hedging operations to look up commission rates for specific instrument/server combinations.

---

## 2. Business Logic

### 2.1 Batch commission lookup by instrument and hedge server

**What**: The TVP passes pairs of (InstrumentID, HedgeServerID). GetCommissionsByInstrumentHedgeServer returns commission data for each pair in one call.

**Columns/Parameters Involved**: InstrumentID, HedgeServerID

**Rules**: Both IDs required. InstrumentID must exist in Trade.Instrument; HedgeServerID must exist in Trade.HedgeServer. Duplicate pairs may be allowed depending on procedure logic.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | No | - | 10 | Instrument identifier (Trade.Instrument) |
| 2 | HedgeServerID | int | No | - | 10 | Hedge server identifier (Trade.HedgeServer) |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.Instrument (InstrumentID) | Implicit reference |
| Trade.HedgeServer (HedgeServerID) | Implicit reference |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.GetCommissionsByInstrumentHedgeServer | Parameter @instrumentHedgePairs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.GetCommissionsByInstrumentHedgeServer

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query commissions for instrument/hedge pairs

```sql
DECLARE @instrumentHedgePairs Trade.InstrumentHedgeServerPairData;
INSERT INTO @instrumentHedgePairs (InstrumentID, HedgeServerID)
VALUES (100, 1), (100, 2), (101, 1);
EXEC Trade.GetCommissionsByInstrumentHedgeServer @instrumentHedgePairs = @instrumentHedgePairs;
```

### 8.2 Build pairs from Instrument table

```sql
DECLARE @P Trade.InstrumentHedgeServerPairData;
INSERT INTO @P (InstrumentID, HedgeServerID)
SELECT i.InstrumentID, 1
FROM Trade.Instrument i
WHERE i.InstrumentTypeID = 5;
EXEC Trade.GetCommissionsByInstrumentHedgeServer @instrumentHedgePairs = @P;
```

### 8.3 Verify type columns

```sql
SELECT c.name, t.name AS type_name
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'InstrumentHedgeServerPairData';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.GetCommissionsByInstrumentHedgeServer*
*Object: Trade.InstrumentHedgeServerPairData | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentHedgeServerPairData.sql*
