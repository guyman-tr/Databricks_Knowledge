# UC deploy follow-ups

Open issues kicked back from deploy sessions. Resolve in dedicated future
sessions; do not block ongoing schema/bronze deploys.

## v_* view comment deploy theory disproved + real bugs surfaced (2026-05-03 update)

**Original hypothesis (DISPROVED)**: that `ALTER TABLE … ALTER COLUMN
COMMENT` silently no-ops on UC views. Phase 5 probe (2026-05-03) ran
both `COMMENT ON COLUMN` and `ALTER TABLE … ALTER COLUMN COMMENT`
against all 3 affected EXW objects — **both syntaxes work and persist**.
And `gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary` is
now at 17/17 column comments after the original deploy, no fix-up
needed.

**Real findings** from systematic v_* audit
(`tools/_tmp_phase5_probe.py`):

- 60 v_* gold "views" exist; **49 already have working column comments**
  (60-100% coverage each). The bug was overstated.
- All 60 are UC `EXTERNAL` table type, not view type — so the
  `ALTER TABLE` form is the correct DDL.
- 11 had **zero column comments**, splitting into:
  - 8 with no wiki + no alter file (need wiki gen first — separate
    work, partly listed under "Bucket A" below).
  - 3 EXW objects (`EXW_Inventory_Snapshot_History`,
    `EXW_WalletInventory`, `EXW_V_RedeemReconciliation`) where
    metadata had been wiped — see two separate root causes below.

### Real bug #1: gold EXW pipeline rematerializes EXTERNAL tables and wipes UC metadata

**Evidence**: alter files for the 3 EXW objects show
`-- Statements: 104/104 succeeded` from the 2026-05-03 batch 1 run, but
when re-checked at 13:30 UTC the same day, column comments were 0/N
(only my probe survived). Re-running the alter immediately restored
all 88 columns to commented state.

**Hypothesis**: a downstream Databricks job rebuilds the gold EXW
external tables (likely DROP + CREATE EXTERNAL or a Spark write that
clobbers the `comment` field on schema). All UC metadata applied via
`ALTER` is lost on every rematerialize cycle.

**Action**: identify which job/pipeline produces
`main.{bi_db,wallet}.gold_sql_dp_prod_we_exw_dbo_*` external tables,
either:
- A. patch its writer to preserve `comment` on schema columns
  (the canonical fix), or
- B. add a post-rematerialize re-comment step (re-run the relevant
  alters as part of the same job), or
- C. accept it and run `tools/_tmp_phase5_redeploy_exw.py` (or its
  productized equivalent) on a schedule.

### Real bug #2: column-name drift in EXW_Inventory_Snapshot_History wiki

**Symptom**: alter file uses backticked names with **spaces** (e.g.
`Allocated Total`, `Funded Free`); UC has the same columns with
**underscores** (`Allocated_Total`, `Funded_Free`). 13 of 18 columns
suffered this drift and silently failed at deploy time (deploy_alter_
batch reported 12 ok / 26 fail per statement, but the alter file
footer said `104/104 succeeded` — old footer was wrong / stale).

**Cause**: wiki author captured the SELECT alias names from the source
view definition (e.g. `[Allocated Total]`) instead of the underlying
materialization-safe column names. The Synapse SP probably renames on
landing into the UC gold layer.

**Fix applied 2026-05-03**: `tools/_tmp_phase5_fix_inventory.py`
patched the `.alter.sql` and redeployed; now 18/18.

**Action item for harness**: add a step in the wiki generator (or
preflight) that resolves wiki §X column names against UC actual
columns BEFORE writing the alter file. When mismatch found, prefer the
UC column name and warn. Audit other EXW tables for similar drift.

### Note: deploy_alter_batch may be over-reporting success

The `deploy_alter_batch.py` log for EXW_Inventory_Snapshot_History
said `OK 104/104 statements` but 26 of those statements are now known
to have failed with `UNRESOLVED_COLUMN.WITH_SUGGESTION`. Either the
deploy tool isn't surfacing per-statement errors, or it ran a
different version of the file. Worth a small audit pass to compare
deploy logs vs `_tmp_phase5_redeploy_exw.py` per-statement results.

## Bronze deploy source-level kickbacks (2026-05-03)

Eight buckets of failures were observed across the 14-DB UC bronze deploy
that are NOT fixable by `tools/preflight_alters.py` text fixes — they
need source/generator/UC investigation in a follow-up session.

### A. Wiki content gap — wikis missing `## Elements` section (52 rows total)

**Diagnosed 2026-05-03**: the generator is NOT broken. It correctly
processes every row with scope status `ready` / `ready_case_match` and
only skips wikis that lack a `## Elements` section (the §X column
catalog needed to emit `ALTER COLUMN COMMENT` statements). Skips are
printed clearly as `SKIP no Elements section: <wiki path>`.

| DB | Count | Root cause |
|---|---:|---|
| etoro | 37 | `no_elements` (wiki exists but no Elements section) |
| USABroker | 15 | `no_elements` (Dictionary stubs from harness regen lack column tables) |

**The 15 USABroker stub wikis to back-fill** (all under
`knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/`):
`Dictionary.ApexValidationError`, `Dictionary.AppropriatenessProduct`,
`Dictionary.AppropriatenessTestResult`, `Dictionary.CustomerType`,
`Dictionary.DocumentType`, `Dictionary.EligibilityStatus`,
`Dictionary.ModifyType`, `Dictionary.OptionsStatus`,
`Dictionary.OptionsStatusControl`, `Dictionary.PhoneType`,
`Dictionary.ReasoningStatus`, `Dictionary.UserDataUpdatesMask`,
`Dictionary.UserDocumentType`, `Dictionary.UserProgram`,
`Dictionary.UserProgramEnrolmentStatus`.

**The 37 etoro wikis to back-fill** are listed in
`knowledge/ProdSchemas/_genbronze_etoro_dryrun.log` (search
`SKIP no Elements section:`).

**Separate companion issue — `no_wiki_file` (37 rows for etoro)**:
Generic Pipeline mapping points to a `wiki_path` that doesn't exist on
disk. These never enter the generator (filtered out before scope). Need
the wiki harness to actually produce these wikis first.

**Action plan** (out of scope for this session — wiki harness work):
1. Run wiki harness loop on the 52 stub/missing wikis to populate
   their §X Elements section + table summary.
2. Rerun `python -m tools.uc_bronze.generate_bronze_alters --db etoro`
   and `--db USABroker`. They will produce 52 new alter files.
3. Preflight + deploy via the existing bronze flow.

**Reference logs**:
- `knowledge/ProdSchemas/_genbronze_etoro_dryrun.log` — full dry-run
  with all 37 SKIP reasons.
- `knowledge/ProdSchemas/_genbronze_usabroker_dryrun.log` — same for
  USABroker.

### B. Hyphen-versioned Tribe shadow tables don't exist in UC (21 rows)

All under `FiatDwhDB.Tribe.*-NNNNNN.alter.sql` (e.g.
`Tribe.AccountsSnapshots-509416`). UC target like
`main.emoney.bronze_fiatdwhdb_tribe_accountssnapshots-509416` returns
`TABLE_OR_VIEW_NOT_FOUND` from `DESCRIBE TABLE`. The wiki + deploy index
expect them but the bronze ingestion either renamed them (underscore
instead of hyphen?) or never created the shadow versions.

**Action**: query `system.information_schema.tables` for
`schema='emoney' AND table_name LIKE 'bronze_fiatdwhdb_tribe_%'` to see
the actual UC names; then either rename the wiki/alter pairs to match
or remove the shadow rows from the deploy-index.

### C. UNRESOLVED_COLUMN — column drift / prose-as-column

Generator emitted column tokens that are prose (parenthetical notes)
instead of actual column names. UC rejects them.

| DB | Count | Examples of bad column tokens |
|---|---:|---|
| etoro | 8 | `AcceptanceStatusID (tinyint)`, `RiskStatusID (see 3)`, `HostName (duplicate)`, `(ParentUserName - see #5)`, `(Additional columns)`, `SubCreditTypeID, PartitionCol, DepositRollbackID, InterestMonthlyID` (multiple cols on one line) |
| WalletDB | 1 | `ValidTo` not in `Wallet.TermsAndConditions` |
| RiskClassification | 1 | `_RiskScore / _Value (sanitized names)` on `dbo.V_RiskClassificationDataLake` |

**Action**: extend `tools/audit_alter_uc_mapping.py` to flag column
tokens containing ` (`, `,`, ` see ` etc. as bogus, similar to the
existing `Tier N` audit. Treat them as "needs manual fix in source
wiki" — the parenthetical notes belong in the §3 column docs prose,
not as the column identifier in the §4 columns table.

### D. SQL Server temporal system columns not replicated (4 rows)

| DB | Object | Missing cols |
|---|---|---|
| MoneyTransfer | `Billing.Transfers` | `StartTime`, `EndTime` |
| RecurringManager | `Recurring.Payment`, `Recurring.PaymentExecution`, `Recurring.PaymentExecutionDepositResult` | `SysStartTime`, `SysEndTime` |

These are SQL Server SYSTEM_TIME period columns. The Generic Pipeline
either doesn't replicate them, or replicates them under different
names. **Action**: confirm UC schema for these tables; if temporal
cols are intentionally dropped, omit them from the wiki §4; if
renamed, update the wiki to match.

### E. Missing UC views (4 rows)

`fiktivo.AffiliateCommission.*VW` (4 of them: `ClosedPositionCommissionVW`,
`ClosedPositionVW`, `CreditCommissionVW`, `CreditVW`) and
`WalletDB.Wallet.V_BI_WalletBalances` and `etoro.BackOffice.RedeemApproval` /
`etoro.Dictionary.MarketingRegion`. Targets like
`main.bi_db.bronze_fiktivo_affiliatecommission_closedposition` etc.
return `TABLE_OR_VIEW_NOT_FOUND`.

**Action**: either bronze the views into UC, or remove from the
deploy-index. Several look like the table they wrap was renamed
(`closedposition` vs `closedpositioncommission`).

## DWH gold layer — UC tables WITHOUT comments (2026-05-03)

Queried `system.information_schema.tables` for every
`main.*.gold_sql_dp_prod_we_*` and cross-checked vs `Wiki/<schema>/Tables/`
and existing `_deploy-index.md` entries. **269 UC gold tables exist; 110
have no `comment`**. Wiki coverage is high but ALTER files were never
generated/deployed for most.

| DWH schema | UC count | Has cmt | No cmt | Wiki ready | Wiki missing |
|---|---:|---:|---:|---:|---:|
| BI_DB_dbo | 110 | 24 | 86 | 70 | 16 |
| DWH_dbo | 91 | 88 | 3 | 2 | 1 |
| Dealing_dbo | 29 | 22 | 7 | 7 | 0 |
| eMoney_dbo | 18 | 12 | 6 | 3 | 3 |
| EXW_dbo | 13 | 13 | 0 | — | — |
| EXW_Wallet | 2 | 0 | 2 | 2 | 0 |
| (decode-fail) | 6 | 0 | 6 | — | — |
| **Total** | **269** | **159** | **110** | **84** | **22** |

### BI_DB_dbo specifically (the user-flagged backlog)

The `_deploy-index.md` froze at `total_deployable: 71` in March 2026 and
was never rebuilt. Since then UC gold for BI_DB has 110 tables but only
24 have comments. The wiki has 617 `.md` files — 524 describe Synapse-only
intermediates that never land in UC (these are intentional knowledge-only
docs and are NOT a backlog), 93 match an actual UC table, and only 24 of
those 93 have ALTERs deployed.

**Actionable next session**:
1. Rebuild BI_DB_dbo deploy-index against current UC (something like
   `tools/build_bidb_dbo_scope.py` or extend the existing harness):
   - For every `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_*` UC table,
     emit a deploy-index row.
   - Pair against `Wiki/BI_DB_dbo/Tables/<table>.md` (case-insensitive).
2. Generate ALTER files for the 70 deployable misses, plus 14 across
   the other DWH schemas (Dealing_dbo: 7, eMoney_dbo: 3, DWH_dbo: 2,
   EXW_Wallet: 2 — total 84 immediately deployable).
3. Deploy via `tools/deploy_alter_batch.py --schema BI_DB_dbo` after
   preflight.
4. Separately, scaffold wikis for the 22 UC-only-no-wiki tables
   (mostly `*_backup`, `*_test`, `*_metric_view`, `dim_revenue_metrics`
   — many are throwaway / one-off and may not need real wikis; treat
   as case-by-case).

The 524 Synapse-only BI_DB wikis (`AML_Alerts_OPS_Report`,
`BI_DB_AB_Test`, etc.) are NOT in scope — they document Synapse-side
intermediates that never reach UC. Confirmed by absence of any
`main.bi_db.gold_*` UC table for those names.

**Sample evidence**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca`
exists in UC (no comment), wiki at
`knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_SAR_Report_FCA.md`
is 28KB of full §1-§9 documentation. Just needs an ALTER + deploy.

## Bronze sample QA — wiki column-coverage gaps (2026-05-03)

QA on 6 deployed bronze samples showed 2 of 6 with wiki §4 column
coverage well below 100%:

| UC target | Cols w/ comment | Note |
|---|---|---|
| `main.wallet.bronze_walletdb_wallet_conversiontransactions` | 11/20 (55%) | `Id`, `ConversionId`, `WalletId`, etc. covered; system/audit cols not |
| `main.emoney.bronze_fiatdwhdb_dbo_customereodbalance` | 10/16 (62%) | Similar — domain cols covered, technical cols not |

Other 4 samples (`etoro.dictionary_funnel`, `etoro.hedge_aic`,
`calendardb.providersexchangedailyschedules`, `userapidb.dictionary_mandatorytype`)
were 100%.

**Action**: extend `tools/uc_bronze/deploy_bronze_alters.py` deploy
report to surface per-table column-coverage %. Flag <80% for wiki
back-fill in a later pass. Not a blocker — partial coverage is still
strictly better than no comments.

