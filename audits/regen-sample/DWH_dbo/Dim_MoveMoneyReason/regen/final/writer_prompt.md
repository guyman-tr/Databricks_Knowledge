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

- **Schema**: `DWH_dbo`
- **Object**: `Dim_MoveMoneyReason`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/DWH_dbo/Dim_MoveMoneyReason/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\Dim_MoveMoneyReason\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\Dim_MoveMoneyReason\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Tables\DWH_dbo.Dim_MoveMoneyReason.sql`

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

# Pre-Resolved Upstream Bundle for `DWH_dbo.Dim_MoveMoneyReason`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Dim_MoveMoneyReason.sql`

```sql
CREATE TABLE [DWH_dbo].[Dim_MoveMoneyReason]
(
	[MoveMoneyReasonID] [int] NULL,
	[MoveMoneyReason] [varchar](30) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED INDEX
	(
		[MoveMoneyReasonID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 1 upstream wiki(s). Read EACH one in full.


### Upstream `etoro.Dictionary.MoveMoneyReason` — production
- **Resolved as**: `etoro.Dictionary.MoveMoneyReason`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Dictionary\Tables\Dictionary.MoveMoneyReason.md`

# Dictionary.MoveMoneyReason

> Classifies the business reasons for internal money movements (balance adjustments, transfers, staking, bonuses) recorded in the ActiveCredit ledger system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MoveMoneyReasonID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.MoveMoneyReason enumerates the valid business justifications for internal money movements — balance credits, debits, and transfers that are not standard deposits or withdrawals. These operations are recorded in the ActiveCredit system (History.ActiveCredit) and tracked for audit, compliance, and financial reporting.

Without this table, the system could not classify internal money movements, making it impossible to distinguish between manual adjustments, bonus abuse corrections, staking rewards, internal account transfers, and recurring investments. Compliance and finance teams rely on these reason codes for reconciliation and regulatory reporting.

Referenced by 50+ procedures across Customer, Billing, and Trade schemas including Customer.SetBalance, Customer.SetBalanceCompensation, Billing.AmountAdd, Billing.DepositProcess, Trade.InsertActiveCredit, and numerous credit history retrieval procedures (Trade.TAPI_GetFlatCreditHistoryByCID variants).

---

## 2. Business Logic

### 2.1 Money Movement Categories

**What**: Eight reason codes categorizing non-standard financial operations.

**Columns/Parameters Involved**: `MoveMoneyReasonID`, `MoveMoneyReason`

**Rules**:
- Adjustment (1): Manual balance correction by operations staff
- Bonus Abuser (2): Reversal of bonus funds from customers flagged for bonus abuse
- Staking (3): Crypto staking reward credits
- ID 4 is missing — possibly deprecated
- InternalTransfer Trade (5): Inter-account transfer related to trading operations
- InternalTransfer (6): General inter-account transfer (not trade-specific)
- Not In Use (7): Reserved/deprecated placeholder
- Recurring Deposit (8): Automated periodic deposit from linked payment method
- Recurring Investment (9): Automated periodic investment allocation

**Diagram**:
```
Money Movement Reasons:
  Manual ──────────> Adjustment (1), Bonus Abuser (2)
  Crypto ──────────> Staking (3)
  Transfers ───────> InternalTransfer Trade (5), InternalTransfer (6)
  Reserved ────────> Not In Use (7)
  Automated ───────> Recurring Deposit (8), Recurring Investment (9)
```

---

## 3. Data Overview

| MoveMoneyReasonID | MoveMoneyReason | Meaning |
|---|---|---|
| 1 | Adjustment | Manual balance correction by operations/compliance staff — used for error fixes, compensations, and regulatory adjustments |
| 2 | Bonus Abuser | Clawback of bonus funds from customers identified as abusing promotional offers — compliance-driven reversal |
| 3 | Staking | Crypto staking reward credits — periodic yield earned on eligible crypto positions held on the platform |
| 5 | InternalTransfer Trade | Money movement between accounts triggered by a trading operation (e.g., transferring funds to cover a trade in a different entity) |
| 9 | Recurring Investment | Automated periodic investment — customer has configured regular allocations to specific instruments or CopyTrading leaders |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MoveMoneyReasonID | int | NO | - | CODE-BACKED | Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures. |
| 2 | MoveMoneyReason | varchar(30) | NO | - | VERIFIED | Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ActiveCredit | MoveMoneyReasonID | Implicit | Credit history records classify the reason for each money movement |
| Customer.SetBalance | @MoveMoneyReasonID | Implicit | Balance adjustment procedure records the reason |
| Customer.SetBalanceCompensation | @MoveMoneyReasonID | Implicit | Compensation procedure records the reason |
| Billing.AmountAdd | @MoveMoneyReasonID | Implicit | Amount addition records movement reason |
| Billing.DepositProcess | MoveMoneyReasonID | Implicit | Deposit processing classifies internal movements |
| Trade.InsertActiveCredit | MoveMoneyReasonID | Implicit | Credit insertion records reason |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table | MoveMoneyReasonID column |
| Customer.SetBalance | Stored Procedure | Records movement reason |
| Customer.SetBalanceCompensation | Stored Procedure | Records compensation reason |
| Customer.SetBalanceDeposit | Stored Procedure | Records deposit reason |
| Customer.SetBalanceCashOut | Stored Procedure | Records cashout reason |
| Customer.SetBalanceBonus | Stored Procedure | Records bonus reason |
| Billing.AmountAdd | Stored Procedure | Records amount addition reason |
| Billing.DepositProcess | Stored Procedure | Classifies deposit movements |
| Trade.InsertActiveCredit | Stored Procedure | Records credit reason |
| Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit | Stored Procedure | Reads for credit history API |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryMoneyReason | CLUSTERED PK | MoveMoneyReasonID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all money movement reasons
```sql
SELECT  MoveMoneyReasonID,
        MoveMoneyReason
FROM    [Dictionary].[MoveMoneyReason] WITH (NOLOCK)
ORDER BY MoveMoneyReasonID;
```

### 8.2 Find active credit entries by reason
```sql
SELECT  mmr.MoveMoneyReason,
        COUNT(*) AS CreditCount
FROM    [History].[ActiveCredit] ac WITH (NOLOCK)
JOIN    [Dictionary].[MoveMoneyReason] mmr WITH (NOLOCK)
        ON ac.MoveMoneyReasonID = mmr.MoveMoneyReasonID
GROUP BY mmr.MoveMoneyReason
ORDER BY CreditCount DESC;
```

### 8.3 Find all staking credits for a customer
```sql
SELECT  ac.*,
        mmr.MoveMoneyReason
FROM    [History].[ActiveCredit] ac WITH (NOLOCK)
JOIN    [Dictionary].[MoveMoneyReason] mmr WITH (NOLOCK)
        ON ac.MoveMoneyReasonID = mmr.MoveMoneyReasonID
WHERE   mmr.MoveMoneyReasonID = 3
        AND ac.CustomerID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MoveMoneyReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MoveMoneyReason.sql*


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason | `—` |
| `etoro.Dictionary.MoveMoneyReason` | production | Dictionary | MoveMoneyReason | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Dictionary\Tables\Dictionary.MoveMoneyReason.md` |

