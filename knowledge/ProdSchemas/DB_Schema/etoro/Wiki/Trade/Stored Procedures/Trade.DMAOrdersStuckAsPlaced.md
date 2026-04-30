# Trade.DMAOrdersStuckAsPlaced

> Detects DMA (Direct Market Access) orders stuck in "Placed" status and sends an HTML email alert to the dealing/execution team, or returns results to PagerDuty.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CallFromPagerDuty |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DMA orders (real stock orders routed directly to exchanges) should transition through their lifecycle quickly. When orders become stuck in StatusID=2 ("Placed" — sent to exchange but no acknowledgement received), it indicates a potential connectivity issue with the exchange, a broker-side failure, or an order routing problem. This procedure is a **monitoring/alerting tool** that:

1. Identifies all open and close orders stuck as "Placed" (StatusID=2) across both Trade.OrderForOpen and Trade.OrderForClose
2. If called from PagerDuty (@CallFromPagerDuty=1): returns the result set directly for programmatic alerting
3. If called from SQL Agent job (@CallFromPagerDuty=0): builds an HTML email report and sends it via Database Mail to dealing-execution@etoro.com, tradingbackend@etoro.com, and TradingExecution

If no stuck orders are found, the procedure exits silently (RETURN).

---

## 2. Business Logic

### 2.1 Stuck Order Detection

**What**: Finds all DMA orders stuck in "Placed" status.

**Columns/Parameters Involved**: `Trade.OrderForOpen.StatusID`, `Trade.OrderForClose.StatusID`

**Rules**:
- CTE combines both order sources:
  - Trade.OrderForOpen WHERE StatusID = 2 (Open orders: OrderID, CID, InstrumentID, Amount, AmountInUnits)
  - Trade.OrderForClose WHERE StatusID = 2 (Close orders: OrderID, CID, PositionID, UnitsToDeduct)
- Results stored in #USpositionfailed temp table
- If no rows found: immediate RETURN (no alert sent)

### 2.2 PagerDuty vs Email Alert

**What**: Routes output based on caller context.

**Columns/Parameters Involved**: `@CallFromPagerDuty`

**Rules**:
- @CallFromPagerDuty = 1: SELECT * from #USpositionfailed and RETURN (PagerDuty consumes result set)
- @CallFromPagerDuty = 0 (default): Build HTML table and send via msdb.dbo.sp_send_dbmail
- Email subject includes current date: "Us orders that fail : {date}"
- Recipients: dealing-execution@etoro.com; tradingbackend@etoro.com; TradingExecution
- HTML table includes: OrderType, OrderID, CID, InstrumentID, Amount, AmountInUnits, PositionID, UnitsToDeduct

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CallFromPagerDuty | BIT | NO | 0 | CODE-BACKED | When 1: returns result set directly for PagerDuty integration. When 0: sends HTML email alert via Database Mail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Trade.OrderForOpen | Read | Finds open orders stuck at StatusID=2 |
| (SELECT) | Trade.OrderForClose | Read | Finds close orders stuck at StatusID=2 |
| (EXEC) | msdb.dbo.sp_send_dbmail | System procedure | Sends HTML email alert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (SQL Agent job) | N/A | Scheduled execution | Periodic monitoring for stuck DMA orders |
| (PagerDuty integration) | N/A | API caller | On-demand stuck order check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DMAOrdersStuckAsPlaced (procedure)
+-- Trade.OrderForOpen (table, memory-optimized)
+-- Trade.OrderForClose (table, memory-optimized)
+-- msdb.dbo.sp_send_dbmail (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table (Memory-Optimized) | Source for stuck open orders |
| Trade.OrderForClose | Table (Memory-Optimized) | Source for stuck close orders |
| msdb.dbo.sp_send_dbmail | System Procedure | Email delivery |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: The procedure uses 4-part naming (`etoro.Trade.OrderForOpen`) which is unusual in stored procedure code — may indicate it was originally written as an ad-hoc query. The HTML generation uses FOR XML PATH('tr') pattern for table row construction. The email subject says "Us orders that fail" which appears to be a legacy naming convention for US/DMA stock orders. No NOLOCK hints are used (memory-optimized tables don't support table hints).

---

## 8. Sample Queries

### 8.1 Manual check for stuck DMA orders

```sql
SELECT  'Open' AS OrderType, OrderID, CID, InstrumentID, StatusID
FROM    Trade.OrderForOpen
WHERE   StatusID = 2
UNION ALL
SELECT  'Close', OrderID, CID, NULL, StatusID
FROM    Trade.OrderForClose
WHERE   StatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DMAOrdersStuckAsPlaced | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DMAOrdersStuckAsPlaced.sql*
