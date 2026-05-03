# UC deploy follow-ups

Open issues kicked back from deploy sessions. Resolve in dedicated future
sessions; do not block ongoing schema/bronze deploys.

## v_* view comment deploy is broken (2026-05-03)

**Symptom**: `gold_sql_dp_prod_we_*_v_*` views show no comments in UC even
when the per-schema `_deploy-index.md` marks them as **Deployed**. Spot
caught on `bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary`.

**Root cause** (two bugs stacked on one code path):

1. **Empty placeholder table comment.** Generator emits
   `ALTER TABLE … SET TBLPROPERTIES ( 'comment' = '' );` for `v_*` files —
   the table-level comment string is never populated from the wiki §1
   summary. See `knowledge/synapse/Wiki/eMoney_dbo/Tables/v_eMoney_Card_Instance_Summary.alter.sql:11`.
2. **Wrong DDL form for views.** The same generator emits
   `ALTER TABLE … ALTER COLUMN … COMMENT '…'` against view targets. Per the
   `uc-deploy-comments` skill, Databricks views need ANSI
   `COMMENT ON COLUMN <view>.<col> IS '…'` — the `ALTER TABLE` form
   typically returns success without setting anything on a view, which is
   why the deploy index reports Deployed but UC stays empty.

**Suspected scope**: every `v_*.alter.sql` file the wiki pipeline has
emitted under any `*/Tables/` or `*/Views/` folder. Only the 34
`etoro_kpi_prep` views are deployed correctly today, via the dedicated
`tools/apply_tvf_col_comments.py` (uses `COMMENT ON COLUMN`).

**Resolution options** (pick one in the follow-up session):

- A. Extend `tools/apply_tvf_col_comments.py` to discover and cover every
  `v_*` view that has a wiki + UC mapping, not just the 34 hard-coded TVFs.
- B. Patch the wiki generator that produces `v_*.alter.sql` files to emit
  `COMMENT ON COLUMN` and to fill the table-level comment from §1, then
  redeploy via `deploy_alter_batch.py`.

Either way, resync the corresponding `_deploy-index.md` after redeploy so
the **Deployed** flag actually reflects what's in UC.

**Affected schemas (where to look first)**:
`eMoney_dbo`, `BI_DB_dbo`, `Dealing_dbo`, `EXW_dbo`, `DWH_dbo`,
`eMoney_Tribe`. Greppable as `v_*.alter.sql` under
`knowledge/synapse/Wiki/*/Tables/` and `*/Views/`.

## Bronze deploy source-level kickbacks (2026-05-03)

Eight buckets of failures were observed across the 14-DB UC bronze deploy
that are NOT fixable by `tools/preflight_alters.py` text fixes — they
need source/generator/UC investigation in a follow-up session.

### A. Generator gap — `.alter.sql` never produced (52 rows total)

The deploy-index has a row but the `.alter.sql` file isn't on disk.
`tools/uc_bronze/generate_bronze_alters.py` skipped them silently.

| DB | Count | Examples |
|---|---:|---|
| etoro | 37 | `Billing.CustomerToFunding`, `Billing.MerchantAccountRouting`, `Dictionary.Downtime*` (10), `History.*` |
| USABroker | 15 | `Dictionary.ApexValidationError`, `Dictionary.AppropriatenessProduct`, `Dictionary.CustomerType`, `Dictionary.OptionsStatus`, `Dictionary.UserProgram*`, ... |

**Action**: rerun `tools/uc_bronze/generate_bronze_alters.py --db etoro`
and `--db USABroker`, inspect the wikis for these names to figure out
why they're being skipped (likely missing §X column section or wrong
file naming). Then redeploy via the same `--db <name>` flow.

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

