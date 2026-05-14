# Fact_CustomerAction — SME / Review Needed

_Last updated: 2026-05-14 (full speckit regen)_

## Parity Gate (Wiki ↔ `.alter.sql` — informational)

| Artifact | Distinct populated columns (`Fact_CustomerAction`) |
|-----------|-----------------------------------------------|
| **Synapse `INFORMATION_SCHEMA` (Phase 1)** | **71** |
| **`Fact_CustomerAction.md` Elements** | **71** |
| **Existing `Fact_CustomerAction.alter.sql` COMMENT stubs** | **71** matched target `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (regenerate ALTER separately via `/generate-alter-dwh` after SME sign-off — **NOT modified here**). |
| Historical “106 vs 71” drift rumor | Current Synapse DDL + wiki both **71**; if additional UC-only columns emerge, log them here **before** parity scripts run. |

## Tier 4 / UNSME Items (prioritized)

1. **`IsRedeem` CLOSE-branch exact expression** — `sys.sql_modules.definition` returned **NULL** for `SP_Fact_CustomerAction` (+ `_DL`) on live Synapse; **SSD T clone required** for verbatim CASE parity. Data proof: **`ActionTypeID=8`** redeem rows ⇒ **`FundingTypeID=27`** (transfer-to-coin); **`ActionTypeID∈{4,6,...}` & `IsRedeem=1`** still appear with CFD redeem linkage — unify narrative after SP scrape.
2. **`HistoryID`** — Still duplicate-prone — need authoritative business statement if any micro-service now guarantees uniqueness partitions.
3. **`PlatformID`** + **`CampaignID`** + **`BonusTypeID`** — Tier retained at **domain expert / Tier5** bundles; SMEs confirm whether marketing dictionaries moved.
4. **`MoveMoneyReasonID` low-volume enums** historically `[UNVALIDATED]` in ALTER — rerun dictionary coverage post `Dim_MoveMoneyReason` regen batch.
5. **`IsSettled` vs `SettlementTypeID`** — dual modelling; deprecation schedule unclear (Tier 5 retained).

## Phase Soft-Fail Ledger

| Phase | Reason |
|-------|--------|
| **Phase 9 (full verbatim SP)** | `OBJECT_DEFINITION`/module body unavailable (**NULL**) on warehouse → inferred from sister wikis + live distributions. |
| **Phase 7 (view dependents)** | `sys.sql_expression_dependencies` referencing `Fact_CustomerAction` returned **0** rows — Synapse DMV limitation; curated consumer list truncated to narrative. |
| **Phase 10 (Atlassian crawl)** | No fresh MCP Atlassian scrape this session — Confluence/Jira bullets copied forward as **stale placeholders**. |
| **Phase 3 width** | **`ActionTypeID` TOP‑50**: only **29** distinct IDs in `DateID≥20260101` window — expand date span for dormant codes (`21‑26`, `31`, `33`, …) if QA demands full cardinality deck. |

## UC / Governance Follow-ups

* **Databricks** confirms **single** masked table (`main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`). **No** mirrored `main.pii_data` counterpart located — validate if omission is policy (financial facts) or tooling gap (`SHOW TABLES` 2026-05-14).  
* **`etr_*` partitions** absent in Synapse — analysts hitting UC must prune partitions explicitly.

## Adversarial (Phase 16) — Blocking Follow-ups Before 9+/10 Score

| Finding | Severity | Action |
|---------|----------|--------|
| SP body missing ⇒ **risk of subtle drift vs formula text** | Major | Obtain SSDT excerpt + paste into lineage “Computation Formula” row for **`IsRedeem`**. |
| Dependent-object inventory not DMV-backed | Moderate | Optional OpsDB scrape for callers. |
| Atlassian URLs not refreshed | Low | Tick Confluence crawler job. |

**Provisional score recorded in wiki footer:** **8.0 / 10** (generator self-pass). External adversarial reviewer should rerun after SSDT ingestion.
