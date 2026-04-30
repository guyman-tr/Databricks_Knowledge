# Trade.GetVirtualHumanAllocations

> Returns a customer's active CopyTrader mirror allocations (ParentCID + allocated amount + average position gain ratio), used by BI analytics to report copy-trading portfolio composition.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @GCID (global customer ID); Returns: ParentCID, Allocation, Gain |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetVirtualHumanAllocations retrieves the active CopyTrader (Mirror) allocation summary for a single customer identified by their Global Customer ID (GCID). For each leader the customer is currently copying (active mirrors), it returns the ParentCID of the leader, the amount allocated to that copy relationship, and the average net profit ratio across all positions the customer holds within that mirror.

The "Virtual Human" designation in the name reflects eToro's historical product terminology - "virtual" referring to the mirrored/copy-trading mode where trades are automatically replicated, and "human" distinguishing human-managed leaders from automated strategies. The procedure is used by BI/analytics roles (PROD_BIadmins) to analyze copy-trading portfolio composition per customer.

Data flows in two stages: first, the GCID is resolved to a local CID via Customer.Customer; then Trade.Mirror is queried for all active mirrors (IsActive=1) for that customer. A LEFT JOIN to a derived subquery from Trade.Position computes the average gain ratio (net profit / allocation amount) per mirror. The gain calculation uses Internal.GetNetProfit(PositionID) to get the current net profit for each open position. If the customer has no positions in a mirror yet, ISNULL(Gain, 0) returns 0.

---

## 2. Business Logic

### 2.1 GCID to CID Resolution

**What**: Converts Global Customer ID to local Customer ID before querying mirror/position tables.

**Columns/Parameters Involved**: `@GCID`, `Customer.Customer.CID`, `Customer.Customer.GCID`

**Rules**:
- If @GCID <= 0 the procedure returns no rows (guard clause on IF @GCID > 0)
- GCID is the external/global identifier; CID is the internal trading system ID
- All mirror and position records are stored against CID, not GCID

### 2.2 Average Gain Ratio Calculation

**What**: For each active mirror, computes the average net-profit-to-allocation ratio across the customer's open positions in that mirror.

**Columns/Parameters Involved**: `Trade.Mirror.MirrorID`, `Trade.Mirror.Amount`, `Trade.Position.MirrorID`, `Trade.Position.PositionID`, `Internal.GetNetProfit`

**Rules**:
- Gain = AVG(CAST(Internal.GetNetProfit(PositionID) AS FLOAT) / CAST(Amount AS FLOAT))
- Only positions WHERE MirrorID > 0 are included (excludes manual/non-copy positions)
- LEFT JOIN - mirrors with no positions return Gain = NULL, displayed as 0
- If a mirror has positions but all have zero amount, the ratio computation would divide by zero; this is guarded by amount constraints at the mirror creation level

**Diagram**:
```
@GCID -> CID (Customer.Customer lookup)
         |
         v
Trade.Mirror WHERE CID=@CID AND IsActive=1
         |
         +---> ParentCID, Amount (allocation per leader)
         |
LEFT JOIN Trade.Position WHERE CID=@CID AND MirrorID>0
         |
         +---> AVG(Internal.GetNetProfit(PositionID) / Amount) AS Gain
         |
Output: ParentCID | Allocation | Gain (0 if no positions yet)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters:** | | | | | | |
| 1 | @GCID | INT | NO | - | CODE-BACKED | Global Customer ID of the customer whose copy-trading allocations are being queried. Must be > 0; if <= 0, the procedure returns no rows. GCID is the cross-system identifier; it is resolved to the internal CID via Customer.Customer. |
| **Output columns:** | | | | | | |
| 2 | ParentCID | int | NO | - | CODE-BACKED | Internal customer ID of the leader being copied. From Trade.Mirror.ParentCID. Identifies whose trades are being automatically replicated for this customer. |
| 3 | Allocation | money/numeric | NO | - | CODE-BACKED | Amount (in account currency) the customer has allocated to copy this leader. From Trade.Mirror.Amount. The total equity committed to this CopyTrader mirror relationship. |
| 4 | Gain | float | NO | 0 | CODE-BACKED | Average net profit ratio across the customer's open positions within this mirror: AVG(GetNetProfit(PositionID) / Amount). 0 when no positions are open in this mirror yet (LEFT JOIN with ISNULL). Represents the blended unrealized return on allocation for this copy relationship. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | Lookup | Resolves GCID to CID for mirror/position lookups |
| ParentCID, Allocation | Trade.Mirror | SELECT FROM | Source of active copy-trading relationships (IsActive=1) |
| Gain (computed) | Trade.Position | SELECT FROM (subquery) | Source of open positions for gain calculation; filtered to MirrorID>0 |
| Gain (computed) | Internal.GetNetProfit | Function call | Computes net profit per position for the gain ratio; called for each position in the subquery |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (BI role) | GRANT EXECUTE | Permission | Business intelligence analytics team calls this SP to report on copy-trading portfolio composition per customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetVirtualHumanAllocations (procedure)
+-- Customer.Customer (table) [x-schema, leaf]
+-- Trade.Mirror (table) [leaf]
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table) [leaf]
|     +-- Trade.PositionTreeInfo (table) [leaf]
+-- Internal.GetNetProfit (function) [x-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Resolves @GCID to local CID |
| Trade.Mirror | Table | Source of active mirror allocations (IsActive=1) |
| Trade.Position | View | Source of open positions for gain calculation |
| Internal.GetNetProfit | Function | Computes current net profit per position for gain ratio |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins (analytics role) | Permission | GRANT EXECUTE - BI analytics team calls this SP |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Guard clause: IF @GCID > 0 prevents execution for invalid/zero GCID values.

---

## 8. Sample Queries

### 8.1 Get all active copy allocations for a customer (by GCID)

```sql
EXEC Trade.GetVirtualHumanAllocations @GCID = 12345;
```

### 8.2 Get active mirror details with leader info for a customer

```sql
DECLARE @GCID INT = 12345;
DECLARE @CID  INT;
SELECT @CID = CID FROM Customer.Customer WITH (NOLOCK) WHERE GCID = @GCID;

SELECT
    tm.MirrorID,
    tm.ParentCID,
    tm.Amount AS Allocation,
    tm.IsActive,
    tm.MirrorStatusID
FROM Trade.Mirror tm WITH (NOLOCK)
WHERE tm.CID = @CID AND tm.IsActive = 1;
```

### 8.3 Check positions contributing to mirror gain for a customer

```sql
DECLARE @GCID INT = 12345;
DECLARE @CID  INT;
SELECT @CID = CID FROM Customer.Customer WITH (NOLOCK) WHERE GCID = @GCID;

SELECT
    tp.PositionID,
    tp.MirrorID,
    tp.Amount,
    tp.InstrumentID
FROM Trade.Position tp WITH (NOLOCK)
WHERE tp.CID = @CID AND tp.MirrorID > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 11 - Phase 10: no results)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped - not found) | Corrections: 0 applied*
*Object: Trade.GetVirtualHumanAllocations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetVirtualHumanAllocations.sql*
