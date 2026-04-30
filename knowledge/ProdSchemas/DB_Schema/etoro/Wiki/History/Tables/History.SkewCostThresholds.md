# History.SkewCostThresholds

> System-versioned temporal history table for Price.SkewCostThresholds, recording all past per-instrument threshold configurations that govern the skew cost model's acceptable spread deviation limits.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `Price.SkewCostThresholds` (source declares `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[SkewCostThresholds])`). SQL Server automatically archives superseded rows here when threshold values are changed.

`Price.SkewCostThresholds` stores per-instrument threshold values for the **skew cost model** - eToro's pricing system that computes the cost of spread skew (the deviation of offered buy/sell prices from the mid-market price). The `Threshold` value defines the boundary condition for each instrument: when skew cost exceeds the threshold, the skew cost model triggers an action (alert, adjustment, or pricing change). The PK is InstrumentID - one threshold per instrument.

Both the source table and history table currently have 0 rows. The skew cost threshold configuration has not been populated in this environment, or is managed elsewhere (e.g., the SKEW_COST_MODEL_SERVICE service type observed in Dictionary.ServiceType at ID=47 may consume this via application configuration). The table infrastructure is in place for per-instrument skew cost threshold governance.

Note: `TRG_T_SkewCostThresholds` performs a no-op self-update on INSERT to ensure consistent temporal registration.

---

## 2. Business Logic

### 2.1 Per-Instrument Skew Cost Threshold

**What**: Each instrument can have its own threshold beyond which skew cost is considered excessive.

**Columns/Parameters Involved**: `InstrumentID`, `Threshold`

**Rules**:
- One row per InstrumentID (PK) - each instrument has at most one threshold
- `Threshold` is decimal(10,4) - supports precise fractional cost values (e.g., 0.0025 for 0.25 basis points)
- FK: InstrumentID -> Trade.Instrument - only valid tradable instruments can have thresholds
- The threshold is evaluated by the skew cost model service (SKEW_COST_MODEL_SERVICE, ServiceTypeID=47)

---

## 3. Data Overview

Both source (`Price.SkewCostThresholds`) and history (`History.SkewCostThresholds`) have 0 rows. No skew cost thresholds have been configured in this environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this skew cost threshold applies to. PK in source table (one threshold per instrument). FK to Trade.Instrument(InstrumentID). Each history row represents a past threshold state for this instrument. |
| 2 | Threshold | decimal(10,4) | NO | - | NAME-INFERRED | The skew cost threshold for this instrument. When computed skew cost exceeds this value, the model triggers an action. High precision (10,4) supports fine-grained threshold tuning. The exact interpretation (absolute cost, percentage, basis points) depends on the skew cost model service consuming this table. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Computed in source as `suser_name()` - SQL Server login that last modified this threshold. Stored as a plain value in history. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Computed in source as `CONVERT(varchar(500), context_info())` - application-set session context at time of change. NULL when context_info() was not set. |
| 5 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this threshold became current in `Price.SkewCostThresholds`. Automatically managed by SQL Server temporal system versioning. |
| 6 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this threshold was superseded. Automatically set by SQL Server. Leading key of the clustered index. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Price.SkewCostThresholds | Temporal History | Each row is a past threshold state for the instrument identified by InstrumentID. |
| InstrumentID | Trade.Instrument | Implicit (FK on source) | The tradable instrument this threshold governs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SkewCostThresholds | HISTORY_TABLE | Temporal History | Active source table; SQL Server archives expired rows here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SkewCostThresholds (table)
  (temporal history - no code-level dependencies; populated by SQL Server from Price.SkewCostThresholds)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.SkewCostThresholds | Table | Active source table; expired rows archived here by SQL Server. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_SkewCostThresholds | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival data. |

---

## 8. Sample Queries

### 8.1 View all past threshold changes
```sql
SELECT
    InstrumentID,
    Threshold,
    DbLoginName,
    SysStartTime AS ValidFrom,
    SysEndTime AS ValidTo
FROM [History].[SkewCostThresholds] WITH (NOLOCK)
ORDER BY SysEndTime DESC
```

### 8.2 Track threshold history for a specific instrument
```sql
SELECT
    Threshold,
    DbLoginName,
    SysStartTime AS EffectiveFrom,
    SysEndTime AS EffectiveTo,
    LAG(Threshold) OVER (ORDER BY SysStartTime) AS PreviousThreshold
FROM [History].[SkewCostThresholds] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
ORDER BY SysStartTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.2/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 7.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SkewCostThresholds | Type: Table | Source: etoro/etoro/History/Tables/History.SkewCostThresholds.sql*
