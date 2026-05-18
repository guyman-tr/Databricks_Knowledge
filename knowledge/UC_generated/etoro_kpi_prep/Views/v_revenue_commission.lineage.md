# Column Lineage: main.etoro_kpi_prep.v_revenue_commission

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_commission` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_commission.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_commission.json` (rows: 15, mismatches: 3) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
        │
        ▼
main.etoro_kpi_prep.v_revenue_commission   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PositionID` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to BIGINT — CAST(fca.PositionID AS BIGINT) AS PositionID |
| 2 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to INT — CAST(fca.RealCID AS INT) AS RealCID |
| 3 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DateID` | `cast` | (Tier 2 — SP_Fact_CustomerAction) | cast to INT — CAST(fca.DateID AS INT) AS DateID |
| 4 | `Occurred` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Occurred` | `passthrough` | (Tier 1 — source-dependent) | fca.Occurred |
| 5 | `etr_ymd` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `etr_ymd` | `passthrough` | — | fca.etr_ymd |
| 6 | `Commission` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Commission` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to DECIMAL(38, 6) — CAST(fca.Commission AS DECIMAL(38, 6)) AS Commission |
| 7 | `CommissionOnClose` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CommissionOnClose` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to DECIMAL(38, 6) — CAST(fca.CommissionOnClose AS DECIMAL(38, 6)) AS CommissionOnClose |
| 8 | `CommissionByUnits` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CommissionByUnits` | `cast` | (Tier 1 — Trade.Position) | cast to DECIMAL(38, 6) — CAST(fca.CommissionByUnits AS DECIMAL(38, 6)) AS CommissionByUnits |
| 9 | `ActionTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `ActionTypeID` | `cast` | (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) | cast to INT — CAST(fca.ActionTypeID AS INT) AS ActionTypeID |
| 10 | `ActionType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN fca.ActionTypeID IN (1, 2, 3, 39) THEN 'Open' ELSE 'Close' END AS ActionType |
| 11 | `IsActiveTrade` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN fca.MirrorID > 0 AND COALESCE(fca.IsAirdrop, 0) = 0 THEN 1 ELSE 0 END AS IsActiveTrade |
| 12 | `IsSettled` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsSettled` | `cast` | (Tier 5 — Expert Review) | cast to INT — CAST(fca.IsSettled AS INT) AS IsSettled |
| 13 | `MirrorID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `MirrorID` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to INT — CAST(fca.MirrorID AS INT) AS MirrorID |
| 14 | `SettlementTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `SettlementTypeID` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to INT — CAST(fca.SettlementTypeID AS INT) AS SettlementTypeID |
| 15 | `TotalCommission` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `unknown` | — | CAST(CASE WHEN fca.ActionTypeID IN (1, 2, 3, 39) THEN fca.Commission WHEN fca.ActionTypeID IN (4, 5, 6, 28, 40) THEN (fca.CommissionOnClose  |

## Cross-check vs system.access.column_lineage

- Total target columns: **15**
- OK: **12**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `ActionType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid` | ERROR |
| `IsActiveTrade` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.isairdrop`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid` | ERROR |
| `TotalCommission` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.commission`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.commissionbyunits`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.commissiononclose` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**
