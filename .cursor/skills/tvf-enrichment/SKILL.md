---
name: tvf-enrichment
description: Enrich descriptions for Synapse Table-Valued Functions (TVFs) that are materialized as views in Unity Catalog. Use when working with TVFs, etoro_kpi_prep views, Function_Population_*, Function_Revenue_*, Function_MIMO_*, or enriching DDR/downstream table columns that originate from TVFs. Covers the full workflow from reading source SQL to propagating comments downstream.
---

# TVF Enrichment Workflow

## Background

Synapse BI_DB TVFs (e.g. `Function_Population_Funded`, `Function_Revenue_Commissions`) have no Tier 1 wiki layer. In Unity Catalog, they're materialized as views in `etoro_kpi_prep` schema. Their columns feed downstream DDR tables, CIDFirstDates, and other reporting objects.

## TVF → UC View Mapping

The canonical mapping lives in `tools/apply_tvf_col_comments.py` (the `MAPPING` list). Key patterns:

| Synapse TVF | UC View |
|-------------|---------|
| `Function_Population_Funded` | `main.etoro_kpi_prep.v_population_funded` |
| `Function_Population_Active_Traders` | `main.etoro_kpi_prep.v_population_active_traders` |
| `Function_Revenue_Commissions` | `main.etoro_kpi_prep.v_revenue_commission` |
| `Function_MIMO_First_Deposit_All_Platforms` | `main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms` |
| `Function_Trading_Volume` | `main.etoro_kpi_prep.v_trading_volume_and_amount` |

Full list: 34 TVFs mapped in the `MAPPING` array.

## Enrichment Workflow (Step by Step)

### Step 1: Read the Synapse TVF Source

**Authoritative source**: `DataPlatform/SynapseSQLPool1/sql_dp_prod_we/BI_DB_dbo/Functions/BI_DB_dbo.<TVF_name>.sql`

**Do NOT rely on**: `_Explain` TVFs — these are stale and not maintained. The function CREATE scripts are the source of truth.

Read the function body to understand:
- Column definitions and SELECT expressions
- WHERE clauses and JOIN logic
- Upstream table references (which Tier 1 tables feed this TVF)

### Step 2: Build/Update the Wiki

Wiki files live at: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/<TVF_name>.md`

Key section is **§4 Output Columns** with this table format:

```markdown
| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | DateID | Fact_CustomerAction.DateID | Direct pass-through | T1 — Function_Population_Funded |
| 2 | IsFunded | CASE WHEN ... | 1 if customer had ≥$50 deposited in prior 365d, else 0 | T1+Transform — Function_Population_Funded |
```

**Tier classification**:
- `T1` — Column exists verbatim in a Tier 1 wiki (DB_Schema glossary or upstream documented table)
- `T1+Transform` — Tier 1 concept with a transformation applied in the TVF
- `T2` — Derived in the TVF with no direct Tier 1 ancestor

### Step 3: Consult Tier 1 Sources

For business definitions, check these in order:
1. `DB_Schema/etoro/Wiki/_glossary.md` — canonical business glossary
2. `DB_Schema/etoro/Wiki/<upstream_table>.md` — upstream table wikis
3. `ExperianceDBs/` — newer Tier 1 wikis for eMoney, ExW schemas

Key definitions that come up repeatedly:
- **Funded**: Customer with ≥$50 total deposits in prior 365 days
- **First Time Funded (FTD)**: Date of first deposit ≥$50
- **Active Trader**: Customer who opened ≥1 position in the period
- **Balance Only Account**: Funded customer with no open positions
- **Portfolio Only**: Customer with positions but no trading activity in period

### Step 4: Generate Alter Scripts

For the TVF views themselves, the wiki's §4 table drives `apply_tvf_col_comments.py`:
```bash
python tools/apply_tvf_col_comments.py --only Function_Population_Funded
```

For downstream tables (DDR, CIDFirstDates), update the `.alter.sql` file in the table's wiki folder with enriched `ALTER COLUMN ... COMMENT` statements.

### Step 5: Propagate Downstream

TVF columns flow into downstream objects. Trace lineage via:

```sql
SELECT downstream_table_name, downstream_column_name,
       upstream_table_name, upstream_column_name
FROM system.access.column_lineage
WHERE upstream_table_name LIKE '%v_population%'
  AND event_date >= CURRENT_DATE - 30
GROUP BY ALL
```

**Key downstream targets**:
- `bi_db.gold_*_bi_db_ddr_customer_daily_status` — TVF population flags
- `bi_db.gold_*_bi_db_ddr_customer_periodic_status` — weekly/monthly/quarterly/yearly variants
- `bi_db.gold_*_bi_db_ddr_fact_mimo_allplatforms` — MIMO TVF columns
- `bi_db.gold_*_bi_db_ddr_fact_trading_volumes_and_amounts` — volume TVF columns
- `bi_db.gold_*_bi_db_ddr_fact_revenue_generating_actions` — revenue TVF columns
- `bi_db.gold_*_bi_db_cidfirstdates` — first-date columns from population TVFs
- `pii_data.gold_*_bi_db_cidfirstdates` — PII copy

When enriching a downstream column, include the TVF origin in the comment:
```
1 if customer had ≥$50 deposited in prior 365 days, else 0. Source: Function_Population_Funded.IsFunded. (T1+Transform)
```

### Step 6: Deploy

Use the `uc-deploy-comments` skill for deployment. For TVF views use `apply_tvf_col_comments.py`. For downstream tables use `deploy_alter_batch.py` or `deploy_ddr_enrichment.py`.

## Periodic Status Column Variants

`DDR_Customer_Periodic_Status` has 4 period variants per column:
- `ColName_ThisWeek` — already in the alter file if base `ColName` is documented
- `ColName_ThisMonth` — often MISSING from the alter file, needs manual addition
- `ColName_ThisQuarter` — same
- `ColName_ThisYear` — same

Always check that all 4 variants exist in the alter script when enriching periodic status columns.

## Common Pitfalls

1. **`_Explain` TVFs are stale** — never treat them as authoritative. Cross-reference with the actual function CREATE script.
2. **Periodic variants** — easy to forget `_ThisMonth`/`_ThisQuarter`/`_ThisYear`. Always check.
3. **COMMENT ON COLUMN** — required for views. `ALTER TABLE ALTER COLUMN COMMENT` will fail.
4. **Override tables** — DDR tables are NOT Override (they're Append), so comments persist. Dimension tables often ARE Override and lose comments daily.
5. **Concurrent ETL** — DDR tables are written during overnight ETL windows. Deploy outside 04:00–08:00 UTC or retry `DELTA_METADATA_CHANGED` errors.
