# Hedge.InsertOpenPositionBulk_MW

> Market-Width (MW) variant of the bulk open position insert - directly inserts a TVP that already contains pre-computed CommissionOnOpen, eliminating the OPENQUERY commission lookup required by InsertOpenPositionBulk.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.CustomerOpenPositions_New |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.InsertOpenPositionBulk_MW` is the "Market Width" (MW) variant of the bulk open position insert procedure. It differs from `Hedge.InsertOpenPositionBulk` in one key respect: the caller pre-computes and includes `CommissionOnOpen` in the TVP, so no OPENQUERY or temp table join is needed. The procedure body is a single bulk INSERT from the TVP.

The `OpenPositionsWithCommissionBulkParameters` TVP type (which this procedure consumes) includes a `CommissionOnOpen DECIMAL(14,4) NOT NULL` column - the market-width (spread) commission charged to customers. This allows the hedge cost reporting system to track eToro's revenue from open positions as part of the unrealized hedge cost calculation: `[Etoro Commission - Unrealized] = SUM(CommissionOnOpen)` per server per period.

When the hedge server application has commission data available at snapshot time (calculated client-side), it calls this MW variant to avoid the network round-trip to [AO-REAL-DB-ROR]. When commission must be computed from the DB, `InsertOpenPositionBulk` (non-MW) is called instead. HedgeCostService holds EXECUTE permission on this procedure.

---

## 2. Business Logic

### 2.1 Direct Commission Pass-Through

**What**: Commission is provided by the caller - no DB lookup needed.

**Columns/Parameters Involved**: `@OpenPositions.CommissionOnOpen`

**Rules**:
- TVP type `OpenPositionsWithCommissionBulkParameters` requires `CommissionOnOpen NOT NULL`.
- ISNULL(CommissionOnOpen, 0): defensive NULL guard despite the TVP column being NOT NULL.
- `NetOpenInUSD = 0`: hardcoded, same as other open position variants - updated downstream.
- All other fields (HedgeServerID, InstrumentID, OccurredAt, UnrealizedPL, OpenBuyUnits, OpenSellUnits, PriceRateID) are mapped directly from TVP to table columns.

**Diagram**:
```
Hedge Server application (Market Width mode)
  |
  | Computes open positions WITH commission data included
  | Populates OpenPositionsWithCommissionBulkParameters TVP
  v
EXEC Hedge.InsertOpenPositionBulk_MW(@OpenPositions)
  |
  | INSERT INTO Hedge.CustomerOpenPositions_New
  |   SELECT HedgeServerID, InstrumentID, OccurredAt, UnrealizedPL,
  |          OpenBuyUnits, OpenSellUnits, PriceRateID,
  |          ISNULL(CommissionOnOpen, 0), 0 AS NetOpenInUSD
  |   FROM @OpenPositions
  v
Hedge.CustomerOpenPositions_New (one row per TVP entry)
  |
  +-> Archived to History.CustomerOpenPositions
  +-> Read by HedgeCostReportHistoryPerDay/PerHour for commission unrealized column
```

### 2.2 MW vs Non-MW Selection

**What**: Two variants exist for different caller capabilities.

**Columns/Parameters Involved**: N/A

**Rules**:
- `InsertOpenPositionBulk` (non-MW): caller provides positions WITHOUT commission; procedure queries [AO-REAL-DB-ROR] via OPENQUERY to compute it.
- `InsertOpenPositionBulk_MW` (this procedure): caller provides positions WITH commission pre-computed; no remote query needed.
- Both write to the same `Hedge.CustomerOpenPositions_New` table with identical column mappings.
- Selection depends on whether the hedge server application has commission data available at snapshot time.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OpenPositions | OpenPositionsWithCommissionBulkParameters (TVP) | NO | - | CODE-BACKED | Memory-optimized TVP containing commission-inclusive open position snapshots. Each row: (HedgeServerID, InstrumentID, OccurredAt, UnrealizedPL, OpenBuyUnits, OpenSellUnits, PriceRateID, CommissionOnOpen). READONLY parameter. CommissionOnOpen NOT NULL in the TVP type - caller must supply commission values (0 if none). |

**TVP columns (from Hedge.OpenPositionsWithCommissionBulkParameters):**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | HedgeServerID | INT | Hedge server for this snapshot row |
| 2 | InstrumentID | INT | Trading instrument for this snapshot row |
| 3 | OccurredAt | DATETIME | Snapshot timestamp (NOT NULL) |
| 4 | UnrealizedPL | DECIMAL(14,4) | Unrealized P&L for all open positions on this instrument/server |
| 5 | OpenBuyUnits | INT | Total long position units |
| 6 | OpenSellUnits | INT | Total short position units |
| 7 | PriceRateID | BIGINT | Market rate snapshot ID used for P&L calculation |
| 8 | CommissionOnOpen | DECIMAL(14,4) | Total market-width commission charged to customers (NOT NULL). eToro's revenue component for open positions. Used in [Etoro Commission - Unrealized] in hedge cost reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.CustomerOpenPositions_New | Writer (INSERT) | Bulk INSERT of all TVP rows, commission included from caller |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. HedgeCostService database role holds EXECUTE permission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InsertOpenPositionBulk_MW (procedure)
+-- Hedge.CustomerOpenPositions_New (table) [INSERT - commission-inclusive position snapshots]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerOpenPositions_New | Table | INSERT target for commission-inclusive open position snapshots |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from HedgeCostService application (Market Width mode). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL(CommissionOnOpen, 0) | NULL guard | Defensive check despite TVP column being NOT NULL. |
| NetOpenInUSD = 0 | Placeholder | Hardcoded to 0 - same as other open position insert variants. |

---

## 8. Sample Queries

### 8.1 Execute with commission-inclusive TVP
```sql
DECLARE @Positions [Hedge].[OpenPositionsWithCommissionBulkParameters]
INSERT INTO @Positions VALUES (1, 1, GETUTCDATE(), -250.50, 50000, 0, 9876543210, 125.50)
INSERT INTO @Positions VALUES (1, 4, GETUTCDATE(), 800.00, 0, 10000, 9876543211, 45.00)

EXEC [Hedge].[InsertOpenPositionBulk_MW] @OpenPositions = @Positions
```

### 8.2 Verify latest inserts with commission in CustomerOpenPositions_New
```sql
SELECT TOP 20 HedgeServerID, InstrumentID, OccurredAt,
       OpenedBuyUnits, OpenedSellUnits, UnrealizedPL, CommissionOnOpen, NetOpenInUSD
FROM [Hedge].[CustomerOpenPositions_New] WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

### 8.3 Check unrealized commission by server in History for a date
```sql
SELECT HedgeServerID,
       DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt)) AS Day,
       SUM(CommissionOnOpen) AS TotalCommissionUnrealized
FROM [History].[CustomerOpenPositions] WITH (NOLOCK)
WHERE OccurredAt >= '2026-03-18'
  AND OccurredAt < '2026-03-19'
GROUP BY HedgeServerID, DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt))
ORDER BY HedgeServerID, Day
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InsertOpenPositionBulk_MW | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.InsertOpenPositionBulk_MW.sql*
