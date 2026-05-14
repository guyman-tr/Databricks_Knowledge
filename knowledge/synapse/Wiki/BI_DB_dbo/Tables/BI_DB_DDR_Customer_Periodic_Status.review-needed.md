# BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status — Review Sidecar

## Tier 4 [UNVERIFIED] Columns
| Column | Issue |
|---|---|
| `Portfolio_Only_ThisYear` | SP outer SELECT predicates reference `ActiveTraded_ThisQuarter` — confirm intent vs MONTH/QUARTER. |
| `BalanceOnlyAccount_ThisYear` | Same `ActiveTraded_ThisQuarter` suspect reference for YEAR bucket. |

## Open Questions
- **131 vs 128 column gap analyses:** LIVE Synapse + SSDT DDL both register **128** physical columns (2026-05-14). Earlier “131 columns” KPI likely miscounted ingestion-only UC metadata (`etr_*`).
- **PII UC twin:** SHOW TABLES returned no matching `main.pii_data.*ddr*periodic*` table (MCP probe as of pipeline run). Needs catalog confirmation if HIPAA-style exports duplicate hash.
- **Portfolio/Balance YEAR bug remediation:** Decide whether YEAR block should reuse `ActiveTraded_ThisYear`/`Portfolio_Only_ThisQuarter` interplay like MONTH/QUARTER.

## Soft-phase fails
- Phase 3 distribution stats skipped (narrow permission on `sys.dm_pdw_nodes_db_partition_stats`).
- Phase 10 Atlassian search not executed inside subagent harness (no stakeholder URLs captured).

## Corrections backlog
- Reconcile marketing copy row-count (historic `12.7B`) vs refreshed sampling once Ops grants DMV reads.
