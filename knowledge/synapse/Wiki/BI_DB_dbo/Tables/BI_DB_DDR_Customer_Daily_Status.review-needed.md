# BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status — Review Needed

_Last updated: 2026-05-14_

Sidecar checklist (not wiki content): capture SME sign-off gaps and validation debt.

---

## Tier 4 / Verification Queue

| Item | Column / Area | Why |
|------|---------------|-----|
| T4-01 | `#basicStatuses.LEFT JOIN #fsc` NULL snapshot behavior | Analysts observed NULL regulations for edge population members — acceptable? |
| T4-02 | DECIMAL vs INT on `CountryID`, `MifidCategorizationID`, `Portfolio_Only` | Need formal rationale for CCI / lake export typing vs `Fact_SnapshotCustomer` ints |
| T4-03 | `#globalDepositorsAlltime` “deprecated schema scaffolding” branch | Maintained for parity — confirm downstream BI still aligns with MIN/CASE semantics |
| T4-04 | Portfolio_Only DECIMAL magnitude meaning | Confirm whether nonzero values are strictly `0`/`1` or carry equity-derived magnitudes upstream |

---

## Phase 16 — Adversarial Evaluation (experiment)

_Scorer persona: skeptic comparing wiki + lineage to SP DDL + MCP samples._

| Dimension | Score (1–10) | Brief rationale |
|-----------|--------------|----------------|
| Tier accuracy | 7.5 | No mislabeled Tier‑1 upstream where none existed; inherits `Fact_SnapshotCustomer` Tier‑2 tagging correctly but TVF internals not fully unwrapped |
| Structural adherence | 8.5 | 8 numbered sections present; parity 64; tier suffix enforced; lineage precedes wiki |
| Upstream fidelity | 7.8 | Stewardship corrections on **`IsValidCustomer` / analytic `IsValidUser`** diverge literal `Dim_Customer` §4.5 prose — intentional per stakeholder rule but increases cross-wiki contradiction risk |
| SP fidelity | 8.8 | Mirrors DELETE/INSERT, RN dedup, MIMO coercion blocks, `#fsc` join |
| Risk / misuse guardrails | 9.0 | Explicit “not prefiltered” + CB vs standard analytics distinction |
| **Weighted composite** | **8.25** | PASS ≥7.5 for batch continuation |

Detailed flags:
- ✅ `IsCreditReportValidCB` / `IsValidCustomer` stewardship text matches stakeholder mandate.
- ⚠️ `Fact_SnapshotCustomer` canon still states `PlayerLevelID <> 4` “not demo”; DDR wiki now states **PI validity** separately — reconcile upstream Fact wiki in a coordinated edit or add cross-link footnote future work.
- ⚠️ PHASE 3 distribution depth was **SOFT/not exhaustively MCP’d** beyond row counts — element text leans structural + SP-backed.

---

## Open Questions for DA / Steward

1. **UC masking split**: Confirm whether a **masked vs PII sibling** catalog entry is intentionally absent (`SHOW TABLES IN main.pii_data` returned none for `*customer_daily_status*`). Single gold table suggests **non-PII** narrow export — approve wording?
2. **Ops priority truth**: Periodic wiki cites priority **99** for daily vs **100** periodic — verify against **OpsDB** (`user-opsdb_sql`) for current Service Broker ordering.
3. **PlayerLevelID semantics vs PI**: Clarify canonical mapping between **Popular Investor** program status and **`PlayerLevelID` numeric** to retire contradictory Dim vs DDR phrasing.

---

## Soft Fails (non-blocking)

- Synapse MCP **forward DateID** (`20260501`) returned **0 rows** while UC already included `20260513` — environment / replica skew; document as soft evidence gap, not table defect.
- Atlassian search **did not** return a page explicitly titled `BI_DB_DDR_Customer_Daily_Status`; linked nearest DDR / MIMO / CB context pages instead.
- **Partition metadata** for UC table left as “not verified” — run `DESCRIBE DETAIL` if governance template requires exact partition keys.

---

## Validation Debt

- [ ] `validate-wiki.ps1` — **BLOCKED in this Windows session** (`ParserError` inside the script around the wiki-vs-ALTER parity message — appears to be a **script encoding / PowerShell 5.x parse** issue, not the markdown file). Retry after repairing `.cursor/scripts/validate-wiki.ps1` or run from PowerShell 7.
- [x] `validate-tier1-coverage.ps1` — **PASS** (reports `DWH columns: 64 (T1=0, T2=63)` with zero matchable upstream wiki columns).

---

## Post-Review Correction Log

(none)
