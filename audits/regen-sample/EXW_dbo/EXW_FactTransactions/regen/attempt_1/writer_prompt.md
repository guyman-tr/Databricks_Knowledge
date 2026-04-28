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

- **Schema**: `EXW_dbo`
- **Object**: `EXW_FactTransactions`
- **Attempt**: `1`
- **Output directory** (relative to repo root): `audits/regen-sample/EXW_dbo/EXW_FactTransactions/regen/attempt_1/`
- **Absolute output directory**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\EXW_dbo\EXW_FactTransactions\regen\attempt_1`
- **Bundle path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\audits\regen-sample\EXW_dbo\EXW_FactTransactions\regen\_upstream_bundle.md`
- **DDL path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_dbo\Tables\EXW_dbo.EXW_FactTransactions.sql`

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

# Pre-Resolved Upstream Bundle for `EXW_dbo.EXW_FactTransactions`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_dbo.EXW_FactTransactions.sql`

```sql
CREATE TABLE [EXW_dbo].[EXW_FactTransactions]
(
	[GCID] [int] NULL,
	[RealCID] [int] NULL,
	[CryptoId] [int] NULL,
	[CryptoName] [nvarchar](500) NULL,
	[InstrumentID] [bigint] NULL,
	[WalletID] [nvarchar](max) NULL,
	[TranID] [bigint] NULL,
	[TranStatusID] [int] NULL,
	[TranStatus] [nvarchar](500) NULL,
	[TranDate] [date] NULL,
	[TranDateID] [bigint] NULL,
	[Amount] [numeric](38, 8) NULL,
	[EtoroFees] [numeric](38, 8) NULL,
	[ProviderFees] [numeric](38, 8) NULL,
	[FeeExchangeRate] [numeric](38, 8) NULL,
	[BlockchainFees] [numeric](38, 8) NULL,
	[EstimatedBlockchainFee] [numeric](38, 8) NULL,
	[ActionTypeID] [int] NULL,
	[ActionTypeName] [nvarchar](500) NULL,
	[AmountUSD] [numeric](38, 8) NULL,
	[EtoroFeesUSD] [numeric](38, 8) NULL,
	[BlockchainFeesUSD] [numeric](38, 8) NULL,
	[EstimatedBlockchainFeesUSD] [numeric](38, 8) NULL,
	[UpdateDate] [datetime] NULL,
	[SenderAddress] [nvarchar](512) NULL,
	[ReciverAddress] [nvarchar](max) NULL,
	[AMLProviderStatus] [varchar](500) NULL,
	[AMLIsPositiveDecision] [int] NULL,
	[IsEtoroFee] [int] NULL,
	[BlockchainTransactionId] [nvarchar](max) NULL,
	[TransactionTypeID] [int] NULL,
	[TransactionType] [varchar](64) NULL,
	[IsRedeem] [int] NULL,
	[IsConversion] [int] NULL,
	[IsPayment] [int] NULL,
	[BlockchainCryptoId] [int] NULL,
	[BlockchainCryptoName] [nvarchar](500) NULL,
	[Occurred] [datetime] NULL,
	[IsFunding] [int] NULL,
	[IsEtoroHandlingFee] [int] NULL,
	[TranDateTime] [datetime] NULL,
	[DateOccured] [date] NULL,
	[LastStatusUpdateOccurred] [datetime] NULL,
	[ReceivedTransactionTypeID] [int] NULL,
	[ReceivedTransactionType] [varchar](64) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [GCID] ),
	HEAP
)

GO

```

---

## Upstream Wikis Found

Found 1 upstream wiki(s). Read EACH one in full.


### Upstream `Wallet.TransactionsView` — production
- **Resolved as**: `WalletDB.Wallet.TransactionsView`
- **Wiki path**: `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Views\Wallet.TransactionsView.md`

# Wallet.TransactionsView

> Comprehensive unified transaction view combining all sent transaction types (redemptions, conversions, payments, staking, and other) with received transactions into a single CTE-based queryable interface with fees, statuses, blockchain details, and customer context. Active replacement for TransactionViewOld.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | TranID (bigint, from SentTransactions.Id or ReceivedTransactions.Id) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the current unified transaction view for the eToro crypto wallet platform, combining all sent and received transactions into a single denormalized output. It replaces the legacy Wallet.TransactionViewOld by adding staking transaction support (TransactionTypeId=9), an "other" catch-all for new types, the LastStatusUpdateOccurred column, and a more maintainable CTE-based architecture.

Without this view, querying a customer's full transaction history would require writing separate queries against multiple transaction tables (SentTransactions, ReceivedTransactions, Redemptions, Conversions, Payments, Staking) and manually unioning them with different fee calculation logic. The view provides a single point of access for all transaction types.

The view is structured as 7 CTEs (redeem_transactions, conversion_in_transactions, conversion_out_transactions, payment_transactions, staking_transactions, other_transactions, received_transactions) that are unioned together, then enriched with the sender address from WalletPool, status name from Dictionary.TransactionStatus, customer Gcid from Wallets, and type name from Dictionary.TransactionTypes. Used by Monitoring.GetAlertValuePerCrypto and referenced in MonitorTeam permissions.

---

## 2. Business Logic

### 2.1 CTE-Based Transaction Routing

**What**: Each sent transaction type has its own CTE with type-specific fee logic, then all CTEs are unioned.

**Columns/Parameters Involved**: `TransactionTypeId`, `ActionTypeId`, `ActionTypeName`

**Rules**:
- `redeem_transactions` (types 0, 8): Redeem/RedeemAsic - fees from Wallet.Redemptions (eToroFeeAmount, EstimatedBlockchainFee + InitialFeeAmount). ROW_NUMBER partitions blockchain fee across outputs
- `conversion_in_transactions` (type 5): ConversionMoneyIn - zero eToro fees, blockchain fee from SentTransactions
- `conversion_out_transactions` (type 6): ConversionMoneyOut - fees from ConversionTransactions with cross-currency exchange rate: ctf.CryptoRateUsd / NULLIF(ctt.CryptoRateUsd, 0)
- `payment_transactions` (type 7): Payment - fees from PaymentTransactions (EtoroFeeCalculated, ProviderFeeCalculated, 1/ExchangeRate)
- `staking_transactions` (type 9): Staking - fees from Staking.StakingTransactions (EtoroFee, BlockchainEstFee). Cross-schema dependency to Staking schema
- `other_transactions` (types NOT IN 0,5,6,7,8,9): Catch-all for CustomerMoneyOut, AmlMoneyBack, Funding, and future types. Fees from SentTransactionOutputs. Filters out self-sends via NormalizedToAddress check
- `received_transactions`: All incoming - no fees, ActionTypeId=2. Filters out self-receives via NormalizedSenderAddress check

**Diagram**:
```
Wallet.TransactionsView
+-- CTE: redeem_transactions (types 0,8) -> Redemptions fees
+-- CTE: conversion_in_transactions (type 5) -> zero eToro fees
+-- CTE: conversion_out_transactions (type 6) -> cross-rate fees
+-- CTE: payment_transactions (type 7) -> payment provider fees
+-- CTE: staking_transactions (type 9) -> staking fees [NEW]
+-- CTE: other_transactions (all others) -> output-level fees
|
+-- UNION ALL -> trx_out1
    +-- JOIN WalletPool -> SenderAddress
    +-- JOIN Dictionary.TransactionStatus -> TransStatus
    = trx_out (ActionTypeId=1, 'Sent')
|
+-- CTE: received_transactions
    +-- JOIN Dictionary.TransactionStatus -> TransStatus
    = (ActionTypeId=2, 'Recive')
|
+-- UNION ALL -> union_trx
    +-- JOIN Wallets -> Gcid
    +-- LEFT JOIN Dictionary.TransactionTypes -> TransactionType
    = final_view (22 columns)
```

### 2.2 Self-Transaction Filtering

**What**: The view excludes transactions where a wallet sends to or receives from its own addresses.

**Columns/Parameters Involved**: `NormalizedToAddress`, `NormalizedSenderAddress`, `WalletAddresses`

**Rules**:
- Sent (other_transactions CTE): `NormalizedToAddress NOT IN (SELECT NormalizedAddress FROM WalletAddresses WHERE WalletId = st.WalletId)` - excludes change outputs and self-sends
- Received: `NormalizedSenderAddress NOT IN (SELECT NormalizedAddress FROM WalletAddresses WHERE WalletId = rt.WalletId)` - excludes self-deposits
- This ensures only externally meaningful transactions appear

### 2.3 Status Resolution Pattern

**What**: Transaction statuses are resolved via correlated subqueries against the status history tables.

**Columns/Parameters Involved**: `TransStatusId`, `LastStatusUpdateOccurred`

**Rules**:
- `TransStatusId = (SELECT TOP 1 StatusId FROM *Statuses WHERE *Id = Id ORDER BY Id DESC)` - gets the most recent status
- `LastStatusUpdateOccurred = (SELECT TOP 1 Occurred FROM *Statuses WHERE *Id = Id ORDER BY Id DESC)` - timestamp of last status change
- This pattern is used for both sent and received transactions

---

## 3. Data Overview

| TranID | gcid | CryptoId | ActionTypeName | TransStatus | Amount | TransactionType | Occurred | Meaning |
|---|---|---|---|---|---|---|---|---|
| 300007 | 0 | 2 (ETH) | Sent | Verified | 0.318099 | Redeem | 2020-08-07 | A verified ETH redemption from an omnibus wallet (Gcid=0). Funds sent from the system wallet as part of a user withdrawal. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | gcid | bigint | NO | - | VERIFIED | Global Customer ID of the wallet owner. Resolved by joining the final output to Wallet.Wallets via WalletId. Gcid=0 indicates omnibus/system wallets. From Wallet.Wallets.Gcid. |
| 2 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency of this transaction. FK to Wallet.CryptoTypes.CryptoID. From SentTransactions.CryptoId or ReceivedTransactions.CryptoId. |
| 3 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet involved in this transaction. From SentTransactions.WalletId or ReceivedTransactions.WalletId. |
| 4 | TranID | bigint | NO | - | CODE-BACKED | Transaction identifier. SentTransactions.Id for sends, ReceivedTransactions.Id for receives. Not globally unique across action types - combine with ActionTypeId to distinguish. |
| 5 | TransStatusId | int | NO | - | CODE-BACKED | Latest status ID. Resolved via correlated subquery: `SELECT TOP 1 StatusId FROM *Statuses ORDER BY Id DESC`. FK to Dictionary.TransactionStatus. |
| 6 | TransStatus | nvarchar | NO | - | CODE-BACKED | Human-readable status name from Dictionary.TransactionStatus. Values: Pending, Verified, Error, Done, Cancelled, NeedsApproval. |
| 7 | TransDate | datetime2(7) | NO | - | CODE-BACKED | Transaction date. For sends: SentTransactions.Occurred. For receives: ReceivedTransactions.BlockchainTransactionDate. |
| 8 | Amount | decimal | YES | - | VERIFIED | Transaction amount in native crypto units. From SentTransactionOutputs.Amount (sends) or ReceivedTransactions.Amount (receives). ISNULL defaults to 0 for "other" types. |
| 9 | EtoroFees | decimal | YES | - | CODE-BACKED | eToro platform fees. Source varies: Redemptions -> eToroFeeAmount, ConversionOut -> EtoroFeeCalculated, Payments -> EtoroFeeCalculated, Staking -> EtoroFee, Other -> SentTransactionOutputs.EtoroFees. NULL for receives. |
| 10 | ProviderFees | decimal | YES | - | CODE-BACKED | External provider fees. Only populated for Payment transactions (type 7) from PaymentTransactions.ProviderFeeCalculated. NULL for all other types. |
| 11 | FeeExchangeRate | decimal | YES | - | CODE-BACKED | Exchange rate for fee currency conversion. ConversionOut: source/dest USD rate ratio. Payment: 1/ExchangeRate. Others: 1. NULL for receives. |
| 12 | BlockchainFee | decimal | YES | - | CODE-BACKED | Actual blockchain network fee (gas/miner fee). For redemptions: counted once per transaction (ROW_NUMBER=1). From SentTransactions.BlockchainFee. NULL for receives. |
| 13 | EffectiveBlockchainFee | decimal | YES | - | CODE-BACKED | Estimated/effective blockchain fee for fee calculations. Redemptions: EstimatedBlockchainFee + InitialFeeAmount. Conversions/Payments: EstimatedBlockChainFee. Staking: BlockchainEstFee. NULL for receives. |
| 14 | ActionTypeId | int | NO | - | CODE-BACKED | Transaction direction: 1=Sent (outgoing), 2=Recive (incoming). Hard-coded per CTE block. |
| 15 | ActionTypeName | nvarchar | NO | - | CODE-BACKED | Human-readable direction: 'Sent' or 'Recive' (legacy misspelling preserved for backward compatibility). |
| 16 | SenderAddress | nvarchar(512) | YES | - | CODE-BACKED | Sender's blockchain address. Sends: from WalletPool.PublicAddress (wallet's own address). Receives: from ReceivedTransactions.SenderAddress (external sender). |
| 17 | ReciverAddress | nvarchar(512) | YES | - | CODE-BACKED | Receiver's blockchain address (legacy misspelling "Reciver"). Sends: from SentTransactionOutputs.ToAddress. Receives: from ReceivedTransactions.ReceiverAddress. |
| 18 | BlockchainTransactionId | nvarchar | YES | - | CODE-BACKED | On-chain transaction hash. Unique identifier on the blockchain for tracking and verification. From SentTransactions or ReceivedTransactions. |
| 19 | TransactionTypeId | int | YES | - | VERIFIED | Sent transaction type: 0=Redeem, 5=ConversionMoneyIn, 6=ConversionMoneyOut, 7=Payment, 8=RedeemAsic, 9=Staking. NULL for received transactions. FK to Dictionary.TransactionTypes. |
| 20 | TransactionType | nvarchar | YES | - | CODE-BACKED | Human-readable type name from Dictionary.TransactionTypes. NULL for received transactions. |
| 21 | Occurred | datetime2(7) | NO | - | CODE-BACKED | When the transaction record was created in the database. From SentTransactions.Occurred or ReceivedTransactions.Occurred. |
| 22 | LastStatusUpdateOccurred | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the most recent status change. Resolved via correlated subquery like TransStatusId. Enables "time since last update" monitoring and SLA tracking. New in this version (not in TransactionViewOld). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.SentTransactions | Source | Outgoing transaction details |
| WalletId | Wallet.SentTransactionOutputs | JOIN | Output amounts, addresses, fees |
| StatusId | Wallet.SentTransactionStatuses | Subquery | Latest sent status |
| WalletId | Wallet.ReceivedTransactions | Source | Incoming transaction details |
| StatusId | Wallet.ReceivedTransactionStatuses | Subquery | Latest received status |
| CorrelationId | Wallet.Redemptions | JOIN | Redemption fees (types 0, 8) |
| CorrelationId | Wallet.Conversions | JOIN | Conversion correlation (types 5, 6) |
| ConversionId | Wallet.ConversionTransactions | JOIN | Conversion fees and rates |
| CorrelationId | Wallet.Payments | JOIN | Payment correlation (type 7) |
| PaymentId | Wallet.PaymentTransactions | JOIN | Payment fees and rates |
| CorrelationId | Staking.Staking | JOIN (cross-schema) | Staking correlation (type 9) |
| StakingId | Staking.StakingTransactions | JOIN (cross-schema) | Staking fees |
| WalletId | Wallet.Wallets | JOIN | Customer Gcid resolution |
| WalletId | Wallet.WalletPool | JOIN | Sender address resolution |
| NormalizedAddress | Wallet.WalletAddresses | Subquery | Self-transaction filtering |
| TransStatusId | Dictionary.TransactionStatus | JOIN (cross-schema) | Status name lookup |
| TransactionTypeId | Dictionary.TransactionTypes | LEFT JOIN (cross-schema) | Type name lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitoring.GetAlertValuePerCrypto | Procedure | READER | Reads transaction data for crypto alert monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TransactionsView (view)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.Redemptions (table)
+-- Wallet.Conversions (table)
+-- Wallet.ConversionTransactions (table)
+-- Wallet.Payments (table)
+-- Wallet.PaymentTransactions (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.Wallets (table)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletAddresses (table)
+-- Staking.Staking (table, cross-schema)
+-- Staking.StakingTransactions (table, cross-schema)
+-- Dictionary.TransactionStatus (table, cross-schema)
+-- Dictionary.TransactionTypes (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Source of all outgoing transactions |
| Wallet.SentTransactionOutputs | Table | Transaction output details |
| Wallet.SentTransactionStatuses | Table | Status history |
| Wallet.Redemptions | Table | Redemption fees |
| Wallet.Conversions | Table | Conversion correlation |
| Wallet.ConversionTransactions | Table | Conversion fees/rates |
| Wallet.Payments | Table | Payment correlation |
| Wallet.PaymentTransactions | Table | Payment fees/rates |
| Wallet.ReceivedTransactions | Table | Incoming transactions |
| Wallet.ReceivedTransactionStatuses | Table | Received status history |
| Wallet.Wallets | Table | Customer Gcid |
| Wallet.WalletPool | Table | Sender address |
| Wallet.WalletAddresses | Table | Self-send filtering |
| Staking.Staking | Table (cross-schema) | Staking correlation |
| Staking.StakingTransactions | Table (cross-schema) | Staking fees |
| Dictionary.TransactionStatus | Table (cross-schema) | Status names |
| Dictionary.TransactionTypes | Table (cross-schema) | Type names |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitoring.GetAlertValuePerCrypto | Procedure | Reads for alert threshold monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get recent transactions for a customer
```sql
SELECT TranID, ActionTypeName, TransStatus, Amount, CryptoId, TransactionType, Occurred, LastStatusUpdateOccurred
FROM Wallet.TransactionsView WITH (NOLOCK)
WHERE gcid = 9661239
  AND Occurred >= DATEADD(day, -30, GETDATE())
ORDER BY Occurred DESC
```

### 8.2 Find staking transactions
```sql
SELECT gcid, CryptoId, Amount, EtoroFees, EffectiveBlockchainFee, TransStatus
FROM Wallet.TransactionsView WITH (NOLOCK)
WHERE TransactionTypeId = 9
ORDER BY Occurred DESC
```

### 8.3 Transaction volume by type with resolved names
```sql
SELECT
    ISNULL(TransactionType, 'Receive') AS TxType,
    ActionTypeName,
    COUNT(*) AS TxCount,
    SUM(Amount) AS TotalAmount,
    SUM(ISNULL(EtoroFees, 0)) AS TotalEtoroFees
FROM Wallet.TransactionsView WITH (NOLOCK)
WHERE Occurred >= DATEADD(day, -7, GETDATE())
GROUP BY TransactionType, ActionTypeName
ORDER BY TxCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TransactionsView | Type: View | Source: WalletDB/Wallet/Views/Wallet.TransactionsView.sql*


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Wallet.TransactionsView` | production | Wallet | TransactionsView | `C:\Users\guyman\Documents\github\CryptoDBs\WalletDB\Wiki\Wallet\Views\Wallet.TransactionsView.md` |

