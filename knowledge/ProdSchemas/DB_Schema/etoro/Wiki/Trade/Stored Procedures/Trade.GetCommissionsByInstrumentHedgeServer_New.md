# Trade.GetCommissionsByInstrumentHedgeServer_New

> Improved version of GetCommissionsByInstrumentHedgeServer that uses a memory-optimized TVP and adds StatusID=1 filter to only aggregate commissions from open positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated commissions grouped by InstrumentID and HedgeServerID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the updated version of Trade.GetCommissionsByInstrumentHedgeServer, created by Ran Ovadia on 2020-12-24. It uses a memory-optimized table type (BigIntTableInMem) instead of the custom InstrumentHedgeServerPairData TVP, and crucially adds a StatusID=1 filter to limit aggregation to open positions only. The original procedure lacked this filter, meaning it could include commissions from closed positions.

The procedure serves the same hedge service use case: aggregating commission exposure per instrument per hedge server for accurate hedging calculations. The improvement ensures only currently open (active) positions contribute to the hedge commission total.

Data flow: Hedge service provides instrument IDs via memory-optimized TVP -> procedure joins to Trade.PositionTbl filtering to IsComputeForHedge=1 AND StatusID=1 -> returns grouped commission totals.

---

## 2. Business Logic

### 2.1 Open-Only Hedge Commission Aggregation

**What**: Aggregates commissions only from open, hedgeable positions.

**Columns/Parameters Involved**: `IsComputeForHedge`, `StatusID`, `Commission`, `FullCommission`

**Rules**:
- Only positions where IsComputeForHedge=1 AND StatusID=1 (open) are included
- Key improvement over original: closed positions are excluded from hedge commission calculations
- TVP contains only InstrumentIDs (via BigIntTableInMem.Id), not instrument-hedge pairs

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instruments | BigIntTableInMem (TVP) | NO | - | CODE-BACKED | Memory-optimized table-valued parameter containing InstrumentIDs to query. Joined on Id to Trade.PositionTbl.InstrumentID. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. From Trade.PositionTbl. |
| 2 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server handling the instrument. From Trade.PositionTbl. |
| 3 | TotalCommission | MONEY | NO | - | CODE-BACKED | Sum of net commissions across all open, hedgeable positions for this instrument/hedge server. |
| 4 | TotalFullCommission | MONEY | NO | - | CODE-BACKED | Sum of full (gross) commissions before adjustments for this instrument/hedge server. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.PositionTbl | JOIN | Aggregates commission data from open positions filtered by IsComputeForHedge and StatusID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Service | EXEC | Caller | Uses aggregated commissions for hedge P&L calculations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCommissionsByInstrumentHedgeServer_New (procedure)
├── Trade.PositionTbl (table)
└── dbo.BigIntTableInMem (user defined type, memory-optimized)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of commission data, filtered by IsComputeForHedge=1 AND StatusID=1 |
| BigIntTableInMem | User Defined Type | Memory-optimized TVP for instrument ID list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Service | External | Calls for open-position commission aggregation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Equivalent direct query for open position commissions

```sql
SELECT TP.InstrumentID, TP.HedgeServerID,
       SUM(Commission) AS TotalCommission,
       SUM(FullCommission) AS TotalFullCommission
FROM Trade.PositionTbl TP WITH (NOLOCK)
WHERE TP.IsComputeForHedge = 1
      AND TP.StatusID = 1
      AND TP.InstrumentID IN (1001, 1002, 1003)
GROUP BY TP.InstrumentID, TP.HedgeServerID;
```

### 8.2 Compare old vs new procedure results

```sql
SELECT TP.InstrumentID, TP.HedgeServerID,
       SUM(CASE WHEN StatusID = 1 THEN Commission ELSE 0 END) AS OpenCommission,
       SUM(Commission) AS AllCommission,
       SUM(Commission) - SUM(CASE WHEN StatusID = 1 THEN Commission ELSE 0 END) AS ClosedDifference
FROM Trade.PositionTbl TP WITH (NOLOCK)
WHERE TP.IsComputeForHedge = 1
GROUP BY TP.InstrumentID, TP.HedgeServerID
HAVING SUM(Commission) <> SUM(CASE WHEN StatusID = 1 THEN Commission ELSE 0 END);
```

### 8.3 Top instruments by open commission exposure

```sql
SELECT TOP 10 TP.InstrumentID,
       SUM(Commission) AS TotalOpenCommission,
       COUNT(*) AS OpenPositionCount
FROM Trade.PositionTbl TP WITH (NOLOCK)
WHERE TP.IsComputeForHedge = 1 AND TP.StatusID = 1
GROUP BY TP.InstrumentID
ORDER BY SUM(Commission) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCommissionsByInstrumentHedgeServer_New | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCommissionsByInstrumentHedgeServer_New.sql*
