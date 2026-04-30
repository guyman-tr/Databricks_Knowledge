# Hedge.OpenPositionsWithCommissionBulkParameters

> Memory-optimized TVP extending OpenPositionsBulkParameters with a CommissionOnOpen column, used by the market-width (MW) variant of the bulk open position insert procedure.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type - MEMORY_OPTIMIZED) |
| **Key Identifier** | No primary key; NONCLUSTERED index on (HedgeServerID, InstrumentID) |
| **Partition** | N/A |
| **Indexes** | 1 (NONCLUSTERED on HedgeServerID, InstrumentID) |

---

## 1. Business Meaning

`Hedge.OpenPositionsWithCommissionBulkParameters` is the commission-aware extension of `Hedge.OpenPositionsBulkParameters`. It adds a `CommissionOnOpen` column to capture the total spread/commission charged to customers when opening their positions - required for the hedge cost analysis that factors in eToro's revenue.

This type is consumed exclusively by `Hedge.InsertOpenPositionBulk_MW`, the "Market Width" variant of the bulk insert procedure. The "_MW" suffix indicates this variant is used when the open position data includes market-width (spread) commission rather than using zero commission. Including commission data in open position snapshots allows the HedgeCost reporting system (via `HedgeCostReportHistoryPerDay` / `PerHour`) to calculate the full hedge cost net of eToro's income.

Like its sibling type, this TVP is memory-optimized for high-frequency use by the hedge server application.

---

## 2. Business Logic

### 2.1 Commission-Inclusive Open Position Snapshot

**What**: Extends the standard open position snapshot with commission revenue data for hedge cost P&L analysis.

**Columns/Parameters Involved**: `CommissionOnOpen`, `UnrealizedPL`, `OpenBuyUnits`, `OpenSellUnits`

**Rules**:
- `CommissionOnOpen` is the total spread/commission charged to customers on opening their positions, in USD. This is eToro's revenue component for open positions.
- `CommissionOnOpen NOT NULL` (unlike other financial columns which are nullable) - signals that commission data is mandatory for the MW flow; if zero commission, pass 0 explicitly.
- Hedge cost = CustomerPL - CommissionOnOpen. Positive hedge cost means the hedge is more expensive than eToro's commission revenue.
- All other fields are identical in semantics to `Hedge.OpenPositionsBulkParameters` - see that type's documentation for full field descriptions.

**Diagram**:
```
Hedge Server (Market Width mode)
  |
  | computes aggregate open positions WITH commission
  |
  | populates OpenPositionsWithCommissionBulkParameters TVP
  v
Hedge.InsertOpenPositionBulk_MW (SP)
  |
  v
Hedge.CustomerOpenPositions (table - with CommissionOnOpen column)
     |
     +-> HedgeCostReportHistoryPerDay/PerHour
     |   reads CommissionOnOpen from History.CustomerOpenPositions
     |   for hedge cost % calculation
     v
Hedge.ArchiveCustomerOpenPositions -> History.CustomerOpenPositions
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server instance generating this snapshot. Implicit FK to Trade.HedgeServer. |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument for this snapshot. Combined with HedgeServerID, uniquely identifies the exposure position. Implicit FK to Trade.Instrument. NONCLUSTERED index key. |
| 3 | OccurredAt | datetime | NO | - | CODE-BACKED | Snapshot timestamp (NOT NULL). Used for time-series ordering and interval-based archival. |
| 4 | UnrealizedPL | decimal(14,4) | YES | - | CODE-BACKED | Aggregate unrealized P&L for all open customer positions on this instrument/server, in USD. See Hedge.OpenPositionsBulkParameters for full description. |
| 5 | OpenBuyUnits | int | YES | - | CODE-BACKED | Total long (buy) units open on this instrument/server. See Hedge.OpenPositionsBulkParameters. |
| 6 | OpenSellUnits | int | YES | - | CODE-BACKED | Total short (sell) units open on this instrument/server. Net exposure = OpenBuyUnits - OpenSellUnits. |
| 7 | PriceRateID | bigint | YES | - | CODE-BACKED | Rate snapshot ID used to compute UnrealizedPL in this row. Enables retrospective rate verification. |
| 8 | CommissionOnOpen | decimal(14,4) | NO | - | CODE-BACKED | Total spread/commission charged to customers when opening positions on this instrument/server, in USD (NOT NULL). This is eToro's revenue for these positions. Used in HedgeCostReport calculations: [Etoro Commission - Unrealized] = SUM(CommissionOnOpen) per HedgeServer per day/hour. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | Implicit | Identifies the hedge server generating this open position snapshot |
| InstrumentID | Trade.Instrument | Implicit | Identifies the trading instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InsertOpenPositionBulk_MW | @OpenPositions parameter | TVP parameter | Receives commission-inclusive open position snapshots for insert into Hedge.CustomerOpenPositions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf TVP type).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InsertOpenPositionBulk_MW | Stored Procedure | Receives market-width variant of open position snapshots including commission data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IDX_OpenPositions | NONCLUSTERED | HedgeServerID ASC, InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MEMORY_OPTIMIZED | Storage | TVP lives entirely in DRAM - eliminates disk I/O for high-frequency parameter passing |

---

## 8. Sample Queries

### 8.1 View latest open positions with commission data
```sql
SELECT TOP 20 HedgeServerID, InstrumentID, OccurredAt,
       OpenBuyUnits, OpenSellUnits, UnrealizedPL, CommissionOnOpen
FROM [Hedge].[CustomerOpenPositions] WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

### 8.2 Calculate hedge cost ratio (commission vs. P&L)
```sql
SELECT HedgeServerID,
       SUM(CommissionOnOpen) AS TotalCommission,
       SUM(UnrealizedPL) AS TotalUnrealizedPL,
       CASE WHEN SUM(CommissionOnOpen) = 0 THEN NULL
            ELSE SUM(UnrealizedPL) / SUM(CommissionOnOpen) * 100
       END AS HedgeCostPct
FROM [Hedge].[CustomerOpenPositions] WITH (NOLOCK)
WHERE OccurredAt >= DATEADD(day, -1, GETUTCDATE())
GROUP BY HedgeServerID
```

### 8.3 Declare and use the commission TVP
```sql
DECLARE @Positions [Hedge].[OpenPositionsWithCommissionBulkParameters]
INSERT INTO @Positions VALUES (1, 100, GETUTCDATE(), -500.25, 10000, 8000, 987654321, 125.50)

EXEC [Hedge].[InsertOpenPositionBulk_MW] @OpenPositions = @Positions
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | Hedge Cost: [Etoro Commission - Unrealized] is CommissionOnOpen from History.CustomerOpenPositions; used in INSight HedgeCost display |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.OpenPositionsWithCommissionBulkParameters | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.OpenPositionsWithCommissionBulkParameters.sql*
