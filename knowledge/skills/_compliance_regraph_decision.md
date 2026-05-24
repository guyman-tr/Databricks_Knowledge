# D Build — Decision Gate: Fold Confluence Into Partition?

_Per spec 011 Phase A.5b decision gate. Audit trail for the choice made between additive-overlay and full re-cluster after the Confluence corpus crawl produced new edges._

## The question

Phase A.5b emitted **64 new edges** across **16 distinct nodes** sourced from 11 stability-thresholded Confluence pages (see `_compliance_confluence_corpus.md`). Several of these nodes — notably the `RiskClassification.*`, `RiskCalculation.*`, `Dictionary.CySecRiskClassificationParameter`, and `BackOffice.SetRiskClassificationNew` — are the production AML risk-classification stack and were either absent or under-weighted in the existing Louvain partition (built only on wiki + tableau + genie + kpi edges in spec 007).

Two options:

| Option | What it means | Cost | Risk |
|---|---|---|---|
| **A. Additive overlay** | Treat the Confluence edges as a scope-extension layer applied on top of the existing partition for THIS domain build only. Do not regenerate `_node_clusters.csv`, `_node_summary.csv`, `_CHECKPOINT_A.md`. Future domain builds will re-run their own crawl and apply their own overlay. | low | none — existing 5 deployed domains are untouched |
| **B. Full re-cluster** | Add Confluence as a 5th edge source in `merge_graph.py` (weight ~1.2 to match Tier 3 of the Authority Hierarchy), regenerate the merged graph, re-run Louvain, refresh `_CHECKPOINT_A.md` and every domain's subgraph profile. | high | affects all 5 already-deployed domains — potential boundary shifts could re-shape Payments, Trading, Customer, Revenue, Cross. Requires re-validation of those 5 skills. |

## Verdict: A. Additive overlay

**Reasoning** (per Authority Hierarchy `knowledge/skills/_AUTHORITY_HIERARCHY.md`):

1. **The Confluence nodes are net-new for D, not boundary-shifters for B/C/E.** All 16 surfaced nodes are in the AML scoring stack (`RiskClassification.*`, `BackOffice.SetRiskClassificationNew`, etc.). None are deposits, trading, marketing, or other B-side concepts. Adding them as D scope cannot move other domains' borders because those domains don't claim these nodes.
2. **Stability of deployed skills > completeness of new build.** The 5 deployed super-domains have been live and consumed by the agent for weeks. Re-clustering would force re-validation of all 5, which is out of scope for spec 011 (build domain D).
3. **The pipeline supports per-domain crawls.** `extract_confluence_edges.py` now writes per-domain output (`_<domain>_confluence_edges.csv`) so each future domain build does its own corpus crawl + overlay. The Confluence edge weight (1.2) and merge-graph integration can be added incrementally per spec 012, 013, etc., before any global re-cluster.
4. **The Phase A.3 partition is already complete enough for v1.** `_compliance_subgraph.md` already shows clusters 21+24+35+53 plus the Genie-widened nodes (`cmp_aml_risk_classification_*`). The Confluence overlay adds the upstream production tables (`RiskClassification.*`, `BackOffice.*`) — exactly the production parents of those `cmp_aml_*` tables.

## Operational consequence

The D build proceeds with:
- **Louvain partition** from Phase A.3 (`_compliance_subgraph.md`, 36 nodes, 4 primary clusters)
- **Genie/KPI seeds** from Phase A.0 (`_compliance_production_anchors.md`, 12 Tier 1 + 14 Tier 2)
- **Tableau fly-over** discovery from Phase A.4 (`BI_DB_RiskAlertManagementTool`)
- **Confluence overlay** from Phase A.5b (16 nodes, 64 edges):
  - `BackOffice.Customer`, `BackOffice.SetRiskClassificationNew`, `BackOffice.CustomerAllTimeAggregatedData`
  - `Customer.CustomerStatic`, `Customer.ExtendedUserField`
  - `Dictionary.CySecRiskClassificationParameter`
  - `History.Customer`, `History.CustomerAnswer`
  - `RiskCalculation.CySecScoresTemporary`, `RiskCalculation.ScoresTemporary`, `RiskCalculation.SetRiskClassificationForCySec`
  - `RiskClassification.CySecRiskClassificationParameter`, `RiskClassification.CySecRiskClassificationParameterView`
  - `dbo.P_RiskClassification`, `dbo.V_RiskClassificationDataLake`
  - `general.bronze_etoro_dictionary_riskclassification` (UC ref correctly normalized through `UC_CATALOGS` allowlist)

Phase B (partition shape decision) and Phase C (SKILL.md authoring) operate on the **union** of these four sources. The Confluence overlay edges are recorded in `knowledge/skills/_compliance_confluence_edges.csv` and the corpus audit trail in `_compliance_confluence_corpus.md`.

## Future work (out of spec 011 scope)

- **Spec 012+ (next domain build)**: same overlay approach.
- **Spec 014 (proposed)**: after 3-4 more domains have applied per-domain Confluence overlays, do a single global re-cluster with Confluence as a 5th edge source. At that point the overlays become absorbed into the canonical partition and `_CHECKPOINT_A.md` refreshes.
- **Authority Hierarchy in `merge_graph.py`**: when global re-cluster happens, Confluence edges should be weighted by their `stability_score` column — Tier 3 canonical edges (score ≥ 0.6) get weight 1.2, Tier 5 non-canonical (if explicitly included) get weight 0.5.
