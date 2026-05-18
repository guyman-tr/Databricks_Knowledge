# Column Lineage: main.etoro_kpi_prep.v_copyfund_positions

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_copyfund_positions` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_copyfund_positions.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_copyfund_positions.json` (rows: 9, mismatches: 6) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.dim_position` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror   ←── primary upstream
  + main.dwh.dim_position   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_copyfund_positions   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `PositionID` | `passthrough` | — | PositionID |
| 2 | `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `CID` | `passthrough` | (Tier 1 — Trade.Mirror) | CID |
| 3 | `MirrorID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `MirrorID` | `passthrough` | (Tier 1 — Trade.Mirror) | MirrorID |
| 4 | `OpenDateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `OpenDateID` | `passthrough` | (Tier 2 — SP_Dim_Mirror_DL_To_Synapse) | OpenDateID |
| 5 | `CloseDateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `—` | `aggregate` | — | MAX(CloseDateID) AS CloseDateID |
| 6 | `ParentCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `ParentCID` | `passthrough` | (Tier 1 — Trade.Mirror) | ParentCID |
| 7 | `ParentUserName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `ParentUserName` | `passthrough` | (Tier 1 — Trade.Mirror) | ParentUserName |
| 8 | `MirrorTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `MirrorTypeID` | `passthrough` | (Tier 1 — Trade.Mirror) | MirrorTypeID |
| 9 | `IsPartialCloseChild` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `IsPartialCloseChild` | `passthrough` | — | IsPartialCloseChild |

## Cross-check vs system.access.column_lineage

- Total target columns: **9**
- OK: **3**, WARN: **5**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `PositionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.positionid` | `main.dwh.dim_position.positionid` | WARN |
| `CID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.cid` | `main.dwh.dim_position.cid` | WARN |
| `MirrorID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.mirrorid` | `main.dwh.dim_position.mirrorid` | WARN |
| `OpenDateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.opendateid` | `main.dwh.dim_position.opendateid` | WARN |
| `CloseDateID` | — | `main.dwh.dim_position.closedateid` | ERROR |
| `IsPartialCloseChild` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.ispartialclosechild` | `main.dwh.dim_position.ispartialclosechild` | WARN |

## Lost / added columns

- Computed/added columns vs primary: **1**

## Joins (detected)

- `INNER JOIN` — JOIN copyfund_mirrors AS cfm ON dp.MirrorID = cfm.MirrorID
