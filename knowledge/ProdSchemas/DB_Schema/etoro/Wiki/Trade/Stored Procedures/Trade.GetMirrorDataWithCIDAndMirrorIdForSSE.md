# Trade.GetMirrorDataWithCIDAndMirrorIdForSSE

> Lightweight CopyTrader data endpoint optimized for Server-Sent Events (SSE): returns minimal position/order IDs, regulation, and country for real-time UI updates without full position payloads.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: 9 result sets with minimal columns (IDs only) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorDataWithCIDAndMirrorIdForSSE is the SSE (Server-Sent Events) optimized variant of the mirror data API procedure. Instead of returning full position and order payloads, it returns only IDs and minimal fields needed for real-time UI updates. The SSE channel uses this to efficiently track which positions and orders exist, without the bandwidth cost of full data.

This procedure exists because the real-time SSE stream must push updates at high frequency. Sending full position data (30+ columns per position) for every update would overwhelm the channel. Instead, this returns just PositionID+InstrumentID for positions and OrderID for orders, and the SSE client hydrates full details on-demand.

Returns 9 result sets: open positions (PositionID, InstrumentID), entry orders (OrderID), exit orders (PositionID), regulation info, orders for close (PositionID), delayed close orders (PositionID), delayed open orders (OrderID), customer country, and orders for open waiting for market (OrderID).

---

## 2. Business Logic

### 2.1 SSE-Optimized Minimal Payloads

**What**: Returns only identifier columns from each order/position table, not full payloads.

**Columns/Parameters Involved**: `@mirrorId`, `@cid`

**Rules**:
- Positions: only PositionID + InstrumentID from Trade.PositionTbl (StatusID=1, open only)
- Entry orders: only OrderID from Trade.OrdersEntry
- Exit orders: only PositionID from Trade.OrdersExit
- Regulation: DesignatedRegulationID or RegulationID from BackOffice.Customer
- Close orders: only PositionID from Trade.CloseExecutionPlan + Trade.OrderForClose (non-terminal)
- Delayed close: only PositionID from Trade.DelayedOrderForClose (StatusID=1)
- Delayed open: only OrderID from Trade.DelayedOrderForOpen (StatusID=1)
- Country: CountryID from Customer.CustomerStatic
- Orders for open: only OrderID from Trade.OrderForOpen (StatusID=11 - waiting for market)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @mirrorId | int | IN | - | CODE-BACKED | The CopyTrader mirror ID for this SSE channel. |
| 2 | @cid | int | IN | - | CODE-BACKED | The copier's customer ID for this SSE channel. |

### 4.2 Result Sets (Summary)

| # | Result Set | Key Columns | Source | Description |
|---|-----------|-------------|--------|-------------|
| 1 | Open Positions | PositionID, InstrumentID | Trade.PositionTbl | Open copied positions for this mirror |
| 2 | Entry Orders | OrderID | Trade.OrdersEntry | Pending entry orders |
| 3 | Exit Orders | PositionID | Trade.OrdersExit | Pending exit orders |
| 4 | Regulation | RegulationID | BackOffice.Customer | Customer's regulation for compliance rules |
| 5 | Close Orders | PositionID | Trade.CloseExecutionPlan | Active non-terminal close orders |
| 6 | Delayed Close | PositionID | Trade.DelayedOrderForClose | Placed delayed close orders |
| 7 | Delayed Open | OrderID | Trade.DelayedOrderForOpen | Placed delayed open orders |
| 8 | Country | CountryID | Customer.CustomerStatic | Customer's country for jurisdiction rules |
| 9 | Orders for Open | OrderID | Trade.OrderForOpen | Orders waiting for market (StatusID=11) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.PositionTbl | SELECT (READER) | Open positions for mirror |
| FROM | Trade.OrdersEntry | SELECT (READER) | Entry orders |
| FROM | Trade.OrdersExit | SELECT (READER) | Exit orders |
| FROM | BackOffice.Customer | SELECT (READER) | Regulation info |
| FROM | Trade.CloseExecutionPlan | SELECT (READER) | Close execution plans |
| FROM | Trade.OrderForClose | SELECT (READER) | Close orders |
| FROM | Dictionary.OrderForExecutionStatus | SELECT (READER) | Terminal status filter |
| FROM | Trade.DelayedOrderForClose | SELECT (READER) | Delayed close orders |
| FROM | Trade.DelayedOrderForOpen | SELECT (READER) | Delayed open orders |
| FROM | Customer.CustomerStatic | SELECT (READER) | Country info |
| FROM | Trade.OrderForOpen | SELECT (READER) | Open orders waiting for market |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (SSE Service) | Direct call | Application | Real-time SSE channel data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorDataWithCIDAndMirrorIdForSSE (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.OrdersEntry (table)
+-- Trade.OrdersExit (table)
+-- BackOffice.Customer (table)
+-- Trade.CloseExecutionPlan (table)
+-- Trade.OrderForClose (table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- Trade.DelayedOrderForClose (table)
+-- Trade.DelayedOrderForOpen (table)
+-- Customer.CustomerStatic (table)
+-- Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Open positions |
| Trade.OrdersEntry | Table | Entry orders |
| Trade.OrdersExit | Table | Exit orders |
| BackOffice.Customer | Table | Regulation |
| Trade.CloseExecutionPlan | Table | Close plans |
| Trade.OrderForClose | Table | Close orders |
| Dictionary.OrderForExecutionStatus | Table | Status filter |
| Trade.DelayedOrderForClose | Table | Delayed close |
| Trade.DelayedOrderForOpen | Table | Delayed open |
| Customer.CustomerStatic | Table | Country |
| Trade.OrderForOpen | Table | Open orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SSE Service) | Application | Real-time updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

TRY/CATCH with THROW.

---

## 8. Sample Queries

### 8.1 Get SSE mirror data

```sql
EXEC Trade.GetMirrorDataWithCIDAndMirrorIdForSSE @mirrorId = 12345, @cid = 67890;
```

### 8.2 Check open positions for SSE

```sql
SELECT  p.PositionID, p.InstrumentID
FROM    Trade.PositionTbl p WITH (NOLOCK)
WHERE   p.MirrorID = 12345
        AND p.ParentPositionID > 0
        AND p.CID = 67890
        AND p.StatusID = 1;
```

### 8.3 Check customer regulation and country

```sql
SELECT  bo.RegulationID,
        bo.DesignatedRegulationID,
        cs.CountryID
FROM    BackOffice.Customer bo WITH (NOLOCK)
        JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON bo.CID = cs.CID
WHERE   bo.CID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorDataWithCIDAndMirrorIdForSSE | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorDataWithCIDAndMirrorIdForSSE.sql*
