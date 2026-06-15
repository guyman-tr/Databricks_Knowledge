# Column Lineage: main.bi_output.bi_output_vg_customer_assignment

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_customer_assignment` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_customer_assignment.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_customer_assignment.json` (rows: 11, mismatches: 1) |
| **Primary upstream** | `main.crm.gold_crm_accountsmanager` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.crm.gold_crm_accountsmanager` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_output.bi_output_vg_crm_user` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_crm_user.md` |

## Lineage Chain

```
main.crm.gold_crm_accountsmanager   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.bi_output.bi_output_vg_crm_user   (JOIN)
        │
        ▼
main.bi_output.bi_output_vg_customer_assignment   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RealCID` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.RealCID |
| 2 | `SalesForceAccountID` | `main.crm.gold_crm_accountsmanager` | `AccountId` | `rename` | — | am.AccountId AS SalesForceAccountID |
| 3 | `AM_CID` | `main.bi_output.bi_output_vg_crm_user` | `BO_User_ID` | `join_enriched` | — | u.BO_User_ID AS AM_CID |
| 4 | `AM_ID` | `main.crm.gold_crm_accountsmanager` | `OwnerId` | `rename` | — | am.OwnerId AS AM_ID |
| 5 | `AM_FullName` | `main.bi_output.bi_output_vg_crm_user` | `FullName` | `join_enriched` | — | u.FullName AS AM_FullName |
| 6 | `AM_Department` | `main.bi_output.bi_output_vg_crm_user` | `Department` | `join_enriched` | — | u.Department AS AM_Department |
| 7 | `AM_Position` | `main.bi_output.bi_output_vg_crm_user` | `Position` | `join_enriched` | — | u.Position AS AM_Position |
| 8 | `AssignmentCreatedDate` | `main.crm.gold_crm_accountsmanager` | `CreatedDate` | `rename` | — | am.CreatedDate AS AssignmentCreatedDate |
| 9 | `AssignmentStartAt` | `main.crm.gold_crm_accountsmanager` | `__START_AT` | `rename` | — | am.__START_AT AS AssignmentStartAt |
| 10 | `AssignmentEndAt` | `main.crm.gold_crm_accountsmanager` | `__END_AT` | `rename` | — | am.__END_AT AS AssignmentEndAt |
| 11 | `IsCurrentAssignment` | `main.crm.gold_crm_accountsmanager` | `—` | `case` | — | CASE WHEN am.__END_AT IS NULL THEN 1 ELSE 0 END AS IsCurrentAssignment |

## Cross-check vs system.access.column_lineage

- Total target columns: **11**
- OK: **10**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IsCurrentAssignment` | — | `main.crm.gold_crm_accountsmanager.__end_at` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **6**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dcu ON am.AccountId = dcu.SalesForceAccountID
- `INNER JOIN` — JOIN main.bi_output.bi_output_vg_crm_user AS u ON am.OwnerId = u.UserId
