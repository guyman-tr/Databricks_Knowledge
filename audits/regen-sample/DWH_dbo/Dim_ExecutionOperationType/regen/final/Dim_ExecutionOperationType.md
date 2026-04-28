# DWH_dbo.Dim_ExecutionOperationType

> 25-row dictionary dimension table enumerating execution operation types used in the HistoryCosts domain. Loaded from `HistoryCosts.Dictionary.ExecutionOperationType` via `SP_Dictionaries_DL_To_Synapse` with full truncate-reload on each run. Covers operation IDs 0–24 representing order, position, and administrative execution actions.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `HistoryCosts.Dictionary.ExecutionOperationType` via `SP_Dictionaries_DL_To_Synapse` |
| **Refresh** | Daily full truncate-reload (part of SP_Dictionaries_DL_To_Synapse batch) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (`OperationTypeId` ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (dictionary dimension) |

---

## 1. Business Meaning

`Dim_ExecutionOperationType` is a small dictionary dimension (25 rows) that classifies the types of execution operations in the trading platform's cost-tracking subsystem (HistoryCosts). Each row represents a distinct operation type — such as opening or closing an order, cancelling a delayed order, position opens/closes, operational adjustments, and administrative actions.

The table is populated by `SP_Dictionaries_DL_To_Synapse`, which performs a full truncate-and-reload from the staging table `DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType`. The `OperationTypeId` column is renamed from `[Id]` in the source, `OperationType` is a direct passthrough, and `UpdateDate` is set to `getdate()` at load time.

Operation types span several categories:
- **Order operations** (0–11): OrderForOpen, OrderForClose, their mirror variants, cancellations, and status updates (Rejected/Filled)
- **Position operations** (12–19): PositionClose, PositionCloseByLimit, PositionOpen, Operational and Direct open/close, OperationalPositionAdjustment
- **Limit/Rate close orders** (20–21): OrderForCloseByLimit, OrderForCloseByRate
- **Administrative operations** (22–24): AdminOrderForOpenWithHedge, AdminOrderForOpenWithoutHedge, AdminPositionOpen

---

## 2. Business Logic

### 2.1 Operation Type Classification

**What**: Each `OperationTypeId` maps to exactly one `OperationType` string label describing an execution action.
**Columns Involved**: `OperationTypeId`, `OperationType`
**Rules**:
- IDs 0–11 represent order-level operations (open, close, cancel, status updates) including mirror-trade variants
- IDs 12–19 represent position-level operations (direct opens/closes, operational adjustments)
- IDs 20–21 represent limit/rate-triggered close orders
- IDs 22–24 represent administrative (back-office) order and position operations
- Mirror variants (IDs 1, 3) indicate operations triggered by the CopyTrader (mirror) system

### 2.2 Full Truncate-Reload Pattern

**What**: The table is fully replaced on each ETL run — no incremental logic.
**Columns Involved**: All
**Rules**:
- `TRUNCATE TABLE` precedes every `INSERT`, so all rows are refreshed each cycle
- `UpdateDate` reflects the last ETL run timestamp, not the creation date of the operation type
- No SCD (slowly changing dimension) logic applies — this is a static dictionary

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution is ROUND_ROBIN (appropriate for a 25-row dictionary). Clustered index on `OperationTypeId` supports efficient point lookups. Broadcasting cost is negligible at this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What operation type is ID 14? | `SELECT * FROM DWH_dbo.Dim_ExecutionOperationType WHERE OperationTypeId = 14` |
| List all order-related operations | `SELECT * FROM DWH_dbo.Dim_ExecutionOperationType WHERE OperationType LIKE 'Order%'` |
| List all admin operations | `SELECT * FROM DWH_dbo.Dim_ExecutionOperationType WHERE OperationType LIKE 'Admin%'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| HistoryCosts fact tables | `ON fact.OperationTypeId = dim.OperationTypeId` | Resolve operation type labels for cost records |

### 3.4 Gotchas

- The table has only 25 rows (IDs 0–24). Any `OperationTypeId` outside this range in a fact table indicates an unmapped or new operation type.
- `OperationType` is `nvarchar(max)` — use caution in GROUP BY or DISTINCT operations on very large joins (though the dictionary itself is tiny).
- All `UpdateDate` values are identical (last ETL run timestamp) — this column does NOT reflect when each operation type was first introduced.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (no upstream wiki available for this object) |
| Tier 2 | Derived from SP code or ETL logic |
| Tier 3 | No source traceable; human review needed |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | OperationTypeId | int | YES | Surrogate key identifying the execution operation type. Renamed from `[Id]` in the production source `HistoryCosts.Dictionary.ExecutionOperationType`. Integer sequence 0–24 covering order operations (0–11), position operations (12–19), limit/rate close orders (20–21), and administrative operations (22–24). (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 2 | OperationType | nvarchar(max) | YES | Descriptive label for the execution operation type. Passthrough from `HistoryCosts.Dictionary.ExecutionOperationType`. Values include: OrderForOpen, OrderForOpenInMirror, OrderForClose, OrderForCloseInMirror, CancelDelayedOrderForOpen, CancelDelayedOrderForClose, CancelOrderForOpen, CancelOrderForClose, OrderForOpenStatusUpdateRejected, OrderForCloseStatusUpdateRejected, OrderForCloseStatusUpdateFilled, OrderForOpenStatusUpdateFilled, PositionClose, PositionCloseByLimit, PositionOpen, OperationalOpenPosition, OperationalClosePosition, OperationalPositionAdjustment, DirectOpenPosition, DirectClosePosition, OrderForCloseByLimit, OrderForCloseByRate, AdminOrderForOpenWithHedge, AdminOrderForOpenWithoutHedge, AdminPositionOpen. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp set to `getdate()` at each SP_Dictionaries_DL_To_Synapse execution. Reflects when the dictionary was last refreshed, not when individual operation types were created. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| OperationTypeId | HistoryCosts.Dictionary.ExecutionOperationType | Id | Rename: `[Id]` → `[OperationTypeId]` |
| OperationType | HistoryCosts.Dictionary.ExecutionOperationType | OperationType | Passthrough |
| UpdateDate | — | — | ETL-computed: `getdate()` |

### 5.2 ETL Pipeline

```
HistoryCosts.Dictionary.ExecutionOperationType (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) ---|
  v
DWH_dbo.Dim_ExecutionOperationType (25 rows)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_executionoperationtype
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No outbound foreign keys. This is a root dictionary table. |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| OperationTypeId | HistoryCosts fact tables | Used as FK to resolve execution operation type labels |

---

## 7. Sample Queries

### 7.1 List All Operation Types

```sql
SELECT OperationTypeId, OperationType
FROM DWH_dbo.Dim_ExecutionOperationType
ORDER BY OperationTypeId;
```

### 7.2 Find Mirror-Related Operations

```sql
SELECT OperationTypeId, OperationType
FROM DWH_dbo.Dim_ExecutionOperationType
WHERE OperationType LIKE '%Mirror%';
```

### 7.3 Join with Cost Facts to Label Operations

```sql
SELECT f.*, d.OperationType
FROM DWH_dbo.SomeHistoryCostsFact f
JOIN DWH_dbo.Dim_ExecutionOperationType d
  ON f.OperationTypeId = d.OperationTypeId
WHERE d.OperationType = 'PositionOpen';
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this object (simple dictionary fast-path — Atlassian search skipped).

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 7/14*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 6/10, Lineage: 8/10*
*Object: DWH_dbo.Dim_ExecutionOperationType | Type: Table | Production Source: HistoryCosts.Dictionary.ExecutionOperationType (no upstream wiki)*
