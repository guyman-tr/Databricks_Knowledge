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
- **Object**: `Dim_CashoutReason`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/DWH_dbo/Dim_CashoutReason/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\Dim_CashoutReason\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\DWH_dbo\Dim_CashoutReason\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Tables\DWH_dbo.Dim_CashoutReason.sql`

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

# Pre-Resolved Upstream Bundle for `DWH_dbo.Dim_CashoutReason`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Dim_CashoutReason.sql`

```sql
CREATE TABLE [DWH_dbo].[Dim_CashoutReason]
(
	[CashoutReasonID] [int] NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[UpdateDate] [datetime] NOT NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED INDEX
	(
		[CashoutReasonID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 2 upstream wiki(s). Read EACH one in full.


### Upstream `Dictionary.CashoutReason` — production
- **Resolved as**: `etoro.Dictionary.CashoutReason`
- **Wiki path**: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Dictionary\Tables\Dictionary.CashoutReason.md`

# Dictionary.CashoutReason

> Lookup table defining the 19 reasons for initiating a cashout (withdrawal) — from user-requested withdrawals and PI payments to risk refunds, account closures, and crypto transfers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CashoutReasonID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 19 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CashoutReason explains *why* a withdrawal was initiated. Every withdrawal recorded in Billing.Withdraw carries a CashoutReasonID that classifies the business context: was it a standard user request (16), a Popular Investor payment (14), an affiliate payment (15), a risk refund (3), an account closure (12, 19), or something else?

This classification is critical for financial reporting, compliance auditing, and operational analytics. Different reasons trigger different processing logic — for example, Billing.WithdrawToFundingProcess filters by `CashoutReasonID IN (12, 14, 15)` to identify forced account closures and partner/PI payments that require special handling. The default for user-initiated withdrawals is CashoutReasonID=16 ("Requested by User"), explicitly set in Billing.WithdrawRequestAdd and Billing.WithdrawalService_WithdrawRequestAdd.

The table is joined extensively in BackOffice withdrawal screens (GetWithdrawRequests, GetCashOutRequests_Main, InProcessPaymentsToSendPCIVersion) to display the reason alongside withdrawal details, and in Trade.TAPI procedures for customer-facing credit history.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: The major categories of withdrawal reasons.

**Columns/Parameters Involved**: `CashoutReasonID`, `Name`

**Rules**:
- **User-Initiated (16)**: Standard withdrawal requested by the customer. Default value in WithdrawRequestAdd.
- **Partner Payments (14, 15)**: Automated payments to Popular Investors (PI Payment) and Affiliates (Affiliate Payment). Special processing in WithdrawToFundingProcess.
- **Risk/Compliance (3, 7, 8)**: Risk refunds, 3rd party payment returns, bonus abuse adjustments. Driven by compliance/risk teams.
- **Account Closures (6, 12, 17, 19)**: Forced withdrawals when accounts are blocked, foreclosed, or failed verification. CashoutReasonID=12 ("Foreclose account") and 19 ("ForClose(GAP)") trigger special handling in processing.
- **Adjustments (1, 4, 5)**: Financial corrections — general adjustments, negative balance fixes, withdrawal fee adjustments.
- **Technical/Operational (9, 10, 11, 13)**: Returned withdrawals, technical issues, underage account closures, test transactions.
- **Crypto (18)**: Withdrawal via crypto wallet transfer — dedicated reason for blockchain-based fund movements.

**Diagram**:
```
Cashout Reason Categories:

  User-Initiated ──► Requested by User (16)
  Partner Payments ──► PI Payment (14), Affiliate Payment (15)
  Risk/Compliance ──► Risk Refund (3), 3rd Party (7), Bonus Abuse (8)
  Account Closure ──► Foreclose (12, 19), Block (6), Failed Verification (17)
  Adjustments ──► Adjustment (1), Negative Balance (4), Fee Adj (5)
  Special ──► Crypto Transfer (18), Returned (9), Test (13)
```

### 2.2 Special Processing by Reason

**What**: How specific CashoutReasonIDs trigger different processing logic.

**Columns/Parameters Involved**: `CashoutReasonID`

**Rules**:
- **Billing.WithdrawToFundingProcess**: Checks `CashoutReasonID IN (12, 14, 15)` — foreclose, PI payment, and affiliate payment get special routing
- **Billing.WithdrawalService_EstimateBonusDeduction**: Uses CashoutReasonID to determine bonus deduction eligibility
- **Billing.WithdrawAndWithdrawToFundingAdd**: Defaults @CashoutReasonID=18 for crypto wallet transfers
- **Trade.TAPI_GetCreditHistoryByCID**: Uses `ISNULL(bw.CashoutReasonID, 0)` — defaults to 0 when no reason set

---

## 3. Data Overview

| CashoutReasonID | Name | Meaning |
|---|---|---|
| 1 | Adjustment | General financial adjustment — manual correction to customer balance. |
| 2 | Partners withdraw | Partner account withdrawal — non-customer partner fund extraction. |
| 3 | Risk Refund | Refund initiated by risk/compliance team — returning funds to flagged customer. |
| 4 | Negative Balance adjustment | Correction for negative account balance — restoring customer to zero. |
| 5 | Withdraw fees adjustment | Adjustment to previously charged withdrawal fees. |
| 6 | Block account – Not communicative | Forced withdrawal when blocking unresponsive account. |
| 7 | 3rd party payment | Return of third-party funds — payment didn't originate from account holder. |
| 8 | Bonus abuse adjustment | Clawback of abused bonus/promotional credits. |
| 9 | Returned withdraw | Previously sent withdrawal was returned by recipient bank/PSP. |
| 10 | Technical issue – Customer side | Withdrawal due to customer-side technical problem requiring resolution. |
| 11 | Underage | Account closure withdrawal — customer found to be under minimum age. |
| 12 | Foreclose account | Forced withdrawal during account foreclosure/liquidation. Special processing in WithdrawToFundingProcess. |
| 13 | Test | Test transaction — internal testing only. |
| 14 | PI Payment | Popular Investor program payment — automated compensation to copy-trading leaders. Special processing in WithdrawToFundingProcess. |
| 15 | Affiliate Payment | Affiliate partner commission payment. Special processing in WithdrawToFundingProcess. |
| 16 | Requested by User | Standard customer-initiated withdrawal. Default reason (set explicitly in WithdrawRequestAdd). Most common cashout reason. |
| 17 | Failed Verification | Withdrawal/return of funds when customer fails identity verification. |
| 18 | Transfered by CryptoWallet | Withdrawal via cryptocurrency wallet transfer. Default for crypto transfers in WithdrawAndWithdrawToFundingAdd. |
| 19 | ForClose(GAP) | Forced withdrawal during account foreclosure with GAP (discrepancy) resolution. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutReasonID | int | NO | - | VERIFIED | Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Withdraw | CashoutReasonID | Implicit | Main withdrawal table stores reason |
| History.WithdrawAction | CashoutReasonID | Implicit | Withdrawal action history stores reason |
| Billing.TBL_Withdraw | CashoutReasonID | UDT column | TVP for batch withdrawal operations |
| BackOffice.GetWithdrawRequests | CashoutReasonID | LEFT JOIN | Withdrawal screen shows reason name |
| BackOffice.GetCashOutRequests_Main | CashoutReasonID | LEFT JOIN | Main cashout screen shows reason |
| BackOffice.InProcessPaymentsToSendPCIVersion | CashoutReasonID | LEFT JOIN | In-process payment report |
| BackOffice.GetProcessedWithdrawPCIVersion | CashoutReasonID | LEFT JOIN | Processed withdrawal report |
| Billing.WithdrawRequestAdd | @CashoutReasonID | Parameter (default 16) | Sets reason at withdrawal creation |
| Billing.WithdrawToFundingProcess | CashoutReasonID | WHERE IN (12,14,15) | Special processing for closures/payments |
| Billing.WithdrawAndWithdrawToFundingAdd | @CashoutReasonID | Parameter (default 18) | Crypto wallet transfers |
| Customer.SetBalanceCashOut | @CashoutReasonID | Parameter | Balance update with reason |
| Trade.TAPI_GetCreditHistoryByCID | CashoutReasonID | SELECT ISNULL | Customer credit history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutReason (table)
  └── stored in Billing.Withdraw, History.WithdrawAction
  └── joined by 22+ procedures across BackOffice, Billing, Trade, SalesForce
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Stores CashoutReasonID per withdrawal |
| History.WithdrawAction | Table | Action history stores reason |
| BackOffice.GetWithdrawRequests | Stored Procedure | JOINs for reason name |
| Billing.WithdrawRequestAdd | Stored Procedure | Default reason = 16 |
| Billing.WithdrawToFundingProcess | Stored Procedure | Special handling for 12, 14, 15 |
| Trade.TAPI_GetCreditHistoryByCID | Stored Procedure | Customer credit history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.CashoutReason | CLUSTERED PK | CashoutReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary.CashoutReason | PRIMARY KEY | Unique reason identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all cashout reasons
```sql
SELECT  CashoutReasonID,
        Name
FROM    Dictionary.CashoutReason WITH (NOLOCK)
ORDER BY CashoutReasonID;
```

### 8.2 Count withdrawals by reason
```sql
SELECT  dcr.Name            AS CashoutReason,
        COUNT(*)            AS WithdrawalCount
FROM    Billing.Withdraw bw WITH (NOLOCK)
JOIN    Dictionary.CashoutReason dcr WITH (NOLOCK)
        ON bw.CashoutReasonID = dcr.CashoutReasonID
GROUP BY dcr.Name
ORDER BY WithdrawalCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis across 22+ procedures.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 22 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CashoutReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CashoutReason.sql*


### Upstream `DWH_dbo.Dim_Manager` — synapse
- **Resolved as**: `DWH_dbo.Dim_Manager`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md`

# DWH_dbo.Dim_Manager

> 5,152-row dimension table mapping ManagerID to the BackOffice customer-success and support manager who is assigned to a customer account -- combining manager name, active status, team-leader flag, Salesforce CRM ID, and Calendly scheduling ID into a single reference table for customer-manager analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.BackOffice.Manager (BackOffice CRM) + Salesforce (SFManagerID) |
| **Refresh** | Daily (incremental: UPDATE existing + INSERT new; never truncates) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP, PK_ManagerID NOT ENFORCED |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Manager` is the reference table for eToro's BackOffice customer-success managers -- the people (support agents, account managers, team leaders) assigned to serve customer accounts. A customer account typically has an assigned ManagerID that identifies the primary relationship owner in the BackOffice/CRM system.

The table holds 5,152 rows: 1,367 currently active managers (`IsActive=True`) including 1 active team leader, plus 3,785 historical/departed managers (`IsActive=False`). Since rows are never deleted, the table preserves the full history of everyone who has ever been a manager in the system.

Key columns: `FirstName`, `LastName` (personal details), `IsActive` (currently employed/assigned), `IsTeamLeader` (hierarchy flag), `SFManagerID` (Salesforce CRM ID, 18-char), `CalendlyID` (scheduling link). The `UserGroup` and `ParentUserGroup` columns are **not populated** -- both are hardcoded to `'Not Available'` in the ETL SP.

ETL pattern: `SP_Dictionaries_DL_To_Synapse` -- loads a staging intermediate (`Ext_Dim_Manager`) from `DWH_staging.etoro_BackOffice_Manager`, then merges into `Dim_Manager` (UPDATE existing rows, INSERT new rows). A post-load UPDATE sets `SFManagerID` from the Salesforce-to-BackOffice mapping table.

---

## 2. Business Logic

### 2.1 Incremental Merge Pattern (Soft-Delete)

**What**: Unlike most DWH Dim tables that use TRUNCATE+INSERT, Dim_Manager uses an incremental UPDATE+INSERT pattern that preserves historical manager records.

**Rules**:
- **UPDATE**: Existing ManagerID rows are updated with current FirstName, LastName, IsTeamLeader, IsActive, CalendlyID. This means a manager's name, active status, or team-leader flag can change.
- **INSERT**: New ManagerIDs from `etoro_BackOffice_Manager` that do not exist in Dim_Manager are appended. `InsertDate` is set to GETDATE() on first insert only.
- **No DELETE**: Managers who leave the company remain in the table with `IsActive=False`. The table is the full history of all managers.
- **SFManagerID**: Set via a separate post-load UPDATE joining to `SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping`. Managers not in Salesforce have NULL SFManagerID.

### 2.2 UserGroup / ParentUserGroup Not Populated

**What**: The DDL defines `UserGroup` and `ParentUserGroup` columns, but the ETL hardcodes both to `'Not Available'` for all rows.

**Rule**: Do not use `UserGroup` or `ParentUserGroup` for any analysis. Both columns have the literal string `'Not Available'` for every row. The intended team/group hierarchy data has not been implemented.

### 2.3 CalendlyID for Customer Scheduling

**What**: `CalendlyID` holds the manager's Calendly scheduling account identifier, used for customer-facing meeting booking.

**Rule**: Most inactive (historical) managers have `CalendlyID='etoro-club'`, suggesting a default value is set when a manager leaves the system rather than the CalendlyID being set to NULL. Active managers have their personal Calendly IDs. Do not use CalendlyID to infer active status.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (5,152 rows trivially replicated). HEAP -- no clustered index. PK_ManagerID is NOT ENFORCED (Synapse syntax; uniqueness is not guaranteed at the DB level, though duplicates are not expected). Zero JOIN overhead.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get manager name for a customer account | `JOIN Dim_Manager ON ManagerID; SELECT FirstName, LastName` |
| Find all currently active managers | `WHERE IsActive = 1` (1,367 rows) |
| Find active team leaders | `WHERE IsActive = 1 AND IsTeamLeader = 1` (1 row currently) |
| Cross-reference with Salesforce | `WHERE SFManagerID IS NOT NULL` |

### 3.3 Gotchas

- **UserGroup = 'Not Available'**: Both `UserGroup` and `ParentUserGroup` are hardcoded placeholder strings. Do not use for grouping or filtering.
- **3,785 inactive managers**: Always filter `WHERE IsActive = 1` for current-state analysis. Leaving out this filter inflates manager counts 4x.
- **CalendlyID default 'etoro-club'**: This is a default value for departed/inactive managers, not a real Calendly account. Filter on IsActive=1 for meaningful CalendlyID usage.
- **HEAP index**: Full table scans on all queries. Acceptable at 5,152 rows.
- **PK NOT ENFORCED**: No database-level guarantee against duplicate ManagerIDs. Validate if using ManagerID as a join key in data quality checks.
- **SFManagerID is NULL for many managers**: Only managers that appear in the Salesforce-to-BackOffice mapping have SFManagerID populated.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ManagerID | int | NO | Auto-generated unique integer identifier for each BackOffice staff member. PK for the entire BackOffice authorization system. ManagerID=0 is the reserved System account; ManagerID=1 is the bootstrap Admin. All BackOffice action tables (BackOffice.Customer, Task, Downtime, etc.) store ManagerID as the 'acting staff' reference. (Tier 1 — BackOffice.Manager) |
| 2 | UserGroup | varchar(50) | NO | Hardcoded to 'Not Available' for all rows. The ETL SP sets this to a literal constant: `'Not Available' as UserGroup`. Intended to represent the manager's team/group but not populated. Do not use. (Tier 3 — SP_Dictionaries_DL_To_Synapse) |
| 3 | ParentUserGroup | varchar(50) | NO | Hardcoded to 'Not Available' for all rows. Same as UserGroup -- intended to represent the manager's parent team hierarchy but not populated. Do not use. (Tier 3 — SP_Dictionaries_DL_To_Synapse) |
| 4 | FirstName | varchar(50) | NO | Staff member's first name. Combined with LastName in views and procedures to produce display names (e.g., BackOffice.GetMyCustomers sets [Manager] = FirstName + ' ' + LastName). (Tier 1 — BackOffice.Manager) |
| 5 | LastName | varchar(50) | NO | Staff member's last name. Combined with FirstName for display. LastName='*' indicates a functional/shared account (e.g., the generic 'support' account). (Tier 1 — BackOffice.Manager) |
| 6 | IsActive | bit | NO | Logical soft-delete flag controlling login access and visibility. 1=active (staff currently employed, can authenticate). 0=deactivated (former staff or suspended; LOGIN is blocked). Do NOT physically delete manager rows — use IsActive=0 to preserve audit history. (Tier 1 — BackOffice.Manager) |
| 7 | IsTeamLeader | bit | NO | Marks this manager as a team leader within their department. 1=team leader role. 0=individual contributor. Used in LoadManagers/LoadManagerByUsername responses for role-based UI rendering. (Tier 1 — BackOffice.Manager) |
| 8 | DWHManagerID | int | YES | Always equal to ManagerID. Standard DWH DWH{X}ID redundancy pattern. Do not use for JOINs. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 9 | StatusID | int | YES | Hardcoded to 1 for all rows. Conveys no business information. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 10 | UpdateDate | datetime | YES | ETL run timestamp for the most recent UPDATE that touched this row. Set to GETDATE() on every daily UPDATE. Reflects last ETL run, not production modification. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 11 | InsertDate | datetime | YES | ETL run timestamp when the manager row was first inserted into Dim_Manager. Set once on INSERT; not updated on subsequent runs. Unlike most DWH tables, this may reflect the actual first-appearance date for the manager. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 12 | SFManagerID | nvarchar(18) | YES | Salesforce CRM 18-character object ID for this manager (e.g., 0050800000DitvwAAB). Set via post-load UPDATE from SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping. NULL for managers not present in the Salesforce mapping. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 13 | CalendlyID | nvarchar(50) | YES | Calendly scheduling identifier for this manager. Exposed via GetManagers procedure for the customer-facing scheduler that lets customers book calls with their account manager. (Tier 1 — BackOffice.Manager) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ManagerID | etoro.BackOffice.Manager | ManagerID | passthrough |
| UserGroup | -- | -- | ETL-computed: hardcoded 'Not Available' |
| ParentUserGroup | -- | -- | ETL-computed: hardcoded 'Not Available' |
| FirstName | etoro.BackOffice.Manager | FirstName | passthrough |
| LastName | etoro.BackOffice.Manager | LastName | passthrough |
| IsActive | etoro.BackOffice.Manager | IsActive | passthrough |
| IsTeamLeader | etoro.BackOffice.Manager | IsTeamLeader | passthrough |
| DWHManagerID | etoro.BackOffice.Manager | ManagerID | rename (= ManagerID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on each UPDATE |
| InsertDate | -- | -- | ETL-computed: GETDATE() on first INSERT only |
| SFManagerID | Salesforce SalesForceToBOManagerMapping | SFManagerID | post-load UPDATE via ManagerID join |
| CalendlyID | etoro.BackOffice.Manager | CalendlyID | passthrough (UPDATE) |

### 5.2 ETL Pipeline

```
etoro.BackOffice.Manager  (BackOffice CRM)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_BackOffice_Manager
  |-- SP_Dictionaries_DL_To_Synapse ---|
      1. TRUNCATE Ext_Dim_Manager + INSERT from etoro_BackOffice_Manager
      2. UPDATE Dim_Manager (existing rows: name, active, team-leader, Calendly)
      3. INSERT Dim_Manager (new ManagerIDs not yet in table)
      4. UPDATE SFManagerID from SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping
  v
DWH_dbo.Dim_Manager  (5,152 rows; incremental, never truncated)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Manager/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer account dimension tables | ManagerID | Identifies the assigned BackOffice manager for each customer |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP; incremental pattern |

---

## 7. Sample Queries

### 7.1 List all currently active managers

```sql
SELECT ManagerID, FirstName, LastName, IsTeamLeader, SFManagerID, CalendlyID
FROM [DWH_dbo].[Dim_Manager]
WHERE IsActive = 1
ORDER BY IsTeamLeader DESC, LastName, FirstName;
```

### 7.2 Count customers per active manager

```sql
SELECT
    m.ManagerID,
    m.FirstName + ' ' + m.LastName AS ManagerName,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_Manager] m ON f.ManagerID = m.ManagerID
WHERE m.IsActive = 1
GROUP BY m.ManagerID, m.FirstName, m.LastName
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.4/10 (★★★★☆) | Phases: 8/14*
*Tiers: 6 T1, 5 T2, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 13/13, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Manager | Type: Table | Production Source: etoro.BackOffice.Manager + Salesforce*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `DWH_dbo.SP_Dictionaries_DL_To_Synapse`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dictionaries_DL_To_Synapse.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Dictionaries_DL_To_Synapse] AS
BEGIN

/********************************************************************************************  
Author:      <Boris Slutski>
Create Date: <2021-09-13>
Description: SP intended to transfer data from DataLake to synapse
**************************  
** Change History  
**************************  
Date           Author     Description   
-----------  ----------  ------------------------------------  
2025-05-13    Daniel K     Add 5 HistoryCosts Dictionaries Tables
********************************************************************************************/
----- EXEC [DWH_dbo].[SP_Dictionaries_DL_To_Synapse]


TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate]

INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate]
([AffiliateID]
,[DateCreated]
,[MarketingExpenseID]
,[MarketingExpenseName]
,[Contact]
,[AffiliatesGroupsName]
,[ContractName]
,[Channel]
,[newContact]
,[AccountActivated]
,[LoginName]
,[UserName1]
,[UserName2]
,[UserName3]
,[UserName4]
,[Email]
,[CompanyAddress]
,[City]
,[CountryID]
,[WebSiteURL]
,[LanguageName]
,[WebSiteTitle]
,[GCID]
,[EntityName]
,[ContactPersonFullName]
,[Telephone])
SELECT							a.AffiliateID
,a.DateCreated 
,a.MarketingExpenseID
,b.MarketingExpenseName 
,case when a.Contact is null or a.Contact =' '  then isnull(a.EntityName COLLATE Latin1_General_BIN,a.Contact ) else a.Contact end AS Contact
,c.AffiliatesGroupsName
,afftype.Description AS ContractName
,CASE
WHEN isnull(b.MarketingExpenseName,'Direct')='Direct' and c.AffiliatesGroupsName='Friend Referral' then 'Friend Referral'
WHEN b.MarketingExpenseName in('Mobile media') then 'Mobile Acquisition' --New channel add by Sivan 20190331
WHEN b.MarketingExpenseName in('Media') then 'Media'
WHEN c.AffiliatesGroupsName='Mobile' then 'Direct'
WHEN b.MarketingExpenseName = 'SMM' then 'Direct'
WHEN b.MarketingExpenseName = 'RAF' then 'Friend Referral'
WHEN a.AffiliateID in (0) then 'Direct' --**
WHEN b.MarketingExpenseName in('Networks','Offline Partners','Local Offices','Local Partners') then 'Affiliate'
ELSE isnull(b.MarketingExpenseName,'Direct')
END AS Channel
,REPLACE(LOWER(case when a.Contact is null or a.Contact =' '  then isnull(a.EntityName COLLATE Latin1_General_BIN,a.Contact) else a.Contact end), 'nonbrand', 'paid')  COLLATE Latin1_General_BIN  AS newContact
,a.AccountStatus as AccountActivated
,a.LoginName
,cast(ISNULL(pd1.Username,'''') as varchar(50)) COLLATE Latin1_General_BIN AS UserName1
,cast(ISNULL(pd2.Username,'''') as varchar(50)) COLLATE Latin1_General_BIN AS UserName2 
,cast(ISNULL(pd3.Username,'''') as varchar(50)) COLLATE Latin1_General_BIN AS UserName3
,cast(a.LoginName as varchar(50)) AS UserName4
,a.Email
,a.CompanyAddress
,a.City
,a.CountryID
,a.WebSiteURL
,lan.LanguageName
,a.[WebSiteTitle]
,a.[GCID]
,a.[EntityName]
,a.[ContactPersonFullName]
,a.[Telephone]
FROM [DWH_staging].[fiktivo_dbo_tblaff_Affiliates] AS a WITH (NOLOCK) 
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_MarketingExpense] AS b WITH (NOLOCK) ON a.MarketingExpenseID = b.MarketingExpenseID 
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_AffiliatesGroups] AS c WITH (NOLOCK) ON a.AffiliatesGroupsID = c.AffiliatesGroupsID 
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_AffiliateTypes] AS afftype WITH (NOLOCK) ON a.AffiliateTypeID = afftype.AffiliateTypeID
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_PaymentDetails] pd1 WITH(NOLOCK) ON a.PaymentDetailsID = pd1.PaymentDetailsID
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_PaymentDetails] pd2 WITH(NOLOCK) ON a.PaymentDetails2ID = pd2.PaymentDetailsID
LEFT OUTER JOIN [DWH_staging].[fiktivo_dbo_tblaff_PaymentDetails] pd3 WITH(NOLOCK) ON a.PaymentDetails3ID = pd3.PaymentDetailsID
left join [DWH_staging].[fiktivo_dbo_tblaff_Languages] lan on lan.LanguageID = a.CommunicationLangID

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_Customer]

INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_Customer]
([CID]
,[UserName])
select CID,UserName
from [DWH_staging].[etoro_Customer_Customer] with (NOLOCK)

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_FTD]

--Alter by Noga 3/11/22
INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_FTD]
([AffiliateID]
,[FTDFirstDate]
,[FTDLastDate]
,[FTDLifeTime]
,[FTDYesterday]
,[FTDLastMonth]
,[FTDLastQuarter]
,[FTDLastYear]
,[FTDThisMonth]
,[FTDThisQuarter]
,[FTDThisYear])

SELECT  
	cpa.AffiliateID
	--,cpa.CID As Real_CID  ---<<<<< optional, New column
	,min(cpa.CreditDate) FTDFirstDate
	,max(cpa.CreditDate) FTDLastDate
	,SUM(CAST(cpa.IsFirstDeposit as INT)) FTDLifeTime
	,sum(case when cpa.CreditDate >= dateadd(day,datediff(day,1,GETDATE()),0) and cpa.CreditDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS FTDYesterday
	,sum(case when cpa.CreditDate > EOMONTH(DATEADD(mm,-2,getdate())) and cpa.CreditDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDLastMonth
	,sum(case when cpa.CreditDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and  cpa.CreditDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDLastQuarter
	,sum(case when cpa.CreditDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and cpa.CreditDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDLastYear
	,sum(case when cpa.CreditDate >=  DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDThisMonth
	,sum(case when cpa.CreditDate >=  DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDThisQuarter
	,sum(case when cpa.CreditDate >=  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDThisYear
FROM [DWH_staging].[fiktivo_AffiliateCommission_Credit] cpa with(nolock) 
INNER JOIN  [DWH_staging].[fiktivo_AffiliateCommission_CreditCommission] cc with(nolock) 
ON cpa.CreditID = cc.CreditID AND cc.Tier=1
WHERE  cpa.CreditTypeID=1 AND 
       CAST(cpa.IsFirstDeposit as INT) = 1 AND
	   cpa.CreditDate < dateadd(day,datediff(day,0,GETDATE()),0)
GROUP  BY cpa.AffiliateID --,cpa.CID
--SELECT  
--tblCommissions.AffiliateID
--,min(cpa.DepositDate) FTDFirstDate
--,max(cpa.DepositDate) FTDLastDate
--,SUM(CAST(cpa.Optional2 as INT)) FTDLifeTime
--,sum(case when cpa.DepositDate >= dateadd(day,datediff(day,1,GETDATE()),0) and cpa.DepositDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS FTDYesterday
--,sum(case when cpa.DepositDate > EOMONTH(DATEADD(mm,-2,getdate())) and cpa.DepositDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDLastMonth
--,sum(case when cpa.DepositDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and  cpa.DepositDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDLastQuarter
--,sum(case when cpa.DepositDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and cpa.DepositDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDLastYear
--,sum(case when cpa.DepositDate >=  DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDThisMonth
--,sum(case when cpa.DepositDate >=  DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDThisQuarter
--,sum(case when cpa.DepositDate >=  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDThisYear
--FROM [DWH_staging].[fiktivo_dbo_tblaff_CPA] cpa with(nolock)
--LEFT JOIN [DWH_staging].[fiktivo_dbo_tblaff_CPA_Commissions] tblCommissions with(nolock)         ON tblCommissions.DepositID = cpa.DepositID
--WHERE  tblCommissions.Tier=1 and CAST(cpa.Optional2 as INT) = 1 and cpa.DepositDate < dateadd(day,datediff(day,0,GETDATE()),0)
--GROUP  BY tblCommissions.AffiliateID
  
TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_FTDe]

--Alter by Noga 3/11/22
INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_FTDe]
([AffiliateID]
,[FTDeFirstDate]
,[FTDeLastDate]
,[FTDeLifeTime]
,[FTDeYesterday]
,[FTDeLastMonth]
,[FTDeLastQuarter]
,[FTDeLastYear]
,[FTDeThisMonth]
,[FTDeThisQuarter]
,[FTDeThisYear])
SELECT
	cpa.AffiliateID,
	--cpa.CID As Real_CID,  ---<<<<< optional, New column
	min(cpa.CreditDate) FTDeFirstDate,
	max(cpa.CreditDate) FTDeLastDate,
	SUM(CAST(cpa.IsFirstDeposit as INT)) FTDeLifeTime,
	 sum(case when cpa.CreditDate >= dateadd(day,datediff(day,1,GETDATE()),0) and cpa.CreditDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS FTDeYesterday
	 ,sum(case when cpa.CreditDate > EOMONTH(DATEADD(mm,-2,getdate())) and cpa.CreditDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDeLastMonth
	,sum(case when cpa.CreditDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and  cpa.CreditDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDeLastQuarter
	,sum(case when cpa.CreditDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and cpa.CreditDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDeLastYear
	,sum(case when cpa.CreditDate >=  DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDeThisMonth
	,sum(case when cpa.CreditDate >=  DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDeThisQuarter
	,sum(case when cpa.CreditDate >=  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDeThisYear
FROM  [DWH_staging].[fiktivo_AffiliateCommission_Credit] cpa with(nolock)  
INNER JOIN [DWH_staging].[fiktivo_AffiliateCommission_CreditCommission] cc with(nolock) 
ON cpa.CreditID = cc.CreditID 
AND cc.Tier=1 
WHERE  cpa.CreditTypeID=1 AND 
       cpa.Valid = 1 AND 
	   CAST(cpa.IsFirstDeposit as INT) = 1 AND 
	   cpa.CreditDate < dateadd(day,datediff(day,0,GETDATE()),0)
GROUP  BY cpa.AffiliateID --,cpa.CID

--SELECT
--tblCommissions.AffiliateID
--,min(cpa.DepositDate) FTDeFirstDate
--,max(cpa.DepositDate) FTDeLastDate
--,SUM(CAST(cpa.Optional2 as INT)) FTDeLifeTime
-- ,sum(case when cpa.DepositDate >= dateadd(day,datediff(day,1,GETDATE()),0) and cpa.DepositDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS FTDeYesterday
-- ,sum(case when cpa.DepositDate > EOMONTH(DATEADD(mm,-2,getdate())) and cpa.DepositDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDeLastMonth
--,sum(case when cpa.DepositDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and  cpa.DepositDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDeLastQuarter
--,sum(case when cpa.DepositDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and cpa.DepositDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDeLastYear
--,sum(case when cpa.DepositDate >=  DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS FTDeThisMonth
--,sum(case when cpa.DepositDate >=  DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS FTDeThisQuarter
--,sum(case when cpa.DepositDate >=  DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS FTDeThisYear
--FROM [DWH_staging].[fiktivo_dbo_tblaff_CPA] cpa with(nolock)
--LEFT JOIN [DWH_staging].[fiktivo_dbo_tblaff_CPA_Commissions] tblCommissions  with(nolock)	ON tblCommissions.DepositID = cpa.DepositID 
--WHERE tblCommissions.Tier=1 and cpa.Valid = 1 and CAST(cpa.Optional2 as INT) = 1 and cpa.DepositDate < dateadd(day,datediff(day,0,GETDATE()),0)
--GROUP  BY	tblCommissions.AffiliateID

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_MasterAffiliate]

INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_MasterAffiliate]
([AffiliateID]
,[MasterAffiliateID])
SELECT a.[NewMemberID] AffiliateID
,a.[AffiliateID] MasterAffiliateID
FROM [DWH_staging].[fiktivo_dbo_tblaff_Tier2Members] a

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Affiliate_Registrations]
--Alter by Noga 3/11/22

INSERT INTO [DWH_dbo].[Ext_Dim_Affiliate_Registrations]
([AffiliateID]
,[RegistrationFirstDate]
,[RegistrationLastDate]
,[RegistrationLifeTime]
,[RegistrationYesterday]
,[RegistrationLastMonth]
,[RegistrationLastQuarter]
,[RegistrationLastYear]
,[RegistrationThisMonth]
,[RegistrationThisQuarter]
,[RegistrationThisYear])

SELECT 
	Registrations.AffiliateID
	--,Registrations.CID As Real_CID  ---<<<<< optional, New column
	,min(Registrations.RegistrationDate)  RegistrationFirstDate
	,max(Registrations.RegistrationDate)  RegistrationLastDate
	,Count(Registrations.RegistrationID) AS RegistrationLifeTime
	,sum(case when Registrations.RegistrationDate >= dateadd(day,datediff(day,1,GETDATE()),0) and Registrations.RegistrationDate < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS RegistrationYesterday
	,sum(case when Registrations.RegistrationDate > EOMONTH(DATEADD(mm,-2,getdate())) and Registrations.RegistrationDate < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS RegistrationLastMonth
	,sum(case when Registrations.RegistrationDate >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and Registrations.RegistrationDate < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS RegistrationLastQuarter
	,sum(case when Registrations.RegistrationDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and Registrations.RegistrationDate < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS RegistrationLastYear
	,sum(case when Registrations.RegistrationDate >= DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS RegistrationThisMonth
	,sum(case when Registrations.RegistrationDate >= DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS RegistrationThisQuarter
	,sum(case when Registrations.RegistrationDate >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS RegistrationThisYear
FROM   [DWH_staging].[fiktivo_AffiliateCommission_Registration] Registrations with(nolock) 
INNER JOIN [DWH_staging].[fiktivo_AffiliateCommission_RegistrationCommission] RC 
ON Registrations.RegistrationID = RC.RegistrationID 
AND RC.Tier=1
WHERE Registrations.RegistrationDate < dateadd(day,datediff(day,0,GETDATE()),0)
group by Registrations.AffiliateID --,Registrations.CID

--SELECT 
--tblCommissions.AffiliateID
--,min(Registrations.ORDER_DATE)  RegistrationFirstDate
--,max(Registrations.ORDER_DATE)  RegistrationLastDate
--,Count(Registrations.RegistrationID) AS RegistrationLifeTime
--,sum(case when Registrations.ORDER_DATE >= dateadd(day,datediff(day,1,GETDATE()),0) and Registrations.ORDER_DATE < dateadd(day,datediff(day,0,GETDATE()),0) then  1 else 0 end) AS RegistrationYesterday
--,sum(case when Registrations.ORDER_DATE > EOMONTH(DATEADD(mm,-2,getdate())) and Registrations.ORDER_DATE < DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS RegistrationLastMonth
--,sum(case when Registrations.ORDER_DATE >= DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) -1, 0) and Registrations.ORDER_DATE < DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS RegistrationLastQuarter
--,sum(case when Registrations.ORDER_DATE >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) and Registrations.ORDER_DATE < DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS RegistrationLastYear
--,sum(case when Registrations.ORDER_DATE >= DATEADD(month, DATEDIFF(month, 0, getdate()), 0) then  1 else 0 end) AS RegistrationThisMonth
--,sum(case when Registrations.ORDER_DATE >= DATEADD(qq, DATEDIFF(qq, -1, GETDATE()) -1, 0) then  1 else 0 end) AS RegistrationThisQuarter
--,sum(case when Registrations.ORDER_DATE >= DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) then  1 else 0 end) AS RegistrationThisYear
--FROM [DWH_staging].[fiktivo_dbo_tblaff_Registrations] Registrations with(nolock)
--LEFT JOIN [DWH_staging].[fiktivo_dbo_tblaff_Registrations_Commissions] tblCommissions with(nolock)	ON Registrations.RegistrationID = tblCommissions.RegistrationID
--WHERE tblCommissions.Tier=1 and Registrations.ORDER_DATE < dateadd(day,datediff(day,0,GETDATE()),0)
--group by tblCommissions.AffiliateID

EXEC [DWH_dbo].SP_Dim_Affiliate

--------------------
TRUNCATE TABLE [DWH_dbo].[Dim_BonusType]

INSERT INTO [DWH_dbo].[Dim_BonusType]
           ([BonusTypeID]
           ,[Name]
           ,[IsWithdrawable]
           ,[IsActive]
           ,[DWHBonusTypeID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
SELECT BonusTypeID,
	   Name,
	   IsWithdrawable,
	   IsActive,
	   BonusTypeID AS DWHBonusTypeID,
	   1 as StatusID,
	   GETDATE() as UpdateDate,
	   GETDATE() as InsertDate
FROM [DWH_staging].[etoro_BackOffice_BonusType]

--------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_EvMatchStatus]

INSERT INTO [DWH_dbo].[Dim_EvMatchStatus](
[EvMatchStatusID]
,[EvMatchStatusName]
,[UpdateDate]
)
SELECT 
[EvMatchStatusId]
,[Name]
,getdate()
FROM [DWH_staging].[UserApiDB_Dictionary_EvMatchStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_ExtendedUserField]

INSERT INTO [DWH_dbo].[Dim_ExtendedUserField]
([FieldID]
,[FieldTypeID]
,[ExtendedUserFieldName]
,[UpdateDate])
SELECT 
[FieldId]
,[FieldTypeId]
,[Name]
,getdate()
FROM [DWH_staging].[UserApiDB_Dictionary_ExtendedUserField]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_VerificationStatus]

INSERT INTO [DWH_dbo].[Dim_VerificationStatus]
([VerificationStatusID]
,[Name]
,[UpdateDate])
SELECT 
[VerificationStatusID]
,[Name]
,getdate()
FROM [DWH_staging].[UserApiDB_Dictionary_VerificationStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_AccountStatus]

INSERT INTO [DWH_dbo].[Dim_AccountStatus]
([AccountStatusID]
,[AccountStatusName]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[AccountStatusID]
,[AccountStatusName]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_AccountStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_AccountType]

INSERT INTO [DWH_dbo].[Dim_AccountType]
([AccountTypeID]
,[Name]
,[DWHAccountTypeID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[AccountTypeID]
,[AccountTypeName]
,[AccountTypeID] as [DWHAccountTypeID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_AccountType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CashoutFeeGroup]

INSERT INTO [DWH_dbo].[Dim_CashoutFeeGroup]
([CashoutFeeGroupID]
,[CashoutFeeGroupName]
,[UpdateDate])
SELECT 
[CashoutFeeGroupID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CashoutFeeGroup]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CashoutStatus]

INSERT INTO [DWH_dbo].[Dim_CashoutStatus]
([CashoutStatusID]
,[Name]
,[DWHCashoutStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[CashoutStatusID]
,[Name]
,[CashoutStatusID] as [DWHCashoutStatusID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CashoutStatus]


TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Channel]

INSERT INTO [DWH_dbo].[Ext_Dim_Channel]
           ([AffiliateID]
           ,[DateCreated]
           ,[MarketingExpenseID]
           ,[MarketingExpenseName]
           ,[Contact]
           ,[AffiliatesGroupsName]
           ,[ContractName]
           ,[Channel]
           ,[newContact])
select a.AffiliateID
,a.DateCreated
,a.MarketingExpenseID 
,b.MarketingExpenseName 
,a.Contact 
,c.AffiliatesGroupsName 
,[Description] as ContractName
,CASE
WHEN isnull(b.MarketingExpenseName,'Direct')='Direct' and c.AffiliatesGroupsName='Friend Referral' then 'Friend Referral'
WHEN b.MarketingExpenseName in('Mobile media') then 'Mobile Acquisition' --New channel add by Sivan 20190331
WHEN b.MarketingExpenseName in('Media') then 'Media'				
WHEN c.AffiliatesGroupsName='Mobile' then 'Direct'
WHEN b.MarketingExpenseName = 'SMM' then 'Direct'
WHEN b.MarketingExpenseName = 'RAF' then 'Friend Referral'
WHEN a.AffiliateID in (0) then 'Direct' 
WHEN b.MarketingExpenseName in('Networks','Offline Partners','Local Offices','Local Partners') then 'Affiliate'
ELSE isnull(b.MarketingExpenseName,'Direct')
END AS Channel
,replace(lower(a.Contact) ,'nonbrand','paid') as newContact 
FROM [DWH_staging].[fiktivo_dbo_tblaff_Affiliates] a
left join [DWH_staging].[fiktivo_dbo_tblaff_MarketingExpense] b  on a.MarketingExpenseID=b.MarketingExpenseID
left join [DWH_staging].[fiktivo_dbo_tblaff_AffiliatesGroups] c  on a.AffiliatesGroupsID = c.AffiliatesGroupsID
left join [DWH_staging].[fiktivo_dbo_tblaff_AffiliateTypes] afftype  on a.[AffiliateTypeID]=afftype.[AffiliateTypeID]
----------------------------------------------
Exec [DWH_dbo].[SP_Dim_Channel]

--------

TRUNCATE TABLE [DWH_dbo].[Dim_ClientWithdrawReason]

INSERT INTO [DWH_dbo].[Dim_ClientWithdrawReason]
([ClientWithdrawReasonID]
,[ClientWithdrawReasonName]
,[UpdateDate])
SELECT 
[ClientWithdrawReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_ClientWithdrawReason]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_ClosePositionReason]

INSERT INTO [DWH_dbo].[Dim_ClosePositionReason]
([ClosePositionReasonID]
,[Name]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[ID]
,[ClosePositionActionName]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_ClosePositionActionType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CountryBin]

INSERT INTO [DWH_dbo].[Dim_CountryBin]
([CountryID]
,[BinCode]
,[IssuingBank]
,[CardTypeID]
,[CardSubType]
,[CardCategory]
,[BankWebSite]
,[BankInfo]
,[ShouldCheck3ds]
,[MinAmountFor3ds]
,[IsPrepaid]
,[UpdateDate])
SELECT 
[CountryID]
,[BinCode]
,[IssuingBank]
,[CardTypeID]
,[CardSubType]
,[CardCategory]
,[BankWebSite]
,[BankInfo]
,[ShouldCheck3ds]
,[MinAmountFor3ds]
,[IsPrepaid]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CountryBin]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CountryIP]

INSERT INTO [DWH_dbo].[Dim_CountryIP]
([CountryID]
,[IPFrom]
,[IPTo]
,[RegionID]
,[UpdateDate])
SELECT 
[CountryID]
,[IPFrom]
,[IPTo]
,[RegionID]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CountryIP]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CreditType]

INSERT INTO [DWH_dbo].[Dim_CreditType]
([CreditTypeID]
,[CreditTypeName]
,[UpdateDate])
SELECT 
[CreditTypeID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CreditType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Currency]

INSERT INTO [DWH_dbo].[Dim_Currency]
([CurrencyID]
,[CurrencyTypeID]
,[Name]
,[Abbreviation]
,[Mask]
,[EEAStockExchange]
,[ISINCode]
,[CurrencySymbol]
,[InterestRateID]
,[UpdateDate])
SELECT 
[CurrencyID]
,[CurrencyTypeID]
,[Name]
,[Abbreviation]
,[Mask]
,[EEAStockExchange]
,[ISINCode]
,[CurrencySymbol]
,[InterestRateID]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_Currency]


----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_BillingDepot]

INSERT INTO [DWH_dbo].[Dim_BillingDepot]
           ([DepotID]
           ,[FundingTypeID]
           ,[PaymentTypeID]
           ,[ProtocolID]
           ,[Name]
           ,[IsActive]
           ,[UpdateDate])
select 
[DepotID]
,[FundingTypeID]
,[PaymentTypeID]
,[ProtocolID]
,[Name]
,[IsActive]
, getdate() as UpdateDate
 FROM [DWH_staging].[etoro_Billing_Depot]


----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_DocumentStatus]

INSERT INTO [DWH_dbo].[Dim_DocumentStatus]
([DocumentStatusID]
,[DocumentStatusName]
,[UpdateDate])
SELECT 
[DocumentStatusID]
,[DocumentStatusName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_DocumentStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_ExchangeInfo]

INSERT INTO [DWH_dbo].[Dim_ExchangeInfo]
([ExchangeID]
,[ExchangeDescription]
,[UpdateDate])
SELECT 
[ExchangeID]
,[ExchangeDescription]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_ExchangeInfo]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_FundType]

INSERT INTO [DWH_dbo].[Dim_FundType]
([FundTypeID]
,[FundTypeName]
,[UpdateDate])
SELECT 
[FundTypeID]
,[Description]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_FundType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Fund]

INSERT INTO [DWH_dbo].[Dim_Fund]
           ([FundID]
           ,[FundName]
           ,[FundAccountID]
           ,[FundOwnerID]
           ,[IsPublic]
           ,[MinCopyAmount]
           ,[RefreshIntervalMonths]
           ,[FundType]
           ,[UpdateDate])

SELECT [FundID]
      ,[FundName]
      ,[FundAccountID]
      ,[FundOwnerID]
      ,[IsPublic]
      ,[MinCopyAmount]
      ,[RefreshIntervalMonths]
      ,[FundType]
 ,getdate() as UpdateDate
from 
[DWH_staging].[etoro_Trade_Fund]
----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_FundingType]

INSERT INTO [DWH_dbo].[Dim_FundingType]
([FundingTypeID]
,[Name]
,[IsNewStyle]
,[IsSingleFunding]
,[IsCashoutActive]
,[DWHFundingTypeID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[FundingTypeID]
,[Name]
,[IsNewStyle]
,[IsSingleFunding]
,[IsCashoutActive]
,[FundingTypeID] as [DWHFundingTypeID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_FundingType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Funnel]

INSERT INTO [DWH_dbo].[Dim_Funnel]
([FunnelID]
,[Name]
,[PlatformID]
,[UpdateDate]
,[InsertDate]
,[StatusID])
SELECT 
[FunnelID]
,[Name]
,[PlatformID]
,getdate()
,getdate()
,1 as StatusID
FROM [DWH_staging].[etoro_Dictionary_Funnel]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_GuruStatus]

INSERT INTO [DWH_dbo].[Dim_GuruStatus]
([GuruStatusID]
,[GuruStatusName]
,[UpdateDate])
SELECT 
[GuruStatusID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_GuruStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Label]

INSERT INTO [DWH_dbo].[Dim_Label]
([LabelID]
,[Name]
,[DWHLabelID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[LabelID]
,[Name]
,[LabelID] as[DWHLabelID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_Label]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Language]

INSERT INTO [DWH_dbo].[Dim_Language]
([LanguageID]
,[Name]
,[DWHLanguageID]
,[StatusID]
,[UpdateDate]
,[InsertDate]
,[IsoCode]
,[CultureCode])
SELECT 
[LanguageID]
,[Name]
,[LanguageID] as [DWHLanguageID]
,1 as StatusID
,getdate()
,getdate()
,[IsoCode]
,[CultureCode]
FROM [DWH_staging].[etoro_Dictionary_Language]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Ext_Dim_Manager]

INSERT INTO [DWH_dbo].[Ext_Dim_Manager]
           ([ManagerID]
           ,[UserGroup]
           ,[ParentUserGroup]
           ,[FirstName]
           ,[LastName]
           ,[IsActive]
           ,[IsTeamLeader]
           ,[DWHManagerID]
           ,[StatusID]
           ,[CalendlyID])
select ManagerID,'Not Available' as UserGroup,'Not Available' as ParentUserGroup,FirstName,LastName,IsActive,IsTeamLeader, 
ManagerID as DWHManagerID, 1 as StatusID
,CalendlyID
from [DWH_staging].[etoro_BackOffice_Manager]

UPDATE 
 A 
SET FirstName=B.FirstName,
 LastName=B.LastName,
 IsTeamLeader=B.IsTeamLeader,
 IsActive=B.IsActive,
CalendlyID = B.CalendlyID,
 UpdateDate=GETDATE()
FROM 
 [DWH_dbo].[Dim_Manager] A
 INNER JOIN
[DWH_dbo].[Ext_Dim_Manager] B
 ON A.ManagerID=B.ManagerID

 INSERT INTO  [DWH_dbo].[Dim_Manager]
 (ManagerID,UserGroup,ParentUserGroup,FirstName,
 LastName,IsActive,IsTeamLeader,DWHManagerID,
 UpdateDate,InsertDate,StatusID,CalendlyID)
SELECT b.ManagerID,
b.UserGroup,
b.ParentUserGroup,
b.FirstName,
b.LastName,
b.IsActive,
b.IsTeamLeader,
b.ManagerID,
GETDATE() as UpdateDate,
GETDATE() as InsertDate,
1 as StatusID,
b.CalendlyID
FROM  [DWH_dbo].[Dim_Manager] a
right JOIN 
 [DWH_dbo].[Ext_Dim_Manager] b
ON(a.ManagerID=b.ManagerID)
WHERE a.ManagerID IS null

update DWH_dbo.Dim_Manager
set 
[SFManagerID] = b.[SFManagerID]
from DWH_dbo.Dim_Manager a
join [DWH_staging].[SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping] b
on a.ManagerID = b.[ManagerID]
where a.ManagerID not in (0,1)
----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_MifidCategorization]

INSERT INTO [DWH_dbo].[Dim_MifidCategorization]
([MifidCategorizationID]
,[Name]
,[UpdateDate])
SELECT 
[MifidCategorizationID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_MifidCategorization]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_MirrorType]

INSERT INTO [DWH_dbo].[Dim_MirrorType]
([MirrorTypeID]
,[MirrorTypeName]
,[UpdateDate])
SELECT 
[MirrorTypeID]
,[MirrorTypeName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_MirrorType]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PaymentStatus]

INSERT INTO [DWH_dbo].[Dim_PaymentStatus]
([PaymentStatusID]
,[Name]
,[DWHPaymentStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT
[PaymentStatusID]
,[Name]
,[PaymentStatusID] as [DWHPaymentStatusID]
,1 as StatusID
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PaymentStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PendingClosureStatus]

INSERT INTO [DWH_dbo].[Dim_PendingClosureStatus]
([PendingClosureStatusID]
,[PendingClosureStatusName]
,[UpdateDate])
SELECT 
[PendingClosureStatusID]
,[PendingClosureStatusName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PendingClosureStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PhoneVerified]

INSERT INTO [DWH_dbo].[Dim_PhoneVerified]
([PhoneVerifiedID]
,[PhoneVerifiedName]
,[UpdateDate])
SELECT 
[PhoneVerifiedID]
,[PhoneVerifiedName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PhoneVerified]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Platform]

INSERT INTO [DWH_dbo].[Dim_Platform]
([PlatformID]
,[Platform]
,[UpdateDate])
SELECT 
[Id]
,[Platform]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_Platform]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PlayerLevel]

INSERT INTO [DWH_dbo].[Dim_PlayerLevel]
([PlayerLevelID]
,[Name]
,[CashoutPendingHours]
,[FromSumLotCount]
,[ToSumLotCount]
,[FromSumDeposit]
,[ToSumDeposit]
,[Sort]
,[DWHPlayerLevelID]
,[UpdateDate]
,[InsertDate]
,[StatusID])
SELECT 
[PlayerLevelID]
,[Name]
,[CashoutPendingHours]
,[FromSumLotCount]
,[ToSumLotCount]
,[FromSumDeposit]
,[ToSumDeposit]
,[Sort]
, [PlayerLevelID] as  [DWHPlayerLevelID]
,getdate()
,getdate()
,1 as [StatusID]
FROM [DWH_staging].[etoro_Dictionary_PlayerLevel]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PlayerStatus]

INSERT INTO [DWH_dbo].[Dim_PlayerStatus]
([PlayerStatusID]
,[Name]
,[IsBlocked]
,[CanEditPosition]
,[CanOpenPosition]
,[CanClosePosition]
,[CanDeposit]
,[CanRequestWithdraw]
,[CanLogin]
,[CanChatAndPost]
,[CanBeCopied]
,[DWHPlayerStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[PlayerStatusID]
,[Name]
,[IsBlocked]
,[CanEditPosition]
,[CanOpenPosition]
,[CanClosePosition]
,[CanDeposit]
,[CanRequestWithdraw]
,[CanLogin]
,[CanChatAndPost]
,[CanBeCopied]
,[PlayerStatusID] as [DWHPlayerStatusID]
,1 as [StatusID]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PlayerStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PlayerStatusReasons]

INSERT INTO [DWH_dbo].[Dim_PlayerStatusReasons]
([PlayerStatusReasonID]
,[Name]
,[UpdateDate])
SELECT 
[PlayerStatusReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PlayerStatusReasons]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_PlayerStatusSubReasons]

INSERT INTO [DWH_dbo].[Dim_PlayerStatusSubReasons]
([PlayerStatusSubReasonID]
,[PlayerStatusSubReasonName]
,[UpdateDate])
SELECT 
[PlayerStatusSubReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_PlayerStatusSubReasons]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RedeemReason]

INSERT INTO [DWH_dbo].[Dim_RedeemReason]
([RedeemReasonID]
,[RedeemReasonName]
,[UpdateDate])
SELECT 
[RedeemReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RedeemReason]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RedeemStatus]

INSERT INTO [DWH_dbo].[Dim_RedeemStatus]
([RedeemStatusID]
,[Name]
,[DisplayName]
,[IsCancelable]
,[InsertDate]
,[UpdateDate])
SELECT 
[RedeemStatusID]
,[Name]
,[DisplayName]
,[IsCancelable]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RedeemStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_BillingProtocolMIDSettingsID]

INSERT INTO [DWH_dbo].[Dim_BillingProtocolMIDSettingsID]
           ([ProtocolMIDSettingsID]
           ,[ParameterID]
           ,[DepotID]
           ,[DepotModeID]
           ,[Value]
           ,[RegulationID]
           ,[CurrencyID]
           ,[Description]
           ,[SubTypeID]
           ,[MerchantAccountID]
           ,[UpdateDate])
SELECT 
ID AS ProtocolMIDSettingsID,
ParameterID,
DepotID,
DepotModeID,
Value,
RegulationID,
CurrencyID,
Description,
SubTypeID,
MerchantAccountID,
GETDATE() AS UpdateDate
FROM [DWH_staging].[etoro_Billing_ProtocolMIDSettings]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_Campaign]

--INSERT INTO [DWH_dbo].[Dim_Campaign]
--           ([CampaignID]
--           ,[CampaignGroupID]
--           ,[Code]
--           ,[MaxNumberOfUsers]
--           ,[StartDate]
--           ,[EndDate]
--           ,[MaxBonusAmount]
--           ,[IsActive]
--           ,[ParticipatedUsers]
--           ,[Description]
--           ,[InsertDate]
--           ,[UpdateDate])
--SELECT [CampaignID]
--      ,[CampaignGroupID]
--      ,[Code]
--      ,[MaxNumberOfUsers]
--      ,[StartDate]
--      ,[EndDate]
--      ,[MaxBonusAmount]
--      ,[IsActive]
--      ,[ParticipatedUsers]
--      ,[Description]
--      ,GETDATE() as InsertDate
--      ,GETDATE() as UpdateDate
--  FROM [DWH_staging].[etoro_BackOffice_Campaign]

-------------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CashoutMode]

INSERT INTO [DWH_dbo].[Dim_CashoutMode]
           ([CashoutModeID]
           ,[CashoutModeName]
           ,[CashoutModeWeight]
           ,[UpdateDate])
SELECT [CashoutModeID]
      ,[CashoutModeName]
      ,[CashoutModeWeight]
	  ,getdate()
  FROM [DWH_staging].[etoro_Dictionary_CashoutMode]

-------------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CashoutReason]

INSERT INTO [DWH_dbo].[Dim_CashoutReason]
([CashoutReasonID]
,[Name]
,[UpdateDate])
SELECT [CashoutReasonID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_CashoutReason]


-------------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_State_and_Province]

INSERT INTO [DWH_dbo].[Dim_State_and_Province]
           ([RegionByIP_ID]
           ,[CountryID]
           ,[ShortName]
           ,[Name]
           ,[UpdateDate])
select 
rei.RegionByIP_ID,
ren.CountryID,
ren.ShortName,
ren.Name,
getdate() as UpdateDate
from [DWH_staging].[etoro_Dictionary_RegionByIP] as rei 
Join [DWH_staging].[etoro_Dictionary_RegionName] as ren
On rei.Name = ren.ShortName  and rei.CountryID=ren.CountryID

-------------------------------------------------

-- TRUNCATE TABLE [DWH_dbo].[Dim_PEPStatus]
-- INSERT INTO [DWH_dbo].[Dim_PEPStatus]
--           ([PEPStatusID]
--           ,[Name]
--           ,[UpdateDate])
-- SELECT [ID] AS PEPStatusID
--      ,[Name]
--      , getdate() as UpdateDate
--  FROM [DWH_staging].[Dim_PEPStatus]

 ----------------------------------------------
TRUNCATE TABLE [DWH_dbo].[Dim_Regulation]

INSERT INTO [DWH_dbo].[Dim_Regulation]
([ID]
,[Name]
,[DWHRegulationID]
,[StatusID]
,[UpdateDate]
,[InsertDate]
,[ClusterRegulationID])
SELECT 
[ID]
,[Name]
,[ID] as [DWHRegulationID]
,1 as [StatusID]
,getdate()
,getdate()
,CASE WHEN ID in (0,1,5) THEN 1 ELSE ID END as ClusterRegulationID
FROM [DWH_staging].[etoro_Dictionary_Regulation]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RiskClassification]

INSERT INTO [DWH_dbo].[Dim_RiskClassification]
([RiskClassificationID]
,[RiskClassificationName]
,[RiskScore]
,[UpdateDate])
SELECT 
[RiskClassificationID]
,[Name]
,[RiskScore]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RiskClassification]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RiskManagementStatus]

INSERT INTO [DWH_dbo].[Dim_RiskManagementStatus]
([RiskManagementStatusID]
,[Name]
,[DWHRiskManagementStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[RiskManagementStatusID]
,[Name]
, [RiskManagementStatusID] as [DWHRiskManagementStatusID]
,1 as [StatusID]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RiskManagementStatus]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_RiskStatus]

INSERT INTO [DWH_dbo].[Dim_RiskStatus]
([RiskStatusID]
,[Name]
,[IsActive]
,[DWHRiskStatusID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[RiskStatusID]
,[Name]
,[IsActive]
,[RiskStatusID] as [DWHRiskStatusID]
,1 as [StatusID]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_RiskStatus]
   
----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_ThreeDsResponseTypes]

INSERT INTO [DWH_dbo].[Dim_ThreeDsResponseTypes]
([ThreeDsResponseTypeID]
,[ThreeDsResponseTypesName]
,[UpdateDate])
SELECT 
[ThreeDsResponseTypeID]
,[Name]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_ThreeDsResponseTypes]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_VerificationLevel]

INSERT INTO [DWH_dbo].[Dim_VerificationLevel]
([ID]
,[Name]
,[DWHVerificationLevelID]
,[StatusID]
,[UpdateDate]
,[InsertDate])
SELECT 
[ID]
,[Name]
,[ID] as [DWHVerificationLevelID]
,1 as [StatusID]
,getdate()
,getdate()
FROM [DWH_staging].[etoro_Dictionary_VerificationLevel]

----------------------------------------------

TRUNCATE TABLE [DWH_dbo].[Dim_WorldCheck]

INSERT INTO [DWH_dbo].[Dim_WorldCheck]
([WorldCheckID]
,[WorldCheckName]
,[UpdateDate])
SELECT 
[WorldCheckID]
,[WorldCheckName]
,getdate()
FROM [DWH_staging].[etoro_Dictionary_WorldCheck]


--------------------

TRUNCATE TABLE [DWH_dbo].[Dim_CompensationReason]

INSERT INTO [DWH_dbo].[Dim_CompensationReason]
	  ([CompensationReasonID]
      ,[ParentID]
      ,[Name]
	  ,[DWHCompensationID]
	  ,[StatusID]
	  ,[UpdateDate]
	  ,[InsertDate])
SELECT [CompensationReasonID]
      ,[ParentID]
      ,[Name]
      ,[CompensationReasonID]
	  ,1
	  ,getdate()
	  ,getdate()
  FROM [DWH_staging].[etoro_BackOffice_CompensationReason]

TRUNCATE TABLE [DWH_dbo].[Dim_ScreeningStatus]

INSERT INTO [DWH_dbo].[Dim_ScreeningStatus]
           ([ScreeningStatusID]
           ,[Name]
           ,[UpdateDate])
SELECT [ID]
      ,[Name]
	  ,getdate()
  FROM [DWH_staging].[ScreeningService_Dictionary_ScreeningStatus]


----------------------------------HistoryCosts-----------------------------------------
TRUNCATE TABLE [DWH_dbo].[Dim_CalculationType]

INSERT INTO [DWH_dbo].[Dim_CalculationType](
[CalculationTypeId],
[CalculationType],
[UpdateDate])
SELECT 
[Id],
[CalculationType],
getdate()
FROM [DWH_staging].[HistoryCosts_Dictionary_CalculationType]

TRUNCATE TABLE [DWH_dbo].[Dim_CostConfigurationId]

INSERT INTO [DWH_dbo].[Dim_CostConfigurationId](
[CostConfigurationId],
[CostConfiguration],
[UpdateDate])
SELECT 
[Id],
[CostConfigurationId],
getdate()
FROM [DWH_staging].[HistoryCosts_Dictionary_CostConfigurationId]

TRUNCATE TABLE [DWH_dbo].[Dim_CostSubtype]

INSERT INTO [DWH_dbo].[Dim_CostSubtype](
[CostSubtypeId],
[CostSubtype],
[UpdateDate])
SELECT 
[Id],
[CostSubtype],
getdate()
FROM [DWH_staging].[HistoryCosts_Dictionary_CostSubtype]


TRUNCATE TABLE [DWH_dbo].[Dim_CostType]

INSERT INTO [DWH_dbo].[Dim_CostType](
[CostTypeId],
[CostType],
[UpdateDate])
SELECT 
[Id],
[CostType],
getdate()
FROM [DWH_staging].[HistoryCosts_Dictionary_CostType]

TRUNCATE TABLE [DWH_dbo].[Dim_ExecutionOperationType]

INSERT INTO [DWH_dbo].[Dim_ExecutionOperationType](
[OperationTypeId],
[OperationType],
[UpdateDate])
SELECT 
[Id],
[OperationType],
getdate()
FROM [DWH_staging].HistoryCosts_Dictionary_ExecutionOperationType

INSERT INTO [DWH_dbo].[Dim_FeeOperationTypes](
[FeeOperationTypeID],
[FeeOperationTypeName],
[UpdateDate])
SELECT 
[FeeOperationTypeID],
[Name],
getdate()
FROM [DWH_staging].etoro_Dictionary_FeeOperationTypes
---------------------------------------------------------------------------

---- iNSERT DEFAULT VALUES 0
DECLARE @ddate date = cast(getdate() as date)

INSERT INTO [DWH_dbo].[Dim_AccountStatus]
           ([AccountStatusID]
           ,[AccountStatusName]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
           (0
           ,'N/A'
           ,1
           ,@ddate
           ,@ddate
		   )
---------------------

INSERT INTO [DWH_dbo].[Dim_AccountType]
           ([AccountTypeID]
           ,[Name]
           ,[DWHAccountTypeID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
           (0
           ,'N/A'
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )

-------------


INSERT INTO [DWH_dbo].[Dim_BonusType]
           ([BonusTypeID]
           ,[Name]
           ,[IsWithdrawable]
           ,[IsActive]
           ,[DWHBonusTypeID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
		   (0
           ,'N/A'
		   ,0
		   ,0
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )

----------------


INSERT INTO [DWH_dbo].[Dim_FundingType]
           ([FundingTypeID]
           ,[Name]
           ,[IsNewStyle]
           ,[IsSingleFunding]
           ,[IsCashoutActive]
           ,[DWHFundingTypeID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
		   (0
           ,'N/A'
		   ,0
		   ,0
		   ,0
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )
-------------

INSERT INTO [DWH_dbo].[Dim_Language]
           ([LanguageID]
           ,[Name]
           ,[DWHLanguageID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate]
           ,[IsoCode]
           ,[CultureCode])
     VALUES
          (0
           ,'N/A'
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   ,'N/A'
		   ,'N/A'
		   )

 --------------
INSERT INTO [DWH_dbo].[Dim_PaymentStatus]
           ([PaymentStatusID]
           ,[Name]
           ,[DWHPaymentStatusID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
	VALUES
			(-1
           ,'N/A'
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )

 --------------


INSERT INTO [DWH_dbo].[Dim_PlayerLevel]
           ([PlayerLevelID]
           ,[Name]
           ,[CashoutPendingHours]
           ,[FromSumLotCount]
           ,[ToSumLotCount]
           ,[FromSumDeposit]
           ,[ToSumDeposit]
           ,[Sort]
           ,[DWHPlayerLevelID]
           ,[UpdateDate]
           ,[InsertDate]
           ,[StatusID])
     VALUES
			(0
           ,'N/A'
		   ,0
           ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
           ,@ddate
           ,@ddate
		   ,1
		   )

---------------

INSERT INTO [DWH_dbo].[Dim_PlayerStatus]
           ([PlayerStatusID]
           ,[Name]
           ,[IsBlocked]
           ,[CanEditPosition]
           ,[CanOpenPosition]
           ,[CanClosePosition]
           ,[CanDeposit]
           ,[CanRequestWithdraw]
           ,[CanLogin]
           ,[CanChatAndPost]
           ,[CanBeCopied]
           ,[DWHPlayerStatusID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
			(0
           ,'N/A'
		   ,0
           ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,0
		   ,1
           ,@ddate
           ,@ddate
		   )
-------------


INSERT INTO [DWH_dbo].[Dim_RedeemStatus]
           ([RedeemStatusID]
           ,[Name]
           ,[DisplayName]
           ,[IsCancelable]
           ,[InsertDate]
           ,[UpdateDate])
	VALUES
		   (0
           ,'N/A'
		   ,'N/A'
           ,1
           ,@ddate
           ,@ddate
		   )

-----


INSERT INTO [DWH_dbo].[Dim_RiskManagementStatus]
           ([RiskManagementStatusID]
           ,[Name]
           ,[DWHRiskManagementStatusID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
			(0
           ,'N/A'
		   ,0
           ,1
           ,@ddate
           ,@ddate
		   )

-------


INSERT INTO [DWH_dbo].[Dim_CompensationReason]
           ([CompensationReasonID]
           ,[ParentID]
           ,[Name]
           ,[DWHCompensationID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
           (0
		   ,Null
           ,'N/A'
		   ,0
		   ,1
           ,@ddate
		   ,@ddate
		   )


-----------------

INSERT INTO [DWH_dbo].[Dim_CashoutStatus]
           ([CashoutStatusID]
           ,[Name]
           ,[DWHCashoutStatusID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
			(0
           ,'N/A'
		   ,0
		   ,1
           ,@ddate
		   ,@ddate
		   )


-------------------


INSERT INTO [DWH_dbo].[Dim_Campaign]
           ([CampaignID]
           ,[CampaignGroupID]
           ,[Code]
           ,[MaxNumberOfUsers]
           ,[StartDate]
           ,[EndDate]
           ,[MaxBonusAmount]
           ,[IsActive]
           ,[ParticipatedUsers]
           ,[Description]
           ,[InsertDate]
           ,[UpdateDate])
     VALUES
			(0
		   ,NULL
           ,'N/A'
		   ,0
		   ,'1900-01-01 00:00:00.000'
		   ,'1900-01-01 00:00:00.000'
		   ,0.00
		   ,0
		   ,0
		   ,NULL
           ,@ddate
		   ,@ddate
		   )

------------------

INSERT INTO [DWH_dbo].[Dim_VerificationLevel]
           ([ID]
           ,[Name]
           ,[DWHVerificationLevelID]
           ,[StatusID]
           ,[UpdateDate]
           ,[InsertDate])
     VALUES
		   (-1
           ,'N/A'
		   ,-1
		   ,1
           ,@ddate
		   ,@ddate
		   )

--------------------------
DECLARE @MaxFullDate DATE 
DECLARE @StartDate DATE 
DECLARE @EndDate DATE
SELECT  @MaxFullDate = max(FullDate) FROM  [DWH_dbo].[Dim_Date]


IF DATEDIFF(YEAR,GETDATE(),@MaxFullDate)<=1
BEGIN
	SELECT @StartDate =  DATEADD(DAY,1,@MaxFullDate)
	SELECT  @EndDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY,365,@StartDate)) + 1, -1) 
	EXEC [DWH_dbo].[SP_PopulateDimDate] @StartDate,@EndDate
END 





  END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason | `—` |
| `Dictionary.CashoutReason` | production | Dictionary | CashoutReason | `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Dictionary\Tables\Dictionary.CashoutReason.md` |
| `DWH_dbo.SP_Dictionaries_DL_To_Synapse` | synapse_sp | DWH_dbo | SP_Dictionaries_DL_To_Synapse | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dictionaries_DL_To_Synapse.sql` |
| `DWH_staging.fiktivo_dbo_tblaff_Affiliates` | unresolved | DWH_staging | fiktivo_dbo_tblaff_Affiliates | `—` |
| `DWH_staging.fiktivo_dbo_tblaff_MarketingExpense` | unresolved | DWH_staging | fiktivo_dbo_tblaff_MarketingExpense | `—` |
| `DWH_staging.fiktivo_dbo_tblaff_AffiliatesGroups` | unresolved | DWH_staging | fiktivo_dbo_tblaff_AffiliatesGroups | `—` |
| `DWH_staging.fiktivo_dbo_tblaff_AffiliateTypes` | unresolved | DWH_staging | fiktivo_dbo_tblaff_AffiliateTypes | `—` |
| `DWH_staging.fiktivo_dbo_tblaff_PaymentDetails` | unresolved | DWH_staging | fiktivo_dbo_tblaff_PaymentDetails | `—` |
| `DWH_staging.fiktivo_dbo_tblaff_Languages` | unresolved | DWH_staging | fiktivo_dbo_tblaff_Languages | `—` |
| `DWH_staging.etoro_Customer_Customer` | unresolved | DWH_staging | etoro_Customer_Customer | `—` |
| `DWH_staging.fiktivo_AffiliateCommission_Credit` | unresolved | DWH_staging | fiktivo_AffiliateCommission_Credit | `—` |
| `DWH_staging.fiktivo_AffiliateCommission_CreditCommission` | unresolved | DWH_staging | fiktivo_AffiliateCommission_CreditCommission | `—` |
| `DWH_staging.fiktivo_dbo_tblaff_Tier2Members` | unresolved | DWH_staging | fiktivo_dbo_tblaff_Tier2Members | `—` |
| `DWH_staging.fiktivo_AffiliateCommission_Registration` | unresolved | DWH_staging | fiktivo_AffiliateCommission_Registration | `—` |
| `DWH_staging.fiktivo_AffiliateCommission_RegistrationCommission` | unresolved | DWH_staging | fiktivo_AffiliateCommission_RegistrationCommission | `—` |
| `DWH_staging.etoro_BackOffice_BonusType` | unresolved | DWH_staging | etoro_BackOffice_BonusType | `—` |
| `DWH_staging.UserApiDB_Dictionary_EvMatchStatus` | unresolved | DWH_staging | UserApiDB_Dictionary_EvMatchStatus | `—` |
| `DWH_staging.UserApiDB_Dictionary_ExtendedUserField` | unresolved | DWH_staging | UserApiDB_Dictionary_ExtendedUserField | `—` |
| `DWH_staging.UserApiDB_Dictionary_VerificationStatus` | unresolved | DWH_staging | UserApiDB_Dictionary_VerificationStatus | `—` |
| `DWH_staging.etoro_Dictionary_AccountStatus` | unresolved | DWH_staging | etoro_Dictionary_AccountStatus | `—` |
| `DWH_staging.etoro_Dictionary_AccountType` | unresolved | DWH_staging | etoro_Dictionary_AccountType | `—` |
| `DWH_staging.etoro_Dictionary_CashoutFeeGroup` | unresolved | DWH_staging | etoro_Dictionary_CashoutFeeGroup | `—` |
| `DWH_staging.etoro_Dictionary_CashoutStatus` | unresolved | DWH_staging | etoro_Dictionary_CashoutStatus | `—` |
| `DWH_staging.etoro_Dictionary_ClientWithdrawReason` | unresolved | DWH_staging | etoro_Dictionary_ClientWithdrawReason | `—` |
| `DWH_staging.etoro_Dictionary_ClosePositionActionType` | unresolved | DWH_staging | etoro_Dictionary_ClosePositionActionType | `—` |
| `DWH_staging.etoro_Dictionary_CountryBin` | unresolved | DWH_staging | etoro_Dictionary_CountryBin | `—` |
| `DWH_staging.etoro_Dictionary_CountryIP` | unresolved | DWH_staging | etoro_Dictionary_CountryIP | `—` |
| `DWH_staging.etoro_Dictionary_CreditType` | unresolved | DWH_staging | etoro_Dictionary_CreditType | `—` |
| `DWH_staging.etoro_Dictionary_Currency` | unresolved | DWH_staging | etoro_Dictionary_Currency | `—` |
| `DWH_staging.etoro_Billing_Depot` | unresolved | DWH_staging | etoro_Billing_Depot | `—` |
| `DWH_staging.etoro_Dictionary_DocumentStatus` | unresolved | DWH_staging | etoro_Dictionary_DocumentStatus | `—` |
| `DWH_staging.etoro_Dictionary_ExchangeInfo` | unresolved | DWH_staging | etoro_Dictionary_ExchangeInfo | `—` |
| `DWH_staging.etoro_Dictionary_FundType` | unresolved | DWH_staging | etoro_Dictionary_FundType | `—` |
| `DWH_staging.etoro_Trade_Fund` | unresolved | DWH_staging | etoro_Trade_Fund | `—` |
| `DWH_staging.etoro_Dictionary_FundingType` | unresolved | DWH_staging | etoro_Dictionary_FundingType | `—` |
| `DWH_staging.etoro_Dictionary_Funnel` | unresolved | DWH_staging | etoro_Dictionary_Funnel | `—` |
| `DWH_staging.etoro_Dictionary_GuruStatus` | unresolved | DWH_staging | etoro_Dictionary_GuruStatus | `—` |
| `DWH_staging.etoro_Dictionary_Label` | unresolved | DWH_staging | etoro_Dictionary_Label | `—` |
| `DWH_staging.etoro_Dictionary_Language` | unresolved | DWH_staging | etoro_Dictionary_Language | `—` |
| `DWH_staging.etoro_BackOffice_Manager` | unresolved | DWH_staging | etoro_BackOffice_Manager | `—` |
| `DWH_dbo.Dim_Manager` | synapse | DWH_dbo | Dim_Manager | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `DWH_dbo.Ext_Dim_Manager` | unresolved | DWH_dbo | Ext_Dim_Manager | `—` |
| `DWH_staging.SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping` | unresolved | DWH_staging | SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping | `—` |
| `DWH_staging.etoro_Dictionary_MifidCategorization` | unresolved | DWH_staging | etoro_Dictionary_MifidCategorization | `—` |
| `DWH_staging.etoro_Dictionary_MirrorType` | unresolved | DWH_staging | etoro_Dictionary_MirrorType | `—` |
| `DWH_staging.etoro_Dictionary_PaymentStatus` | unresolved | DWH_staging | etoro_Dictionary_PaymentStatus | `—` |
| `DWH_staging.etoro_Dictionary_PendingClosureStatus` | unresolved | DWH_staging | etoro_Dictionary_PendingClosureStatus | `—` |
| `DWH_staging.etoro_Dictionary_PhoneVerified` | unresolved | DWH_staging | etoro_Dictionary_PhoneVerified | `—` |
| `DWH_staging.etoro_Dictionary_Platform` | unresolved | DWH_staging | etoro_Dictionary_Platform | `—` |
| `DWH_staging.etoro_Dictionary_PlayerLevel` | unresolved | DWH_staging | etoro_Dictionary_PlayerLevel | `—` |
| `DWH_staging.etoro_Dictionary_PlayerStatus` | unresolved | DWH_staging | etoro_Dictionary_PlayerStatus | `—` |
| `DWH_staging.etoro_Dictionary_PlayerStatusReasons` | unresolved | DWH_staging | etoro_Dictionary_PlayerStatusReasons | `—` |
| `DWH_staging.etoro_Dictionary_PlayerStatusSubReasons` | unresolved | DWH_staging | etoro_Dictionary_PlayerStatusSubReasons | `—` |
| `DWH_staging.etoro_Dictionary_RedeemReason` | unresolved | DWH_staging | etoro_Dictionary_RedeemReason | `—` |
| `DWH_staging.etoro_Dictionary_RedeemStatus` | unresolved | DWH_staging | etoro_Dictionary_RedeemStatus | `—` |
| `DWH_staging.etoro_Billing_ProtocolMIDSettings` | unresolved | DWH_staging | etoro_Billing_ProtocolMIDSettings | `—` |
| `DWH_staging.etoro_Dictionary_CashoutMode` | unresolved | DWH_staging | etoro_Dictionary_CashoutMode | `—` |
| `DWH_staging.etoro_Dictionary_CashoutReason` | unresolved | DWH_staging | etoro_Dictionary_CashoutReason | `—` |
| `DWH_staging.etoro_Dictionary_RegionByIP` | unresolved | DWH_staging | etoro_Dictionary_RegionByIP | `—` |
| `DWH_staging.etoro_Dictionary_RegionName` | unresolved | DWH_staging | etoro_Dictionary_RegionName | `—` |
| `DWH_staging.etoro_Dictionary_Regulation` | unresolved | DWH_staging | etoro_Dictionary_Regulation | `—` |
| `DWH_staging.etoro_Dictionary_RiskClassification` | unresolved | DWH_staging | etoro_Dictionary_RiskClassification | `—` |
| `DWH_staging.etoro_Dictionary_RiskManagementStatus` | unresolved | DWH_staging | etoro_Dictionary_RiskManagementStatus | `—` |
| `DWH_staging.etoro_Dictionary_RiskStatus` | unresolved | DWH_staging | etoro_Dictionary_RiskStatus | `—` |
| `DWH_staging.etoro_Dictionary_ThreeDsResponseTypes` | unresolved | DWH_staging | etoro_Dictionary_ThreeDsResponseTypes | `—` |
| `DWH_staging.etoro_Dictionary_VerificationLevel` | unresolved | DWH_staging | etoro_Dictionary_VerificationLevel | `—` |
| `DWH_staging.etoro_Dictionary_WorldCheck` | unresolved | DWH_staging | etoro_Dictionary_WorldCheck | `—` |
| `DWH_staging.etoro_BackOffice_CompensationReason` | unresolved | DWH_staging | etoro_BackOffice_CompensationReason | `—` |
| `DWH_staging.ScreeningService_Dictionary_ScreeningStatus` | unresolved | DWH_staging | ScreeningService_Dictionary_ScreeningStatus | `—` |
| `DWH_staging.HistoryCosts_Dictionary_CalculationType` | unresolved | DWH_staging | HistoryCosts_Dictionary_CalculationType | `—` |
| `DWH_staging.HistoryCosts_Dictionary_CostConfigurationId` | unresolved | DWH_staging | HistoryCosts_Dictionary_CostConfigurationId | `—` |
| `DWH_staging.HistoryCosts_Dictionary_CostSubtype` | unresolved | DWH_staging | HistoryCosts_Dictionary_CostSubtype | `—` |
| `DWH_staging.HistoryCosts_Dictionary_CostType` | unresolved | DWH_staging | HistoryCosts_Dictionary_CostType | `—` |
| `DWH_staging.HistoryCosts_Dictionary_ExecutionOperationType` | unresolved | DWH_staging | HistoryCosts_Dictionary_ExecutionOperationType | `—` |
| `DWH_staging.etoro_Dictionary_FeeOperationTypes` | unresolved | DWH_staging | etoro_Dictionary_FeeOperationTypes | `—` |
| `DWH_dbo.Dim_Date` | unresolved | DWH_dbo | Dim_Date | `—` |

