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
   **Tier 2** with the transform stated.
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

- **Schema**: `BI_DB_dbo`
- **Object**: `BI_DB_AdvancedDeposit_Ext`
- **Attempt**: `2`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_AdvancedDeposit_Ext/regen/attempt_2/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_AdvancedDeposit_Ext\regen\attempt_2`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_AdvancedDeposit_Ext\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_AdvancedDeposit_Ext.sql`
- **No-upstream marker present**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_AdvancedDeposit_Ext\regen\_no_upstream_found.txt` — object is dormant or has no resolvable upstream wiki. Footer may say `Production Source: Unknown (dormant)`. Tier 4 inferred is STILL banned — ground every column description in DDL + SP code.

---

# build-wiki-bidb-batch

You are running the DWH Semantic Documentation pipeline for schema BI_DB_dbo.
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
- **OpsDB priority file**: `.specify/Configs/opsdb-objects-status.json`
- **OpsDB dependencies**: `.specify/Configs/opsdb-procedure-dependencies.json`
- **Generic pipeline mapping**: `knowledge/synapse/Wiki/_generic_pipeline_mapping.json`
- **MCP Synapse**: `mcp__synapse_sql__execute_sql_read_only` (live data sampling, distribution)
- **MCP Databricks**: `mcp__databricks_sql__execute_sql_read_only` (UC metadata verification)

---

# PRE-RESOLVED UPSTREAM BUNDLE

Treat the block below as your AUTHORITATIVE Tier 1 inheritance source. Quote upstream descriptions verbatim. Do not paraphrase.

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_AdvancedDeposit_Ext`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_AdvancedDeposit_Ext.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_AdvancedDeposit_Ext]
(
	[DepositID] [bigint] NULL,
	[CID] [int] NULL,
	[FundingID] [bigint] NULL,
	[FundingType] [varchar](50) NULL,
	[CurrencyID] [bigint] NULL,
	[PaymentStatusID] [bigint] NULL,
	[ManagerID] [bigint] NULL,
	[RiskManagementStatusID] [bigint] NULL,
	[Amount] [money] NULL,
	[ExchangeRate] [numeric](16, 8) NULL,
	[ModificationDate] [datetime] NULL,
	[TransactionID] [varchar](6) NULL,
	[IPAddress] [numeric](18, 0) NULL,
	[Approved] [bit] NULL,
	[Commission] [money] NULL,
	[PaymentDate] [datetime] NULL,
	[ClearingHouseEffectiveDate] [datetime] NULL,
	[OldPaymentID] [bigint] NULL,
	[IsFTD] [bit] NULL,
	[ProcessorValueDate] [datetime] NULL,
	[RefundVerificationCode] [varchar](50) NULL,
	[DepotID] [bigint] NULL,
	[MatchStatusID] [bigint] NULL,
	[FunnelID] [bigint] NULL,
	[Code] [varchar](50) NULL,
	[ExTransactionID] [varchar](50) NULL,
	[PaymentStatus_PaymentStatusID] [bigint] NULL,
	[PaymentStatus_Name] [varchar](50) NULL,
	[RiskManagementStatus_RiskManagementStatusID] [bigint] NULL,
	[RiskManagementStatus_Name] [varchar](50) NULL,
	[Channel] [nvarchar](50) NULL,
	[SubChannel] [varchar](100) NULL,
	[Region] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[FirstDepositAttempt] [datetime] NULL,
	[FirstDepositDate] [datetime] NULL,
	[Registered] [datetime] NULL,
	[SerialID] [bigint] NULL,
	[Funnel] [varchar](50) NULL,
	[FunnelFrom] [varchar](50) NULL,
	[AcquisitionFunnel] [varchar](50) NULL,
	[BinCode] [bigint] NULL,
	[CreditCardType] [varchar](50) NULL,
	[CardSubType] [varchar](50) NULL,
	[BINCountry] [varchar](50) NULL,
	[DepoName] [varchar](50) NULL,
	[CardCategory] [varchar](50) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)

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

Previous attempt scored **5.15** (FAIL). The adversarial judge required regeneration with the following specific fixes:

> Re-run with: (1) Re-tag ALL 34 Tier 1 columns to Tier 2 — no upstream wiki was available in the bundle, so Tier 1 inheritance is impossible. Use '(Tier 2 — SP_H_Deposits code analysis)' or equivalent. (2) Remove fabricated 'upstream wiki' reference in PaymentStatusID. (3) Write distinct descriptions for Funnel, FunnelFrom, and AcquisitionFunnel explaining the different join paths and business meanings. (4) Differentiate Country (customer registration) vs BINCountry (card issuer) descriptions. (5) Add a Phase Gate Checklist section or remove the 'Phases: 13/14' footer claim. (6) Update footer tier breakdown to 0 T1, ~47 T2.

Top issues from the judge:
1. [high] `All 34 claimed Tier 1 columns` — The upstream bundle explicitly states 'NO UPSTREAM WIKI was resolvable for any source listed in the lineage.' Every Tier 1 tag is invalid — no wiki existed to quote verbatim from. All 34 should be Tier 2 (SP code-traced) or Tier 3.
2. [high] `PaymentStatusID (#6)` — Description states 'Full 39-value enum in upstream wiki' — this upstream wiki does not exist per the bundle. This is a fabricated source reference.
3. [high] `Funnel (#39), FunnelFrom (#40), AcquisitionFunnel (#41)` — All three columns share an identical copy-pasted description despite representing three different join paths with different business semantics (deposit funnel vs. source funnel vs. current funnel).
4. [medium] `Country (#34), BINCountry (#45)` — Near-identical descriptions copy-pasted. Country is customer registration country; BINCountry is card-issuing bank country. Core description should differentiate these.
5. [medium] `Footer / Phase Gate` — Footer claims 'Phases: 13/14' but no Phase Gate Checklist section exists in the document. Cannot verify which phases were completed or skipped.

Tier 1 paraphrasing failures (must be fixed verbatim):

- **DepositID**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Passthrough from Fact_BillingDeposit.`
  - Loss: Entire Tier 1 claim fabricated — no upstream wiki was available to quote from
- **Amount**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Deposit amount in the deposit currency (CurrencyID). DWH note: as of 2025-04-17, capped via CASE expression in upstream ETL to prevent extreme outlier values from distorting aggregations. Passthrough `
  - Loss: Description invented without wiki source; specific DWH note may be from code but not from a documented wiki
- **PaymentStatusID**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Current deposit status. Key values: 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. Full 39-value enum in upstream wiki. Passthrough from Fact_Billing`
  - Loss: Fabricated reference to 'upstream wiki' that does not exist; enum values not verifiable from any provided wiki
- **Country**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CountryID.`
  - Loss: Fabricated Tier 1 claim from Dictionary.Country; description invented
- **Funnel**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup `
  - Loss: Fabricated Tier 1 claim from Dictionary.Funnel; identical description copy-pasted across 3 funnel columns
- **FunnelFrom**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup `
  - Loss: Identical copy-paste from Funnel column; fabricated Tier 1
- **AcquisitionFunnel**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup `
  - Loss: Identical copy-paste from Funnel column; fabricated Tier 1
- **CreditCardType**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Card brand name. DDL note: source column has a typo ('CarTypeName' instead of 'CardTypeName') — historical artifact from legacy DWH SQL Server migration. Key values: Visa, Master Card, MasterCard, Din`
  - Loss: Fabricated Tier 1 from Dictionary.CardType; card brand list not sourced from any wiki
- **DepoName**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Dim-lookup passthrough from Dim_Bil`
  - Loss: Fabricated Tier 1 from Billing.Depot; vendor names (MoneyBookers, Neteller) not sourced from any wiki
- **BINCountry**:
  - Upstream: `NO UPSTREAM WIKI EXISTS IN BUNDLE`
  - You wrote: `Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via fbd.BinCountryIDAsInteger. May differ`
  - Loss: Copy-paste of Country description with fraud note appended; fabricated Tier 1

Address every issue above. Do NOT regenerate the whole wiki from scratch — keep what was correct, only fix what the judge flagged.
