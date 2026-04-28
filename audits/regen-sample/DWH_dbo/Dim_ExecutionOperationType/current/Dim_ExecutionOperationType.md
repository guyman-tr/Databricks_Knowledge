# DWH_dbo.Dim_ExecutionOperationType

> Trading execution operation type dimension - classifies how positions and orders were created, modified, or cancelled in the HistoryCosts cost tracking system.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | HistoryCosts.Dictionary.ExecutionOperationType |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (OperationTypeId ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_ExecutionOperationType` is a 25-row dictionary (IDs 0-24) classifying trading execution operations used by the HistoryCosts system. The values describe how a position or order was initiated, filled, rejected, or cancelled across five operational contexts: standard orders, mirror/copy-trade orders, direct (back-office) operations, admin overrides, and limit/rate-triggered closures.

The data originates from `HistoryCosts.Dictionary.ExecutionOperationType` on the HistoryCosts production database. This database has no upstream wiki in DB_Schema (confirmed). The ETL loads from `DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType`, part of the broader SP_Dictionaries HistoryCosts section (lines 1342+ of SP_Dictionaries_DL_To_Synapse).

**Note**: No active DWH table or SP in the SSDT repo references `Dim_ExecutionOperationType.OperationTypeId` as a foreign key in the current schema. This dimension is maintained as a reference for the HistoryCosts cost tables (Fact_History_Cost) which are not yet documented. The ROUND_ROBIN distribution is a known anomaly - same pattern as Dim_CalculationType, applied without size consideration despite the table having only 25 rows (REPLICATE would be more appropriate).

`SP_Dictionaries_DL_To_Synapse` TRUNCATE + INSERT. Column `Id` renamed to `OperationTypeId`. Daily refresh. Last updated 2026-03-11 (~8 days stale as of 2026-03-19).

---

## 2. Business Logic

### 2.1 Operation Type Taxonomy

**What**: The 25 operation types group into five categories representing different paths through the trading execution pipeline.

**Columns Involved**: `OperationTypeId`, `OperationType`

**Rules**:
- **Standard Orders (0-11)**: Order lifecycle events for normal positions (open/close orders, cancellations, status updates for filled/rejected)
- **Position Events (12-14)**: Direct position state changes (PositionClose, PositionCloseByLimit, PositionOpen)
- **Operational (15-17)**: Back-office initiated position actions (OperationalOpenPosition, OperationalClosePosition, OperationalPositionAdjustment)
- **Direct (18-19)**: Direct position management (DirectOpenPosition, DirectClosePosition)
- **Limit/Rate Triggered (20-21)**: Automated close triggers (OrderForCloseByLimit, OrderForCloseByRate)
- **Admin (22-24)**: Administrative overrides (AdminOrderForOpenWithHedge, AdminOrderForOpenWithoutHedge, AdminPositionOpen)
- **Mirror variants (1, 3)**: Copy-trade versions of open/close operations

**Diagram**:
```
Standard Order Path:
  0  OrderForOpen -> 11 OrderForOpenStatusUpdateFilled
                  -> 8  OrderForOpenStatusUpdateRejected
                  -> 4  CancelDelayedOrderForOpen
                  -> 6  CancelOrderForOpen

  2  OrderForClose -> 10 OrderForCloseStatusUpdateFilled
                   -> 9  OrderForCloseStatusUpdateRejected
                   -> 5  CancelDelayedOrderForClose
                   -> 7  CancelOrderForClose
                   -> 20 OrderForCloseByLimit (limit triggered)
                   -> 21 OrderForCloseByRate (rate triggered)
                   -> 13 PositionCloseByLimit

Mirror Variants:
  1  OrderForOpenInMirror (copy-trade)
  3  OrderForCloseInMirror (copy-trade)

Direct/Admin/Operational:
  14 PositionOpen | 12 PositionClose
  18 DirectOpenPosition | 19 DirectClosePosition
  15-17 Operational* | 22-24 Admin*
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed - an anomaly for a 25-row dictionary (REPLICATE would avoid data movement). The CLUSTERED INDEX on `OperationTypeId` supports efficient lookups. Joins from large fact tables will incur data movement due to the non-REPLICATE distribution. Use broadcast hints if needed.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 25 rows - no partitioning needed. Broadcast join is automatic regardless of distribution strategy.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode OperationTypeId in cost records | `LEFT JOIN DWH_dbo.Dim_ExecutionOperationType ON OperationTypeId` |
| Find all cancel operations | `WHERE OperationType LIKE 'Cancel%'` |
| Find mirror/copy-trade operations | `WHERE OperationTypeId IN (1, 3)` |
| Find admin-initiated operations | `WHERE OperationTypeId IN (22, 23, 24)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_History_Cost (pending) | ON OperationTypeId | Decode execution operation type in cost records |

### 3.4 Gotchas

- **ROUND_ROBIN distribution**: Unlike other Dim_ tables which use REPLICATE, this table uses ROUND_ROBIN. JOINs from large fact tables will require data movement. This is a known distribution anomaly (same as Dim_CalculationType).
- **OperationTypeId starts at 0**: ID=0 (OrderForOpen) is a valid production value, not a placeholder. There is no N/A row.
- **HistoryCosts context**: These operation types are specific to the HistoryCosts cost tracking system, not the main trading platform. They represent how trades were executed for cost attribution purposes.
- **"InMirror" = copy-trade**: Operations with "InMirror" (IDs 1, 3) are copy-trade (mirror) variants of standard open/close orders.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | OperationTypeId | int | YES | Primary key. Integer code identifying the trading execution operation type. Values: 0=OrderForOpen, 1=OrderForOpenInMirror, 2=OrderForClose, 3=OrderForCloseInMirror, 4=CancelDelayedOrderForOpen, 5=CancelDelayedOrderForClose, 6=CancelOrderForOpen, 7=CancelOrderForClose, 8=OrderForOpenStatusUpdateRejected, 9=OrderForCloseStatusUpdateRejected, 10=OrderForCloseStatusUpdateFilled, 11=OrderForOpenStatusUpdateFilled, 12=PositionClose, 13=PositionCloseByLimit, 14=PositionOpen, 15=OperationalOpenPosition, 16=OperationalClosePosition, 17=OperationalPositionAdjustment, 18=DirectOpenPosition, 19=DirectClosePosition, 20=OrderForCloseByLimit, 21=OrderForCloseByRate, 22=AdminOrderForOpenWithHedge, 23=AdminOrderForOpenWithoutHedge, 24=AdminPositionOpen. Renamed from `Id` in source. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 | OperationType | nvarchar(max) | YES | Human-readable operation type name. Passthrough from source column with same name. Uses nvarchar(max) in DWH (oversized for these short strings). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL constraint (unlike most other DWH dict tables). Does not reflect production source update time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| OperationTypeId | HistoryCosts.Dictionary.ExecutionOperationType | Id | rename: Id -> OperationTypeId |
| OperationType | HistoryCosts.Dictionary.ExecutionOperationType | OperationType | passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at SP execution time |

### 5.2 ETL Pipeline

```
HistoryCosts.Dictionary.ExecutionOperationType -> Staging pipeline -> DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_ExecutionOperationType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | HistoryCosts.Dictionary.ExecutionOperationType | Execution operation type dictionary on HistoryCosts production DB |
| Staging | DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames Id->OperationTypeId. Adds UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_ExecutionOperationType | 25-row ROUND_ROBIN dict (anomaly). Daily refresh. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references to other DWH objects. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_History_Cost (pending) | OperationTypeId (expected) | Cost records classified by execution operation type |

---

## 7. Sample Queries

### 7.1 List all execution operation types

```sql
SELECT OperationTypeId, OperationType
FROM DWH_dbo.Dim_ExecutionOperationType
ORDER BY OperationTypeId
```

### 7.2 Find cancel operation codes

```sql
SELECT OperationTypeId, OperationType
FROM DWH_dbo.Dim_ExecutionOperationType
WHERE OperationType LIKE 'Cancel%'
ORDER BY OperationTypeId
```

### 7.3 Categorize operations by type group

```sql
SELECT
    CASE
        WHEN OperationTypeId IN (0,1,2,3,4,5,6,7,8,9,10,11) THEN 'Order Lifecycle'
        WHEN OperationTypeId IN (12,13,14) THEN 'Position Event'
        WHEN OperationTypeId IN (15,16,17) THEN 'Operational'
        WHEN OperationTypeId IN (18,19) THEN 'Direct'
        WHEN OperationTypeId IN (20,21) THEN 'Limit/Rate Triggered'
        WHEN OperationTypeId IN (22,23,24) THEN 'Admin'
        ELSE 'Unknown'
    END AS OperationCategory,
    COUNT(*) AS TypeCount
FROM DWH_dbo.Dim_ExecutionOperationType
GROUP BY
    CASE
        WHEN OperationTypeId IN (0,1,2,3,4,5,6,7,8,9,10,11) THEN 'Order Lifecycle'
        WHEN OperationTypeId IN (12,13,14) THEN 'Position Event'
        WHEN OperationTypeId IN (15,16,17) THEN 'Operational'
        WHEN OperationTypeId IN (18,19) THEN 'Direct'
        WHEN OperationTypeId IN (20,21) THEN 'Limit/Rate Triggered'
        WHEN OperationTypeId IN (22,23,24) THEN 'Admin'
        ELSE 'Unknown'
    END
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Dim_ExecutionOperationType | Type: Table | Production Source: HistoryCosts.Dictionary.ExecutionOperationType*
