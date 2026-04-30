# Trade.GetAccountPartialExitOrders

> Returns all pending partial close exit orders for a customer account across both regular and async execution mechanisms.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns list of exit order IDs with mechanism indicator |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all pending partial close (exit) orders for a given customer. A partial close reduces a position's unit count without fully closing it - for example, closing 50 out of 100 units of a position. The procedure returns these partial exit orders from both the regular execution pipeline (Trade.OrdersExit) and the async execution pipeline (Trade.OrderForClose), distinguishing them with a mechanism flag.

The procedure exists to support account asset management and position state queries. When the system needs to know which positions have pending partial closes (e.g., before processing a new close request, or when calculating available units), it needs to query both execution pipelines. This procedure consolidates that logic.

Data flows from Trade.OrdersExit (regular exit orders for manual positions with UnitsToDeduct > 0) and Trade.OrderForClose (async exit orders with StatusID=11 "Waiting for Market" and UnitsToDeduct > 0), combined via UNION ALL with a mechanism indicator (0=regular, 1=async).

---

## 2. Business Logic

### 2.1 Dual Execution Pipeline Consolidation

**What**: Partial exit orders can exist in two different pipelines, and both must be checked.

**Columns/Parameters Involved**: `UnitsToDeduct`, `MirrorID`, `StatusID`

**Rules**:
- Regular mechanism (AsyncMechanism=0): Orders in Trade.OrdersExit with MirrorID=0 (manual only) and UnitsToDeduct > 0 (partial close indicator)
- Async mechanism (AsyncMechanism=1): Orders in Trade.OrderForClose with StatusID=11 (Waiting for Market) and UnitsToDeduct > 0
- UnitsToDeduct > 0 distinguishes partial closes from full closes (full closes have NULL UnitsToDeduct)
- Only manual positions (MirrorID=0) are included in the regular path

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve partial exit orders for. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | ExitOrderID | BIGINT | NO | - | CODE-BACKED | The OrderID of the pending partial close order (aliased from OrderID). |
| 3 | AsyncMechanism | INT | NO | - | CODE-BACKED | Execution mechanism indicator: 0 = regular (Trade.OrdersExit), 1 = async (Trade.OrderForClose with StatusID=11 Waiting for Market). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM (regular) | Trade.OrdersExit | Direct Read | Reads manual partial exit orders |
| FROM (async) | Trade.OrderForClose | Direct Read | Reads async partial exit orders waiting for market |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAccountPartialExitOrders (procedure)
├── Trade.OrdersExit (table)
└── Trade.OrderForClose (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | SELECT - regular partial exit orders |
| Trade.OrderForClose | Table | SELECT - async partial exit orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get partial exit orders for a customer

```sql
EXEC Trade.GetAccountPartialExitOrders @CID = 12345678;
```

### 8.2 Check regular partial exit orders directly

```sql
SELECT  OrderID AS ExitOrderID,
        PositionID,
        UnitsToDeduct,
        MirrorID
FROM    Trade.OrdersExit WITH (NOLOCK)
WHERE   CID = 12345678
    AND MirrorID = 0
    AND UnitsToDeduct > 0;
```

### 8.3 Check async partial exit orders directly

```sql
SELECT  OrderID AS ExitOrderID,
        PositionID,
        UnitsToDeduct,
        StatusID
FROM    Trade.OrderForClose WITH (NOLOCK)
WHERE   CID = 12345678
    AND UnitsToDeduct > 0
    AND StatusID = 11;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAccountPartialExitOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAccountPartialExitOrders.sql*
