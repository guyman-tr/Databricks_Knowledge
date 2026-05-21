# Root-cause analysis: DWH Tier-1 promotion-lie corruption

**Generated**: 2026-05-21 (Phase E `blame_origin` of the cleanup plan).
**Subject**: ~432 Tier-1 column-documentation claims in `knowledge/synapse/Wiki/DWH_dbo/**` that the new L1-structural audit flagged as **promotion lies** — passthrough views claiming `(Tier 1 — …)` for columns whose actual source wiki (`Fact_SnapshotEquity`, `Dim_Customer`, …) is itself Tier 2.

---

## Patient-zero commit

| Hop in the spotcheck | Wiki | First-introduced-in | Date | Author |
|---|---|---|---|---|
| Hop 3 (V_Fact_SnapshotEquity, V_Fact_SnapshotEquity_ForDWHRep, V_Fact_SnapshotEquity_FromDateID) | `knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotEquity*.md` | **`cd9e5671`** | 2026-03-29 12:04:28 UTC | Guy Manova |
| Hop 2 (V_Liabilities) | `knowledge/synapse/Wiki/DWH_dbo/Views/V_Liabilities.md` | `affb5471` (initial), `cd9e5671` (Tier-1 form) | 2026-03 / 2026-03-29 | Guy Manova |

The introducing commit `cd9e5671` is titled **"feat: complete DWH_dbo view re-documentation + BI_DB/Dealing batch fixes"** with body:

> All 21 DWH_dbo views re-documented with full per-column expansion (598 cols).
> Eliminated all See-other-file shortcuts — views are equal citizens.
> **Tier 1 inheritance from upstream wikis (Dim_Customer, Fact_BillingDeposit).**
> New ALTER scripts for BI_DB_dbo (22 objects) and DWH_dbo views.
> …
> Made-with: Cursor

The phrase "Tier 1 inheritance from upstream wikis" in the commit body is precisely the offending generator behaviour.

## Offending generator behaviour

The DWH view generator at the time inherited descriptions from upstream wikis but stamped the inherited rows `(Tier 1 — inherited from <Source> wiki)` instead of verifying the actual tier in the source wiki. When the source row was Tier 2 (e.g. `Fact_SnapshotEquity.Credit` correctly self-tags `(Tier 2 — SP_Fact_SnapshotEquity)`), the view generator silently promoted it to Tier 1, treating the upstream wiki as if it were the source-of-truth.

Concretely, every view row of the form

```
| <n> | <Col> | <SourceTable>.<Col> | <descr-copied-verbatim-from-SourceTable.wiki> | (Tier 1 — inherited from <SourceTable> wiki) |
```

is structurally suspect because Tier 1 is reserved for *true* OLTP / source-of-truth wikis, never for DWH views that merely pass a value through.

The L1-structural audit layer (`tools/tier1_audit/judge.py::layer_1_structural`) implemented for this cleanup pass is what surfaces these rows — it verifies that the resolved source's Tier is also Tier 1; if not, it flags the row.

## How the corruption propagated

Once the patient-zero DWH views shipped, the propagation chain was deterministic:

1. **BI_DB wikis** that pulled from `V_Fact_SnapshotEquity` / `V_Liabilities` saw a `(Tier 1 — …)` row and copy-stamped their own row with a chained tag like `(Tier 1 -- V_Liabilities via Fact_SnapshotEquity)` — the "via" prefix encoding the chain.
2. **UC_generated wikis** (etoro_kpi, bi_output) inherited from BI_DB layer wikis. The generator at `cache_upstream_wikis.py` appended its OWN inheritance tag instead of verifying the upstream one, producing the "double tier 1 stacking" the spotcheck documents at Hop 5 (`cidfirstdates_v.Credit` carrying TWO Tier 1 tags).
3. **UC live column comments** were deployed from each layer's `.alter.sql` files via `uc-deploy-comments` skill. An analyst opening `main.etoro_kpi.cidfirstdates_v` in the Databricks catalog reads the corrupt comment text and trusts it as the official definition.

## Why prior LLM judges missed it

The previous `knowledge/_dwh_llm_judge_cache/*.json` runs were focused on semantic accuracy against Confluence / live data. They did not run a structural check — they would only flag a row if its TEXT was wrong. For passthrough views like Hop 3, the text was a verbatim copy of the (Tier 2) source description, so the judge gave it a PASS even though the tier tag was wrong.

The new L1-structural layer added in this cleanup is what closes that gap.

## What this audit does NOT yet fix

- **Hop 1 narrative drift** at `Fact_SnapshotEquity.Credit` itself: the description introduces the phrase "outstanding credit/bonus balance" that does not exist in the OLTP source (`History.ActiveCredit.Credit`, "running balance after the event"). This is a Tier-2 wording drift, not a Tier-1 promotion lie, and it is the upstream root of the "promotional/bonus credit" hallucination chain.
- **V_Liabilities Hop 2**: the 5-column "Source / Formula / Tier" wiki layout that V_Liabilities uses (instead of an embedded `(Tier N — X)` tag) is invisible to the current Tier-1 parser. This is documented in the spotcheck and is a separate parser-extension task.

## Guardrails delivered in this branch (Phase E)

1. `tools/cleanup_tier1/propagation_map.py` — DAG-driven (not substring), strict
   (source_column, downstream_column) pairing.
2. `tools/tier1_audit/judge.py::layer_1_structural` — the audit layer that
   surfaces all promotion lies upfront.
3. `tools/cleanup_tier1/audit_dag_walk.py` + `audit_queue.py` — topologically
   ordered re-audit harness so the next sweep across BI_DB / Dealing /
   UC_generated runs upstream-first against the now-correct DWH layer.

## Recommended next actions

1. **Patch the wiki generator** so that at write-time it verifies every Tier-1
   tag it emits actually resolves to a Tier-1 source AND the row text matches
   that source text. (See `harden_generator` todo in the cleanup plan.)
2. **Wire `tier1_audit/run_audit*.py --no-llm` into CI** as a fast structural
   gate so future generator regressions are caught at PR time. (See
   `ci_gate` todo.)
3. **Re-run the L0/L1/L2 audit on BI_DB and UC_generated layers** now that the
   DWH layer they inherit from is truth; the Phase D walk is what does that.
4. **Manually fix the Hop-1 Tier-2 wording at `Fact_SnapshotEquity.Credit`**
   via a separate narrative-review pass (it's the root cause of all
   "promotional/bonus credit" hallucinations downstream).
