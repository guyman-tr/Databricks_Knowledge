# Column Lineage: main.etoro_kpi.customer_exclude_list

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.customer_exclude_list` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\customer_exclude_list.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\customer_exclude_list.json` (rows: 4, mismatches: 1) |
| **Primary upstream** | `main.general.bronze_etoro_customer_customer_masked` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_customer_customer_masked` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md` |

## Lineage Chain

```
main.general.bronze_etoro_customer_customer_masked   ←── primary upstream
        │
        ▼
main.etoro_kpi.customer_exclude_list   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.general.bronze_etoro_customer_customer_masked` | `CID` | `passthrough` | — | cc.CID |
| 2 | `GCID` | `main.general.bronze_etoro_customer_customer_masked` | `GCID` | `passthrough` | — | cc.GCID |
| 3 | `excludeReason` | `main.general.bronze_etoro_customer_customer_masked` | `—` | `case` | — | CASE WHEN LOWER(cc.Comments) LIKE '%abuse%' AND PlayerStatusID = 2 THEN 'Abuser' WHEN PlayerStatusReasonID = 4 THEN 'High risk' WHEN PlayerL |
| 4 | `RegisterationDate` | `main.general.bronze_etoro_customer_customer_masked` | `Registered` | `rename` | — | cc.Registered AS RegisterationDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **4**
- OK: **3**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `excludeReason` | — | `main.general.bronze_etoro_customer_customer_masked.comments`, `main.general.bronze_etoro_customer_customer_masked.playerlevelid`, `main.general.bronze_etoro_customer_customer_masked.playerstatusid`, `main.general.bronze_etoro_customer_customer_masked.playerstatusreasonid`, `main.general.bronze_etoro_customer_customer_masked.username` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **1**
