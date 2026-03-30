# Deployment Report: DWH_dbo.Dim_AccountStatus

> Generated: 2026-03-30 | Pipeline: dwh-semantic-doc (15-phase)

## 1. Object Summary

| Property | Value |
|----------|-------|
| **Synapse Object** | `DWH_dbo.Dim_AccountStatus` |
| **Object Type** | Table |
| **UC Primary Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` |
| **Columns Documented** | 5 |
| **Quality Score** | 7.6/10 (4 stars) |
| **Tier Breakdown** | 2 T1, 3 T2, 0 T3, 0 T4, 0 T5 |
| **Review Items** | 0 Tier 4 + 0 clarification + 2 structural questions (sidecar) |

## 2. Output Files

| File | Status | Description |
|------|--------|-------------|
| `Dim_AccountStatus.md` | EXISTS | Wiki documentation |
| `Dim_AccountStatus.review-needed.md` | EXISTS | Review sidecar |
| `Dim_AccountStatus.alter.sql` | UPDATED | Main ALTER script (12 statements); `LAST EXECUTION` footer appended |
| `Dim_AccountStatus.downstream.alter.sql` | N/A | Downstream propagation is a separate command |
| `Dim_AccountStatus.deploy-report.md` | WRITTEN | This file |

## 3. Main ALTER Execution

| Component | Succeeded | Total | Status |
|-----------|-----------|-------|--------|
| Table comment | 1 | 1 | OK |
| Table tags | 1 | 1 | OK |
| Column comments | 5 | 5 | OK |
| PII tags | 5 | 5 | OK |
| **Total** | **12** | **12** | **OK** |

**Pre-check**: `DESCRIBE TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` succeeded.

**Execution**: Single `databricks.sql.connect()` session (`bi-sql-warehouse-customer`), OAuth `guyman` profile.

## 4. Downstream Objects (Deep Lineage)

Not run. Self-only deploy (`propagate-downstream-dwh` is separate).

## 5. Failures

No failures. All 12 statements executed successfully.

## 6. Phases Completed

| Phase | Status | Notes |
|-------|--------|-------|
| 1–14 (wiki pipeline) | DONE (per wiki footer) | Simple-dict fast-path; not all phases run |
| UC deploy (this run) | DONE | 2026-03-30 |

## Notes

- **`_deploy-index.md`**: Created at `knowledge/synapse/Wiki/DWH_dbo/_deploy-index.md` (130 deployable objects; `Dim_AccountStatus` = Deployed). Regenerate with `python tools/build_deploy_index_dwh_dbo.py` after bulk generate/deploy.

## Protocol 6 — deploy summary

| Item | Value |
|------|-------|
| **Schema** | DWH_dbo |
| **Object** | Dim_AccountStatus |
| **`_deploy-index.md`** | **Present** — see repo root `DWH_dbo/_deploy-index.md` |
| **This run** | 12/12 ALTER statements succeeded |
| **Next step** | Deploy remaining `Generated` rows via `/deploy-alter-dwh DWH_dbo resume`; optional `/propagate-downstream-dwh` |
