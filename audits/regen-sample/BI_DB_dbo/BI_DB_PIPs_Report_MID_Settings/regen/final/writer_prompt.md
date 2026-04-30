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

- **Schema**: `BI_DB_dbo`
- **Object**: `BI_DB_PIPs_Report_MID_Settings`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_PIPs_Report_MID_Settings/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_PIPs_Report_MID_Settings\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_PIPs_Report_MID_Settings\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_PIPs_Report_MID_Settings]
(
	[Date] [date] NULL,
	[DateID] [int] NULL,
	[TransactionID] [varchar](20) NULL,
	[MIDName] [varchar](50) NULL,
	[MID] [varchar](50) NULL,
	[ActionType] [varchar](50) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [TransactionID] ),
	CLUSTERED INDEX
	(
		[Date] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 8 upstream wiki(s). Read EACH one in full.


### Upstream `BI_DB_dbo.BI_DB_DepositWithdrawFee` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_DepositWithdrawFee`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md`

# BI_DB_dbo.BI_DB_DepositWithdrawFee

## 1. Overview

Daily **deposit, withdrawal, and fee / reversal-style cash events** at transaction grain, enriched with customer snapshot attributes, payment method and card metadata, merchant (**MID**) fields, and **PIPs** (payment processing) amounts in USD. Each row represents one logical transaction row from **Fact_Deposit_State** or **Fact_Cashout_State** (plus billing dimension joins); **Amount**, **AmountUSD**, and **PIPsCalculation** are signed after load using a transaction-type direction map.

**Row grain**: One row per **DepositWithdrawID** / **TransactionID** combination for the processed **DateID** (deposits and withdraws unions), after deduplication rules on billing withdraw.

---

## 2. Business context

Replaces legacy deposit/withdraw logic with the RnD PIPS-based pipeline (2025). Used for **finance reconciliation**, payment analytics, and geographic / method attribution (**RegCountry**, **BinCountry**, **CardType**, **MIDName**, etc.).

**Key business rules** (from `SP_DepositWithdrawFee`):
- **Scope**: Rows where **ModificationDateID** = **@StartDateID** from **Fact_Deposit_State** (deposits vs non-deposit types) and **Fact_Cashout_State** (withdraws vs non-withdraw types).
- **Withdraw path**: **Fact_Cashout_State** joined to deduped **Fact_BillingWithdraw** rows present in **Fact_Cashout_State** for that date (handles duplicate billing rows).
- **Deposit path**: **Fact_Deposit_State** joined to **Fact_BillingDeposit** for funding metadata.
- **ABS then sign**: Source amounts are loaded with **ABS**; final **UPDATE** applies **#amountDirections** so **Withdraw** / **Refund** / **Chargeback** types are negative where configured.
- **PIPsCalculation**: **ABS(ISNULL(PIPsInUSD,0))** at insert; further multiplied or negated by direction rules and special-case **UPDATE**s for rollback / chargeback-reversal rows joined to **Fact_CustomerAction**.
- **CreditTypeID**: Intentionally **NULL** in the modern proc (per change history).
- **MOPCountry**, **IsGermanBaFin**: **NULL** literals in current build.
- **IsIBANTrade**: **1** when billing **FlowID** = 2 (withdraw) or = 1 (deposit) per branch logic.
- **TransactionID**: **CAST(DepositID AS varchar) + 'D'** or **CAST(WPID AS varchar) + 'W'**.

**Related table**: **BI_DB_DepositWithdrawFee_Reversals** receives deposit/withdraw **reversal** subsets from the same SP (not documented in this file).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 44 |
| **Distribution** | HASH(CID) |
| **Clustered index** | CLUSTERED COLUMNSTORE INDEX |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as **YYYYMMDD** for the load (**@StartDateID**). (Tier 2 -- SP_DepositWithdrawFee, @StartDateID) |
| 2 | CID | int | YES | Internal customer id (**RealCID**) from deposit or cashout state. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.CID / Fact_Cashout_State.CID) |
| 3 | DepositWithdrawID | int | YES | **DepositID** or **WithdrawID** depending on path -- stable id for the cash event. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositID / Fact_Cashout_State.WithdrawID) |
| 4 | Occurred | datetime | YES | Event timestamp (**ModificationDate** from state fact). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ModificationDate) |
| 5 | CreditTypeID | int | YES | Set to **NULL** in the current procedure (legacy column retired). (Tier 2 -- SP_DepositWithdrawFee, NULL) |
| 6 | TransactionID | varchar(200) | YES | Synthetic id: deposit id + **D** or WP id + **W**. (Tier 2 -- SP_DepositWithdrawFee, computed) |
| 7 | Date | date | YES | Calendar date of **ModificationDate**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ModificationDate) |
| 8 | Customer | varchar(200) | YES | External customer id (**Dim_Customer.ExternalID**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Customer.ExternalID) |
| 9 | TransactionType | varchar(200) | YES | Type string from state (**Deposit**, **Withdraw**, chargebacks, refunds, rollbacks, etc.). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.TransactionType) |
| 10 | PaymentMethod | varchar(200) | YES | Funding type name (**Dim_FundingType.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_FundingType.Name) |
| 11 | Amount | numeric(38,8) | YES | Transaction amount in original currency; **ABS** at insert then signed via **#amountDirections** (and edge-case **UPDATE**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.Amount) |
| 12 | Currency | varchar(200) | YES | Currency code (**Dim_Currency.Abbreviation**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Currency.Abbreviation) |
| 13 | ExchangeRate | numeric(38,8) | YES | FX rate on the state row. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExchangeRate) |
| 14 | AmountUSD | numeric(38,8) | YES | USD amount; **ABS** at insert then signed like **Amount**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.AmountInUSD) |
| 15 | RegulationID | int | YES | Regulation key from customer snapshot. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.RegulationID) |
| 16 | LabelID | int | YES | Marketing / label id from snapshot (deposit path uses **dc.LabelID** join in one branch). (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.LabelID / Dim_Customer.LabelID) |
| 17 | PlayerLevelID | int | YES | Player level id from snapshot. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.PlayerLevelID) |
| 18 | Regulation | varchar(200) | YES | Regulation name (**Dim_Regulation.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Regulation.Name) |
| 19 | Label | varchar(200) | YES | Label name (**Dim_Label.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Label.Name) |
| 20 | IsValidCustomer | int | YES | Snapshot validity flag. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.IsValidCustomer) |
| 21 | UpdateDate | datetime | NO | Row load timestamp (**GETDATE()** at insert). (Tier 3 -- SP_DepositWithdrawFee, GETDATE()) |
| 22 | BaseExchangeRate | numeric(38,8) | YES | Base FX rate from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.BaseExchangeRate) |
| 23 | ExchangeFee | numeric(38,8) | YES | Exchange fee from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExchangeFee) |
| 24 | ExternalTransactionID | varchar(200) | YES | Provider transaction id (**ExTransactionID**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExTransactionID) |
| 25 | Depot | varchar(200) | YES | Billing depot name (**Dim_BillingDepot**). (Tier 2 -- SP_DepositWithdrawFee, Dim_BillingDepot.Name) |
| 26 | MIDValue | varchar(200) | YES | Merchant id value on the state row (**MID**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.MID) |
| 27 | Club | varchar(200) | YES | Player level / club name (**Dim_PlayerLevel.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_PlayerLevel.Name) |
| 28 | PlayerStatus | varchar(200) | YES | Player status label (**Dim_PlayerStatus.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_PlayerStatus.Name) |
| 29 | PIPsCalculation | numeric(38,8) | YES | **ABS(PIPsInUSD)** at insert; adjusted by direction rules and post-join **UPDATE**s (rollbacks, chargeback reversals, **Fact_CustomerAction** tie-break). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.PIPsInUSD) |
| 30 | RegCountry | varchar(200) | YES | Registration country from snapshot **CountryID**. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name) |
| 31 | RegCountryByIP | varchar(50) | YES | Country from customer **CountryIDByIP**. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name) |
| 32 | CardType | varchar(200) | YES | Card type name (**Dim_CardType.CarTypeName**) or raw **Fact_Deposit_State.CardType** on deposit path. (Tier 2 -- SP_DepositWithdrawFee, Dim_CardType / Fact_Deposit_State) |
| 33 | CardCategory | varchar(200) | YES | Card category from billing deposit or withdraw. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingDeposit / Fact_BillingWithdraw) |
| 34 | BinCountry | varchar(200) | YES | Country from BIN country id on billing. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name) |
| 35 | MOPCountry | varchar(200) | YES | Not populated (**NULL**) in current SP. (Tier 2 -- SP_DepositWithdrawFee, NULL) |
| 36 | IsGermanBaFin | int | YES | Not populated (**NULL**) in current SP. (Tier 2 -- SP_DepositWithdrawFee, NULL) |
| 37 | IsIBANTrade | int | YES | **1** when deposit **FlowID** = 1 or withdraw **FlowID** = 2 on billing fact. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingDeposit.FlowID / Fact_BillingWithdraw.FlowID) |
| 38 | MIDName | varchar(200) | YES | Merchant display name from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.MIDName) |
| 39 | GuruStatus | varchar(200) | YES | Guru status from snapshot (**Dim_GuruStatus**). (Tier 2 -- SP_DepositWithdrawFee, Dim_GuruStatus.GuruStatusName) |
| 40 | PreviousTransactionStatus | varchar(200) | YES | Prior status on state (**PreviousStatus** / **PreviousStatus**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.PreviousStatus) |
| 41 | TransactionStatus | varchar(200) | YES | Current status (**DepositStatus** or **CashoutStatus**). (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositStatus / Fact_Cashout_State.CashoutStatus) |
| 42 | DepositID | int | YES | Populated on deposit rows; **NULL** on withdraw rows. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositID) |
| 43 | WithdrawPaymentID | int | YES | Populated on withdraw rows; **NULL** on deposit rows. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingWithdraw.WithdrawPaymentID) |
| 44 | CreditID | bigint | YES | Credit id from state (**CreditID**) for reconciliation to **Fact_CustomerAction**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.CreditID) |

---

## 5. Relationships

### Source tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| Fact_Deposit_State | DWH_dbo | Deposit and non-deposit transaction stream |
| Fact_Cashout_State | DWH_dbo | Withdraw and non-withdraw transaction stream |
| Fact_BillingDeposit | DWH_dbo | Deposit billing metadata |
| Fact_BillingWithdraw | DWH_dbo | Withdraw billing metadata (deduped for withdraw branch) |
| Dim_Customer | DWH_dbo | Customer external id, IP country |
| Fact_SnapshotCustomer | DWH_dbo | Regulation, label, player attributes |
| Dim_Range | DWH_dbo | Snapshot validity for modification date |
| Dim_Regulation, Dim_Label, Dim_PlayerLevel, Dim_PlayerStatus, Dim_GuruStatus | DWH_dbo | Descriptive attributes |
| Dim_Currency, Dim_FundingType, Dim_BillingDepot, Dim_CardType, Dim_Country | DWH_dbo | Reference data |
| Fact_CustomerAction | DWH_dbo | Post-load sign fixes for **PIPsCalculation** / amounts (edge cases) |

### Consumers

| Consumer | Purpose |
|----------|---------|
| Finance reporting & PIPs reconciliation | Cash movement and fee analysis by method and geography |

---

## 6. ETL & lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DepositWithdrawFee |
| **ETL pattern** | DELETE by **DateID**, INSERT union of **#deposits** and **#withdraws**, then **UPDATE** sign corrections |
| **Schedule** | Daily, Priority 99 (FinanceReportSPS) |
| **Parameter** | **@StartDate** (DATE) |
| **Delete scope** | `DELETE WHERE DateID = @StartDateID` |
| **Process log name** | **SP_DepositWithdrawFee_2025** (in **SP_ProcessStatusLog** call inside the procedure) |

---

## 7. Query advisory

| Consideration | Guidance |
|---------------|----------|
| **Filter on DateID and CID** | HASH on **CID**; **DateID** is the primary partition for daily reloads. |
| **Sign interpretation** | Always use post-**UPDATE** values; do not assume raw source sign. |
| **Reversals** | Reversal-only rows live in **BI_DB_DepositWithdrawFee_Reversals**. |
| **NULL columns** | **CreditTypeID**, **MOPCountry**, **IsGermanBaFin** are intentionally null today. |

---

## 8. Classification & status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Payments |
| **Sub-domain** | Deposits, withdrawals, fees |
| **Sensitivity** | PII-adjacent (**Customer**, **CID**, payment metadata) |
| **Owner** | Finance / Billing analytics |
| **Quality score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*


### Upstream `DWH_dbo.Fact_BillingDeposit` — synapse
- **Resolved as**: `DWH_dbo.Fact_BillingDeposit`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md`

# DWH_dbo.Fact_BillingDeposit

> Central deposit transaction fact table — 73.9M rows recording every eToro deposit attempt with full payment lifecycle state, routing details, exchange metadata, and ~90 XML-extracted payment data attributes. Updated daily from etoro.Billing.Deposit via SP_Fact_BillingDeposit_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Deposit + etoro.Billing.Funding + etoro.Billing.RecurringDeposit (SP join) |
| **Refresh** | Daily (SP_Fact_BillingDeposit_DL_To_Synapse, rolling DELETE + INSERT) |
| | |
| **Synapse Distribution** | HASH (DepositID) |
| **Synapse Index** | CLUSTERED (DepositID ASC) + NC (PaymentStatusID ASC, ExpirationDateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Fact_BillingDeposit` is the DWH's authoritative record of every deposit attempt on the eToro platform — approved, declined, pending, charged back, or refunded. With 73.9M rows, it is the primary billing analytics table, used for FTD (First Time Deposit) attribution, payment provider performance, fraud analysis, exchange revenue reporting, regulatory compliance segmentation, and customer lifecycle analytics.

The table combines data from three production sources:
1. **`Billing.Deposit`** — the core deposit ledger (direct passthrough for 35 columns)
2. **`Billing.Funding`** — payment instrument details (FundingTypeID, IsRefundExcluded, DocumentRequired, AFT flags)
3. **`Billing.RecurringDeposit`** — recurring deposit configuration (OUTER APPLY for IsRecurring flag)

Additionally, ~91 columns are extracted from XML blobs stored in `Billing.Deposit.PaymentData` and `Billing.Deposit.FundingData` using the DWH UDF `ExtractXMLValue`. These cover payment-method-specific fields that vary by funding type (credit card BIN details, bank account info, e-wallet data, etc.).

**ETL pattern** (`SP_Fact_BillingDeposit_DL_To_Synapse`):
1. DELETE rows from `Ext_FBD_Fact_BillingDeposit` for the ModificationDateID window
2. INSERT from staging into Ext_FBD (multi-source JOIN + XML extraction)
3. DELETE from main `Fact_BillingDeposit` for the window
4. INSERT from Ext_FBD into Fact_BillingDeposit
5. UPDATE `PlatformID` from `Fact_CustomerAction` WHERE ActionTypeID=14 matching on SessionID (second SP pass: `EXEC SP_Fact_BillingDeposit @Yesterday`)

**Amount capping**: As of 2025-04-17, an `Amount CASE` expression caps extreme values before storage to prevent outlier distortion in aggregations.

**PlatformID enrichment**: The platform the customer used when depositing is not stored in Billing.Deposit — it is looked up via a session-to-platform join against `Fact_CustomerAction` (ActionTypeID=14, session-based match) in a second ETL pass.

**Upstream wiki**: `Billing.Deposit` has a full upstream wiki (documented in DB_Schema) providing Tier 1 column descriptions for 35 DWH columns.

---

## 2. Business Logic

### 2.1 Deposit Status Lifecycle

**What**: Deposits progress through states from submission through approval, decline, or reversal.

**Columns Involved**: `PaymentStatusID`, `RiskManagementStatusID`, `MatchStatusID`

**Rules**:
- `PaymentStatusID=2` (Approved) is the only successful terminal state — drives customer account crediting via Billing.AmountAdd in production
- `PaymentStatusID=35` (DeclineByRRE) represents real-time risk engine declines (~10.2% of deposits)
- `PaymentStatusID=13` (Pending), `5` (InProcess): intermediate states for offline/wire deposits
- States 11-12, 26, 37-39 represent post-approval reversals (Chargeback, Refund, and their reversals)
- For full state machine, see upstream wiki: Billing.Deposit §2.1

### 2.2 First Time Deposit (FTD)

**What**: `IsFTD=1` marks the customer's first ever approved deposit — the event that triggers marketing attribution and FTD bonus eligibility.

**Columns Involved**: `IsFTD`, `CID`, `DepositID`

**Rules**:
- Only one deposit per customer can have `IsFTD=1` (monotonic guarantee from production)
- `IsFTD=0` for DepositTypeID=4 (MoneyTransfer/internal transfer) regardless of deposit history
- ~60.6% of Billing.Deposit rows have IsFTD=1 (many customers deposit exactly once)
- DWH stores this as `int` (0/1) rather than `bit` in production

### 2.3 Amount and Exchange Rate

**What**: Deposits are stored in deposit currency (CurrencyID) and pre-computed to USD (AmountUSD).

**Columns Involved**: `Amount`, `CurrencyID`, `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `AmountUSD`

**Rules**:
- `Amount` is in deposit currency; stored as MONEY (4 decimal places)
- As of 2025-04-17: Amount is capped via CASE expression before storage (prevents extreme outlier values)
- `AmountUSD = Amount × ExchangeRate` (DWH-computed in ETL)
- `BaseExchangeRate` stores the rate before fee markup; `ExchangeFee` stores the fee
- For USD deposits: ExchangeRate=1.0, AmountUSD=Amount

### 2.4 XML-Extracted Payment Data (~91 Columns)

**What**: `Billing.Deposit.PaymentData` and `FundingData` store provider-specific XML blobs. The DWH ETL extracts ~91 attributes using `ExtractXMLValue(xml_blob, attribute_name)` into dedicated nvarchar(max) columns.

**Rules**:
- Each `*AsString`, `*AsDecimal`, `*AsInteger` suffix column is a single XML attribute extracted by name
- The payment data schema varies by FundingTypeID — credit card deposits populate card-specific fields; bank wire deposits populate bank-specific fields; e-wallet deposits populate e-wallet fields
- NULL in any XML column means either: (a) the attribute doesn't exist for this funding type, or (b) it was absent from the XML for this deposit
- `ThreeDsResponseType` is a notable XML-extracted field — joins to Dim_ThreeDsResponseTypes via TRY_CAST(...AS INT)

### 2.5 Platform Attribution

**What**: `PlatformID` identifies the device/platform the customer was on when making the deposit (web, iOS, Android, etc.).

**Columns Involved**: `PlatformID`, `SessionID`

**Rules**:
- `PlatformID` is NOT from Billing.Deposit — it's populated via a second ETL pass:
  `UPDATE Fact_BillingDeposit SET PlatformID = (SELECT PlatformID FROM Fact_CustomerAction WHERE ActionTypeID=14 AND SessionID = Fact_BillingDeposit.SessionID)`
- If no matching Fact_CustomerAction row exists for the session, PlatformID remains NULL
- ActionTypeID=14 represents a "Deposit" action type in Fact_CustomerAction

### 2.6 Recurring Deposits

**What**: `IsRecurring` identifies deposits that are part of a scheduled recurring deposit plan.

**Columns Involved**: `IsRecurring`, `DepositID`

**Rules**:
- `IsRecurring = 1` when a matching row exists in `Billing.RecurringDeposit` for this deposit (OUTER APPLY)
- `IsRecurring = 0` for one-time deposits
- Recurring deposits may have DepositTypeID=3 (Recurring) or DepositTypeID=5 (RecurringInvestment)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`HASH(DepositID)` ensures even distribution — each deposit has a unique ID so this is an optimal hash key for point lookups and JOINs by deposit. The clustered index on `DepositID` makes per-deposit point lookups fast. The NC index on `(PaymentStatusID, ExpirationDateID)` supports filtered queries by status and expiration date.

**Warning**: At 73.9M rows, full-table scans are expensive. Always filter by `ModificationDateID` or `PaymentStatusID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily approved deposit volume | WHERE PaymentStatusID=2, GROUP BY ModificationDateID |
| FTD analysis | WHERE IsFTD=1 AND PaymentStatusID=2 |
| Exchange fee revenue | SUM(AmountUSD - Amount/ExchangeRate×BaseExchangeRate) |
| Regulation-specific deposits | WHERE ProcessRegulationID = @regId |
| Platform breakdown | GROUP BY PlatformID (JOIN Dim_Platform) |
| 3DS outcome analysis | TRY_CAST(ThreeDsResponseType AS INT) JOIN Dim_ThreeDsResponseTypes |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID | Customer demographics |
| DWH_dbo.Dim_Date | ON ModificationDateID | Time dimension |
| DWH_dbo.Dim_Currency | ON CurrencyID | Currency name |
| DWH_dbo.Dim_Platform | ON PlatformID | Device/platform |
| DWH_dbo.Dim_ThreeDsResponseTypes | ON TRY_CAST(ThreeDsResponseType AS INT) | 3DS outcome |

### 3.4 Gotchas

- **73.9M rows**: Always filter. Prefer ModificationDateID or ExpirationDateID index for range queries
- **XML columns are all nvarchar(max)**: Aggregating or joining on XML-extracted columns requires TRY_CAST — they are stored as strings regardless of semantic type
- **`v` column**: This unnamed column (`v`) is an XML-extracted field with no descriptive name — artifact of the XML schema. Contents unknown without domain review
- **PlatformID may be NULL**: Session-to-platform join succeeds only if the deposit session was logged in Fact_CustomerAction
- **AmountUSD is ETL-computed**: Not from production; recalculated as Amount×ExchangeRate at ETL time. For exact USD reconciliation, use Amount×ExchangeRate directly
- **ExpirationDateID formula**: Complex derived calculation from ExpirationDateAsString XML field — not a simple date conversion

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Billing.Deposit) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

**Note**: Elements are grouped by category for readability.

### 4.1 Core Deposit Identifiers & Status (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | int | YES | Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH. (Tier 1 — upstream wiki, Billing.Deposit) |
| 2 | CID | int | YES | Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer. (Tier 1 — upstream wiki, Billing.Deposit) |
| 3 | PaymentStatusID | int | YES | Current deposit status. Key values: 1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum in upstream wiki. NC index key. (Tier 1 — upstream wiki, Billing.Deposit) |
| 4 | IsFTD | int | YES | First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 in Billing.Deposit. Stored as int in DWH (vs. bit in production). (Tier 1 — upstream wiki, Billing.Deposit) |
| 5 | PaymentDate | datetime | YES | UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. (Tier 1 — upstream wiki, Billing.Deposit) |
| 6 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — upstream wiki, Billing.Deposit) |
| 7 | RiskManagementStatusID | int | YES | Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation. (Tier 1 — upstream wiki, Billing.Deposit) |
| 8 | MatchStatusID | tinyint | YES | PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.2 Amount & Currency (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 9 | Amount | money | YES | Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations. (Tier 1 — upstream wiki, Billing.Deposit) |
| 10 | CurrencyID | int | YES | Currency of the deposit amount. References DWH_dbo.Dim_Currency. 1=USD, 2=EUR, 3=GBP, etc. (Tier 1 — upstream wiki, Billing.Deposit) |
| 11 | ExchangeRate | numeric(16,8) | YES | Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 12 | BaseExchangeRate | numeric(16,8) | YES | Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019). (Tier 1 — upstream wiki, Billing.Deposit) |
| 13 | ExchangeFee | int | YES | Exchange fee in provider-specific integer encoding (basis points). Added by Adi (19/02/2019). (Tier 1 — upstream wiki, Billing.Deposit) |
| 14 | Commission | money | YES | Commission charged on this deposit. Default 0 in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 15 | AmountUSD | decimal(11,2) | YES | Deposit amount converted to USD. DWH-computed: Amount × ExchangeRate. Not from production source — pre-computed in ETL for reporting convenience. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.3 Payment Instrument & Routing (from Billing.Deposit + Billing.Funding — Tier 1 + Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 16 | FundingID | int | YES | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. (Tier 1 — upstream wiki, Billing.Deposit) |
| 17 | FundingTypeID | int | YES | Type of payment instrument. Sourced from Billing.Funding.FundingTypeID (not from Billing.Deposit directly). Categorizes the deposit by payment method (credit card, wire, ACH, etc.). (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 18 | DepotID | int | YES | Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 19 | ProtocolMIDSettingsID | int | YES | Merchant ID configuration profile. Default 0=no specific MID. Added 2018-10-24. (Tier 1 — upstream wiki, Billing.Deposit) |
| 20 | MerchantAccountID | int | YES | Merchant account legal entity for regulatory routing. Added with DBA-646. (Tier 1 — upstream wiki, Billing.Deposit) |
| 21 | RoutingReasonID | int | YES | Reason code for routing path selection. Values 1-8; 3=most common (~29%). ~31% NULL for legacy records. Added PAYUS-3061, 2021-06-15. (Tier 1 — upstream wiki, Billing.Deposit) |
| 22 | ProcessRegulationID | int | YES | Regulatory entity/jurisdiction: 1=Cyprus/EU (~63%), 2=UK/FCA (~16%), 4=AU (~2.5%), others for ASIC etc. Added DBA-646, 2021-09-05. (Tier 1 — upstream wiki, Billing.Deposit) |
| 23 | FlowID | int | YES | Deposit UX flow variant. NULL=default (98.9%), 1=new flow (0.97%), 3=specific variant. Added PAYIL-8362, 2024-04-18. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.4 Identifiers & Timestamps (from Billing.Deposit — Tier 1 + DWH Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 24 | Approved | bit | YES | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Retained for backward compatibility. (Tier 1 — upstream wiki, Billing.Deposit) |
| 25 | ProcessorValueDate | datetime | YES | Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods. (Tier 1 — upstream wiki, Billing.Deposit) |
| 26 | ClearingHouseEffectiveDate | datetime | YES | Settlement date assigned by the clearing house. NULL for instant payment methods. (Tier 1 — upstream wiki, Billing.Deposit) |
| 27 | ExTransactionID | varchar(50) | YES | External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution. (Tier 1 — upstream wiki, Billing.Deposit) |
| 28 | RefundVerificationCode | varchar(50) | YES | Verification code for refund correlation. Set by UpdateRefundDetails. NULL for non-refunded deposits. (Tier 1 — upstream wiki, Billing.Deposit) |
| 29 | IPAddress | numeric(18,0) | YES | Customer IP address at deposit time, as a 32-bit integer. Used for fraud detection. (Tier 1 — upstream wiki, Billing.Deposit) |
| 30 | SessionID | bigint | YES | Application session ID. Used for PlatformID enrichment via Fact_CustomerAction JOIN (second ETL pass). (Tier 1 — upstream wiki, Billing.Deposit) |
| 31 | ManagerID | int | YES | Operations manager who processed this deposit. 0=automated. (Tier 1 — upstream wiki, Billing.Deposit) |
| 32 | FunnelID | int | YES | Marketing funnel ID. FK to Dictionary.Funnel. (Tier 1 — upstream wiki, Billing.Deposit) |
| 33 | PaymentGeneration | int | YES | Payment infrastructure generation: 0=Gen0 (7.7%), 1=Gen1 (92%). Added 2020-04-19. (Tier 1 — upstream wiki, Billing.Deposit) |
| 34 | ModificationDateID | int | YES | ETL key. Integer YYYYMMDD derived from ModificationDate (CONVERT(INT, date)). Used for rolling-window DELETE+INSERT. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 35 | ExpirationDateID | int | YES | Integer date ID derived from ExpirationDateAsString XML attribute via a complex formula in SP. Represents card expiration date as YYYYMMDD. NC index key. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 36 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP execution. Not from production. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.5 Bonus & Campaign (from Billing.Deposit — Tier 1)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 37 | BonusStatusID | int | YES | Promotional bonus status. Values: 0=New, 1=Approved, 2=Declined, 3=Reverted. Only 239 non-zero records in production. (Tier 1 — upstream wiki, Billing.Deposit) |
| 38 | BonusAmount | money | YES | Bonus amount credited with this deposit. NULL when no bonus applies. (Tier 1 — upstream wiki, Billing.Deposit) |
| 39 | BonusErrorCode | int | YES | Error code when bonus processing fails (BonusStatusID=2). NULL when bonus succeeds or not attempted. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.6 Platform & Recurring (DWH-enriched — Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | PlatformID | int | YES | Device/platform the customer used for this deposit. NOT from Billing.Deposit — enriched via second ETL pass: JOIN Fact_CustomerAction ON SessionID WHERE ActionTypeID=14. NULL if no matching session action found. References DWH_dbo.Dim_Platform. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 41 | IsRecurring | int | YES | 1=deposit is part of a recurring schedule (OUTER APPLY on Billing.RecurringDeposit). 0=one-time deposit. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 42 | IsSetBalanceCompleted | int | YES | 1=account crediting (Billing.AmountAdd) completed for this deposit. Added DBA-646. (Tier 1 — upstream wiki, Billing.Deposit) |

### 4.7 Funding Instrument Metadata (from Billing.Funding — Tier 2)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 43 | IsRefundExcluded | int | YES | Whether this deposit is excluded from refund eligibility. Sourced from Billing.Funding.IsRefundExcluded. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 44 | DocumentRequired | int | YES | Whether documentation was required for this deposit/funding instrument. Sourced from Billing.Funding.DocumentRequired. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 45 | IsAftSupportedAsBool | bit | YES | Whether Account Funding Transaction (AFT) is supported by this funding instrument. Sourced from Billing.Funding. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 46 | IsAftEligibleAsBool | bit | YES | Whether this deposit was eligible for AFT processing. Sourced from Billing.Funding. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 47 | IsAftProcessedAsBool | bit | YES | Whether this deposit was actually processed via AFT. Sourced from Billing.Funding or Billing.Deposit. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |

### 4.8 XML-Extracted Payment Data Fields (~91 Columns — Tier 2)

The following columns are all extracted from `Billing.Deposit.PaymentData` or `FundingData` XML blobs using `ExtractXMLValue(xml_blob, 'AttributeName')`. Each column stores the string value of a single XML attribute. All are `nvarchar(max)` unless noted. NULL means the attribute was absent in the XML for this deposit/funding type.

| # | Element | Notes |
|---|---------|-------|
| 48 | SecuredCardDataAsString | Tokenized card data reference |
| 49 | BinCodeAsString | Card BIN (first 6-8 digits) |
| 50 | BinCountryIDAsInteger (int) | Country of card BIN |
| 51 | CardTypeIDAsInteger (int) | Card type ID (Visa, MC, etc.) |
| 52 | CountryIDAsInteger (int) | Customer country from payment data |
| 53 | StateIDAsInteger (int) | Customer state/province from payment data |
| 54 | BankIDAsInteger (int) | Bank identifier integer |
| 55 | AccountNameAsString | Bank account holder name |
| 56 | AccountTypeAsString | Bank account type (checking, savings) |
| 57 | BankAccountAsString | Bank account number (masked) |
| 58 | BankAddressAsString | Bank address |
| 59 | BankCodeAsDecimal | Bank code (numeric string) |
| 60 | BankDetailsAccountIDAsString | Bank details account identifier |
| 61 | BankIDAsString | Bank identifier string |
| 62 | BankNameAsString | Name of the bank |
| 63 | BICCodeAsString | SWIFT/BIC code for wire transfers |
| 64 | CIDAsString | Customer ID as string (XML cross-check) |
| 65 | v | XML-extracted field with no descriptive name (artifact) — contents require domain review |
| 66 | CustomerAddressAsString | Customer's billing address |
| 67 | CustomerNameAsString | Customer name from payment instrument |
| 68 | FundingType | Funding type label from XML |
| 69 | MaskedAccountIDAsString | Masked account/card identifier for display |
| 70 | PurseAsString | E-wallet purse/account ID |
| 71 | RoutingNumberAsString | US ACH routing number |
| 72 | SecureIDAsDecimal | Secure transaction ID (numeric string) |
| 73 | SortCodeAsString | UK bank sort code |
| 74 | AccountBalanceAsDecimal | Account balance from payment provider |
| 75 | AccountHolderAsString | Account holder name |
| 76 | AccountIDAsDecimal | Account identifier (numeric string) |
| 77 | ACHBankAccountIDAsInteger | ACH bank account reference ID |
| 78 | Address1AsString | Billing address line 1 |
| 79 | Address2AsString | Billing address line 2 |
| 80 | AdviseAsString | Payment provider advisory message |
| 81 | AvailableBalanceAsDecimal | Available balance from provider |
| 82 | BankCodeAsString | Bank code (string form) |
| 83 | BillNumberAsString | Bill/invoice number |
| 84 | BuildingNumberAsString | Building number in address |
| 85 | CardHolderPhoneNumberBodyAsString | Cardholder phone number body |
| 86 | CardHolderPhoneNumberPrefixAsString | Cardholder phone number prefix |
| 87 | CardNumberAsString | Card number (masked) |
| 88 | CityAsString | Billing city |
| 89 | CountryIDAsString | Country identifier string |
| 90 | CountryNameAsString | Country name from payment XML |
| 91 | CreatedAtAsString | Payment instrument creation timestamp |
| 92 | CurrentBalanceAsDecimal | Current balance from provider |
| 93 | CustomerIDAsString | Customer ID string from payment data |
| 94 | EmailAsString | Customer email from payment instrument |
| 95 | EndPointIDAsString | Payment provider endpoint identifier |
| 96 | ErrorCodeAsString | Provider error code on decline |
| 97 | ErrorTypeAsString | Provider error type classification |
| 98 | FirstNameAsString | Cardholder/account holder first name |
| 99 | IBANCodeAsString | IBAN for wire/SEPA transfers |
| 100 | InitialTransactionIDAsString | Initial transaction ID for recurring |
| 101 | IPAsString | Customer IP as string |
| 102 | LanguageIDAsInteger | Language ID from payment data |
| 103 | LastNameAsString | Cardholder/account holder last name |
| 104 | MD5AsString | MD5 hash from payment provider |
| 105 | PayerAsString | Payer name (PayPal/e-wallet) |
| 106 | PayerBusiness | Payer business name (PayPal) |
| 107 | PayerIDAsString | Payer identifier string |
| 108 | PayerPurseAsString | Payer purse/wallet ID |
| 109 | PayerStatus | Payer verification status |
| 110 | PaymentAmountAsDecimal | Amount from payment XML |
| 111 | PaymentDateAsDateTime | Payment date from XML |
| 112 | PaymentGuaranteeAsString | Payment guarantee code |
| 113 | PaymentModeAsInteger | Payment processing mode |
| 114 | PaymentProviderTransactionStatusAsString | Status string from provider |
| 115 | PaymentStatusAsInteger | Status integer from provider |
| 116 | PaymentTypeAsString | Payment type label from provider |
| 117 | PlaidItemIDAsString | Plaid (ACH) item identifier |
| 118 | PlaidNamesAsString | Plaid account holder names |
| 119 | PlatformIDAsInteger | Platform from payment XML (separate from PlatformID) |
| 120 | PromotionCodeAsString | Promotion/voucher code used |
| 121 | PSPCodeAsString | Payment service provider code |
| 122 | RapidFirstNameAsString | Rapid (payout) first name |
| 123 | RapidLastNameAsString | Rapid (payout) last name |
| 124 | ResponseMessageAsString | Provider response message |
| 125 | ResponseTimeAsString | Provider response time |
| 126 | SecretKeyAsString | Provider secret key (masked/reference) |
| 127 | ThreeDsAsJson | Raw 3DS authentication data as JSON string |
| 128 | ThreeDsResponseType | 3DS outcome ID as string. Cast to INT to JOIN Dim_ThreeDsResponseTypes. 15 possible values (0-14). |
| 129 | TokenAsString | Payment token from tokenization service |
| 130 | TransactionIDAsString | Provider transaction ID string |
| 131 | ZipCodeAsString | Billing postal/ZIP code |
| 132 | MOPCountry | Method-of-Payment country code |
| 133 | SwiftCodeAsString | SWIFT code for wire transfers |
| 134 | ClientBankNameAsString | Client's bank name |
| 135 | BankName | Bank name (varchar(100), not nvarchar(max)) |
| 136 | CardCategory | Card category label (varchar(50)) |

*All XML-extracted columns: Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse (ExtractXMLValue)*

---

## 5. Lineage

### 5.1 Production Sources

| Source | DWH Columns | Transform |
|--------|-------------|-----------|
| etoro.Billing.Deposit (d) | CID, CurrencyID, Commission, Approved, ModificationDate, FundingID, ExchangeRate, DepositID, ProcessorValueDate, DepotID, PaymentStatusID, ManagerID, RiskManagementStatusID, Amount (capped), PaymentDate, IPAddress, ClearingHouseEffectiveDate, IsFTD, RefundVerificationCode, MatchStatusID, BonusStatusID, BonusAmount, BonusErrorCode, ExTransactionID, BaseExchangeRate, ExchangeFee, ProtocolMIDSettingsID, FunnelID, SessionID, PaymentGeneration, ProcessRegulationID, MerchantAccountID, IsSetBalanceCompleted, RoutingReasonID, FlowID | Mostly passthrough; Amount has CASE cap |
| etoro.Billing.Funding (f) | FundingTypeID, IsRefundExcluded, DocumentRequired, IsAftSupportedAsBool, IsAftEligibleAsBool, IsAftProcessedAsBool | JOIN on FundingID |
| etoro.Billing.RecurringDeposit | IsRecurring | OUTER APPLY check |
| ETL-computed | ModificationDateID, ExpirationDateID, AmountUSD, UpdateDate | SP formulas |
| XML (d.PaymentData / d.FundingData) | ~91 XML columns | ExtractXMLValue(xml, 'attr') |
| DWH_dbo.Fact_CustomerAction (2nd pass) | PlatformID | UPDATE via SessionID JOIN, ActionTypeID=14 |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit (etoroDB-REAL, 73.9M rows)
  + etoro.Billing.Funding (payment instruments)
  + etoro.Billing.RecurringDeposit (recurring schedule)
  |
  v [Generic Pipeline — daily, 1440 min, Override]
Bronze/etoro/Billing/Deposit/
  |
  v [staging]
DWH_staging.etoro_Billing_Deposit + etoro_Billing_Funding + etoro_Billing_RecurringDeposit
  |
  v [SP_Fact_BillingDeposit_DL_To_Synapse — Pass 1]
    1. DELETE Ext_FBD (rolling window by ModificationDateID)
    2. INSERT Ext_FBD from staging (multi-source JOIN + ~91 ExtractXMLValue calls)
    3. DELETE Fact_BillingDeposit (same window)
    4. INSERT Fact_BillingDeposit from Ext_FBD
  |
  v [SP_Fact_BillingDeposit @Yesterday — Pass 2]
    UPDATE PlatformID via Fact_CustomerAction (SessionID JOIN, ActionTypeID=14)
DWH_dbo.Fact_BillingDeposit (73.9M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Current deposit status |
| RiskManagementStatusID | DWH_dbo.Dim_RiskManagementStatus | Risk engine decision |
| ModificationDateID | DWH_dbo.Dim_Date | Date dimension |
| ExpirationDateID | DWH_dbo.Dim_Date | Card expiration date |
| FundingTypeID | DWH_dbo.Dim_FundingType | Payment method type |
| PlatformID | DWH_dbo.Dim_Platform | Device/platform |
| FunnelID | DWH_dbo.Dim_Funnel | Marketing funnel |
| TRY_CAST(ThreeDsResponseType AS INT) | DWH_dbo.Dim_ThreeDsResponseTypes | 3DS authentication outcome |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Cashout_State | DepositID | Linked deposit for refund/chargeback cashouts |
| SP_Fact_BillingDeposit (2nd pass) | SessionID | Platform enrichment pass reads this table |

---

## 7. Sample Queries

### 7.1 Daily approved deposit volume (USD)

```sql
SELECT
    ModificationDateID,
    COUNT(*) AS DepositCount,
    SUM(AmountUSD) AS TotalUSD,
    SUM(CASE WHEN IsFTD=1 THEN 1 ELSE 0 END) AS FTDCount
FROM [DWH_dbo].[Fact_BillingDeposit]
WHERE PaymentStatusID = 2
  AND ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-30,GETDATE()), 112))
GROUP BY ModificationDateID
ORDER BY ModificationDateID DESC
```

### 7.2 Decline rate by regulation entity

```sql
SELECT
    ProcessRegulationID,
    COUNT(*) AS TotalDeposits,
    SUM(CASE WHEN PaymentStatusID = 2 THEN 1 ELSE 0 END) AS Approved,
    SUM(CASE WHEN PaymentStatusID = 35 THEN 1 ELSE 0 END) AS DeclinedByRRE,
    CAST(SUM(CASE WHEN PaymentStatusID = 2 THEN 1 ELSE 0 END) AS float) / COUNT(*) AS ApprovalRate
FROM [DWH_dbo].[Fact_BillingDeposit]
WHERE ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-7,GETDATE()), 112))
GROUP BY ProcessRegulationID
ORDER BY TotalDeposits DESC
```

### 7.3 3DS outc

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_BillingProtocolMIDSettingsID` — synapse
- **Resolved as**: `DWH_dbo.Dim_BillingProtocolMIDSettingsID`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingProtocolMIDSettingsID.md`

# DWH_dbo.Dim_BillingProtocolMIDSettingsID

> Payment routing MID (Merchant ID) configuration dimension. Each row defines a protocol parameter value for a (depot + mode + regulation + currency) combination, driving payment gateway selection for deposits and withdrawals. Sourced daily from etoro.Billing.ProtocolMIDSettings via SP_Dictionaries_DL_To_Synapse. ~1,851 rows.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.ProtocolMIDSettings |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DepotID) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_BillingProtocolMIDSettingsID is the DWH version of etoro.Billing.ProtocolMIDSettings -- the payment routing configuration table. It maps every combination of payment parameter + depot + trading mode + regulatory jurisdiction + currency to a specific Value (the MID, Merchant ID, or protocol identifier string) used to route transactions through a specific payment processor endpoint.

When a deposit is processed, the system looks up this table to determine which MID to use for the given depot, regulation, and currency. The ProtocolMIDSettingsID foreign key in deposit and withdrawal transaction tables references this table to record which routing configuration was used for each payment.

Source: etoro.Billing.ProtocolMIDSettings on etoroDB-REAL. Exported daily to Bronze/etoro/Billing/ProtocolMIDSettings/ and staged into DWH_staging.etoro_Billing_ProtocolMIDSettings. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern. The production ID column is renamed to ProtocolMIDSettingsID in DWH. UpdateDate is set to GETDATE() at load time.

Row composition (approximate, based on production wiki at 1,470 rows; DWH has 1,851 as of 2026-03-11):
- DepotModeID: ~60% Demo (2), ~37% Live (1), ~3% General (0)
- SubTypeID: ~94% default (0), ~6% alternate (3)
- MerchantAccountID: ~25% have a specific merchant account override; ~75% NULL

**SENSITIVE DATA**: The Value column contains MID strings, API keys, and merchant credentials. Do not include in unmasked reports or logs.

---

## 2. Business Logic

### 2.1 MID Routing Lookup

**What**: Given a depot + regulation + currency + mode, retrieve the MID/protocol string (Value) to use for payment processing.

**Columns Involved**: `ProtocolMIDSettingsID`, `ParameterID`, `DepotID`, `DepotModeID`, `RegulationID`, `CurrencyID`, `Value`, `SubTypeID`, `MerchantAccountID`

**Rules**:
- Primary lookup key: (ParameterID, DepotID, DepotModeID, RegulationID, CurrencyID) -- the logical PK from production
- CurrencyID=0 means "any currency" -- applies regardless of transaction currency
- SubTypeID=0 is the default routing path; SubTypeID=3 is an alternate routing path
- MerchantAccountID (when set) provides finer-grained routing to a specific acquiring account within a depot

**Primary reader**: Billing.GetProtocolMIDSettings(@RegulationID, @DepotID, @CurrencyID, @MerchantAccountID)

### 2.2 Depot Mode Segmentation (Live vs Demo)

**What**: Live and Demo accounts use separate MID entries to route to different processing environments.

**Columns Involved**: `DepotModeID`

| DepotModeID | Meaning | Approx Count |
|-------------|---------|-------------|
| 0 | General (applies to both modes) | ~3% |
| 1 | Live trading accounts | ~37% |
| 2 | Demo accounts | ~60% |

**Rules**:
- High Demo count (60%) reflects that demo deposits use the same routing infrastructure with sandbox MIDs
- When routing a payment, the system selects the matching DepotModeID based on whether the customer has a live or demo account

### 2.3 Regulatory Segmentation

**What**: Each regulatory entity (CySEC, FCA, ASIC, etc.) has its own set of MIDs reflecting eToro's multi-jurisdiction legal structure.

**Columns Involved**: `RegulationID`

**Rules**:
- RegulationID=0: applies to all regulations (general fallback)
- RegulationID=1: CySEC (eToro EU)
- RegulationID=2: FCA (eToro UK)
- Additional values for ASIC, FINRA, and other regulatory entities
- Ensures transactions route through the correct legal entity's acquiring relationship

### 2.4 SubTypeID and MerchantAccountID Routing

**What**: Fine-grained routing controls within a (depot, mode, regulation, currency) combination.

**Columns Involved**: `SubTypeID`, `MerchantAccountID`

**Rules**:
- SubTypeID=0: default routing (94% of rows)
- SubTypeID=3: alternate sub-routing for specific processor subsets (6% of rows)
- MerchantAccountID (when set): links to a specific merchant account in Billing.MerchantAccountValues for finer routing

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on DepotID. With ~1,851 rows, REPLICATE is acceptable -- every node holds a full copy, enabling zero-movement JOINs when filtering by DepotID. The clustered index on DepotID optimizes lookups from deposit/cashout fact tables.

**Note**: Unlike the production table (clustered on ID), the DWH clusters on DepotID. Queries by ProtocolMIDSettingsID range scans will not benefit from the clustered index; use DepotID-based lookups for best performance.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, partitioning is optional at this row count. If partitioned, partition by RegulationID or DepotID for routing lookups. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| MID config for a specific depot | WHERE DepotID = N AND DepotModeID IN (0,1) |
| All Live mode entries for a regulation | WHERE DepotModeID = 1 AND RegulationID = N |
| Entries with merchant account overrides | WHERE MerchantAccountID IS NOT NULL |
| Row count by mode | GROUP BY DepotModeID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_BillingDepot | ON Dim_BillingDepot.DepotID = Dim_BillingProtocolMIDSettingsID.DepotID | Resolve depot name and payment method |
| Fact deposit/cashout tables | ON ProtocolMIDSettingsID | Identify which MID config was used per transaction |

### 3.4 Gotchas

- **Value column is SENSITIVE**: Contains MID strings, API keys, and merchant credentials. Exclude from unmasked exports, logs, and reports.
- **ProtocolMIDSettingsID = production ID**: The DWH renames the production `ID` column to `ProtocolMIDSettingsID`. These are the same values; use ProtocolMIDSettingsID when joining to fact tables that store the original ID.
- **CurrencyID=0 = any currency**: Most rows use CurrencyID=0 as a wildcard -- they apply to all currencies, not just currency 0. Do not filter `WHERE CurrencyID = 0` expecting only "no-currency" rows.
- **UpdateDate staleness warning**: Live data as of 2026-03-18 shows UpdateDate=2026-03-11, suggesting the ETL may not have run for ~7 days. Monitor UpdateDate for freshness issues.
- **Clustered on DepotID (not ID)**: Production clusters on ID for sequential inserts; DWH clusters on DepotID for JOIN performance. This changes query plan behavior.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 stars | Tier 3 - name-inferred | (Tier 3 - name-inferred) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProtocolMIDSettingsID | int | NOT NULL | Surrogate primary key. Renamed from `ID` in the production Billing.ProtocolMIDSettings table. Referenced by fact deposit and withdrawal tables to record which routing configuration was used per transaction. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 2 | ParameterID | int | NOT NULL | Protocol parameter type. Part of logical routing key. References Billing.Parameter which defines the parameter name/type (e.g., MID, SecretKey, ApiKey). Together with DepotID, DepotModeID, RegulationID, CurrencyID forms the unique routing key. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 3 | DepotID | int | NOT NULL | Payment gateway/depot. Part of logical routing key. References Billing.Depot (DWH: Dim_BillingDepot.DepotID). Identifies the payment processor this MID configuration belongs to. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 4 | DepotModeID | tinyint | NOT NULL | Trading mode. Part of logical routing key. 0=General (applies to both), 1=Live, 2=Demo. Separates Live and Demo payment processing environments. ~60% Demo, ~37% Live. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 5 | Value | nvarchar(250) | YES | The protocol identifier string (MID, merchant ID, API key, etc.) passed to the payment processor for routing. SENSITIVE -- contains payment gateway credentials. Examples: merchant ID numbers, API endpoint identifiers. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 6 | RegulationID | int | NOT NULL | Regulatory entity. Part of logical routing key. Segments MIDs by legal jurisdiction: 0=General, 1=CySEC (EU), 2=FCA (UK), plus additional ASIC/other values. Ensures transactions route through the correct legal entity's acquiring relationship. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 7 | CurrencyID | int | NOT NULL | Currency restriction. Part of logical routing key. 0=any currency (most rows). Non-zero values restrict this MID entry to a specific transaction currency. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 8 | Description | nvarchar(250) | YES | Human-readable description of this MID entry (e.g., processor name, account identifier). Nullable; not all rows have a description. (Tier 3 - name-inferred) |
| 9 | SubTypeID | int | NOT NULL | Sub-routing type. 0=default routing (~94% of rows); 3=alternate sub-routing for specific processor subsets (~6% of rows). Allows multiple routing paths within the same (depot, mode, regulation, currency). (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 10 | MerchantAccountID | int | YES | Optional link to a specific merchant account configuration in Billing.MerchantAccountValues. When set (~25% of rows), enables finer-grained routing to a specific acquiring account within a depot. NULL when not applicable. (Tier 1 - upstream wiki, Billing.ProtocolMIDSettings) |
| 11 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Monitor for freshness -- live data as of 2026-03-18 shows last load was 2026-03-11. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ProtocolMIDSettingsID | etoro.Billing.ProtocolMIDSettings | ID | Passthrough (renamed: ID -> ProtocolMIDSettingsID) |
| ParameterID | etoro.Billing.ProtocolMIDSettings | ParameterID | Passthrough |
| DepotID | etoro.Billing.ProtocolMIDSettings | DepotID | Passthrough |
| DepotModeID | etoro.Billing.ProtocolMIDSettings | DepotModeID | Passthrough |
| Value | etoro.Billing.ProtocolMIDSettings | Value | Passthrough |
| RegulationID | etoro.Billing.ProtocolMIDSettings | RegulationID | Passthrough |
| CurrencyID | etoro.Billing.ProtocolMIDSettings | CurrencyID | Passthrough |
| Description | etoro.Billing.ProtocolMIDSettings | Description | Passthrough |
| SubTypeID | etoro.Billing.ProtocolMIDSettings | SubTypeID | Passthrough |
| MerchantAccountID | etoro.Billing.ProtocolMIDSettings | MerchantAccountID | Passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Billing.ProtocolMIDSettings -> Generic Pipeline (daily, Override) -> Bronze/etoro/Billing/ProtocolMIDSettings/ -> DWH_staging.etoro_Billing_ProtocolMIDSettings -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_BillingProtocolMIDSettingsID
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Billing.ProtocolMIDSettings | ~1,851-row MID routing config (etoroDB-REAL) |
| Lake | Bronze/etoro/Billing/ProtocolMIDSettings/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Billing_ProtocolMIDSettings | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; ID renamed to ProtocolMIDSettingsID; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_BillingProtocolMIDSettingsID | ~1,851 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ProtocolMIDSettingsID | etoro.Billing.ProtocolMIDSettings | Production source (upstream reference) |
| DepotID | DWH_dbo.Dim_BillingDepot | Payment depot dimension in DWH |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Fact deposit tables | ProtocolMIDSettingsID | Records which MID config was used per transaction |
| Fact withdrawal tables | ProtocolMIDSettingsID | Records which MID config was used per withdrawal |

---

## 7. Sample Queries

### 7.1 Row distribution by depot mode

```sql
SELECT
    DepotModeID,
    CASE DepotModeID WHEN 0 THEN 'General' WHEN 1 THEN 'Live' WHEN 2 THEN 'Demo' ELSE 'Unknown' END AS ModeName,
    COUNT(*) AS RowCount
FROM [DWH_dbo].[Dim_BillingProtocolMIDSettingsID]
GROUP BY DepotModeID
ORDER BY DepotModeID
```

### 7.2 MID configs for a specific depot (excluding sensitive Value)

```sql
SELECT
    pms.ProtocolMIDSettingsID,
    pms.ParameterID,
    pms.DepotID,
    bd.Name AS DepotName,
    pms.DepotModeID,
    pms.RegulationID,
    pms.CurrencyID,
    pms.SubTypeID,
    pms.Description
    -- Value intentionally excluded: contains sensitive MID credentials
FROM [DWH_dbo].[Dim_BillingProtocolMIDSettingsID] pms
JOIN [DWH_dbo].[Dim_BillingDepot] bd ON bd.DepotID = pms.DepotID
WHERE pms.DepotID = 7  -- Neteller
ORDER BY pms.RegulationID, pms.DepotModeID
```

### 7.3 ETL freshness check

```sql
SELECT MAX(UpdateDate) AS LastLoad, COUNT(*) AS RowCount
FROM [DWH_dbo].[Dim_BillingProtocolMIDSettingsID]
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.5/10 (4 stars) | Phases: 9/14 (P3/P5/P6/P9B/P10 skipped)*
*Tiers: 9 T1, 1 T2, 1 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 9.0/10, Relationships: 5.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_BillingProtocolMIDSettingsID | Type: Table | Production Source: etoro.Billing.ProtocolMIDSettings*


### Upstream `DWH_dbo.Dim_Regulation` — synapse
- **Resolved as**: `DWH_dbo.Dim_Regulation`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md`

# DWH_dbo.Dim_Regulation

> Lookup table defining the 15 regulatory jurisdictions under which eToro operates globally, with DWH-specific grouping (ClusterRegulationID) for analytics aggregation.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Regulation |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Regulation defines the 15 regulatory jurisdictions under which eToro operates globally. Each regulation represents a financial authority (CySEC, FCA, ASIC, FinCEN, etc.) and maps to an eToro legal entity holding the corresponding license. This classification drives multi-jurisdiction compliance - it determines which rules apply to each customer, what instruments they can trade, what leverage limits are enforced, and how their funds are segregated. (Tier 1 - upstream wiki, Dictionary.Regulation)

RegulationID is one of the most frequently joined columns in the DWH. It is assigned to users at registration (CustomerStatic.RegulationID) and propagated through every subsequent operation - deposits, trading, copy-trading, and compliance reporting. V_Dim_Customer joins Dim_Regulation to resolve the regulation name for every customer.

**DWH vs Production differences**: The DWH strips 6 columns from production (IsUSA, JurisdictionName, BankID, RegulationLongName, RegulationShortName, DefaultRegulationID) and adds 3 DWH-specific columns (DWHRegulationID = ID alias, StatusID = hardcoded 1, ClusterRegulationID = grouping logic). Analysts needing US/non-US split or jurisdiction names should reference the upstream wiki or query production via the Bronze layer.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_Regulation. All 15 rows have StatusID=1 (Active). No sentinel row.

---

## 2. Business Logic

### 2.1 ClusterRegulationID Grouping

**What**: The ETL groups certain regulations into a single cluster (ID=1) for analytics aggregation.

**Columns Involved**: `ClusterRegulationID`, `ID`

**Rules**:
- IDs 0 (None), 1 (CySEC), 5 (BVI) -> ClusterRegulationID=1 (grouped as "CySEC/BVI/None" cluster)
- All other IDs -> ClusterRegulationID = ID (each regulation is its own cluster)

**Rationale**: BVI (5) is the non-US fallback regulation for users in jurisdictions without a specific eToro entity. CySEC (1) is the primary EU regulation. None (0) is the sentinel for unassigned users. Grouping them under cluster 1 allows DWH analytics to treat these three as a single reporting unit.

```
ClusterRegulationID mapping:
  ID=0 (None)    -> Cluster 1
  ID=1 (CySEC)   -> Cluster 1
  ID=5 (BVI)     -> Cluster 1
  All others     -> Cluster = ID (FCA=2, NFA=3, ASIC=4, eToroUS=6, ...)
```

### 2.2 DWH Column Gaps vs Production

**What**: The DWH drops 6 production columns that are needed for full compliance analysis.

**Columns Dropped**:
- `IsUSA` - US/non-US jurisdiction flag (critical for instrument availability branching)
- `JurisdictionName` - eToro legal entity name (e.g., "eToro EU", "eToro UK")
- `BankID` - FK to Dictionary.Bank (custodian banking partner)
- `RegulationLongName` - Full formal name (e.g., "Cyprus Securities Exchange Commission")
- `RegulationShortName` - Abbreviated code for compact display
- `DefaultRegulationID` - Self-reference fallback (non-US->BVI, US->eToroUS)

**Impact**: DWH analytics that need US vs non-US split must either hardcode the IDs (6, 7, 8, 12, 14 are US) or join to the Bronze layer. See Section 3.4 Gotchas.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on ID. With 15 rows, REPLICATE is optimal. Join on ID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RegulationID to name in customer data | `LEFT JOIN DWH_dbo.Dim_Regulation r ON r.ID = cs.RegulationID` |
| Group analytics by regulation cluster | `GROUP BY r.ClusterRegulationID` |
| US vs non-US split (without IsUSA) | `WHERE r.ID IN (6, 7, 8, 12, 14)` for US; else non-US |
| Full customer record with regulation | Use `DWH_dbo.V_Dim_Customer` (pre-joins Dim_Regulation) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.CustomerStatic / V_Dim_Customer | ON r.ID = cs.RegulationID | Resolve regulation name per customer |
| DWH_dbo.V_Dim_Customer | Dim_Regulation already joined (INNER JOIN on RegulationID) | Use view instead of re-joining |

### 3.4 Gotchas

- **IsUSA not in DWH**: Production Dictionary.Regulation.IsUSA (US=1, non-US=0) is dropped by ETL. DWH analysts must hardcode: US regulations = IDs 6, 7, 8, 12, 14.
- **DWHRegulationID = ID**: These two columns always have the same value. DWHRegulationID is an ETL alias and appears redundant. Prefer ID for joins.
- **StatusID always 1**: Hardcoded Active for all rows. Not a meaningful filter.
- **Cluster 1 includes 3 regulations**: ClusterRegulationID=1 covers None (0), CySEC (1), and BVI (5). Aggregating by ClusterRegulationID will merge these three.
- **V_Dim_Customer uses INNER JOIN**: V_Dim_Customer has `INNER JOIN Dim_Regulation ON ID = RegulationID`. Customers with NULL RegulationID would be excluded.
- **Production has 6 more columns**: If you need IsUSA, JurisdictionName, or DefaultRegulationID, use the Bronze/staging layer or etoro.Dictionary.Regulation directly.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.Regulation)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 2 | Name | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 3 | DWHRegulationID | tinyint | YES | ETL-computed alias of ID - always equals ID. `[ID] as [DWHRegulationID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field not present in production. Use ID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded 1 (Active) for all rows by ETL (`1 as [StatusID]`). Not present in production Dictionary.Regulation. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Same value as UpdateDate since table is TRUNCATE+INSERTed daily. Not present in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | ClusterRegulationID | tinyint | YES | ETL-computed grouping: `CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END`. Groups None (0), CySEC (1), and BVI (5) into cluster 1. All other regulations map to their own ID. Used for analytics aggregation where BVI/CySEC/None are treated as a single reporting unit. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | etoro.Dictionary.Regulation | ID | passthrough |
| Name | etoro.Dictionary.Regulation | Name | passthrough |
| DWHRegulationID | - | - | ETL-computed: [ID] aliased as DWHRegulationID |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |
| ClusterRegulationID | - | - | ETL-computed: CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END |

**Lost from production** (dropped by ETL):

| Production Column | Type | Reason Dropped |
|-------------------|------|----------------|
| IsUSA | tinyint | Not carried to DWH; hardcode IDs 6,7,8,12,14 for US |
| JurisdictionName | varchar(30) | Not carried to DWH |
| BankID | int | Not carried to DWH |
| RegulationLongName | varchar(100) | Not carried to DWH |
| RegulationShortName | varchar(50) | Not carried to DWH |
| DefaultRegulationID | int | Not carried to DWH |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.Regulation.md (quality 9.2, 15 rows documented)

### 5.2 ETL Pipeline

```
etoro.Dictionary.Regulation -> Generic Pipeline -> DWH_staging.etoro_Dictionary_Regulation -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_Regulation
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Regulation | 15 current rows (IDs 0-14) |
| Staging | DWH_staging.etoro_Dictionary_Regulation | Raw import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds DWHRegulationID, StatusID, InsertDate, UpdateDate, ClusterRegulationID. Drops 6 production columns. |
| Target | DWH_dbo.Dim_Regulation | 15 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - production FKs (BankID, DefaultRegulationID) are dropped by ETL.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | ID (INNER JOIN on RegulationID) | Pre-joined customer view resolves regulation name |
| DWH_dbo.CustomerStatic | RegulationID | Every customer assigned a regulation at registration |

---

## 7. Sample Queries

### 7.1 List all regulations with cluster groupings
```sql
SELECT
    ID,
    Name,
    DWHRegulationID,
    ClusterRegulationID,
    StatusID
FROM [DWH_dbo].[Dim_Regulation]
ORDER BY ID
```

### 7.2 US vs non-US regulation breakdown
```sql
SELECT
    CASE WHEN ID IN (6, 7, 8, 12, 14) THEN 'US' ELSE 'Non-US' END AS Region,
    ID,
    Name
FROM [DWH_dbo].[Dim_Regulation]
WHERE ID > 0
ORDER BY Region, ID
```

### 7.3 Customer count by regulation cluster
```sql
SELECT
    r.ClusterRegulationID,
    r.Name AS PrimaryRegulationName,
    COUNT(DISTINCT cs.CustomerID) AS customer_count
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_Regulation] r ON r.ID = cs.RegulationID
GROUP BY r.ClusterRegulationID, r.Name
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 2 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Regulation | Type: Table | Production Source: etoro.Dictionary.Regulation*


### Upstream `DWH_dbo.Fact_CustomerAction` — synapse
- **Resolved as**: `DWH_dbo.Fact_CustomerAction`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`

# DWH_dbo.Fact_CustomerAction

> The central customer activity fact table in the Synapse DWH, recording every significant user action — position opens/closes, logins, deposits, cashouts, fees, bonuses, social engagement, copy-trade operations, and more — as one row per event.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Row Count** | ~11 billion |
| **Production Sources** | `History.Credit` (via `History.ActiveCredit`), `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `STS_Audit_UserOperationsData` (logins), `Billing.Login` (cashier logins), `Customer.CustomerStatic` (registrations) |
| **Refresh** | Daily (midnight ETL via SWITCH partition) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE + 4 nonclustered |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **UC Format** | Delta |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` |
| **UC Table Type** | EXTERNAL |

---

## 1. Business Meaning

`DWH_dbo.Fact_CustomerAction` is the unified customer event log for the eToro platform. Every significant action a customer performs — opening a position, closing a position, depositing money, withdrawing, logging in, publishing a social post, receiving a fee, getting a bonus, registering an account — is captured as a single row in this table. It answers: "What did this customer do, when, and what were the financial details?"

The table consolidates events from five distinct production sources into a single ActionTypeID-driven schema:
1. **Position opens** (ActionTypeID 1-3, 39): From `Trade.OpenPositionEndOfDay` via the Generic Pipeline + staging
2. **Position closes** (ActionTypeID 4-6, 28, 40): From `History.ClosePositionEndOfDay` via the Generic Pipeline + staging
3. **Credit/financial events** (ActionTypeID 7-13, 15-20, 27, 30, 32, 34-38, 42-45): From `History.Credit` (which unions `History.ActiveCredit` + archived Credit partition tables back to 2007)
4. **Logins** (ActionTypeID 14): From `STS_Audit_UserOperationsData` (Session Tracking Service) with platform/browser detection
5. **Registrations** (ActionTypeID 41): From `Customer.CustomerStatic`

Because the table unions fundamentally different event types, **most columns are only populated for specific ActionTypeIDs**. Position-related columns (InstrumentID, Leverage, Commission, IsBuy, etc.) are NULL/0 for non-position events. Fee-specific columns (IsFeeDividend, DividendID) are only set for ActionTypeID=35. This is a sparse fact table by design.

The data originates from production systems, flows through the Azure Data Lake and DWH staging tables, and is loaded by `SP_Fact_CustomerAction_DL_To_Synapse` (staging extract) and `SP_Fact_CustomerAction` (transform + load). Post-load, `SP_Fact_CustomerAction_IsParitalCloseParent` marks partial-close parents. The load uses SWITCH partition for daily increments.

---

## 2. Business Logic

### 2.1 ActionTypeID — Event Classification

**What**: Every row is classified by ActionTypeID, which determines what type of customer action occurred and which columns are populated.

**Columns Involved**: `ActionTypeID`, mapped via `DWH_dbo.Dim_ActionType`

**Rules**:

| ActionTypeID | Name | Category | Source |
|---|---|---|---|
| 1 | ManualPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID=0 |
| 2 | CopyPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID>0, OrigParentPositionID>0 |
| 3 | CopyPlusPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID>0 |
| 4 | ManualPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 5 | CopyPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 6 | CopyPlusPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 7 | Deposit | Deposit | History.Credit (CreditTypeID=1) |
| 8 | Cashout | Cashout | History.Credit (CreditTypeID=2) |
| 9 | Bonus | Bonus | History.Credit (CreditTypeID=7) |
| 10 | Cashout request | Cashout request | History.Credit (CreditTypeID=9) |
| 11 | Chargeback | Chargeback | History.Credit (CreditTypeID=11) |
| 12 | Refund | Refund | History.Credit (CreditTypeID=12) |
| 14 | LoggedIn | LoggedIn | STS_Audit_UserOperationsData |
| 15 | Account balance to mirror | Mirror ops | History.Credit (CreditTypeID=18) |
| 16 | Mirror balance to account | Mirror ops | History.Credit (CreditTypeID=19) |
| 17 | Register new mirror | Mirror ops | History.Credit (CreditTypeID=20) |
| 18 | Unregister mirror | Mirror ops | History.Credit (CreditTypeID=21) |
| 19 | Detach position from mirror | DetachPosition | History.Credit |
| 21-26 | Publish Post/Comment/Like, Received Post/Comment/Like | Social engagement | **DEAD DATA** — legacy rows exist but no longer updated. No active ETL. |
| 27 | DepositAttempt | DepositAttempt | History.Credit |
| 28 | DetachedPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 29 | Cashier Loggin | Cashier login | Billing.Login |
| 30 | Processed Cashout | Processed Cashout | History.Credit (CreditTypeID=2 processed) |
| 32 | Edit StopLoss | Edit StopLoss | History.Credit (CreditTypeID=13) |
| 34 | Open Stock Order | Stock order | History.Credit (CreditTypeID=29) |
| 35 | End Of The Week Fee | Fees | History.Credit (CreditTypeID=14) — overnight, weekend, dividend, SDRT, ticket fees |
| 36 | Compensation | Compensation | History.Credit (CreditTypeID=6) |
| 37 | Reverse cashout | Reverse cashout | History.Credit (CreditTypeID=8) |
| 38 | Affiliate Deposit | Deposit | History.Credit |
| 39 | PositionOpenTypeUnknown | PositionOpen | Position open without matching History.Credit (fix at weekly maintenance) |
| 40 | PositionCloseTypeUnknown | PositionClose | Position close without matching History.Credit |
| 41 | Customer Registration | Registration | Customer.CustomerStatic |
| 42 | Cashout Rollback | Chargeback | History.Credit (CreditTypeID=33) |
| 43 | Reverse Deposit | Reverse Deposit | History.Credit (CreditTypeID=32) |
| 44 | InternalDeposit | Deposit | History.Credit (MoveMoneyReasonID=5) |
| 45 | InternalWithdraw | Withdraw | History.Credit (MoveMoneyReasonID=5) |

### 2.2 IsFeeDividend — Fee Sub-Classification

**What**: For ActionTypeID=35 (End of Week Fee), classifies the specific fee type.

**Columns Involved**: `IsFeeDividend`, `Description`

**Rules** (per DSM-1463):
- `1` = Overnight/weekend fee (Description: "Over night fee", "Weekend fee")
- `2` = Dividend payment (Description LIKE '%dividend%')
- `3` = SDRT charge (Description LIKE '%sdrt%')
- `4` = Ticket fees (Description: "OpenTotalFees" or "CloseTotalFees")
- `NULL` = Not ActionTypeID=35

### 2.3 Position-Derived Columns (Shared with Dim_Position)

**What**: ~33 columns in Fact_CustomerAction are copies of the same data from `Trade.OpenPositionEndOfDay` / `History.ClosePositionEndOfDay` that also populates `DWH_dbo.Dim_Position`. These columns display the same data under the same column names but are populated independently at ETL time.

**Shared columns**: `PositionID`, `InstrumentID`, `Amount`, `Leverage`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `MirrorID`, `IsSettled`, `InitialUnits`, `IsDiscounted`, `CommissionByUnits`, `FullCommissionByUnits`, `RegulationIDOnOpen`, `ReopenForPositionID`, `IsReOpen`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `OriginalPositionID`, `IsPartialCloseParent`, `IsPartialCloseChild`, `IsAirDrop`, `SettlementTypeID`, `DLTOpen`, `DLTClose`, `OpenMarkupByUnits`, `IsBuy`, `NetProfit`, `RedeemStatus`, `RedeemID`, `IsRedeem`

**Rules**:
- These columns are ONLY populated for position events (ActionTypeID IN 1-6, 28, 39, 40)
- For non-position events, these columns are 0 or NULL
- The ETL joins from staging tables directly — NOT from Dim_Position itself
- Column meanings are identical to Dim_Position (see `Dim_Position.md` for detailed descriptions)

### 2.4 PlatformID — Product/Platform Resolution

**What**: Identifies which product/platform the action originated from. Badly named — it's actually a FK to `Dim_Product.ProductID`, not a standalone platform enum.

**Columns Involved**: `PlatformID`

**Rules**:
- Only populated for ActionTypeID=14 (logins) and 41 (registrations)
- Resolve via JOIN to `DWH_dbo.Dim_Product` — provides Product, Platform, and SubPlatform columns
- Do NOT hard-code value mappings (101=Android, etc.) — always JOIN to Dim_Product

**Query pattern**:
```sql
SELECT dp.Product, dp.Platform, dp.SubPlatform, fca.*
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Product dp ON fca.PlatformID = dp.ProductID
WHERE fca.ActionTypeID = 14
```

### 2.6 Reopen Commission Adjustment

**What**: For reopened positions (IsReOpen=1), the commission at close is adjusted.

**Columns Involved**: `CommissionOnClose`, `FullCommissionOnClose`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `IsReOpen`, `ReopenForPositionID`

**Rules**:
- `CommissionOnClose = new_position.CommissionOnClose - original_position.CommissionOnClose`
- `CommissionOnCloseOrig` / `FullCommissionOnCloseOrig` preserve original values

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX + 4 nonclustered indexes (`ActionTypeID+DateID`, `ActionTypeID`, `CompensationReasonID`, `RealCID+DateID`). Always include `RealCID` in WHERE or JOIN for optimal single-distribution queries. The columnstore index enables efficient analytical scans across the ~11B rows.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is stored as **Delta** (EXTERNAL, ~430 GB, ~7K files), partitioned by `etr_y`, `etr_ym`, `etr_ymd` (year, year-month, year-month-day). Always include partition columns in WHERE clauses for partition pruning — e.g., `WHERE etr_y = '2025' AND etr_ym = '202503'` will skip scanning irrelevant partitions. Given the table's ~11B rows, partition pruning is critical for any practical query. The partition columns are Databricks-layer additions not present in the Synapse source. Deletion vectors are enabled (`delta.enableDeletionVectors = true`).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All logins for a customer | `WHERE ActionTypeID = 14 AND RealCID = @cid` |
| Position opens in a date range | `WHERE ActionTypeID IN (1,2,3) AND DateID BETWEEN @start AND @end` |
| Revenue (commissions) | `WHERE ActionTypeID IN (1,2,3,4,5,6,28) AND Commission > 0` |
| Deposits for a customer | `WHERE ActionTypeID = 7 AND RealCID = @cid` |
| Overnight fees | `WHERE ActionTypeID = 35 AND IsFeeDividend = 1` |
| Dividend payments | `WHERE ActionTypeID = 35 AND IsFeeDividend = 2` |
| First-time deposits (FTD) | `WHERE IsFTD = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_ActionType` | `ON fca.ActionTypeID = dat.ActionTypeID` | Action type name and category |
| `DWH_dbo.Dim_Customer` | `ON fca.RealCID = dc.RealCID` | Customer demographics, country |
| `DWH_dbo.Dim_Instrument` | `ON fca.InstrumentID = di.InstrumentID` | Instrument name (position events only) |
| `DWH_dbo.Dim_Position` | `ON fca.PositionID = dp.PositionID` | Full position details (avoid when possible — heavy join on 11B rows) |
| `DWH_dbo.Dim_BonusType` | `ON fca.BonusTypeID = dbt.BonusTypeID` | Bonus type name, IsWithdrawable (bonus events only) |
| `DWH_dbo.Dim_Campaign` | `ON fca.CampaignID = dcm.CampaignID` | Campaign code, description, dates |
| `DWH_dbo.Dim_Country` | `ON fca.CountryIDByIP = dco.CountryID` | Country name from IP geolocation |
| `DWH_dbo.Dim_FundingType` | `ON fca.FundingTypeID = dft.FundingTypeID` | Payment method name (deposit/cashout events) |
| `DWH_dbo.Dim_PaymentStatus` | `ON fca.PaymentStatusID = dps.PaymentStatusID` | Payment status name |
| `DWH_dbo.Dim_Product` | `ON fca.PlatformID = dp.ProductID` | Product, Platform, SubPlatform (logins/registrations only) |
| `DWH_dbo.Dim_Date` | `ON fca.DateID = dd.DateID` | Calendar attributes |
| `DWH_dbo.Dim_Regulation` | `ON fca.RegulationIDOnOpen = dr.ID` | Regulation name |

### 3.4 Gotchas

- **Most columns are only populated for specific ActionTypeIDs.** InstrumentID, Leverage, Commission, IsBuy are all 0/NULL for logins, deposits, social events, etc.
- **11 billion rows** — always filter by ActionTypeID + DateID to avoid full scans
- **IsReal is always 1** in this table — it only contains real-account actions (no demo)
- **Leverage=0 means non-position event**, not "no leverage". For actual position opens, Leverage=1 means no leverage (real ownership)
- **IsBuy NULL** means non-position event. For position events: True=Buy, False=Sell
- **Description is sparse** — only populated for fee events (ActionTypeID=35) and a few others. Contains human-readable strings like "Over night fee", "Payment caused by dividend", "OpenTotalFees"
- **PlatformTypeID** vs **PlatformID**: PlatformTypeID is a legacy field (0=default, 99=STS); PlatformID is a FK to `Dim_Product.ProductID` (badly named — always JOIN to Dim_Product, don't hard-code values)
- **StatusID is nearly always 1** (~11B rows with StatusID=1, ~2M NULL)
- **DemoCID is always 0** (real accounts only)
- **HistoryID is NOT unique** — despite being intended as a key, it contains duplicates. Never use it for JOINs, deduplication, or row identification

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | decimal(38,0) | NO | Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert) |
| 2 | GCID | int | NO | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 3 | RealCID | int | NO | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | DemoCID | int | NO | Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 5 | Occurred | datetime | NO | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 6 | IPNumber | bigint | YES | IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login) |
| 7 | IsReal | tinyint | NO | Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 8 | ActionTypeID | smallint | NO | Event type classifier. References `DWH_dbo.Dim_ActionType.ActionTypeID` — JOIN for Name, Category, CategoryID. See Section 2.1 for full mapping. Key filter column — drives which other columns are populated. (Tier 1 — ETL-derived from CreditTypeID/source) |
| 9 | PlatformTypeID | smallint | NO | Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms. (Tier 3 — ETL-assigned) |
| 10 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 11 | Amount | decimal(11,2) | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl) |
| 12 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 13 | NetProfit | money | NO | Realized PnL. 0 when open; set on close. In position currency. (Tier 1 — Trade.PositionTbl) |
| 14 | Commission | money | NO | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 — Trade.PositionTbl) |
| 15 | PositionID | bigint | NO | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 16 | CampaignID | int | NO | Marketing campaign identifier. 0 if not campaign-related. References `DWH_dbo.Dim_Campaign.CampaignID` — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive. (Tier 5 — domain expert) |
| 17 | BonusTypeID | smallint | NO | Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus events. References `DWH_dbo.Dim_BonusType.BonusTypeID` — JOIN for Name, IsWithdrawable, IsActive. (Tier 5 — domain expert) |
| 18 | FundingTypeID | smallint | NO | Payment method used for deposits/withdrawals. 0 for non-deposit events. References `DWH_dbo.Dim_FundingType.FundingTypeID` — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive. (Tier 5 — domain expert) |
| 19 | LoginID | int | NO | Login session identifier from `Billing.Login`. 0 for non-login events. (Tier 1 — Billing.Login) |
| 20 | MirrorID | int | NO | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 21 | WithdrawID | int | NO | Withdrawal request ID for cashout events. 0 for non-cashout events. (Tier 1 — History.Credit) |
| 22 | DurationInSeconds | int | YES | Duration of a login session in seconds. NULL for non-login events. (Tier 1 — Billing.Login) |
| 23 | PostID | uniqueidentifier | YES | Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. (Tier 1 — Social platform) |
| 24 | CaseID | int | NO | CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise. (Tier 1 — CRM) |
| 25 | UpdateDate | datetime | NO | UTC timestamp of the last DWH ETL update for this row. Set to `GETUTCDATE()` during each ETL run. (Tier 2 — ETL-assigned) |
| 26 | DateID | int | NO | Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. (Tier 2 — ETL-computed) |
| 27 | TimeID | int | NO | Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`. (Tier 2 — ETL-computed) |
| 28 | StatusID | tinyint | YES | Row status. Nearly always 1 (active). NULL for ~2M rows. (Tier 3 — ETL-assigned) |
| 29 | PreviousOccurred | datetime | YES | Deprecated/unused column. NULL for most rows — not reliably populated. Do not use. (Tier 5 — domain expert) |
| 30 | CompensationReasonID | int | NO | Compensation reason for compensation events (ActionTypeID=36) and position opens (for airdrop identification). References `BackOffice.CompensationReason`. 0 for non-compensation events. (Tier 1 — History.Credit, updated 2025-12-21) |
| 31 | WithdrawPaymentID | int | NO | Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL. (Tier 1 — History.Credit) |
| 32 | CommissionOnClose | money | NO | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 33 | IsPlug | bit | YES | Deprecated/unused column. Always NULL. (Tier 5 — domain expert) |
| 34 | DepositID | int | YES | Deposit transaction identifier. NULL for non-deposit events. (Tier 1 — History.Credit) |
| 35 | PostRootID | varchar(200) | YES | Root post ID for social engagement events. NULL for non-social events. (Tier 1 — Social platform) |
| 36 | FullCommission | money | YES | Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 — Trade.PositionTbl) |
| 37 | FullCommissionOnClose | money | YES | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 38 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 39 | RedeemStatus | int | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 40 | SessionID | bigint | YES | STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events. (Tier 1 — STS) |
| 41 | IsRedeem | int | YES | Redeem flag. 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as `Dim_Position.IsRedeem` (via RedeemStatus mapping). (Tier 3 — ETL-derived) |
| 42 | RegulationIDOnOpen | int | YES | Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer's regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 43 | PlatformID | int | YES | Product/platform identifier — badly named, actually references `Dim_Product.ProductID` (not a standalone platform enum). Resolves to Product, Platform, and SubPlatform via JOIN to `DWH_dbo.Dim_Product`. Only populated for ActionTypeID=14 (logins) and 41 (registrations). (Tier 5 — domain expert) |
| 44 | ReopenForPositionID | bigint | YES | When position was reopened: references the erroneously closed PositionID. (Tier 1 — Trade.PositionTbl) |
| 45 | IsReOpen | int | YES | 1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 46 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 47 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reopen. ETL default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 48 | OriginalPositionID | bigint | YES | Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 49 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 50 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 51 | InitialUnits | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl) |
| 52 | PaymentStatusID | int | YES | Payment processing status for deposit/cashout events. NULL for non-payment events. References `DWH_dbo.Dim_PaymentStatus.PaymentStatusID` — JOIN for Name. (Tier 5 — domain expert) |
| 53 | IsDiscounted | int | YES | 1=position received a discounted rate. DWH note: CAST from bit to int. (Tier 1 — Trade.PositionTbl) |
| 54 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 55 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 56 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 57 | IsFTD | int | YES | First-Time Deposit flag: 1 = this is the customer's first deposit. NULL for non-deposit events. (Tier 2 — ETL-computed) |
| 58 | CountryIDByIP | int | YES | Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID` — JOIN for country name. Also see `DWH_dbo.Dim_CountryIP` for IP-to-country resolution. (Tier 5 — domain expert) |
| 59 | IsAnonymousIP | int | YES | Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows. (Tier 1 — IP geolocation) |
| 60 | ProxyType | varchar(3) | YES | Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections. (Tier 1 — STS) |
| 61 | IsFeeDividend | int | YES | Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See Section 2.2 and DSM-1463. (Tier 2 — ETL-derived from Description) |
| 62 | IsAirDrop | int | YES | 1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 63 | DividendID | int | YES | Dividend event identifier for dividend-related fees. NULL for non-dividend events. (Tier 1 — Trade positions) |
| 64 | MoveMoneyReasonID | int | YES | Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. References `Dictionary.MoveMoneyReason`. (Tier 1 — History.Credit) |
| 65 | SettlementTypeID | int | YES | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 — Trade.PositionTbl) |
| 66 | DLTOpen | smallint | YES | DLT flag at open. Added 2024-06-02 (Ofir A). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 67 | DLTClose | smallint | YES | DLT flag at close. Added 2024-06-02. NULL for open positions and older positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 68 | OpenMarkupByUnits | money | YES | Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 — Trade.Position) |
| 69 | Description | varchar(255) | YES | Human-readable description. Populated mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". For ActionTypeID=32: "edit stop loss by customer". For deposits: "Processed By eToro.Payments.Deposit", etc. (Tier 1 — History.Credit, added 2024-08) |
| 70 | IsBuy | bit | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 71 | CreditID | bigint | YES | Reference to the source `History.Credit.CreditID`. Enables join back to credit history for audit. (Tier 1 — History.Credit, added 2025-07) |

---

## 5. Relationships

### 5.1 References To

| Target Object | Join Column | Purpose |
|--------------|-------------|---------|
| DWH_dbo.Dim_ActionType | ActionTypeID | Action type name and category |
| DWH_dbo.Dim_Customer | RealCID | Customer demographics, country, regulation |
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument name, type (position events only) |
| DWH_dbo.Dim_Position | PositionID | Full position details (position events only) |
| DWH_dbo.Dim_Product | PlatformID → ProductID | Product, Platform, SubPlatform (badly named FK) |
| DWH_dbo.Dim_Regulation | RegulationIDOnOpen | Regulation name at event time |
| DWH_dbo.Dim_Date | DateID | Calendar attributes |
| DWH_dbo.Dim_BonusType | BonusTypeID | Bonus type name, IsWithdrawable, IsActive |
| DWH_dbo.Dim_Campaign | CampaignID | Campaign code, description, dates, bonus amount |
| DWH_dbo.Dim_Country | CountryIDByIP → CountryID | Country name (IP geolocation) |
| DWH_dbo.Dim_FundingType | FundingTypeID | Payment method name and properties |
| DWH_dbo.Dim_PaymentStatus | PaymentStatusID | Payment status name |
| Dictionary.CreditType | (via CreditID → History.Credit) | Credit type classification |
| Dictionary.MoveMoneyReason | MoveMoneyReasonID | Money movement reason |

### 5.2 Referenced By

| Source Object | Type | Usage |
|--------------|------|-------|
| BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | Function | First deposit across platforms |
| BI_DB_dbo.Function_Population_Active_Traders | Function | Active trader population |
| BI_DB_dbo.Function_Population_First_Time_Funded | Function | FTD population |
| BI_DB_dbo.Function_Population_First_Trading_Action | Function | First trading action |
| BI_DB_dbo.Function_Population_OTD_DateRange | Function | OTD date range population |
| BI_DB_dbo.Function_Revenue_Commissions | Function | Commission revenue calculation |
| BI_DB_dbo.Function_Revenue_FullCommissions | Function | Full commission revenue |
| BI_DB_dbo.Function_Revenue_CashoutFee_* | Function | Cashout fee revenue |
| BI_DB_dbo.Function_Revenue_DormantFee | Function | Dormant fee revenue |
| BI_DB_dbo.Function_Revenue_Share_Lending | Function | Share lending revenue |
| BI_DB_dbo.Function_Revenue_TransferCoinFee | Function | Crypto transfer fee revenue |
| BI_DB_dbo.V_C2P_Positions | View | CRM-to-position mapping |
| DWH_dbo.V_FCA_NumOfLogins_mean_1q | View | Average login count (1 quarter) |
| DWH_dbo.SP_Fact_FirstCustomerAction | SP | First action per customer |
| DWH_dbo.Fact_FirstCustomerAction | Table | Derivative table: first action per customer per type |

---

## 6. Dependencies

### 6.1 ETL Pipeline

```
Production Sources:
  History.ActiveCredit + Archive Credit Tables (2007-2022Q1)
    → History.Credit (view, UNION ALL)
      → Generic Pipeline → DWH_staging.Ext_FCA_Real_History_Credit_ForFactAction
  
  Trade.PositionTbl → Trade.OpenPositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_Trade_OpenPositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Trade_Position
  
  History.Position_Active → History.ClosePositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_History_ClosePositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_History_Position
  
  STS_Audit_UserOperationsData (Session Tracking Service)
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Audit_Loggin
  
  Billing.Login → DWH_staging.etoro_Billing_Login
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Cashier_Loggin
  
  Customer.CustomerStatic → DWH_staging.etoro_Customer_CustomerStatic
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Customer_Registration

All staging → SP_Fact_CustomerAction → Ext_FCA_Fact_CustomerAction
  → SP_Fact_CustomerAction_SWITCH → Fact_CustomerAction (SWITCH partition)
  → SP_Fact_CustomerAction_IsParitalCloseParent (post-load update)
```

### 6.2 ETL Stored Procedures

| SP | Role |
|----|------|
| SP_Fact_CustomerAction_DL_To_Synapse | Stage 1: Extract data from lake staging tables into Ext_FCA_* intermediate tables |
| SP_Fact_CustomerAction | Stage 2: Transform and load into Ext_FCA_Fact_C

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Fact_SnapshotCustomer` — synapse
- **Resolved as**: `DWH_dbo.Fact_SnapshotCustomer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md`

# DWH_dbo.Fact_SnapshotCustomer

> Daily SCD Type 2 snapshot of every eToro customer's current state — the central customer-attribute table powering regulatory reporting, risk, and analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Ext_FSC_Real_Customer_Customer (CC), Ext_FSC_BackOffice_Customer (BO), Ext_FSC_BackOffice_RegulationChangeLog, Ext_FSC_Customer_FirstTimeDeposits, Ext_FSC_PhoneCustomer, Ext_FSC_StocksLending, Ext_Dim_Customer_CustomerIdentification_DLT |
| **Refresh** | Daily via MERGE (SP_Fact_SnapshotCustomer), orchestrated by SP_Fact_SnapshotCustomer_DL_To_Synapse |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX + NCI(RealCID ASC) |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked; matches `_generic_pipeline_mapping.json` generic_id=1115, `business_group` DWH). Unmasked PII export: `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid`. |
| **UC Format** | delta |
| **UC Partitioned By** | N/A (view is unpartitioned) |
| **UC Table Type** | Two UC targets: `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` (unmasked) + `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked) |

---

## 1. Business Meaning

Fact_SnapshotCustomer is the central customer state table in the DWH. For every eToro customer (RealCID), it holds one row per distinct attribute state within a year, recording which attributes were active between FromDate and ToDate (encoded together in `DateRangeID`). The pattern is SCD Type 2 by year: each year's rows are closed as attribute changes occur, and a new open row is created with the updated state. At year-end, all open rows are closed and reopened with the new year's date range.

As of 2026-03-19: **406M+ total rows**, **46.4M distinct customers**, data from **2007-08-22 to present**. 302M rows are "currently open" (ToDate = year-end). 11.9% of current open rows represent depositors; 98.0% are valid customers (IsValidCustomer=1).

The SP loads data from 6 source systems via staging Ext_FSC tables pre-populated by SP_Fact_SnapshotCustomer_DL_To_Synapse. The core CC (Customer Core) source provides demographics and status; the BO (Back Office) source provides risk/compliance attributes. RegulationID is taken from RegulationChangeLog — **not** from Back Office — because regulation changes take effect end-of-day.

8 legacy columns (DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist) are present in the DDL but NOT populated by the current SP. They carry DEFAULT (0) values.

---

## 2. Business Logic

### 2.1 SCD Type 2 Pattern — DateRangeID

**What**: Each customer-state row has a DateRangeID encoding both the open date (FromDate) and close date (ToDate) as a 12-digit bigint.

**Columns Involved**: `DateRangeID`, `RealCID`

**Rules**:
- DateRangeID = `YYYYMMDD` (open date, 8 chars) + `MMDDD` (year-end month+day, 4 chars) → e.g., `202603101231` = opened 2026-03-10, closes 2026-12-31
- When an attribute changes, the SP updates DateRangeID of the existing row to close it (right 4 chars become yesterday's MMDD), then inserts a new row with today's open date + year-end
- To get the **most current row** per customer: `RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'`
- On January 1st: all prior year's open rows are closed (12-31) and re-opened for the new year
- The `Dim_Range` dimension table stores FromDateID + ToDateID for each DateRangeID

### 2.2 IsValidCustomer — Segment Flag

**What**: Computed flag indicating whether a customer is a "valid" retail customer for analytics (excludes demo, blocked countries, excluded labels).

**Columns Involved**: `IsValidCustomer`, `PlayerLevelID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsValidCustomer = 1 IF:
  PlayerLevelID <> 4 (not demo)
  AND LabelID NOT IN (30, 26) (not internal/excluded label)
  AND CountryID <> 250 (not blocked country)
ELSE 0
```
Pre-2020-03-14 rule additionally excluded AccountTypeID=9.

### 2.3 IsCreditReportValidCB — Credit Reporting Flag

**What**: Flag indicating whether a customer is eligible for credit report validation (CB = CreditBureau context).

**Columns Involved**: `IsCreditReportValidCB`, `PlayerLevelID`, `AccountTypeID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsCreditReportValidCB = 1 IF:
  NOT (PlayerLevelID = 4 AND AccountTypeID <> 2)  (not non-real demo)
  AND LabelID NOT IN (26, 30)
  AND NOT (CountryID = 250 AND CID NOT IN (3400616, 10526243))
ELSE 0
```

### 2.4 RegulationID — End-of-Day Rule

**What**: A customer's regulatory jurisdiction is taken from RegulationChangeLog (end-of-day change), NOT from the back-office system (immediate change), because regulation changes take effect at end of day for business/legal reasons.

**Columns Involved**: `RegulationID`, sourced from `Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID`

### 2.5 GDPR Erasure Masking

**What**: When a GDPR deletion request is processed, the UserName in Customer Core gets a `DelUserName` prefix. The SP detects this and masks Email, City, Address, Zip, and PhoneNumber in Fact_SnapshotCustomer.

**Columns Involved**: `Email`, `City`, `Address`, `Zip`, `PhoneNumber`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) distribution + CCI makes per-customer aggregations and filters on RealCID highly efficient — queries that filter or join on RealCID benefit from colocation. The NCI on RealCID provides efficient point-lookup for single customers.

**Warning**: With 406M rows, full table scans are expensive. Always filter by DateRangeID or a specific year range when possible.

### 3.1b UC (Databricks) Storage

**In Databricks**, the data is accessed via `V_Fact_SnapshotCustomer_FromDateID` (generic_id=1115), not directly. Two UC targets:
- `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` — full PII (gated access)
- `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` — Email/City/Address/Zip masked

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current state for all customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Current state for one customer | `WHERE RealCID = @cid AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Customer state on a specific date | `WHERE RealCID = @cid AND LEFT(CAST(DateRangeID AS VARCHAR(12)),8) <= @date AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) >= RIGHT(@date, 4)` |
| Count of depositors | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsDepositor = 1` |
| Valid retail customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsValidCustomer = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON f.CountryID = dc.CountryID | Country name/region |
| DWH_dbo.Dim_Label | ON f.LabelID = dl.LabelID | Brand/label name |
| DWH_dbo.Dim_Language | ON f.LanguageID = dl.LanguageID | Customer language |
| DWH_dbo.Dim_VerificationLevel | ON f.VerificationLevelID = dv.VerificationLevelID | KYC verification status |
| DWH_dbo.Dim_PlayerStatus | ON f.PlayerStatusID = dp.PlayerStatusID | Account lifecycle status |
| DWH_dbo.Dim_Regulation | ON f.RegulationID = dr.RegulationID | Regulatory jurisdiction |
| DWH_dbo.Dim_AccountStatus | ON f.AccountStatusID = das.AccountStatusID | Account enabled/disabled |
| DWH_dbo.Dim_Range | ON f.DateRangeID = dr.DateRangeID | Decode FromDateID + ToDateID |
| DWH_dbo.Fact_Guru_Copiers | ON f.RealCID = fg.RealCID | Copy-trading activity |

### 3.4 Gotchas

- **DateRangeID is NOT a date** — it is a 12-digit bigint encoding (FromDate)(ToDate MMDD). Always extract with LEFT(...,8) for FromDate and RIGHT(...,4) for ToDate MMDD.
- **Most-current-row filter**: `RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` gets the currently open row, but after year-end closure this may temporarily return 0 rows. Use `MAX(DateRangeID)` per RealCID as a safer alternative.
- **Legacy columns with 0 defaults**: DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist are all DEFAULT 0 and NOT populated by the current SP. Do not rely on them.
- **PII masking**: Email, City, Address, Zip are dynamically masked (`MASKED WITH (FUNCTION = 'default()')`). Users without `UNMASK` permission see NULL. PhoneNumber is NOT masked at DDL level but is GDPR-erased via the SP for deleted users.
- **WeekendFeePrecentage** (note: typo in column name — "Precentage" instead of "Percentage") — use as-is.
- **AccountStatusID distribution**: 1=93.2% (Active), 0=6.1% (unknown/default), 2=0.9% (Inactive). Only 3 distinct values observed.
- **Not exported directly to UC** — join via `V_Fact_SnapshotCustomer_FromDateID` in UC.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 2 | RealCID | int | YES | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 3 | DemoCID | int | YES | [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL) |
| 4 | CustomerChangeTypeID | tinyint | YES | [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=Insert, 2=Update). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL) |
| 5 | CurentValue | int | YES | [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL) |
| 6 | PreviousValue | int | YES | [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL) |
| 7 | CountryID | int | YES | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 8 | LabelID | int | YES | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 9 | LanguageID | int | YES | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 10 | VerificationLevelID | int | YES | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 11 | DocsOK | smallint | YES | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 12 | PlayerStatusID | int | YES | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 13 | Bankruptcy | smallint | YES | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 14 | RiskStatusID | int | YES | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 15 | RiskClassificationID | int | YES | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 16 | CommunicationLanguageID | int | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 17 | PremiumAccount | smallint | YES | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 18 | Evangelist | smallint | YES | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 19 | GuruStatusID | smallint | YES | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 20 | UpdateDate | datetime | YES | DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 21 | RegulationID | tinyint | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 22 | AccountStatusID | int | YES | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 23 | AccountManagerID | int | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 24 | PlayerLevelID | int | YES | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 25 | AccountTypeID | int | YES | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 26 | DateRangeID | bigint | YES | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 27 | IsDepositor | bit | YES | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 28 | PendingClosureStatusID | tinyint | YES | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 29 | DocumentStatusID | int | YES | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 30 | SuitabilityTestStatusID | int | YES | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 31 | MifidCategorizationID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 32 | IsEmailVerified | int | YES | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 33 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 34 | DesignatedRegulationID | int | YES | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 35 | EvMatchStatus | int | YES | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 36 | RegionID | int | YES | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 37 | PlayerStatusReasonID | int | YES | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 38 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 39 | AffiliateID | int | YES | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 40 | Email | nvarchar(50) | YES | Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName='DelUserName*'. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 41 | City | nvarchar(50) | YES | Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 42 | Address | nvarchar(100) | YES | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 43 | Zip | nvarchar(50) | YES | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 44 | PhoneNumber | varchar(30) | YES | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 45 | IsPhoneVerified | bit | YES | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 46 | PhoneVerificationDateID | varchar(8) | YES | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 47 | PlayerStatusSubReasonID | int | YES | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 48 | WeekendFeePrecentage | int | YES | Weekend overnight fee percentage applied to this customer. Note: column name typo ("Precentage"). Source: Ext_FSC_Real_Customer_Customer.WeekendFeePrecentage (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 49 | DltStatusID | int | YES | DLT (Digital Ledger/Tangany) wallet status ID. DEFAULT 0. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 50 | DltID | nvarchar(100) | YES | DLT wallet identifier (Tangany ID). NULL if no DLT wallet. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 51 | EquiLendID | varchar(4000) | YES | EquiLend securities lending platform identifier. NULL if not enrolled in stocks lending. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 52 | StocksLendingStatusID | int | YES | Status of the customer's stocks lending enrollment. NULL if not enrolled. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source System | Source Object | Source Column | Transform |
|---------------|--------------|---------------|---------------|-----------|
| RealCID | Customer Core (CC) | Ext_FSC_Real_Customer_Customer | CID | Passthrough |
| GCID | CC / DLT | Ext_FSC_Real_Customer_Customer / Ext_Dim_Customer_CustomerIdentification_DLT | GCID | COALESCE(CC.GCID, FSC.GCID, DLT.GCID, 0) |
| CountryID | CC | Ext_FSC_Real_Customer_Customer | CountryID | COALESCE(CC, FSC, 0) |
| LabelID | CC | Ext_FSC_Real_Customer_Customer | LabelID | COALESCE(CC, FSC, 0) |
| LanguageID | CC | Ext_FSC_Real_Customer_Customer | LanguageID | COALESCE(CC, FSC, 0) |
| PlayerStatusID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusID | COALESCE(CC, FSC, 0) |
| CommunicationLanguageID | CC | Ext_FSC_Real_Customer_Customer | CommunicationLanguageID | COALESCE(CC, FSC, 0) |
| AccountStatusID | CC | Ext_FSC_Real_Customer_Customer | AccountStatusID | COALESCE(CC, FSC, 0) |
| PlayerLevelID | CC | Ext_FSC_Real_Customer_Customer | PlayerLevelID | COALESCE(CC, FSC, 0) |
| IsEmailVerified | CC | Ext_FSC_Real_Customer_Customer | IsEmailVerified | COALESCE(CC, FSC, 0) |
| PendingClosureStatusID | CC | Ext_FSC_Real_Customer_Customer | PendingClosureStatusID | COALESCE(CC, FSC, 0) |
| RegionID | CC | Ext_FSC_Real_Customer_Customer | RegionID | COALESCE(CC, FSC, 0) |
| PlayerStatusReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusReasonID | COALESCE(CC, FSC, 0) |
| PlayerStatusSubReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusSubReasonID | COALESCE(CC, FSC, 0) |
| WeekendFeePrecentage | CC | Ext_FSC_Real_Customer_Customer | WeekendFeePrecentage | COALESCE(CC, FSC) |
| AffiliateID | CC | Ext_FSC_Real_Customer_Customer | AffiliateID | COALESCE(CC, FSC, 0) |
| Email | CC | Ext_FSC_Real_Customer_Customer | Email | COALESCE(CC, FSC, '') + GDPR masking |
| City | CC | Ext_FSC_Real_Customer_Customer | City | COALESCE(CC, FSC, '') + GDPR masking |
| Address | CC | Ext_FSC_Real_Customer_Customer | Address | COALESCE(CC, FSC, '') + GDPR masking |
| Zip | CC | Ext_FSC_Real_Customer_Customer | Zip | COALESCE(CC, FSC, '') + GDPR masking |
| VerificationLevelID | Back Office (BO) | Ext_FSC_BackOffice_Customer | VerificationLevelID | COALESCE(BO, FSC, 0) |
| RiskStatusID | BO | Ext_FSC_BackOffice_Customer | RiskStatusID | COALESCE(BO, FSC, 0) |
| RiskClassificationID | BO | Ext_FSC_BackOffice_Customer | RiskClassificationID | COALESCE(BO, FSC, 0) |
| GuruStatusID | BO | Ext_FSC_BackOffice_Customer | GuruStatusID | COALESCE(BO, FSC, 0) |
| AccountTypeID | BO | Ext_FSC_BackOffice_Customer | AccountTypeID | COALESCE(BO, FSC, 0) |
| AccountManagerID | BO | Ext_FSC_BackOffice_Customer | AccountManagerID | COALESCE(BO, FSC, 0) |
| DocumentStatusID | BO | Ext_FSC_BackOffice_Customer | DocumentStatusID | COALESCE(BO, FSC, 0) |
| SuitabilityTestStatusID | BO | Ext_FSC_BackOffice_Customer | SuitabilityTestStatusID | COALESCE(BO, FSC, 0) |
| MifidCategorizationID | BO | Ext_FSC_BackOffice_Customer | MifidCategorizationID | COALESCE(BO, FSC, 0) |
| DesignatedRegulationID | BO | Ext_FSC_BackOffice_Customer | DesignatedRegulationID | COALESCE(BO, FSC, 0) |
| EvMatchStatus | BO | Ext_FSC_BackOffice_Customer | EvMatchStatus | COALESCE(BO, FSC, 0) |
| RegulationID | Regulation | Ext_FSC_BackOffice_RegulationChangeLog | ToRegulationID | COALESCE(RegChange, FSC.RegulationID, BO.RegulationID, 0) — end-of-day |
| IsDepositor | FTD | Ext_FSC_Customer_FirstTimeDeposits | CID | 1 if CID exists in FTD table |
| PhoneNumber | Phone | Ext_FSC_PhoneCustomer | PhoneNumber | COALESCE(Phone, FSC, '') |
| IsPhoneVerified | Phone | Ext_FSC_PhoneCustomer | PhoneVerifiedID | CASE WHEN PhoneVerifiedID IN (1,2) THEN 1 ELSE 0 |
| PhoneVerificationDateID | Phone | Ext_FSC_PhoneCustomer | PhoneVerificationDateID | COALESCE(Phone, FSC, ''); exclude 19000101 |
| DltStatusID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltStatusID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| DltID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| EquiLendID | StocksLending | ComplianceStateDB_Compliance_StocksLending | EquiLendID | via Ext_FSC_StocksLending |
| StocksLendingStatusID | StocksLending | ComplianceStateDB_Compliance_StocksLending | StocksLendingStatusID | via Ext_FSC_StocksLending |
| DateRangeID | ETL-computed | N/A | @date + year-end | convert(bigint, convert(varchar,@date,112) + right(convert(varchar,@largedate,112),4)) |
| IsValidCustomer | ETL-computed | N/A | N/A | CASE on PlayerLevelID, LabelID, CountryID |
| IsCreditReportValidCB | ETL-computed | N/A | N/A | CASE on PlayerLevelID, AccountTypeID, LabelID, CountryID |
| UpdateDate | ETL-computed | N/A | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Customer Core (CC) → etoro_History_Customer_Customer (CDC)
  → Ext_FSC_Real_Customer_Customer

Back Office (BO) → etoro_History_BackOfficeCustomer (CDC)
  → Ext_FSC_BackOffice_Customer
  → Ext_FSC_BackOffice_RegulationChangeLog

FTD System → CustomerFinanceDB_Customer_FirstTimeDeposits
  → Ext_FSC_Customer_FirstTimeDeposits

Phone Verification → ContactVerification_Phone_Customer
  → Ext_FSC_PhoneCustomer

DLT/Tangany → UserApiDB_Customer_CustomerIdentification
  → Ext_Dim_Customer_CustomerIdentification_DLT

Stocks Lending → ComplianceStateDB_Compliance_StocksLending
  → Ext_FSC_StocksLending

[All above via SP_Fact_SnapshotCustomer_DL_To_Synapse]
  → SP_Fact_SnapshotCustomer(@dt) [MERGE + DateRange update]
  → DWH_dbo.Fact_SnapshotCustomer
```

| Step | Object | Description |
|------|--------|-------------|
| Source Load | SP_Fact_SnapshotCustomer_DL_To_Synapse | Loads 6 Ext_FSC staging tables from DL, then calls inner SP |
| ETL | SP_Fact_SnapshotCustomer (Author: Boris Slutski, 2018-03-11) | MERGE: close existing rows + INSERT new rows + Dim_Range update |
| Target | DWH_dbo.Fact_SnapshotCustomer | DWH customer snapshot table |
| UC Export | V_Fact_SnapshotCustomer_FromDateID (generic_id=1115) | Daily Merge to UC (two targets: PII + masked) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country name/region |
| LabelID | DWH_dbo.Dim_Label | Brand/label name |
| LanguageID | DWH_dbo.Dim_Language | Language name |
| VerificationLevelID | DWH_dbo.Dim_VerificationLevel | KYC tier |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Account lifecycle status |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Real vs demo tier |
| RiskStatusID | DWH_dbo.Dim_RiskStatus | Risk status |
| RiskClassificationID | DWH_dbo.Dim_RiskClassification | Risk classification |
| GuruStatusID | DWH_dbo.Dim_GuruStatus | Popular Investor status |
| RegulationID / DesignatedRegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction |
| AccountStatusID | DWH_dbo.Dim_AccountStatus | Account enabled/disabled |
| AccountTypeID | DWH_dbo.Dim_AccountType | Account type |
| DocumentStatusID | DWH_dbo.Dim_DocumentStatus | KYC document status |
| MifidCategorizationID | DWH_dbo.Dim_MifidCategorization | MiFID II client category |
| PlayerStatusReasonID | DWH_dbo.Dim_PlayerStatusReasons | Status reason code |
| PlayerStatusSubReasonID | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| EvMatchStatus | DWH_dbo.Dim_EvMatchStatus | eVerify match status |
| PendingClosureStatusID | DWH_dbo.Dim_PendingClosureStatus | Closure status |
| DateRangeID | DWH_dbo.Dim_Range | SCD2 date range decode |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Guru_Copiers | RealCID | SP_Fact_Guru_Copiers joins FSC for guru/copier state |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | All columns | Databricks export view (generic_id=1115) |
| DWH_dbo.V_Fact_SnapshotCustomer | All columns | Alternative view (not in generic mapping) |
| DWH_dbo.Dim_Range | DateRangeID | SP inserts new DateRangeIDs into Dim_Range |

---

## 7. Sample Queries

### 7.1 Current customer state for a single customer

```sql
SELECT
    f.RealCID,
    f.GCID,
    f.AccountStatusID,
    f.PlayerStatusID,
    f.CountryID,
    f.RegulationID,
    f.IsDepositor,
    f.IsValidCustomer,
    f.DateRangeID,
    LEFT(CAST(f.DateRangeID AS VARCHAR(12)), 8) AS FromDateYYYYMMDD
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
WHERE f.RealCID = 12345678
  AND RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231';
```

### 7.2 Count of valid retail depositors by country (current snapshot)

```sql
SELECT
    dc.CountryName,
    COUNT(DISTINCT f.RealCID) AS depositor_count
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
JOIN [DWH_dbo].[Dim_Country] dc ON f.CountryID = dc.CountryID
WHERE RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231'
  AND f.IsDepositor = 1
  AND f.IsValidCustomer = 1
GROUP BY dc.CountryName
ORDER BY depositor_count DESC;
```

### 7.3 Customers who changed regulation during 2025 (history)

```sql
SELECT
    f.RealCID,
    f.Regula

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Range` — synapse
- **Resolved as**: `DWH_dbo.Dim_Range`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md`

# DWH_dbo.Dim_Range

> DWH-internal date range helper table mapping (FromDate, ToDate) pairs as composite keys, used by Snapshot analytics to efficiently join year-to-date and multi-period equity/customer snapshots.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH-internal (generated by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer) |
| **Refresh** | Daily - INSERT-only accumulation by Snapshot SPs |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DateRangeID, FromDateID, ToDateID) + 3 NCI indexes |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Range is a DWH-internal helper lookup that pre-computes all possible (FromDate, ToDate) date range pairs needed by the Snapshot analytics pipelines. Each row represents a unique start-to-end date interval, identified by a composite BigInt key (DateRangeID). The table enables efficient range-based JOINs in SnapshotEquity and SnapshotCustomer views without requiring date arithmetic at query time.

This table has no external production source. It is generated entirely within the DWH by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer, which INSERT new DateRangeID combinations as they encounter new date pairs during snapshot processing. The pattern is append-only - new rows are added daily but existing rows are never updated or deleted.

As of 2026-03-10, the table contains approximately 1.3 million date range pairs spanning from 2007-01-01 to 2026-03-10 on the FromDate side, and 2007-08-26 to 2026-12-31 on the ToDate side.

---

## 2. Business Logic

### 2.1 DateRangeID Encoding

**What**: DateRangeID is a deterministic composite key encoding both FromDate and MMDD(ToDate) into a single 12-digit BigInt.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- Formula: `DateRangeID = CONCAT(YYYYMMDD(FromDate), MMDD(ToDate))`
- Example: FromDateID=20070101, ToDateID=20071231 -> DateRangeID=200701011231
- Decoding FromDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 8))`
- Decoding ToDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 4) + RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4))`
- The YEAR component of ToDateID is always the SAME as the YEAR of FromDateID (only MMDD of ToDate is stored in the last 4 digits)

**Diagram**:
```
DateRangeID (12-digit BigInt):
  [ YYYY | MM | DD | MM | DD ]
  [  From Year  | From MMDD  | To MMDD ]
   |___________|             |________|
   Chars 1-8 = FromDateID    Chars 9-12 = MMDD(ToDate)

  ToDateID = YYYY(FromDate) + MMDD(ToDate)
  -> Year-end range example:
     FromDate=2020-03-15, ToDate=2020-12-31
     DateRangeID = 202003151231
     ToDateID    = 20201231
```

### 2.2 Snapshot Range Pattern

**What**: Dim_Range is the bridge between individual customer dates and fiscal/calendar year-end periods in Snapshot reports.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- The primary use case is "from customer registration/event date to year-end": FromDate = customer's start date, ToDate = December 31 of that year
- The SPs also generate non-year-end ranges when snapshots require partial-period measurements
- The table grows daily as new snapshot dates are processed
- No deduplication needed - DateRangeID uniqueness is enforced by the NOT EXISTS check in both SPs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a composite CLUSTERED INDEX on (DateRangeID, FromDateID, ToDateID) and three Non-Clustered Indexes: IX_Dim_Range_FromDateID, IX_Dim_Range_ToDateID, and IX_Dim_Range_FromDateID_ToDateID. The NCI indexes are unusual for Synapse (which typically uses only CCI) and suggest heavy range-based lookups by the Snapshot SPs. Always filter on FromDateID or ToDateID directly to leverage these indexes.

Note: PRIMARY KEY (DateRangeID) is declared NOT ENFORCED - Synapse does not validate uniqueness but the ETL SPs maintain it via NOT EXISTS guards.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` is Parquet. With 1.3M rows, consider filtering on FromDateID for performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find the DateRangeID for a specific (from, to) pair | `SELECT DateRangeID FROM DWH_dbo.Dim_Range WHERE FromDateID = @from AND ToDateID = @to` |
| Find all ranges starting from a given date | `WHERE FromDateID = @date` (uses IX_Dim_Range_FromDateID) |
| Look up range details from a DateRangeID | `SELECT FromDateID, ToDateID FROM DWH_dbo.Dim_Range WHERE DateRangeID = @id` |
| Check how many ranges exist for a year | `WHERE FromDateID BETWEEN @year*10000+101 AND @year*10000+1231` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_SnapshotEquity | DateRangeID | Resolve snapshot equity date ranges |
| DWH_dbo.Fact_SnapshotCustomer | DateRangeID | Resolve snapshot customer date ranges |
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | View-level access to snapshot equity with resolved ranges |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridging |

### 3.4 Gotchas

- **ToDate YEAR = FromDate YEAR**: The DateRangeID encoding only stores MMDD of ToDate. The year of ToDate is derived from FromDate's year. This means all ranges in this table are within-year ranges - cross-year ranges cannot be represented.
- **INSERT-only, no TRUNCATE**: Both writer SPs use NOT EXISTS guards, making the table append-only. Rows are never deleted. If a DateRangeID is erroneously created, it persists forever.
- **Primary key NOT ENFORCED**: Synapse does not verify uniqueness of DateRangeID. Trust the ETL logic, not the constraint.
- **DateRangeID is a STRING-derived number**: Always treat DateRangeID as a derived key, not a business ID. Decode using LEFT/RIGHT string operations if needed.
- **1.3M rows for a dim table**: Larger than typical dimensions. REPLICATE is appropriate given daily Snapshot SP joins from all distributions.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3b - DDL structure | `(Tier 3b - DDL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateRangeID | bigint | NO | Primary key (NOT ENFORCED). 12-digit composite key encoding FromDate and MMDD(ToDate). Formula: CONCAT(YYYYMMDD(From), MMDD(To)). Example: 200701011231 = From:20070101, To:20071231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 2 | FromDateID | int | NO | Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 3 | ToDateID | int | NO | End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 4 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() when the row was inserted. NULL for oldest rows (pre-UpdateDate tracking). Not a business date. (Tier 3b - DDL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateRangeID | DWH-internal (computed) | - | ETL-computed: CONCAT(YYYYMMDD(@date), MMDD(@largedate)) |
| FromDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 8) |
| ToDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 4) + RIGHT(DateRangeID, 4) |
| UpdateDate | - | - | ETL-computed: GETDATE() at insert time |

### 5.2 ETL Pipeline

```
SP_Fact_SnapshotEquity (daily) ---+
                                  +--> INSERT new DateRangeIDs --> DWH_dbo.Dim_Range
SP_Fact_SnapshotCustomer (daily) -+
```

| Step | Object | Description |
|------|--------|-------------|
| Writer 1 | SP_Fact_SnapshotEquity | INSERTs new (FromDate, ToDate) pairs from #outputdata temp table (Action='UPDATE') |
| Writer 2 | SP_Fact_SnapshotCustomer | INSERTs new (FromDate, ToDate) pairs from #outputdata and #UpdatedRanges temp tables |
| Guard | NOT EXISTS check | Both SPs use NOT EXISTS to prevent duplicate DateRangeIDs |
| Target | DWH_dbo.Dim_Range | Append-only. 1.3M rows as of 2026-03-10 |
| Export | Generic Pipeline (daily) | Exports to dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - DateRangeID, FromDateID, and ToDateID are DWH-internal keys with no external FK targets.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | Snapshot equity view with date range context |
| DWH_dbo.V_Fact_SnapshotEquity_FromDateID | DateRangeID / FromDateID | Snapshot equity filtered by customer registration date |
| DWH_dbo.V_Fact_SnapshotCustomer | DateRangeID | Snapshot customer view with date range context |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | DateRangeID / FromDateID | Snapshot customer filtered by registration date |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridge view |

---

## 7. Sample Queries

### 7.1 Decode a DateRangeID back to its components
```sql
SELECT
    DateRangeID,
    FromDateID,
    ToDateID,
    -- Verify encoding formula
    CONVERT(BIGINT,
        LEFT(CONVERT(VARCHAR(12), DateRangeID), 4)
        + RIGHT(CONVERT(VARCHAR(12), DateRangeID), 4)
    ) AS ToDateID_decoded
FROM [DWH_dbo].[Dim_Range]
WHERE DateRangeID = 200701011231
```

### 7.2 Find all year-end ranges (FromDate to Dec 31 of same year)
```sql
SELECT DateRangeID, FromDateID, ToDateID
FROM [DWH_dbo].[Dim_Range]
WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'
ORDER BY FromDateID DESC
```

### 7.3 Count ranges per year
```sql
SELECT
    LEFT(CAST(FromDateID AS VARCHAR(8)), 4) AS FromYear,
    COUNT(*) AS range_count
FROM [DWH_dbo].[Dim_Range]
GROUP BY LEFT(CAST(FromDateID AS VARCHAR(8)), 4)
ORDER BY FromYear DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.3/10 (★★★★☆) | Phases: 10/14*
*Tiers: 0 T1, 3 T2, 1 T3b, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Range | Type: Table | Production Source: DWH-internal (SP_Fact_SnapshotEquity + SP_Fact_SnapshotCustomer)*


### Upstream `DWH_dbo.Fact_BillingWithdraw` — synapse
- **Resolved as**: `DWH_dbo.Fact_BillingWithdraw`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md`

# DWH_dbo.Fact_BillingWithdraw

> Denormalized withdrawal fact table; each row combines a customer withdrawal request (Billing.Withdraw), its payment execution leg (Billing.WithdrawToFunding), and the funding instrument metadata (Billing.Funding) into a single wide row with XML-extracted payment details and BIN-code enrichment, providing a one-stop analytics surface for withdrawal operations, cashout monitoring, and regulatory reporting.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | Billing.Withdraw + Billing.WithdrawToFunding + Billing.Funding |
| **Key Identifier** | WithdrawID (CLUSTERED INDEX, HASH distribution key) |
| **Distribution** | HASH(WithdrawID) |
| **Index** | CLUSTERED INDEX (WithdrawID ASC); NCI on ExpirationDateID |
| **Column Count** | 83 |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` |
| **UC Copy Strategy** | Merge |
| **Refresh** | Daily (1440 min) |
| **ETL Pattern** | DELETE-day + Staging INSERT + Post-load BIN enrichment |

---

## 1. Business Meaning

`Fact_BillingWithdraw` is the DWH's primary withdrawal analytics table. It denormalizes three production tables into a single row per withdrawal-to-funding execution:

1. **Billing.Withdraw** (`bw`): The withdrawal request — customer ID, amount, status, fees, request date
2. **Billing.WithdrawToFunding** (`wtf`): The payment execution leg — processing currency, exchange rate, payment status, depot routing
3. **Billing.Funding** (`bf`): The funding instrument — payment method metadata extracted from XML

The ETL uses `DWH_dbo.ExtractXMLValue()` to parse ~40 fields from the XML blobs (`wtf.WithdrawData` and `bf.FundingData`), flattening provider-specific payment details (card numbers, bank accounts, IBAN codes, etc.) into queryable columns. Many fields use a COALESCE pattern that tries the WithdrawToFunding XML first, falling back to the Funding XML when unavailable.

After the main load, `SP_Fact_BillingWithdraw` enriches each day's rows with `BankName` (issuing bank) and `CardCategory` from `Dim_CountryBin` matched on BIN code.

### Business Usage

- **Regulatory Reporting**: Confluence "Business & Regulatory Undertakings Monitoring Platform" queries `Fact_BillingWithdraw WHERE Fee>0` for withdrawal fee monitoring
- **Cashout Fee Analysis**: Confluence "Cashout Fee" joins to `Dim_CashoutReason`, `Dim_BillingDepot`, `Dim_FundingType`, `Dim_CardType` for fee breakdowns by regulation, club, country, and account type
- **Deposits & Withdrawals Reporting**: Confluence "Deposits and withdrawals - DWH" uses this table alongside `Fact_BillingDeposit` for combined payment flow analysis

---

## 2. Business Logic

### 2.1 ETL Pipeline (SP_Fact_BillingWithdraw_DL_To_Synapse)

```
Step 1: DELETE existing rows for @dt day (ModificationDateID range)
Step 2: TRUNCATE Ext_FBW_Fact_BillingWithdraw
Step 3: INSERT into Ext from 3-way staging JOIN:
        bw LEFT JOIN wtf ON WithdrawID
           LEFT JOIN bf ON FundingID
        WHERE bw.ModificationDate in @dt day range
        → ExtractXMLValue() for ~40 columns from XML
        → COALESCE(wtf.WithdrawData, bf.FundingData) for shared fields
Step 4: DELETE existing in Fact matching by WithdrawID (upsert pattern)
Step 5: INSERT from Ext into Fact_BillingWithdraw
Step 6: EXEC SP_Fact_BillingWithdraw @date = @dt
```

### 2.2 Post-Load Enrichment (SP_Fact_BillingWithdraw)

```
Step 1: Wait for Dim_CountryBin to be loaded today (polling loop, 60s intervals)
Step 2: UPDATE BankName = cb.IssuingBank, CardCategory = cb.CardCategory
        FROM Fact_BillingWithdraw fbw
        JOIN Dim_CountryBin cb ON CAST(fbw.BinCodeAsString AS INT) = cb.BinCode
        WHERE ModificationDateID = @dateID
```

### 2.3 Dual Status Tracking

The table carries two CashoutStatusID columns reflecting different levels:
- **CashoutStatusID_Withdraw** (request level): Tracks the overall withdrawal request lifecycle. 71% of requests are Cancelled in production.
- **CashoutStatusID_Funding** (execution level): Tracks the specific payment leg execution. A request can be Processed overall while having multiple legs with different statuses.

Both reference `Dim_CashoutStatus`. Key values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled.

### 2.4 Dual FundingType Tracking

- **FundingTypeID_Withdraw**: The payment method the customer selected when making the withdrawal request (from Billing.Withdraw)
- **FundingTypeID_Funding**: The payment method of the actual funding instrument receiving the payout (from Billing.Funding)

These may differ when the payout is routed to a different method than originally requested.

### 2.5 Dual Amount Tracking

- **Amount_Withdraw**: The gross withdrawal amount in the request currency (CurrencyID)
- **Amount_WithdrawToFunding**: The actual payout amount in the processing currency (ProcessCurrencyID)

The difference may be due to exchange rate conversion (ExchangeRate) and fees (Fee, ExchangeFee).

### 2.6 XML Extraction Pattern

~40 columns are extracted from XML blobs stored in the production `WithdrawData` and `FundingData` columns using `DWH_dbo.ExtractXMLValue()`. All are stored as `nvarchar(max)` regardless of their semantic type (some represent integers, decimals, dates). The COALESCE pattern for shared fields (BIN code, IBAN, SWIFT, etc.) prefers the payment execution data over the funding instrument data, as the execution-time data is more current.

### 2.7 BIN Code Enrichment

After the main ETL load, `SP_Fact_BillingWithdraw` enriches rows by matching `BinCodeAsString` (CAST to INT) against `Dim_CountryBin.BinCode` to populate `BankName` (issuing bank) and `CardCategory`. This step waits for `Dim_CountryBin` to be loaded for the current day, polling every 60 seconds.

### 2.8 Column Rename Disambiguation

| DWH Column | Source Column | Source Table | Why Renamed |
|-----------|-------------|-------------|-------------|
| Amount_Withdraw | Amount | bw (Billing.Withdraw) | Disambiguate from WTF amount |
| Amount_WithdrawToFunding | Amount | wtf (Billing.WithdrawToFunding) | Payment leg amount in process currency |
| FundingTypeID_Withdraw | FundingTypeID | bw (Billing.Withdraw) | Payment method of the withdrawal request |
| FundingTypeID_Funding | FundingTypeID | bf (Billing.Funding) | Payment method of the funding instrument |
| CashoutStatusID_Withdraw | CashoutStatusID | bw (Billing.Withdraw) | Request-level status |
| CashoutStatusID_Funding | CashoutStatusID | wtf (Billing.WithdrawToFunding) | Execution-level status |
| ModificationDate_WithdrawToFunding | ModificationDate | wtf (Billing.WithdrawToFunding) | Execution leg last modified |
| WithdrawPaymentID | ID | wtf (Billing.WithdrawToFunding) | WTF surrogate key |

---

## 3. Query Advisory

### 3.1 Distribution & Indexing

- **HASH(WithdrawID)**: Queries filtering on `WithdrawID` are single-node. Customer-level queries (by CID) require data movement across distributions.
- **Clustered Index**: WithdrawID ASC — efficient for point lookups and range scans by WithdrawID.
- **NCI on ExpirationDateID**: Supports card expiration-based queries (compliance, PCI reporting).

### 3.2 Data Freshness

- Daily incremental load based on `ModificationDate` in the source
- Post-load BIN enrichment depends on `Dim_CountryBin` being loaded first (blocking dependency with polling)
- `UpdateDate` reflects the ETL execution timestamp

---

## 4. Elements

> Note: Upstream production wikis available for Billing.Withdraw (9.5/10), Billing.WithdrawToFunding (9.1/10), and Billing.Funding. Tier 1 descriptions inherited verbatim from upstream where columns are passthrough or renamed. XML-extracted columns (parsed from WithdrawData/FundingData XML blobs via ExtractXMLValue) are Tier 2 because they are not table-level columns in the source — they are values inside an XML document.

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. (Tier 1 — Billing.Withdraw) |
| 2 | WithdrawID | int | YES | Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. (Tier 1 — Billing.Withdraw) |
| 3 | CurrencyID | int | YES | Currency of the withdrawal amount. FK to Dictionary.Currency. (Tier 1 — Billing.Withdraw) |
| 4 | FundingTypeID_Withdraw | int | YES | Payment method type of the withdrawal request (Visa/Wire/Neteller/eToroMoney/etc.). 26 distinct values in production. Renamed from FundingTypeID to disambiguate from Billing.Funding's FundingTypeID. (Tier 1 — Billing.Withdraw) |
| 5 | RequestDate | datetime | YES | Timestamp when the customer submitted the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 6 | Amount_Withdraw | money | YES | Gross withdrawal amount in CurrencyID denomination. Renamed from Amount to disambiguate from WithdrawToFunding Amount. (Tier 1 — Billing.Withdraw) |
| 7 | Commission | money | YES | Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers. (Tier 1 — Billing.Withdraw) |
| 8 | Approved | int | YES | Whether the withdrawal has received required approval. 1=Approved, 0=Pending approval. DEFAULT=0. DWH note: CAST from bit to int. (Tier 1 — Billing.Withdraw) |
| 9 | ModificationDate | datetime | YES | UTC timestamp of the most recent status change or update on the withdrawal request. (Tier 1 — Billing.Withdraw) |
| 10 | ModificationDateID | int | YES | Integer date key derived from ModificationDate: CONVERT(INT, CONVERT(VARCHAR, ModificationDate, 112)). Format YYYYMMDD. Used for partition-style filtering and the DELETE/INSERT ETL pattern. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 11 | Fee | money | YES | Platform fee charged for this withdrawal. Subtracted from the gross Amount_Withdraw. (Tier 1 — Billing.Withdraw) |
| 12 | FundingID | int | YES | FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. (Tier 1 — Billing.Withdraw) |
| 13 | CashoutReasonID | int | YES | Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. (Tier 1 — Billing.Withdraw) |
| 14 | ClientWithdrawReasonID | int | YES | Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied). FK to Dim_ClientWithdrawReason. (Tier 1 — Billing.Withdraw) |
| 15 | AccountCurrencyID | int | YES | Customer eToro account currency, if different from CurrencyID. Used when account and withdrawal currencies differ. FK to Dim_Currency. (Tier 1 — Billing.Withdraw) |
| 16 | CashoutStatusID_Withdraw | int | YES | Withdrawal request-level status. FK to Dim_CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. Renamed from CashoutStatusID. (Tier 1 — Billing.Withdraw) |
| 17 | Comment | nvarchar(255) | YES | Operations comment on the withdrawal request. Free-text field populated by back-office staff. (Tier 1 — Billing.Withdraw) |
| 18 | FlowID | int | YES | Processing flow identifier. NULL=legacy, 0=standard, 2=eToroMoney (triggers MoveMoneyReasonID=5), 3=alternate (triggers MoveMoneyReasonID=6). (Tier 1 — Billing.Withdraw) |
| 19 | WithdrawTypeID | int | YES | Withdrawal type classification. NULL=legacy (55%), 0=standard (41%), 1=special/alternate (3.7%), 2=second alternate (0.5%). Added 2024-08-22. (Tier 1 — Billing.Withdraw) |
| 20 | CashoutStatusID_Funding | int | YES | Execution-level status of the payment leg. FK to Dim_CashoutStatus. Values: 3=Processed (31.5%), 4=Canceled (67.7%), 14=Pending Review, 17=Partially Reversed. Renamed from CashoutStatusID. (Tier 1 — Billing.WithdrawToFunding) |
| 21 | ProcessCurrencyID | int | YES | Currency used for the actual payment processing. May differ from withdrawal CurrencyID when cross-currency routing is applied. FK to Dim_Currency. (Tier 1 — Billing.WithdrawToFunding) |
| 22 | ExchangeRate | numeric(16,8) | YES | Exchange rate applied to convert from withdrawal currency to ProcessCurrencyID. NULL for same-currency payouts. (Tier 1 — Billing.WithdrawToFunding) |
| 23 | Amount_WithdrawToFunding | money | YES | Payout amount in ProcessCurrencyID currency. Renamed from Amount. For refunds, the amount being refunded to the instrument. (Tier 1 — Billing.WithdrawToFunding) |
| 24 | ModificationDate_WithdrawToFunding | datetime | YES | UTC timestamp of the most recent status change on the payment execution leg. Renamed from ModificationDate. (Tier 1 — Billing.WithdrawToFunding) |
| 25 | DepositID | int | YES | For refund legs (CashoutTypeID=2): references the source Billing.Deposit being refunded. Value 0 is null-equivalent for cashout legs. (Tier 1 — Billing.WithdrawToFunding) |
| 26 | CashoutTypeID | tinyint | YES | Categorizes the type of payment execution: 1=Cashout (standard withdrawal, 69%), 2=Refund (refund of a prior deposit, 31%). (Tier 1 — Billing.WithdrawToFunding) |
| 27 | VerificationCode | varchar(50) | YES | Verification code supplied or received during withdrawal processing. (Tier 1 — Billing.WithdrawToFunding) |
| 28 | ProcessorValueDate | datetime | YES | Value date from the payment processor — when funds are considered available. Set for wire/ACH payouts; NULL for instant methods. (Tier 1 — Billing.WithdrawToFunding) |
| 29 | DepotID | int | YES | Which Billing.Depot (acquirer/gateway configuration) processed this payment leg. FK to Dim_BillingDepot. (Tier 1 — Billing.WithdrawToFunding) |
| 30 | ExchangeFee | int | YES | Exchange fee in provider-specific integer units. (Tier 1 — Billing.WithdrawToFunding) |
| 31 | WithdrawPaymentID | int | YES | Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID. (Tier 1 — Billing.WithdrawToFunding) |
| 32 | BaseExchangeRate | numeric(16,8) | YES | Reference exchange rate before fee markup. Spread = ExchangeRate minus BaseExchangeRate. (Tier 1 — Billing.WithdrawToFunding) |
| 33 | ProtocolMIDSettingsID | int | YES | MID configuration profile used for this payment leg. FK to Dim_BillingProtocolMIDSettingsID. Default=0. (Tier 1 — Billing.WithdrawToFunding) |
| 34 | CashoutModeID | tinyint | YES | Mode of withdrawal execution: 1=Standard (75.2%), NULL=legacy (17%), 2=Alternate e.g. eToroMoney/ACH (4%), 0=Unknown/fallback (3.8%). FK to Dim_CashoutMode. (Tier 1 — Billing.WithdrawToFunding) |
| 35 | FundingTypeID_Funding | int | YES | Payment method type of the funding instrument receiving the payout. Renamed from FundingTypeID on Billing.Funding. 34 distinct types (Visa/MC/Neteller/PayPal/Wire/eToroMoney/etc.). FK to Dim_FundingType. (Tier 1 — Billing.Funding) |
| 36 | AccountIDAsString | nvarchar(max) | YES | Payment account identifier. COALESCE: prefers wtf.WithdrawData XML, falls back to bf.FundingData XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 37 | ACHBankAccountIDAsInteger | nvarchar(max) | YES | ACH bank account identifier for US bank transfers. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 38 | BinCodeAsString | nvarchar(max) | YES | Bank Identification Number (first 6-8 digits of card). COALESCE from wtf/bf XML. CAST to INT for JOIN with Dim_CountryBin to populate BankName and CardCategory. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 39 | BinCountryIDAsInteger | nvarchar(max) | YES | Country associated with the BIN code. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 40 | BSBNumberAsString | nvarchar(max) | YES | Bank State Branch number for Australian bank transfers. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 41 | CardTypeIDAsInteger | nvarchar(max) | YES | Card type identifier (Visa, Mastercard, etc.). COALESCE from wtf/bf XML. FK to Dim_CardType after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 42 | CityAsString | nvarchar(max) | YES | City from the payment execution data. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 43 | ClientAddressAsString | nvarchar(max) | YES | Client address from the payment execution data. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 44 | ClientBankNameAsString | nvarchar(max) | YES | Client's bank name. COALESCE from wtf/bf XML. Distinct from BankNameAsString (#67) which is from bf.FundingData only, and BankName (#82) which is post-load enrichment from Dim_CountryBin. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 45 | CountryIDAsInteger | nvarchar(max) | YES | Country identifier from payment data. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 46 | ExpirationDateAsString | nvarchar(max) | YES | Card expiration date as raw string from wtf.WithdrawData XML. Format varies by provider (MMYY, MM/YY, etc.). See ExpirationDateID (#69) for the normalized integer version. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 47 | ErrorCodeAsString | nvarchar(max) | YES | Provider error code if the payment leg failed or was rejected. Extracted from wtf.WithdrawData XML only. NULL for successful transactions. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 48 | IBANCodeAsString | nvarchar(max) | YES | International Bank Account Number for SEPA/wire transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 49 | InitialTransactionIDAsString | nvarchar(max) | YES | Initial transaction reference from the payment provider. Extracted from wtf.WithdrawData XML only. Links the withdrawal to the original deposit transaction for refund tracing. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 50 | MD5AsString | nvarchar(max) | YES | MD5 hash of payment data for verification/deduplication. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 51 | PayeeNameAsString | nvarchar(max) | YES | Payee name from the payment execution. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 52 | PayerPurseAsString | nvarchar(max) | YES | E-wallet purse identifier (e.g., PayPal, Neteller purse ID). Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 53 | ReferenceNumberAsString | nvarchar(max) | YES | Provider reference number for the transaction. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 54 | ResponseMessageAsString | nvarchar(max) | YES | Provider response message (success/failure details). Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 55 | ResponseTimeAsString | nvarchar(max) | YES | Provider response timestamp as string. Extracted from wtf.WithdrawData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 56 | RoutingNumberAsString | nvarchar(max) | YES | Bank routing number for US bank transfers (ABA routing). COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 57 | SecuredCardDataAsString | nvarchar(max) | YES | Secured/tokenized card data from the payment provider. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 58 | SortCodeAsString | nvarchar(max) | YES | Bank sort code for UK bank transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 59 | SwiftCodeAsString | nvarchar(max) | YES | SWIFT/BIC code for international wire transfers. COALESCE from wtf/bf XML. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 60 | AccountIDAsDecimal | nvarchar(max) | YES | Funding instrument account ID (decimal form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 61 | AccountNameAsString | nvarchar(max) | YES | Account holder name on the funding instrument. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 62 | AccountTypeAsString | nvarchar(max) | YES | Account type (checking, savings, etc.). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 63 | BankAccountAsString | nvarchar(max) | YES | Bank account number for wire/bank transfers. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 64 | BankAddressAsString | nvarchar(max) | YES | Bank address for wire transfers. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 65 | BankCodeAsString | nvarchar(max) | YES | Bank code (national bank identifier). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 66 | BankDetailsAccountIDAsString | nvarchar(max) | YES | Bank details account reference. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 67 | BankIDAsInteger | nvarchar(max) | YES | Bank identifier (integer form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 68 | BankIDAsString | nvarchar(max) | YES | Bank identifier (string form). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 69 | BankNameAsString | nvarchar(max) | YES | Bank name from the bf.FundingData XML. Distinct from the enriched BankName (#82) which comes from Dim_CountryBin BIN-code lookup, and ClientBankNameAsString (#44) which is COALESCE from wtf/bf. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 70 | CardNumberAsString | nvarchar(max) | YES | Masked card number (last 4 digits typically visible). Extracted from bf.FundingData XML only. Source column FundingData is masked with FUNCTION='default()' in production. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 71 | CryptoCodeAsString | nvarchar(max) | YES | Cryptocurrency code/address for crypto withdrawals. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 72 | CustomerAddressAsString | nvarchar(max) | YES | Customer address from the funding instrument record. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 73 | CustomerNameAsString | nvarchar(max) | YES | Customer name from the funding instrument record. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 74 | EmailAsString | nvarchar(max) | YES | Email address associated with the funding instrument (e.g., PayPal email). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 75 | ExpirationDateID | int | YES | Card expiration date as normalized integer key: 200000 + YY*100 + MM for valid dates; 190001 for NULL or strings shorter than 4 characters. NCI index on this column. Computed from bf.FundingData ExpirationDateAsString XML field. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 76 | InstrumentIDAsInteger | nvarchar(max) | YES | Instrument identifier within the funding provider. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 77 | MaskedAccountIDAsString | nvarchar(max) | YES | Masked version of the account ID for display/audit. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 78 | PayerIDAsString | nvarchar(max) | YES | Payer identifier (e.g., PayPal Payer ID). Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 79 | PurseAsString | nvarchar(max) | YES | E-wallet purse identifier from the funding instrument. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 80 | SecureIDAsDecimal | nvarchar(max) | YES | Secure identifier for payment verification. Extracted from bf.FundingData XML only. (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 81 | UpdateDate | datetime | YES | ETL load timestamp (Synapse server time at INSERT via GETDATE()). (Tier 2 — SP_Fact_BillingWithdraw_DL_To_Synapse) |
| 82 | BankName | varchar(100) | YES | Issuing bank name looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.IssuingBank. NULL when BinCodeAsString is NULL or BIN code not found. Distinct from BankNameAsString (#69) which comes from the funding XML. (Tier 2 — SP_Fact_BillingWithdraw) |
| 83 | CardCategory | varchar(50) | YES | Card category (Debit, Credit, Prepaid, etc.) looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.CardCategory. NULL when BIN code not found. (Tier 2 — SP_Fact_BillingWithdraw) |

---

## 5. Lineage

### 5.1 Staging Sources (from DWH_staging)

| Alias | Staging Table | Production Source | Role |
|-------|--------------|-------------------|------|
| `bw` | `DWH_staging.etoro_Billing_Withdraw` | `Billing.Withdraw` | Withdrawal request (core facts) |
| `wtf` | `DWH_staging.etoro_Billing_WithdrawToFunding` | `Billing.WithdrawToFunding` | Payment execution leg + XML payment data |
| `bf` | `DWH_staging.etoro_Billing_Funding` | `Billing.Funding` | Funding instrument + XML funding data |

### 5.3 Internal DWH Dependencies

| Table | Role |
|-------|------|
| `DWH_dbo.Ext_FBW_Fact_BillingWithdraw` | Staging/external table for the 3-way join result |
| `DWH_dbo.Dim_CountryBin` | Post-load enrichment: BankName + CardCategory via BIN code |
| `DWH_dbo.ExtractXMLValue` (function) | Parses individual fields from XML blobs |

---

## 6. Relationships

### 6.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CID | Dim_Customer | CID = RealCID |
| CurrencyID / AccountCurrencyID / ProcessCurrencyID | Dim_Currency | CurrencyID = CurrencyID |
| FundingTypeID_Withdraw / FundingTypeID_Funding | Dim_FundingType | FundingTypeID = FundingTypeID |
| CashoutStatusID_Withdraw / CashoutStatusID_Funding | Dim_CashoutStatus | CashoutStatusID = CashoutStatusID |
| CashoutReasonID | Dim_CashoutReason | CashoutReasonID = CashoutReasonID |
| ClientWithdrawReasonID | Dim_ClientWithdrawReason | ClientWithdrawReasonID = ClientWithdrawReasonID |
| CashoutModeID | Dim_CashoutMode | CashoutModeID = CashoutModeID |
| DepotID | Dim_BillingDepot | DepotID = DepotID |
| ProtocolMIDSettingsID | Dim_BillingProtocolMIDSettingsID | ProtocolMIDSettingsID = ProtocolMIDSettingsID |
| BinCodeAsString (CAST INT) | Dim_CountryBin | CAST(BinCodeAsString AS INT) = BinCode |
| ModificationDateID | Dim_Date (implicit) | YYYYMMDD integer key |

### 6.2 Source Chain

```
Billing.Withdraw ──bw──┐
                        ├── LEFT JOIN ON WithdrawID ──► Ext_FBW_Fact_BillingWithdraw ──► Fact_BillingWithdraw
Billing.WithdrawToFunding ─wtf─┤                                                            │
                        ├── LEFT JOIN ON FundingID                                    POST-LOAD UPDATE
Billing.Funding ──bf────┘                                                                    │
                                                                                     Dim_CountryBin
                                                                                   (BankName, CardCategory)
```

### 6.3 Referenced By

*To be populated during cross-object enrichment (Phase 12).*

---

## 7. Sample Queries

```sql
-- Withdrawal details with status names
SELECT fbw.WithdrawID, fbw.CID, fbw.Amount_Withdraw, fbw.Fee,
       dcs.Name AS WithdrawStatus, dcs2.Name AS FundingStatus
FROM DWH_dbo.Fact_BillingWithdraw fbw
JOIN DWH_dbo.Dim_CashoutStatus dcs ON fbw.CashoutStatusID_Withdraw = dcs.CashoutStatusID
LEFT JOIN DWH_dbo.Dim_CashoutStatus dcs2 ON fbw.CashoutStatusID_Funding = dcs2.CashoutStatusID
WHERE fbw.ModificationDateID BETWEEN 20260301 AND 20260319;

-- Withdrawal fee analysis (regulatory pattern)
SELECT fbw.CID, fbw.WithdrawID, fbw.Amount_Withdraw, fbw.Fee,
       dft.Name AS FundingType, dcr.Name AS CashoutReason
FROM DWH_dbo.Fact_BillingWithdraw fbw
JOIN DWH_dbo.Dim_FundingType dft ON fbw.FundingTypeID_Withdraw = dft.FundingTypeID
LEFT JOIN DWH_dbo.Dim_CashoutReason dcr ON fbw.CashoutReasonID = dcr.CashoutReasonID
WHERE fbw.Fee > 0;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| Business & Regulatory Undertakings Monitoring Platform | Queries Fact_BillingWithdraw WHERE Fee>0 for withdrawal fee monitoring |
| Cashout Fee (Confluence) | Joins to Dim_CashoutReason, Dim_BillingDepot, Dim_FundingType for fee breakdowns |
| Deposits and withdrawals - DWH (Confluence) | Uses alongside Fact_BillingDeposit for combined payment flow analysis |

---
*Generated: 2026-03-19 | Quality: 8.5/10*
*Tiers: 34 T1, 49 T2, 0 T3, 0 T4, 0 T5 | Phases: 1,5,8,9,9B,10,10.5,13,11*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_PIPs_Report_MID_Settings`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_PIPs_Report_MID_Settings.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_PIPs_Report_MID_Settings] @date [date] AS 

     
/**************************************Start Main Comment History******************************************************     
Author:      Guy Manova       
Date:        2024-03-04      
Description: this creates a daily dictionary which brings (hopefully) the BO MIDSettings logics correctly. it's joined in tableau DepositWithdrawFee report 
			to show correct MidValue and Entity. 
			the reason it's separated and only done in tableau, is because it's reliant on a lot of external lake tables, which cannot impede the "financial" reports run
			(depositwithdrawfee is part of the finance package). this is just metadata, so added in tableau. 
     
			 this is a temporary solution to bring the cashout rollbacks pips into finance (previously only available through BO). 
			the end game of this should be to receive in views from DBAs on production - we recompute many hard coded things here
			which can be changed at the source without being informed to us, and we will diverge from the production data (BO)
			the logics here are complex, unfoptunately synapse doesnot support select statements within UDFs so the DBA functions 
			could not be copied to synapse, instead they are translated to tables with joins and apply statements. these are based 
			on the following stored procedures and functions, if needed you can look them up in the DBA github repositories: 

			deposits:
			main SP: etoro/SPs/Billing/Billing.[GetRollbackedPaymentOrdersReport].sql
					 etoro/SPs/BackOffice/BackOffice.[BillingDepositPCIVersion].sql
			functions: etoro/etoro/Billing/Functions/Billing.GetMerchantDetailsForOneAccountByDepotOnly.sql
						etoro/etoro/BackOffice/Functions/BackOffice.GetMerchantDetails.sql
						etoro/etoro/BackOffice/Functions/BackOffice.CalculateDepositPIPsUSD.sql
			withdraws: 
			main SP: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetRiskExposureReportPCIVersion.sql
			functions: etoro/etoro/Billing/Functions/Billing.GetMerchantDetailsForOneAccountByDepotOnly.sql
						etoro/etoro/BackOffice/Functions/BackOffice.GetMerchantDetails.sql
						etoro/etoro/BackOffice/Functions/BackOffice.CalculateDepositPIPsUSD.sql

**************************      
** Change History      
**************************      
Date         Author			ticket number	 Description       
------		--------	    -------------	 ------------ 
2024-03-08	Guy M							still doing QA against BO with Elena - i simplified the withdraws by A LOT, and added a fix to Deposits. 		

****************************************End Main Comment History****************************************************/   

-- exec BI_DB_dbo.SP_PIPs_Report_MID_Settings '20240304'

BEGIN  

-- declare @date date = '20240215'
DECLARE @StartDate DATE = @date
DECLARE @StartDateID INT = CONVERT(VARCHAR(8), @StartDate, 112)

--------------------------------
-- externals for new MID logics
--------------------------------


IF OBJECT_ID('tempdb..#MapMerchantCodeToMid') IS NOT NULL DROP TABLE #MapMerchantCodeToMid;
CREATE TABLE #MapMerchantCodeToMid  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT * FROM [BI_DB_dbo].[External_eToro_Dictionary_MapMerchantCodeToMid];


IF OBJECT_ID('tempdb..#MerchantAccountRouting') IS NOT NULL DROP TABLE #MerchantAccountRouting;
CREATE TABLE #MerchantAccountRouting  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT * FROM [BI_DB_dbo].[External_eToro_Billing_MerchantAccountRouting];

--DECLARE @BeginDate DATETIME = '20230627';      
--DECLARE @BeginDateID int =CAST(CONVERT(VARCHAR(8), @BeginDate, 112) AS INT)
--declare @sysstart datetime 
--set @sysstart = SYSDATETIME()


/********************************************
logic of [Billing].[GetMerchantDetailsForOneAccountByDepotOnly]: 
take the top 1 order by mar.RegulationID desc of either Name of BODDecription, based on 
whether 1 or 0 is passed to the function: if 0 then Name, if 1 then BODDescription
********************************************/

IF OBJECT_ID('tempdb..#MerchantAccount') IS NOT NULL DROP TABLE #MerchantAccount;
CREATE TABLE #MerchantAccount  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT * FROM [BI_DB_dbo].[External_eToro_Dictionary_MerchantAccount];

IF OBJECT_ID('tempdb..#GetMerchantDetailsForOneAccountByDepotOnly') IS NOT NULL DROP TABLE #GetMerchantDetailsForOneAccountByDepotOnly;
CREATE TABLE #GetMerchantDetailsForOneAccountByDepotOnly  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT ma1.MerchantAccountID, ma1.MerchantID, ma1.Name, ma1.BODescription, mar.DepotID, mar.RegulationID
FROM #MerchantAccountRouting mar
	JOIN #MerchantAccount ma1
		ON mar.MerchantAccountID = ma1.MerchantAccountID
WHERE mar.CurrencyID = 0
AND mar.PaymentTypeID = 0
AND mar.DepotModeID = 1
AND mar.CountryID = 0
AND mar.SubTypeID = 0;


--DECLARE @StartDate DATE = '20240101'
--DECLARE @StartDateID INT = CONVERT(VARCHAR(8), @StartDate, 112)

IF OBJECT_ID('tempdb..#BDEP') IS NOT NULL DROP TABLE #BDEP
CREATE TABLE #BDEP  
    WITH (CLUSTERED INDEX(DepositWithdrawID),DISTRIBUTION=HASH(DepositWithdrawID))
AS
SELECT
	bddwf.DateID
  , bddwf.CID
  , bddwf.DepositWithdrawID
  , bddwf.DepositWithdrawID AS DepositID
  , bddwf.Occurred
  , bddwf.TransactionType
  , bddwf.Currency
  , bddwf.RegulationID
  , bddwf.Depot
  , bddwf.MIDValue
  , fbd.CurrencyID
  , fbd.FundingID
  , fbd.DepotID
  , fbd.FundingTypeID
  , fbd.ProtocolMIDSettingsID
  , fbd.MerchantAccountID
FROM BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf
JOIN DWH_dbo.Fact_BillingDeposit fbd
	ON bddwf.DepositWithdrawID = fbd.DepositID
WHERE bddwf.DateID = @StartDateID
AND bddwf.TransactionType = 'Deposit'


IF OBJECT_ID('tempdb..#midPrep') IS NOT NULL DROP TABLE #midPrep
CREATE TABLE #midPrep  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT 
	 BDEP.DepositID
	--, dc2.Name AS IPCountryName
	--, dc3.Name AS BinCountry
	, BDEP.FundingID
	, BDEP.Depot
	, BDEP.DepotID
	, (
		SELECT TOP 1 bdo.BODescription
		FROM #GetMerchantDetailsForOneAccountByDepotOnly bdo
		WHERE (bdo.RegulationID = BDEP.RegulationID OR bdo.RegulationID = 0) AND bdo.DepotID = BDEP.DepotID
		ORDER BY bdo.RegulationID
		) AS BillingGetMerchantDetailWhen1
	, (
		SELECT ma.BODescription
		FROM #MerchantAccount ma
		WHERE ma.MerchantAccountID = do.MerchantAccountID
		) AS BackofficeGetMerchantDetailWhen1
	, (
		SELECT TOP 1 bdo.Name
		FROM #GetMerchantDetailsForOneAccountByDepotOnly bdo
		WHERE (bdo.RegulationID = BDEP.RegulationID OR bdo.RegulationID = 0) AND bdo.DepotID = BDEP.DepotID
		ORDER BY bdo.RegulationID
		) AS BillingGetMerchantDetailWhen0
	, (
		SELECT ma.Name
		FROM #MerchantAccount ma
		WHERE ma.MerchantAccountID = do.MerchantAccountID
		) AS BackofficeGetMerchantDetailWhen0
	, (
		SELECT bdo.DepotID
		FROM #GetMerchantDetailsForOneAccountByDepotOnly bdo
		WHERE (bdo.RegulationID = BDEP.RegulationID) AND bdo.DepotID = BDEP.DepotID
		) AS BillingGetMerchantDepotID
	, BDEP.CID
	, BDEP.CurrencyID
	, BDEP.FundingTypeID
	, BPMS.DepotID AS BPMSDepotID
	, BDEP.RegulationID AS CCSTRegulationID
	, DR.Name AS DRName
	, DMA.Name AS DMAName
	, DMA.BODescription AS DMABODescription
	, ma.Name AS maName
	, ma.BODescription AS maBODescription
	, BPMS.Description AS BPMSDescription
	, BMMC.MID AS BMMCMID
	, BPMS.Value AS BPMSValue
	, BDEP.ProtocolMIDSettingsID
	, BDEP.MIDValue AS MIDValueOld
FROM #BDEP BDEP
LEFT JOIN DWH_dbo.Dim_BillingProtocolMIDSettingsID BPMS -- select * from DWH_dbo.Dim_BillingProtocolMIDSettingsID
	ON BDEP.ProtocolMIDSettingsID = BPMS.ProtocolMIDSettingsID
LEFT JOIN #MapMerchantCodeToMid BMMC 
	ON BMMC.MerchantCode = BPMS.[Value] AND BMMC.CurrencyID = BDEP.CurrencyID AND BPMS.RegulationID = BMMC.RegulationID
LEFT JOIN #MerchantAccount DMA
	ON DMA.MerchantAccountID = BDEP.MerchantAccountID
LEFT JOIN #GetMerchantDetailsForOneAccountByDepotOnly do
	ON BDEP.DepotID = do.DepotID AND BDEP.RegulationID = do.RegulationID
LEFT JOIN #MerchantAccount ma
	ON do.MerchantAccountID = ma.MerchantAccountID
JOIN DWH_dbo.Dim_Regulation DR
	ON BDEP.RegulationID = DR.DWHRegulationID
-- WHERE BDEP.DepositID = 55191132

IF OBJECT_ID('tempdb..#midPrep2') IS NOT NULL DROP TABLE #midPrep2
CREATE TABLE #midPrep2 
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT *
	, CASE WHEN p.FundingTypeID = 2 THEN BPMSDescription
			WHEN BPMSDepotID IN (78,79,80,4,75,86) THEN maBODescription
		ELSE COALESCE(DMABODescription, maBODescription,BillingGetMerchantDetailWhen1,  DRName)
		END AS MIDNameNew
	, CASE WHEN FundingTypeID = 2 THEN BPMSValue
			WHEN BPMSDepotID IN (78,79,80,4,75,86) THEN maName
		ELSE COALESCE(DMAName, maName, BPMSDescription, BillingGetMerchantDetailWhen0, BMMCMID, BPMSValue)
		END AS MIDNew
FROM #midPrep p

IF OBJECT_ID('tempdb..#problems1') IS NOT NULL DROP TABLE #problems1
CREATE TABLE #problems1  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT *
FROM #midPrep2 p
WHERE p.DMAName IS NULL 
	AND p.DMABODescription IS NULL
	AND p.maName IS NULL
	AND p.maBODescription IS NULL
	AND (p.BillingGetMerchantDetailWhen1 IS NULL OR p.BillingGetMerchantDetailWhen0 IS NULL)
	AND (p.BackofficeGetMerchantDetailWhen1 IS NULL OR p.BackofficeGetMerchantDetailWhen0 IS NULL)

IF OBJECT_ID('tempdb..#fixProblem1') IS NOT NULL DROP TABLE #fixProblem1
CREATE TABLE #fixProblem1  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT w.*
	, CASE WHEN dr.DWHRegulationID IN (1,3,5) THEN 'eToroEU'
		   WHEN dr.DWHRegulationID IN (2) THEN 'eToroUK'
		   WHEN dr.DWHRegulationID IN (4,10) THEN 'eToroAU'
		   WHEN dr.DWHRegulationID IN (6,7,8) THEN '0'
		   WHEN dr.DWHRegulationID IN (9,11) THEN
				CASE WHEN w.BPMSDescription LIKE '%EU' OR  w.BPMSDescription LIKE  'EU%' or w.BMMCMID LIKE '%EU' or w.BMMCMID LIKE 'EU%'THEN 'eToroEU'
					 WHEN w.BPMSDescription LIKE '%AU' OR  w.BPMSDescription LIKE  'AU%' or w.BMMCMID LIKE '%AU' or w.BMMCMID LIKE 'AU%'THEN 'eToroAU'
					 WHEN w.BPMSDescription LIKE '%UK' OR  w.BPMSDescription LIKE  'UK%' or w.BMMCMID LIKE '%UK' or w.BMMCMID LIKE 'UK%'THEN 'eToroUK'
				ELSE 'NA' end
		  ELSE 'NA' END AS UpdateMIDNameNew
	, CASE WHEN w.MIDNew LIKE '%Old%' THEN w.BMMCMID 
	ELSE w.MIDValueOld END AS UpdateMIDNew
FROM #problems1 w
LEFT JOIN DWH_dbo.Dim_Regulation dr
	ON w.MIDNameNew = dr.Name

 UPDATE  t1
 SET 
 t1.MIDNameNew = t2.UpdateMIDNameNew
 , t1.MIDNew = t2.UpdateMIDNew
 FROM #midPrep2 t1
 INNER JOIN #fixProblem1 t2
	 ON t1.DepositID = t2.DepositID

UPDATE #midPrep2
SET MIDNameNew = 
	CASE WHEN MIDNew LIKE '%)AU%' THEN 'eToroAU'
		 WHEN MIDNew LIKE '%)UK%' THEN 'eToroUK'
		 WHEN MIDNew LIKE '%)EU%' THEN 'eToroEU'
		 WHEN MIDNew LIKE '%)ME%' THEN 'eToroME'
		 WHEN MIDNew LIKE '%EMUK%' THEN 'EMUK'
	ELSE 'NA' END
WHERE FundingTypeID = 2 AND MIDNameNew = 'NA'

-- select * from #midPrep2 where DepositID = 56625837


/*************************************
     cashouts
************************************/

--- mimic [Billing].[GetMerchantDetailsForOneAccountByDepotOnly] function

-- 1: bring in  Billing.MerchantAccountRouting

IF OBJECT_ID('tempdb..#MerchantAccountRouting') IS NOT NULL DROP TABLE #MerchantAccountRouting;
CREATE TABLE #MerchantAccountRouting  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT * FROM [BI_DB_dbo].[External_eToro_Billing_MerchantAccountRouting];

-- 2: bring in  Dictionary.MerchantAccount

IF OBJECT_ID('tempdb..#MerchantAccount') IS NOT NULL DROP TABLE #MerchantAccount;
CREATE TABLE #MerchantAccount  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT * FROM [BI_DB_dbo].[External_eToro_Dictionary_MerchantAccount];

-- 3: join with conditions

IF OBJECT_ID('tempdb..#GetMerchantDetailsForOneAccountByDepotOnly') IS NOT NULL DROP TABLE #GetMerchantDetailsForOneAccountByDepotOnly;
CREATE TABLE #GetMerchantDetailsForOneAccountByDepotOnly  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT ma1.MerchantAccountID, ma1.MerchantID, ma1.Name, ma1.BODescription, mar.DepotID, mar.RegulationID
FROM #MerchantAccountRouting mar
	JOIN #MerchantAccount ma1
		ON mar.MerchantAccountID = ma1.MerchantAccountID
WHERE mar.CurrencyID = 0
AND mar.PaymentTypeID = 0
AND mar.DepotModeID = 1
AND mar.CountryID = 0
AND mar.SubTypeID = 0;



--- mimic [BackOffice].[GetMerchantDetails] function

-- 1: this is based only on merchant account no depot

IF OBJECT_ID('tempdb..#BackOfficeGetMerchantDetails') IS NOT NULL DROP TABLE #BackOfficeGetMerchantDetails;
CREATE TABLE #BackOfficeGetMerchantDetails  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT ma.MerchantAccountID, ma.MerchantID, ma.Name, ma.BODescription
FROM #MerchantAccount ma


/*
IF OBJECT_ID('tempdb..#MapMerchantCodeToMid') IS NOT NULL DROP TABLE #MapMerchantCodeToMid
CREATE TABLE #MapMerchantCodeToMid  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT * FROM [BI_DB_dbo].[External_eToro_Dictionary_MapMerchantCodeToMid]
*/


IF OBJECT_ID('tempdb..#BDEP') IS NOT NULL DROP TABLE #BDEP
CREATE TABLE #BDEP  
    WITH (CLUSTERED INDEX(DepositWithdrawID),DISTRIBUTION=HASH(DepositWithdrawID))
AS
SELECT
	bddwf.DateID
  , bddwf.CID
  , bddwf.DepositWithdrawID
  , bddwf.DepositWithdrawID AS DepositID
  , bddwf.Occurred
  , bddwf.TransactionType
  , bddwf.Currency
  , bddwf.RegulationID
  , bddwf.Depot
  , bddwf.MIDValue
  , fbd.CurrencyID
  , fbd.FundingID
  , fbd.DepotID
  , fbd.FundingTypeID
  , fbd.ProtocolMIDSettingsID
  , fbd.MerchantAccountID
FROM BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf
JOIN DWH_dbo.Fact_BillingDeposit fbd
	ON bddwf.DepositWithdrawID = fbd.DepositID
WHERE bddwf.DateID = @StartDateID
AND bddwf.TransactionType = 'Deposit'



IF OBJECT_ID('tempdb..#historyCreditYest') IS NOT NULL DROP TABLE #historyCreditYest 
CREATE TABLE #historyCreditYest  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT * 
FROM DWH_dbo.Fact_CustomerAction fca
WHERE fca.DateID = @StartDateID
AND fca.ActionTypeID IN (8)


IF OBJECT_ID('tempdb..#wtf') IS NOT NULL DROP TABLE #wtf
CREATE TABLE #wtf
    WITH (HEAP,DISTRIBUTION=hash(ID))
AS
SELECT wtf.* FROM BI_DB_dbo.External_etoro_billing_vWithdrawToFunding_Alltime wtf
JOIN #historyCreditYest cy
	ON cy.WithdrawPaymentID = wtf.ID




IF OBJECT_ID('tempdb..#fsc') IS NOT NULL DROP TABLE #fsc
CREATE TABLE #fsc  
    WITH (HEAP,DISTRIBUTION=HASH(CID))
AS
SELECT fsc.RealCID AS CID, fsc.CountryID, fsc.LabelID, fsc.PlayerStatusID, fsc.RegulationID, fsc.PlayerLevelID, fsc.IsValidCustomer, fsc.IsCreditReportValidCB
FROM DWH_dbo.Fact_SnapshotCustomer fsc
	JOIN DWH_dbo.Dim_Range dr1
		ON fsc.DateRangeID = dr1.DateRangeID AND @StartDateID BETWEEN dr1.FromDateID AND dr1.ToDateID

IF OBJECT_ID('tempdb..#wtfAction') IS NOT NULL DROP TABLE #wtfAction -- select count(*) from #wtfAction select top 10 * from #wtfAction
CREATE TABLE #wtfAction  
    WITH (HEAP,DISTRIBUTION=HASH(BW2F_ID))
AS
SELECT * FROM Dealing_staging.External_Etoro_History_WithdrawToFundingAction



IF OBJECT_ID('tempdb..#BackOfficeGetMerchantDetailsPrep') IS NOT NULL DROP TABLE #BackOfficeGetMerchantDetailsPrep
CREATE TABLE #BackOfficeGetMerchantDetailsPrep  
    WITH (clustered index (WithdrawProcessingID),DISTRIBUTION=hash(WithdrawProcessingID))
AS
SELECT COALESCE(BW2F_ID,y.ID) AS WithdrawProcessingID, COALESCE(a.MerchantAccountID, y.MerchantAccountID) AS MerchantAccountID
FROM #wtfAction a
	FULL OUTER JOIN #wtf y
		ON a.BW2F_ID = y.ID

-- select * from #wtfAction
-- select * from ##wtf


--DECLARE @StartDate DATE = '20240101'
--DECLARE @StartDateID INT = CONVERT(VARCHAR(8), @StartDate, 112)

IF OBJECT_ID('tempdb..#bwtf') IS NOT NULL DROP TABLE #bwtf -- SELECT * FROM #bwtf
CREATE TABLE #bwtf  
    WITH (CLUSTERED INDEX (WithdrawPaymentID),DISTRIBUTION=HASH(WithdrawPaymentID))
AS
SELECT rbt.*
FROM DWH_dbo.Fact_BillingWithdraw rbt
WHERE cast(rbt.ModificationDate_WithdrawToFunding AS DATE) = @StartDate

--SELECT TOP 10 ModificationDate_WithdrawToFunding FROM DWH_dbo.Fact_BillingWithdraw

IF OBJECT_ID('tempdb..#wtf_T_HistoryAction') IS NOT NULL DROP TABLE #wtf_T_HistoryAction
CREATE TABLE #wtf_T_HistoryAction  
    WITH (HEAP,DISTRIBUTION=HASH(BW2F_ID))
AS
SELECT a.BW2F_ID, a.MerchantAccountID, a.FundingID
FROM
(
SELECT wtfa.*, ROW_NUMBER () OVER (PARTITION BY wtfa.BW2F_ID ORDER BY wtfa.ModificationDate desc) AS RN
FROM DWH_staging.etoro_History_WithdrawToFundingAction wtfa
WHERE BW2F_ID IN (SELECT WithdrawPaymentID FROM #bwtf)
AND wtfa.CashoutStatusID IN (3) 
AND wtfa.MerchantAccountID IS NOT NULL
) a
WHERE a.RN = 1

-- DECLARE @StartDate DATE = '20240304'

IF OBJECT_ID('tempdb..#ProcessTracking') IS NOT NULL DROP TABLE #ProcessTracking
CREATE TABLE #ProcessTracking  
    WITH (HEAP,DISTRIBUTION=HASH(WithdrawPaymentID))
AS
SELECT              
BWTF.CID,        
BWTF.WithdrawPaymentID,  
BWTF.WithdrawID,              
BWTF.DepotID,
BWTF.DepositID AS [Deposit ID],              
DR.Name AS [Regulation],     
BWTF.FundingTypeID_Funding,
 CASE          
	WHEN BWTF.DepotID IN (35, 36, 37, 38, 39, 40, 41, 42, 43) THEN DR2.Name      
	WHEN BWTF.DepotID IN (1,24,25,26,/*12,*/78,79,80,4,/*88,*/ 75,86) THEN gmdfoabdo.BODescription       
	WHEN BWTF.FundingTypeID_Funding IN (2) THEN BPMS1.Description      
	ELSE COALESCE(bogmd.BODescription, bogmd2.BODescription, DR1.Name)
 END AS [MIDName],        
 CASE          
    WHEN BWTF.DepotID IN (35, 36, 37, 38, 39, 40, 41, 42, 43, 44) THEN BPMS2.[Value]        
    WHEN BWTF.DepotID IN (1,24,25,26,/*12,*/ 78,79,80,4,/*88,*/ 75,86) THEN gmdfoabdo.[Name]     
    WHEN BWTF.FundingTypeID_Funding IN (2) THEN BPMS1.[Value]      
    WHEN BWTF.DepotID IN (18) THEN BPMS1.[Value]          
	ELSE COALESCE (bogmd.Name, bogmd2.Name, BPMS1.Description, BMMC.MID, BPMS1.[Value])
 END AS [MID]          
FROM #bwtf BWTF WITH (NOLOCK)  -----   select * from #bwtf   
LEFT JOIN #fsc f
	ON BWTF.CID = f.CID
LEFT JOIN #wtf w
	ON BWTF.WithdrawPaymentID = w.ID
LEFT JOIN #BDEP BDEP WITH (NOLOCK)   ------           
  ON BWTF.DepositID = BDEP.DepositID              
LEFT JOIN DWH_dbo.Dim_BillingProtocolMIDSettingsID BPMS1 WITH (NOLOCK) -----     ProtocolMIDSettingsID       
  ON BWTF.ProtocolMIDSettingsID = BPMS1.ProtocolMIDSettingsID              
LEFT JOIN DWH_dbo.Dim_Regulation DR1 WITH (NOLOCK)  --------            
  ON DR1.DWHRegulationID = BPMS1.RegulationID              
LEFT JOIN DWH_dbo.Dim_Regulation DR WITH (NOLOCK) -----              
  ON f.RegulationID = DR.DWHRegulationID              
LEFT JOIN #MapMerchantCodeToMid BMMC WITH (NOLOCK)  ---------            
  ON BMMC.MerchantCode = BPMS1.[Value] AND BMMC.CurrencyID = BDEP.CurrencyID AND BPMS1.RegulationID = BMMC.RegulationID   
LEFT JOIN #GetMerchantDetailsForOneAccountByDepotOnly gmdfoabdo
	ON BWTF.DepotID = gmdfoabdo.DepotID AND f.RegulationID = gmdfoabdo.RegulationID
LEFT JOIN #BackOfficeGetMerchantDetails bogmd
	ON w.MerchantAccountID = bogmd.MerchantAccountID
LEFT JOIN DWH_dbo.Dim_BillingProtocolMIDSettingsID BPMS2 WITH (NOLOCK)    -- select * from   DWH_dbo.Dim_BillingProtocolMIDSettingsID        
  ON BDEP.ProtocolMIDSettingsID = BPMS2.ProtocolMIDSettingsID   
LEFT JOIN DWH_dbo.Dim_Regulation DR2 WITH (NOLOCK)              
  ON DR2.DWHRegulationID = BPMS2.RegulationID   
LEFT JOIN #BackOfficeGetMerchantDetails bogmd2
	ON bogmd2.MerchantAccountID = BPMS1.MerchantAccountID

UPDATE #ProcessTracking
SET MID = 'PWMBUS',
	MIDName = 'eToroUS'
WHERE MID IS NULL AND MIDName IS NULL AND FundingTypeID_Funding = 32


IF OBJECT_ID('tempdb..#final') IS NOT NULL DROP TABLE #final
CREATE TABLE #final  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT cast(p.DepositID AS VARCHAR (20)) + 'D' AS TransactionID
	 , p.MIDNameNew
	 , p.MIDNew 
	 , 'Deposit' AS ActionType
FROM #midPrep2 p
UNION ALL 
SELECT cast(t.WithdrawPaymentID as VARCHAR(20)) + 'W' AS TransactionID
	 , t.MIDName as MIDNameNew
	 , t.MID as MIDNew
	, 'Withdraw' AS ActionType
FROM #ProcessTracking t
WHERE t.WithdrawPaymentID IS NOT NULL

-- select * from #final where ActionType = 'Deposit'
-- select * from #final where TransactionID = '56625837D'

DELETE FROM BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings WHERE [Date] = @StartDate

INSERT INTO BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings
	(
	 [Date] 
	 ,DateID 
	 ,TransactionID
	 ,MIDName 
	 ,MID
	 ,ActionType 
	 ,UpdateDate 
	)
SELECT 
	@StartDate AS [Date]
	, @StartDateID AS DateID
	, f.TransactionID
	, f.MIDNameNew
	, f.MIDNew
	, f.ActionType
	, GETDATE() AS UpdateDate
FROM #final f

-- select * from BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings where DateID = 20240304 and TransactionID = '12443434W'

END


/* join to depositwithdrawfee query: 

SELECT bddwf.DateID
	 , bddwf.CID
	 , bddwf.TransactionID
	 , bdprms.MID as MIDValue
	 , bdprms.MIDName AS Entity
FROM BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf
JOIN BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings bdprms
	ON bddwf.Date = bdprms.Date 
		AND bddwf.TransactionID = bdprms.TransactionID
where bddwf.Date = '20240119'

*/

--select * from BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings



GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_PIPs_Report_MID_Settings` | synapse_sp | BI_DB_dbo | SP_PIPs_Report_MID_Settings | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_PIPs_Report_MID_Settings.sql` |
| `BI_DB_dbo.External_eToro_Dictionary_MapMerchantCodeToMid` | unresolved | BI_DB_dbo | External_eToro_Dictionary_MapMerchantCodeToMid | `—` |
| `BI_DB_dbo.External_eToro_Billing_MerchantAccountRouting` | unresolved | BI_DB_dbo | External_eToro_Billing_MerchantAccountRouting | `—` |
| `BI_DB_dbo.External_eToro_Dictionary_MerchantAccount` | unresolved | BI_DB_dbo | External_eToro_Dictionary_MerchantAccount | `—` |
| `BI_DB_dbo.BI_DB_DepositWithdrawFee` | synapse | BI_DB_dbo | BI_DB_DepositWithdrawFee | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `DWH_dbo.Fact_BillingDeposit` | synapse | DWH_dbo | Fact_BillingDeposit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `DWH_dbo.Dim_BillingProtocolMIDSettingsID` | synapse | DWH_dbo | Dim_BillingProtocolMIDSettingsID | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingProtocolMIDSettingsID.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `DWH_dbo.Fact_CustomerAction` | synapse | DWH_dbo | Fact_CustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `BI_DB_dbo.External_etoro_billing_vWithdrawToFunding_Alltime` | unresolved | BI_DB_dbo | External_etoro_billing_vWithdrawToFunding_Alltime | `—` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `Dealing_staging.External_Etoro_History_WithdrawToFundingAction` | unresolved | Dealing_staging | External_Etoro_History_WithdrawToFundingAction | `—` |
| `DWH_dbo.Fact_BillingWithdraw` | synapse | DWH_dbo | Fact_BillingWithdraw | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `DWH_staging.etoro_History_WithdrawToFundingAction` | unresolved | DWH_staging | etoro_History_WithdrawToFundingAction | `—` |

