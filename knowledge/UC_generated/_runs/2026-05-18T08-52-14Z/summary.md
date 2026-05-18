# Run Summary — 2026-05-18T08-52-14Z

**Schemas**: etoro_kpi_prep
**Wall-clock**: 56.0s
**UC queries**: column_lineage=1 table_lineage=1 information_schema=?
**Phases run**: -1,0,1,2,3,4,5,6,7
**CLI args**: `--schemas etoro_kpi_prep --phases 5,6,7 --force --max-parallelism 1`
**DAG nodes**: — (— in-scope)

## Per-schema rollup

| Schema | In-scope | Out-of-scope | Generated | Deployed | Blocked | Failed | Unverified cols |
|--------|----------|--------------|-----------|----------|---------|--------|-----------------|
| `etoro_kpi_prep` | 53 | 0 | 21 | 0 | 1 | 28 | 249 |
| **TOTAL** | **53** | **0** | **21** | **0** | **1** | **28** | **249** |

## Blocked objects (grouped by upstream)

| Upstream FQN | Blocking N objects | Affected objects | Routing-rule attempts |
|--------------|-------------------|------------------|----------------------|
| `main.etoro_kpi_prep.v_revenue_stakingfee` | 1 | `etoro_kpi_prep.v_ddr_revenues` | rules 1-5 attempted in cache_upstream_wikis.py; see _discovery/upstream_wikis/_index.json |

## Phase time breakdown

| Phase | Wall-clock (sum across schemas) | Rows processed |
|-------|-------------------------------|----------------|
| 5 | 13.2s | 0 |
| 6 | 2.1s | 0 |
| 7 | 39.0s | 53 |

## Adversarial evaluator (Phase 7)

| Schema | Evaluated | First-pass PASS | Regen PASS | Final FAIL | Avg weighted | InhFid | NarrAcc | NullProv | Compl | Shape | Coher |
|--------|-----------|----------------|------------|------------|--------------|--------|---------|----------|-------|-------|-------|
| `etoro_kpi_prep` | 53 | 21 | 0 | 32 | 7.35 | 8.7 | 9.0 | 6.9 | 3.9 | 2.9 | 6.8 |
| **TOTAL** | **53** | **21** | **0** | **32** | **7.35** | **8.7** | **9.0** | **6.9** | **3.9** | **2.9** | **6.8** |

### Final-FAIL objects

| Schema | Object | Weighted score | First-line feedback |
|--------|--------|----------------|---------------------|
| `etoro_kpi_prep` | `gold_de_user_dim_ddr_customer_dailystatus_scd` | 0.00 | all 38 columns unclassifiable |
| `etoro_kpi_prep` | `v_ddr_revenues` | 6.10 | upstream wiki missing: main.etoro_kpi_prep.v_revenue_stakingfee |
| `etoro_kpi_prep` | `v_dim_dataplatform_uuid` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_dim_ftdplatform` | 7.20 | Completeness 4.0/10: 5/10 structural checks pass; failing: ['required section headers present', 'every element has tier  |
| `etoro_kpi_prep` | `v_globalftdplatform` | 7.20 | Completeness 4.0/10: 5/10 structural checks pass; failing: ['required section headers present', 'every element has tier  |
| `etoro_kpi_prep` | `v_mimo_allplatforms` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_mimo_emoneyplatform` | 6.85 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_mimo_first_deposit_all_platforms` | 7.15 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_moneyfarm_aum` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_moneyfarm_fees` | 6.45 | all 5 columns unclassifiable |
| `etoro_kpi_prep` | `v_moneyfarm_mimo` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_options_aum` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_population_active_traders` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_population_active_traders_lite` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_population_balance_only_accounts` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_population_first_time_funded` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_population_first_trading_action` | 6.85 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_population_funded` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_population_otd_daterange` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_population_portfolio_only` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_revenue_adminfee` | 7.35 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_revenue_cashoutfee_excluderedeem` | 7.35 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_revenue_cashoutfee_incredeem` | 7.35 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_revenue_conversionfee` | 7.25 | Completeness 4.0/10: 5/10 structural checks pass; failing: ['required section headers present', 'every element has tier  |
| `etoro_kpi_prep` | `v_revenue_cryptotofiat_c2f` | 7.15 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_revenue_dividend` | 7.35 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_revenue_interestfee` | 7.35 | Completeness 4.0/10: 5/10 structural checks pass; failing: ['required section headers present', 'every element has tier  |
| `etoro_kpi_prep` | `v_revenue_rollover` | 7.25 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_revenue_spotadjustfee` | 7.25 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_revenue_ticketfee_fixed` | 6.45 | all 6 columns unclassifiable |
| `etoro_kpi_prep` | `v_revenue_transfercoinfee` | 7.35 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |
| `etoro_kpi_prep` | `v_spaceship_mimo` | 7.20 | Completeness 4.0/10: 6/10 structural checks pass; failing: ['required section headers present', 'frontmatter has object_ |

## Errors

_(none)_

---
_Generated by `tools/uc_pipelines/write_audit_summary.py` at 2026-05-18T08:53:10Z._
