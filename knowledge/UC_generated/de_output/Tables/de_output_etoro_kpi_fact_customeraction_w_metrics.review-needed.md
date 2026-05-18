---
object: main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
schema: de_output
framework: uc-pipeline-doc
sidecar_kind: review-needed
generated_at: 2026-05-17T18:30:00Z
---

# Review needed — de_output_etoro_kpi_fact_customeraction_w_metrics

> Lightweight checklist of open questions, missing evidence, and inherited risks
> for this materialized table. The full wiki lives in
> `de_output_etoro_kpi_fact_customeraction_w_metrics.md`. Items here either need
> a domain expert / engineer to resolve, or are inherited unresolved items from
> the upstream view's sidecar. Mark items complete by deleting their row + bumping
> the wiki date.

---

## 1. Source code not snapshottable (HIGH priority)

**Status**: Phase 2 (`fetch_writer_source.py`) returned `WRITER_FOUND_BUT_NO_SOURCE_FETCHED`.

**Evidence**: `_discovery/source_code/_fetch_manifest.json` reports:
- Primary writer: JOB id `712655402982749` (60 events in last 90d), `fetch_error: "job has no notebook tasks"`.
- Secondary writers: 3 DBSQL queries (`0e24356b-…`, `1233bc96-…`, `68a459bd-…`) with low event counts (4, 2, 2).

**Why it matters**: without source we cannot independently verify:
- The actual write strategy (`INSERT OVERWRITE` vs `MERGE INTO ... USING (...)` vs DLT `@dlt.table`).
- Any per-row business logic the JOB applies BEFORE writing (currently inferred to be `SELECT *` + `current_timestamp() AS UpdateDate` — based on the 1:1 column lineage match, but not proven).
- Schema-drift handling: how does the JOB react if the upstream view adds a column? Does it fail fast or silently drop?

**Suggested actions**:
1. Pull the JOB definition via `databricks jobs get 712655402982749` and inspect its `tasks` array. Look for `python_wheel_task`, `spark_jar_task`, `sql_task`, or `pipeline_task`. Snapshot the inferred SQL / wheel entrypoint to `_discovery/source_code/de_output_etoro_kpi_fact_customeraction_w_metrics.{sql,py}` and re-run Phase 4 to validate.
2. If the JOB is a Python wheel or JAR, locate the project repo (likely `data-platform-de_output-etoro_kpi` or similar) and pin the wheel version → commit hash.
3. Re-run `fetch_writer_source.py` with elevated auth (Workspace API needs `workspace.read` on `/Workspace/Jobs/...` paths).

## 2. Refresh cadence and write strategy — INFERRED, not verified

**Status**: Section 2 of the wiki infers daily MERGE based on event counts. This is **inference, not fact**.

**Evidence**:
- 60 production-JOB events in 90 days ≈ daily cadence.
- 9.1B rows on a daily full overwrite would be cost-prohibitive → MERGE is the economic default.
- Per-row `UpdateDate` distribution would confirm: if `SELECT MIN(UpdateDate), MAX(UpdateDate) FROM ...` shows a wide spread (months), it's a MERGE; if every row has the same UpdateDate (today), it's an OVERWRITE.

**Suggested action**: run the verification query in §2 of the wiki:
```sql
SELECT date_trunc('day', UpdateDate) AS update_day, COUNT(*)
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
GROUP BY 1 ORDER BY 1 DESC LIMIT 30;
```
If >1 day shows up: MERGE confirmed. If only 1 day: OVERWRITE confirmed. Update wiki §2 accordingly and remove this item.

## 3. Inherited from upstream — open issues

These items propagate from `v_fact_customeraction_w_metrics.review-needed.md` and will resolve here automatically once the upstream sidecar is closed out. Listed for completeness so anyone reading this sidecar sees the full risk surface.

### 3.1 `ShareLendingFeeEtoroShare` vs `ShareLendingFeeUserShare` — IDENTICAL EXPRESSIONS
Both columns are `CASE WHEN ActionTypeID=36 AND CompensationReasonID=119 THEN Amount ELSE 0 END`. The view does NOT split eToro vs user share. Same data in two columns. **Question for the share-lending product owner**: should one of these be `Amount * <eToroShare%>` and the other `Amount * <UserShare%>`? Currently downstream consumers will double-count if they `SUM(EtoroShare + UserShare)`.

### 3.2 `ShareLendingFeeBrokerShare` arithmetic — convoluted but correct
`Amount / ROUND(0.425, 1) - 2 * Amount` simplifies to `0.5 * Amount` because `ROUND(0.425, 1) = 0.4`. The parameterized form preserves a 0.425 split intent that the rounding collapses. **Question**: is the intent `Amount * (1/0.425 - 2) = Amount * 0.353` (i.e. should `ROUND(0.425, 2)` give 0.43 with 2 decimals)? If yes, the current `ROUND(_, 1)` is a bug. Confirm with finance.

### 3.3 `CashoutFeeExludingRedeem` — preserved misspelling
Column name has "Exluding" instead of "Excluding". **Decision**: keep as-is (downstream queries reference this exact name) or rename and add a backward-compatible view? Logged here so future renamers see the trade-off.

### 3.4 Upstream wiki tier_breakdown mismatch
The upstream wiki's frontmatter declares `tier1_columns: 30, tier2_columns: 53, tier3_columns: 4, tier5_columns: 10` BUT the actual `(Tier N — …)` tag count over the 97 rows of the Elements table is `T1=28, T2=65, T3=1, T5=3`. The actual tag counts are the ones inherited into this de_output wiki (`28 T1, 66 T2, 1 T3, 3 T5` after adding `UpdateDate` as T2). Discrepancy is in the upstream wiki, not here. **Suggested action**: fix the upstream wiki frontmatter to match the element table.

## 4. Inherited from `v_fact_customeraction_enriched` (grand-upstream)

### 4.1 `IsRecurring` depends on `dim_position.OrderID` resolution
If a recurring-investment plan's `OrderID` doesn't resolve to a `dim_position` row, `IsRecurring` will be 0 even when the customer IS on a plan. Materialized here verbatim → same risk surface.

### 4.2 `BI_DB_DepositWithdrawFee` JOIN cost is upstream's problem
Now materialized into the table — so query consumers don't pay it per-query. This is the **win** of the materialization. Sidecar note: ensure the JOB has enough wall-clock budget; if the upstream `BI_DB_DepositWithdrawFee` ever explodes in row count, the JOB's MERGE step is the bottleneck.

## 5. Cross-check vs `system.access.column_lineage`

- All 98 UC columns have exactly one lineage entry per source pattern:
  - **97 columns**: single source `main.etoro_kpi_prep.v_fact_customeraction_w_metrics.<same_name>`. Mismatches: **0**.
  - **1 column** (`UpdateDate`): source NULL. Confirmed writer-stamped.
- No ambiguous columns, no missing lineage. The runtime cache is unusually clean for this object.

## 6. Downstream consumers — UNKNOWN

Phase 0 of this pack tags this as a terminal object in our DAG, but we haven't enumerated who actually queries it. **Suggested action**: query `system.access.query_history` for the last 30 days filtered to this table name and bucket by user / warehouse. The output should land in Section 5.1 of the wiki as "top consumers" (currently absent).

## 7. Storage-level metadata not pulled

This wiki documents the logical schema and lineage. It does NOT document:
- Partitioning scheme (`SHOW PARTITIONS main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`).
- Z-ORDER columns (`DESCRIBE EXTENDED ...`).
- Optimization cadence (`DESCRIBE HISTORY ...` for OPTIMIZE / VACUUM events).
- Data freshness SLO and PII / DLP classification.

**Suggested action**: a separate Phase 7-style "operational metadata" pass would round this out. Out of scope for the current SDD framework v1.

---

*Items 1, 2, 3.4, 6, 7 are this-object-specific. Items 3.1–3.3 and 4 inherit from upstream wikis and resolve there.*
