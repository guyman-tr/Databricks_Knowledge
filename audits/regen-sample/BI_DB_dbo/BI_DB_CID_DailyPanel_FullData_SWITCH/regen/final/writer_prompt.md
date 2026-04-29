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
- **Object**: `BI_DB_CID_DailyPanel_FullData_SWITCH`
- **Attempt**: `2`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_CID_DailyPanel_FullData_SWITCH/regen/attempt_2/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_CID_DailyPanel_FullData_SWITCH\regen\attempt_2`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_CID_DailyPanel_FullData_SWITCH\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH]
(
	[CID] [int] NOT NULL,
	[DateID] [int] NOT NULL,
	[Active_Month] [int] NULL,
	[ActiveDate] [date] NULL,
	[Seniority] [int] NULL,
	[Seniority_Seg] [varchar](11) NOT NULL,
	[Reg_Month] [int] NULL,
	[RegDate] [date] NULL,
	[IsReg_ThisD] [int] NOT NULL,
	[FTD_Month] [int] NULL,
	[FTDdate] [date] NULL,
	[IsFTD_ThisD] [int] NOT NULL,
	[FTDA] [money] NULL,
	[Region] [nvarchar](500) NOT NULL,
	[Country] [varchar](500) NULL,
	[Channel] [nvarchar](500) NOT NULL,
	[SubChannel] [nvarchar](500) NOT NULL,
	[AffiliateID] [int] NULL,
	[FirstAction] [varchar](22) NULL,
	[FirstInstrument] [varchar](50) NULL,
	[V2_Complete] [int] NOT NULL,
	[V3_Complete] [int] NOT NULL,
	[IsPro] [int] NOT NULL,
	[IsOTD] [int] NULL,
	[Daily_Classification] [varchar](50) NULL,
	[EOD_Club] [varchar](50) NOT NULL,
	[EOD_Regulation] [varchar](50) NOT NULL,
	[Equity] [decimal](23, 4) NULL,
	[RealizedEquity] [money] NULL,
	[AUM] [money] NULL,
	[Credit] [money] NOT NULL,
	[ActiveUser] [int] NOT NULL,
	[Active] [int] NOT NULL,
	[ActiveOpen] [int] NOT NULL,
	[IsOpen_Copy] [int] NOT NULL,
	[Count_Opened_Copy] [int] NOT NULL,
	[Count_Closed_Copy] [int] NOT NULL,
	[MoneyIn_Copy] [decimal](38, 2) NOT NULL,
	[MoneyOut_Copy] [decimal](38, 2) NOT NULL,
	[IsOpen_CopyPortfolio] [int] NOT NULL,
	[Count_Opened_CopyPortfolio] [int] NOT NULL,
	[Count_Closed_CopyPortfolio] [int] NOT NULL,
	[MoneyIn_CopyPortfolio] [decimal](38, 2) NOT NULL,
	[MoneyOut_CopyPortfolio] [decimal](38, 2) NOT NULL,
	[Active_Copy] [int] NOT NULL,
	[Active_Real_Stocks] [int] NOT NULL,
	[Active_CFD_Stocks] [int] NOT NULL,
	[Active_Real_Crypto] [int] NOT NULL,
	[Active_CFD_Crypto] [int] NOT NULL,
	[Active_FX/Comm/Ind] [int] NOT NULL,
	[ActiveOpen_Copy] [int] NOT NULL,
	[ActiveOpen_Real_Stocks] [int] NOT NULL,
	[ActiveOpen_CFD_Stocks] [int] NOT NULL,
	[ActiveOpen_Real_Crypto] [int] NOT NULL,
	[ActiveOpen_CFD_Crypto] [int] NOT NULL,
	[ActiveOpen_FX/Comm/Ind] [int] NOT NULL,
	[NewTrades_Copy] [int] NOT NULL,
	[NewTrades_Real_Stocks] [int] NOT NULL,
	[NewTrades_CFD_Stocks] [int] NOT NULL,
	[NewTrades_Real_Crypto] [int] NOT NULL,
	[NewTrades_CFD_Crypto] [int] NOT NULL,
	[NewTrades_FX/Comm/Ind] [int] NOT NULL,
	[NewTrades_Total] [int] NULL,
	[AmountIn_NewTrades_Copy] [money] NOT NULL,
	[AmountIn_NewTrades_Real_Stocks] [money] NOT NULL,
	[AmountIn_NewTrades_CFD_Stocks] [money] NOT NULL,
	[AmountIn_NewTrades_Real_Crypto] [money] NOT NULL,
	[AmountIn_NewTrades_CFD_Crypto] [money] NOT NULL,
	[AmountIn_NewTrades_FX/Comm/Ind] [money] NOT NULL,
	[AmountIn_NewTrades_Total] [money] NULL,
	[Revenue_Copy] [decimal](38, 2) NOT NULL,
	[Revenue_Real_Stocks] [decimal](38, 2) NOT NULL,
	[Revenue_CFD_Stocks] [decimal](38, 2) NOT NULL,
	[Revenue_Real_Crypto] [decimal](38, 2) NOT NULL,
	[Revenue_CFD_Crypto] [decimal](38, 2) NOT NULL,
	[Revenue_FX/Comm/Ind] [decimal](38, 2) NOT NULL,
	[Revenue_Total] [decimal](38, 2) NULL,
	[PnL_Copy] [decimal](38, 4) NOT NULL,
	[PnL_Real_Stocks] [decimal](38, 4) NOT NULL,
	[PnL_CFD_Stocks] [decimal](38, 4) NOT NULL,
	[PnL_Real_Crypto] [decimal](38, 4) NOT NULL,
	[PnL_CFD_Crypto] [decimal](38, 4) NOT NULL,
	[PnL_FX/Comm/Ind] [decimal](38, 4) NOT NULL,
	[PnL_Total] [decimal](38, 4) NULL,
	[TotalDeposits] [decimal](38, 2) NOT NULL,
	[CountDeposits] [int] NOT NULL,
	[TotalCashouts] [decimal](38, 2) NOT NULL,
	[TotalCoFee] [money] NOT NULL,
	[NetDeposits] [decimal](38, 2) NULL,
	[ACC_Revenue_Copy] [decimal](38, 2) NULL,
	[ACC_Revenue_Real_Stocks] [decimal](38, 2) NULL,
	[ACC_Revenue_CFD_Stocks] [decimal](38, 2) NULL,
	[ACC_Revenue_Real_Crypto] [decimal](38, 2) NULL,
	[ACC_Revenue_CFD_Crypto] [decimal](38, 2) NULL,
	[ACC_Revenue_FX/Comm/Ind] [decimal](38, 2) NULL,
	[ACC_Revenue_Total] [decimal](38, 2) NULL,
	[ACC_PnL_Copy] [decimal](38, 4) NULL,
	[ACC_PnL_Real_Stocks] [decimal](38, 4) NULL,
	[ACC_PnL_CFD_Stocks] [decimal](38, 4) NULL,
	[ACC_PnL_Real_Crypto] [decimal](38, 4) NULL,
	[ACC_PnL_CFD_Crypto] [decimal](38, 4) NULL,
	[ACC_PnL_FX/Comm/Ind] [decimal](38, 4) NULL,
	[ACC_PnL_Total] [decimal](38, 4) NULL,
	[ACC_TotalDeposits] [decimal](38, 2) NULL,
	[ACC_CountDeposits] [int] NULL,
	[ACC_TotalCashouts] [decimal](38, 2) NULL,
	[ACC_TotalCoFee] [money] NULL,
	[ACC_NetDeposits] [decimal](38, 2) NULL,
	[UpdateDate] [datetime] NOT NULL,
	[AccountManager] [varchar](101) NULL,
	[IsIslamic] [int] NOT NULL,
	[IsContacted] [int] NOT NULL,
	[IsContactedAmount] [money] NOT NULL,
	[EOD_IsFunded] [int] NOT NULL,
	[WithdrawalToWallet] [decimal](38, 2) NOT NULL,
	[ACC_WithdrawalToWallet] [decimal](38, 2) NULL,
	[LastApplicationProAccountDate] [date] NOT NULL,
	[LastPosOpenDate] [date] NULL,
	[LastLoggedIn] [date] NULL,
	[EOD_Equity_Copy] [money] NULL,
	[EOD_Equity_Real_Crypto] [money] NULL,
	[EOD_Equity_Real_Stocks] [money] NULL,
	[EOD_Equity_CFD_Crypto] [money] NULL,
	[EOD_Equity_CFD_Stocks] [money] NULL,
	[EOD_Equity_FX/Comm/Ind] [money] NULL,
	[EOD_Equity_Real_Crypto_Lev1] [money] NULL,
	[EOD_Equity_Real_Stocks_LevCFD] [money] NULL,
	[EOD_Equity_CFD_Crypto_Lev1] [money] NULL,
	[EOD_Equity_CFD_Stocks_LevCFD] [money] NULL,
	[Active_Real_Stocks_Lev1] [tinyint] NULL,
	[Active_CFD_Stocks_LevCFD] [tinyint] NULL,
	[Active_Real_Crypto_Lev1] [tinyint] NULL,
	[Active_CFD_Crypto_LevCFD] [tinyint] NULL,
	[ActiveOpen_Real_Stocks_Lev1] [tinyint] NULL,
	[ActiveOpen_CFD_Stocks_LevCFD] [tinyint] NULL,
	[ActiveOpen_Real_Crypto_Lev1] [tinyint] NULL,
	[ActiveOpen_CFD_Crypto_LevCFD] [tinyint] NULL,
	[NewTrades_Real_Stocks_Lev1] [int] NULL,
	[NewTrades_CFD_Stocks_LevCFD] [int] NULL,
	[NewTrades_Real_Crypto_Lev1] [int] NULL,
	[NewTrades_CFD_Crypto_LevCFD] [int] NULL,
	[AmountIn_NewTrades_Real_Stocks_Lev1] [money] NULL,
	[AmountIn_NewTrades_CFD_Stocks_LevCFD] [money] NULL,
	[AmountIn_NewTrades_Real_Crypto_Lev1] [money] NULL,
	[AmountIn_NewTrades_CFD_Crypto_LevCFD] [money] NULL,
	[Revenue_Real_Stocks_Lev1] [money] NULL,
	[Revenue_CFD_Stocks_LevCFD] [money] NULL,
	[Revenue_Real_Crypto_Lev1] [money] NULL,
	[Revenue_CFD_Crypto_LevCFD] [money] NULL,
	[PnL_Real_Stocks_Lev1] [money] NULL,
	[PnL_CFD_Stocks_LevCFD] [money] NULL,
	[PnL_Real_Crypto_Lev1] [money] NULL,
	[PnL_CFD_Crypto_LevCFD] [money] NULL,
	[IsFunded_New] [int] NULL,
	[NewMarketingRegion] [varchar](50) NULL,
	[Active_FX] [int] NULL,
	[Active_Comm] [int] NULL,
	[Active_Ind] [int] NULL,
	[ActiveOpen_FX] [int] NULL,
	[ActiveOpen_Comm] [int] NULL,
	[ActiveOpen_Ind] [int] NULL,
	[Revenue_FX] [decimal](38, 2) NULL,
	[Revenue_Comm] [decimal](38, 2) NULL,
	[Revenue_Ind] [decimal](38, 2) NULL,
	[PnL_FX] [decimal](38, 2) NULL,
	[PnL_Comm] [decimal](38, 2) NULL,
	[PnL_Ind] [decimal](38, 2) NULL,
	[FirstNewFundedDate] [date] NULL,
	[ACC_ChurnDays] [int] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CID] ),
	CLUSTERED COLUMNSTORE INDEX,
	PARTITION
	(
		[DateID] RANGE LEFT FOR VALUES (20180101, 20180102, 20180103, 20180104, 20180105, 20180106, 20180107, 20180108, 20180109, 20180110, 20180111, 20180112, 20180113, 20180114, 20180115, 20180116, 20180117, 20180118, 20180119, 20180120, 20180121, 20180122, 20180123, 20180124, 20180125, 20180126, 20180127, 20180128, 20180129, 20180130, 20180131, 20180201, 20180202, 20180203, 20180204, 20180205, 20180206, 20180207, 20180208, 20180209, 20180210, 20180211, 20180212, 20180213, 20180214, 20180215, 20180216, 20180217, 20180218, 20180219, 20180220, 20180221, 20180222, 20180223, 20180224, 20180225, 20180226, 20180227, 20180228, 20180301, 20180302, 20180303, 20180304, 20180305, 20180306, 20180307, 20180308, 20180309, 20180310, 20180311, 20180312, 20180313, 20180314, 20180315, 20180316, 20180317, 20180318, 20180319, 20180320, 20180321, 20180322, 20180323, 20180324, 20180325, 20180326, 20180327, 20180328, 20180329, 20180330, 20180331, 20180401, 20180402, 20180403, 20180404, 20180405, 20180406, 20180407, 20180408, 20180409, 20180410, 20180411, 20180412, 20180413, 20180414, 20180415, 20180416, 20180417, 20180418, 20180419, 20180420, 20180421, 20180422, 20180423, 20180424, 20180425, 20180426, 20180427, 20180428, 20180429, 20180430, 20180501, 20180502, 20180503, 20180504, 20180505, 20180506, 20180507, 20180508, 20180509, 20180510, 20180511, 20180512, 20180513, 20180514, 20180515, 20180516, 20180517, 20180518, 20180519, 20180520, 20180521, 20180522, 20180523, 20180524, 20180525, 20180526, 20180527, 20180528, 20180529, 20180530, 20180531, 20180601, 20180602, 20180603, 20180604, 20180605, 20180606, 20180607, 20180608, 20180609, 20180610, 20180611, 20180612, 20180613, 20180614, 20180615, 20180616, 20180617, 20180618, 20180619, 20180620, 20180621, 20180622, 20180623, 20180624, 20180625, 20180626, 20180627, 20180628, 20180629, 20180630, 20180701, 20180702, 20180703, 20180704, 20180705, 20180706, 20180707, 20180708, 20180709, 20180710, 20180711, 20180712, 20180713, 20180714, 20180715, 20180716, 20180717, 20180718, 20180719, 20180720, 20180721, 20180722, 20180723, 20180724, 20180725, 20180726, 20180727, 20180728, 20180729, 20180730, 20180731, 20180801, 20180802, 20180803, 20180804, 20180805, 20180806, 20180807, 20180808, 20180809, 20180810, 20180811, 20180812, 20180813, 20180814, 20180815, 20180816, 20180817, 20180818, 20180819, 20180820, 20180821, 20180822, 20180823, 20180824, 20180825, 20180826, 20180827, 20180828, 20180829, 20180830, 20180831, 20180901, 20180902, 20180903, 20180904, 20180905, 20180906, 20180907, 20180908, 20180909, 20180910, 20180911, 20180912, 20180913, 20180914, 20180915, 20180916, 20180917, 20180918, 20180919, 20180920, 20180921, 20180922, 20180923, 20180924, 20180925, 20180926, 20180927, 20180928, 20180929, 20180930, 20181001, 20181002, 20181003, 20181004, 20181005, 20181006, 20181007, 20181008, 20181009, 20181010, 20181011, 20181012, 20181013, 20181014, 20181015, 20181016, 20181017, 20181018, 20181019, 20181020, 20181021, 20181022, 20181023, 20181024, 20181025, 20181026, 20181027, 20181028, 20181029, 20181030, 20181031, 20181101, 20181102, 20181103, 20181104, 20181105, 20181106, 20181107, 20181108, 20181109, 20181110, 20181111, 20181112, 20181113, 20181114, 20181115, 20181116, 20181117, 20181118, 20181119, 20181120, 20181121, 20181122, 20181123, 20181124, 20181125, 20181126, 20181127, 20181128, 20181129, 20181130, 20181201, 20181202, 20181203, 20181204, 20181205, 20181206, 20181207, 20181208, 20181209, 20181210, 20181211, 20181212, 20181213, 20181214, 20181215, 20181216, 20181217, 20181218, 20181219, 20181220, 20181221, 20181222, 20181223, 20181224, 20181225, 20181226, 20181227, 20181228, 20181229, 20181230, 20181231, 20190101, 20190102, 20190103, 20190104, 20190105, 20190106, 20190107, 20190108, 20190109, 20190110, 20190111, 20190112, 20190113, 20190114, 20190115, 20190116, 20190117, 20190118, 20190119, 20190120, 20190121, 20190122, 20190123, 20190124, 20190125, 20190126, 20190127, 20190128, 20190129, 20190130, 20190131, 20190201, 20190202, 20190203, 20190204, 20190205, 20190206, 20190207, 20190208, 20190209, 20190210, 20190211, 20190212, 20190213, 20190214, 20190215, 20190216, 20190217, 20190218, 20190219, 20190220, 20190221, 20190222, 20190223, 20190224, 20190225, 20190226, 20190227, 20190228, 20190301, 20190302, 20190303, 20190304, 20190305, 20190306, 20190307, 20190308, 20190309, 20190310, 20190311, 20190312, 20190313, 20190314, 20190315, 20190316, 20190317, 20190318, 20190319, 20190320, 20190321, 20190322, 20190323, 20190324, 20190325, 20190326, 20190327, 20190328, 20190329, 20190330, 20190331, 20190401, 20190402, 20190403, 20190404, 20190405, 20190406, 20190407, 20190408, 20190409, 20190410, 20190411, 20190412, 20190413, 20190414, 20190415, 20190416, 20190417, 20190418, 20190419, 20190420, 20190421, 20190422, 20190423, 20190424, 20190425, 20190426, 20190427, 20190428, 20190429, 20190430, 20190501, 20190502, 20190503, 20190504, 20190505, 20190506, 20190507, 20190508, 20190509, 20190510, 20190511, 20190512, 20190513, 20190514, 20190515, 20190516, 20190517, 20190518, 20190519, 20190520, 20190521, 20190522, 20190523, 20190524, 20190525, 20190526, 20190527, 20190528, 20190529, 20190530, 20190531, 20190601, 20190602, 20190603, 20190604, 20190605, 20190606, 20190607, 20190608, 20190609, 20190610, 20190611, 20190612, 20190613, 20190614, 20190615, 20190616, 20190617, 20190618, 20190619, 20190620, 20190621, 20190622, 20190623, 20190624, 20190625, 20190626, 20190627, 20190628, 20190629, 20190630, 20190701, 20190702, 20190703, 20190704, 20190705, 20190706, 20190707, 20190708, 20190709, 20190710, 20190711, 20190712, 20190713, 20190714, 20190715, 20190716, 20190717, 20190718, 20190719, 20190720, 20190721, 20190722, 20190723, 20190724, 20190725, 20190726, 20190727, 20190728, 20190729, 20190730, 20190731, 20190801, 20190802, 20190803, 20190804, 20190805, 20190806, 20190807, 20190808, 20190809, 20190810, 20190811, 20190812, 20190813, 20190814, 20190815, 20190816, 20190817, 20190818, 20190819, 20190820, 20190821, 20190822, 20190823, 20190824, 20190825, 20190826, 20190827, 20190828, 20190829, 20190830, 20190831, 20190901, 20190902, 20190903, 20190904, 20190905, 20190906, 20190907, 20190908, 20190909, 20190910, 20190911, 20190912, 20190913, 20190914, 20190915, 20190916, 20190917, 20190918, 20190919, 20190920, 20190921, 20190922, 20190923, 20190924, 20190925, 20190926, 20190927, 20190928, 20190929, 20190930, 20191001, 20191002, 20191003, 20191004, 20191005, 20191006, 20191007, 20191008, 20191009, 20191010, 20191011, 20191012, 20191013, 20191014, 20191015, 20191016, 20191017, 20191018, 20191019, 20191020, 20191021, 20191022, 20191023, 20191024, 20191025, 20191026, 20191027, 20191028, 20191029, 20191030, 20191031, 20191101, 20191102, 20191103, 20191104, 20191105, 20191106, 20191107, 20191108, 20191109, 20191110, 20191111, 20191112, 20191113, 20191114, 20191115, 20191116, 20191117, 20191118, 20191119, 20191120, 20191121, 20191122, 20191123, 20191124, 20191125, 20191126, 20191127, 20191128, 20191129, 20191130, 20191201, 20191202, 20191203, 20191204, 20191205, 20191206, 20191207, 20191208, 20191209, 20191210, 20191211, 20191212, 20191213, 20191214, 20191215, 20191216, 20191217, 20191218, 20191219, 20191220, 20191221, 20191222, 20191223, 20191224, 20191225, 20191226, 20191227, 20191228, 20191229, 20191230, 20191231, 20200101, 20200102, 20200103, 20200104, 20200105, 20200106, 20200107, 20200108, 20200109, 20200110, 20200111, 20200112, 20200113, 20200114, 20200115, 20200116, 20200117, 20200118, 20200119, 20200120, 20200121, 20200122, 20200123, 20200124, 20200125, 20200126, 20200127, 20200128, 20200129, 20200130, 20200131, 20200201, 20200202, 20200203, 20200204, 20200205, 20200206, 20200207, 20200208, 20200209, 20200210, 20200211, 20200212, 20200213, 20200214, 20200215, 20200216, 20200217, 20200218, 20200219, 20200220, 20200221, 20200222, 20200223, 20200224, 20200225, 20200226, 20200227, 20200228, 20200229, 20200301, 20200302, 20200303, 20200304, 20200305, 20200306, 20200307, 20200308, 20200309, 20200310, 20200311, 20200312, 20200313, 20200314, 20200315, 20200316, 20200317, 20200318, 20200319, 20200320, 20200321, 20200322, 20200323, 20200324, 20200325, 20200326, 20200327, 20200328, 20200329, 20200330, 20200331, 20200401, 20200402, 20200403, 20200404, 20200405, 20200406, 20200407, 20200408, 20200409, 20200410, 20200411, 20200412, 20200413, 20200414, 20200415, 20200416, 20200417, 20200418, 20200419, 20200420, 20200421, 20200422, 20200423, 20200424, 20200425, 20200426, 20200427, 20200428, 20200429, 20200430, 20200501, 20200502, 20200503, 20200504, 20200505, 20200506, 20200507, 20200508, 20200509, 20200510, 20200511, 20200512, 20200513, 20200514, 20200515, 20200516, 20200517, 20200518, 20200519, 20200520, 20200521, 20200522, 20200523, 20200524, 20200525, 20200526, 20200527, 20200528, 20200529, 20200530, 20200531, 20200601, 20200602, 20200603, 20200604, 20200605, 20200606, 20200607, 20200608, 20200609, 20200610, 20200611, 20200612, 20200613, 20200614, 20200615, 20200616, 20200617, 20200618, 20200619, 20200620, 20200621, 20200622, 20200623, 20200624, 20200625, 20200626, 20200627, 20200628, 20200629, 20200630, 20200701, 20200702, 20200703, 20200704, 20200705, 20200706, 20200707, 20200708, 20200709, 20200710, 20200711, 20200712, 20200713, 20200714, 20200715, 20200716, 20200717, 20200718, 20200719, 20200720, 20200721, 20200722, 20200723, 20200724, 20200725, 20200726, 20200727, 20200728, 20200729, 20200730, 20200731, 20200801, 20200802, 20200803, 20200804, 20200805, 20200806, 20200807, 20200808, 20200809, 20200810, 20200811, 20200812, 20200813, 20200814, 20200815, 20200816, 20200817, 20200818, 20200819, 20200820, 20200821, 20200822, 20200823, 20200824, 20200825, 20200826, 20200827, 20200828, 20200829, 20200830, 20200831, 20200901, 20200902, 20200903, 20200904, 20200905, 20200906, 20200907, 20200908, 20200909, 20200910, 20200911, 20200912, 20200913, 20200914, 20200915, 20200916, 20200917, 20200918, 20200919, 20200920, 20200921, 20200922, 20200923, 20200924, 20200925, 20200926, 20200927, 20200928, 20200929, 20200930, 20201001, 20201002, 20201003, 20201004, 20201005, 20201006, 20201007, 20201008, 20201009, 20201010, 20201011, 20201012, 20201013, 20201014, 20201015, 20201016, 20201017, 20201018, 20201019, 20201020, 20201021, 20201022, 20201023, 20201024, 20201025, 20201026, 20201027, 20201028, 20201029, 20201030, 20201031, 20201101, 20201102, 20201103, 20201104, 20201105, 20201106, 20201107, 20201108, 20201109, 20201110, 20201111, 20201112, 20201113, 20201114, 20201115, 20201116, 20201117, 20201118, 20201119, 20201120, 20201121, 20201122, 20201123, 20201124, 20201125, 20201126, 20201127, 20201128, 20201129, 20201130, 20201201, 20201202, 20201203, 20201204, 20201205, 20201206, 20201207, 20201208, 20201209, 20201210, 20201211, 20201212, 20201213, 20201214, 20201215, 20201216, 20201217, 20201218, 20201219, 20201220, 20201221, 20201222, 20201223, 20201224, 20201225, 20201226, 20201227, 20201228, 20201229, 20201230, 20201231, 20210101, 20210102, 20210103, 20210104, 20210105, 20210106, 20210107, 20210108, 20210109, 20210110, 20210111, 20210112, 20210113, 20210114, 20210115, 20210116, 20210117, 20210118, 20210119, 20210120, 20210121, 20210122, 20210123, 20210124, 20210125, 20210126, 20210127, 20210128, 20210129, 20210130, 20210131, 20210201, 20210202, 20210203, 20210204, 20210205, 20210206, 20210207, 20210208, 20210209, 20210210, 20210211, 20210212, 20210213, 20210214, 20210215, 20210216, 20210217, 20210218, 20210219, 20210220, 20210221, 20210222, 20210223, 20210224, 20210225, 20210226, 20210227, 20210228, 20210301, 20210302, 20210303, 20210304, 20210305, 20210306, 20210307, 20210308, 20210309, 20210310, 20210311, 20210312, 20210313, 20210314, 20210315, 20210316, 20210317, 20210318, 20210319, 20210320, 20210321, 20210322, 20210323, 20210324, 20210325, 20210326, 20210327, 20210328, 20210329, 20210330, 20210331, 20210401, 20210402, 20210403, 20210404, 20210405, 20210406, 20210407, 20210408, 20210409, 20210410, 20210411, 20210412, 20210413, 20210414, 20210415, 20210416, 20210417, 20210418, 20210419, 20210420, 20210421, 20210422, 20210423, 20210424, 20210425, 20210426, 20210427, 20210428, 20210429, 20210430)
	)
)

GO

```

---

## Upstream Wikis Found

Found 1 upstream wiki(s). Read EACH one in full.


### Upstream `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_DailyPanel_FullData.md`

# BI_DB_dbo.BI_DB_CID_DailyPanel_FullData

> Daily per-depositor customer panel — the broadest customer panel in BI_DB_dbo, covering all eToro depositors with 183 columns of daily activity, revenue, PnL, equity, copy trading, running accumulators, and demographic attributes. One row per depositor per day. 64.5M rows per daily date as of April 2026; data from 2018-01-01 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source ETL (see Section 4) |
| **Refresh** | Daily — DELETE WHERE DateID = @startDateINT + INSERT (SP_CID_DailyPanel_FullData, SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Partition** | RANGE LEFT on DateID, daily partitions 20180101–20260531 |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CID_DailyPanel_FullData is the primary daily CRM analytics panel for **all eToro depositors** — the broadest customer-level table in BI_DB_dbo. For each customer who has ever made a deposit (IsDepositor=1 in Fact_SnapshotCustomer), it provides a daily snapshot of their activity, financial metrics, trading behavior, acquisition attributes, and accumulated lifetime totals.

The table serves as the foundation for:
- **CRM reporting**: Customer segmentation, Club tier distribution, regulation analysis, activity funnels
- **Revenue analytics**: Daily and lifetime revenue by instrument type, with Islamic/ticket/conversion fee breakdown since 2025
- **PnL tracking**: Customer-side daily and lifetime P&L by instrument
- **Activity measurement**: Active, ActiveOpen, ActiveUser flags; Copy trading flows; new trades by type
- **Cashflow analysis**: Daily deposits, cashouts, and their lifetime accumulators

**Population boundary**: Only **depositors** are included — customers with `IsDepositor=1` at the snapshot date. Non-depositing registered customers are absent. ~5.9M distinct depositor rows per day as of April 2026.

**Instrument taxonomy**: Columns are systematically repeated across 6 asset class families:
- **Copy** — mirror-copy positions (MirrorID > 0)
- **Real Stocks** — settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6)
- **CFD Stocks** — leveraged stock/ETF CFDs (IsSettled=0)
- **Real Crypto** — settled crypto (InstrumentTypeID=10, IsSettled=1)
- **CFD Crypto** — leveraged crypto CFDs
- **FX/Comm/Ind** — forex, commodities, indices (InstrumentTypeID IN 1,2,4)

A secondary **Lev1/LevCFD split** duplicates Active, ActiveOpen, NewTrades, AmountIn, Revenue, PnL, and EOD_Equity columns: Lev1 = leverage=1 AND IsBuy=1 (long unlevered position); LevCFD = leveraged or short position. These mirror the IsSettled split for stocks and crypto, using a leverage-based test instead of the settled flag.

**ACC_ prefix**: 14 cumulative columns accumulate lifetime totals from first deposit date by reading the previous day's row and adding today's increment. On a customer's first day in the table, ACC_ initialises from the day's values.

**Column evolution**: The SP has been extended 8 times since 2020. Columns 168–183 (FirstNewFundedDate, ACC_ChurnDays, EOD_LSD, ActiveOpen_AirDrop/Mirror/Manual/IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, CashoutsAdjusted, Transactional_Revenue_Total, ACC_Transactional_Revenue_Total, Revenue_TicketFeeByPercent) were added 2021–2025. Historical rows pre-dating the column additions will show NULL for these columns.

**Daily_Classification** (EOD_Segment): This column is assigned by a separate SP (`SP_CID_DailyPanel_UpdateCluster`) that runs after the main insert. As of April 2026 all rows contain an empty string — the cluster assignment appears to be no longer operational post-Synapse migration. Historical 2018–2020 rows contain values like "Traders", "Crypto", etc.

---

## 2. Business Logic

### 2.1 EOD_Club — Loyalty Tier

**What**: Customer's eToro Club loyalty tier at end of day, based on `Dim_PlayerLevel` with a custom LowBronze/HighBronze split.

**Columns Involved**: `EOD_Club`

**Rules**:
```
EOD_Club =
  WHEN EOD_Equity < 1000 AND Dim_PlayerLevel.PlayerLevelID = 1  → 'LowBronze'
  WHEN Dim_PlayerLevel.PlayerLevelID = 1                         → 'HighBronze'
  ELSE Dim_PlayerLevel.Name                                      → 'Silver'/'Gold'/'Platinum'/'Platinum Plus'/'Diamond'
```
Bronze (PlayerLevelID=1) is split into two ranges at the $1,000 equity mark. Silver through Diamond use the Dim_PlayerLevel.Name directly. Observed distribution (April 2026): LowBronze 79.8%, HighBronze 7.2%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%.

### 2.2 EOD_Regulation

**What**: Customer's regulatory jurisdiction at end of day.

**Columns Involved**: `EOD_Regulation`

**Rules**: Read from `Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`. Observed distribution (April 2026): CySEC 56.5%, FCA 24.2%, FinCEN+FINRA 5.6%, ASIC & GAML 5.3%, FSA Seychelles 4.2%, others < 2%.

### 2.3 ActiveOpen — Position Opened Today

**What**: Flag: customer opened at least one trading position on this date (manual, mirror, or mirror-add; excludes AirDrop positions).

**Columns Involved**: `ActiveOpen`, `ActiveOpen_Manual`, `ActiveOpen_Mirror`

**Rules**:
```
ActiveOpen = 1 IF (ActiveOpen_Manual=1) OR (ActiveOpen_NewMirror=1) OR (ActiveOpen_AddMirror=1)
ActiveOpen_Manual  = has a position opened today with MirrorID=0 AND IsAirDrop=0
ActiveOpen_Mirror  = opened a new DWH_dbo.Dim_Mirror row today (MirrorTypeID IN 1,4)
                     OR added mirror allocation today (Fact_CustomerAction ActionTypeID=15)
ActiveOpen_AirDrop = has a position opened today where IsAirDrop=1
ActiveOpen_IncludeCopy = manual + copy combined, excludes only AirDrop
```

### 2.4 Active vs ActiveOpen vs ActiveUser

| Column | Meaning | Source |
|---|---|---|
| `Active` | Any position held or closed on this date (any instrument) | Dim_Position, any row in date range |
| `ActiveOpen` | Opened a new position today (manual/mirror) | Dim_Position WHERE OpenDateID = today |
| `ActiveUser` | Logged in today | Fact_CustomerAction ActionTypeID=14 |

### 2.5 ACC_ Running Totals

**What**: Columns prefixed `ACC_` are lifetime running totals, accumulating from first deposit date.

**Columns Involved**: `ACC_Revenue_*`, `ACC_PnL_*`, `ACC_TotalDeposits`, `ACC_CountDeposits`, `ACC_TotalCashouts`, `ACC_TotalCoFee`, `ACC_NetDeposits`, `ACC_WithdrawalToWallet`, `ACC_Transactional_Revenue_Total`

**Rules**:
```
ACC_Revenue_X (today) = Revenue_X (today) + ACC_Revenue_X (yesterday)
ACC_TotalDeposits     = TotalDeposits + ACC_TotalDeposits (yesterday)
ACC_ChurnDays         = IF @date <= FirstNewFundedDate OR IsFunded_New=1 THEN 0
                        ELSE 1 + ACC_ChurnDays (yesterday)
```
Yesterday's row is read from `BI_DB_CID_DailyPanel_FullData WHERE DateID = @EndPreviousDINT`. First-day customers start with the day's values (no prior row → NULL from #History, treated as 0 via ISNULL).

### 2.6 Revenue_Total vs Transactional_Revenue_Total

**What**: Two revenue aggregate columns with different scope.

**Columns Involved**: `Revenue_Total`, `Transactional_Revenue_Total`, `Revenue_IslamicFees`, `Revenue_TicketFees`, `Revenue_ConversionFees`, `Revenue_TicketFeeByPercent`

**Rules**:
```
Revenue_Total = Trading commissions (FullCommissions + RollOverFee, all instruments)
              + Revenue_TicketFees (stock ticket fee, flat)
              + Revenue_TicketFeeByPercent components (crypto/stock/FX/copy by %)
              + Revenue_ConversionFees (FX conversion on deposits/cashouts)
              + Revenue_IslamicFees (AdminFee + SpotAdjustFee — swap-free accounts only)

Transactional_Revenue_Total = Revenue_Total MINUS Revenue_IslamicFees
                             (i.e., the pure transaction-driven portion, excludes Islamic swap fees)
```
`Revenue_IslamicFees` = AdminFee + SpotAdjustFee from Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee. Only non-zero for accounts with WeekendFeePrecentage=0 (Islamic/swap-free).

### 2.7 Seniority and Seniority_Seg

**What**: Customer's age as a depositor, measured from first deposit date.

**Columns Involved**: `Seniority`, `Seniority_Seg`

**Rules**:
```
Seniority     = DATEDIFF(MONTH, FTDdate, start-of-month of @date)  [integer months]
Seniority_Seg = '<1month' | '1-2month' | '<2-3month' | ... | '12+month'
```
Segmentation uses day-difference thresholds (30/60/90...360 days), not month subtraction.

### 2.8 IsOTD — One Trade Done

**What**: Flag indicating the customer has made exactly 1 prior deposit (ActionTypeID=7) before today.

**Columns Involved**: `IsOTD`

**Rules**: `COUNT(Fact_CustomerAction WHERE ActionTypeID=7 AND DateID < @endDateINT) = 1`. Used to identify customers in their "first repeat transaction" window.

### 2.9 IsFunded_New

**What**: Flag: customer has equity > 0 AND is at VerificationLevel 3 AND has a first action date before tomorrow.

**Columns Involved**: `IsFunded_New`, `EOD_IsFunded`

**Rules**:
```
EOD_IsFunded = 1 IF EOD_Equity >= 25 (i.e., in #FundedAccounts)
IsFunded_New = 1 IF EOD_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < @nextD
```
`EOD_IsFunded` uses the $25 threshold (original funded definition); `IsFunded_New` uses the stricter definition requiring full KYC (VL3).

### 2.10 CashoutsAdjusted

**What**: Adjusted cashout metric that subtracts cashout-adjustment credits and coin transfers from gross cashouts.

**Columns Involved**: `CashoutsAdjusted`

**Rules**: `SUM(TPCashoutsOldDef - CashoutAdjustment - TransferCoins)` from `BI_DB_V_DDR_Daily_Panel`. Used by DDR/finance reporting to normalise cashout figures.

### 2.11 IsIslamic

**What**: Flag: customer has an Islamic (swap-free) account.

**Columns Involved**: `IsIslamic`

**Rules**: `Dim_Customer.WeekendFeePrecentage = 0 → IsIslamic = 1`. Islamic accounts pay AdminFee and SpotAdjustFee instead of rollover/swap fees.

### 2.12 Copy Trading Columns

**What**: Copy and CopyPortfolio are two distinct copy-trading modes tracked separately.

**Columns Involved**: `IsOpen_Copy`, `Count_Opened_Copy`, `Count_Closed_Copy`, `MoneyIn_Copy`, `MoneyOut_Copy`, `IsOpen_CopyPortfolio`, `Count_Opened_CopyPortfolio`, `Count_Closed_CopyPortfolio`, `MoneyIn_CopyPortfolio`, `MoneyOut_CopyPortfolio`

**Rules**:
- **Copy** (dm.CID IS NULL): ActionTypeID=17 (open), 18 (close), 15 (add), 16 (remove). Standard copy trading where customer copies a trader.
- **CopyPortfolio** (dm.CID IS NOT NULL — ParentCID in social-manager accounts): Managed copy portfolio product. Distinguished by whether the Dim_Mirror's ParentCID is a social-manager account (`AccountTypeID=9`).

---

## 3. Data Elements

> 183 columns. Grouped by functional area. Key columns shown per group; Lev1/LevCFD and FX/Comm/Ind sub-splits follow the same pattern as the representative column in each group.

### 3A. Identity & Date

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `CID` | BIGINT | eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID | T1 | DWH_dbo.Dim_Customer |
| `DateID` | INT | Partition key: date in YYYYMMDD format. One row per CID per day | T2 | SP_CID_DailyPanel_FullData @date param |

### 3B. Activity Period & Acquisition

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `Active_Month` | INT | YYYYMM of this row's date | T2 | SP computed: YEAR*100+MONTH |
| `ActiveDate` | DATE | Calendar date of this row | T2 | SP @date param |
| `Seniority` | INT | Months since customer's first deposit (FTDdate) as of start of the current month | T2 | SP: DATEDIFF(MONTH, FTDdate, start-of-month) |
| `Seniority_Seg` | NVARCHAR | Seniority bucket label: '<1month', '1-2month', '<2-3month', ... '<11-12month', '12+month' | T2 | SP CASE on DATEDIFF(DAY, FTDdate, date) |
| `Reg_Month` | INT | YYYYMM of customer registration | T2 | Dim_Customer.RegisteredReal |
| `RegDate` | DATE | Customer registration date | T2 | Dim_Customer.RegisteredReal |
| `IsReg_ThisD` | INT | 1 if customer registered on this specific date | T2 | SP: RegDate = @date |
| `FTD_Month` | INT | YYYYMM of customer's first-time deposit (FTD) | T2 | Dim_Customer.FirstDepositDate |
| `FTDdate` | DATE | Customer's first-time deposit date | T2 | Dim_Customer.FirstDepositDate |
| `IsFTD_ThisD` | INT | 1 if customer made their first deposit on this specific date | T2 | SP: FTDdate = @date |
| `FTDA` | FLOAT | First-time deposit amount (USD) | T2 | Dim_Customer.FirstDepositAmount |
| `Region` | NVARCHAR | Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe') | T1 | DWH_dbo.Dim_Country.Region via Fact_SnapshotCustomer.CountryID |
| `NewMarketingRegion` | NVARCHAR | Marketing team region classification (e.g., 'Arabic', 'French', 'Norway', 'ROW') | T2 | Dim_Country.MarketingRegionManualName |
| `Country` | NVARCHAR | Customer's country name at snapshot date | T1 | DWH_dbo.Dim_Country.Name via Fact_SnapshotCustomer.CountryID |
| `Channel` | NVARCHAR | Acquisition channel (e.g., 'Direct', 'Affiliate', 'SEM', 'SEO', 'Friend Referral', 'Mobile Acquisition') | T2 | BI_DB_CIDFirstDates.Channel |
| `SubChannel` | NVARCHAR | Acquisition sub-channel detail | T2 | BI_DB_CIDFirstDates.SubChannel |
| `AffiliateID` | INT | Affiliate serial ID for affiliate-acquired customers; NULL for direct/organic | T2 | BI_DB_CIDFirstDates.SerialID |

### 3C. Customer Profile & KYC

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `FirstAction` | NVARCHAR | Deprecated — always NULL. Originally planned first action type | T4 | SP: NULL AS FirstAction |
| `FirstInstrument` | NVARCHAR | Deprecated — always NULL. Originally planned first instrument traded | T4 | SP: NULL AS FirstInstrument |
| `V2_Complete` | INT | 1 if customer has completed verification level 2 as of this date | T2 | Dim_Customer.VerificationLevel2Date <= @date |
| `V3_Complete` | INT | 1 if customer has completed full KYC (verification level 3) as of this date | T2 | Dim_Customer.VerificationLevel3Date <= @date |
| `V3_CompleteDate` | DATE | Date customer completed verification level 3 | T2 | Dim_Customer.VerificationLevel3Date |
| `LastPosOpenDate` | DATE | Most recent date customer opened a position (ActionTypeID IN 1,2), max of today vs. yesterday's carry-forward | T2 | Fact_CustomerAction AT=1,2 ISNULL(today, yesterday) |
| `LastLoggedIn` | DATE | Most recent login date (ActionTypeID=14), max of today vs. yesterday's carry-forward | T2 | Fact_CustomerAction AT=14 ISNULL(today, yesterday) |
| `IsPro` | INT | 1 if customer is classified as professional client (MifidCategorizationID IN 2,3 in Fact_SnapshotCustomer) | T2 | Fact_SnapshotCustomer.MifidCategorizationID |
| `IsOTD` | INT | 1 if customer has made exactly one prior deposit (One Trade Done) | T2 | Fact_CustomerAction AT=7, count before today = 1 |
| `Daily_Classification` | NVARCHAR | Customer segment label (e.g., 'Traders', 'Crypto'). Set by separate SP_CID_DailyPanel_UpdateCluster SP. As of 2026 all rows are empty string — appears non-operational post-Synapse migration | T4 | SP_CID_DailyPanel_UpdateCluster (separate run) |
| `EOD_Club` | NVARCHAR | Loyalty tier at EOD: 'LowBronze', 'HighBronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond' | T2 | Dim_PlayerLevel.Name with LowBronze/HighBronze split at $1K equity |
| `EOD_Regulation` | NVARCHAR | Regulatory jurisdiction name at EOD (e.g., 'CySEC', 'FCA', 'ASIC & GAML', 'FinCEN+FINRA') | T2 | DWH_dbo.Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID |
| `LastApplicationProAccountDate` | DATE | Date of most recent professional account application; '1900-01-01' sentinel if never applied | T2 | External_BI_OUTPUT_Customer_ProfessionalCustomers.ApplicationDate |

### 3D. EOD Financials

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `Equity` | FLOAT | Total EOD equity (USD): NWA (net worth of assets) + Liabilities from DWH_dbo.V_Liabilities. Includes all open positions at market value | T2 | DWH_dbo.V_Liabilities.ActualNWA + Liabilities |
| `RealizedEquity` | FLOAT | Realized equity component (cash + closed positions only), excluding open unrealized positions | T2 | DWH_dbo.V_Liabilities.RealizedEquity |
| `AUM` | FLOAT | Assets Under Management: value of assets the customer holds in copy-trading and portfolio products | T2 | DWH_dbo.V_Liabilities.AUM |
| `Credit` | FLOAT | Credit/margin balance: funds provided as credit (e.g., bonus credits). V_Liabilities.EOD_Balance | T2 | DWH_dbo.V_Liabilities.EOD_Balance |
| `EOD_Equity_Copy` | FLOAT | EOD equity in active copy/mirror positions (Amount + PositionPnL for MirrorID>0) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_Real_Stocks` | FLOAT | EOD equity in settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_CFD_Stocks` | FLOAT | EOD equity in leveraged stock/ETF CFD positions (IsSettled=0, InstrumentTypeID IN 5,6) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_Real_Crypto` | FLOAT | EOD equity in settled cryptocurrency positions (IsSettled=1, InstrumentTypeID=10) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_CFD_Crypto` | FLOAT | EOD equity in leveraged crypto CFD positions (IsSettled=0, InstrumentTypeID=10) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_FX/Comm/Ind` | FLOAT | EOD equity in FX, commodities, and indices positions (InstrumentTypeID IN 1,2,4) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_Real_Crypto_Lev1` | FLOAT | EOD equity in crypto positions where Leverage=1 AND IsBuy=1 (unlevered long) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_Real_Stocks_LevCFD` | FLOAT | EOD equity in stock positions where Leverage>1 OR IsBuy=0 (levered or short) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_CFD_Crypto_Lev1` | FLOAT | EOD equity in CFD-Crypto positions where Leverage=1 AND IsBuy=1 | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_CFD_Stocks_LevCFD` | FLOAT | EOD equity in CFD-Stocks positions where Leverage>1 OR IsBuy=0 | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_IsFunded` | INT | 1 if EOD_Equity >= $25 (original funded customer threshold) | T2 | SP: EOD_Equity >= 25 |
| `IsFunded_New` | INT | 1 if EOD_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < tomorrow (stricter funded definition) | T2 | SP: #NewFundedAcccounts |
| `EOD_LSD` | NVARCHAR | Life Stage Definition segment label at EOD (e.g., lifecycle stage name). Source: BI_DB_CID_LifeStageDefinition | T2 | BI_DB_CID_LifeStageDefinition.LSD |

### 3E. Activity Flags

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `ActiveUser` | INT | 1 if customer logged in (ActionTypeID=14) on this date | T2 | Fact_CustomerAction AT=14 |
| `Active` | INT | 1 if customer had any position open or closed on this date (any instrument, including partial close children excluded) | T2 | Dim_Position OpenDateID<=today AND (CloseDateID=0 OR CloseDateID>=today) |
| `ActiveOpen` | INT | 1 if customer opened a new position today — manual trade OR started/added a mirror (AirDrop excluded). See §2.3 | T2 | SP: ActiveOpen_Manual OR ActiveOpen_NewMirror OR ActiveOpen_AddMirror |
| `Active_Copy` | INT | 1 if customer has an open copy position on this date (MirrorID>0) | T2 | Dim_Position MirrorID>0, in date range |
| `Active_Real_Stocks` | INT | 1 if customer has an open settled stock position (IsSettled=1, InstrumentTypeID IN 5,6, non-AirDrop) | T2 | Dim_Position |
| `Active_CFD_Stocks` | INT | 1 if customer has an open CFD stock position (IsSettled=0, InstrumentTypeID IN 5,6) | T2 | Dim_Position |
| `Active_Real_Crypto` | INT | 1 if customer has an open settled crypto position (IsSettled=1, InstrumentTypeID=10, non-AirDrop) | T2 | Dim_Position |
| `Active_CFD_Crypto` | INT | 1 if customer has an open CFD crypto position (IsSettled=0, InstrumentTypeID=10) | T2 | Dim_Position |
| `Active_FX/Comm/Ind` | INT | 1 if customer has an open FX/commodities/indices position (InstrumentTypeID IN 1,2,4) | T2 | Dim_Position |
| `Active_FX` | INT | 1 if customer has an open FX (Currencies, InstrumentTypeID=1) position | T2 | Dim_Position |
| `Active_Comm` | INT | 1 if customer has an open Commodities (InstrumentTypeID=2) position | T2 | Dim_Position |
| `Active_Ind` | INT | 1 if customer has an open Indices (InstrumentTypeID=4) position | T2 | Dim_Position |
| `Active_Real_Stocks_Lev1` | INT | 1 if customer has an open stock position with Leverage=1 AND IsBuy=1 | T2 | Dim_Position leverage-based split |
| `Active_CFD_Stocks_LevCFD` | INT | 1 if customer has an open stock position with Leverage>1 OR IsBuy=0 | T2 | Dim_Position leverage-based split |
| `Active_Real_Crypto_Lev1` | INT | 1 if customer has an open crypto position with Leverage=1 AND IsBuy=1 | T2 | Dim_Position leverage-based split |
| `Active_CFD_Crypto_LevCFD` | INT | 1 if customer has an open crypto position with Leverage>1 OR IsBuy=0 | T2 | Dim_Position leverage-based split |

### 3F. ActiveOpen by Instrument

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `ActiveOpen_Manual` | INT | 1 if opened a non-AirDrop, non-copy position today (MirrorID=0, IsAirDrop=0) | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Mirror` | INT | 1 if started a new copy relationship OR added mirror allocation today | T2 | Dim_Mirror + Fact_CustomerAction AT=15 |
| `ActiveOpen_AirDrop` | INT | 1 if received an AirDrop position today (IsAirDrop=1) | T2 | Dim_Position OpenDateID=today, IsAirDrop=1 |
| `ActiveOpen_IncludeCopy` | INT | 1 if opened any position today including copy but excluding AirDrop | T2 | Dim_Position |
| `ActiveOpen_Copy` | INT | 1 if opened a copy position today (MirrorID>0, non-portfolio, OpenDateID=today) | T2 | Dim_Position |
| `ActiveOpen_Real_Stocks` | INT | 1 if opened a settled stock position today (non-AirDrop) | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_CFD_Stocks` | INT | 1 if opened a CFD stock position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Real_Crypto` | INT | 1 if opened a settled crypto position today (non-AirDrop) | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_CFD_Crypto` | INT | 1 if opened a CFD crypto position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_FX/Comm/Ind` | INT | 1 if opened a FX/Comm/Ind position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_FX` | INT | 1 if opened a FX position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Comm` | INT | 1 if opened a Commodities position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Ind` | INT | 1 if opened an Indices position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Real_Stocks_Lev1` | INT | 1 if opened a stock position (Leverage=1, IsBuy=1) today | T2 | Dim_Position |
| `ActiveOpen_CFD_Stocks_LevCFD` | INT | 1 if opened a leveraged/short stock position today | T2 | Dim_Position |
| `ActiveOpen_Real_Crypto_Lev1` | INT | 1 if opened a crypto position (Leverage=1, IsBuy=1) today | T2 | Dim_Position |
| `ActiveOpen_CFD_Crypto_LevCFD` | INT | 1 if opened a leveraged/short crypto position today | T2 | Dim_Position |

### 3G. Copy Trading Activity

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `IsOpen_Copy` | INT | 1 if customer opened a new copy relationship (started copying a trader) today | T2 | Fact_CustomerAction AT=17 |
| `Count_Opened_Copy` | INT | Number of distinct copy relationships opened today | T2 | Fact_CustomerAction AT=17 DISTINCT MirrorID |
| `Count_Closed_Copy` | INT | Number of distinct copy relationships closed today | T2 | Fact_CustomerAction AT=18 DISTINCT MirrorID |
| `MoneyIn_Copy` | FLOAT | Total funds allocated into copy positions today (negative Amount from AT=17,15) | T2 | Fact_CustomerAction AT=17,15 |
| `MoneyOut_Copy` | FLOAT | Total funds returned from closed copy positions today (Amount from AT=18,16) | T2 | Fact_CustomerAction AT=18,16 |
| `IsOpen_CopyPortfolio` | INT | 1 if customer opened a CopyPortfolio (managed portfolio product) today | T2 | Fact_CustomerAction AT=17 where ParentCID is social-manager account |
| `Count_Opened_CopyPortfolio` | INT | Number of CopyPortfolio relationships opened today | T2 | Fact_CustomerAction, portfolio mode |
| `Count_Closed_CopyPortfolio` | INT | Number of CopyPortfolio relationships closed today | T2 | Fact_CustomerAction, portfolio mode |
| `MoneyIn_CopyPortfolio` | FLOAT | Total funds into CopyPortfolio positions today | T2 | Fact_CustomerAction, portfolio mode |
| `MoneyOut_CopyPortfolio` | FLOAT | Total funds returned from CopyPortfolio positions today | T2 | Fact_CustomerAction, portfolio mode |

### 3H. New Trades & Amount In

> `NewTrades_*` = count of positions opened today (IsPartialCloseChild=0). `AmountIn_NewTrades_*` = USD invested in those positions. Repeated for Copy, Real_Stocks, CFD_Stocks, Real_Crypto, CFD_Crypto, FX/Comm/Ind, plus Lev1/LevCFD variants and a _Total.

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `NewTrades_Copy` | INT | Count of new copy positions opened today | T2 | Dim_Position OpenDateID=today, MirrorID>0 |
| `NewTrades_Real_Stocks` | INT | Count of new settled stock positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_CFD_Stocks` | INT | Count of new CFD stock positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_Real_Crypto` | INT | Count of new settled crypto positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_CFD_Crypto` | INT | Count of new CFD crypto positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_FX/Comm/Ind` | INT | Count of new FX/Comm/Ind positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_Total` | INT | Total count of all new positions opened today across all instrument types | T2 | SP: SUM of all NewTrades_* |
| `AmountIn_NewTrades_Copy` | FLOAT | Total USD invested in new copy positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_Real_Stocks` | FLOAT | Total USD in new settled stock positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_CFD_Stocks` | FLOAT | Total USD in new CFD stock positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_Real_Crypto` | FLOAT | Total USD in new settled crypto positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_CFD_Crypto` | FLOAT | Total USD in new CFD crypto positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_FX/Comm/Ind` | FLOAT | Total USD in new FX/Comm/Ind positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_Total` | FLOAT | Total USD invested in all new positions today | T2 | SP: SUM of all AmountIn_NewTrades_* |
| `NewTrades_Real_Stocks_Lev1` | INT | Count of new Lev1 stock positions (Leverage=1, IsBuy=1) today | T2 | Dim_Position |
| `NewTrades_CFD_Stocks_LevCFD` | INT | Count of new leveraged/short stock positions today | T2 | Dim_Position |
| `NewTrades_Real_Crypto_Lev1` | INT | Count of new Lev1 crypto positions today | T2 | Dim_Position |
| `NewTrades_CFD_Crypto_LevCFD` | INT | Count of new leveraged/short crypto positions today | T2 | Dim_Position |
| `AmountIn_NewTrades_Real_Stocks_Lev1` | FLOAT | USD in new Lev1 stock positions today | T2 | Dim_Position |
| `AmountIn_NewTrades_CFD_Stocks_LevCFD` | FLOAT | USD in new leveraged/short stock positions today | T2 | Dim_Position |
| `AmountIn_NewTrades_Real_Crypto_Lev1` | FLOAT | USD in new Lev1 crypto positions today | T2 | Dim_Position |
| `AmountIn_NewTrades_CFD_Crypto_LevCFD` | FLOAT | USD in new leveraged/short crypto positions today | T2 | Dim_Position |

### 3I. Daily Revenue

> Revenue = trading commissions (FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport plus ticket fees, conversion fees, Islamic fees from revenue functions.

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `Revenue_Copy` | FLOAT | Daily revenue from copy positions (FullCommissions + RollOverFee) + TicketFeeByPercent_Copy | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Real_Stocks` | FLOAT | Revenue from settled stock positions + flat ticket fees | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFee |
| `Revenue_CFD_Stocks` | FLOAT | Revenue from CFD stock positions + ticket fee by percent (Stocks CFD) | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Real_Crypto` | FLOAT | Revenue from settled crypto positions + ticket fee by percent (Crypto Real) | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_CFD_Crypto` | FLOAT | Revenue from CFD crypto positions + ticket fee by percent (Crypto CFD) | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_FX/Comm/Ind` | FLOAT | Revenue from FX/Commodities/Indices positions + ticket fee by percent | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_FX` | FLOAT | Revenue from FX (Currencies) positions + Currencies CFD ticket fee by percent | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Comm` | FLOAT | Revenue from Commodities positions + Commodities CFD ticket fee by percent | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Ind` | FLOAT | Revenue from Indices positions + Indices CFD ticket fee by percent | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Total` | FLOAT | Total daily revenue across all instruments + all fee types (commissions + rollover + ticket + conversion + Islamic). See §2.6 | T2 | SP: SUM of all revenue components |
| `Revenue_IslamicFees` | FLOAT | Islamic account fees only: AdminFee + SpotAdjustFee (swap-free surcharge). 0 for non-Islamic accounts | T2 | Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee |
| `Revenue_TicketFees` | FLOAT | Flat per-trade ticket fees on stock trades (Function_Revenue_TicketFee) | T2 | Function_Revenue_TicketFee |
| `Revenue_ConversionFees` | FLOAT | Currency conversion fees on deposits/cashouts (Function_Revenue_ConversionFee) | T2 | Function_Revenue_ConversionFee |
| `Reven

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE] @dt [Date] AS
BEGIN


IF OBJECT_ID('[BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE]') IS NOT NULL
	DROP TABLE [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE]

IF OBJECT_ID('[BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH]') IS NOT NULL
	DROP TABLE [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH]

		

DECLARE @sql NVARCHAR(MAX) 
DECLARE @sql2 NVARCHAR(MAX) 
DECLARE @range NVARCHAR(MAX) 
	

SELECT @range =  
CONVERT(VARCHAR(8), DATEADD(dd,-1,@dt) ,112)  +','+ CONVERT(VARCHAR(8), @dt,112) +','+ CONVERT(VARCHAR(8), DATEADD(dd,1,@dt) ,112)
	

	SET @sql = 'CREATE TABLE [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE]
                WITH
	  
			  (  
					
					DISTRIBUTION = HASH ( [CID] ),
					CLUSTERED INDEX 
					(
						[DateID] ASC
					),
					PARTITION (DateID RANGE 
					LEFT FOR VALUES 
					('+@range+')
				)
			) AS SELECT TOP 0 * FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData]'
   EXEC (@sql)


   	SET @sql2 = 'CREATE TABLE [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH]
                WITH
	  
			  (  
					
					DISTRIBUTION = HASH ( [CID] ),
					CLUSTERED INDEX 
					(
						[DateID] ASC
					),
					PARTITION (DateID RANGE 
					LEFT FOR VALUES 
					('+@range+')
				)
			) AS SELECT TOP 0 * FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData]'
   EXEC (@sql2)

end



GO

```

### SP `BI_DB_dbo.SP_BI_DB_CID_DailyPanel_FullData_SWITCH`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_BI_DB_CID_DailyPanel_FullData_SWITCH.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_BI_DB_CID_DailyPanel_FullData_SWITCH] AS
BEGIN


--   set deadlock_priority high
--- we have to have same indexes and constraints as partitioned table
Declare @CurrentDay int
Declare @PartToSwitch int 
Declare @SqlStr varchar(max)
Declare @TS BIT = 1
Declare @MaxValue int
Declare @MinValue int
Declare @LastPar int
Declare @IsRight bit 


Declare @MaxValue_SGL int
Declare @MinValue_SGL int
Declare @LastPar_SGL int
Declare @IsRight_SGL bit 
Declare @PartToSwitch_SGL int 





-----------------------

set  @CurrentDay = (Select top 1  DateID from [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE])

SELECT 
@MaxValue_SGL=max(cast(rng.value as int )),
@MinValue_SGL=min(cast(rng.value as int )),
@IsRight_SGL=max(cast(pf.boundary_value_on_right as int)),
@LastPar_SGL=max(partition_number)
FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.[object_id] = tbl.[object_id]
INNER JOIN  sys.indexes    idx ON  prt.[object_id] = idx.[object_id]               AND                                prt.[index_id]  = idx.[index_id]
INNER JOIN  sys.data_spaces ds ON  idx.[data_space_id] = ds.[data_space_id]
INNER JOIN  sys.partition_schemes    ps  ON  ds.[data_space_id]  = ps.[data_space_id]
INNER JOIN sys.partition_functions   pf  ON  ps.[function_id]    = pf.[function_id]
LEFT JOIN sys.partition_range_values rng ON  pf.[function_id]    = rng.[function_id]
AND  rng.[boundary_id] = prt.[partition_number]
WHERE tbl.object_id =object_id('BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE')



SELECT 
@MaxValue=max(cast(rng.value as int )),
@MinValue=min(cast(rng.value as int )),
@IsRight=max(cast(pf.boundary_value_on_right as int)),
@LastPar=max(partition_number)
FROM        sys.schemas    sch
INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
INNER JOIN  sys.partitions prt ON  prt.[object_id] = tbl.[object_id]
INNER JOIN  sys.indexes    idx ON  prt.[object_id] = idx.[object_id]               AND                                prt.[index_id]  = idx.[index_id]
INNER JOIN  sys.data_spaces ds ON  idx.[data_space_id] = ds.[data_space_id]
INNER JOIN  sys.partition_schemes    ps  ON  ds.[data_space_id]  = ps.[data_space_id]
INNER JOIN sys.partition_functions   pf  ON  ps.[function_id]    = pf.[function_id]
LEFT JOIN sys.partition_range_values rng ON  pf.[function_id]    = rng.[function_id]
AND  rng.[boundary_id] = prt.[partition_number]
WHERE tbl.object_id =object_id('BI_DB_dbo.BI_DB_CID_DailyPanel_FullData')





        IF @CurrentDay <= @MinValue_SGL 
		BEGIN
			SET @PartToSwitch_SGL = 1 
		END 

		IF @CurrentDay > @MaxValue_SGL 
		BEGIN
		     SET @PartToSwitch_SGL=@LastPar_SGL
		END 

		IF @PartToSwitch_SGL IS NULL 
		 BEGIN  
			SELECT TOP 1 @PartToSwitch_SGL = prt.[partition_number]
			FROM        sys.schemas    sch
			INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
			INNER JOIN  sys.partitions prt ON  prt.[object_id] = tbl.[object_id]
			INNER JOIN  sys.indexes    idx ON  prt.[object_id] = idx.[object_id] AND prt.[index_id]  = idx.[index_id]
			INNER JOIN  sys.data_spaces ds ON  idx.[data_space_id] = ds.[data_space_id]
			INNER JOIN  sys.partition_schemes  ps  ON  ds.[data_space_id]  = ps.[data_space_id]
			INNER JOIN  sys.partition_functions pf  ON  ps.[function_id]    = pf.[function_id]
			LEFT  JOIN  sys.partition_range_values rng ON  pf.[function_id]    = rng.[function_id]
			AND  rng.[boundary_id] = prt.[partition_number]
			WHERE tbl.object_id =object_id('BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE')
			AND rng.value  >= @CurrentDay
			ORDER BY CAST(rng.value as int)
		END




       IF @CurrentDay <= @MinValue 
		BEGIN
			SET @PartToSwitch = 1 
		END 

		IF @CurrentDay > @MaxValue 
		BEGIN
		     SET @PartToSwitch=@LastPar
		END 

		IF @PartToSwitch IS NULL 
		 BEGIN  
			SELECT TOP 1 @PartToSwitch = prt.[partition_number]
			FROM        sys.schemas    sch
			INNER JOIN  sys.tables     tbl ON  sch.schema_id   = tbl.schema_id
			INNER JOIN  sys.partitions prt ON  prt.[object_id] = tbl.[object_id]
			INNER JOIN  sys.indexes    idx ON  prt.[object_id] = idx.[object_id] AND prt.[index_id]  = idx.[index_id]
			INNER JOIN  sys.data_spaces ds ON  idx.[data_space_id] = ds.[data_space_id]
			INNER JOIN  sys.partition_schemes  ps  ON  ds.[data_space_id]  = ps.[data_space_id]
			INNER JOIN  sys.partition_functions pf  ON  ps.[function_id]    = pf.[function_id]
			LEFT  JOIN  sys.partition_range_values rng ON  pf.[function_id]    = rng.[function_id]
			AND  rng.[boundary_id] = prt.[partition_number]
			WHERE tbl.object_id =object_id('BI_DB_dbo.BI_DB_CID_DailyPanel_FullData')
			AND rng.value  >= @CurrentDay
			ORDER BY CAST(rng.value as int)
		END 



---------------------------------------------------------------------------
-- build switch statement

--- 1 .switch existing data in partition to shadow table 
Set @SqlStr = 'ALTER TABLE BI_DB_dbo.BI_DB_CID_DailyPanel_FullData SWITCH PARTITION ' + CAST(@PartToSwitch as varchar) +
' TO BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH PARTITION ' + CAST(@PartToSwitch_SGL as varchar) + ';'
--print @SqlStr   
exec (@SqlStr)

--- 2 .switch new data to partitioned table
Set @SqlStr = 'ALTER TABLE BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE SWITCH PARTITION ' + CAST(@PartToSwitch_SGL as varchar) + '  TO BI_DB_dbo.BI_DB_CID_DailyPanel_FullData PARTITION ' + CAST(@PartToSwitch as varchar) +' WITH (TRUNCATE_TARGET = ON);'
--print @SqlStr
exec (@SqlStr)
--- 3. remove check constraint
---Set @SqlStr = 'ALTER TABLE dbo.Fact_CustomerAction_SWITCH_SINGLE DROP CONSTRAINT FCASS_value_for_switch'

-- print @SqlStr
---exec (@SqlStr)

--- 4 . truncate shadow table
TRUNCATE TABLE BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH

END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE` | synapse_sp | BI_DB_dbo | SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE.sql` |
| `BI_DB_dbo.SP_BI_DB_CID_DailyPanel_FullData_SWITCH` | synapse_sp | BI_DB_dbo | SP_BI_DB_CID_DailyPanel_FullData_SWITCH | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_BI_DB_CID_DailyPanel_FullData_SWITCH.sql` |
| `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData` | synapse | BI_DB_dbo | BI_DB_CID_DailyPanel_FullData | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_DailyPanel_FullData.md` |
| `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE` | unresolved | BI_DB_dbo | BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE | `—` |
| `sys.schemas` | unresolved | sys | schemas | `—` |
| `sys.tables` | unresolved | sys | tables | `—` |
| `sys.partitions` | unresolved | sys | partitions | `—` |
| `sys.indexes` | unresolved | sys | indexes | `—` |
| `sys.data_spaces` | unresolved | sys | data_spaces | `—` |
| `sys.partition_schemes` | unresolved | sys | partition_schemes | `—` |
| `sys.partition_functions` | unresolved | sys | partition_functions | `—` |
| `sys.partition_range_values` | unresolved | sys | partition_range_values | `—` |


---

# JUDGE FEEDBACK FROM PREVIOUS ATTEMPT — apply ALL of these

Previous attempt scored **6.5** (FAIL). The adversarial judge required regeneration with the following specific fixes:

> Re-run with: (1) Re-tag ALL 169 columns as (Tier 1 — BI_DB_CID_DailyPanel_FullData). This table performs zero ETL; ALTER TABLE SWITCH is a metadata-only operation. Quote each column description verbatim from BI_DB_CID_DailyPanel_FullData wiki. (2) Rewrite Section 4 Tier Legend: define T1=passthrough from BI_DB_CID_DailyPanel_FullData, T3=no traceable source (unused), T4=deprecated/NULL inherited from parent. Remove T2 entirely. (3) For FirstAction, FirstInstrument, Daily_Classification: keep T1 tier label, note deprecated/NULL status in description body. (4) Fix Synapse Index property to CLUSTERED INDEX (DateID ASC) reflecting runtime SP behavior. (5) Update footer tier breakdown to 169 T1, 0 T2, 0 T3, 0 T4.

Top issues from the judge:
1. [high] `All 169 columns (DateID, Channel, Revenue_Total, EOD_Equity_Copy, and 160 others)` — All 169 columns are passhthroughs from BI_DB_CID_DailyPanel_FullData via ALTER TABLE ... SWITCH PARTITION — a metadata-only operation with zero ETL. With the parent wiki present in the bundle, the rubric requires every column to be Tier 1 from BI_DB_CID_DailyPanel_FullData. Writer labeled 164 as T2 (relaying the parent's SP lineage) and 2 as T4. Only CID, Region, Country are correctly T1.
2. [high] `Section 4 — Tier Legend` — Tier Legend defines T2 as 'ETL-computed in the parent table's writer SP (SP_CID_DailyPanel_FullData)'. This SWITCH table performs zero ETL — no column is ETL-computed in this table. T2 should not appear in the legend. The correct legend for this object is T1 (passthrough from parent) and T4 (deprecated).
3. [medium] `FirstAction, FirstInstrument, Daily_Classification` — Tagged T4 in the wiki. These are deprecated/NULL columns that are passhthroughs of T4 columns in the parent table. For the SWITCH table they should still be labeled Tier 1 from BI_DB_CID_DailyPanel_FullData with the deprecated note in the description body, not a different tier label.
4. [low] `Property table — Synapse Index` — Property table shows 'CLUSTERED COLUMNSTORE INDEX' (SSDT DDL value). Section 3.1 correctly notes SP_CREATE_SWITCH_SINGLE creates 'CLUSTERED INDEX (DateID ASC)' at runtime. Property table should reflect runtime state or note the discrepancy.
5. [low] `Section 4 — Tier Legend` — Tier 3 is absent from the tier legend. While no T3 columns exist, the standard legend template requires T3 to be defined so analysts know it was considered and found inapplicable.

Address every issue above. Do NOT regenerate the whole wiki from scratch — keep what was correct, only fix what the judge flagged.
