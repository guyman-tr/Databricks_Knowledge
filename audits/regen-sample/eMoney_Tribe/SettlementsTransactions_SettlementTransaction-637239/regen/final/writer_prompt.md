# Regen Harness — Writer Prompt

# Regen Harness — Writer (single-object mode)

You are running the DWH Semantic Documentation pipeline on **ONE OBJECT** in
isolated regen-harness mode. This is NOT the normal batch loop. You are NOT
reading `_index.md`, NOT updating any index file, NOT processing other
objects, NOT running cross-schema sync. You document one object end-to-end and
exit.

---

## ⛔ MCP PRE-FLIGHT — MANDATORY

Before reading any rule files or DDL:

1. Call `mcp__synapse_sql__execute_sql_read_only` with `SELECT 1 AS mcp_preflight`.
2. **If it fails or the tool does not exist**: print `REGEN ABORT: Synapse MCP unavailable` and **EXIT IMMEDIATELY**. A wiki without live data sampling is INCOMPLETE and WILL FAIL the adversarial judge.
3. **If it succeeds**: print `MCP PRE-FLIGHT: PASS` and continue.

No exceptions. No "code-only documentation" fallback. No "I'll skip Phase 2 because the table looks dormant" — the judge sees the dormant footer too and will fail you for missing data evidence.

---

## ⛔ PHASE 3 DISTRIBUTION CAP

Phase 3 (distribution analysis) is capped at **at most 3 categorical columns**
per object. Pick those whose names match the regex
`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`.
Skip free-text columns entirely (Email, Description, Comment, Note, Address,
Name, Url, Subject, Body, Reason).

If fewer than 3 columns match the regex, run distribution queries on however
many DO match — running zero distribution queries is OK if the table has no
obviously-categorical columns.

---

## ⛔ OUTPUT DIRECTORY GUARANTEE

The directory listed under **Absolute output directory** in the Object Header
ALREADY EXISTS, was created by the harness, and is empty (apart from the
writer_prompt.md you are reading). DO NOT run `Bash ls` to check it. DO NOT
run `Bash mkdir`. Just call `Write` directly with the absolute paths from the
Object Header for the three required files.

---

## ⛔ PRE-RESOLVED UPSTREAM CONTEXT — your Tier 1 inheritance source is below, USE IT

The block titled **"## PRE-RESOLVED UPSTREAM BUNDLE"** in this prompt was
assembled **deterministically by the harness, before you started**. It contains:

- The **DDL** for the object you are documenting (verbatim from SSDT).
- Every **upstream wiki** the harness could resolve from the existing
  `.lineage.md` plus DDL-derived references — both local Synapse wikis and
  remote production-DB wikis (DB_Schema, ExperianceDBs, etc.).
- For any stored procedure mentioned in the lineage, the **SP source code**
  pulled from `DataPlatform\SynapseSQLPool1\sql_dp_prod_we\...`.

**Treat this bundle as your AUTHORITATIVE source for Tier 1 inheritance.** You
are NOT permitted to claim "no upstream wiki could be found" if the bundle
contains one. You ARE permitted to read additional files via the `Read` tool
if you need more context.

### Tier rules — re-stated, NON-NEGOTIABLE

For every column in the object:

1. **Passthrough or rename WITH upstream wiki present in the bundle** →
   **Tier 1**. Description MUST be a verbatim quote from the upstream wiki.
   Do not paraphrase. Do not "improve". Do not generalize vendor names. Do not
   drop NULL semantics. The judge will run a character-by-character
   comparison.
2. **ETL-computed** (CASE / arithmetic / aggregation visible in the SP source) →
   **Tier 2** with the transform stated. The source after `(Tier 2 — …)` MUST
   name the **upstream TABLE the transform reads from**, NOT the SP that
   performs the transform. The SP is the tool; the table is the data source.
   Examples:
   - `ABS(Fact_Deposit_State.Amount)` → `(Tier 2 — Fact_Deposit_State)`
   - `CASE WHEN x.IsSettled = 1 THEN 'Real' END` → `(Tier 2 — Fact_BillingDeposit)`
   - Pure passthrough from a DWH fact (no production wiki) →
     `(Tier 2 — Fact_X)`, NOT `(Tier 2 — SP_X)`.
   - Multi-source UNION → list both tables, slash-separated:
     `(Tier 2 — Fact_Deposit_State / Fact_Cashout_State)`.
   The ONLY case where an SP name belongs in the source is when the column is
   purely synthesized inside the SP with no input table column (e.g.
   `GETDATE()`, `@StartDateID`, fixed literal). Then write `(Tier 2 — SP_X)`.
3. **Dim-lookup passthrough** (`SELECT dim.X` with no transform AND `Dim_X`
   has its own Tier 1 origin documented in the bundle) → **Tier 1 with the
   dim's origin** (e.g. `Dictionary.Country`), NOT `Tier 2 via SP_X` and NOT
   `Tier 1 via Dim_X` (Dim_X is a relay, not a root). Quote the dim's wiki
   verbatim.
4. **No source traceable from bundle, DDL, JOINs, or SP source** →
   **Tier 3** with explicit reason. Be specific: "PII column, no upstream wiki
   located, name suggests …".
5. **`Tier 4 — inferred from name`** is BANNED unless the bundle explicitly
   shows the column has no upstream and no SP code touches it. Lazy Tier 4 is
   the #1 reason wikis fail the judge. If you are tempted to write Tier 4
   with no other evidence, you have skipped Phase 9 — go back and read the
   SP source in the bundle.

### Footer rules

- If the bundle contains AT LEAST ONE upstream wiki: the footer MUST identify
  the production source(s). Writing `Production Source: Unknown (dormant)`
  when the bundle proves an upstream exists is an automatic fail.
- If `_no_upstream_found.txt` exists in the regen folder: it is OK to mark
  the table as dormant in the footer, but you MUST still ground every column
  description in the DDL + SP code rather than `Tier 4 — inferred`.

---

## Output paths — write here, NOT into the main wiki tree

Write all THREE output files into:

```
audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/
  {Object}.md
  {Object}.lineage.md
  {Object}.review-needed.md
```

`{Schema}`, `{Object}`, and `{N}` are passed in via the prompt header below.

**DO NOT** write into `knowledge/synapse/Wiki/` under any circumstances. The
main tree is read-only for this run. **DO NOT** modify `_index.md` or any
`_batch_context.json`. **DO NOT** generate `.alter.sql`. **DO NOT** run Phase
16 — the adversarial judge runs as a separate, fresh claude process AFTER you
exit. Pretending to evaluate yourself wastes tokens.

---

## Pipeline scope for this single object

Run phases 1 through 11 inclusive. Skip Phase 16. Skip Phase 11W (no ALTER).
Skip cross-object index updates. Skip `_batch_context.json` writes.

Required phase gates (you must print them as you complete each):

```
PHASE GATE — {Schema}.{Object}:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

If a phase truly cannot run (e.g. no SPs reference the table), mark it `[-]`
with a one-line reason. Skipping P2 or P3 because "the table is small" is
NOT a valid reason — sample it.

---

## Outputs — three files, exact shape

Follow the GOLDEN-REFERENCE in
`.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`.

1. **`{Object}.lineage.md`** — written FIRST (Phase 10B). Source Objects
   table + Column Lineage table. Every Tier 1 row must point to a file in the
   pre-resolved bundle (or to a wiki you read independently).
2. **`{Object}.md`** — the main wiki, 8 sections, every column in
   Section 4's Elements table, every description ending with
   `(Tier N — source)`.
3. **`{Object}.review-needed.md`** — items needing human review. MUST NOT
   contain a `## 4. Elements` section.

---

## Final checklist before exiting

Print, verbatim:

```
OUTPUT CHECK — {Schema}.{Object}:
  [x] .lineage.md    written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.lineage.md
  [x] .md            written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.md
  [x] .review-needed.md written → audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/{Object}.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: N    Tier2: N    Tier3: N    Tier4: N
  Bundle inheritance used: YES/NO  (NO is only valid if `_no_upstream_found.txt` exists)
```

Then EXIT. Do not run a self-evaluation. Do not "double-check by re-reading
the wiki you just wrote". Do not append a verdict block. The judge runs in a
separate process with its own context.


---

# Object Header

- **Schema**: `eMoney_Tribe`
- **Object**: `SettlementsTransactions_SettlementTransaction-637239`
- **Attempt**: `2`
- **Output directory** (relative to repo root): `audits/regen-sample/eMoney_Tribe/SettlementsTransactions_SettlementTransaction-637239/regen/attempt_2/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\eMoney_Tribe\SettlementsTransactions_SettlementTransaction-637239\regen\attempt_2`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\eMoney_Tribe\SettlementsTransactions_SettlementTransaction-637239\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\eMoney_Tribe\Tables\eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239.sql`
- **No-upstream marker present**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\eMoney_Tribe\SettlementsTransactions_SettlementTransaction-637239\regen\_no_upstream_found.txt` — object is dormant or has no resolvable upstream wiki. Footer may say `Production Source: Unknown (dormant)`. Tier 4 inferred is STILL banned — ground every column description in DDL + SP code.

---

# build-wiki-dwh-batch

You are running the DWH Semantic Documentation pipeline for a Synapse DWH schema.
**Wiki-only mode** — generate documentation files only. ALTER scripts are generated separately later via `/generate-alter-dwh`.

## ⛔ MCP PRE-FLIGHT — NON-NEGOTIABLE, CHECK BEFORE ANYTHING ELSE

Before loading rules, before reading the index, before planning anything:

1. **Test Synapse MCP**: Call `mcp__synapse_sql__execute_sql_read_only` with `SELECT 1 AS mcp_preflight`
2. **If it fails or the tool does not exist**: Print `BATCH ABORT: Synapse MCP unavailable` and **EXIT IMMEDIATELY**. Do NOT proceed. Do NOT fall back to "prior batch context data". Do NOT use a "schema practice" of skipping MCP. A wiki without live data sampling is INCOMPLETE and WILL NOT PASS the adversarial evaluator. STOP HERE.
3. **If it succeeds**: Print `MCP PRE-FLIGHT: PASS` and continue to Instructions.

There is NO exception to this rule. No "prior context", no "code-only documentation", no "graceful degradation". MCP down = batch aborted. Period.

---

## Instructions (regen-harness, single object)

1. **Load rules** — read these in order before anything else:
   - `.cursor/rules/semantic-layer-core/repo-first-access.mdc`
   - `.cursor/rules/dwh-semantic-doc/00-execution-card.mdc`
   - `.cursor/rules/dwh-semantic-doc/mcp-query-rules.mdc`
   - `.cursor/rules/dwh-semantic-doc/GOLDEN-REFERENCE.mdc`
   - `.cursor/rules/dwh-semantic-doc/10.5b-tier1-enforcement.mdc`

2. **Skip batch planning** — do NOT read `_index.md`, do NOT touch
   `_batch_context.json`, do NOT scan the blacklist. The harness
   already chose this object.

3. **Run the pipeline for THIS object only**: phases 1 through 11
   inclusive. Use the pre-resolved upstream bundle (provided below)
   as your authoritative Tier 1 source. Generate three files in
   `audits/regen-sample/{schema}/{object}/regen/attempt_{N}/`:
   `.lineage.md`, `.md`, `.review-needed.md`. Do NOT generate
   `.alter.sql`. Do NOT modify any file under `knowledge/synapse/Wiki/`.

4. **Skip Phase 16** — the adversarial judge runs in a separate,
   fresh claude process after you exit. Self-evaluation here wastes
   tokens and pollutes the comparison.

5. **Exit cleanly** after printing the OUTPUT CHECK block defined in
   the Regen Harness preamble.

## Key resources

- **SSDT DDL files**: `C:\Users\guyman\Documents\github\DataPlatform\` (repo-first for structure)
- **Upstream wikis (dynamic)**: Load `knowledge/synapse/Wiki/_upstream_wiki_routing.json` for Tier 1 repo locations. Includes DB_Schema, ExperianceDBs, CryptoDBs, BankingDBs, ComplianceDBs, PaymentsDBs and more.
- **DWH upstream wikis**: `knowledge/synapse/Wiki/DWH_dbo/` (for cross-schema references)
- **Dependency graph**: `knowledge/synapse/Wiki/_dependency_order.json`
- **Generic pipeline mapping**: `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`
- **MCP Synapse**: `mcp__synapse_sql__execute_sql_read_only` (live data sampling, distribution)
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC metadata verification)

## Batch size reference

| Schema | Batch Size |
|--------|-----------|
| DWH_dbo | 4 |
| BI_DB_dbo | 3 |
| Dealing_dbo | 4 |
| EXW_dbo | 3 |
| eMoney_dbo | 4 |
| Default | 3 |

---

# PRE-RESOLVED UPSTREAM BUNDLE

Treat the block below as your AUTHORITATIVE Tier 1 inheritance source. Quote upstream descriptions verbatim. Do not paraphrase.

# Pre-Resolved Upstream Bundle for `eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239.sql`

```sql
CREATE TABLE [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[@Created] [datetime2](7) NULL,
	[@Id] [varchar](40) NULL,
	[@SettlementsTransactions@Id-333243] [varchar](40) NULL,
	[FileDate] [varchar](max) NULL,
	[WorkDate] [varchar](max) NULL,
	[@WorkDate] [datetime2](7) NULL,
	[IssuerIdentificationNumber] [varchar](max) NULL,
	[ProgramName] [varchar](max) NULL,
	[ProgramId] [varchar](max) NULL,
	[ProductName] [varchar](max) NULL,
	[ProductId] [varchar](max) NULL,
	[SubProductId] [varchar](max) NULL,
	[HolderId] [varchar](max) NULL,
	[AccountId] [varchar](max) NULL,
	[BankAccountId] [varchar](max) NULL,
	[CardNumber] [varchar](max) NULL,
	[CardNumberId] [varchar](max) NULL,
	[CardRequestId] [varchar](max) NULL,
	[MtiCode] [varchar](max) NULL,
	[MessageReasonCode] [varchar](max) NULL,
	[Bin] [varchar](max) NULL,
	[TransactionCode] [varchar](max) NULL,
	[TransactionCodeDescription] [varchar](max) NULL,
	[AuthorizationCode] [varchar](max) NULL,
	[TransactionDateTime] [varchar](max) NULL,
	[TransactionAmount] [varchar](max) NULL,
	[TransactionCurrencyCode] [varchar](max) NULL,
	[TransactionCurrencyAlpha] [varchar](max) NULL,
	[TransLink] [varchar](max) NULL,
	[TraceId] [varchar](max) NULL,
	[TransactionCodeIdentifier] [varchar](max) NULL,
	[HolderAmount] [varchar](max) NULL,
	[HolderCurrencyCode] [varchar](max) NULL,
	[HolderCurrencyAlpha] [varchar](max) NULL,
	[FxRate] [varchar](max) NULL,
	[FeeGroupId] [varchar](max) NULL,
	[FeeGroupName] [varchar](max) NULL,
	[FxFeeName] [varchar](max) NULL,
	[FxFeeCode] [varchar](max) NULL,
	[FxFeeAmount] [varchar](max) NULL,
	[FxFeeCurrency] [varchar](max) NULL,
	[FxFeeReason] [varchar](max) NULL,
	[F0FeeName] [varchar](max) NULL,
	[F0FeeCode] [varchar](max) NULL,
	[F0FeeAmount] [varchar](max) NULL,
	[F0FeeCurrency] [varchar](max) NULL,
	[F0FeeReason] [varchar](max) NULL,
	[BillRateAmount] [varchar](max) NULL,
	[BillingDate] [varchar](max) NULL,
	[BillingAmount] [varchar](max) NULL,
	[BillingCurrencyCode] [varchar](max) NULL,
	[BillingCurrencyAlpha] [varchar](max) NULL,
	[ReconciliationDate] [varchar](max) NULL,
	[SettlementDate] [varchar](max) NULL,
	[SettlementAmount] [varchar](max) NULL,
	[SettlementCurrencyCode] [varchar](max) NULL,
	[SettlementCurrencyAlpha] [varchar](max) NULL,
	[SettlementConversionRate] [varchar](max) NULL,
	[MerchantNumber] [varchar](max) NULL,
	[Merchant] [varchar](max) NULL,
	[MerchantName] [varchar](max) NULL,
	[MerchantAddress] [varchar](max) NULL,
	[MerchantCity] [varchar](max) NULL,
	[MerchantPostcode] [varchar](max) NULL,
	[MerchantCountryCodeAlpha] [varchar](max) NULL,
	[MerchantCountryName] [varchar](max) NULL,
	[Mcc] [varchar](max) NULL,
	[CardPresent] [varchar](max) NULL,
	[CardInputMode] [varchar](max) NULL,
	[CardholderAuthenticationMethod] [varchar](max) NULL,
	[PosDataDe22] [varchar](max) NULL,
	[PosDataDe61] [varchar](max) NULL,
	[AcquirerId] [varchar](max) NULL,
	[AcquirerReferenceNumber] [varchar](max) NULL,
	[TransactionId] [varchar](max) NULL,
	[InterchangeFeeAmount] [varchar](max) NULL,
	[InterchangeFeeCurrency] [varchar](max) NULL,
	[InterchangeFeeDirection] [varchar](max) NULL,
	[InterchangeRateDesignator] [varchar](max) NULL,
	[CycleNumber] [varchar](max) NULL,
	[CycleFileId] [varchar](max) NULL,
	[TransactionClass] [varchar](max) NULL,
	[Action] [varchar](max) NULL,
	[Network] [varchar](max) NULL,
	[TransactionDescription] [varchar](max) NULL,
	[EntryModeCode] [varchar](max) NULL,
	[EntryModeCodeDescription] [varchar](max) NULL,
	[ECIIndicator] [varchar](max) NULL,
	[Suspicious] [varchar](max) NULL,
	[RiskRuleCodes] [varchar](max) NULL,
	[FunctionCode] [varchar](max) NULL,
	[LoadType] [varchar](max) NULL,
	[LoadSource] [varchar](max) NULL,
	[SettlementFlag] [varchar](max) NULL,
	[TransactionCodeQualifier] [varchar](max) NULL,
	[BusinessFormatCode] [varchar](max) NULL,
	[CardType] [varchar](max) NULL,
	[ParentTransactionId] [varchar](max) NULL,
	[DisputeId] [varchar](max) NULL,
	[ExternalDisputeId] [varchar](max) NULL,
	[ActualAuthorizationId] [varchar](max) NULL,
	[FirstAuthorizationDate] [varchar](max) NULL,
	[InterchangeFeeAmountRounded] [varchar](max) NULL,
	[ReferenceNumber] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL,
	[PosDataExtendedDe61] [varchar](max) NULL,
	[Created] [datetime2](7) NULL,
	[TokenizedRequest] [varchar](max) NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	HEAP
)

GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_ST_637239] ON [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_ST_637239_c2] ON [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[@SettlementsTransactions@Id-333243] ASC
)WITH (DROP_EXISTING = OFF)
GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [idx_637239_Id] ON [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|


---

# JUDGE FEEDBACK FROM PREVIOUS ATTEMPT — apply ALL of these

Previous attempt scored **7.1** (FAIL). The adversarial judge required regeneration with the following specific fixes:

> Re-run with: (1) Re-tag @Created, @Id, @SettlementsTransactions@Id-333243, and Created as Tier 3 — no upstream wiki was available in the bundle. (2) Update footer tier counts from '4 T1, 5 T2, 103 T3' to '0 T1, 5 T2, 107 T3'. (3) Remove or annotate the Tier 1 legend row to indicate no Tier 1 columns exist for this table. (4) Keep all other content — business meaning, completeness, evidence, and shape are strong.

Top issues from the judge:
1. [high] `@Created, @Id, @SettlementsTransactions@Id-333243, Created` — All 4 columns tagged Tier 1 but the upstream bundle explicitly states 'NO UPSTREAM WIKI was resolvable for any source listed in the lineage.' These are writer-composed descriptions falsely attributed as verbatim upstream quotes. Must be re-tagged as Tier 3.
2. [medium] `Section 4 Tier Legend` — Tier 1 legend reads 'Verbatim from upstream production wiki (FiatDwhDB.Tribe)' but no such wiki exists in the bundle. Legend is technically correct in definition but the writer violated it by tagging columns as Tier 1 anyway.
3. [medium] `Footer` — Footer claims '4 T1, 5 T2, 103 T3' — should be '0 T1, 5 T2, 107 T3' after correcting the fabricated Tier 1 assignments.
4. [low] `review-needed sidecar Section 1` — Sidecar references 'upstream production wiki (Tribe.SettlementsTransactions_SettlementTransaction-637239.md)' as if it exists and documents 4 columns — but the bundle says NO upstream wiki was resolvable. Writer may have accessed a source outside the provided bundle.
5. [low] `Section 3.1` — Duplicate NCI documentation is accurate (ClusteredIndex_ST_637239 and idx_637239_Id both on @Id) — correctly identified but not a wiki deficiency.

Tier 1 paraphrasing failures (must be fixed verbatim):

- **@Created**:
  - Upstream: `No upstream wiki exists in the bundle`
  - You wrote: `DWH timestamp. (Tier 1 — FiatDwhDB.Tribe.SettlementsTransactions_SettlementTransaction-637239)`
  - Loss: Fabricated Tier 1 — no upstream wiki was available; should be Tier 3
- **@Id**:
  - Upstream: `No upstream wiki exists in the bundle`
  - You wrote: `PK. Unique GUID identifier for this settlement transaction record. Indexed by ClusteredIndex_ST_637239 and idx_637239_Id. Used as the primary JOIN key to sibling tables (RiskActions-236807, SecurityCh`
  - Loss: Fabricated Tier 1 — writer-composed description attributed as upstream verbatim; no upstream wiki exists
- **@SettlementsTransactions@Id-333243**:
  - Upstream: `No upstream wiki exists in the bundle`
  - You wrote: `FK to parent. Links to the parent SettlementsTransactions-333243 container record. Contains identical GUID values to @Id in sampled data (1:1 relationship). Indexed by ClusteredIndex_ST_637239_c2. (Ti`
  - Loss: Fabricated Tier 1 — no upstream wiki was available; should be Tier 3
- **Created**:
  - Upstream: `No upstream wiki exists in the bundle`
  - You wrote: `Source timestamp. Timestamp of when the settlement record was created in the source system (FiatDwhDB.Tribe). Used as the incremental load watermark by SP_eMoney_Reconciliation_ETLs (WHERE @Created >=`
  - Loss: Fabricated Tier 1 — writer-composed description attributed as upstream verbatim; no upstream wiki exists

Address every issue above. Do NOT regenerate the whole wiki from scratch — keep what was correct, only fix what the judge flagged.
