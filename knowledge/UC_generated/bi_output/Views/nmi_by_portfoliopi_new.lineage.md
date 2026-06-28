# Column Lineage: main.bi_output.nmi_by_portfoliopi_new

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.nmi_by_portfoliopi_new` |
| **Object Type** | `MATERIALIZED_VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\nmi_by_portfoliopi_new.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\nmi_by_portfoliopi_new.json` (rows: 7, mismatches: 6) |
| **Primary upstream** | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_etoro_backoffice_customer` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.general.bronze_etoro_customer_customer_masked` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_db/<Tables|Views>/bronze_etoro_dwh_v_historymirrorhourly.md` |

## Lineage Chain

```
main.bi_db.bronze_etoro_dwh_v_historymirrorhourly   ←── primary upstream
  + main.general.bronze_etoro_customer_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.general.bronze_etoro_backoffice_customer   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager   (JOIN)
        │
        ▼
main.bi_output.nmi_by_portfoliopi_new   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `ParentCID` | `—` | `ParentCID` | `join_enriched` | — | mirror.ParentCID |
| 2 | `CopyType` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` | `CopyType` | `passthrough` | — | CopyType |
| 3 | `UserName` | `—` | `ParentUserName` | `join_enriched` | — | mirror.ParentUserName AS UserName |
| 4 | `Region` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Region` | `join_enriched` | — | dc.Region AS Region |
| 5 | `MoneyIn` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` | `MoneyIn` | `cast` | — | cast to DECIMAL(12, 2) — CAST(MoneyIn AS DECIMAL(12, 2)) AS MoneyIn |
| 6 | `MoneyOut` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` | `MoneyOut` | `cast` | — | cast to DECIMAL(12, 2) — CAST(MoneyOut AS DECIMAL(12, 2)) AS MoneyOut |
| 7 | `NetMoneyIn` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly` | `—` | `unknown` | — | CAST((MoneyIn + MoneyOut) AS DECIMAL(12, 2)) AS NetMoneyIn |

## Cross-check vs system.access.column_lineage

- Total target columns: **7**
- OK: **1**, WARN: **3**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `ParentCID` | — | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.parentcid` | ERROR |
| `CopyType` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.copytype` | `main.general.bronze_etoro_backoffice_customer.accounttypeid` | WARN |
| `UserName` | — | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.parentusername` | ERROR |
| `MoneyIn` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.moneyin` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.amount`, `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.mirroroperationid` | WARN |
| `MoneyOut` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.moneyout` | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.amount`, `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.mirroroperationid` | WARN |
| `NetMoneyIn` | — | `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.amount`, `main.bi_db.bronze_etoro_dwh_v_historymirrorhourly.mirroroperationid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.general.bronze_etoro_customer_customer_masked AS cc ON mirror.ParentCID = cc.CID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON dc.CountryID = cc.CountryID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_backoffice_customer AS bc ON bc.CID = cc.CID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager AS bm ON bc.ManagerID = bm.ManagerID
- `INNER INNER` — INNER JOIN main.general.bronze_etoro_backoffice_customer AS bc ON hm.ParentCID = bc.CID AND (AccountTypeID = 9 OR GuruStatusID >= 2)
