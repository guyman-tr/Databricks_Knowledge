# Trade.GetCommissionsByInstrumentHedgeServer_New_SS

> Sequential scan variant of commission aggregation that processes instruments one at a time using an index hint on IDX_TBT_IsComputeForHedge, designed for better performance with specific query plans.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated commissions grouped by InstrumentID and HedgeServerID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a performance-optimized variant of Trade.GetCommissionsByInstrumentHedgeServer_New, created by Ran Ovadia on 2020-12-24. Instead of joining the full TVP to PositionTbl in a single query (which may produce suboptimal plans for certain data distributions), it processes instruments one at a time in a WHILE loop, forcing the optimizer to use the IDX_TBT_IsComputeForHedge index for each instrument lookup.

The "SS" likely stands for "Sequential Scan" or "Single-Seek", referring to the strategy of processing each instrument individually with forced index usage rather than relying on the optimizer to handle the batch efficiently.

Data flow: Hedge service provides instrument IDs -> procedure copies to temp table with clustered index -> iterates instrument by instrument -> forces index IDX_TBT_IsComputeForHedge on each lookup -> accumulates results in #t2 -> returns all rows.

---

## 2. Business Logic

### 2.1 Sequential Index-Forced Commission Aggregation

**What**: Processes each instrument individually with forced index usage for predictable performance.

**Columns/Parameters Involved**: `IsComputeForHedge`, `StatusID`, `InstrumentID`, `Commission`, `FullCommission`

**Rules**:
- Same business filters as _New variant: IsComputeForHedge=1 AND StatusID=1 (open positions only)
- Processes instruments one at a time in a WHILE loop for plan stability
- Forces use of IDX_TBT_IsComputeForHedge index via index hint
- Results accumulated in temp table #t2, returned at the end
- Input TVP copied to #t1 with a clustered index on Id for ordered iteration

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instruments | BigIntTableInMem (TVP) | NO | - | CODE-BACKED | Memory-optimized table-valued parameter containing InstrumentIDs to query. Copied to #t1 for sequential processing. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. |
| 2 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server handling the instrument. |
| 3 | TotalCommission | FLOAT | NO | - | CODE-BACKED | Sum of net commissions (stored as float in temp table, converted from money). |
| 4 | TotalFullCommission | FLOAT | NO | - | CODE-BACKED | Sum of full (gross) commissions (stored as float in temp table, converted from money). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.PositionTbl | Index-forced lookup | Queries positions per instrument using forced IDX_TBT_IsComputeForHedge index |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Service | EXEC | Caller | Uses for commission aggregation when the standard join variant has plan issues |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCommissionsByInstrumentHedgeServer_New_SS (procedure)
├── Trade.PositionTbl (table)
└── dbo.BigIntTableInMem (user defined type, memory-optimized)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of commission data with forced index IDX_TBT_IsComputeForHedge |
| BigIntTableInMem | User Defined Type | Memory-optimized TVP for instrument ID list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Service | External | Alternative commission aggregation with predictable plans |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses index hint: `WITH (NOLOCK, index=IDX_TBT_IsComputeForHedge)` on Trade.PositionTbl.

### 7.2 Constraints

- Uses WHILE loop with DELETE for sequential processing - not set-based
- Temp table #t2 uses FLOAT instead of MONEY for commission columns (potential precision difference)
- Drops temp tables with IF EXISTS for re-runnability

---

## 8. Sample Queries

### 8.1 Equivalent direct query using the forced index

```sql
SELECT TP.InstrumentID, TP.HedgeServerID,
       SUM(Commission) AS TotalCommission,
       SUM(FullCommission) AS TotalFullCommission
FROM Trade.PositionTbl TP WITH (NOLOCK, INDEX=IDX_TBT_IsComputeForHedge)
WHERE TP.IsComputeForHedge = 1 AND TP.StatusID = 1
      AND TP.InstrumentID = 1001
GROUP BY TP.InstrumentID, TP.HedgeServerID;
```

### 8.2 Check which instruments have hedgeable open positions

```sql
SELECT DISTINCT InstrumentID
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE IsComputeForHedge = 1 AND StatusID = 1
ORDER BY InstrumentID;
```

### 8.3 Compare MONEY vs FLOAT precision for commission totals

```sql
SELECT TP.InstrumentID,
       SUM(Commission) AS CommissionAsMoney,
       CAST(SUM(Commission) AS FLOAT) AS CommissionAsFloat
FROM Trade.PositionTbl TP WITH (NOLOCK)
WHERE TP.IsComputeForHedge = 1 AND TP.StatusID = 1
GROUP BY TP.InstrumentID
HAVING ABS(CAST(SUM(Commission) AS FLOAT) - CAST(SUM(Commission) AS MONEY)) > 0.001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCommissionsByInstrumentHedgeServer_New_SS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCommissionsByInstrumentHedgeServer_New_SS.sql*
