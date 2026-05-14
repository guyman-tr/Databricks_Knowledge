# Feature Specification: DWH_dbo LLM Judge — Grounded WRONG-only Verdict Pipeline

**Feature Branch**: `008-dwh-judge`
**Created**: 2026-05-13
**Status**: Draft
**Input**: Stand up a grounded LLM judge over DWH_dbo wiki content (descriptions + structured claims) that distinguishes WRONG from SLOPPY, cites verbatim Tier-1 evidence for every flag, and emits a single centralized review CSV. Zero auto-writes — after the codepoint regex corruption incident (where heuristic extraction produced fused artifacts like `7=Diamondsk limits` and `13=Local Cardd reporting` that auto-deployed to UC), the judge only produces evidence. A separate applier runs after the user marks `approve_y_n=Y` in the CSV.

## User Scenarios & Testing

### User Story 1 — Detect Wrong Facts Without Touching Files (Priority: P1)

As a data knowledge engineer, I need to identify every wiki claim that contradicts the live Tier-1 source-of-truth, so that I can fix factual errors before they pollute the Genie vector index. The judge MUST NOT edit any files or deploy any UC change as part of detection.

**Why this priority**: Genie's retrieval is driven by column-description vector search. WRONG descriptions yield WRONG generated SQL. SLOPPY descriptions are forgivable; WRONG ones are not.

**Independent Test**: Run the full judge pipeline against `knowledge/synapse/Wiki/DWH_dbo/` and produce `knowledge/_dwh_judge_review.csv` while git status on all wiki files remains unchanged.

**Acceptance Scenarios**:

1. **Given** a wiki claim like `PlayerLevelID=4 -> Popular Investor` and a live dictionary row `Dim_PlayerLevel.Name='Internal'`, **When** the judge runs, **Then** the row appears in the review CSV with `wiki_value=Popular Investor`, `truth_value=Internal`, `truth_source=DWH_dbo.Dim_PlayerLevel`.
2. **Given** a wiki column description that says `Default=0` while DDL says `default_definition IS NULL`, **When** the deterministic verifier runs, **Then** a row is emitted with `claim_type=default`, full citation pointing to `INFORMATION_SCHEMA.COLUMNS` + `sys.default_constraints`.
3. **Given** a wiki prose description that says "FK to Dictionary.Foo" but no `Foo` exists in DWH_dbo, **When** the deterministic verifier runs, **Then** the row is flagged WRONG with `truth_source=fks.json` (no match).
4. **Given** an LLM prose verdict marked WRONG without a verbatim contradicting quote, **When** the LLM stage writes its CSV, **Then** the row is downgraded to UNVERIFIABLE and excluded from the review CSV.

---

### User Story 2 — Centralized Review Without Per-File Drudgery (Priority: P1)

As a data knowledge engineer, I need a single CSV that lets me scan all WRONG verdicts in spreadsheet form, sort/filter by object/column/claim_type, and approve fixes in bulk by filling a single column.

**Why this priority**: Reviewing one wiki at a time was the bottleneck on previous remediation rounds. A flat CSV lets me sweep through 100–300 verdicts in one sitting.

**Independent Test**: Open `knowledge/_dwh_judge_review.csv` in Excel; every row has the wiki value, the truth value, the citation, the suggested fix, and an empty `approve_y_n` cell.

**Acceptance Scenarios**:

1. **Given** the review CSV, **When** I sort by `severity, claim_type, object, column`, **Then** the highest-impact deterministic violations cluster at the top.
2. **Given** rows with `approve_y_n=Y`, **When** I run the applier, **Then** only those rows are patched.
3. **Given** rows with `approve_y_n` empty or `N`, **When** the applier runs, **Then** they are skipped.

---

### User Story 3 — Verbatim Citations to Block LLM Hallucination (Priority: P1)

As a data knowledge engineer, I need every WRONG verdict to cite the verbatim Tier-1 text that contradicts the wiki, so that I never trust an LLM judgment without ground-truth proof.

**Why this priority**: The codepoint regex corruption was a heuristic that wrote without a verification gate. The LLM stage is even more dangerous if it can hallucinate verdicts. The citation rule is the entire trust contract.

**Independent Test**: For 20 random WRONG rows from the review CSV, confirm by hand that `truth_value` (deterministic rows) or `contradicting_fact_verbatim` (LLM rows) is present verbatim in the snapshot / DDL / SP code / upstream wiki cited in `truth_source`.

**Acceptance Scenarios**:

1. **Given** a deterministic row, **When** I look up `truth_source` (e.g., `DWH_dbo.Dim_PlayerLevel.Name`), **Then** `truth_value` appears literally in that source.
2. **Given** an LLM row, **When** I check `contradicting_fact_verbatim` against the ground-truth blob the LLM was prompted with, **Then** it appears as a substring (enforced by `verbatim_substring_check`).
3. **Given** an LLM verdict with no verbatim citation, **When** the pipeline runs, **Then** the row is dropped to UNVERIFIABLE and excluded from the review CSV.

---

### Edge Cases

- What if a Tier-1 source itself is missing from the upstream index? → Mark `truth_source=UNRESOLVED_UPSTREAM`; the verifier emits an `UNVERIFIABLE` row that is filtered out of the review CSV but appears in a debug log so we can extend the truth snapshot later.
- What if a column's DDL changes between snapshot and review? → The snapshot timestamp is part of every row's metadata; the applier re-runs the deterministic verifier on the patched output as a sanity check and refuses to write if any new WRONG appears.
- What if a wiki description is correct but uses a synonym (e.g., `Customer` vs `User`)? → The LLM prose judge classifies that as SLOPPY (factually consistent, vague wording) and the row is dropped.
- What if the LLM is given a column where the wiki description is empty? → No prompt is sent; the column is logged as `NO_DESCRIPTION` and not emitted to the review CSV.
- What if the wiki .md and .alter.sql disagree on the description? → Both are extracted separately; both go through the same verifier. The review CSV shows two rows so the user can pick which one to fix.

## Clarifications

### Session 2026-05-13

- Q: Scope of the first pass? → A: DWH_dbo only (Dim_*, Fact_*, V_*, CustomerStatic, History_*, STS_*). BI_DB, Dealing, EXW, eMoney run as a second pass after DWH_dbo settles.
- Q: Output mode? → A: Centralized CSV for bulk review (not per-wiki review). No auto-remediate from the judge itself. A separate applier runs only after the user fills `approve_y_n=Y` in the CSV.
- Q: Severity bar? → A: WRONG only. SLOPPY (verbose / vague but factually consistent) and Tier-3 commentary that adds nothing but harms nothing are tolerated. The judge filters SLOPPY and UNVERIFIABLE out of the review CSV.
- Q: Truth-source authority? → A: One-shot Synapse snapshot at the start of the run (DDL, SP code, FKs, dictionary truth, upstream wiki index). The snapshot is timestamped and reused across all stages.
- Q: LLM model? → A: composer-2-fast for the bulk pass. At ~1500–2000 columns with batched prompts this is ~$1–3 total.

## Requirements

### Functional Requirements

- **FR-001**: System MUST pull a frozen truth snapshot from Synapse (INFORMATION_SCHEMA.COLUMNS, sys.default_constraints, sys.foreign_keys, sys.sql_modules for every DWH_dbo SP_*) into `knowledge/_dwh_truth_snapshot/` as JSON.
- **FR-002**: System MUST index `knowledge/skills/_de_existing/*.md` and the existing `knowledge/_dictionary_truth.json` into the snapshot so every Tier-1 claim has a lookup path.
- **FR-003**: System MUST parse every DWH_dbo `.md` element-table and every `.alter.sql` COMMENT body into `knowledge/_dwh_wiki_claims.csv` with structured `claim_type ∈ {type, nullable, default, fk_ref, codepoint, lineage_tag, sample_pct, distinct_values, description}`.
- **FR-004**: Deterministic verifier MUST emit `knowledge/_dwh_deterministic_violations.csv` where every row contains `(object, column, claim_type, wiki_value, truth_value, truth_source, wiki_file, wiki_line)` and `truth_value` is literally present in the source identified by `truth_source`.
- **FR-005**: LLM prose judge MUST run a fully-grounded prompt per column (DDL + SP snippet + upstream wiki + dictionary truth) and emit `knowledge/_dwh_llm_judge.csv`. WRONG verdicts MUST include a `contradicting_fact_verbatim` field that is enforced (by code) to be a substring of the prompt's ground-truth blob; rows that fail the check are coerced to UNVERIFIABLE.
- **FR-006**: System MUST merge deterministic + LLM outputs into one `knowledge/_dwh_judge_review.csv`, filter out SLOPPY / CORRECT / UNVERIFIABLE rows, sort by `(severity, claim_type, object, column)`, and include an empty `approve_y_n` column for human review.
- **FR-007**: System MUST NOT modify any `.md`, `.alter.sql`, or deploy any UC change as part of the judge pipeline. Detection is read-only.
- **FR-008**: Applier (`tools/dwh_judge/apply_approved.py`) MUST process only rows with `approve_y_n=Y`, use literal substring substitution (no regex), and re-run the deterministic verifier on the patched output as a sanity check. It refuses to write if any new WRONG appears.

### Key Entities

- **TruthSnapshot**: Frozen Synapse + upstream-wiki + dictionary-truth bundle taken once per judge run. Timestamped.
- **WikiClaim**: A single structured assertion extracted from a `.md` row or `.alter.sql` COMMENT body, attributed to `(object, column, claim_type)`.
- **Violation**: A wiki claim that contradicts the snapshot. Carries `wiki_value`, `truth_value`, `truth_source` (file path + line / table.column), and `verdict_source ∈ {deterministic, llm}`.
- **ReviewRow**: A row of the central review CSV. Carries `approve_y_n` (empty by default) plus the violation fields.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of DWH_dbo `.md` and `.alter.sql` files in scope are parsed without skipped objects.
- **SC-002**: 100% of WRONG rows in the review CSV have a `truth_source` citation that resolves to a real entry in the snapshot.
- **SC-003**: 100% of LLM WRONG rows pass the `verbatim_substring_check` (no LLM-only flagging without a verbatim quote from the prompt).
- **SC-004**: 0 wiki files modified by the judge pipeline itself (git diff stays clean for the wiki tree).
- **SC-005**: Spot-check of 20 random WRONG rows shows ≥ 95% precision (true contradictions, not synonym disagreements).
