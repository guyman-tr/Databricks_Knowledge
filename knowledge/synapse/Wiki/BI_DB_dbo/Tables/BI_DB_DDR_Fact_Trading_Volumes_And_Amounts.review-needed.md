# Review needed — BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts

Lightweight QA sidecar (**not** wiki). Generated **2026-05-14**.

---

## Tier 5 corrections logged

| Column | Tier 5 Correction | Was Based On | New Tier | Change Summary |
|--------|-------------------|--------------|----------|----------------|
| **IsSQF** | SpotQuotedFuture (smaller-contract RealFutures on CME); **GroupID = 59** via `Trade.InstrumentGroups` / `Function_Instrument_Snapshot_Enriched` | Tier 2 narrative — **“Sustainable & Quality-Focused instrument flag”** (fabricated) | Tier 5 (user expert correction 2026-05-14) | Replaced fabricated narrative with grounded product semantic |

---

## Open questions

1. **`IsAirDrop`** — MCP sample rows show **`NULL`** in `TOP 10` (`DateID≥20260101`); confirm intended outer-join sentinel vs ingestion gap.  
2. **UC partitioning** — property row left reconcile note; **`SHOW TBLPROPERTIES`** on gold table for authoritative `etr_*` columns.  
3. **Downstream consumers** — `sys.sql_expression_dependencies` returned **0** references; enumerate Genie / Notebook dependencies outside SQL module graph.  
4. **`BI_DB_VolumeQA`** row-count reconciliation — SP comment cites “bizarre data loss” investigations; align QA playbook with stakeholder ticket (if exists — not found in scoped Confluence query).

---

## Soft fails / evidence gaps

| Item | Severity | Detail |
|------|----------|--------|
| Confluence specificity | SOFT | No page titled/placed BI_DB_ddr_tv&a lineage; broader volume docs only. |
| View dependency catalogue | SOFT | Zero rows from `sys.sql_expression_dependencies` for this fact (may under-report). |

---

## PII checklist (surrogate posture)

| Column | Verdict |
|--------|---------|
| `RealCID` | **Customer surrogate** — join amplification risk to PII-bearing dims; classify governance as **Indirect identifier** |

No email, phone, postal address, or free-text biography columns on fact DDL.
