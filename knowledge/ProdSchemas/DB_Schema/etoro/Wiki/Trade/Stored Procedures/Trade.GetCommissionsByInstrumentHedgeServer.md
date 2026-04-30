# Trade.GetCommissionsByInstrumentHedgeServer

> Calculates total commission and full commission per instrument and hedge server for all hedgeable open positions matching a set of instrument-hedge server pairs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated commissions grouped by InstrumentID and HedgeServerID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure aggregates commission data across open positions for specific instruments used by the hedge service. When the hedge system needs to know the total commission exposure per instrument per hedge server, it passes a table-valued parameter with instrument-hedge pairs and receives the totals back. This is essential for accurate hedging P&L calculations where commissions affect the net exposure.

Without this procedure, the hedge service would need to calculate commission totals itself by querying individual positions, which would be inefficient for multi-instrument hedge adjustments.

Data flow: Hedge service provides instrument-hedge server pairs via TVP -> procedure joins to Trade.PositionTbl filtering to IsComputeForHedge=1 -> returns grouped commission totals.

---

## 2. Business Logic

### 2.1 Hedge-Eligible Commission Aggregation

**What**: Only positions flagged for hedge computation contribute to the totals.

**Columns/Parameters Involved**: `IsComputeForHedge`, `Commission`, `FullCommission`

**Rules**:
- Only positions where IsComputeForHedge=1 are included
- No StatusID filter - includes all position statuses (open and potentially others)
- JOIN is on InstrumentID only - HedgeServerID is not filtered by TVP, only grouped in output
- Two commission types: Commission (net, after adjustments) and FullCommission (gross, before adjustments)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentHedgePairs | Trade.InstrumentHedgeServerPairData (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing instrument-hedge server pairs to query. Joined on InstrumentID to Trade.PositionTbl. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument identifier. From Trade.PositionTbl. |
| 2 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server handling the instrument. From Trade.PositionTbl. |
| 3 | TotalCommission | MONEY | NO | - | CODE-BACKED | Sum of net commissions across all hedgeable positions for this instrument/hedge server. |
| 4 | TotalFullCommission | MONEY | NO | - | CODE-BACKED | Sum of full (gross) commissions before adjustments for this instrument/hedge server. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.PositionTbl | JOIN | Aggregates commission data from positions filtered by IsComputeForHedge |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Service | EXEC | Caller | Uses aggregated commissions for hedge P&L calculations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCommissionsByInstrumentHedgeServer (procedure)
├── Trade.PositionTbl (table)
└── Trade.InstrumentHedgeServerPairData (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of commission data, filtered by IsComputeForHedge=1 |
| Trade.InstrumentHedgeServerPairData | User Defined Type | TVP parameter type for instrument-hedge server pairs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Service | External | Calls for commission aggregation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check commission totals for a specific instrument

```sql
SELECT TP.InstrumentID, TP.HedgeServerID,
       SUM(Commission) AS TotalCommission,
       SUM(FullCommission) AS TotalFullCommission
FROM Trade.PositionTbl TP WITH (NOLOCK)
WHERE TP.IsComputeForHedge = 1
      AND TP.InstrumentID = 1001
GROUP BY TP.InstrumentID, TP.HedgeServerID;
```

### 8.2 Find instruments with highest commission exposure

```sql
SELECT TOP 10 TP.InstrumentID,
       SUM(Commission) AS TotalCommission,
       COUNT(*) AS PositionCount
FROM Trade.PositionTbl TP WITH (NOLOCK)
WHERE TP.IsComputeForHedge = 1
GROUP BY TP.InstrumentID
ORDER BY SUM(Commission) DESC;
```

### 8.3 Compare commission vs full commission gap

```sql
SELECT TP.InstrumentID, TP.HedgeServerID,
       SUM(Commission) AS NetCommission,
       SUM(FullCommission) AS GrossCommission,
       SUM(FullCommission) - SUM(Commission) AS CommissionAdjustment
FROM Trade.PositionTbl TP WITH (NOLOCK)
WHERE TP.IsComputeForHedge = 1 AND TP.StatusID = 1
GROUP BY TP.InstrumentID, TP.HedgeServerID
HAVING SUM(FullCommission) - SUM(Commission) <> 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCommissionsByInstrumentHedgeServer | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCommissionsByInstrumentHedgeServer.sql*
