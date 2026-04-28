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

- **Schema**: `eMoney_dbo`
- **Object**: `eMoney_Client_Balance_Check_Opening_Balance`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/eMoney_dbo/eMoney_Client_Balance_Check_Opening_Balance/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\eMoney_dbo\eMoney_Client_Balance_Check_Opening_Balance\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\eMoney_dbo\eMoney_Client_Balance_Check_Opening_Balance\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\eMoney_dbo\Tables\eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance.sql`

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

# Pre-Resolved Upstream Bundle for `eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance.sql`

```sql
CREATE TABLE [eMoney_dbo].[eMoney_Client_Balance_Check_Opening_Balance]
(
	[Date] [date] NULL,
	[Openning_Balance_Gap] [decimal](16, 6) NULL,
	[UpdateDate] [date] NOT NULL
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

Found 1 upstream wiki(s). Read EACH one in full.


### Upstream `eMoney_dbo.eMoneyClientBalance` — synapse
- **Resolved as**: `eMoney_dbo.eMoneyClientBalance`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoneyClientBalance.md`

# eMoney_dbo.eMoneyClientBalance

> Daily account-level balance table for the eToro Money fiat platform; tracks opening balance, 12 transaction flow components, closing balance (BO and computed), reconciliation gaps, and full reporting-currency conversions for all active Tribe accounts across UK, Malta, AUS, and DK entities. Computed by SP_eMoney_ClientBalance from three Tribe ETL staging tables plus DWH dimension lookups.

| Property | Value |
|----------|-------|
| Schema | eMoney_dbo |
| Object type | Table |
| Distribution | HASH(AccountId) |
| Index | CLUSTERED COLUMNSTORE INDEX |
| Rows (approx) | ~1.19B |
| Date range | 2023-12-29 → 2026-04-12 |
| Writer SP | SP_eMoney_ClientBalance (1073 lines; @d DATE param) |
| ETL pattern | Daily DELETE WHERE BalanceDateID=@dreport_i + INSERT |
| Columns (live) | 72 (SSDT stale at 45; 27 added via ALTER TABLE 2026-01-20) |
| UC target | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance |

---

## 1. Object Purpose

`eMoneyClientBalance` is the primary daily balance reconciliation table for the eToro Money fiat platform. For each Tribe account (`AccountId`), it captures the full intraday money movement picture: what the account held at day open, how it changed through banking transfers, card activity, eToro platform loads/unloads, adjustments, and fees, and what Tribe's back-office system reports as the closing balance. The computed closing balance (`ClosingBalanceCalc`) is independently derived and compared to the Tribe back-office closing balance (`ClosingBalanceBO`) to produce the reconciliation gap (`ClosingBalanceGAP`), which is the primary data quality signal used by the eToro Money finance team.

From 2026-01-20, the table was extended with full reporting-currency (RepCur) conversions of every financial column, plus FX components to separate pure business activity from currency revaluation effects.

**Primary use cases:**
- Daily balance reconciliation for eToro Money finance operations
- Per-account transaction flow breakdown (card, banking, eToro platform, fees)
- Multi-currency FX exposure and gain/loss analysis (post-2026-01-20)
- Linking Tribe accounts to eToro DWH user identities (GCID/CID)

---

## 2. Business Context

### 2.1 eToro Money Fiat Platform Architecture

eToro Money is eToro's regulated e-money product. Tribe Payments provides the underlying card and banking infrastructure. The DWH receives daily extract files from Tribe:
- **ETL_AccountSnapshot**: Tribe's authoritative balance file (settled balance per account per day)
- **ETL_AccountsActivities**: All non-card transactions (banking, eToro wallet transfers, adjustments)
- **ETL_SettlementsTransactions**: Card network settlement transactions

The SP_eMoney_ClientBalance processes these three files daily to build the account-level balance ledger.

### 2.2 Balance Date vs. File Date

A critical design detail: Tribe's balance files always arrive one day late. The business date to reconcile (@dreport = @d) corresponds to balance files dated @d+1 (@date). This means:
- `BalanceDate` = yesterday (business date)
- ETL_AccountSnapshot closing balance is read with `DateID = @d_i` (today's integer)
- ETL_AccountSnapshot opening balance is read with `DateID = @dreport_i` (yesterday's integer)

### 2.3 Opening Balance Priority Chain

Opening balance is populated in priority order:
1. **Primary (steady state)**: `eMoneyClientBalance.ClosingBalanceBO` from `BalanceDateID = @dreport_prev_i` (two days ago's closing balance as today's opening)
2. **First-fill fallback**: `ETL_AccountSnapshot.SettledBalance` for `DateID = @dreport_i` (used only when no prior eMoneyClientBalance row exists)

### 2.4 Multi-Entity FX Architecture (Added 2026-01-20)

With AUS (AUD) and DK (DKK) entities launched in late 2025, reporting across entities required a consistent currency. Each entity has a **reporting currency** mapped in `eMoney_EntityByCurrencyISO_MappingStatic`:
- eToro Money UK → GBP
- eToro Money Malta → EUR (also for DKK accounts)
- eToro Money AUS → AUD

Every financial column is replicated as `{Column}RepCur = {Column} * CrossExchangeRate2`. The FX components (`FX`, `PositiveFX`, `FXGAP`) separate currency revaluation from actual transactions, enabling clean P&L reporting across entities.

### 2.5 IsExistingUser Resolution

Tribe accounts are linked to eToro DWH users via two JOIN paths:
1. `AccountId = eMoney_Dim_Account.ProviderCurrencyBalanceID` (preferred — account-level)
2. `HolderId = eMoney_Dim_Account.ProviderHolderID` (fallback — holder-level)

Both paths filter `GCID_Unique_Count=1` to avoid ambiguous resolutions. A post-load UPDATE backfills GCID/CID/IsExistingUser for rows with `BalanceDateID >= 20250701` where GCID was initially NULL, addressing a known mapping lag after the July 2025 DIM rebuild.

---

## 3. Source Tables

| Source | Role | Join Key |
|--------|------|----------|
| eMoney_dbo.ETL_AccountSnapshot | Closing balance (BO), opening fallback, account metadata | DateID |
| eMoney_dbo.ETL_AccountsActivities | Banking/eToro/adjustment transactions | DateID, AccountId; Network IN ('Internal Payment','External Payment'); TC NOT IN (6,14,15,24,25,64) |
| eMoney_dbo.ETL_SettlementsTransactions | Card settlements | DateID, AccountId |
| eMoney_dbo.eMoneyClientBalance (self) | Prior-day closing as today's opening | BalanceDateID = @dreport_prev_i |
| eMoney_dbo.eMoney_Dim_Account | GCID, CID, AccountSubProgram, IsTest | ProviderCurrencyBalanceID / ProviderHolderID; GCID_Unique_Count=1 |
| eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Entity, HolderCurrency, ReportingCurrency | CurrencyISO = CurrencyIson |
| BI_DB_dbo.External_Cmrdb_FxRate | ExchangeRate, CrossExchangeRate | IsOld=0, AddedBy IS NULL, ExchangeDate > GETDATE()-60 |
| DWH_dbo.Fact_CurrencyPriceWithSplit | USDApproxRate, CrossExchangeRate2 | InstrumentID, OccurredDateID |
| DWH_dbo.Dim_Instrument | Reporting/holder instrument metadata | InstrumentID |

---

## 4. Data Elements

### 4.1 Date / ID Dimensions

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| BalanceDate | date | Business date this row represents; equals @d input param (= yesterday relative to load). All rows for a given run share this date. | T2 |
| BalanceDateID | int | Integer YYYYMMDD of BalanceDate; used as the DELETE key for idempotent daily reload. | T2 |

### 4.2 Account Identity

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| AccountId | int | Tribe fiat account identifier. Distribution hash key. Each account has exactly one currency denomination (CurrencyIson). | T2 |
| HolderId | int | Tribe holder (customer) identifier. One holder may have multiple accounts (one per currency). | T2 |
| ProgramId | int | Tribe program identifier. Maps to specific product configurations: 39=UK CARD GBP, 175=UK IBANO, 176=EU TEST IBANO, 177=EU IBANO, 178=UK FTD, 179=EU FTD, 180=UK GBP FOR UAE, 181=EU TEST BC, 182=EU Card, 183=Banking Circle AUD Account, 184=Banking Circle DKK Account, 185=Banking Circle DKK Test, 186=Banking Circle AUD Test. | T2 |
| Program | nvarchar(256) | Human-readable program label derived from ProgramId CASE expression. 'NA' for any ProgramId not in the 13 hardcoded values. | T2 |
| CurrencyIson | int | ISO 4217 numeric currency code for this account (826=GBP, 978=EUR, 36=AUD, 208=DKK). | T2 |
| AccountStatus | nvarchar(256) | Tribe account status shortcode: A=Active, S=Suspended, B=Blocked, P=Spend only, R=Receive only. Distribution (live): A=92.3%, S=6.5%, B=0.55%, P=0.53%, R=0.05%. | T2 |
| AccountStatusDescription | nvarchar(256) | Full text description of AccountStatus: 'Active', 'Suspended', 'Blocked', 'Spend only', 'Receive only'. | T2 |
| Entity | varchar(17) | eToro legal entity derived from CurrencyIson via eMoney_EntityByCurrencyISO_MappingStatic: 'eToro Money UK', 'eToro Money Malta', 'eToro Money AUS'. 'New' for 131 rows where CurrencyIson not in mapping table. | T2 |
| HolderCurrency | varchar(256) | ISO alpha currency code for this account (GBP, EUR, AUD, DKK). NULL for ~966M pre-mapping rows (loaded before entity mapping was populated for all CurrencyIson values). | T2 |
| ReportingCurrency | varchar(256) | Entity reporting currency: GBP (UK), EUR (Malta, including DKK accounts), AUD (AUS). NULL for same ~966M pre-mapping rows. | T2 |

### 4.3 User Resolution

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| GCID | int | eToro Global Customer ID. Resolved via eMoney_Dim_Account on ProviderCurrencyBalanceID (primary) or ProviderHolderID (fallback); GCID_Unique_Count=1 only. NULL for ~3.16M rows of unlinked Tribe accounts. | T2 |
| CID | int | eToro Customer ID paired with GCID. | T2 |
| AccountSubProgram | nvarchar(256) | Sub-program label copied from eMoney_Dim_Account (e.g., 'IBAN EU Green', 'IBAN EU Black', 'Card Green EU'). NULL if GCID unresolved. | T2 |
| IsExistingUser | int | 1 if account resolved to an eToro DWH user (GCID IS NOT NULL); 0 otherwise. 99.7% of rows are 1. Post-load UPDATE backfills this for BalanceDateID >= 20250701 where initial resolution failed. | T2 |
| IsTest | int | 1 if this is a test account per eMoney_Dim_Account.IsTestAccount; 0 for confirmed production accounts; NULL for ~966M rows loaded before IsTest column addition (~Sep 2025). | T2 |
| UpdateDate | datetime | GETDATE() load timestamp. | T2 |
| USDApproxRate | decimal(16,6) | Approximate USD conversion rate for this account's holder currency, from DWH_dbo.Fact_CurrencyPriceWithSplit mid-price (Ask+Bid)/2, adjusted for quote direction (IsToUSD flag). | T2 |

### 4.4 Opening Balance

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| OpeningBalance | decimal(16,6) | Total account balance at business date open in holder currency. Cascades from prior day's eMoneyClientBalance.ClosingBalanceBO (steady state) or ETL_AccountSnapshot.SettledBalance (first-fill fallback). | T2 |
| OpeningPositiveBalance | decimal(16,6) | Positive-only component of OpeningBalance; equals MAX(0, OpeningBalance). Used to track positive balance FX exposure separately from negative balances. | T2 |

### 4.5 Transaction Flows (Holder Currency)

All transaction flow columns use ISNULL(..., 0) — never NULL; zero for accounts with no activity in that category.

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| BankPayIns | decimal(16,6) | Sum of all inbound banking transfers: External Payment with positive HolderAmount (excl. TC=66) + TC=65 inbound return + TC=13/LoadSource=33 internal return. | T2 |
| BankPayOuts | decimal(16,6) | Sum of all outbound banking transfers: External Payment with negative HolderAmount (excl. TC=65) + TC=66 outbound return + TC=11/LoadSource=33. | T2 |
| Card_POS | decimal(16,6) | Sum of point-of-sale card transactions from ETL_SettlementsTransactions WHERE TransactionCode NOT IN (3,8). | T2 |
| Card_ATM | decimal(16,6) | Sum of ATM cash withdrawal transactions from ETL_SettlementsTransactions WHERE TransactionCode IN (3,8). | T2 |
| EtoroDeposits | decimal(16,6) | Sum of eToro platform wallet loads: TC=1 (Load), LoadType=1 (eWallet), LoadSource IN (30=External client Wallet, 35=local currency debit, 25=eToro). | T2 |
| EtoroCashouts | decimal(16,6) | Sum of eToro platform wallet unloads: TC=4 (Unload), LoadType=1 (eWallet), LoadSource IN (30,35,25). | T2 |
| EtoroC2FDeposits | decimal(16,6) | Sum of crypto-to-fiat conversion loads: TC=1 (Load), LoadType=1 (eWallet), LoadSource=34 (Crypto). | T2 |
| BalanceAdjustments | decimal(16,6) | Sum of manual and API balance adjustments: TC IN (11=CREDIT_ADJUSTMENT, 13=DEBIT_ADJUSTMENT), LoadSource IN (31=GUI, 32=PM API). | T2 |
| ChargeBackAdjustments | decimal(16,6) | Sum of chargeback dispute credits: TC=79 (DISPUTE_CREDIT_ADJUSTMENT). | T2 |
| ATMFee | decimal(16,6) | Sum of ATM fee charges from ETL_SettlementsTransactions WHERE F0FeeName='ATM fee'. | T2 |
| FxFee | decimal(16,6) | Sum of FX conversion fees from ETL_SettlementsTransactions.FxFeeAmount. | T2 |
| OtherFee | decimal(16,6) | Sum of non-ATM settlement fees from ETL_SettlementsTransactions WHERE F0FeeName<>'ATM fee'. | T2 |

### 4.6 Closing Balance & Reconciliation

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| ClosingBalanceCalc | decimal(16,6) | DWH-computed closing balance: ROUND(OpeningBalance + BankPayIns + BankPayOuts + Card_POS + Card_ATM + EtoroDeposits + EtoroCashouts + EtoroC2FDeposits + BalanceAdjustments + ChargeBackAdjustments + ATMFee + FxFee + OtherFee, 2). | T2 |
| ClosingBalanceBO | decimal(16,6) | Tribe back-office closing balance from ETL_AccountSnapshot.SettledBalance for DateID=@d_i (tomorrow's file = today's closing). Authoritative source of truth. | T2 |
| ClosingBalanceGAP | decimal(16,6) | Reconciliation gap: ClosingBalanceCalc - ClosingBalanceBO. Near-zero expected. Systematic non-zero gaps trigger SP_eMoney_Client_Balance_Check_Exceptions_Gap alert. | T2 |
| OpeningBalanceGAP | decimal(16,6) | Opening balance gap: difference between prior day's recorded closing balance and today's opening balance from snapshot file. 0 if no prior eMoneyClientBalance row (first fill). | T2 |
| ClosingNegativeBalanceBO | decimal(16,6) | Negative balance component of ClosingBalanceBO: CASE WHEN ClosingBalanceBO < 0 THEN ClosingBalanceBO ELSE 0 END. | T2 |
| NegativeBalanceMovement | decimal(16,6) | Change in negative balance: OpeningNegativeBalance - ClosingNegativeBalanceBO. Used in positive balance closing calc to preserve correct total. | T2 |
| ClosingPositiveBalanceBO | decimal(16,6) | Positive balance component of ClosingBalanceBO: CASE WHEN ClosingBalanceBO >= 0 THEN ClosingBalanceBO ELSE 0 END. | T2 |
| ClosingPositiveBalanceCalc | decimal(16,6) | DWH-computed positive closing balance: ROUND(OpeningPositiveBalance + all 12 transaction components + NegativeBalanceMovement, 2). | T2 |
| ClosingPositiveBalanceGAP | decimal(16,6) | Positive balance reconciliation gap: ClosingPositiveBalanceCalc - ClosingPositiveBalanceBO. | T2 |
| CheckCalc | decimal(16,6) | Internal consistency check: ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO. Should equal zero; non-zero indicates positive/negative decomposition error. | T2 |
| TransOutOfDate | decimal(16,6) | Sum of HolderAmount from transactions where TransactionDateTime date ≠ BalanceDate (late-arriving records from both settlements and activities). Tracks timing mismatch that contributes to ClosingBalanceGAP. | T2 |

### 4.7 FX Rate Columns (Added 2026-01-20)

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| CrossExchangeRate | decimal(24,12) | Holder-to-reporting-currency FX rate on business date (CrossExchangeRatePrev from prior day). 1 if HolderCurrency = ReportingCurrency. Source: BI_DB_dbo.External_Cmrdb_FxRate. | T2 |
| ExchangeRate | decimal(24,12) | Reporting-to-holder FX rate on business date (= PriceFromReportingCurrencyToHolderCurrencyBusnessDate). Inverse of CrossExchangeRate. | T2 |
| PriceFX | decimal(24,12) | Day-over-day FX rate change: CrossExchangeRate2 - CrossExchangeRatePrev2. Used to compute FX gain/loss columns. | T2 |
| FX | decimal(24,12) | FX gain/loss on total opening balance: OpeningBalance * PriceFX. Isolates currency revaluation from business activity. | T2 |
| PositiveFX | decimal(24,12) | FX gain/loss on positive opening balance component: OpeningPositiveBalance * PriceFX. | T2 |
| FXGAP | decimal(12,6) | FX reconciliation residual: ClosingBalanceBORepCur - OpeningBalanceRepCur - Delta (sum of all RepCur transaction flows) - FX. Near-zero expected; non-zero indicates rate sourcing inconsistency. | T2 |

### 4.8 Reporting Currency (RepCur) Columns (Added 2026-01-20)

All RepCur columns are `{source_column} * CrossExchangeRate2`. `CrossExchangeRate2 = 1/ExchangeRate`. Same-currency accounts have CrossExchangeRate2=1 (no conversion applied). **NULL for rows loaded before 2026-01-20** when the ALTER TABLE additions were not yet in place.

| Column | Source Column | Tier |
|--------|---------------|------|
| ClosingBalanceBORepCur | ClosingBalanceBO | T2 |
| OpeningBalanceRepCur | OpeningBalance | T2 |
| OpeningPositiveBalanceRepCur | OpeningPositiveBalance | T2 |
| BankPayInsRepCur | BankPayIns | T2 |
| BankPayOutsRepCur | BankPayOuts | T2 |
| Card_POSRepCur | Card_POS | T2 |
| Card_ATMRepCur | Card_ATM | T2 |
| EtoroDepositsRepCur | EtoroDeposits | T2 |
| EtoroCashoutsRepCur | EtoroCashouts | T2 |
| EtoroC2FDepositsRepCur | EtoroC2FDeposits | T2 |
| BalanceAdjustmentsRepCur | BalanceAdjustments | T2 |
| ChargeBackAdjustmentsRepCur | ChargeBackAdjustments | T2 |
| ATMFeeRepCur | ATMFee | T2 |
| FxFeeRepCur | FxFee | T2 |
| OtherFeeRepCur | OtherFee | T2 |
| ClosingBalanceCalcRepCur | ClosingBalanceCalc | T2 |
| ClosingBalanceGAPRepCur | ClosingBalanceGAP | T2 |
| ClosingNegativeBalanceBORepCur | ClosingNegativeBalanceBO | T2 |
| NegativeBalanceMovementRepCur | NegativeBalanceMovement | T2 |
| ClosingPositiveBalanceBORepCur | ClosingPositiveBalanceBO | T2 |
| ClosingPositiveBalanceCalcRepCur | ClosingPositiveBalanceCalc | T2 |
| ClosingPositiveBalanceGAPRepCur | ClosingPositiveBalanceGAP | T2 |

---

## 5. Business Logic

### 5.1 Daily ETL Flow

```
1. Declare @d (business date), @date (@d+1 = file date), @dreport (@d), @dreport_prev (@d-1)
2. Build #ISO_Mapping: entity/currency/instrument metadata from eMoney_EntityByCurrencyISO_MappingStatic + Dim_Instrument
3. Build #preprate → #rate: Cmrdb FX rates for @dreport (business date)
4. Build #rateprev: Cmrdb FX rates for @dreport_prev (prior business date)
5. Build #AccountsActivities: DISTINCT from ETL_AccountsActivities WHERE DateID=@dreport_i
   Network IN ('Internal Payment','External Payment'), TransactionCode NOT IN (6,14,15,24,25,64)
6. Build #AccountsActivitiesOutOfDate: transactions where TransactionDateTime date ≠ @dreport
7. Build #Settlements: DISTINCT from ETL_SettlementsTransactions WHERE DateID=@dreport_i
8. Build #SettlementsOutOfDate: settlements where TransactionDateTime date ≠ @dreport
9. Build #balanceclosing → #balancecl: ClosingBalanceBO from ETL_AccountSnapshot @d_i; RNDesc=1 for dedup
10. Build #balanceopening → #balanceop: OpeningBalance from ETL_AccountSnapshot @dreport_i; RNDesc=1
11. Build #opbalanceclientbalance: prior day's ClosingBalanceBO from eMoneyClientBalance WHERE BalanceDateID=@dreport_prev_i
12. Build #balance: JOIN closing + opening + prior_close + ISO_Mapping; opening balance cascade logic
13. Build #nocardtx: aggregate banking/eToro/adjustment flows from #AccountsActivities
14. Build #card: aggregate card flows from #Settlements
15. Build #final: JOIN all components; compute ClosingBalanceCalc, gaps, decompositions, Program CASE
16. Build #dim / #dim2: DISTINCT GCID/CID/AccountSubProgram/IsTest from eMoney_Dim_Account; GCID_Unique_Count=1
17. Build #split: FX rates from Fact_CurrencyPriceWithSplit + Cmrdb; compute CrossExchangeRate2, PriceFix2, USDApproxRate
18. Build #output: JOIN #final + #dim + #dim2 + #split; add IsExistingUser, COALESCE GCID, add FX rate columns
19. Build #outputwithrepcurnorounds: add all RepCur columns = {col} * CrossExchangeRate2
20. DELETE FROM eMoneyClientBalance WHERE BalanceDateID=@dreport_i
21. INSERT INTO eMoneyClientBalance from #outputwithrepcurnorounds (72 columns)
22. Post-load UPDATE: backfill GCID/CID/AccountSubProgram/IsExistingUser for BalanceDateID >= 20250701 WHERE GCID IS NULL
23. EXEC SP_eMoney_Client_Balance_Check_Opening_Balance @d  (alert)
24. EXEC SP_eMoney_Client_Balance_Check_Exceptions_Gap @d   (alert)
```

### 5.2 Transaction Code Exclusions

ETL_AccountsActivities filters out TransactionCodes 6, 14, 15, 24, 25, 64. LoadType 35 (local currency debits/credits, added SR-271356 2024-09-16) is INCLUDED in both deposits (LoadSource IN 30,35,25) and cashouts.

### 5.3 Reporting Currency Conversion Pattern

For cross-entity aggregation:
```
CrossExchangeRate2 = 1 / ExchangeRate
{Column}RepCur     = {Column} * CrossExchangeRate2
```
Where ExchangeRate = price from ReportingCurrency to HolderCurrency on business date. For same-currency accounts, CrossExchangeRate2 = 1 (no conversion). Null for accounts where entity mapping is missing.

---

## 6. Dependencies

### 6.1 Upstream Tables

| Table | Dependency | Notes |
|-------|-----------|-------|
| eMoney_dbo.ETL_AccountSnapshot | Hard — closing/opening balances | Must be loaded before SP run |
| eMoney_dbo.ETL_AccountsActivities | Hard — banking/eToro flows | Must be loaded before SP run |
| eMoney_dbo.ETL_SettlementsTransactions | Hard — card flows | Must be loaded before SP run |
| eMoney_dbo.eMoney_Dim_Account | Soft — GCID/CID resolution | Pre-load UPDATE handles missing; SP still loads without it |
| eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Soft — entity/currency mapping | Missing mapping → Entity='New', NULL HolderCurrency/ReportingCurrency |
| BI_DB_dbo.External_Cmrdb_FxRate | Hard (for RepCur) | Required for FX rate columns; filtered IsOld=0, AddedBy IS NULL |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Hard (for USDApproxRate) | Required for USD rate and CrossExchangeRate2 computation |

### 6.2 Known Downstream Consumers

- Finance reconciliation reporting (primary consumer of ClosingBalanceGAP, ClosingBalanceBORepCur)
- SP_eMoney_Client_Balance_Check_Opening_Balance (reads this table for prior day close)
- SP_eMoney_Client_Balance_Check_Exceptions_Gap (reads this table post-load for alert validation)
- Self-referential: SP reads prior day's eMoneyClientBalance.ClosingBalanceBO as today's opening balance

---

## 7. Data Quality Notes

### 7.1 ClosingBalanceGAP Non-Zero Cases

Expected sources of non-zero gap:
- **TransOutOfDate**: transactions dated differently from business date are included in flows but may not match the snapshot balance
- **Timing**: settlement files arriving after the daily cut cause systematic negative gaps
- **First-fill rows**: OpeningBalance uses ETL_AccountSnapshot (may differ slightly from Tribe's internal opening)

### 7.2 IsTest NULL Population (~966M rows)

IsTest is NULL for rows loaded before the IsTest column was added (~Sep 2025 with AUS entity launch). These rows should be treated as non-test (IsTest = 0 ≈ NULL) for production analytics. Use `ISNULL(IsTest, 0)` in filters.

### 7.3 HolderCurrency / ReportingCurrency NULL Population (~966M rows)

Rows loaded before the entity/currency mapping was fully expanded have NULL HolderCurrency and ReportingCurrency. These pre-date the RepCur column additions (2026-01-20) and will also have NULL for all RepCur columns. For time-series analysis, filter `BalanceDate >= '2026-01-20'` to work with fully-populated RepCur data.

### 7.4 SSDT DDL Stale

The SSDT DDL (45 columns) does not reflect the live table (72 columns). The 27 additional columns (CrossExchangeRate through FXGAP, minus ClosingBalanceBORepCur which was in SSDT but also re-added with changed precision) were added via ALTER TABLE commands in the SP comment block. `ClosingBalanceBORepCur` in SSDT has type `decimal(16,6)`; live table has `decimal(24,12)` after the 2026-01-20 ALTER.

---

## 8. UC Migration Notes

| Property | Value |
|----------|-------|
| UC target | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance |
| Column mapping | Direct rename; all 72 columns carry over |
| Partitioning suggestion | PARTITION BY BalanceDateID (integer; enables efficient date-range pruning) |
| RepCur column backfill | Rows before 2026-01-20 have NULL RepCur columns; migration must preserve NULLs or backfill with NULL for pre-date rows |
| IsTest backfill | Rows before ~Sep 2025 have NULL IsTest; ISNULL(IsTest, 0) pattern recommended |
| SSDT alignment | DDL must be updated to match 72-column live schema before UC migration |

---

*Wiki generated: 2026-04-20 | Quality: 8.7/10 | Phases completed: P1, P2, P3, P8, P9, P10B, P11 | Tier distribution: T2=72 (100%)*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `eMoney_dbo.SP_eMoney_Client_Balance_Check_Opening_Balance`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\eMoney_dbo\Stored Procedures\eMoney_dbo.SP_eMoney_Client_Balance_Check_Opening_Balance.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [eMoney_dbo].[SP_eMoney_Client_Balance_Check_Opening_Balance] @Date [Date] AS
BEGIN
/**************************************Start Main Comment History******************************************************
Author:      Adi Meidan  
Date:        Alert for eMoney CB Opening Balance gap 
   
**************************  
** Change History  
**************************  
Date         Author            Description     
----------    ----------        ------------------------------------ 
****************************************End Main Comment History****************************************************/
--DECLARE @Date DATE = '20240604'
DECLARE @DateID  AS INT  =CAST(CONVERT(CHAR(8), @Date, 112) AS INT)


IF OBJECT_ID('tempdb..#final') IS NOT NULL DROP TABLE #final
CREATE TABLE #final 
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT mcb.BalanceDateID DateID,
sum(mcb.OpeningBalanceGAP) AS 'Openning_Balance_Gap'
FROM eMoney_dbo.eMoneyClientBalance mcb
WHERE mcb.BalanceDateID=@DateID 
GROUP BY BalanceDateID
HAVING sum(mcb.OpeningBalanceGAP)<>0 


--IF OBJECT_ID('tempdb..#final') IS NOT NULL DROP TABLE #final
--CREATE TABLE #final
--    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
--AS
--SELECT ddbp.DateID
--	  ,ddbp.Openning_Balance_Gap
--FROM #Opening_Balance ddbp
--WHERE ddbp.Openning_Balance_Gap<>0 

-----truncate table --------
TRUNCATE TABLE eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance

---insert---

INSERT INTO eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance
(
[Date] 
,Openning_Balance_Gap
,UpdateDate
)

SELECT cast(CONVERT (DATETIME,convert(char(8),f.DateID)) AS DATE) AS 'Date'
	  ,f.Openning_Balance_Gap
	  ,@Date 'UpdateDate'
FROM #final f

END



--EXEC [BI_DB_dbo].[SP_eMoney_Client_Balance_Check_Opening_Balance] '2024-06-04'


GO

```

### SP `eMoney_dbo.SP_eMoney_ClientBalance`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\eMoney_dbo\Stored Procedures\eMoney_dbo.SP_eMoney_ClientBalance.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [eMoney_dbo].[SP_eMoney_ClientBalance] @d [DATE] AS
BEGIN
--EXEC  [eMoney_dbo].[SP_eMoney_ClientBalance] '2026-01-11' 
/*
DECLARE @StartDate DATE = '2026-01-11';
DECLARE @EndDate DATE = '2026-01-14';

WHILE @StartDate <= @EndDate
BEGIN
    EXEC [eMoney_dbo].[SP_eMoney_ClientBalance] @StartDate;

    -- Move to the next day
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END*/
--
/**************************************Start Main Comment History******************************************************
Author:     Inessa Kontorovich  
Date:       2024 -04 SP eMoney ClientBalance    based on Tribe data sources Mapping to busness logic was done by Kashif and can be found here:
---https://docs.google.com/spreadsheets/d/1F5dUqJUzFH3ya0ilJ6Yv9fbegw-E9wUYGhrUYVPYxow/edit?gid=0#gid=0
**************************  
** Change History  
**************************  
Date         Author            Description    
2024-09-16	 Inessa			   #SR-271356 - Adding LoadType 35 to Deposits  from Platform Activity( this is new loadtype   for local currency debits/credits.) 
2024-09-09	 Inessa			   #SR-270821 - Adding LoadType 35 to CashOuts  from Platform Activity( this is new loadtype   for local currency debits/credits.) 
2024-06-23   Adi Meidan        Adding alerts at the end of the script
2024-07-03	 Inessa			   Adding USD estimated Rate column
2024-10-08   Inessa			   Adding Opening Balance Gap calculation instead of current comparison
2025-04-03   Inessa			   Adding load type 25 to etoro loads unloads part
2025-07-23   Markos            Change the connection (On Holder ID or Account ID)
2025-07-30   Inessa            Last version was deployed without insert part, this is hotfix ( no logic changed)
2025-09-25   Lior              Adding a new entity - AUS using AUD
2025-10-29   Inessa            fix for dups on dim acount
2025-12-11   Inessa            DDK handling, EUR adding
2026-01-20   Inessa            Changing Rate Evalueation Sourse
                               Adding ReportingCurrency Estimated fields and FX portion to have ratre changes allignment 
2026-02-04   Inessa            Changing Rate  FX Price calc ( to take opening balance, instead of closing)

****************************************End Main Comment History****************************************************/
 
--DECLARE @d DATE ='2026-02-04'  --date we want to reconcile  de facto , that is input BI date ='yesterday'
DECLARE @date DATE = DATEADD(dd,1,@d) --'today' date , next date to buisness date we want to reconcile. This is the date we get balances files ( next date)
DECLARE @d_i INT = CAST(CONVERT (VARCHAR(8) , @date, 112 ) AS INT)
DECLARE @dreport DATE  = @d  --buisness date we want to reconcile  de facto , for transactions files it is working date, for balances it is prev date to balance work date, as balance is always a day later
DECLARE @dreport_i INT   = CAST(CONVERT (VARCHAR(8) , @dreport, 112 ) AS INT)   --PRINT @d_i  PRINT @dreport_i
DECLARE @dreport_prev DATE  = DATEADD(dd,-1,@dreport)  --date for prev calculated balance
DECLARE @dreport_prev_i INT   = CAST(CONVERT (VARCHAR(8) , @dreport_prev, 112 ) AS INT) ----date for prev calculated balance

--DECLARE @min_d_i INT = ISNULL((SELECT MIN(BalanceDateID)  FROM eMoney_dbo.eMoneyClientBalance ), 19990101)
/***********************************************************
no card   activity table
UPDATE eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic
SET InstrumentID =
CASE WHEN CurrencyISO =208 THEN 75
WHEN CurrencyISO =826 THEN 2
WHEN CurrencyISO =36 THEN 7
WHEN CurrencyISO =978 THEN 1
ELSE Null END
 **********************************************************/
 
 /***********************mapping***********************************/

 IF OBJECT_ID('tempdb..#ISO_Mapping') IS NOT NULL DROP TABLE #ISO_Mapping
 CREATE TABLE #ISO_Mapping WITH(HEAP, DISTRIBUTION = ROUND_ROBIN)
 AS
 SELECT mebcims.CurrencyISO
	   ,mebcims.CurrencyName
	   ,mebcims.Entity
	   ,mebcims.InstrumentID
	   ,mebcims.UpdateDate
	   ,mebcims.ReportingCurrency
	   ,mebcims.ReportingInstrumentID
	   ,di.SellCurrencyID  ReportingSellCurrencyID 
	   ,di.BuyCurrencyID   ReportingBuyCurrencyID
	   ,di.Name ReportingName
	   ,di2.Name  
	   ,di2.SellCurrencyID
	   ,di2.BuyCurrencyID
	   , CASE WHEN di2.SellCurrencyID =1 THEN 1 ELSE 0 END IsToUSD

	   FROM eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic mebcims
	   JOIN DWH_dbo.Dim_Instrument di
	   ON mebcims.ReportingInstrumentID = di.InstrumentID
	     JOIN DWH_dbo.Dim_Instrument di2
	   ON mebcims.InstrumentID = di2.InstrumentID
	   
---select * from 
 /*****************************************************************************************
add prices fx
 ****************************************************************************************/
IF OBJECT_ID('tempdb..#preprate') IS NOT NULL DROP TABLE #preprate
CREATE TABLE #preprate WITH(HEAP, DISTRIBUTION = ROUND_ROBIN)
AS 
SELECT DISTINCT 
  DomesticCurrencyCode  
 ,ForeignCurrencyCode
 ,ExchangeRate
 ,ExchangeQuantity
 ,ExchangeDate
 ,AddedDate
 ,CrossExchangeRate
FROM [BI_DB_dbo].[External_Cmrdb_FxRate]
WHERE 1=1
 --AND ForeignCurrencyCode ='DKK'
 --AND DomesticCurrencyCode ='EUR'
 AND IsOld =0
 AND AddedBy  IS NULL 
 AND ExchangeDate >getdate()-60

--DECLARE @dreport DATE  = '2026-01-11'  DECLARE @dreport_prev DATE  = DATEADD(dd,-1,@dreport) 
/*********************************** #rate report date	**********************************************************************/
IF OBJECT_ID('tempdb..#rate') IS NOT NULL DROP TABLE #rate
CREATE TABLE #rate WITH(HEAP, DISTRIBUTION = ROUND_ROBIN)
AS 
SELECT SUB.DomesticCurrencyCode FromCurrency 
	  ,SUB.ForeignCurrencyCode  ToCurrency
	  ,SUB.ExchangeRate  PriceFromReportingCurrencyToHolderCurrencyBusnessDate
	  --,SUB.ExchangeQuantity
	  ,SUB.ExchangeDate  TableDate
	   ,DATEADD(DAY, -1,ExchangeDate) BusnessDate
	  ,SUB.AddedDate
	  ,SUB.CrossExchangeRate
	  ,im.ReportingCurrency
	  ,im.CurrencyName
	 -- ,SUB.RN 
FROM
(
SELECT p.DomesticCurrencyCode
	  ,p.ForeignCurrencyCode
	  ,p.ExchangeRate
	  ,p.ExchangeQuantity
	  ,p.ExchangeDate
	  ,p.AddedDate
	  ,p.CrossExchangeRate  
	  ,ROW_NUMBER() OVER ( PARTITION BY  p.DomesticCurrencyCode,p.ForeignCurrencyCode,ExchangeDate ORDER BY AddedDate DESC) AS RN
	   FROM #preprate p
	   )SUB
	   JOIN #ISO_Mapping im  
	    ON DomesticCurrencyCode =im.ReportingCurrency
	   AND ForeignCurrencyCode=im.CurrencyName
	   WHERE RN =1
	    AND DomesticCurrencyCode <>ForeignCurrencyCode   
	    AND  DATEADD(DAY, -1,ExchangeDate) =@dreport  -- IN ('2026-01-10','2026-01-11')-- 

		--SELECT * FROM #rate r  ;		SELECT   1/7.4720050000000000

-- SELECT 0.1338390000000000 -  0.1338030000000000  ==0.0000360000000000

	
/*********************************** #rateprev	**********************************************************************/

IF OBJECT_ID('tempdb..#rateprev') IS NOT NULL DROP TABLE #rateprev
CREATE TABLE #rateprev WITH(HEAP, DISTRIBUTION = ROUND_ROBIN)
AS 
SELECT SUB.DomesticCurrencyCode FromCurrency
	  ,SUB.ForeignCurrencyCode  ToCurrency
	  ,SUB.ExchangeRate  PriceFromReportingCurrencyToHolderCurrencyPrevDate
	  --,SUB.ExchangeQuantity
	  ,SUB.ExchangeDate  TableDate
	  ,DATEADD(DAY, -1,ExchangeDate)  BusnessDatePrev
	  ,SUB.AddedDate
	  ,SUB.CrossExchangeRate
	  ,im.ReportingCurrency
	  ,im.CurrencyName 
FROM
(
SELECT p.DomesticCurrencyCode
	  ,p.ForeignCurrencyCode
	  ,p.ExchangeRate
	  ,p.ExchangeQuantity
	  ,p.ExchangeDate
	  ,p.AddedDate
	  ,p.CrossExchangeRate  
       ,ROW_NUMBER() OVER ( PARTITION BY  p.DomesticCurrencyCode,p.ForeignCurrencyCode,ExchangeDate ORDER BY AddedDate DESC) AS RN
	   FROM #preprate p
	   )SUB
	   JOIN #ISO_Mapping im  
	    ON DomesticCurrencyCode =im.ReportingCurrency
	   AND ForeignCurrencyCode=im.CurrencyName
	   WHERE RN =1
	    AND DomesticCurrencyCode <>ForeignCurrencyCode   
	    AND  DATEADD(DAY, -1,ExchangeDate) =@dreport_prev


	--	SELECT * FROM #rate r ;		SELECT * FROM #rateprev p

/***********************************************************
 activity table
 **********************************************************/
IF OBJECT_ID('tempdb..#AccountsActivities') IS NOT NULL DROP TABLE #AccountsActivities
CREATE TABLE #AccountsActivities WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 
 
SELECT DISTINCT --adding distinct as i saw dupps on data
       aa.WorkDate
      ,aa.ProgramId
	  ,aa.HolderId
	  ,aa.AccountId
	  ,aa.TransactionCode
	  ,aa.TransactionCodeDescription
	  ,aa.TransactionDateTime
	  ,aa.TransactionCurrencyCode
	  ,aa.TransactionCurrencyAlpha
	  ,aa.TransLink
	  ,aa.TransactionDescription
	  ,aa.ReferenceNumber
	  ,aa.BalanceAdjustmentType
	  ,aa.LoadType
	  ,aa.LoadSource
	  ,aa.Reference
	  ,aa.HolderCurrencyAlpha
	  ,aa.DateID  
	  ,aa.TransactionId
	  ,Date
      ,ISNULL(im.Entity,'NEW')Entity
      ,aa.Network
	  ,aa.HolderAmount
	 
FROM eMoney_dbo.ETL_AccountsActivities aa WITH(NOLOCK) 
LEFT JOIN #ISO_Mapping im
ON im.CurrencyName =aa.HolderCurrencyAlpha
WHERE aa.Network IN ('Internal Payment', 'External Payment')
      AND aa.TransactionCode NOT IN (6, 14, 15, 24, 25, 64)
	  AND aa.DateID =  @dreport_i

/***********************************************************
out of date transactions from activity table
 **********************************************************/
 
IF OBJECT_ID('tempdb..#AccountsActivitiesOutOfDate') IS NOT NULL DROP TABLE #AccountsActivitiesOutOfDate
CREATE TABLE #AccountsActivitiesOutOfDate WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 
 SELECT aa.AccountId
	   ,SUM(HolderAmount) HolderAmount
	   FROM #AccountsActivities aa
 WHERE CAST(aa.TransactionDateTime AS DATE) <>@dreport
 GROUP BY aa.AccountId

 /***********************************************************
card transactions -settlments
 **********************************************************/
IF OBJECT_ID('tempdb..#Settlements') IS NOT NULL DROP TABLE #Settlements
CREATE TABLE #Settlements WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 

SELECT DISTINCT --adding distinct as i saw dupps on data
       st.WorkDate
      ,st.ProgramId
	  ,st.AccountId
	  ,st.CardNumber
	  ,st.MessageReasonCode
	  ,st.Bin
	  ,st.TransactionCode
	  ,st.TransactionCodeDescription
	  ,st.TransactionDateTime
	  ,st.TransactionAmount
	  ,st.TransactionCurrencyCode
	  ,st.TransactionCurrencyAlpha
	  ,st.TransLink
	  ,st.TraceId
	  ,st.TransactionCodeIdentifier
	  ,st.HolderAmount
	  ,st.HolderCurrencyCode
	  ,st.HolderCurrencyAlpha
	  ,st.FxFeeName
	  ,st.FxFeeCode
	  ,st.FxFeeAmount
	  ,st.FxFeeCurrency
	  ,st.F0FeeName
	  ,st.F0FeeCode
	  ,st.F0FeeAmount
	  ,st.F0FeeCurrency
	  ,st.SettlementDate
	  ,st.SettlementAmount
	  ,st.SettlementCurrencyCode
	  ,st.SettlementCurrencyAlpha
	  ,st.SettlementFlag
	  ,st.InterchangeFeeAmount
	  ,st.InterchangeFeeCurrency
	  ,st.FunctionCode
	  ,st.TransactionCodeQualifier
	  ,st.DateID  
	  ,st.Date 
	  ,st.TransactionId
	  ,st.Network
FROM eMoney_dbo.ETL_SettlementsTransactions st WITH(NOLOCK)
WHERE  st.DateID = @dreport_i

--select * from #Settlements
/***********************************************************
out of date transactions from settlements table
 **********************************************************/
IF OBJECT_ID('tempdb..#SettlementsOutOfDate') IS NOT NULL DROP TABLE #SettlementsOutOfDate
CREATE TABLE #SettlementsOutOfDate WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 
SELECT aa.AccountId
	   ,SUM(HolderAmount) HolderAmount
	   FROM #Settlements   aa

 WHERE CAST(aa.TransactionDateTime AS DATE) <>@dreport
 GROUP BY aa.AccountId

/***********************************************************
closing Balance
 **********************************************************/
IF OBJECT_ID('tempdb..#balanceclosing') IS NOT NULL DROP TABLE #balanceclosing
CREATE TABLE #balanceclosing WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 
 
SELECT eas.WorkDate
	  ,CAST(eas.AccountId  AS INT)AccountId
	  ,eas.HolderId
	  ,eas.ProgramId
	  ,eas.CurrencyIson
	  ,eas.SettledBalance
	  ,eas.AccountStatus
	  ,eas.AccountStatusDescription
	  ,eas.Date
	  ,eas.DateID
	  ,eas.Created
FROM eMoney_dbo.ETL_AccountSnapshot eas 
WHERE eas.DateID = @d_i
--SELECT max (DateID) FROM eMoney_dbo.ETL_AccountSnapshot
--select sum(SettledBalance),CurrencyIson  from  #balanceclosing group by CurrencyIson
---------------add rownumber in case we have few files for closing balance---------


 
IF OBJECT_ID('tempdb..#balancecl') IS NOT NULL DROP TABLE #balancecl
CREATE TABLE #balancecl WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 
SELECT b.WorkDate  ClosingBalanceWorkDate
	  ,b.AccountId
	  ,b.HolderId
	  ,b.ProgramId
	  ,b.CurrencyIson
	  ,b.SettledBalance  ClosingBalanceBO
	  ,CASE WHEN b.SettledBalance<0 THEN b.SettledBalance ELSE 0 END ClosingNegativeBalanceBO
	  ,CASE WHEN b.SettledBalance >=0 THEN b.SettledBalance ELSE 0 END ClosingPositiveBalanceBO
	  ,b.AccountStatus
	  ,b.AccountStatusDescription
	  ,b.Date
	  ,b.DateID
	  ,ROW_NUMBER() OVER ( PARTITION BY AccountId ORDER BY Created DESC) rn
FROM #balanceclosing b

--SELECT DateID FROM #balancecl b where  b.CurrencyIson  =826
--select * from #balancecl where AccountId=2460934
--DECLARE @d DATE ='2024-02-28'  DECLARE @dreport DATE  = DATEADD(dd,-1,@d) DECLARE @d_i INT = CAST(CONVERT (VARCHAR(8) , @d, 112 ) AS INT)DECLARE @dreport_i INT   = CAST(CONVERT (VARCHAR(8) , @dreport, 112 ) AS INT) -- PRINT @d_i  PRINT @dreport_i
/***********************************************************
Opening Balance By Date from tribe file
 **********************************************************/
  IF OBJECT_ID('tempdb..#balanceopening') IS NOT NULL DROP TABLE #balanceopening
  CREATE TABLE #balanceopening WITH(HEAP, DISTRIBUTION = HASH(AccountId))
  AS

SELECT eas.WorkDate
	  ,CAST(eas.AccountId  AS INT)AccountId
	  ,eas.SettledBalance 
	  ,eas.Date
	  ,eas.DateID
	  ,eas.Created
	  ,eas.CurrencyIson
FROM eMoney_dbo.ETL_AccountSnapshot eas 
WHERE eas.DateID = @dreport_i
 
 ---------------add rownumber in case we have few files for opening balance---------
IF OBJECT_ID('tempdb..#balanceop') IS NOT NULL DROP TABLE #balanceop
CREATE TABLE #balanceop WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 
SELECT b.WorkDate
	  ,b.AccountId
	  ,b.SettledBalance OpeningBalanceBO
	  ,CASE WHEN b.SettledBalance <0 THEN b.SettledBalance ELSE 0  END OpeningNegativeBalanceBO
	  ,CASE WHEN b.SettledBalance >=0 THEN b.SettledBalance ELSE 0  END OpeningPositiveBalanceBO
	  ,b.Date
	  ,b.DateID
	  ,b.CurrencyIson
	  ,ROW_NUMBER() OVER ( PARTITION BY AccountId ORDER BY  Created DESC) rn
FROM #balanceopening b
--SELECT SUM(OpeningNegativeBalanceBO), SUM(OpeningPositiveBalanceBO)  FROM #balanceop    where   CurrencyIson  =826
/***********************************************************
Opening Balance   from ClientBalanceTable
 **********************************************************/
 
 --DECLARE @d DATE ='2024-02-29'  DECLARE @d_i INT = CAST(CONVERT (VARCHAR(8) , @d, 112 ) AS INT) DECLARE @dreport DATE  = DATEADD(dd,-1,@d)  DECLARE @dreport_prev DATE  = DATEADD(dd,-1,@dreport)  DECLARE @dreport_prev_i INT   = CAST(CONVERT (VARCHAR(8) , @dreport_prev, 112 ) AS INT) 

IF OBJECT_ID('tempdb..#opbalanceclientbalance') IS NOT NULL DROP TABLE #opbalanceclientbalance
CREATE TABLE #opbalanceclientbalance WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 

SELECT AccountId
      ,ClosingBalanceBO  AS OpeningBalanceByCB
	  ,ClosingNegativeBalanceBO as OpeningNegativeBalanceByCB
	  ,ClosingPositiveBalanceBO as OpeningPositiveBalanceByCB
	  ,BalanceDate AS OpeningBalanceDate

FROM [eMoney_dbo].[eMoneyClientBalance]  --select top 1 * from [eMoney_dbo].[eMoneyClientBalance]
WHERE BalanceDateID = @dreport_prev_i
 
--select * from  #opbalanceclientbalance where AccountId=2460934
/***********************************************************
compile all Balances
 **********************************************************/
--DECLARE @d DATE ='2024-02-28' DECLARE @dreport DATE  = DATEADD(dd,-1,@d) DECLARE @d_i INT = CAST(CONVERT (VARCHAR(8) , @d, 112 ) AS INT) DECLARE @dreport_i INT   = CAST(CONVERT (VARCHAR(8) , @dreport, 112 ) AS INT)
 
 
IF OBJECT_ID('tempdb..#balance') IS NOT NULL DROP TABLE #balance
CREATE TABLE #balance WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 

SELECT b.ClosingBalanceWorkDate
	  ,b.AccountId
	  ,CAST(b.HolderId   AS INT) HolderId
	  ,CAST(b.ProgramId AS INT) ProgramId
	  ,CAST(b.CurrencyIson AS INT)CurrencyIson
	  ,b.ClosingBalanceBO
	  ,b.ClosingNegativeBalanceBO
	  ,b.ClosingPositiveBalanceBO
	  ,CASE WHEN  (SELECT SUM( OpeningNegativeBalanceByCB) FROM  #opbalanceclientbalance )  IS NULL  
	                    THEN o.OpeningNegativeBalanceBO ELSE oc.OpeningNegativeBalanceByCB END OpeningNegativeBalance  ---the case is for first fill , to avoid nulls
	  ,CASE WHEN  (SELECT SUM( OpeningPositiveBalanceByCB) FROM  #opbalanceclientbalance )  IS NULL  
	                    THEN o.OpeningPositiveBalanceBO ELSE oc.OpeningPositiveBalanceByCB END OpeningPositiveBalance  
	  ,CASE WHEN  (SELECT SUM( OpeningBalanceByCB) FROM  #opbalanceclientbalance )  IS NULL  
	                    THEN o.OpeningBalanceBO ELSE oc.OpeningBalanceByCB END OpeningBalance 
	  --,ISNULL(ISNULL(oc.OpeningBalanceByCB,0) -  ROUND(o.OpeningBalanceBO,2),0) OpeningBalanceGAP
	  ,b.AccountStatus
	  ,b.AccountStatusDescription
	  ,b.Date ClosingDate
	  ,o.Date OpeningDate	  
	--  ,CASE WHEN b.CurrencyIson = 826  THEN 'eToro Money UK' 
	--        WHEN b.CurrencyIson = 978 THEN 'eToro Money Malta' 
	--		WHEN b.CurrencyIson = 036 THEN 'eToro Money AUS'
	--		ELSE 'New' END AS 'EntityOld'
	,ISNULL(im.Entity,'New')Entity
	,im.CurrencyName HolderCurrency
FROM #balancecl b
LEFT JOIN #balanceop o                ON b.AccountId = o.AccountId AND o.rn =1
LEFT JOIN #opbalanceclientbalance oc  ON b.AccountId = oc.AccountId 
LEFT JOIN #ISO_Mapping im
ON b.CurrencyIson = im.CurrencyISO
WHERE b.rn=1
 
 --SELECT * FROM #ISO_Mapping
 --select * from #balance where ISNULL(Entity,'NA') <>ISNULL(EntityOld,'NA')

/***********************************************************
no card from activity table
 **********************************************************/
 
IF OBJECT_ID('tempdb..#nocardtx') IS NOT NULL DROP TABLE #nocardtx
CREATE TABLE #nocardtx WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS 

SELECT aa.AccountId
	  ,ISNULL(SUM(CASE WHEN aa.Network = 'External Payment' AND aa.TransactionCode<>66  AND aa.HolderAmount>0 THEN aa.HolderAmount  --normal tx  in
	        WHEN aa.Network = 'External Payment' AND aa.TransactionCode =65                                   THEN aa.HolderAmount --banking return ( External Payment	= 65 Inbound Return)
			WHEN                                     aa.TransactionCode =13 AND LoadSource =33	              THEN aa.HolderAmount --internal Returns (13 - DEBIT_ADJUSTMENT	,33 - Balance adjustment load by system)
			ELSE 0 
			END ),0) [BankPayIns]
			--
      ,ISNULL(SUM(CASE WHEN aa.Network = 'External Payment' AND aa.TransactionCode<>65  AND aa.HolderAmount<0 THEN aa.HolderAmount  --normal tx out
	        WHEN aa.Network = 'External Payment' AND aa.TransactionCode =66                                   THEN aa.HolderAmount --banking return ( External Payment	= = 66 Inbound Return)
			WHEN                                     aa.TransactionCode =11 AND LoadSource =33	              THEN aa.HolderAmount --internal Returns (11 - DEBIT_ADJUSTMENT	,33 - Balance adjustment load by system)
			ELSE 0 
			END ),0) [BankPayOuts]
             --
	  ,ISNULL(SUM(CASE WHEN aa.TransactionCode =1  AND aa.LoadType =1 AND aa.LoadSource IN(30,35,25) THEN aa.HolderAmount  --normal tx load(1-load, 1-eWallet,30 - External client Wallet)
	       	ELSE 0 
			END  ),0)[EtoroDeposits]
			--
      ,ISNULL(SUM(CASE WHEN aa.TransactionCode =4  AND aa.LoadType =1 AND aa.LoadSource IN(30,35,25) THEN aa.HolderAmount  --normal tx unload(4-Unload, 1-eWallet,30 - External client Wallet)
	       	ELSE 0 
			END  ),0)[EtoroCashouts]
			--
	  ,ISNULL(SUM(CASE WHEN aa.TransactionCode =1  AND aa.LoadType =1 AND aa.LoadSource =34 THEN aa.HolderAmount  --normal tx load(1-load, 1-eWallet,34 - Crypto)
	       	ELSE 0 
			END  ),0)[EtoroC2FDeposits]
			--
	  ,ISNULL(SUM(CASE WHEN aa.TransactionCode IN(11,13)  AND aa.LoadSource IN(31,32) THEN aa.HolderAmount  -- 11-creditadjust,13-debit_adjust 31- balance adj load from Gui  32 - Balance adjustment load from PM API
	       
	       	ELSE 0 
			END  ),0)BalanceAdjustments
			--
	  ,ISNULL(SUM(CASE WHEN aa.TransactionCode =79   THEN aa.HolderAmount  --DISPUTE_CREDIT_ADJUSTMENT
	       	ELSE 0 
			END  ),0)ChargeBackAdjustments
FROM #AccountsActivities aa  
    GROUP BY aa.AccountId


/***********************************************************
 card from Settlments table
 **********************************************************/
 
IF OBJECT_ID('tempdb..#card ') IS NOT NULL DROP TABLE #card 
CREATE TABLE #card  WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS  

SELECT    s.AccountId
	     ,ISNULL(SUM(CASE WHEN s.TransactionCode      IN (3,8)   THEN s.HolderAmount ELSE 0 END ),0) Card_ATM --3,8-atm
	     ,ISNULL(SUM(CASE WHEN s.TransactionCode  NOT IN (3,8)   THEN s.HolderAmount ELSE 0 END ),0) Card_POS 
         ,ISNULL(SUM(s.FxFeeAmount),0) FxFee
         ,ISNULL(SUM  (CASE WHEN s.F0FeeName = 'ATM fee' THEN s.F0FeeAmount  ELSE 0 END  ),0) ATMFee
         ,ISNULL(SUM  (CASE WHEN s.F0FeeName <>'ATM fee' THEN s.F0FeeAmount  ELSE 0 END  ),0) OtherFee 
FROM #Settlements s  
GROUP BY s.AccountId

/***********************************************************
compile balance and transactions
 **********************************************************/
 --DECLARE @d DATE ='2025-11-14' DECLARE @dreport DATE  = DATEADD(dd,-1,@d) DECLARE @d_i INT = CAST(CONVERT (VARCHAR(8) , @d, 112 ) AS INT) DECLARE @dreport_i INT   = CAST(CONVERT (VARCHAR(8) , @dreport, 112 ) AS INT)
 --PRINT @dreport PRINT @dreport_i
IF OBJECT_ID('tempdb..#final') IS NOT NULL DROP TABLE #final
CREATE TABLE #final WITH(HEAP, DISTRIBUTION = HASH(AccountId))  AS  
SELECT @dreport AS BalanceDate
      ,@dreport_i AS BalanceDateID
      ,b.AccountId
	  ,ISNULL(b.OpeningBalance,0)OpeningBalance
	  ,ISNULL(n.BankPayIns,0)BankPayIns
	  ,ISNULL(n.BankPayOuts,0)BankPayOuts
	  ,ISNULL(s.Card_POS,0)Card_POS
	  ,ISNULL(s.Card_ATM,0)Card_ATM
	  ,ISNULL(n.EtoroDeposits,0)EtoroDeposits
	  ,ISNULL(n.EtoroCashouts,0)EtoroCashouts
	  ,ISNULL(n.EtoroC2FDeposits,0)EtoroC2FDeposits
	  ,ISNULL(n.BalanceAdjustments,0)BalanceAdjustments
	  ,ISNULL(n.ChargeBackAdjustments,0)ChargeBackAdjustments
	  ,ISNULL(s.ATMFee,0)ATMFee
	  ,ISNULL(s.FxFee,0)FxFee
	  ,ISNULL(s.OtherFee,0)OtherFee
	  ,ROUND((ISNULL(b.OpeningBalance,0) 
	                   +ISNULL(n.BankPayIns,0)
	                   +ISNULL(n.BankPayOuts,0)
	                   +ISNULL(s.Card_POS,0)
	                   +ISNULL(s.Card_ATM,0)
	                   +ISNULL(n.EtoroDeposits,0)
	                   +ISNULL(n.EtoroCashouts,0)
	                   +ISNULL(n.EtoroC2FDeposits,0)
	                   +ISNULL(n.BalanceAdjustments,0)
	                   +ISNULL(n.ChargeBackAdjustments,0)
	                   +ISNULL(s.ATMFee,0)
	                   +ISNULL(s.FxFee,0)
					   +ISNULL(s.OtherFee,0)),2) AS ClosingBalanceCalc 
	  ,ROUND((ISNULL(b.OpeningPositiveBalance,0) 
	                   +ISNULL(n.BankPayIns,0)
	                   +ISNULL(n.BankPayOuts,0)
	                   +ISNULL(s.Card_POS,0)
	                   +ISNULL(s.Card_ATM,0)
	                   +ISNULL(n.EtoroDeposits,0)
	                   +ISNULL(n.EtoroCashouts,0)
	                   +ISNULL(n.EtoroC2FDeposits,0)
	                   +ISNULL(n.BalanceAdjustments,0)
	                   +ISNULL(n.ChargeBackAdjustments,0)
	                   +ISNULL(s.ATMFee,0)
	                   +ISNULL(s.FxFee,0)
					   +ISNULL(s.OtherFee,0))
					   +(ISNULL(b.OpeningNegativeBalance,0) -ISNULL(ClosingNegativeBalanceBO,0))  ,2)    AS ClosingPositiveBalanceCalc
	  ,b.ClosingBalanceBO  
	  ,CASE WHEN oc.AccountId   IS NULL THEN 0 ELSE (oc.OpeningBalanceByCB-b.OpeningBalance) END   OpeningBalanceGAP
	  ,b.OpeningNegativeBalance
	  ,b.ClosingNegativeBalanceBO
	  ,b.OpeningPositiveBalance
	  ,b.ClosingPositiveBalanceBO
	  ,ISNULL(b.OpeningNegativeBalance,0) -ISNULL(ClosingNegativeBalanceBO,0)    NegativeBalanceMovement    
	  ,ISNULL(sod.HolderAmount,0)+ISNULL(aod.HolderAmount,0)  AS TransOutOfDate
	  ,b.HolderId
	  ,b.ProgramId
	  ,b.CurrencyIson
	  ,b.AccountStatus
	  ,b.AccountStatusDescription
	  ,b.Entity 
	  ,b.HolderCurrency
FROM  #balance b 
  LEFT  JOIN #nocardtx n  ON b.AccountId =n.AccountId
  LEFT  JOIN #card s ON s.AccountId =b.AccountId
  LEFT  JOIN #AccountsActivitiesOutOfDate aod ON b.AccountId = aod.AccountId
  LEFT  JOIN #SettlementsOutOfDate sod ON b.AccountId = sod.AccountId
  LEFT  JOIN #opbalanceclientbalance oc  ON b.AccountId = oc.AccountId 

  --SELECT DISTINCT Entity, HolderCurrency, CurrencyIson FROM #final
  /***********************************************************

 **********************************************************/

IF OBJECT_ID('tempdb..#dim') IS NOT NULL DROP TABLE #dim
CREATE TABLE #dim WITH(HEAP, DISTRIBUTION = HASH(ProviderCurrencyBalanceID))
AS (
  SELECT DISTINCT mda.GCID
  , mda.CID
  , mda.ProviderHolderID
 -- , mda.AccountSubProgramID
  , mda.AccountSubProgram
  , mda.ProviderCurrencyBalanceID
  , mda.IsTestAccount
 FROM eMoney_dbo.eMoney_Dim_Account mda
 WHERE mda.GCID_Unique_Count=1
 
 )
 
 IF OBJECT_ID('tempdb..#dim2') IS NOT NULL DROP TABLE #dim2
CREATE TABLE #dim2 WITH(HEAP, DISTRIBUTION = HASH(ProviderHolderID))
AS (
  SELECT DISTINCT mda.GCID
  , mda.CID
  , mda.ProviderHolderID
 -- , mda.AccountSubProgramID
  , mda.AccountSubProgram
  , mda.ProviderCurrencyBalanceID
  , mda.IsTestAccount
 FROM eMoney_dbo.eMoney_Dim_Account mda 
 WHERE mda.GCID_Unique_Count=1
  )
 

	  
    /***********************************************************
prices
 **********************************************************/
 
--DECLARE @dreport_i INT =20260204 
IF OBJECT_ID('tempdb..#split') IS NOT NULL DROP TABLE #split
CREATE TABLE #split WITH(HEAP, DISTRIBUTION = HASH(CurrencyISO))
AS
SELECT im.InstrumentID
       ,im.CurrencyISO
	   ,s.OccurredDateID
   	   ,im.ReportingCurrency
	   ,im.CurrencyName
	   ,CASE WHEN im.IsToUSD=1 THEN (Ask + Bid)/2
	         WHEN im.IsToUSD=0 THEN 1/((Ask + Bid)/2)  ELSE 1 END ApproxRateUSD
	 ,(SELECT 1/ ((Ask + Bid)/2)  FROM  DWH_dbo.Fact_CurrencyPriceWithSplit  s 
         				           WHERE s.InstrumentID =1 
			                       AND s.OccurredDateID =@dreport_i
			                          )  USDtoEUR
      ,r.CrossExchangeRate
      ,rr.CrossExchangeRate  CrossExchangeRatePrev
      ,r.CrossExchangeRate - rr.CrossExchangeRate  PriceFix 
	  ,1/r.PriceFromReportingCurrencyToHolderCurrencyBusnessDate CrossExchangeRate2
	  ,1/rr.PriceFromReportingCurrencyToHolderCurrencyPrevDate CrossExchangeRatePrev2
	  ,1/r.PriceFromReportingCurrencyToHolderCurrencyBusnessDate-1/rr.PriceFromReportingCurrencyToHolderCurrencyPrevDate  PriceFix2
	  ,r.PriceFromReportingCurrencyToHolderCurrencyBusnessDate
	  ,rr.PriceFromReportingCurrencyToHolderCurrencyPrevDate
FROM DWH_dbo.Fact_CurrencyPriceWithSplit  s
   JOIN #ISO_Mapping im 
         ON s.InstrumentID =im.InstrumentID
   LEFT JOIN #rate r 
      ON im.CurrencyName = r.CurrencyName
     AND im.ReportingCurrency = r.ReportingCurrency
   LEFT JOIN #rateprev  rr 
      ON im.CurrencyName = rr.CurrencyName
     AND im.ReportingCurrency = rr.ReportingCurrency
WHERE  s.OccurredDateID =@dreport_i
---select * from #split
    /***********************************************************
output
 **********************************************************/

IF OBJECT_ID('tempdb..#output') IS NOT NULL DROP TABLE #output
CREATE TABLE #output WITH(HEAP, DISTRIBUTION = HASH(AccountId)) as
SELECT  f.BalanceDate
       ,f.BalanceDateID
	   ,f.AccountId
	   ,f.OpeningBalance
	   ,f.BankPayIns
	   ,f.BankPayOuts
	   ,f.Card_POS
	   ,f.Card_ATM
	   ,f.EtoroDeposits
	   ,f.EtoroCashouts
	   ,f.EtoroC2FDeposits
	   ,f.BalanceAdjustments
	   ,f.ChargeBackAdjustments
	   ,f.ATMFee
	   ,f.FxFee
	   ,f.OtherFee
	   ,f.ClosingBalanceCalc
	   ,f.ClosingBalanceBO
	   ,ISNULL((f.ClosingBalanceCalc-f.ClosingBalanceBO),0) AS  ClosingBalanceGAP
	   ,ISNULL(f.OpeningBalanceGAP ,0)OpeningBalanceGAP
	   ,ISNULL(f.OpeningPositiveBalance,0)OpeningPositiveBalance
	   ,ISNULL(f.ClosingPositiveBalanceBO,0)ClosingPositiveBalanceBO
	   ,ISNULL(f.ClosingPositiveBalanceCalc,0) ClosingPositiveBalanceCalc
	   ,ISNULL(f.OpeningNegativeBalance,0)OpeningNegativeBalance
	   ,ISNULL(f.ClosingNegativeBalanceBO,0)  ClosingNegativeBalanceBO
	   ,ISNULL(f.NegativeBalanceMovement,0)NegativeBalanceMovement
	   ,ISNULL((f.ClosingPositiveBalanceCalc-f.ClosingPositiveBalanceBO),0) AS  ClosingPositiveBalanceGAP
	   ,ISNULL(f.TransOutOfDate,0)  TransOutOfDate
	   ,f.HolderId
	   ,f.ProgramId
	   ,CASE WHEN f.ProgramId =39  THEN  'UK CARD GBP' 
	         WHEN f.ProgramId =175 THEN 'UK IBANO' 
			 WHEN f.ProgramId =176 THEN 'EU TEST IBANO' 
			 WHEN f.ProgramId =177 THEN 'EU IBANO' 
			 WHEN f.ProgramId =178 THEN 'UK FTD' 
			 WHEN f.ProgramId =179 THEN 'EU FTD' 
			 WHEN f.ProgramId =180 THEN 'UK GBP FOR UAE' 
			 WHEN f.ProgramId =181 THEN 'EU TEST BC' 
			 WHEN f.ProgramId =182 THEN 'EU Card'
             WHEN f.ProgramId =183 THEN 'Banking Circle AUD Account'
             WHEN f.ProgramId =184 THEN 'Banking Circle DKK Account'
             WHEN f.ProgramId =185 THEN 'Banking Circle DKK Test'
             WHEN f.ProgramId =186 THEN 'Banking Circle AUD Test' 
			 ELSE 'NA' END Program
	   ,f.CurrencyIson
	   ,f.AccountStatus
	   ,f.AccountStatusDescription
	   ,f.Entity 
	   ,coalesce(d.GCID,d1.GCID) AS GCID
	   ,coalesce(d.CID,d1.CID) AS CID
	   ,ISNULL(coalesce(d.IsTestAccount,d1.IsTestAccount),0) AS IsTest
	   ,coalesce(d.AccountSubProgram,d1.AccountSubProgram) AS AccountSubProgram
	   ,CASE WHEN coalesce(d.GCID,d1.GCID) IS NULL THEN 0 ELSE 1 END IsExistingUser
	   ,f.HolderCurrency
	   ,CASE WHEN fcp.ReportingCurrency = fcp.CurrencyName THEN 1 ELSE fcp.CrossExchangeRatePrev END  CrossExchangeRatePrev
	   ,CASE WHEN fcp.ReportingCurrency = fcp.CurrencyName THEN 1 ELSE fcp.CrossExchangeRate END  CrossExchangeRate
	   ,CASE WHEN fcp.ReportingCurrency = fcp.CurrencyName THEN 0 ELSE fcp.PriceFix END  PriceFix
	   ,CASE WHEN fcp.ReportingCurrency = fcp.CurrencyName THEN 1 ELSE fcp.PriceFromReportingCurrencyToHolderCurrencyBusnessDate END  ExchangeRate
	   ------------------------------------------------
	   ,CASE WHEN fcp.ReportingCurrency = fcp.CurrencyName THEN 1 ELSE fcp.CrossExchangeRatePrev2 END  CrossExchangeRatePrev2
	   ,CASE WHEN fcp.ReportingCurrency = fcp.CurrencyName THEN 1 ELSE fcp.CrossExchangeRate2 END  CrossExchangeRate2
	   ,CASE WHEN fcp.ReportingCurrency = fcp.CurrencyName THEN 0 ELSE fcp.PriceFix2 END  PriceFix2
	   ,fcp.ApproxRateUSD USDApproxRate
	   ,fcp.ReportingCurrency
       FROM #final f 
	   LEFT JOIN #dim d 
	   ON f.AccountId =d.ProviderCurrencyBalanceID
	   LEFT JOIN #dim2 d1
	   ON f.HolderId =d1.ProviderHolderID 
	   LEFT JOIN #split fcp  
	   ON f.CurrencyIson = fcp.CurrencyISO
       AND fcp.OccurredDateID = f.BalanceDateID 
/* SELECT o.CrossExchangeRatePrev, o.CrossExchangeRate, o.CrossExchangeRatePrev2, o.CrossExchangeRate2, o.PriceFix, o.PriceFix2,o.ClosingBalanceCalc
 , o.ClosingBalanceBO, o.ClosingBalanceGAP FROM #output o WHERE o.AccountId =17195291  
 */
  /****************************/
 
IF OBJECT_ID('tempdb..#outputwithrepcurnorounds') IS NOT NULL DROP TABLE #outputwithrepcurnorounds
CREATE TABLE #outputwithrepcurnorounds WITH(HEAP, DISTRIBUTION = HASH(AccountId))
AS
SELECT o.BalanceDate
			 ,o.BalanceDateID
			 ,o.AccountId
			 ,o.OpeningBalance
			 ,o.OpeningPositiveBalance
			 ,o.BankPayIns
			 ,o.BankPayOuts
			 ,o.Card_POS
			 ,o.Card_ATM
			 ,o.EtoroDeposits
			 ,o.EtoroCashouts
			 ,o.EtoroC2FDeposits
			 ,o.BalanceAdjustments
			 ,o.ChargeBackAdjustments
			 ,o.ATMFee
			 ,o.FxFee
			 ,o.OtherFee
			 ,o.ClosingBalanceCalc
	         ,o.ClosingBalanceBO
	         ,o.ClosingBalanceGAP
	         ,o.OpeningBalanceGAP
	         ,o.ClosingNegativeBalanceBO
	         ,o.NegativeBalanceMovement
	         ,o.ClosingPositiveBalanceBO  
	         ,o.ClosingPositiveBalanceCalc  
	         ,o.ClosingPositiveBalanceGAP 
	         ,o.ClosingPositiveBalanceCalc+o.ClosingNegativeBalanceBO -o.ClosingBalanceBO  as  CheckCalc
			 ,o.TransOutOfDate
			 ,o.HolderId
			 ,o.ProgramId
			 ,o.Program
			 ,o.CurrencyIson
			 ,o.AccountStatus
			 ,o.AccountStatusDescription
			 ,o.Entity
			 ,o.GCID
			 ,o.CID
			 ,o.AccountSubProgram
			 ,o.IsExistingUser
			 ,GETDATE() UpdateDate
			 ,USDApproxRate
			 ,HolderCurrency
			 ,ReportingCurrency
		     ,o.ClosingBalanceBO * o.CrossExchangeRate2 AS ClosingBalanceBORepCur
             ,IsTest
		
             ---new---
             ,CrossExchangeRate2
             ,ExchangeRate
             ,ISNULL(o.OpeningBalance, 0) * o.CrossExchangeRatePrev2  AS OpeningBalanceRepCur
             ,ISNULL(o.OpeningPositiveBalance, 0) * o.CrossExchangeRatePrev2  AS OpeningPositiveBalanceRepCur
             ,o.OpeningBalance * o.PriceFix2  AS FX
		     ,o.OpeningPositiveBalance * o.PriceFix2  AS PositiveFX
             ,o.BankPayIns * o.CrossExchangeRate2  AS BankPayInsRepCur
             ,o.BankPayOuts * o.CrossExchangeRate2  AS BankPayOutsRepCur
             ,o.Card_POS * o.CrossExchangeRate2  AS Card_POSRepCur
             ,o.Card_ATM * o.CrossExchangeRate2  AS Card_ATMRepCur

             ,o.EtoroDeposits * o.CrossExchangeRate2  AS EtoroDepositsRepCur
             ,o.EtoroCashouts * o.CrossExchangeRate2  AS EtoroCashoutsRepCur
             ,o.EtoroC2FDeposits * o.CrossExchangeRate2  AS EtoroC2FDepositsRepCur
             ,o.BalanceAdjustments * o.CrossExchangeRate2  AS BalanceAdjustmentsRepCur
             ,o.ChargeBackAdjustments * o.CrossExchangeRate2  AS ChargeBackAdjustmentsRepCur
             ,o.ATMFee * o.CrossExchangeRate2  AS ATMFeeRepCur
             ,o.FxFee * o.CrossExchangeRate2  AS FxFeeRepCur
             ,o.OtherFee * o.CrossExchangeRate2  AS OtherFeeRepCur
             ,o.ClosingBalanceCalc * o.CrossExchangeRate2 AS ClosingBalanceCalcRepCur
             ,o.ClosingBalanceGAP * o.CrossExchangeRate2  AS ClosingBalanceGAPRepCur
             ,o.ClosingNegativeBalanceBO * o.CrossExchangeRate2  AS ClosingNegativeBalanceBORepCur
             ,o.NegativeBalanceMovement * o.CrossExchangeRate2  AS NegativeBalanceMovementRepCur
			 ,o.ClosingPositiveBalanceCalc * o.CrossExchangeRate2   AS ClosingPositiveBalanceCalcRepCur
             ,o.ClosingPositiveBalanceBO * o.CrossExchangeRate2  AS ClosingPositiveBalanceBORepCur
			 ,o.ClosingPositiveBalanceGAP * o.CrossExchangeRate2  AS ClosingPositiveBalanceGAPRepCur
             ,o.PriceFix2 
			 ,o.CrossExchangeRatePrev2

		     ,o.BankPayIns * o.CrossExchangeRate2  +
              o.BankPayOuts * o.CrossExchangeRate2  +
              o.Card_POS * o.CrossExchangeRate2 +
              o.Card_ATM * o.CrossExchangeRate2 +
			  o.EtoroDeposits * o.CrossExchangeRate2 +
              o.EtoroCashouts * o.CrossExchangeRate2  +
              o.EtoroC2FDeposits * o.CrossExchangeRate2  +
              o.BalanceAdjustments * o.CrossExchangeRate2 +
              o.ChargeBackAdjustments * o.CrossExchangeRate2  +
              o.ATMFee * o.CrossExchangeRate2  +
              o.FxFee * o.CrossExchangeRate2  +
              o.OtherFee * o.CrossExchangeRate2  AS Delta
			 FROM #output o



--DELETE FROM [eMoney_dbo].[eMoneyClientBalance] WHERE BalanceDate  ='2026-01-11'

DELETE FROM [eMoney_dbo].[eMoneyClientBalance] WHERE BalanceDateID  =@dreport_i 
INSERT  INTO [eMoney_dbo].[eMoneyClientBalance]
 (
        BalanceDate
	   ,BalanceDateID
	   ,AccountId
	   ,OpeningBalance
	   ,OpeningPositiveBalance
	   ,BankPayIns
	   ,BankPayOuts
	   ,Card_POS
	   ,Card_ATM
	   ,EtoroDeposits
	   ,EtoroCashouts
	   ,EtoroC2FDeposits
	   ,BalanceAdjustments
	   ,ChargeBackAdjustments
	   ,ATMFee
	   ,FxFee
	   ,OtherFee
	   ,ClosingBalanceCalc
	   ,ClosingBalanceBO
	   ,ClosingBalanceGAP
	   ,OpeningBalanceGAP
	   ,ClosingNegativeBalanceBO
	   ,NegativeBalanceMovement
	   ,ClosingPositiveBalanceBO  
	   ,ClosingPositiveBalanceCalc  
	   ,ClosingPositiveBalanceGAP 
	   ,CheckCalc
	   ,TransOutOfDate
	   ,HolderId
	   ,ProgramId
	   ,Program
	   ,CurrencyIson
	   ,AccountStatus
	   ,AccountStatusDescription
	   ,Entity
	   ,GCID
	   ,CID
	   ,AccountSubProgram
	   ,IsExistingUser 
       ,UpdateDate
	   ,USDApproxRate
	   ,HolderCurrency 
	   ,ReportingCurrency
	   ,IsTest
	    --new---
	   ,CrossExchangeRate
	   ,ExchangeRate
	   ,OpeningBalanceRepCur
	   ,OpeningPositiveBalanceRepCur
	   ,FX
	   ,PositiveFX
	   ,BankPayInsRepCur
	   ,BankPayOutsRepCur
	   ,Card_POSRepCur
	   ,Card_ATMRepCur
	   ,EtoroDepositsRepCur
	   ,EtoroCashoutsRepCur
	   ,EtoroC2FDepositsRepCur
	   ,BalanceAdjustmentsRepCur
	   ,ChargeBackAdjustmentsRepCur
	   ,ATMFeeRepCur
	   ,FxFeeRepCur
	   ,OtherFeeRepCur
	   ,ClosingBalanceBORepCur
	   ,ClosingBalanceCalcRepCur
	   ,ClosingBalanceGAPRepCur
	   ,ClosingNegativeBalanceBORepCur
	   ,NegativeBalanceMovementRepCur
	   ,ClosingPositiveBalanceBORepCur
	   ,ClosingPositiveBalanceCalcRepCur
	   ,ClosingPositiveBalanceGAPRepCur 
	   ,PriceFX
	   ,FXGAP
 )
	 SELECT o.BalanceDate
		   ,o.BalanceDateID
		   ,o.AccountId
		   ,o.OpeningBalance
		   ,o.OpeningPositiveBalance
		   ,o.BankPayIns
		   ,o.BankPayOuts
		   ,o.Card_POS
		   ,o.Card_ATM
		   ,o.EtoroDeposits
		   ,o.EtoroCashouts
		   ,o.EtoroC2FDeposits
		   ,o.BalanceAdjustments
		   ,o.ChargeBackAdjustments
		   ,o.ATMFee
		   ,o.FxFee
		   ,o.OtherFee
		   ,o.ClosingBalanceCalc
		   ,o.ClosingBalanceBO
		   ,o.ClosingBalanceGAP
		   ,o.OpeningBalanceGAP
		   ,o.ClosingNegativeBalanceBO
		   ,o.NegativeBalanceMovement
		   ,o.ClosingPositiveBalanceBO
		   ,o.ClosingPositiveBalanceCalc
		   ,o.ClosingPositiveBalanceGAP
		   ,o.CheckCalc
		   ,o.TransOutOfDate
		   ,o.HolderId
		   ,o.ProgramId
		   ,o.Program
		   ,o.CurrencyIson
		   ,o.AccountStatus
		   ,o.AccountStatusDescription
		   ,o.Entity
		   ,o.GCID
		   ,o.CID
		   ,o.AccountSubProgram
		   ,o.IsExistingUser
		   ,o.UpdateDate
		   ,o.USDApproxRate
		   ,o.HolderCurrency
		   ,o.ReportingCurrency
		   ,o.IsTest
		   --new--
		   ,o.CrossExchangeRate2
		   ,o.ExchangeRate
		   ,o.OpeningBalanceRepCur
		   ,o.OpeningPositiveBalanceRepCur
		   ,o.FX
		   ,o.PositiveFX
		   ,o.BankPayInsRepCur
		   ,o.BankPayOutsRepCur
		   ,o.Card_POSRepCur
		   ,o.Card_ATMRepCur
		   ,o.EtoroDepositsRepCur
		   ,o.EtoroCashoutsRepCur
		   ,o.EtoroC2FDepositsRepCur
		   ,o.BalanceAdjustmentsRepCur
		   ,o.ChargeBackAdjustmentsRepCur
		   ,o.ATMFeeRepCur
		   ,o.FxFeeRepCur
		   ,o.OtherFeeRepCur
		   ,o.ClosingBalanceBORepCur
		   ,o.ClosingBalanceCalcRepCur
		   ,o.ClosingBalanceGAPRepCur
		   ,o.ClosingNegativeBalanceBORepCur
		   ,o.NegativeBalanceMovementRepCur
		   ,o.ClosingPositiveBalanceBORepCur
		   ,o.ClosingPositiveBalanceCalcRepCur
		   ,o.ClosingPositiveBalanceGAPRepCur 
		   ,o.PriceFix2    PriceFX
		   ,CAST((ISNULL(o.ClosingBalanceBORepCur, 0) - ISNULL(o.OpeningBalanceRepCur, 0) -  ISNULL(o.Delta, 0) -ISNULL(o.FX, 0)) AS DECIMAL(16, 6)) AS FXGAP
		  FROM #outputwithrepcurnorounds o

/************************Update Missing Users after July 2025 backwards as we having mapping issues a lot 

*************/
UPDATE f
SET 
    f.GCID = COALESCE(d.GCID, d1.GCID),
    f.CID = COALESCE(d.CID, d1.CID),
    f.AccountSubProgram = COALESCE(d.AccountSubProgram, d1.AccountSubProgram),
    f.IsExistingUser = CASE WHEN COALESCE(d.GCID, d1.GCID) IS NULL THEN 0 ELSE 1 END
FROM 
    eMoney_dbo.eMoneyClientBalance f
    LEFT JOIN #dim d ON f.AccountId = d.ProviderCurrencyBalanceID
    LEFT JOIN #dim2 d1 ON f.HolderId = d1.ProviderHolderID
WHERE 
    f.GCID IS NULL
    AND f.BalanceDateID >= 20250701
	AND COALESCE(d.GCID, d1.GCID) IS NOT NULL;

/************************CB Alerts*************/
/*Start*/
PRINT 'Start eMoney CB Alerts'

EXEC [eMoney_dbo].[SP_eMoney_Client_Balance_Check_Opening_Balance] @d
EXEC [eMoney_dbo].[SP_eMoney_Client_Balance_Check_Exceptions_Gap] @d

PRINT 'End eMoney CB Alerts'
/*End*/

END
	
/* 
    --------------------------
	--drop
 ALTER TABLE [eMoney_dbo].[eMoneyClientBalance] DROP COLUMN ClosingBalanceBORepCur

 ----add
          ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD CrossExchangeRate decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ExchangeRate decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD OpeningBalanceRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD OpeningPositiveBalanceRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD FX decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD PositiveFX decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD BankPayInsRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD BankPayOutsRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD Card_POSRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD Card_ATMRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD EtoroDepositsRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD EtoroCashoutsRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD EtoroC2FDepositsRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD BalanceAdjustmentsRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ChargeBackAdjustmentsRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ATMFeeRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD FxFeeRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD OtherFeeRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ClosingBalanceBORepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ClosingBalanceCalcRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ClosingBalanceGAPRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ClosingNegativeBalanceBORepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD NegativeBalanceMovementRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ClosingPositiveBalanceBORepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ClosingPositiveBalanceCalcRepCur decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD ClosingPositiveBalanceGAPRepCur  decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD PriceFX  decimal(24, 12) NULL;
		  ALTER TABLE [eMoney_dbo].[eMoneyClientBalance]  ADD FXGAP  decimal(12, 6) NULL;
		  
   	  
   SELECT o.CrossExchangeRate2, o.CrossExchangeRatePrev2, o.ExchangeRate, o.OpeningBalance, o.ClosingBalanceBO,o.ClosingBalanceCalc, o.OpeningBalanceRepCur
			,o.ClosingBalanceBORepCur, ClosingBalanceCalcRepCur,o.FX
			,o.ClosingBalanceGAPRepCur, o.PriceFix2  
		    ,CAST((ISNULL(o.ClosingBalanceBORepCur, 0) - ISNULL(o.OpeningBalanceRepCur, 0) - ISNULL(o.FX, 0)) AS DECIMAL(18, 6)) AS FXGAP
		  FROM #outputwithrepcurnorounds o  WHERE o.AccountId =17271525 

	  
		   SELECT 
		    sum(o.ClosingBalanceCalcRepCur) ClosingBalanceCalcRepCur
		   ,sum( o.ClosingBalanceBORepCur) ClosingBalanceBORepCur
		   ,sum(o.ClosingPositiveBalanceBORepCur)ClosingPositiveBalanceBO
		   ,sum(o.ClosingPositiveBalanceCalcRepCur)ClosingPositiveBalanceCalc
		   ,sum(o.ClosingPositiveBalanceGAPRepCur)ClosingPositiveBalanceGAP
		   , o.BalanceDate
		   , sum(FX)fx
		   , Sum(OpeningBalanceRepCur)OpeningBalanceRepCur
		   , sum(FXGAP) FXGAP
		   , AccountId
		   	from 	 [eMoney_dbo].[eMoneyClientBalance] o
		   WHERE o.HolderCurrency ='DKK'
		   AND o.ClosingBalanceBO <>0  AND o.BalanceDate IN ( '2026-01-11')
		   GROUP BY BalanceDate,AccountId

			  */



GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `eMoney_dbo.eMoneyClientBalance` | synapse | eMoney_dbo | eMoneyClientBalance | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoneyClientBalance.md` |
| `eMoney_dbo.SP_eMoney_Client_Balance_Check_Opening_Balance` | synapse_sp | eMoney_dbo | SP_eMoney_Client_Balance_Check_Opening_Balance | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\eMoney_dbo\Stored Procedures\eMoney_dbo.SP_eMoney_Client_Balance_Check_Opening_Balance.sql` |
| `eMoney_dbo.SP_eMoney_ClientBalance` | synapse_sp | eMoney_dbo | SP_eMoney_ClientBalance | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\eMoney_dbo\Stored Procedures\eMoney_dbo.SP_eMoney_ClientBalance.sql` |

