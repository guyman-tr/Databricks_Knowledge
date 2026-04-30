# Trade.GetUnrealizedCustomersData

> Returns three aggregate totals representing eToro's global unrealized P&L exposure across all open customer positions, excluding internal Etorian (PlayerLevelID=4) accounts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - schema-wide aggregate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUnrealizedCustomersData` provides a global risk snapshot of eToro's unrealized P&L exposure across all currently open positions. It returns a single row with three aggregate values: total unrealized net profit (in dollars), total unrealized commission, and a combined "eToro P&L" figure (net profit + commission). This is used for treasury/risk management purposes to understand the total floating exposure on the books at any given moment.

The procedure joins `Trade.Position` (open positions view) to `Trade.PnL` (real-time P&L values) and filters out internal eToro hedge/internal accounts (PlayerLevelID=4 via Customer.Customer). This ensures the reported figures reflect only genuine customer exposure, not internal eToro accounts that would cancel out.

The naming convention uses "eToro" vs "IFX" suffixes (UnREAL_PNLeToro vs UnREAL_PNLIFX): these likely correspond to different legal entity book assignments, though in the current implementation both sums use the same NetProfit column. The outer query sums `X.NetProfit + X.Commission AS UnREAL_PNLeToro` and independently sums `X.NetProfit` as `UnREAL_PNLIFX`, making the values different by the commission component.

---

## 2. Business Logic

### 2.1 Etorian Account Exclusion

**What**: Internal eToro accounts (PlayerLevelID=4) are excluded from the unrealized exposure totals.

**Columns/Parameters Involved**: `Customer.Customer.PlayerLevelID`, `CC.CID`

**Rules**:
- INNER JOIN to `Customer.Customer` with filter `CC.PlayerLevelID <> 4`
- PlayerLevelID=4 = Etorian (internal eToro hedge desk account)
- All other PlayerLevelIDs (1=regular customer, 2=Popular Investor, etc.) are included
- This mirrors the IsComputedForHedge exclusion logic used elsewhere (e.g., GetTreeNodesByParentCID_Inner)

### 2.2 Three Aggregate Output Values

**What**: Three computed aggregate totals returned as a single row.

**Rules**:
- `UnREAL_PNLeToro`: SUM of (NetProfit + Commission) per position - total eToro book exposure including commission
- `UnREAL_Commission`: SUM of Commission alone - total unrealized commission across open positions
- `UnREAL_PNLIFX`: SUM of NetProfit alone - total P&L excluding commission component
- All three use ISNULL(..., 0) to return 0 rather than NULL when no positions exist
- Source: `Trade.PnL.PnLInDollars` as NetProfit, `Trade.PnL.Commission` as Commission

### 2.3 Partition-Aware Join

**What**: The join between Trade.Position and Trade.PnL uses the partition column to enable partition elimination.

**Rules**:
- Join condition: `TP.PositionID = PnL.PositionID AND TP.PositionPartitionCol = PnL.PartitionCol`
- This is the standard partition-aware join pattern across all Trade schema queries
- Without the partition column in the join, a full scan of PnL would be required

---

## 3. Data Overview

N/A for Stored Procedure (returns a single aggregate row, no parameters).

---

## 4. Elements

No input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UnREAL_PNLeToro | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of (NetProfit + Commission) across all open real customer positions. Represents total eToro book exposure including unrealized commission. ISNULL to 0 if no positions. |
| 2 | UnREAL_Commission | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of Commission alone from Trade.PnL across all open real customer positions. ISNULL to 0. |
| 3 | UnREAL_PNLIFX | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of NetProfit (PnLInDollars) alone from Trade.PnL. Does not include commission component. Likely represents IFX legal entity exposure. ISNULL to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position | FROM | View of all open positions - all customers, all instruments |
| JOIN | Trade.PnL | INNER JOIN | Real-time P&L for each open position (PnLInDollars, Commission) |
| JOIN | Customer.Customer | INNER JOIN | Used solely for PlayerLevelID filter (exclude Etorian accounts) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (risk/treasury monitoring) | - | EXEC caller | Schema-wide P&L aggregate - called by risk monitoring or reporting jobs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUnrealizedCustomersData (procedure)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.PnL (table)
+-- Customer.Customer (table) [PlayerLevelID filter only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Source of all open positions |
| Trade.PnL | Table | Provides PnLInDollars (NetProfit) and Commission |
| Customer.Customer | Table | Filter to exclude PlayerLevelID=4 (Etorian) accounts |

### 6.2 Objects That Depend On This

No documented dependents. Called externally by monitoring or reporting systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Isolation hint | All three table hints use NOLOCK - dirty reads acceptable for this aggregate |
| PlayerLevelID <> 4 | Business filter | Excludes internal eToro accounts from customer exposure totals |
| PositionPartitionCol = PnL.PartitionCol | Partition join | Ensures partition elimination when joining Trade.Position to Trade.PnL |

---

## 8. Sample Queries

### 8.1 Get global unrealized exposure snapshot
```sql
EXEC Trade.GetUnrealizedCustomersData
-- Returns: UnREAL_PNLeToro, UnREAL_Commission, UnREAL_PNLIFX
```

### 8.2 Understand the computation manually
```sql
SELECT
    ISNULL(SUM(PnL.PnLInDollars + PnL.Commission), 0) AS UnREAL_PNLeToro,
    ISNULL(SUM(PnL.Commission), 0)                    AS UnREAL_Commission,
    ISNULL(SUM(PnL.PnLInDollars), 0)                  AS UnREAL_PNLIFX
FROM Trade.Position TP WITH (NOLOCK)
     INNER JOIN Trade.PnL PnL WITH (NOLOCK)
         ON TP.PositionID = PnL.PositionID
         AND TP.PositionPartitionCol = PnL.PartitionCol
     INNER JOIN Customer.Customer CC WITH (NOLOCK)
         ON TP.CID = CC.CID
         AND CC.PlayerLevelID <> 4
```

### 8.3 Breakdown by PlayerLevelID to verify Etorian exclusion
```sql
SELECT CC.PlayerLevelID,
       COUNT(TP.PositionID) AS PositionCount,
       SUM(PnL.PnLInDollars) AS TotalPnL
FROM Trade.Position TP WITH (NOLOCK)
     INNER JOIN Trade.PnL PnL WITH (NOLOCK)
         ON TP.PositionID = PnL.PositionID
         AND TP.PositionPartitionCol = PnL.PartitionCol
     INNER JOIN Customer.Customer CC WITH (NOLOCK) ON TP.CID = CC.CID
GROUP BY CC.PlayerLevelID
ORDER BY CC.PlayerLevelID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Schema-wide aggregate not covered in the configured TRAD/DB Confluence folder.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUnrealizedCustomersData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUnrealizedCustomersData.sql*
