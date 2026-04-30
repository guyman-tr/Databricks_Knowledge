# Trade.FundIntervalAllocation_New

> Replacement/staging version of fund interval allocation definitions, storing the investment allocation instructions for Smart Portfolio (fund) rebalancing intervals.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | FundIntervalAllocationID (IDENTITY, no PK constraint defined) |
| **Partition** | No |
| **Indexes** | 0 (heap - no indexes) |

---

## 1. Business Meaning

This table appears to be a staging or replacement version of Trade.FundIntervalAllocation, storing the allocation instructions that define how a Smart Portfolio (fund) should distribute its investment across instruments and/or other traders during a given rebalancing interval. Each row specifies what percentage of the fund to invest, in which instrument or copied trader (ParentCID), with what risk parameters (StopLoss/TakeProfit percentages) and leverage.

The table likely exists as part of a migration or redesign of the fund allocation system. The "_New" suffix suggests it was created alongside the original FundIntervalAllocation table during a transition period. Given the lack of indexes, PK constraints, or procedure references, it may be a development artifact or backup table.

No stored procedures in the current codebase reference this table, suggesting it may be unused or referenced only by application code outside the database layer.

---

## 2. Business Logic

### 2.1 Fund Allocation Definition

**What**: Each row defines one allocation instruction within a fund rebalancing interval - either an instrument investment or a copy-trade allocation.

**Columns/Parameters Involved**: `FundIntervalID`, `AllocationType`, `InstrumentID`, `ParentCID`, `InvestmentPct`, `StopLossPct`, `TakeProfitPct`

**Rules**:
- FundIntervalID links to Trade.FundInterval to identify which rebalancing interval this allocation belongs to
- AllocationType (tinyint) classifies the allocation type (likely: instrument direct, copy-trade, etc.)
- When InstrumentID is populated: direct instrument investment
- When ParentCID is populated: copy-trade allocation (invest in another trader's strategy)
- InvestmentPct: percentage of the fund's total allocation dedicated to this line
- StopLossPct/TakeProfitPct: risk parameters applied to positions created by this allocation

### 2.2 Allocation Lifecycle Tracking

**What**: Allocations track the resulting positions and orders from execution.

**Columns/Parameters Involved**: `EntryOrderID`, `ExitOrderID`, `PositionID`, `MirrorID`, `CreateDate`, `LastUpdateDate`

**Rules**:
- EntryOrderID/ExitOrderID: link to the orders created when the allocation is executed
- PositionID: the resulting position opened by this allocation
- MirrorID: for copy-trade allocations, links to the Mirror record
- CreateDate/LastUpdateDate: audit timestamps for allocation creation and modification

---

## 3. Data Overview

N/A - Table structure only (no live data query performed as no procedures reference this table and it appears to be a staging/legacy artifact).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundIntervalAllocationID | int IDENTITY | NO | Auto-increment | NAME-INFERRED | Surrogate identity key for the allocation record. Auto-incrementing. |
| 2 | FundIntervalID | int | NO | - | CODE-BACKED | Links to Trade.FundInterval - identifies which fund rebalancing interval this allocation belongs to. See [Trade.FundInterval](Trade.FundInterval.md). |
| 3 | AllocationType | tinyint | NO | - | NAME-INFERRED | Type of allocation instruction. Likely classifies as instrument direct, copy-trade, or other allocation strategies. Exact values not confirmed via code. |
| 4 | InstrumentID | int | YES | - | CODE-BACKED | Financial instrument for direct investment allocations. References Trade.Instrument. NULL when the allocation is a copy-trade (ParentCID is used instead). |
| 5 | ParentCID | int | YES | - | NAME-INFERRED | Customer ID of the trader being copied for copy-trade allocations. References Customer.Customer. NULL when the allocation is a direct instrument investment. |
| 6 | InvestmentPct | decimal(5,2) | NO | - | NAME-INFERRED | Percentage of the fund's total investment allocated to this line item. Range likely 0.00-100.00. |
| 7 | StopLossPct | decimal(5,2) | NO | - | NAME-INFERRED | Stop-loss threshold as a percentage. Applied to positions created by this allocation. |
| 8 | TakeProfitPct | numeric(10,4) | YES | - | NAME-INFERRED | Take-profit threshold as a percentage. Applied to positions created by this allocation. Higher precision than StopLossPct. |
| 9 | OpenOpen | bit | YES | - | NAME-INFERRED | Possibly controls whether the allocation should open positions at open market or queue as pending orders. |
| 10 | IsBuy | bit | YES | - | NAME-INFERRED | Direction of the position: 1 = Buy/Long, 0 = Sell/Short. NULL if direction is determined at execution time. |
| 11 | Leverage | int | YES | - | NAME-INFERRED | Leverage multiplier for positions created by this allocation. |
| 12 | EntryOrderID | int | YES | - | NAME-INFERRED | ID of the entry order created when this allocation was executed. |
| 13 | ExitOrderID | int | YES | - | NAME-INFERRED | ID of the exit order created when the position from this allocation is being closed. |
| 14 | PositionID | int | YES | - | NAME-INFERRED | ID of the position opened as a result of this allocation execution. |
| 15 | MirrorID | int | YES | - | NAME-INFERRED | Mirror (copy-trade) record ID for copy-trade allocations. Links to Trade.Mirror. |
| 16 | CreateDate | datetime | NO | - | NAME-INFERRED | Timestamp when this allocation record was created. |
| 17 | LastUpdateDate | datetime | NO | - | NAME-INFERRED | Timestamp of the most recent modification to this allocation record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundIntervalID | Trade.FundInterval | Implicit | Rebalancing interval this allocation belongs to |
| InstrumentID | Trade.Instrument | Implicit | Instrument for direct investment allocations |
| ParentCID | Customer.Customer | Implicit | Copied trader for copy-trade allocations |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

This table is a **heap** (no clustered index, no PK constraint, no non-clustered indexes). This supports the hypothesis that it is a staging or unused table.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View allocations for a specific fund interval
```sql
SELECT FundIntervalAllocationID, AllocationType, InstrumentID, ParentCID,
       InvestmentPct, StopLossPct, TakeProfitPct, Leverage
FROM   Trade.FundIntervalAllocation_New WITH (NOLOCK)
WHERE  FundIntervalID = @FundIntervalID
ORDER BY FundIntervalAllocationID
```

### 8.2 Find copy-trade vs instrument allocations
```sql
SELECT AllocationType, COUNT(*) AS AllocCount,
       AVG(InvestmentPct) AS AvgPct
FROM   Trade.FundIntervalAllocation_New WITH (NOLOCK)
GROUP BY AllocationType
```

### 8.3 Check allocations that resulted in open positions
```sql
SELECT FundIntervalAllocationID, InstrumentID, ParentCID,
       PositionID, MirrorID, InvestmentPct
FROM   Trade.FundIntervalAllocation_New WITH (NOLOCK)
WHERE  PositionID IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 5.5/10 (Elements: 3.5/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 14 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FundIntervalAllocation_New | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.FundIntervalAllocation_New.sql*
