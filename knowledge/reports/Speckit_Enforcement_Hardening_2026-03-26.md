# Speckit Enforcement Hardening Report

**Date:** 26 March 2026
**Scope:** Harden the DWH semantic documentation speckit against agent drift in long batch sessions
**Target:** `.cursor/rules/dwh-semantic-doc/` and `.cursor/rules/semantic-layer-core/`
**Prepared by:** Data Platform team (Cursor agent-assisted implementation)

---

## 1. Problem Statement

During long agentic batch sessions (10+ objects per batch), the agent drifts from speckit rules:
- Skipping phases without notice
- Producing incomplete tier suffixes on column descriptions
- Omitting dictionary values from descriptions
- Writing wiki content into `.review-needed.md` (wrong file)
- Failing to read upstream wikis despite Phase 10A being mandatory

Root cause: not context fatigue from rule loading (agent-requestable rules are already on-demand), but the **absence of structured enforcement checkpoints** that force the agent to self-verify before moving on.

---

## 2. Architecture: Three-Layer Enforcement

```
Layer 1 — CONTRACT (top of each phase file)
  Sets expectations BEFORE execution.
  Structured table: inputs required, outputs required, MUST NOT, failure mode (HARD/SOFT).

Layer 2 — CHECKPOINT (bottom of each phase file)
  Verifies AFTER execution.
  Structured checklist with [ ] boxes and a PHASE {N} CHECKPOINT: PASS/FAIL marker.

Layer 3 — GATE (cross-cutting, always loaded)
  Verifies ALL checkpoints before Phase 11 generates docs.
  Refuses to proceed if any HARD checkpoint is missing or failed.
```

---

## 3. Changes Made

### 3.1 Bookends Applied to 13 Phase Files

Every phase rule file now has a CONTRACT block (after frontmatter + title) and a CHECKPOINT block (at the end).

| File | Phase | Failure Mode | Key Contract Constraints |
|------|-------|-------------|------------------------|
| `01-structure-analysis.mdc` | P1 | HARD | Must read DDL from SSDT repo, not MCP |
| `02-live-data-sampling.mdc` | P2 | HARD | Must obtain core sample; emit PHASE 2 GATE marker |
| `03-distribution-analysis.mdc` | P3 | SOFT | Must not drop upstream enum values |
| `04-lookup-resolution.mdc` | P4 | SOFT | Must check glossary first (Tier 5); repo before MCP |
| `05-join-analysis.mdc` | P5 | SOFT | Must search repo before sys.sql_modules |
| `06-business-logic-discovery.mdc` | P6 | SOFT | Must not fabricate concepts without evidence |
| `07-view-dependency-scan.mdc` | P7 | SOFT | Must check nested view chains |
| `08-procedure-reference-scan.mdc` | P8 | HARD | Must consume Phase 2 ETL results, not re-discover |
| `09-procedure-logic-extraction.mdc` | P9 | HARD | Must apply alias-level attribution; read 10+ reader SPs |
| `09b-etl-orchestration-analysis.mdc` | P9B | SOFT | Must check static JSON files before OpsDB MCP |
| `10-atlassian-knowledge-scan.mdc` | P10 | SOFT | Must validate against code evidence (code is king) |
| `10.5b-tier1-enforcement.mdc` | P10.5b | HARD | Zero Tier 1 with rich upstream wiki = delete and redo |
| `13-production-lineage-mapping.mdc` | P10A + P10B | HARD (both) | Must trace through external tables; write .lineage.md BEFORE .md |

### 3.2 Golden Reference Created

**New file:** `.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`

Based on `Dim_Mirror.md` (quality 9.0/10, 314 lines, 19 Tier 1 + 7 Tier 2 columns).

| Section | Content |
|---------|---------|
| **A. Annotated Skeleton** | Condensed structural skeleton showing the SHAPE of a perfect wiki — all 8 sections with annotations |
| **B. Quality Assertions** | 13 machine-checkable assertions (HARD/SOFT) the agent verifies before writing |
| **C. Dictionary Inline Values Rule** | <=15 values: inline key=value pairs; >15 values: name join target only; document both prod and DWH names when they differ |
| **D. Anti-Patterns** | 5 concrete examples of BAD output: missing tier suffix, vague business meaning, wrong file, missing columns, ETL without detail |

### 3.3 GATE-wiki-generation.mdc Updated

| Change | Detail |
|--------|--------|
| Mandatory reads | Added `GOLDEN-REFERENCE.mdc` as item 6 (was 5 items, now 6) |
| Checkpoint chain verification | New section: verifies all HARD phases (P1, P2, P8, P9, P10A, P10B) emitted PASS before Phase 11 |
| Shape comparison | New section: agent compares output against golden skeleton before writing to disk |

### 3.4 Phase 11 (11-generate-documentation.mdc) Updated

| Change | Detail |
|--------|--------|
| Pre-Read: Golden Reference | New mandatory step before upstream wiki read |
| Dictionary inline values rule | Added to Elements table generation section — <=15 values inline, >15 join target only |
| Post-write shape check | Added as item 8 in validation gate — all HARD assertions from golden reference |

### 3.5 Execution Card (00-execution-card.mdc) Updated

| Change | Detail |
|--------|--------|
| Pipeline table | Added `Checkpoint` column showing expected checkpoint output per phase |
| Hard enforcement reminders | Added: "CHECKPOINT markers are not optional" and "GOLDEN REFERENCE must be read once per batch" |

### 3.6 Batch Orchestration (batch-orchestration.mdc) Updated

| Change | Detail |
|--------|--------|
| Per-object checkpoint chain | Added verification note alongside phase gate checklist |
| Done condition | Objects may ONLY be marked Done if all HARD checkpoints show PASS + both validations passed + shape check passed |

---

## 4. Dictionary Inline Values Rule

| Dictionary Size | Rule | Example |
|----------------|------|---------|
| **<=15 distinct values** | Inline key=value pairs in description | `1=Regular, 2=CopyMe, 3=Social Index, 4=Fund (Dictionary.MirrorType)` |
| **>15 distinct values** | Name join target only | `FK to Dim_Country. Resolves to country name.` |

**Threshold rationale:** 15 values fit in ~200 characters. Beyond that, inline enumeration hurts readability.

**Naming convention:** When production Dictionary name differs from DWH Dim name, document BOTH:
- Production: `Dictionary.MirrorType` (lineage traceability)
- DWH: `Dim_MirrorType` (query use)

---

## 5. Files Modified (Summary)

| # | File | Action |
|---|------|--------|
| 1 | `.cursor/rules/dwh-semantic-doc/01-structure-analysis.mdc` | +CONTRACT +CHECKPOINT |
| 2 | `.cursor/rules/dwh-semantic-doc/02-live-data-sampling.mdc` | +CONTRACT +CHECKPOINT |
| 3 | `.cursor/rules/dwh-semantic-doc/03-distribution-analysis.mdc` | +CONTRACT +CHECKPOINT |
| 4 | `.cursor/rules/dwh-semantic-doc/04-lookup-resolution.mdc` | +CONTRACT +CHECKPOINT |
| 5 | `.cursor/rules/dwh-semantic-doc/05-join-analysis.mdc` | +CONTRACT +CHECKPOINT |
| 6 | `.cursor/rules/dwh-semantic-doc/06-business-logic-discovery.mdc` | +CONTRACT +CHECKPOINT |
| 7 | `.cursor/rules/dwh-semantic-doc/07-view-dependency-scan.mdc` | +CONTRACT +CHECKPOINT |
| 8 | `.cursor/rules/dwh-semantic-doc/08-procedure-reference-scan.mdc` | +CONTRACT +CHECKPOINT |
| 9 | `.cursor/rules/dwh-semantic-doc/09-procedure-logic-extraction.mdc` | +CONTRACT +CHECKPOINT |
| 10 | `.cursor/rules/dwh-semantic-doc/09b-etl-orchestration-analysis.mdc` | +CONTRACT +CHECKPOINT |
| 11 | `.cursor/rules/dwh-semantic-doc/10-atlassian-knowledge-scan.mdc` | +CONTRACT +CHECKPOINT |
| 12 | `.cursor/rules/dwh-semantic-doc/10.5b-tier1-enforcement.mdc` | +CONTRACT +CHECKPOINT |
| 13 | `.cursor/rules/dwh-semantic-doc/13-production-lineage-mapping.mdc` | +CONTRACT (x2) +CHECKPOINT (x2) |
| 14 | `.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc` | **NEW FILE** |
| 15 | `.cursor/rules/dwh-semantic-doc/GATE-wiki-generation.mdc` | +golden ref +checkpoint chain +shape check |
| 16 | `.cursor/rules/dwh-semantic-doc/11-generate-documentation.mdc` | +golden ref pre-read +dict rule +shape check |
| 17 | `.cursor/rules/dwh-semantic-doc/00-execution-card.mdc` | +checkpoint column +enforcement reminders |
| 18 | `.cursor/rules/semantic-layer-core/batch-orchestration.mdc` | +checkpoint validation +Done conditions |

**Total: 17 files modified + 1 new file = 18 files touched.**

---

## 6. Context Pressure Analysis

Each CONTRACT/CHECKPOINT block adds ~15-20 lines per file. Since these files are agent-requestable (not `alwaysApply`), only the phase currently executing is loaded. Net context increase per loaded phase: ~15-20 lines — negligible compared to the enforcement value.

The `GOLDEN-REFERENCE.mdc` file adds ~150 lines but is only read once per batch (during Phase 11 pre-read), not loaded for every phase.

The two `alwaysApply` gates (`GATE-wiki-generation.mdc` and `GATE-lineage-contract.mdc`) grew by ~40 lines combined. These are always in context but the additions are structured tables, not prose.

---

## 7. Expected Impact

| Drift Pattern | Enforcement Mechanism |
|--------------|----------------------|
| Skipping phases | CHECKPOINT markers required; GATE verifies chain before P11 |
| Missing tier suffix | Golden reference assertion B2 (HARD); validate-wiki.ps1 |
| Vague descriptions | Anti-pattern D2; Rule 20 formula check in P11 validation |
| Wrong file (wiki in sidecar) | Anti-pattern D3; file identity check in GATE |
| No upstream wiki read | Phase 10A CONTRACT (HARD when source known); Tier 1 coverage validation |
| Dictionary values omitted | Section C rule in golden reference + P11 Elements generation |
| ETL pipeline missing | Golden reference assertion B7 (HARD) |

---

*Generated: 2026-03-26 | Conversation: Speckit Enforcement Hardening*
