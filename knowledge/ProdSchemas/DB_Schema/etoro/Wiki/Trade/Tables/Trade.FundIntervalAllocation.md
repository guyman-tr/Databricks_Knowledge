# Trade.FundIntervalAllocation

> Per-interval allocation records for CopyFunds/SmartPortfolios: each row defines one asset (instrument) or copy (parent) allocation with investment percentage, stop-loss, take-profit, and optional order/position links for a fund rebalance period.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | FundIntervalAllocationID (int, PK) |
| **Partition** | MAIN filegroup |
| **Indexes** | 2 active (1 clustered PK, 1 unique NC) |

---

## 1. Business Meaning

Trade.FundIntervalAllocation stores the individual allocation entries for each CopyFund/SmartPortfolio rebalance interval. Each row represents one line item in a fund's allocation plan for a specific period: either an asset allocation (InstrumentID set, investment in a tradeable instrument) or a copy allocation (ParentCID set, investment in another leader). The table holds InvestmentPct, StopLossPct, TakeProfitPct, and optional links to EntryOrderID, ExitOrderID, PositionID, and MirrorID when the allocation has been executed.

This table exists because CopyFunds rebalance on a schedule (monthly, bimonthly, quarterly). Each interval needs a list of what to allocate: which instruments at what percentage, which copy leaders, and what risk parameters. Without FundIntervalAllocation, Trade.GetFundInfo could not return the allocation composition for an interval, and Trade.CreateNewFundAllocation could not persist new allocation entries. It is the child of Trade.FundInterval: each interval has many allocations.

Data flows: Rows are created by Trade.CreateNewFundAllocation (INSERT with FundIntervalID, AllocationType, InstrumentID/ParentCID, InvestmentPct, StopLossPct, TakeProfitPct, etc.). Trade.GetFundInfo reads allocations JOINed to Fund and FundInterval for API responses. Trade.DeleteFundAllocationBacktestData and Trade.FundBacktestDataDelete remove allocations for backtest intervals (FundIntervalType=1).

---

## 2. Business Logic

### 2.1 Asset vs Copy Allocation

**What**: Each row is either an asset allocation (direct instrument) or a copy allocation (another leader).

**Columns/Parameters Involved**: `AllocationType`, `InstrumentID`, `ParentCID`

**Rules**:
- AllocationType=1 (Copy): ParentCID is set, InstrumentID is NULL. Investment in another CopyTrader leader.
- AllocationType=2 (Asset): InstrumentID is set, ParentCID is NULL or set for combined cases. Investment in an instrument.
- CreateNewFundAllocation: @InstrumentSymbol maps to InstrumentID; @ParentUserName maps to ParentCID. Validation: if InstrumentSymbol provided, InvestmentPct, StopLossPct, TakeProfitPct, IsBuy, Leverage required. If ParentUserName provided, InvestmentPct, OpenOpen, StopLossPct required.
- Unique constraint: (FundIntervalID, InstrumentID, ParentCID) ensures one allocation per instrument/parent per interval.

**Diagram**:
```
Trade.FundInterval (PlannedStart, PlannedEnd)
    |
    v
Trade.FundIntervalAllocation
    |-- AllocationType=1: Copy allocation (ParentCID set)
    |-- AllocationType=2: Asset allocation (InstrumentID set)
    |-- InvestmentPct, StopLossPct, TakeProfitPct: risk params
    |-- EntryOrderID, ExitOrderID, PositionID, MirrorID: execution links
```

### 2.2 Risk Parameters per Allocation

**What**: Each allocation has stop-loss and take-profit percentages plus optional leverage and direction.

**Columns/Parameters Involved**: `StopLossPct`, `TakeProfitPct`, `InvestmentPct`, `Leverage`, `IsBuy`, `OpenOpen`

**Rules**:
- InvestmentPct: Percentage of fund to allocate to this entry. decimal(5,2).
- StopLossPct: Stop-loss percentage (e.g., 100 = 100%). StopLossPct=100 can mean no SL or 100% loss tolerance depending on app logic.
- TakeProfitPct: Take-profit percentage. Sample shows 100000 as "unlimited" or large placeholder.
- IsBuy: 1=long, 0=short. Required for asset allocations.
- Leverage: Multiplier (e.g., 1 = no leverage). Required for asset allocations.
- OpenOpen: For copy allocations, controls whether to open new positions when copying.

---

## 3. Data Overview

| FundIntervalAllocationID | FundIntervalID | AllocationType | InstrumentID | ParentCID | InvestmentPct | StopLossPct | TakeProfitPct | IsBuy | Leverage | Meaning |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 2 | 6270 | NULL | 5 | 100 | 100000 | 1 | 1 | Asset allocation for instrument 6270. 5% investment, 100% stop-loss, take-profit at 100000 (effectively unlimited). Long, 1x leverage. |

**Selection criteria for the 5 rows:**
- Table has 1 row in sample. Single row included to show structure. In production, multiple rows per FundIntervalID with mix of Copy (1) and Asset (2) allocations would exist. This sample is an asset allocation with typical risk params.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundIntervalAllocationID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Surrogate identifier. NOT FOR REPLICATION. |
| 2 | FundIntervalID | int | NO | - | CODE-BACKED | FK to Trade.FundInterval. The rebalance interval this allocation belongs to. CreateNewFundAllocation inserts; GetFundInfo JOINs. |
| 3 | AllocationType | tinyint | NO | - | CODE-BACKED | FK to Dictionary.AllocationType. 1=Copy (ParentCID set), 2=Asset (InstrumentID set). |
| 4 | InstrumentID | int | YES | - | CODE-BACKED | FK to Trade.Instrument (implicit). The instrument for asset allocations. NULL for copy allocations. Resolved from InstrumentMetaData.SymbolFull in CreateNewFundAllocation. |
| 5 | ParentCID | int | YES | - | CODE-BACKED | Customer ID of the copied leader for copy allocations. NULL for asset allocations. Resolved from Customer.UserName in CreateNewFundAllocation. |
| 6 | InvestmentPct | decimal(5,2) | NO | - | CODE-BACKED | Percentage of fund allocated to this entry. CreateNewFundAllocation requires non-null for both asset and copy. |
| 7 | StopLossPct | decimal(5,2) | NO | - | CODE-BACKED | Stop-loss percentage. 100 may mean no SL or 100% loss cap. Required on create. |
| 8 | TakeProfitPct | numeric(10,4) | YES | - | CODE-BACKED | Take-profit percentage. 100000 in sample may mean unlimited. Nullable. |
| 9 | OpenOpen | bit | YES | - | CODE-BACKED | For copy allocations: whether to open new positions. Required when ParentUserName provided. |
| 10 | IsBuy | bit | YES | - | CODE-BACKED | 1=long, 0=short. Required for asset allocations in CreateNewFundAllocation. |
| 11 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier. 1=no leverage. Required for asset allocations. |
| 12 | EntryOrderID | int | YES | - | CODE-BACKED | Link to order opened for this allocation when executed. NULL until allocation is executed. |
| 13 | ExitOrderID | int | YES | - | CODE-BACKED | Link to exit order when allocation is closed. NULL until closed. |
| 14 | PositionID | bigint | YES | - | CODE-BACKED | Link to Trade.PositionTbl when allocation has an open position. NULL until opened. |
| 15 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror identifier. NULL for non-copy or when not yet linked. |
| 16 | CreateDate | datetime | NO | getdate() | CODE-BACKED | When the allocation row was created. |
| 17 | LastUpdateDate | datetime | NO | - | CODE-BACKED | Last modification timestamp. Set at INSERT by CreateNewFundAllocation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundIntervalID | Trade.FundInterval | FK (FK_TFIA_FundIntervalID) | Parent interval; each allocation belongs to one interval |
| AllocationType | Dictionary.AllocationType | FK (FK_TFIA_AllocationType) | 1=Copy, 2=Asset |
| InstrumentID | Trade.Instrument | Implicit | Instrument for asset allocations |
| EntryOrderID | Trade.Orders | Implicit | Entry order when executed |
| ExitOrderID | Trade.Orders | Implicit | Exit order when closed |
| PositionID | Trade.PositionTbl | Implicit | Open position link |
| ParentCID | Customer.Customer | Implicit | Leader for copy allocations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetFundInfo | - | JOIN | Reads allocations by FundAccountID for API |
| Trade.CreateNewFundAllocation | - | Writer | INSERTs new allocations |
| Trade.DeleteFundAllocationBacktestData | FundIntervalID | JOIN | Deletes allocations for backtest intervals |
| Trade.FundBacktestDataDelete | - | Read/Delete | Deletes backtest allocations |
| Trade.FundMgrSync | SYN_RankingsFundMgrFundIntervalAllocation | JOIN | Syncs to FundMgr via synonym |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FundIntervalAllocation (table)
```

Tables have no code-level dependencies. FK targets (Trade.FundInterval, Dictionary.AllocationType) are structural dependencies only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FundInterval | Table | FK target for FundIntervalID |
| Dictionary.AllocationType | Table | FK target for AllocationType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetFundInfo | Procedure | JOINs Fund to FundInterval to FundIntervalAllocation |
| Trade.CreateNewFundAllocation | Procedure | INSERTs allocations |
| Trade.DeleteFundAllocationBacktestData | Procedure | JOINs for backtest cleanup |
| Trade.FundBacktestDataDelete | Procedure | Reads/deletes backtest allocations |
| Trade.FundMgrSync | Procedure | Syncs via synonym |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeFundIntervalAllocation | CLUSTERED PK | FundIntervalAllocationID ASC | - | - | Active |
| IDX_UNQ_Trade_FundIntervalAllocation | NC UNIQUE | FundIntervalID, InstrumentID, ParentCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeFundIntervalAllocation | PRIMARY KEY | Unique allocation identifier |
| DF_TradeFundIntervalAllocation_CreateDate | DEFAULT | getdate() for CreateDate |
| FK_TFIA_AllocationType | FOREIGN KEY | AllocationType -> Dictionary.AllocationType.AllocationType |
| FK_TFIA_FundIntervalID | FOREIGN KEY | FundIntervalID -> Trade.FundInterval.FundIntervalID |

---

## 8. Sample Queries

### 8.1 List allocations for an interval with allocation type description
```sql
SELECT  fia.FundIntervalAllocationID,
        fia.FundIntervalID,
        at.AllocationTypeDesc,
        fia.InstrumentID,
        fia.ParentCID,
        fia.InvestmentPct,
        fia.StopLossPct,
        fia.TakeProfitPct,
        fia.IsBuy,
        fia.Leverage
FROM    Trade.FundIntervalAllocation fia WITH (NOLOCK)
JOIN    Dictionary.AllocationType at WITH (NOLOCK) ON fia.AllocationType = at.AllocationType
WHERE   fia.FundIntervalID = 1
ORDER BY fia.FundIntervalAllocationID;
```

### 8.2 Get fund allocations with instrument symbols
```sql
SELECT  fi.FundIntervalID,
        fia.AllocationType,
        imd.SymbolFull AS InstrumentSymbol,
        fia.InvestmentPct,
        fia.StopLossPct,
        fia.TakeProfitPct
FROM    Trade.FundInterval fi WITH (NOLOCK)
JOIN    Trade.FundIntervalAllocation fia WITH (NOLOCK) ON fi.FundIntervalID = fia.FundIntervalID
LEFT JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON fia.InstrumentID = imd.InstrumentID
WHERE   fi.FundID = 1
ORDER BY fi.PlannedStart, fia.FundIntervalAllocationID;
```

### 8.3 Count allocations by type per fund
```sql
SELECT  f.FundName,
        at.AllocationTypeDesc,
        COUNT(*) AS AllocationCount
FROM    Trade.Fund f WITH (NOLOCK)
JOIN    Trade.FundInterval fi WITH (NOLOCK) ON f.FundID = fi.FundID
JOIN    Trade.FundIntervalAllocation fia WITH (NOLOCK) ON fi.FundIntervalID = fia.FundIntervalID
JOIN    Dictionary.AllocationType at WITH (NOLOCK) ON fia.AllocationType = at.AllocationType
GROUP BY f.FundName, at.AllocationTypeDesc
ORDER BY f.FundName, at.AllocationTypeDesc;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,4,5,7,8,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FundIntervalAllocation | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.FundIntervalAllocation.sql*
