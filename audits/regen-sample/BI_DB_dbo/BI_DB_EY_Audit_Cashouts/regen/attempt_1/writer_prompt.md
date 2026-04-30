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
- **Object**: `BI_DB_EY_Audit_Cashouts`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_Cashouts/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_EY_Audit_Cashouts\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\BI_DB_dbo\BI_DB_EY_Audit_Cashouts\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Tables\BI_DB_dbo.BI_DB_EY_Audit_Cashouts.sql`

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

# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_EY_Audit_Cashouts`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_EY_Audit_Cashouts.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_EY_Audit_Cashouts]
(
	[RealCID] [int] NOT NULL,
	[DateID] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[ExternalID] [decimal](38, 0) NULL,
	[ActionType] [varchar](100) NULL,
	[WithdrawID] [int] NOT NULL,
	[WithdrawPaymentID] [int] NOT NULL,
	[Occurred] [datetime] NOT NULL,
	[Amount] [decimal](11, 2) NOT NULL,
	[PaymentMethod] [varchar](50) NULL,
	[Depot] [varchar](50) NULL,
	[BankNameAsString] [nvarchar](max) NULL,
	[CardType] [varchar](50) NULL,
	[Regulation] [varchar](50) NULL,
	[IsCreditReportValidCB] [int] NULL,
	[BaseExchangeRate] [varchar](50) NULL,
	[ExchangeFee] [varchar](50) NULL,
	[VerificationCode] [varchar](50) NULL,
	[UpdateDate] [date] NULL
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

Found 13 upstream wiki(s). Read EACH one in full.


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

### Upstream `DWH_dbo.Dim_FundingType` — synapse
- **Resolved as**: `DWH_dbo.Dim_FundingType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md`

# DWH_dbo.Dim_FundingType

> Payment method dimension - maps funding type IDs to payment method names and behavioral flags for eToro deposits, withdrawals, and cashout eligibility. Used by billing and customer action fact tables.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.FundingType |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (FundingTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_FundingType` is a payment method dimension with 44 rows (FundingTypeID 0-44, with ID 41 absent). Each row represents a payment method or funding channel that eToro customers use for deposits and withdrawals. Methods span credit cards, bank transfers, e-wallets, crypto, regional payment systems (Yandex, Qiwi, AliPay, WeChat, Przelewy24), and eToro-internal channels (eToroCryptoWallet, eToroMoney).

Three behavioral flags classify each method:
- `IsNewStyle`: modern-era payment integration (True = post-legacy platform)
- `IsSingleFunding`: one-time/single use (True = e.g., BankDraft, InternalPayment)
- `IsCashoutActive`: cashout/withdrawal supported via this method (True = bidirectional)

**FundingTypeID=0 (N/A)** is a DWH-injected synthetic null-sentinel row, inserted after the main staging load as a hardcoded VALUES insert. Fact tables use `ISNULL(FundingTypeID, 0)` to replace NULLs with this sentinel, enabling NULL-safe joins.

**FundingTypeID=27 (eToroCryptoWallet)** has hardcoded business logic: `SP_Fact_CustomerAction` calculates `IsRedeem = 1` when CreditTypeID=2 AND FundingTypeID=27. This hardcoding creates a maintenance risk if the crypto wallet ID changes.

This dimension is actively consumed by three major fact tables: `Fact_BillingDeposit`, `Fact_BillingWithdraw`, and `Fact_CustomerAction`.

---

## 2. Business Logic

### 2.1 Payment Method Classification Flags

**What**: Three bit flags classify payment method behavior.

**Columns Involved**: `IsNewStyle`, `IsSingleFunding`, `IsCashoutActive`

**Rules**:
- `IsNewStyle`: FALSE only for BankDraft (4), WesternUnion (5), MoneyGram (9). These are legacy payment methods.
- `IsSingleFunding`: TRUE for one-time or non-reusable methods: BankDraft (4), WesternUnion (5), MoneyGram (9), InternalPayment (16), TestDeposit (18), IBDeposit (19)
- `IsCashoutActive`: FALSE for methods where withdrawal is not supported: Giropay (11), Payoneer (14), Sofort (15), InternalPayment (16), LocalBankWire (17), TestDeposit (18), CashU (24), AliPay (25), WeChat (26), RapidTransfer (30), AstroPay (31), EtoroOptions (42), MoneyFarm (44)

### 2.2 Null Sentinel (FundingTypeID=0)

**What**: FundingTypeID=0 / Name='N/A' is a synthetic row added post-staging to represent unknown/missing funding type.

**Columns Involved**: `FundingTypeID`, `DWHFundingTypeID`

**Rules**:
- SP_Fact_CustomerAction uses `ISNULL(FundingTypeID, 0)` and `ISNULL(d.FundingTypeID, ISNULL(dd.FundingTypeID, 0))` to coerce NULLs to 0
- For the N/A row: DWHFundingTypeID=0 (same as FundingTypeID), all flags=False
- Inserted via hardcoded VALUES block in SP_Dictionaries (not from staging)

### 2.3 eToroCryptoWallet Hardcoded Logic

**What**: FundingTypeID=27 (eToroCryptoWallet) drives the `IsRedeem` flag in Fact_CustomerAction.

**Columns Involved**: `FundingTypeID`

**Rules**:
- `IsRedeem = CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`
- This hardcoded check appears in multiple sections of SP_Fact_CustomerAction
- Risk: If eToroCryptoWallet is assigned a new FundingTypeID, IsRedeem calculation breaks silently

### 2.4 DWHFundingTypeID Passthrough

**What**: `DWHFundingTypeID` mirrors `FundingTypeID` for all source rows (passthrough from staging).

**Rules**:
- For rows from staging: `DWHFundingTypeID = FundingTypeID` (same value, ETL SET `[FundingTypeID] as [DWHFundingTypeID]`)
- For the N/A row (FundingTypeID=0): `DWHFundingTypeID = 0`
- Purpose is likely for DWH-layer remapping or future surrogate key substitution. Currently identical to FundingTypeID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed (44 rows - appropriate). CLUSTERED INDEX on FundingTypeID. No data movement on joins.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, 44 rows - no partitioning needed. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FundingTypeID to name | `LEFT JOIN DWH_dbo.Dim_FundingType ON FundingTypeID` |
| Find cashout-eligible methods | `WHERE IsCashoutActive = 1` |
| Identify legacy payment methods | `WHERE IsNewStyle = 0` |
| Exclude N/A sentinel | `WHERE FundingTypeID > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingDeposit | ON FundingTypeID | Payment method for deposits |
| DWH_dbo.Fact_BillingWithdraw | ON FundingTypeID_Withdraw / FundingTypeID_Funding | Payment method for withdrawals |
| DWH_dbo.Fact_CustomerAction | ON FundingTypeID | Payment method for customer financial actions |

### 3.4 Gotchas

- **FundingTypeID=0 is synthetic**: The N/A row (ID=0) does not come from the source system. It is DWH-injected after TRUNCATE+INSERT. Never filter it out blindly - fact tables use it for NULL FK rows.
- **FundingTypeID=41 missing**: The sequence jumps from 40 to 42. ID 41 was likely deleted or never assigned.
- **FundingTypeID=27 hardcoded**: eToroCryptoWallet ID is hardcoded in SP_Fact_CustomerAction for IsRedeem logic. Do not renumber/reassign this ID.
- **FundingTypeID is smallint NULL**: Nullable primary key with NOT NULL-equivalent usage. Join columns in fact tables may be int - implicit type conversion occurs.
- **Fact_BillingWithdraw has TWO FK columns**: `FundingTypeID_Withdraw` (the withdrawal method) and `FundingTypeID_Funding` (the original funding method). Both reference this dimension.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundingTypeID | smallint | YES | Primary key identifying the payment method. (Tier 1 — Dictionary.FundingType) |
| 2 | Name | varchar(50) | NO | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). (Tier 1 — Dictionary.FundingType) |
| 3 | IsNewStyle | bit | NO | Whether this payment method uses the newer integration style. Affects which code path handles the transaction. (Tier 1 — Dictionary.FundingType) |
| 4 | IsSingleFunding | bit | NO | Whether this is a one-time payment method (cannot be saved for repeat use). 1=single-use, 0=can be saved. (Tier 1 — Dictionary.FundingType) |
| 5 | IsCashoutActive | bit | NO | Whether withdrawals (cashouts) are supported via this method. 1=supports cashout, 0=deposit-only. (Tier 1 — Dictionary.FundingType) |
| 6 | DWHFundingTypeID | smallint | NO | DWH copy of FundingTypeID. SET in ETL as `[FundingTypeID] as [DWHFundingTypeID]`. Currently identical to FundingTypeID for all rows. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | StatusID | int | YES | Hardcoded to 1 for all rows (both staging rows and N/A sentinel). Likely means active. No corresponding Dim_Status table found. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 8 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() (stored as @ddate variable). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 9 | InsertDate | datetime | YES | ETL load timestamp. Set to GETDATE() (same value as UpdateDate). Both columns set on each run. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | passthrough |
| Name | etoro.Dictionary.FundingType | Name | passthrough |
| IsNewStyle | etoro.Dictionary.FundingType | IsNewStyle | passthrough |
| IsSingleFunding | etoro.Dictionary.FundingType | IsSingleFunding | passthrough |
| IsCashoutActive | etoro.Dictionary.FundingType | IsCashoutActive | passthrough |
| DWHFundingTypeID | etoro.Dictionary.FundingType | FundingTypeID | ETL-computed: same as FundingTypeID (alias) |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.FundingType -> Generic Pipeline -> DWH_staging.etoro_Dictionary_FundingType
    -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 672) -> Dim_FundingType (rows 1-44)
    -> SP_Dictionaries_DL_To_Synapse (VALUES INSERT, ~line 1475) -> Dim_FundingType row 0 (N/A sentinel)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.FundingType | Payment method dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/FundingType/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_FundingType | Raw import |
| ETL (main) | DWH_dbo.SP_Dictionaries_DL_To_Synapse ~line 672 | TRUNCATE + INSERT. Adds DWHFundingTypeID=FundingTypeID, StatusID=1, UpdateDate/InsertDate=GETDATE(). |
| ETL (sentinel) | DWH_dbo.SP_Dictionaries_DL_To_Synapse ~line 1475 | Hardcoded VALUES INSERT for FundingTypeID=0, Name='N/A'. |
| Target | DWH_dbo.Dim_FundingType | 44-row REPLICATE/CLUSTERED dimension. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references from this table. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingDeposit | FundingTypeID | Payment method for each deposit transaction |
| DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Withdraw | Withdrawal payment method |
| DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Funding | Original funding method for withdrawal |
| DWH_dbo.Fact_CustomerAction | FundingTypeID | Payment method for customer financial actions |

---

## 7. Sample Queries

### 7.1 All payment methods with cashout support

```sql
SELECT FundingTypeID, Name, IsNewStyle, IsSingleFunding
FROM DWH_dbo.Dim_FundingType
WHERE IsCashoutActive = 1 AND FundingTypeID > 0
ORDER BY FundingTypeID
```

### 7.2 Legacy (non-new-style) methods

```sql
SELECT FundingTypeID, Name, IsSingleFunding, IsCashoutActive
FROM DWH_dbo.Dim_FundingType
WHERE IsNewStyle = 0 AND FundingTypeID > 0
```

### 7.3 Join deposits with payment method name

```sql
SELECT ft.Name AS PaymentMethod, COUNT(*) AS DepositCount
FROM DWH_dbo.Fact_BillingDeposit bd
JOIN DWH_dbo.Dim_FundingType ft ON bd.FundingTypeID = ft.FundingTypeID
WHERE ft.FundingTypeID > 0
GROUP BY ft.Name
ORDER BY DepositCount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 5 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/9, Logic: 9/10, Relationships: 9/10, Sources: 8/10*
*Object: DWH_dbo.Dim_FundingType | Type: Table | Production Source: etoro.Dictionary.FundingType*


### Upstream `DWH_dbo.Dim_BillingDepot` — synapse
- **Resolved as**: `DWH_dbo.Dim_BillingDepot`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md`

# DWH_dbo.Dim_BillingDepot

> Lookup dimension of payment gateway endpoints ("depots"), each configuring one (FundingType + PaymentType + Protocol) routing combination. Sourced daily from etoro.Billing.Depot via SP_Dictionaries_DL_To_Synapse. 163 rows; 114 active.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Depot |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DepotID) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_BillingDepot is the DWH version of etoro.Billing.Depot -- the central payment gateway routing configuration table. Each row defines one payment depot: a named combination of payment method (FundingTypeID), payment direction (PaymentTypeID: Deposit/Cashout/Refund), and processing gateway (ProtocolID). The routing engine selects a depot to process each transaction based on these three dimensions plus customer-specific factors (regulation, BIN, quotas).

Source: etoro.Billing.Depot on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Billing/Depot/ and staged into DWH_staging.etoro_Billing_Depot. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern.

163 rows total (DepotID range 1-174 with gaps); 114 active (70%), 49 inactive (legacy or decommissioned). The DWH includes only 7 of the 8 production columns -- PayoutGeneration and Features are excluded by the ETL SELECT.

Sample depots: 1=MoneyBookers USD, 7=Neteller, 10=Wire, 3=WebMoney, 4=Giropay.

---

## 2. Business Logic

### 2.1 Depot Routing Selection

**What**: The payment routing engine selects a depot for each transaction based on FundingTypeID, PaymentTypeID, and ProtocolID combined with customer-specific routing criteria.

**Columns Involved**: `DepotID`, `FundingTypeID`, `PaymentTypeID`, `ProtocolID`, `IsActive`

**Rules**:
- Only depots with IsActive=1 are eligible for routing (114 of 163)
- IsActive=0 or NULL means the depot is inactive (legacy or decommissioned) -- excluded from routing
- The (FundingTypeID, PaymentTypeID, ProtocolID) triple uniquely identifies a depot endpoint
- PaymentTypeID: 1=Deposit, 2=Cashout, 3=Refund

**Dimension Relationships**:
- FundingTypeID references Dictionary.FundingType (payment method: CreditCard, Wire, Neteller, etc.)
- PaymentTypeID references Dictionary.PaymentType (1=Deposit, 2=Cashout, 3=Refund)
- ProtocolID references Dictionary.Protocol (specific gateway API)

### 2.2 DWH Completeness Note

**Excluded from DWH**: The production Billing.Depot table also has PayoutGeneration (automated payout file support) and Features (per-depot JSON/XML configuration flags). These columns are not in the SP SELECT and are not present in Dim_BillingDepot. Analyses requiring payout generation capability or feature flags must query the production source.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on DepotID. REPLICATE is correct for a 163-row lookup -- every distribution node holds a local copy, eliminating data movement on JOINs. The clustered index on DepotID supports efficient point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for a 163-row reference table. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All active payment depots | WHERE IsActive = 1 |
| Deposit depots by payment method | WHERE PaymentTypeID = 1, GROUP BY FundingTypeID |
| Cashout-capable depots | WHERE PaymentTypeID = 2 AND IsActive = 1 |
| Depots for a specific gateway | WHERE ProtocolID = N |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | ON DepotID | MID configuration per depot |
| Fact tables (deposit/cashout) | ON DepotID | Resolve depot name and attributes for transactions |

### 3.4 Gotchas

- **IsActive NULL = Inactive**: The column is nullable. NULL should be treated as inactive (not eligible for routing). Use `WHERE IsActive = 1` rather than `WHERE IsActive <> 0`.
- **No InsertDate**: Unlike most other Dim_ tables loaded by SP_Dictionaries, this table has only UpdateDate (no InsertDate, no StatusID, no DWH surrogate key).
- **PayoutGeneration/Features not in DWH**: Two production columns are excluded. For payout batch analysis, the production source must be queried directly.
- **163 rows total, 114 active**: Inactive rows represent legacy/decommissioned gateway integrations. Do not assume all rows are usable.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Billing.Depot) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepotID | int | NOT NULL | Primary key. Manually assigned (no IDENTITY). Stable identifier for this payment gateway endpoint. Range 1-174 with gaps; 163 rows. Referenced by fact deposit/cashout tables and MID settings. (Tier 1 - upstream wiki, Billing.Depot) |
| 2 | FundingTypeID | int | NOT NULL | Payment method type (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). References Dictionary.FundingType. 38 distinct values across 163 depots. (Tier 1 - upstream wiki, Billing.Depot) |
| 3 | PaymentTypeID | int | NOT NULL | Direction of payment flow. 1=Deposit, 2=Cashout, 3=Refund. References Dictionary.PaymentType. (Tier 1 - upstream wiki, Billing.Depot) |
| 4 | ProtocolID | int | NOT NULL | Payment processing protocol/gateway. References Dictionary.Protocol. Identifies the specific API or connection (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). (Tier 1 - upstream wiki, Billing.Depot) |
| 5 | Name | varchar(50) | NOT NULL | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. (Tier 1 - upstream wiki, Billing.Depot) |
| 6 | IsActive | bit | YES | Whether this depot currently accepts transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. (Tier 1 - upstream wiki, Billing.Depot) |
| 7 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production depot configuration changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DepotID | etoro.Billing.Depot | DepotID | Passthrough |
| FundingTypeID | etoro.Billing.Depot | FundingTypeID | Passthrough |
| PaymentTypeID | etoro.Billing.Depot | PaymentTypeID | Passthrough |
| ProtocolID | etoro.Billing.Depot | ProtocolID | Passthrough |
| Name | etoro.Billing.Depot | Name | Passthrough |
| IsActive | etoro.Billing.Depot | IsActive | Passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| *(excluded)* | etoro.Billing.Depot | PayoutGeneration | Not loaded into DWH |
| *(excluded)* | etoro.Billing.Depot | Features | Not loaded into DWH |

### 5.2 ETL Pipeline

```
etoro.Billing.Depot -> Generic Pipeline (daily, Override) -> Bronze/etoro/Billing/Depot/ -> DWH_staging.etoro_Billing_Depot -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_BillingDepot
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Billing.Depot | 163-row payment depot registry (etoroDB-REAL) |
| Lake | Bronze/etoro/Billing/Depot/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Billing_Depot | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; 7 of 8 production columns loaded; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_BillingDepot | 163 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DepotID | etoro.Billing.Depot | Production source (upstream reference) |
| FundingTypeID | etoro.Dictionary.FundingType | Payment method lookup (implicit -- no FK in DWH) |
| PaymentTypeID | etoro.Dictionary.PaymentType | Payment direction lookup (implicit -- no FK in DWH) |
| ProtocolID | etoro.Dictionary.Protocol | Gateway protocol lookup (implicit -- no FK in DWH) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | DepotID | MID configuration per depot |

---

## 7. Sample Queries

### 7.1 List active depots

```sql
SELECT DepotID, Name, FundingTypeID, PaymentTypeID, ProtocolID
FROM [DWH_dbo].[Dim_BillingDepot]
WHERE IsActive = 1
ORDER BY FundingTypeID, PaymentTypeID
```

### 7.2 Count depots by payment direction

```sql
SELECT
    PaymentTypeID,
    CASE PaymentTypeID WHEN 1 THEN 'Deposit' WHEN 2 THEN 'Cashout' WHEN 3 THEN 'Refund' ELSE 'Unknown' END AS Direction,
    COUNT(*) AS TotalDepots,
    SUM(CAST(ISNULL(IsActive, 0) AS INT)) AS ActiveDepots
FROM [DWH_dbo].[Dim_BillingDepot]
GROUP BY PaymentTypeID
ORDER BY PaymentTypeID
```

### 7.3 ETL freshness check

```sql
SELECT MAX(UpdateDate) AS LastLoad, COUNT(*) AS DepotCount
FROM [DWH_dbo].[Dim_BillingDepot]
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.5/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 6 T1, 1 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_BillingDepot | Type: Table | Production Source: etoro.Billing.Depot*


### Upstream `DWH_dbo.Dim_CardType` — synapse
- **Resolved as**: `DWH_dbo.Dim_CardType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CardType.md`

# DWH_dbo.Dim_CardType

> 18-row replicated dimension table listing payment card network brands (Visa, MasterCard, Diners, etc.) with their active status. Sourced from etoro production `Dictionary.CardType` via one-time migration (last updated 2019-06-30). Used as a lookup dimension by billing and deposit SPs across BI_DB_dbo.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `Dictionary.CardType` (etoro production) via DWH_Migration staging |
| **Refresh** | Daily (Generic Pipeline, Override, 1440 min) — but data unchanged since 2019-06-30 |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CardTypeID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override) |

---

## 1. Business Meaning

Dim_CardType is a small lookup dimension defining the 18 payment card network brands recognized by the eToro platform in the DWH layer. It is a subset of the production `Dictionary.CardType` table (which has 32 entries). When a customer deposits via credit or debit card, the card's BIN (Bank Identification Number) is resolved to a CardTypeID, and this dimension provides the human-readable brand name and active status.

The table was loaded via a one-time migration from production (`DWH_Migration.Dim_CardType` staging table) and all 18 rows share the same UpdateDate of 2019-06-30, indicating no incremental refreshes have occurred since the initial load. The Generic Pipeline exports this table daily to Unity Catalog as a Gold Override, but the underlying data has not changed.

Notable: the DWH copy carries only 18 of the 32 production card types (CardTypeID 0–17) and does NOT include the `Is3dsOn` column from the production source. The `IsActive` values in the DWH differ from production for some card types (e.g., CardTypeID 0 "None" is IsActive=1 in DWH but IsActive=0 in production; Maestro (8) is IsActive=0 in DWH but IsActive=1 in production), suggesting the DWH snapshot was taken at a different point in time.

---

## 2. Business Logic

### 2.1 Card Brand Lookup

**What**: Maps CardTypeID integers to human-readable card network brand names.

**Columns Involved**: `CardTypeID`, `CarTypeName`

**Rules**:
- CardTypeID 0 = "None" (fallback when BIN lookup fails to identify a card network)
- CardTypeID 1 = Visa, 2 = Master Card, 3 = Diners, 8 = Maestro — the four historically active brands in production
- CardTypeIDs 4–7, 9–17 are inactive/legacy brands (Amex, Fire Pay, JCB, American Express, Laser, Switch, UK Local Credit Card, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital)

### 2.2 Active Status Flag

**What**: Indicates whether a card brand is accepted for deposits.

**Columns Involved**: `IsActive`

**Rules**:
- IsActive = 1: Card brand is accepted for deposits. In the DWH snapshot: Visa (1), Master Card (2), Diners (3), and None (0) show as active
- IsActive = 0: Card brand is not accepted — card will be rejected at deposit time
- Note: DWH values may diverge from current production state (snapshot from 2019-06-30)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution — full copy on every compute node. Ideal for this 18-row lookup: JOINs never require data movement.
- **CLUSTERED INDEX** on `CardTypeID` — efficient for point lookups and range scans by ID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What card brands are active? | `SELECT * FROM DWH_dbo.Dim_CardType WHERE IsActive = 1` |
| Resolve CardTypeID to name | JOIN to Dim_CardType on CardTypeID |
| Full card type list | `SELECT * FROM DWH_dbo.Dim_CardType ORDER BY CardTypeID` (only 18 rows) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact_BillingDeposit | `ON d.CardTypeID = ct.CardTypeID` | Resolve card brand for deposit transactions |
| Dim_CountryBin | `ON cb.CardTypeID = ct.CardTypeID` | Link BIN records to card brand names |

### 3.4 Gotchas

- **Column name typo**: The column is `CarTypeName` (missing "d" — not `CardTypeName`). This is in the DDL and cannot be changed without an ALTER.
- **IsActive divergence**: DWH IsActive values reflect a 2019 snapshot and may differ from current production `Dictionary.CardType.IsActive`.
- **Missing Is3dsOn**: The production `Dictionary.CardType` has an `Is3dsOn` column for 3D Secure configuration that is NOT carried into the DWH dimension. If 3DS status is needed, query production directly.
- **Subset of production**: Only 18 of 32 production card types are present (CardTypeIDs 0–17). CardTypeIDs 18–31 are not in the DWH.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (Dictionary.CardType) |
| Tier 2 | Derived from ETL code or SP logic |
| Tier 3 | Inferred with explicit reasoning |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CardTypeID | int | YES | Card network identifier. Active brands: 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. Inactive: 0=None, 4=Amex, 5=FirePay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Local Card, 14=China UnionPay, 15=Solo, 16=Cirrus, 17=GE Capital. (Tier 1 — Dictionary.CardType) |
| 2 | CarTypeName | varchar(50) | YES | Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. (Tier 1 — Dictionary.CardType) |
| 3 | IsActive | int | YES | Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. Type widened from bit to int in DWH. Only 4 of 32 are currently active in production. DWH note: DWH snapshot values may differ from current production state. (Tier 1 — Dictionary.CardType) |
| 4 | UpdateDate | datetime | YES | ETL metadata timestamp recording when the row was loaded into the DWH. All 18 rows show 2019-06-30 00:22:57, indicating a single bulk migration load. (Tier 2 — DWH_Migration load) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CardTypeID | Dictionary.CardType | CardTypeID | Passthrough |
| CarTypeName | Dictionary.CardType | Name | Rename (Name → CarTypeName) |
| IsActive | Dictionary.CardType | IsActive | Passthrough, type widened (bit → int) |
| UpdateDate | — | — | ETL-added (getdate() at migration load) |

### 5.2 ETL Pipeline

```
etoro.Dictionary.CardType (production, 32 rows)
  |-- One-time migration (2019-06-30) ---|
  v
DWH_Migration.Dim_CardType (staging, ROUND_ROBIN)
  |-- INSERT INTO ... SELECT ---|
  v
DWH_dbo.Dim_CardType (18 rows, REPLICATE)
  |-- Generic Pipeline (Override, daily, parquet) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype (UC Gold)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DWH_dbo.Dim_CountryBin | CardTypeID | Implicit FK | BIN-to-country records reference card brand |
| BI_DB_dbo.SP_DepositWithdrawFee | CardTypeID | SP JOIN | Deposit/withdrawal fee calculations by card type |
| BI_DB_dbo.SP_H_Deposits | CardTypeID | SP JOIN | Historical deposit reporting by card brand |
| BI_DB_dbo.SP_AllDeposits | CardTypeID | SP JOIN | All-deposits aggregation by card type |
| BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts | CardTypeID | SP JOIN | Audit deposit/cashout reports |
| BI_DB_dbo.SP_EY_Audit_BO_Deposits_With_PIPs | CardTypeID | SP JOIN | Audit BO deposits with PIPs |
| BI_DB_dbo.SP_Deposit_Reversals_PIPs | CardTypeID | SP JOIN | Deposit reversal PIP calculations |
| BI_DB_dbo.SP_Withdraw_Rollback_PIPs | CardTypeID | SP JOIN | Withdrawal rollback PIP calculations |
| BI_DB_dbo.SP_Finance_Cashout_RollbackDetails | CardTypeID | SP JOIN | Finance cashout rollback details |

---

## 7. Sample Queries

### 7.1 List all active card types
```sql
SELECT CardTypeID, CarTypeName
FROM DWH_dbo.Dim_CardType
WHERE IsActive = 1
ORDER BY CardTypeID;
```

### 7.2 Card type distribution in deposits
```sql
SELECT ct.CarTypeName AS CardBrand,
       COUNT(*) AS DepositCount
FROM DWH_dbo.Fact_BillingDeposit d
JOIN DWH_dbo.Dim_CardType ct ON d.CardTypeID = ct.CardTypeID
GROUP BY ct.CarTypeName
ORDER BY DepositCount DESC;
```

### 7.3 Full card type reference
```sql
SELECT CardTypeID, CarTypeName, IsActive, UpdateDate
FROM DWH_dbo.Dim_CardType
ORDER BY CardTypeID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Tiers: 3 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 4/4, Logic: 9/10, Lineage: 9/10*
*Object: DWH_dbo.Dim_CardType | Type: Table | Production Source: Dictionary.CardType (etoro)*


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


### Upstream `DWH_dbo.Dim_ActionType` — synapse
- **Resolved as**: `DWH_dbo.Dim_ActionType`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ActionType.md`

# DWH_dbo.Dim_ActionType

> 45-row static dimension table enumerating all customer action types in the trading platform — covering position opens/closes, deposits, cashouts, bonuses, chargebacks, mirror operations, user engagement, and registration events. Each action type is grouped into a Category with a CategoryID. Loaded daily via Generic Pipeline (Override). Production source unknown (no writer SP, no upstream wiki).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP; loaded via Generic Pipeline from DWH_Migration staging |
| **Refresh** | Daily (1440 min), Override copy strategy |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ActionTypeID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override) |

---

## 1. Business Meaning

Dim_ActionType is a small, static lookup table (45 rows) that defines every type of customer action tracked by the platform's Fact_CustomerAction fact table and related objects. Action types range from trading operations (ManualPositionOpen=1, CopyPositionClose=5) to financial transactions (Deposit=7, Cashout=8, Bonus=9) to social/engagement events (Publish Post=21, Publish Comment=22) to administrative actions (Open CRM Case=31, Customer Registration=41).

Each action type carries a Category (human-readable grouping, 30 distinct values) and CategoryID (integer grouping, 29 distinct values). The Category groups related actions — e.g., ActionTypeIDs 1-3 and 39 all map to Category="PositionOpen" (CategoryID=18), while ActionTypeIDs 4-6, 28, and 40 map to "PositionClose" (CategoryID=17).

Row 0 is the sentinel/unknown row (Name="N/A", Category="N/A", CategoryID=0). ActionTypeID 33 is absent (gap in the sequence).

The table has no writer SP — it is loaded via the Generic Pipeline from a DWH_Migration staging table. Timestamps (UpdateDate, InsertDate) suggest the original data was seeded in July 2013 with row 0 added in February 2014. The table is essentially static; new action types are added rarely.

---

## 2. Business Logic

### 2.1 Action Type Categorization

**What**: Each action type belongs to exactly one category, identified by both a string name (Category) and an integer ID (CategoryID).
**Columns Involved**: ActionTypeID, Name, Category, CategoryID
**Rules**:
- Multiple ActionTypeIDs can share the same Category/CategoryID (e.g., 5 action types map to PositionClose)
- CategoryID values are not sequential — they range from 0 to 28 with gaps
- The N/A sentinel (ActionTypeID=0) has Category="N/A" and CategoryID=0

### 2.2 Trading Action Groups

**What**: Position lifecycle actions are grouped into PositionOpen (CategoryID=18) and PositionClose (CategoryID=17).
**Columns Involved**: ActionTypeID, Category, CategoryID
**Rules**:
- PositionOpen includes Manual (1), Copy (2), CopyPlus (3), and Unknown (39)
- PositionClose includes Manual (4), Copy (5), CopyPlus (6), Detached (28), and Unknown (40)
- These categories are used by SP_Validation_Cycle_Gap_DL_To_Synapse for financial reconciliation (CategoryID=17 triggers NetProfit logic)

### 2.3 Financial Action Groups

**What**: Monetary actions are categorized for cashflow tracking.
**Columns Involved**: ActionTypeID, Category, CategoryID
**Rules**:
- Deposit actions: Deposit (7), Affiliate Deposit (38), InternalDeposit (44) — all CategoryID=8
- Cashout actions: Cashout (8) uses CategoryID=4; Cashout request (10) uses CategoryID=5; Processed Cashout (30) uses CategoryID=19
- InternalWithdraw (45) uses Category="Withdraw" with CategoryID=4 (same as Cashout)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution — the entire 45-row table is copied to every compute node. Ideal for a small dimension used in frequent JOINs. CLUSTERED INDEX on ActionTypeID provides fast point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What category does an action type belong to? | `SELECT * FROM DWH_dbo.Dim_ActionType WHERE ActionTypeID = @id` |
| List all position-open action types | `SELECT * FROM DWH_dbo.Dim_ActionType WHERE Category = 'PositionOpen'` |
| Get all action types in a category group | `SELECT * FROM DWH_dbo.Dim_ActionType WHERE CategoryID = @catId` |
| Full lookup dump | `SELECT * FROM DWH_dbo.Dim_ActionType ORDER BY ActionTypeID` (only 45 rows) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_CustomerAction | `fca.ActionTypeID = dat.ActionTypeID` | Resolve action type name/category for customer action records |
| DWH_dbo.Fact_FirstCustomerAction | `ffca.ActionTypeID = dat.ActionTypeID` | Resolve action type for first-action-per-customer records |
| DWH_dbo.Fact_History_Cost | `fhc.ActionTypeID = dat.ActionTypeID` | Resolve action type for historical cost entries |

### 3.4 Gotchas

- **ActionTypeID=0 is sentinel**: Name="N/A", Category="N/A" — filter or handle explicitly in reports
- **ActionTypeID=33 is missing**: The sequence 0-45 has a gap at 33 — do not assume contiguous IDs
- **Category vs CategoryID is not 1:1**: 30 distinct Category strings map to 29 distinct CategoryIDs — Cashout (8) and InternalWithdraw (45) share CategoryID=4 but have different Category strings ("Cashout" vs "Withdraw")
- **Double spaces in some Name values**: "Unregister  mirror", "Publish  Post", etc. contain double spaces — be careful with string matching
- **Typos in data**: "Recived" (sic) instead of "Received" in WallEngagement entries (IDs 24-26)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP/ETL code |
| Tier 3 | Grounded in DDL + live data, no upstream wiki or SP code available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ActionTypeID | smallint | YES | Primary key identifying a specific customer action type. Integer codes 0-45 (gap at 33) where 0=N/A sentinel. Used as FK in Fact_CustomerAction, Fact_FirstCustomerAction, Fact_History_Cost, and numerous BI_DB/EXW/eMoney reporting SPs. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 2 | Name | varchar(100) | YES | Human-readable name of the action type. Values include ManualPositionOpen, CopyPositionClose, Deposit, Cashout, Bonus, Chargeback, LoggedIn, Customer Registration, etc. (45 distinct values). (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 3 | UpdateDate | datetime | YES | Timestamp of the last update to this action type row. Most rows show 2013-07-17 (original seed); row 0 shows 2014-02-24. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 4 | InsertDate | datetime | YES | Timestamp when this action type row was first inserted. Same pattern as UpdateDate — bulk seeded 2013-07-17, sentinel added 2014-02-24. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 5 | Category | varchar(50) | YES | Category grouping for the action type. 30 distinct values: PositionOpen, PositionClose, Deposit, Cashout, Bonus, Chargeback, UserEngagement, WallEngagement, DetachPosition, etc. Multiple ActionTypeIDs can share one Category. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| 6 | CategoryID | int | YES | Integer identifier for the Category grouping. 29 distinct values (0-28). Used by SP_Validation_Cycle_Gap_DL_To_Synapse for financial reconciliation filtering (e.g., CategoryID=17 triggers NetProfit logic, CategoryID=4 triggers negative Amount). Not a FK to another dimension — self-contained within this table. (Tier 3 — no upstream wiki, grounded in DDL + live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| ActionTypeID | Unknown (external) | — | Direct load via Generic Pipeline |
| Name | Unknown (external) | — | Direct load via Generic Pipeline |
| UpdateDate | Unknown (external) | — | Direct load via Generic Pipeline |
| InsertDate | Unknown (external) | — | Direct load via Generic Pipeline |
| Category | Unknown (external) | — | Direct load via Generic Pipeline |
| CategoryID | Unknown (external) | — | Direct load via Generic Pipeline |

### 5.2 ETL Pipeline

```
Unknown production source (trading platform lookup table)
  |-- Generic Pipeline (Bronze export, parquet) ---|
  v
DWH_Migration.Dim_ActionType (staging, varchar types, ROUND_ROBIN)
  |-- Generic Pipeline (type cast + Override load) ---|
  v
DWH_dbo.Dim_ActionType (45 rows, REPLICATE)
  |-- Generic Pipeline (Override, delta, daily) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None — Dim_ActionType is a root dimension with no outgoing FKs.

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ActionTypeID | DWH_dbo.Fact_CustomerAction | FK lookup for action type on customer action records |
| ActionTypeID | DWH_dbo.Fact_FirstCustomerAction | FK lookup for first customer action |
| ActionTypeID | DWH_dbo.Fact_History_Cost | FK lookup for historical cost action type |
| CategoryID | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse | Used for financial reconciliation category filtering |
| ActionTypeID | BI_DB_dbo.SP_DDR_Fact_Revenue_Generating_Actions | Revenue action classification |
| ActionTypeID | BI_DB_dbo.SP_DDR_Fact_Non_Revenue_Generating_Actions | Non-revenue action classification |
| ActionTypeID | BI_DB_dbo.SP_Client_Balance_New | Client balance computation |
| ActionTypeID | EXW_dbo.SP_EXW_C2F_E2E | Customer-to-fund end-to-end reporting |

---

## 7. Sample Queries

### 7.1 List All Action Types with Categories

```sql
SELECT ActionTypeID, Name, Category, CategoryID
FROM DWH_dbo.Dim_ActionType
ORDER BY ActionTypeID;
```

### 7.2 Find All Position-Related Action Types

```sql
SELECT ActionTypeID, Name, Category
FROM DWH_dbo.Dim_ActionType
WHERE Category IN ('PositionOpen', 'PositionClose')
ORDER BY Category, ActionTypeID;
```

### 7.3 Count Customer Actions by Category

```sql
SELECT dat.Category, dat.CategoryID, COUNT(*) AS action_count
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_ActionType dat ON fca.ActionTypeID = dat.ActionTypeID
WHERE fca.DateID >= 20260101
GROUP BY dat.Category, dat.CategoryID
ORDER BY action_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (regen harness mode — Jira scan skipped).

---

*Generated: 2026-04-28 | Quality: 7.5/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 6 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 7/10, Lineage: 6/10*
*Object: DWH_dbo.Dim_ActionType | Type: Table | Production Source: Unknown (dormant/external)*


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


### Upstream `DWH_dbo.Dim_Customer` — synapse
- **Resolved as**: `DWH_dbo.Dim_Customer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`

﻿# DWH_dbo.Dim_Customer

> Master customer dimension table for the DWH; consolidates identity, demographics, compliance status, acquisition tracking, and external integrations from 14+ staging sources into a single slowly-changing Type 1 dimension with explicit change detection, PII masking, and multi-phase post-load enrichment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | RealCID (PK NOT ENFORCED, CLUSTERED INDEX, HASH distribution key) |
| **Distribution** | HASH(RealCID) |
| **Index** | CLUSTERED INDEX (RealCID ASC); PK NONCLUSTERED NOT ENFORCED |
| **Column Count** | 107 |
| **PII Masking** | 14 columns with Dynamic Data Masking |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Tables** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (masked), `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer` (unmasked PII) |
| **UC Copy Strategy** | Override |
| **Refresh** | Daily (1440 min) |
| **ETL Pattern** | CDC-style: change detection → DELETE/INSERT → multi-phase UPDATE enrichment |

---

## 1. Business Meaning

`Dim_Customer` is the DWH's central customer master table — the single point of reference for all customer attributes in analytics and reporting. It consolidates data from 14+ production staging tables spanning multiple microservices (Customer, BackOffice, Billing, Compliance, STS Audit, UserAPI, SalesForce, ContactVerification) into one denormalized row per customer.

The table follows a Type 1 SCD (Slowly Changing Dimension) pattern: each daily ETL run detects changes across 50+ columns and performs a DELETE/INSERT for modified customers, preserving certain indicator fields (deposit history, avatar, document proofs, Tangany/DLT/EquiLend IDs) that are maintained independently of the core change cycle.

Two UC copies exist:
- **Masked**: `main.dwh.gold_...dim_customer_masked` — PII columns contain masked values, accessible to general analytics
- **Unmasked**: `main.pii_data.gold_...dim_customer` — full PII, restricted access

### Business Usage

- **Regulatory Reporting**: Confluence "Business & Regulatory Undertakings Monitoring Platform" JOINs `Dim_Customer` on CID=RealCID for country, regulation, and status filtering
- **BI Queries**: Nearly every DWH fact table JOINs to Dim_Customer (via CID=RealCID) for customer segmentation
- **Synapse Training**: Confluence "Temporary Tables in Synapse" uses Dim_Customer as a reference example for HASH distribution optimization

---

## 5. Lineage

### 2.1 Staging Sources (14+ tables)

| Staging Table | Production Source | Role |
|--------------|-------------------|------|
| `DWH_staging.etoro_Customer_Customer` | Customer.CustomerStatic | Core customer profile (identity, demographics, registration) |
| `DWH_staging.etoro_BackOffice_Customer` | BackOffice.Customer | Compliance/admin attributes (verification, risk, regulation, guru status) |
| `DWH_staging.etoro_History_Customer` | History.Customer | Latest version for change detection (SCD) |
| `DWH_staging.etoro_History_BackOfficeCustomer` | History.BackOfficeCustomer | Latest version for BO attribute change detection |
| `DWH_staging.STS_Audit_UserOperationsData` | STS_Audit.UserOperationsData | 2FA enable/disable tracking |
| `DWH_staging.ContactVerification_Phone_Customer` | ContactVerification.Phone.Customer | Phone number, verification status |
| `DWH_staging.UserApiDB_Customer_Avatars` | UserApiDB.Customer.Avatars | Avatar upload tracking |
| `DWH_staging.etoro_Billing_vDeposit` | Billing.vDeposit | Legacy FTD source (replaced by below) |
| `DWH_staging.CustomerFinanceDB_Customer_FirstTimeDeposits` | CustomerFinanceDB.Customer.FirstTimeDeposits | FTD date, amount, platform, recovery date |
| `DWH_staging.ScreeningService_Screening_UserScreening` | ScreeningService.Screening.UserScreening | Screening/compliance status |
| `DWH_staging.SalesForce_DB_Prod_dbo_IdMapTopology` | SalesForce_DB_Prod.dbo.IdMapTopology | SalesForce account ID mapping |
| `DWH_staging.etoro_BackOffice_CustomerDocument` + `etoro_BackOffice_CustomerDocumentToDocumentType` | BackOffice.CustomerDocument | Address proof & ID proof status |
| `DWH_staging.etoro_Customer_CustomerStatic` | Customer.CustomerStatic | ApexID only |
| `DWH_staging.UserApiDB_Customer_CustomerIdentification` | UserApiDB.Customer.CustomerIdentification | GCID, DemoCID, TanganyID, DltID |
| `DWH_staging.ComplianceStateDB_Compliance_StocksLending` | ComplianceStateDB.Compliance.StocksLending | EquiLendID, StocksLendingStatusID |
| `DWH_dbo.Ext_Dim_SubChannel_UnifyCode` | (DWH internal) | SubChannelID via AffiliateID mapping |

### 2.2 ETL Pipeline (SP_Dim_Customer_DL_To_Synapse → SP_Dim_Customer)

```
ORCHESTRATOR (SP_Dim_Customer_DL_To_Synapse):
  1. Load 14 staging/external tables:
     Ext_Dim_Customer_Affiliate, Ext_Dim_Customer_BOCustomer, Ext_Dim_Customer_2FA,
     Ext_Dim_Customer_PhoneCustomer, Ext_Dim_Customer_Customer, Ext_Dim_Customer_Avatars,
     Ext_etoro_Billing_vDeposit, Ext_CustomerFinanceDB_Customer_FirstTimeDeposits,
     Ext_Dim_Customer_ScreeningStatusID, Ext_Dim_Customer_SF_ID, Ext_Dim_Customer_Document,
     Ext_Dim_CustomerStatic, Ext_Dim_Customer_CustomerIdentification, Ext_Dim_Customer_StocksLending
  2. EXEC SP_Dim_Customer

CORE LOGIC (SP_Dim_Customer):
  Step 1: Build #customer — JOIN Ext_Customer_Customer + Ext_BOCustomer
          Compute: IsValidCustomer, IsCreditReportValidCB
          Rename: SerialID→AffiliateID, ManagerID→AccountManagerID, isEmployeeAccount→EmployeeAccount
  Step 2: Detect #new (CIDs not yet in Dim_Customer)
  Step 3: Detect #update (50+ column comparison using ISNULL + COLLATE)
  Step 4: Build #full_list (new OR updated CIDs) with 2FA from Ext_2FA
  Step 5: Preserve #CustomerInitalIndicaton (deposit, avatar, document, Tangany, DLT, phone, FTD fields)
  Step 6: BEGIN TRAN: DELETE matching CIDs → INSERT with preserved indicators
  Step 7: Post-transaction UPDATEs:
          Avatar → HasAvatar, AvatarUploadDate
          Deposit → IsDepositor, FirstDepositDate, FirstDepositAmount, FTD fields
          ScreeningStatusID → from screening service
          SalesForceAccountID → from SF ID map
          Document proofs → IsAddressProof, IsIDProof + expiry dates
          2FA → from audit log
          SubChannelID → from affiliate mapping
          ApexID → from CustomerStatic
          Phone → PhoneNumber, IsPhoneVerified, PhoneVerificationDate
          Tangany → TanganyID, TanganyStatusID
          DLT → DltID, DltStatusID
          StocksLending → EquiLendID, StocksLendingStatusID
  Step 8: Populate Ext_Dim_Customer_ExternalID_GCID, update UserName_Lower
```

### 2.3 Key Column Renames

| DWH Column | Source Column | Source Table | Why |
|-----------|-------------|-------------|-----|
| RealCID | CID | etoro_Customer_Customer | Disambiguate from other CID uses in DWH |
| AffiliateID | SerialID | etoro_Customer_Customer | Business-friendly name |
| AccountManagerID | ManagerID | etoro_BackOffice_Customer | Disambiguate from other ManagerID columns |
| EmployeeAccount | isEmployeeAccount | etoro_BackOffice_Customer | Normalize casing |
| RegisteredReal | Registered | etoro_Customer_Customer | Clarify real-account registration |

### 2.4 DWH-Computed Columns

| Column | Computation |
|--------|------------|
| IsValidCustomer | `1` when PlayerLevelID≠4 AND LabelID NOT IN (30,26) AND CountryID≠250; else `0` |
| IsCreditReportValidCB | Similar to IsValidCustomer but also excludes PlayerLevelID=4 when AccountTypeID≠2, and has specific CID exceptions for CountryID=250 |
| UpdateDate | `GETDATE()` — ETL timestamp |
| UserName_Lower | `LOWER(UserName)` — set in final UPDATE |

---

## 4. Elements

### 3.1 Customer Identity

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 1 | RealCID | int | NO | No | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | No | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | DemoCID | int | YES | No | Demo account CID associated with this customer. From `UserApiDB_Customer_CustomerIdentification`. (Tier 2 — SP_Dim_Customer) |
| 4 | OriginalCID | int | YES | No | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 5 | ID | uniqueidentifier | NO | No | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — Customer.CustomerStatic) |
| 6 | ExternalID | decimal(38,0) | YES | No | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. (Tier 1 — Customer.CustomerStatic) |

### 3.2 Personal Information (PII — Masked)

| # | Column | Type | Nullable | Masked | Description |
|---|--------|------|----------|--------|-------------|
| 7 | UserName | varchar(20) | YES | Yes | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 8 | UserName_Lower | varchar(20) | YES | Yes | Lowercase version of UserName. Set by final UPDATE in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 9 | FirstName | nvarchar(50) | YES | Yes | Legal first name in Unicode. nvarchar supports non-Latin scripts (Cyrillic, Arabic, etc.). Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 10 | LastName | nvarchar(50) | YES | Yes | Legal last name in Unicode. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 11 | MiddleName | nvarchar(50) | YES | Yes | Middle name in Unicode. Added 2018. Included in CustomerVersionUpdate history tracking. (Tier 1 — Customer.CustomerStatic) |
| 12 | Gender | char(1) | YES | Yes | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 13 | BirthDate | datetime | YES | Yes | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 — Customer.CustomerStatic) |
| 14 | Email | varchar(50) | YES | Yes | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic) |
| 15 | Phone | varchar(30) | YES | Yes | Phone number from production Customer.CustomerStatic. (Tier 1 — Customer.CustomerStatic) |
| 16 | IP | varchar(15) | YES | Yes | Registration IP address. (Tier 1 — Customer.CustomerStatic) |
| 17 | Zip | nvarchar(50) | YES | Yes | Postal code. Used in LinkedAccountHash1. (Tier 1 — Customer.CustomerStatic) |
| 18 | City | nvarchar(50) | YES | Yes | City in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 19 | Address | nvarchar(100) | YES | Yes | Street address in Unicode. (Tier 1 — Customer.CustomerStatic) |
| 20 | BuildingNumber | nvarchar(30) | YES | Yes | Building/apartment number. Separate from Address for structured address storage. (Tier 1 — Customer.CustomerStatic) |

### 3.3 Acquisition & Marketing

| # | Column | Type | Description |
|---|--------|------|-------------|
| 21 | AffiliateID | int | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 22 | CampaignID | int | Marketing campaign ID under which the customer was acquired. FK to BackOffice.Campaign. NULL for organically acquired customers. (Tier 1 — Customer.CustomerStatic) |
| 23 | SubChannelID | int | Sub-channel ID. Populated post-load from SubChannel unify code via AffiliateID mapping. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 24 | LabelID | int | Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. (Tier 1 — Customer.CustomerStatic) |
| 25 | BannerID | int | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 26 | FunnelID | int | Registration funnel ID. FK to Dictionary.Funnel. Tracks which user journey/funnel variant the customer came through. NULL when not tracked. (Tier 1 — Customer.CustomerStatic) |
| 27 | FunnelFromID | int | Source funnel variant ID tracking where the customer came from within the acquisition funnel. (Tier 1 — Customer.CustomerStatic) |
| 28 | DownloadID | int | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 — Customer.CustomerStatic) |
| 29 | ReferralID | int | Referral CID - the customer who referred this customer (for RAF program tracking). (Tier 1 — Customer.CustomerStatic) |
| 30 | SubSerialID | varchar(1024) | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. (Tier 1 — Customer.CustomerStatic) |

### 3.4 Registration & Account Lifecycle

| # | Column | Type | Description |
|---|--------|------|-------------|
| 31 | RegisteredReal | datetime | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 32 | RegisteredDemo | datetime | Demo account registration date. Source unclear — may be populated separately. (Tier 2 — SP_Dim_Customer) |
| 33 | AccountExpirationDate | datetime | Expiration date for demo or time-limited accounts. NULL for standard real-money accounts. (Tier 1 — Customer.CustomerStatic) |
| 34 | AccountStatusID | int | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 — Customer.CustomerStatic) |
| 35 | PlayerStatusID | int | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 36 | PlayerStatusReasonID | int | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. (Tier 1 — Customer.CustomerStatic) |
| 37 | PlayerStatusSubReasonID | int | Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). (Tier 1 — Customer.CustomerStatic) |
| 38 | PendingClosureStatusID | tinyint | Status in the pending closure workflow. Default=1 (no pending closure). Updated when customer requests account closure. (Tier 1 — Customer.CustomerStatic) |
| 39 | PlayerLevelID | int | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard (94%); 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 40 | AccountTypeID | int | Customer account classification. Default=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K. (Tier 1 — BackOffice.Customer) |
| 41 | IsDepositor | bit | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. (Tier 2 — SP_Dim_Customer) |
| 42 | FirstDepositDate | datetime | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 43 | FirstDepositAmount | money | Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer) |

### 3.5 Compliance & Regulation

| # | Column | Type | Description |
|---|--------|------|-------------|
| 44 | RegulationID | tinyint | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 45 | DesignatedRegulationID | int | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 — BackOffice.Customer) |
| 46 | RegulationChangeDate | datetime | Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger. NULL if never changed since creation. (Tier 1 — BackOffice.Customer) |
| 47 | CountryID | int | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 48 | CountryIDByIP | int | Country detected from the customer IP address at registration. Used for fraud detection and geo-comparison (CountryID vs CountryIDByIP mismatch flagging). (Tier 1 — Customer.CustomerStatic) |
| 49 | CitizenshipCountryID | int | Country of citizenship (may differ from CountryID/residence). FK to Dictionary.Country. Added 2018 for enhanced KYC. (Tier 1 — Customer.CustomerStatic) |
| 50 | POBCountryID | int | Place of birth country. FK to Dictionary.Country. Added for KYC (HLD: RD-4436). (Tier 1 — Customer.CustomerStatic) |
| 51 | RegionID | int | Geographic region ID (GeoIP-derived or set). Used alongside CountryID for more granular regional regulation. (Tier 1 — Customer.CustomerStatic) |
| 52 | RegionByIP_ID | int | Region detected from IP address. Separate from RegionID (profile-based) to allow mismatch detection. (Tier 1 — Customer.CustomerStatic) |
| 53 | VerificationLevelID | int | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0. (Tier 1 — BackOffice.Customer) |
| 54 | DocsOK | tinyint | Whether required documents are verified. (Tier 2 — SP_Dim_Customer) |
| 55 | DocumentStatusID | int | Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 — BackOffice.Customer) |
| 56 | IsAddressProof | int | Whether address proof document is on file (1/0). Updated from BackOffice.CustomerDocument. (Tier 2 — SP_Dim_Customer) |
| 57 | IsAddressProofExpiryDate | datetime | Expiry date of address proof document. (Tier 2 — SP_Dim_Customer) |
| 58 | IsIDProof | int | Whether ID proof document is on file (1/0). (Tier 2 — SP_Dim_Customer) |
| 59 | IsIDProofExpiryDate | datetime | Expiry date of ID proof document. (Tier 2 — SP_Dim_Customer) |
| 60 | SuitabilityTestStatusID | int | MiFID II appropriateness/suitability test result. NULL if test not completed. (Tier 1 — BackOffice.Customer) |
| 61 | MifidCategorizationID | int | MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1. (Tier 1 — BackOffice.Customer) |
| 62 | ScreeningStatusID | int | Compliance screening status. Updated from ScreeningService. (Tier 2 — SP_Dim_Customer) |
| 63 | WorldCheckID | int | Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 — BackOffice.Customer) |
| 64 | WorldCheckResultsUpdated | datetime | When World-Check results were last updated. Preserved from previous row. (Tier 2 — SP_Dim_Customer) |
| 65 | IsEDD | bit | Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. Default=0. (Tier 1 — BackOffice.Customer) |
| 66 | Bankruptcy | tinyint | Bankruptcy flag. (Tier 2 — SP_Dim_Customer) |
| 67 | IsValidCustomer | int | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) |
| 68 | IsCreditReportValidCB | int | DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. (Tier 2 — SP_Dim_Customer) |

### 3.6 Risk & Communication

| # | Column | Type | Description |
|---|--------|------|-------------|
| 69 | RiskStatusID | int | Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags). (Tier 1 — BackOffice.Customer) |
| 70 | RiskClassificationID | int | Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Tracked in UPDATE trigger audit. (Tier 1 — BackOffice.Customer) |
| 71 | EmployeeAccount | tinyint | 1 if this is an eToro employee personal trading account (renamed from isEmployeeAccount). Flags employee accounts for special monitoring and compliance checks. (Tier 1 — BackOffice.Customer) |
| 72 | LanguageID | int | Customer preferred platform language. FK to Dictionary.Language. Controls UI language. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 73 | CommunicationLanguageID | int | Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences. (Tier 1 — Customer.CustomerStatic) |
| 74 | IsEmailVerified | int | Whether the email address has been verified by clicking a confirmation link. NULL for older accounts predating this flag. (Tier 1 — Customer.CustomerStatic) |
| 75 | PrivacyPolicyID | int | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 — Customer.CustomerStatic) |
| 76 | IsCopyBlocked | bit | 1 if the customer is blocked from copy trading. 0 in all current rows - feature exists but currently unused/not enforced. (Tier 1 — BackOffice.Customer) |

### 3.7 Social & Trading Features

| # | Column | Type | Description |
|---|--------|------|-------------|
| 77 | GuruStatusID | smallint | eToro Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. (Tier 1 — BackOffice.Customer) |
| 78 | NumOfGurus | int | Number of Popular Investors this customer is copying. (Tier 2 — SP_Dim_Customer) |
| 79 | NumOfCopiers | int | Number of customers copying this customer's trades. (Tier 2 — SP_Dim_Customer) |
| 80 | NumOfRAF | int | Number of successful Refer-A-Friend referrals. (Tier 2 — SP_Dim_Customer) |
| 81 | SocialConnectID | int | Social media connection type. DEFAULT=0. (Tier 2 — SP_Dim_Customer) |
| 82 | PremiumAccount | tinyint | Whether this is a premium account. (Tier 2 — SP_Dim_Customer) |
| 83 | Evangelist | tinyint | Whether this customer is an evangelist/ambassador. (Tier 2 — SP_Dim_Customer) |
| 84 | HasAvatar | tinyint | Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). (Tier 2 — SP_Dim_Customer) |
| 85 | AvatarUploadDate | datetime | When the avatar was uploaded. (Tier 2 — SP_Dim_Customer) |
| 86 | EvMatchStatus | int | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — BackOffice.Customer) |

### 3.8 Account Management

| # | Column | Type | Description |
|---|--------|------|-------------|
| 87 | AccountManagerID | int | Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 — BackOffice.Customer) |
| 88 | UpdateDate | datetime | ETL load/update timestamp (GETDATE()). (Tier 2 — SP_Dim_Customer) |
| 89 | SalesForceAccountID | nvarchar(18) | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. (Tier 1 — BackOffice.Customer) |

### 3.9 Authentication & Phone Verification

| # | Column | Type | Description |
|---|--------|------|-------------|
| 90 | 2FA | int | Two-factor authentication status. 0=disabled, 1=enabled. Derived from `STS_Audit_UserOperationsData` login type events. Preserves previous value when no new 2FA event exists. (Tier 2 — SP_Dim_Customer) |
| 91 | PhoneVerifiedID | int | Result code of phone number verification process. NULL if not yet attempted. (Tier 1 — BackOffice.Customer) |
| 92 | PhoneNumber | varchar(30) | Verified phone number from ContactVerification service. Overrides `Phone` from Customer_Customer when available. (Tier 2 — SP_Dim_Customer) |
| 93 | IsPhoneVerified | bit | Whether phone is verified (VerificationStatusID IN (1,2) → 1). (Tier 2 — SP_Dim_Customer) |
| 94 | PhoneVerificationDate | smalldatetime | Date phone was verified. '1900-01-01' if not verified. (Tier 2 — SP_Dim_Customer) |

### 3.10 External Integrations

| # | Column | Type | Description |
|---|--------|------|-------------|
| 95 | ApexID | varchar(8) | APEX US stocks broker account ID. Only populated for US-regulated customers at Level >= 2 who have APEX accounts. (Tier 1 — Customer.CustomerStatic) |
| 96 | TanganyID | nvarchar(max) | Tangany crypto custody integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 97 | TanganyStatusID | tinyint | Tangany integration status. (Tier 2 — SP_Dim_Customer) |
| 98 | EquiLendID | nvarchar(max) | EquiLend securities lending integration ID. Updated from StocksLending. (Tier 2 — SP_Dim_Customer) |
| 99 | StocksLendingStatusID | int | Stocks lending consent status. (Tier 2 — SP_Dim_Customer) |
| 100 | DltID | nvarchar(max) | Distributed Ledger Technology integration ID. Updated from CustomerIdentification. (Tier 2 — SP_Dim_Customer) |
| 101 | DltStatusID | int | DLT integration status. (Tier 2 — SP_Dim_Customer) |
| 102 | HasWallet | int | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) |

### 3.11 FTD (First Time Deposit) Tracking

| # | Column | Type | Description |
|---|--------|------|-------------|
| 103 | FTDPlatformID | nvarchar(4000) | Platform/account type of the first deposit (AccountTypeId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 104 | FTDTransactionID | nvarchar(4000) | Transaction ID of the first deposit (TransactionId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |
| 105 | FTDRecoveryDate | datetime2(7) | Recovery date for the FTD (Updated field from source). If FTDRecoveryDate is later than original FirstDepositDate, FirstDepositDate is updated to FTDRecoveryDate. Added 2025-09-12. (Tier 2 — SP_Dim_Customer) |

### 3.12 Miscellaneous

| # | Column | Type | Description |
|---|--------|------|-------------|
| 106 | CashoutFeeGroupID | int | Determines which withdrawal fee schedule applies to this customer. FK to Dictionary.CashoutFeeGroup. NULL = default fee group. (Tier 1 — BackOffice.Customer) |
| 107 | WeekendFeePrecentage | int | Weekend swap fee percentage. Default=100 (full fee). Values below 100 indicate discounted weekend fees for select customers. Note: column name has typo Precentage. (Tier 1 — Customer.CustomerStatic) |

---

## 2. Business Logic

### 4.1 Change Detection (CDC-Style)

The SP compares 50+ columns between `#customer` (staging) and existing `Dim_Customer` using `ISNULL(old,0) <> ISNULL(new,0)` with explicit `COLLATE Latin1_General_100_BIN` for string columns. Only customers with actual changes (or new customers) are processed. This prevents unnecessary row churn.

### 4.2 Indicator Preservation

When a customer row is updated (DELETE+INSERT), certain indicator fields are preserved from the old row via `#CustomerInitalIndicaton`: FirstDepositAmount, FirstDepositDate, HasAvatar, IsDepositor, ScreeningStatusID, SalesForceAccountID, document proofs, WorldCheckID, Tangany, Phone, EquiLend, DLT, FTD fields. These are then refreshed in subsequent post-load UPDATEs if new data is available.

### 4.3 Multi-Source Identity Resolution

Customer attributes come from multiple microservices. The ETL uses `ISNULL(history_version, current_value)` patterns to prefer the latest History version (with temporal filtering: ValidFrom < @CurrentDate, ValidFrom >= @DelayDate, ValidTo >= @CurrentDate) over the current snapshot, ensuring the most up-to-date attribute values are captured.

### 4.4 FTD Recovery Date Logic

The `FirstDepositDate` is updated using: if the existing `FirstDepositDate` (as date) is earlier than `FTDRecoveryDate`, use `FTDRecoveryDate`; otherwise use the `FTDDate`. This handles cases where an FTD was reversed and re-deposited on a different day.

### 4.5 IsValidCustomer Business Rule

```
IsValidCustomer = 1 WHEN:
  PlayerLevelID ≠ 4 (not Popular Investor)
  AND LabelID NOT IN (30, 26) (not bonus-only or specific label)
  AND CountryID ≠ 250
```

This excludes demo-like, internal, and specific-jurisdiction accounts from standard reporting.

---

## 6. Relationships

### 5.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CountryID / CountryIDByIP / CitizenshipCountryID / POBCountryID | Dim_Country | CountryID = CountryID |
| AffiliateID | Dim_Affiliate | AffiliateID = AffiliateID |
| CampaignID | Dim_Campaign | CampaignID = CampaignID |
| AccountTypeID | Dim_AccountType | AccountTypeID = AccountTypeID |
| AccountStatusID | Dim_AccountStatus | AccountStatusID = AccountStatusID |
| PlayerLevelID | (Dictionary.PlayerLevel — no DWH dim) | — |
| GuruStatusID | Dim_GuruStatus | GuruStatusID = GuruStatusID |
| FunnelID | Dim_Funnel | FunnelID = FunnelID |
| DocumentStatusID | Dim_DocumentStatus | DocumentStatusID = DocumentStatusID |
| EvMatchStatus | Dim_EvMatchStatus | EvMatchStatus = EvMatchStatus |
| CashoutFeeGroupID | Dim_CashoutFeeGroup | CashoutFeeGroupID = CashoutFeeGroupID |

### 5.2 Fact Table Relationships

Nearly every DWH fact table JOINs to Dim_Customer:
- `Fact_BillingWithdraw.CID = Dim_Customer.RealCID`
- `Fact_CustomerUnrealized_PnL.CID = Dim_Customer.RealCID`
- `Fact_SnapshotCustomer.RealCID = Dim_Customer.RealCID`
- `Fact_CustomerAction.CID = Dim_Customer.RealCID`
- `Dim_Position.CID = Dim_Customer.RealCID`

### 5.3 Source Chain

```
Production Microservices                    DWH Staging                         Synapse DWH
──────────────────────                    ──────────                         ───────────
Customer.CustomerStatic          →  etoro_Customer_Customer            ─┐
BackOffice.Customer              →  etoro_BackOffice_Customer          ─┤
History.Customer                 →  etoro_History_Customer             ─┤
History.BackOfficeCustomer       →  etoro_History_BackOfficeCustomer   ─┤  

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Currency` — synapse
- **Resolved as**: `DWH_dbo.Dim_Currency`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md`

# DWH_dbo.Dim_Currency

> Despite its name, this is the universal instrument registry (15.7K rows) for all tradeable assets on the eToro platform: stocks (13K), ETFs (1.1K), crypto (686), commodities (533), indices (203), and forex (174).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Currency |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full TRUNCATE+INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CurrencyID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Currency` is the **universal instrument registry** for the eToro DWH. Despite its misleading name (inherited from eToro's origins as a forex-only platform), it contains every tradeable asset on the platform: 13,044 stocks, 1,094 ETFs, 686 crypto assets, 533 commodities, 203 indices, and 174 forex pairs - 15,734 rows total as of 2026-03-11.

`CurrencyID` is the platform-wide instrument identifier. It is referenced by virtually every fact table in the DWH: trade positions, deposits, credit events, and cost history all use CurrencyID to identify the instrument involved. Joining to Dim_Currency decodes CurrencyID into instrument name, asset class (CurrencyTypeID), and trading properties.

The ETL is a full TRUNCATE+INSERT daily reload from `DWH_staging.etoro_Dictionary_Currency`. All 9 source columns are passthroughs; only UpdateDate is ETL-computed. The DWH has more rows than the upstream wiki documents (15.7K vs 10.7K upstream) because the wiki was written earlier and the platform has added more instruments since.

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md` (quality 9+/10, VERIFIED confidence).

---

## 2. Business Logic

### 2.1 Instrument Classification by Asset Class

**What**: CurrencyTypeID classifies every instrument into one of 6 asset classes, determining trading rules, leverage limits, and settlement options.

**Columns Involved**: `CurrencyTypeID`

**DWH distribution (live 2026-03-11)**:
```
CurrencyTypeID=5 (Stocks):     13,044 rows (83%)
CurrencyTypeID=6 (ETF):         1,094 rows (7%)
CurrencyTypeID=10 (Crypto):       686 rows (4%)
CurrencyTypeID=2 (Commodity):     533 rows (3%)
CurrencyTypeID=4 (Indices):       203 rows (1%)
CurrencyTypeID=1 (Forex):         174 rows (1%)
```

**Rules**:
- Stocks (5): Individual company shares. Can trade as REAL (1x) or CFD.
- ETF (6): Exchange-traded funds. Similar rules to stocks.
- Crypto (10): Bitcoin, Ethereum, etc. ESMA max 2x retail leverage. Can be REAL at 1x.
- Commodity (2): Gold, Oil, Silver, etc. Always CFD. ESMA max 10x retail.
- Forex (1): Currency pairs. Always CFD. ESMA max 30x (majors) / 20x (minors).
- Indices (4): S&P 500, NASDAQ, etc. Always CFD. ESMA max 20x retail.

### 2.2 Bitmask System (Legacy Forex)

**What**: The Mask column encodes forex instrument identity as power-of-2 bitmasks for legacy system compatibility.

**Columns Involved**: `Mask`

**Rules**:
- USD=1 (2^0), EUR=2 (2^1), GBP=4 (2^2), JPY=8 (2^3), AUD=16 (2^4), CHF=32 (2^5), CAD=64 (2^6), NZD=128 (2^7)
- Only meaningful for the original 8 major forex currencies. Stocks, crypto, commodities have NULL or 0.
- Hard ceiling of 31 instruments (INT bitmask limit) - now exceeded, so not used for newer assets.

### 2.3 EEA Stock Exchange Compliance (MiFID II)

**What**: Flags instruments listed on European Economic Area exchanges requiring KID documents under PRIIPs regulation.

**Columns Involved**: `EEAStockExchange`

**Rules**:
- EEAStockExchange=1 for ~216 instruments on EU/EEA exchanges (London, Frankfurt, Paris, etc.)
- These require KID (Key Information Document) availability for retail EU clients
- Affects instrument availability for EU-regulated users

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE with 15.7K rows is appropriate. The CLUSTERED INDEX on CurrencyID supports fast point lookups. At this row count, the table is small enough to broadcast to all nodes efficiently.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (15.7K rows). Z-ORDER BY CurrencyID optional.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode instrument ID in a fact | `JOIN DWH_dbo.Dim_Currency d ON f.CurrencyID = d.CurrencyID` |
| Filter stocks only | `WHERE CurrencyTypeID = 5` |
| Find a specific instrument by ticker | `WHERE Abbreviation = 'AAPL.US'` |
| List EEA instruments | `WHERE EEAStockExchange = 1` |
| Exclude CurrencyID=0 (placeholder) | `WHERE CurrencyID > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| All DWH fact tables | ON f.CurrencyID = d.CurrencyID | Decode instrument for any trade/position/cost fact |
| DWH_dbo.Dim_Country | ON c.DefaultCurrencyID = d.CurrencyID | Default account currency per country [UNVERIFIED - DefaultCurrencyID dropped from Dim_Country] |

### 3.4 Gotchas

- **Naming is misleading**: This is NOT just currencies. 83% of rows are stocks. Always filter by CurrencyTypeID when intent is asset-class-specific.
- CurrencyID=0 is a placeholder ("NULL instrument"). Exclude with `WHERE CurrencyID > 0` for business analytics.
- Mask is NULL/0 for all non-forex instruments. Do not use Mask for asset identification outside legacy forex systems.
- DWH has 15.7K rows; upstream production wiki shows 10.7K - the platform has added ~5K instruments since the wiki was written. Row count grows over time.
- Name is `varchar(50)` - many stock names are verbose (e.g., "United States of America, US Dollar"). Use Abbreviation for tickers.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyID | int | NO | Primary key. Universal instrument identifier. 0=NULL placeholder, 1-8=major forex currencies, ~1000+=stocks (AAPL, GOOG, etc.), ~100000+=crypto (BTC, ETH). Referenced by virtually all DWH fact tables. Legacy name: eToro originated as forex-only. (Tier 1 - Dictionary.Currency upstream wiki) |
| 2 | CurrencyTypeID | int | NO | FK to Dim_CurrencyType (if exists). Asset class: 1=Forex (174), 2=Commodity (533), 4=Indices (203), 5=Stocks (13,044), 6=ETF (1,094), 10=Crypto (686). Determines trading rules, leverage limits, and settlement eligibility. (Tier 1 - Dictionary.Currency upstream wiki) |
| 3 | Name | varchar(50) | NO | Full instrument name. Verbose for forex ("United States of America, US Dollar"), company name for stocks, coin name for crypto. (Tier 1 - Dictionary.Currency upstream wiki) |
| 4 | Abbreviation | varchar(20) | NO | Ticker symbol. "USD", "EUR" for forex; "AAPL.US", "TSLA.US" for US stocks (format: TICKER.EXCHANGE); "BTC" for crypto. Unique across all instruments. Use this for human-readable instrument identification. (Tier 1 - Dictionary.Currency upstream wiki) |
| 5 | Mask | int | YES | Legacy power-of-2 bitmask for original 8 major forex currencies (USD=1, EUR=2, GBP=4, JPY=8, AUD=16, CHF=32, CAD=64, NZD=128). NULL or 0 for all stocks, crypto, commodities, indices. Only used in legacy forex calculations. (Tier 1 - Dictionary.Currency upstream wiki) |
| 6 | EEAStockExchange | bit | NO | Whether this instrument is listed on a European Economic Area exchange, requiring KID documents under MiFID II PRIIPs regulation. 1=EEA-listed (~216 instruments), 0=not EEA-listed. Affects instrument availability for retail EU users. (Tier 1 - Dictionary.Currency upstream wiki) |
| 7 | ISINCode | varchar(25) | YES | International Securities Identification Number (12-char: 2-char country + 9-char ticker + check digit). Available for stocks and ETFs. NULL for forex, commodities, crypto, and indices. Used for regulatory reporting and cross-system integration. (Tier 1 - Dictionary.Currency upstream wiki) |
| 8 | CurrencySymbol | nchar(5) | YES | Display symbol for the instrument (e.g., "$" for USD, "€" for EUR, "£" for GBP, "₿" for BTC). NULL for most stocks and commodities. nchar type supports Unicode symbols. (Tier 2 - SP passthrough; live data confirms) |
| 9 | InterestRateID | int | YES | FK to an interest rate configuration for this instrument. Used for overnight financing rates on leveraged positions. NULL for most instruments. (Tier 2 - SP passthrough; live data confirms for major forex) |
| 10 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each daily full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CurrencyID | etoro.Dictionary.Currency | CurrencyID | passthrough |
| CurrencyTypeID | etoro.Dictionary.Currency | CurrencyTypeID | passthrough |
| Name | etoro.Dictionary.Currency | Name | passthrough |
| Abbreviation | etoro.Dictionary.Currency | Abbreviation | passthrough |
| Mask | etoro.Dictionary.Currency | Mask | passthrough |
| EEAStockExchange | etoro.Dictionary.Currency | EEAStockExchange | passthrough |
| ISINCode | etoro.Dictionary.Currency | ISINCode | passthrough |
| CurrencySymbol | etoro.Dictionary.Currency | CurrencySymbol | passthrough |
| InterestRateID | etoro.Dictionary.Currency | InterestRateID | passthrough |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.Currency
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_Currency (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_Currency (15.7K rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Currency | Master instrument registry. All 6 asset classes. Audit-triggered with History.AuditHistory in production. |
| Staging | DWH_staging.etoro_Dictionary_Currency | Raw staging. Same column structure. |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. All 9 columns passthrough. Injects GETDATE() for UpdateDate. |
| Target | DWH_dbo.Dim_Currency | Final DWH instrument dimension (15.7K rows) |

**Note**: The upstream production table has audit triggers (INSERT/UPDATE/DELETE -> History.AuditHistory). DWH does not replicate this audit trail.

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CurrencyTypeID | DWH_dbo.Dim_CurrencyType (if exists) | Asset class classification. Implicit FK. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| All DWH trading fact tables | CurrencyID | Virtually every trade, position, and cost fact references CurrencyID for instrument identification. |
| DWH_dbo.Dim_Country | MarketingRegionID via DefaultCurrencyID | Country default currency references CurrencyID in production (DefaultCurrencyID dropped from DWH Dim_Country). |

---

## 7. Sample Queries

### 7.1 Instruments by asset class
```sql
SELECT CurrencyTypeID, COUNT(*) AS InstrumentCount
FROM [DWH_dbo].[Dim_Currency]
WHERE CurrencyID > 0
GROUP BY CurrencyTypeID
ORDER BY InstrumentCount DESC;
```

### 7.2 Find an instrument by ticker
```sql
SELECT CurrencyID, Name, Abbreviation, CurrencyTypeID, ISINCode
FROM [DWH_dbo].[Dim_Currency]
WHERE Abbreviation = 'AAPL.US';
```

### 7.3 EEA-listed instruments
```sql
SELECT CurrencyID, Abbreviation, Name, ISINCode
FROM [DWH_dbo].[Dim_Currency]
WHERE EEAStockExchange = 1
ORDER BY Abbreviation;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.
Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md`.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (4 stars) | Phases: 9/14 (no Atlassian)*
*Tiers: 7 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.Dim_Currency | Type: Table | Production Source: etoro.Dictionary.Currency*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_EY_Audit_Deposit_Cashouts] @Date [DATE] AS

/**************************************Start Main Comment History******************************************************
Author:      Guy Manova
Date:        2023-06-09
Description:

**************************
** Change History
**************************
Date         Author       Description

2024-07-03		Guy M		added date auto completion code for missing dates
****************************************End Main Comment History****************************************************/

BEGIN
SET NOCOUNT ON;


--DECLARE @Date DATE=cast (getdate()-1 as date)
DECLARE @DateID INT =CAST(CONVERT(VARCHAR(10), @Date, 112) AS INT)

		----- check for missing previous dates and fill up -----

		DECLARE @TargetDateInt INT = CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT) --- !!!!! MAKE SURE CORRECT @VARIABLE NAME !!!!!
		DECLARE @MaxDateID INT;
		-- Get the maximum DateID from the table
		SELECT @MaxDateID = MAX(DateID) --- !!!!! MAKE SURE CORRECT Date Column !!!!!
		FROM BI_DB_dbo.BI_DB_EY_Audit_Deposits ; --- !!!!! MAKE SURE CORRECT Table !!!!!

		PRINT @MaxDateID

		-- Check if there are any missing dates
		IF @MaxDateID < @TargetDateInt
		BEGIN
		    DECLARE @StartDate DATE = CAST(CAST(@MaxDateID AS VARCHAR(8)) AS DATE);
		    DECLARE @EndDate DATE = DATEADD(DAY, -1, @Date); --- !!!!! MAKE SURE CORRECT @PARAMETER NAME !!!!!
		    DECLARE @DateToProcess DATE = DATEADD(DAY, 1, @StartDate);

		    WHILE @DateToProcess <= @EndDate
		    BEGIN
		        DECLARE @DateInt INT = CAST(FORMAT(@DateToProcess, 'yyyyMMdd') AS INT);
		        -- Run the stored procedure for the missing date
		        EXEC BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts @Date = @DateToProcess; ---- !!!!! MAKE SURE CORRECT SP is RUN with correct @VARIABLE !!!! !!!!!
				PRINT cast( @DateToProcess AS VARCHAR (20)) + ' Data Added'
		        SET @DateToProcess = DATEADD(DAY, 1, @DateToProcess);
		    END
		END

	ELSE

	BEGIN
	PRINT 'no missing dates'
	END

IF OBJECT_ID('tempdb..#mimo') IS NOT NULL DROP TABLE #mimo
CREATE TABLE #mimo
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT RealCID
,fca.DepositID
,fca.WithdrawID
,fca.WithdrawPaymentID
,fca.Occurred
,fca.DateID
,fca.FundingTypeID
,fca.ActionTypeID
,fca.Amount


FROM DWH_dbo.Fact_CustomerAction fca
WHERE fca.DateID=@DateID
 AND fca.ActionTypeID IN (7,8,11,12,13,37)
--AND fca.FundingTypeID <> 0 AND ISNULL(fca.Amount,0) <> 0



CREATE CLUSTERED INDEX #col1 ON #mimo (RealCID, DepositID, WithdrawID, ActionTypeID, DateID, FundingTypeID);


IF OBJECT_ID('tempdb..#pips') IS NOT NULL DROP TABLE #pips
CREATE TABLE #pips
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT DISTINCT bddwf.CID
,bddwf.DepositWithdrawID
,REPLACE(REPLACE(bddwf.TransactionID, 'D',''),'W','') AS TransactionID
,bddwf.TransactionType
,bddwf.ExchangeRate
,bddwf.BaseExchangeRate
,bddwf.ExchangeFee

FROM BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf
WHERE bddwf.DateID=@DateID
AND bddwf.TransactionType in ('Deposit', 'Withdraw');

CREATE CLUSTERED INDEX #col1 ON #pips (TransactionID, TransactionType);

---- deposits  ----

--- metadata ---
IF OBJECT_ID('tempdb..#meta') IS NOT NULL DROP TABLE #meta
CREATE TABLE #meta
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT
	fbd.CID
  , fbd.DepositID
  , dft.Name AS PaymentType
  , dbd.Name AS Depot
  , CASE WHEN fbd.BankNameAsString IS NULL THEN v ELSE fbd.BankNameAsString END AS BankName
  , fbd.CurrencyID
  , fbd.Amount AS CurrencyAmount
  , fbd.AmountUSD
  , fbd.ExchangeRate
  , dct.CarTypeName
  , fbd.PaymentStatusID
  , fbd.TransactionIDAsString
  , p.BaseExchangeRate
  , p.ExchangeFee
FROM DWH_dbo.Fact_BillingDeposit fbd
LEFT JOIN DWH_dbo.Dim_FundingType dft
	ON fbd.FundingTypeID = dft.FundingTypeID
LEFT JOIN DWH_dbo.Dim_BillingDepot dbd
	ON fbd.DepotID = dbd.DepotID
LEFT JOIN DWH_dbo.Dim_CardType dct
	ON fbd.CardTypeIDAsInteger = dct.CardTypeID
LEFT JOIN #pips p
	ON fbd.DepositID = p.DepositWithdrawID AND p.TransactionType = 'Deposit'
WHERE fbd.ModificationDateID=@DateID
--AND fbd.PaymentStatusID IN (2,4)
--AND fbd.FundingTypeID = 1

CREATE CLUSTERED INDEX #col1 ON #meta (DepositID);


IF OBJECT_ID('tempdb..#metaCO') IS NOT NULL DROP TABLE #metaCO
CREATE TABLE #metaCO
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT  DISTINCT fbw.CID
			, fbw.WithdrawID
			, fbw.CurrencyID
			, fbw.CashoutStatusID_Funding
			, fbw.Amount_WithdrawToFunding
			, fbw.ModificationDate_WithdrawToFunding
			, fbw.DepotID
			, fbw.FundingTypeID_Funding
			, fbw.CardTypeIDAsInteger
			, fbw.WithdrawPaymentID
			, CASE WHEN fbw.ClientBankNameAsString IS NULL THEN fbw.BankNameAsString ELSE fbw.ClientBankNameAsString END AS BankNameAsString
			, dbd.Name AS Depot
			, dft.Name AS PaymentMethod
			, dct.CarTypeName AS CardType
			, fbw.ExchangeRate
			, p.BaseExchangeRate
			, p.ExchangeFee
			, fbw.VerificationCode

FROM DWH_dbo.Fact_BillingWithdraw fbw
LEFT JOIN DWH_dbo.Dim_BillingDepot dbd
	ON fbw.DepotID = dbd.DepotID
LEFT JOIN DWH_dbo.Dim_FundingType dft
	ON dbd.FundingTypeID = dft.FundingTypeID
LEFT JOIN DWH_dbo.Dim_CardType dct
	ON dct.CardTypeID = fbw.CardTypeIDAsInteger
LEFT JOIN #pips p
	ON p.TransactionID = fbw.WithdrawPaymentID AND p.TransactionType = 'Withdraw'
WHERE fbw.CashoutStatusID_Funding = 3
AND fbw.ModificationDateID=@DateID

CREATE CLUSTERED INDEX #col1 ON #metaCO (CID, WithdrawID, WithdrawPaymentID);


IF OBJECT_ID('tempdb..#DepsWithRefunds') IS NOT NULL DROP TABLE #DepsWithRefunds
CREATE TABLE #DepsWithRefunds
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT m.RealCID
	  ,m.DepositID
	  ,m.WithdrawID
	  ,m.WithdrawPaymentID
	  ,m.Occurred
	  ,m.DateID
	  ,m.FundingTypeID
	  ,m.ActionTypeID
	  ,m.Amount
	  ,'Deposit' AS ActionType

FROM #mimo m
WHERE m.ActionTypeID = 7

UNION

SELECT m.RealCID
	  ,m.DepositID
	  ,m.WithdrawID
	  ,m.WithdrawPaymentID
	  ,m.Occurred
	  ,m.DateID
	  ,m.FundingTypeID
	  ,m.ActionTypeID
	  ,m.Amount
	  ,dat.Name AS ActionType
FROM #mimo m
JOIN DWH_dbo.Dim_ActionType dat
	ON m.ActionTypeID = dat.ActionTypeID
WHERE m.ActionTypeID in (11,12,13,37)
AND m.DepositID IS NOT NULL;

CREATE CLUSTERED INDEX #col1 ON #DepsWithRefunds (RealCID, DepositID, ActionType);


IF OBJECT_ID('tempdb..#deps') IS NOT NULL DROP TABLE #deps
CREATE TABLE #deps
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT
	m.RealCID
   ,m.DepositID
   ,m.WithdrawID
   ,m.WithdrawPaymentID
   ,m.Occurred
   ,m.DateID
   ,m.FundingTypeID
   ,m.ActionTypeID
   ,m.Amount
   ,m.ActionType
  , fsc.IsCreditReportValidCB
  , dr1.Name AS Regulation
  , m1.PaymentType
  , m1.Depot
  , m1.BankName
  , m1.CurrencyID
  , m1.CurrencyAmount
  , m1.AmountUSD
  , m1.ExchangeRate
  , m1.CarTypeName AS CardType
  , m1.TransactionIDAsString
  , m1.BaseExchangeRate
  , m1.ExchangeFee

FROM #DepsWithRefunds m
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
	ON m.RealCID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND m.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Regulation dr1
	ON fsc.RegulationID = dr1.DWHRegulationID
LEFT JOIN #meta m1
	ON m.DepositID = m1.DepositID;

CREATE CLUSTERED INDEX #col1 ON #deps (RealCID, DepositID);



---- final deposits table ----
IF OBJECT_ID('tempdb..#DepositsFinal') IS NOT NULL DROP TABLE #DepositsFinal
CREATE TABLE #DepositsFinal
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT
dc.RealCID
 , dc.ExternalID
  , d.Amount
  , d.ActionType
  , d.DepositID
  , d.Occurred
  , d.Regulation
  , d.FundingTypeID
  , d.PaymentType AS PaymentMethod
  , d.CurrencyID
  , d.CurrencyAmount AS NonUSDAmount
  , dc1.Abbreviation AS Currency
  , d.TransactionIDAsString
  , d.CardType
  , d.Depot
  , d.BankName
  , d.IsCreditReportValidCB
  , d.BaseExchangeRate
  , d.ExchangeFee


FROM #deps d
LEFT JOIN DWH_dbo.Dim_Customer dc
	ON d.RealCID = dc.RealCID
LEFT JOIN DWH_dbo.Dim_Currency dc1
	ON d.CurrencyID = dc1.CurrencyID;



/*********************************************************************************************************************************************************
*********************************************************************************************************************************************************
**********************************************************************************************************************************************************/
IF OBJECT_ID('tempdb..#COsWithRefunds') IS NOT NULL DROP TABLE #COsWithRefunds
CREATE TABLE #COsWithRefunds
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT m.RealCID
	  ,m.DepositID
	  ,m.WithdrawID
	  ,m.WithdrawPaymentID
	  ,m.Occurred
	  ,m.DateID
	  ,m.FundingTypeID
	  ,m.ActionTypeID
	  ,m.Amount
	  ,'Cashout' AS ActionType

FROM #mimo m
WHERE m.ActionTypeID = 8

UNION

SELECT m.RealCID
	  ,m.DepositID
	  ,m.WithdrawID
	  ,m.WithdrawPaymentID
	  ,m.Occurred
	  ,m.DateID
	  ,m.FundingTypeID
	  ,m.ActionTypeID
	  ,m.Amount
	  ,dat.Name AS ActionType
FROM #mimo m
JOIN DWH_dbo.Dim_ActionType dat
	ON m.ActionTypeID = dat.ActionTypeID
WHERE m.ActionTypeID in (11,12,13,37)
AND m.WithdrawID IS NOT NULL;

CREATE CLUSTERED INDEX #col1 ON #COsWithRefunds (RealCID, WithdrawID, ActionType);


IF OBJECT_ID('tempdb..#COs') IS NOT NULL DROP TABLE  #COs
CREATE TABLE #COs
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT
	m.RealCID
   ,m.DepositID
   ,m.WithdrawID
   ,m.WithdrawPaymentID
   ,m.Occurred
   ,m.DateID
   ,m.FundingTypeID
   ,m.ActionTypeID
   ,m.Amount
   ,m.ActionType
   ,m1.PaymentMethod
   ,m1.Depot
   ,m1.BankNameAsString
   ,m1.CurrencyID
   ,m1.ExchangeRate
   ,m1.CardType
   ,dr1.Name AS Regulation
   ,fsc.IsCreditReportValidCB
   ,m1.BaseExchangeRate
   ,m1.ExchangeFee
   ,m1.VerificationCode

FROM #COsWithRefunds m
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
	ON m.RealCID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND m.DateID BETWEEN dr.FromDateID AND dr.ToDateID
LEFT JOIN DWH_dbo.Dim_Regulation dr1
	ON fsc.RegulationID = dr1.DWHRegulationID
LEFT JOIN #metaCO m1
	ON m.WithdrawPaymentID = m1.WithdrawPaymentID;

CREATE CLUSTERED INDEX #col1 ON #COs (RealCID, WithdrawID);




-- final withdraws table
IF OBJECT_ID('tempdb..#COFinal') IS NOT NULL DROP TABLE  #COFinal
CREATE TABLE #COFinal
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT dc.ExternalID
	, c.ActionType
	, c.WithdrawID
	, c.WithdrawPaymentID
	, c.Occurred
	, c.Amount
	, c.PaymentMethod
	, c.Depot
	, c.BankNameAsString
	, c.CardType
	, c.Regulation
	, c.IsCreditReportValidCB
	, c.BaseExchangeRate
	, c.ExchangeFee
	, c.VerificationCode
	, dc.RealCID

FROM #COs c
JOIN DWH_dbo.Dim_Customer dc
	ON c.RealCID = dc.RealCID;

 --insert data Depsits

 DELETE BI_DB_dbo.BI_DB_EY_Audit_Deposits FROM  BI_DB_dbo.BI_DB_EY_Audit_Deposits WHERE DateID=@DateID

 INSERT INTO  BI_DB_dbo.BI_DB_EY_Audit_Deposits
 (RealCID
	,DateID
	,[Date]
	,ExternalID
	,Amount
	,ActionType
	,DepositID
	,Occurred
	,Regulation
	,FundingTypeID
	,PaymentMethod
	,CurrencyID
	,NonUSDAmount
	,Currency
	,TransactionIDAsString
	,CardType
	,Depot
	,BankName
	,IsCreditReportValidCB
	,BaseExchangeRate
	,ExchangeFee
	,UpdateDate )

SELECT df.RealCID
,@DateID 'DateID'
,@Date 'Date'
	 ,df.ExternalID
	 ,df.Amount
	 ,df.ActionType
	 ,df.DepositID
	 ,df.Occurred
	 ,df.Regulation
	 ,df.FundingTypeID
	 ,df.PaymentMethod
	 ,df.CurrencyID
	 ,df.NonUSDAmount
	 ,df.Currency
	 ,df.TransactionIDAsString
	 ,df.CardType
	 ,df.Depot
	 ,df.BankName
	 ,df.IsCreditReportValidCB
	 ,df.BaseExchangeRate
	 ,df.ExchangeFee
	 ,GETDATE() AS 'UpdateDate'

FROM #DepositsFinal df


--insert data Cashouts

 DELETE BI_DB_dbo.BI_DB_EY_Audit_Cashouts FROM  BI_DB_dbo.BI_DB_EY_Audit_Cashouts WHERE DateID=@DateID

 INSERT INTO  BI_DB_dbo.BI_DB_EY_Audit_Cashouts
 (RealCID
	,DateID
	,[Date]
	,ExternalID
	,ActionType
	,WithdrawID
	,WithdrawPaymentID
	,Occurred
	,Amount
	,PaymentMethod
	,Depot
	,BankNameAsString
	,CardType
	,Regulation
	,IsCreditReportValidCB
	,BaseExchangeRate
	,ExchangeFee
	,VerificationCode
	,UpdateDate )

SELECT c.RealCID
,@DateID 'DateID'
,@Date 'Date'
	  ,c.ExternalID
	  ,c.ActionType
	  ,c.WithdrawID
	  ,c.WithdrawPaymentID
	  ,c.Occurred
	  ,c.Amount
	  ,c.PaymentMethod
	  ,c.Depot
	  ,c.BankNameAsString
	  ,c.CardType
	  ,c.Regulation
	  ,c.IsCreditReportValidCB
	  ,c.BaseExchangeRate
	  ,c.ExchangeFee
	  ,c.VerificationCode
	  ,GETDATE() AS 'UpdateDate'

FROM #COFinal c

END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts` | synapse_sp | BI_DB_dbo | SP_EY_Audit_Deposit_Cashouts | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts.sql` |
| `BI_DB_dbo.BI_DB_EY_Audit_Deposits` | unresolved | BI_DB_dbo | BI_DB_EY_Audit_Deposits | `—` |
| `DWH_dbo.Fact_CustomerAction` | synapse | DWH_dbo | Fact_CustomerAction | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `BI_DB_dbo.BI_DB_DepositWithdrawFee` | synapse | BI_DB_dbo | BI_DB_DepositWithdrawFee | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `DWH_dbo.Fact_BillingDeposit` | synapse | DWH_dbo | Fact_BillingDeposit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingDeposit.md` |
| `DWH_dbo.Dim_FundingType` | synapse | DWH_dbo | Dim_FundingType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `DWH_dbo.Dim_BillingDepot` | synapse | DWH_dbo | Dim_BillingDepot | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_BillingDepot.md` |
| `DWH_dbo.Dim_CardType` | synapse | DWH_dbo | Dim_CardType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_CardType.md` |
| `DWH_dbo.Fact_BillingWithdraw` | synapse | DWH_dbo | Fact_BillingWithdraw | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_BillingWithdraw.md` |
| `DWH_dbo.Dim_ActionType` | synapse | DWH_dbo | Dim_ActionType | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ActionType.md` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `DWH_dbo.Dim_Customer` | synapse | DWH_dbo | Dim_Customer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `DWH_dbo.Dim_Currency` | synapse | DWH_dbo | Dim_Currency | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |

