---
object: main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
schema: de_output
framework: uc-pipeline-doc
table_type: EXTERNAL
format: delta
column_count: 98
row_count: 9128648899
generated_at: 2026-05-17T18:30:00Z
upstreams:
  - main.etoro_kpi_prep.v_fact_customeraction_w_metrics
writer:
  kind: JOB
  path: null  # job has no notebook tasks (id 712655402982749); source not fetchable via Workspace API
  source_code_snapshot: null  # see _discovery/source_code/_fetch_manifest.json
tier_breakdown:
  tier1_columns: 28
  tier2_columns: 66
  tier3_columns: 1
  tier4_columns: 0
  tier5_columns: 3
  unverified_columns: 0
---

# de_output_etoro_kpi_fact_customeraction_w_metrics

> Materialized **EXTERNAL Delta** snapshot of `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` (9.1B rows @ `abfss://…/DE_OUTPUT/Etoro_KPI/Fact_CustomerAction_W_Metrics`). Adds **1** writer-stamped column (`UpdateDate`) on top of the upstream view's 97 columns; every other column is a 1:1 passthrough. Exists to collapse the upstream view's 10 LEFT JOINs into a single Delta scan for heavy revenue / MIMO consumers — query this table instead of the view when scanning ≥30 days of data.

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` |
| **Type** | EXTERNAL |
| **Format** | DELTA |
| **Owner** | guyman@etoro.com |
| **Location** | `abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Etoro_KPI/Fact_CustomerAction_W_Metrics` |
| **Row count** | 9,128,648,899 |
| **Column count** | 98 (97 passthrough + 1 stamped) |
| **Writer** | `JOB` id `712655402982749` — Databricks job (no notebook tasks; likely a JAR / Python wheel / SQL task). 3 ad-hoc DBSQL queries also touched this table in the last 90d (low event counts — likely manual reruns / repair runs). |
| **Primary upstream** | `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` |
| **Downstream consumers** | n/a (terminal in this DAG; consumed by Tableau / Genie / ad-hoc analytics) |
| **Generated** | 2026-05-17 |
| **Created (UC)** | Mon Apr 20 09:55:50 UTC 2026 |

---

## 1. What it is

Materialization (EXTERNAL Delta) of `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` — the revenue / flow metrics view. **Same grain** (one row per customer-action event, minus logins/registrations as the upstream filters them) and **same column semantics** as the upstream view. The only added column is `UpdateDate`, a writer-stamped TIMESTAMP marking when each row was last materialized into this Delta table.

Two questions this materialization answers:

1. **Performance**: the upstream view runs 10 LEFT JOINs (depositwithdrawfee × 2 aliases, depositwithdrawfee_reversals, dim_mirror, positions_opened_from_iban, positions_closed_to_iban, bronze_etoro_trade_adminpositionlog, recurring_positions CTE, v_dim_instrument_enriched). At 9.1B rows the per-query JOIN cost is prohibitive. This table folds the JOINs into a single Delta scan.
2. **Audit / change tracking**: the `UpdateDate` column lets downstream consumers detect late-arriving records or repair-run effects — `MAX(UpdateDate)` per partition is a freshness signal.

**1:1 passthrough invariant**: per `system.access.column_lineage` (90-day window, 60 production-job runs + 8 manual DBSQL events), every one of the 97 upstream view columns maps to exactly one column here with the same name and type, no transformations. The job is functionally `INSERT [OVERWRITE] INTO de_output_etoro_kpi_fact_customeraction_w_metrics SELECT *, current_timestamp() AS UpdateDate FROM v_fact_customeraction_w_metrics`.

---

## 2. Transform Logic

**Pure passthrough of `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` — no per-column transformation logic.** All revenue-bucket CASEs, commission-rebuild CASEs, JOIN-enriched flags (`IsSQF`, `IsCopyFund`, `IsOpenFromIBAN`, `IsClosedToIBAN`, `IsRecurring`, `IsC2P`), and copy-trade-parent passthroughs (`ParentCID`, `ParentUserName`) are defined and resolved in the upstream view. See upstream wiki for full transform rules: `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_w_metrics.md` §2.

Write strategy (inferred — source code not fetchable):

- **Single added column**: `UpdateDate TIMESTAMP` — stamped per row by the writer (sample value: `2026-05-02T09:47:47.159568Z`). Source NULL in `system.access.column_lineage` confirms it is a literal / function output, not a column projection. Almost certainly `current_timestamp()` evaluated at write time.
- **Refresh cadence**: 60 JOB events in the last 90 days → roughly daily, matching the upstream view's data-arrival cadence (`fact_customeraction` rebuild). The 3 secondary DBSQL events (low counts: 4, 2, 2) suggest the production cadence is the JOB and the DBSQL queries are manual repair / backfill operations from a notebook or SQL editor.
- **MERGE vs OVERWRITE**: not knowable without the source — but a `MERGE` is more likely given the 9.1B row size (full overwrite of 9.1B rows daily would be very expensive). The `UpdateDate` per-row stamp is the strongest evidence of MERGE — full overwrite would have a single UpdateDate per run, but a MERGE that touches only changed rows produces a distribution. Verify by querying `SELECT date_trunc('day', UpdateDate), COUNT(*) FROM ... GROUP BY 1 ORDER BY 1 DESC LIMIT 30`.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 3 | Occurred | TIMESTAMP | YES | UTC timestamp when the action occurred. For position opens: when position was opened. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 4 | ActionTypeID | INT | YES | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. This view filters `ActionTypeID NOT IN (14, 41)` (no logins / registrations). (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) |
| 5 | PlatformTypeID | INT | YES | Legacy platform discriminator (`0` default; `99` STS-heavy logins sampled 202601+). (Tier 3 — ETL-assigned) |
| 6 | InstrumentID | INT | YES | FK to `Trade.Instrument`. Financial instrument being traded. Inherits the upstream COALESCE semantics of `v_fact_customeraction_enriched` (prefers position-derived instrument). (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 7 | Amount | DECIMAL | YES | Position / ledger amount discipline per branch. Must be ≥ 0 on trade opens historically. (Tier 1 — Trade.PositionTbl / History.Credit) |
| 8 | Leverage | INT | YES | Leverage multiplier. Inherits the upstream COALESCE semantics (prefers position's stored leverage). (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 9 | NetProfit | DECIMAL | YES | Realized PnL. 0 when open; populated on closes in position currency. (Tier 1 — Trade.PositionTbl) |
| 10 | Commission | DECIMAL | YES | Open commission in dollars (`/100` cents conversion on ingest). (Tier 1 — Trade.PositionTbl) |
| 11 | PositionID | LONG | YES | Surrogate bigint, unique trade position key. Inherits the upstream Description-parse CASE for `ActionTypeID = 36, CompensationReasonID IN (117, 118)` rows. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction) |
| 12 | FundingTypeID | INT | YES | Ledger funding / wallet channel identifier (deposits & cash-outs). Value 27 pairs with redeem flag derivation on cash-outs. References `Dim_FundingType`. (Tier 1 — History.Credit) |
| 13 | MirrorID | INT | YES | FK to `Trade.Mirror` (`0`/NULL ⇒ manual trading; >0 ⇒ copy-trade child). Inherits the upstream post-mirror-close zero-out CASE. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 14 | WithdrawID | INT | YES | Withdrawal request identifier for cash-out credits; 0 when absent. (Tier 1 — History.Credit) |
| 15 | DateID | INT | YES | `Occurred` → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 16 | CompensationReasonID | INT | YES | `BackOffice.CompensationReason` code on comps & some opens for airdrops. (Tier 1 — History.Credit, updated wiki 2025-12) |
| 17 | WithdrawPaymentID | INT | YES | Payment-processing key for withdrawals. (Tier 1 — History.Credit) |
| 18 | CommissionOnClose | DECIMAL | YES | Close commission dollars — reopen-adjust net-of-original per `Dim_Position` wiki. (Tier 1 — Trade.PositionTbl) |
| 19 | DepositID | INT | YES | Deposit transaction reference on inbound money rows (`NULL` off-deposit actions). (Tier 1 — History.Credit) |
| 20 | FullCommission | DECIMAL | YES | Gross commission inclusive of hidden spread uplift at open. (Tier 1 — Trade.PositionTbl) |
| 21 | FullCommissionOnClose | DECIMAL | YES | Gross commission on exit — symmetrical reopen-adjust story to `CommissionOnClose`. (Tier 1 — Trade.PositionTbl) |
| 22 | RedeemID | INT | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 23 | RedeemStatus | INT | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 24 | IsRedeem | INT | YES | Dual-semantics redeem flag (ledger / crypto-wallet path OR CFD Billing.Redeem path). See upstream `v_fact_customeraction_enriched` description for full semantics. (Tier 2 — SP_Fact_CustomerAction) |
| 25 | ReopenForPositionID | LONG | YES | When position reopened: erroneous prior `PositionID`. NULL if virgin cycle. (Tier 1 — Trade.PositionTbl) |
| 26 | IsReOpen | INT | YES | 1=this position was reopened from `ReopenForPositionID`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 27 | CommissionOnCloseOrig | DECIMAL | YES | `CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0` — preserves naive close commission before netting. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 28 | FullCommissionOnCloseOrig | DECIMAL | YES | `CASE WHEN ReopenForPositionID IS NOT NULL THEN FullCommissionOnClose ELSE 0` (default zeros). (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 29 | OriginalPositionID | LONG | YES | Source position BEFORE partial-split chains. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 30 | IsPartialCloseParent | INT | YES | Marks parent row around partial-close split. (Tier 5 — domain expert, SP_Fact_CustomerAction_IsParitalCloseParent) |
| 31 | IsPartialCloseChild | INT | YES | Marks remainder leg after partial close — filter guidance: avoid dropping CLOSE child rows blindly. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 32 | PaymentStatusID | INT | YES | Payment pipeline status IDs on inbound/outbound monies — join `Dim_PaymentStatus`. (Tier 5 — domain expert) |
| 33 | IsDiscounted | INT | YES | 1=commission discount applied at open (legacy bit widening). (Tier 1 — Trade.PositionTbl) |
| 34 | IsSettled | INT | YES | 1 = real asset, 0 = CFD asset. Inherits the upstream COALESCE semantics. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 35 | CommissionByUnits | DECIMAL | YES | Prorated commission for partial close. (Tier 1 — Trade.Position) |
| 36 | FullCommissionByUnits | DECIMAL | YES | Prorated full commission for partial close. (Tier 1 — Trade.Position) |
| 37 | IsFTD | INT | YES | First-Time Deposit tagging on qualifying deposit/action rows. (Tier 2 — SP_Fact_CustomerAction) |
| 38 | IsFeeDividend | INT | YES | Fee subclass for `ActionTypeID=35` (1 nightly/weekend fee, 2 dividend, 3 SDRT, 4 ticket aggregates). (Tier 2 — SP_Fact_CustomerAction) |
| 39 | IsAirDrop | INT | YES | 1 denotes airdrop-sourced crypto open. Inherits the upstream COALESCE semantics. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 40 | DividendID | INT | YES | Dividend event pointer for dividend-driven fee deductions. (Tier 1 — Trade.Positions/dividends lineage) |
| 41 | MoveMoneyReasonID | INT | YES | `Dictionary.MoveMoneyReason` code on internal sweeps (5/6/recurring enums per prior audits). (Tier 1 — History.Credit) |
| 42 | SettlementTypeID | INT | YES | `Dictionary.SettlementTypes` modern encoding (`0 CFD`, `1 REAL`, `2 TRS`, `3 CMT`, `4 REAL_FUTURES`, `5 MARGIN_TRADE`). Inherits the upstream COALESCE semantics. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 43 | etr_y | STRING | YES | Year partition value injected by the gold/spaceship pipeline. Used as Delta partition key in UC. (Tier 2 — gold/spaceship pipeline) |
| 44 | etr_ym | STRING | YES | Year-month partition value (`YYYY-MM`) injected by the gold/spaceship pipeline. (Tier 2 — gold/spaceship pipeline) |
| 45 | etr_ymd | STRING | YES | Year-month-day partition value (`YYYY-MM-DD`) injected by the gold/spaceship pipeline. (Tier 2 — gold/spaceship pipeline) |
| 46 | DLTOpen | INT | YES | Distributed-ledger telemetry captured at OPEN. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 47 | DLTClose | INT | YES | Ledger telemetry captured at CLOSE mirroring `DLTOpen`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 48 | OpenMarkupByUnits | DECIMAL | YES | Prorated open markup for partial closes. (Tier 1 — Trade.Position) |
| 49 | Description | STRING | YES | Operational narrative pulled from Credits / fees ("Over night fee", ticket fee tokens, Payments deposit processor strings). (Tier 1 — History.Credit) |
| 50 | IsBuy | BOOLEAN | YES | `1` Long, `0` Short; NULL ⇒ non-trade row sentinel. Inherits the upstream COALESCE semantics. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 51 | CreditID | LONG | YES | Direct pointer to `History.Credit.CreditID` lineage for reversible audits. (Tier 1 — History.Credit) |
| 52 | OpenDateID | INT | YES | Position open date as `YYYYMMDD` int. Cast from `dp.OpenDateID` (replicated through `v_fact_customeraction_enriched`). (Tier 2 — main.dwh.dim_position) |
| 53 | CloseDateID | INT | YES | Position close date as `YYYYMMDD` int. 0 = still open. (Tier 2 — main.dwh.dim_position) |
| 54 | TicketFeeAction | STRING | YES | Pre-classifier for ticket fees: `'Open'` when upstream `Description = 'OpenTotalFees'`, `'Close'` when `'CloseTotalFees'`, NULL otherwise. Consumed here by `TicketFeeOpen` / `TicketFeeClose`. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction) |
| 55 | RollOverFee | DECIMAL | YES | Overnight / weekend fee bucket. `CASE WHEN ActionTypeID = 35 AND IsFeeDividend = 1 THEN -1 * Amount ELSE 0 END`. Sign-flipped (fees stored positive upstream are charged to the customer, so this column is negative). (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 56 | Dividend | DECIMAL | YES | Dividend pass-through bucket. `CASE WHEN ActionTypeID = 35 AND IsFeeDividend = 2 THEN Amount ELSE 0 END`. Customer-positive (credit). (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 57 | SDRT | DECIMAL | YES | UK Stamp Duty Reserve Tax bucket. `CASE WHEN ActionTypeID = 35 AND IsFeeDividend = 3 THEN -1 * Amount ELSE 0 END`. Customer-negative. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 58 | AdminFee | DECIMAL | YES | Administrative fee bucket. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 117 THEN -1 * Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 59 | SpotAdjustFee | DECIMAL | YES | Spot-adjustment fee bucket. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 118 THEN -1 * Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 60 | ConversionFeeDeposit | DECIMAL | YES | FX conversion fee on deposits. `CASE WHEN ActionTypeID IN (7, 44) AND dwfd.DepositID IS NOT NULL THEN dwfd.PIPsCalculation ELSE 0 END`. Pulls fee amount from `bi_db_depositwithdrawfee` joined on `DepositID`. (Tier 2 — main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 61 | ConversionFeeWithdraw | DECIMAL | YES | FX conversion fee on withdrawals. `CASE WHEN ActionTypeID IN (8, 45) AND dwfw.WithdrawPaymentID IS NOT NULL THEN dwfw.PIPsCalculation ELSE 0 END`. Pulls from `bi_db_depositwithdrawfee` aliased `dwfw` filtered to `TransactionType = 'Withdraw'`. (Tier 2 — main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 62 | ConversionFeeReversal | DECIMAL | YES | Reversed conversion fee for cancelled deposits. `CASE WHEN dwfdr.DepositID IS NOT NULL THEN -1 * dwfdr.PIPsCalculation ELSE 0 END`. Pulls from `bi_db_depositwithdrawfee_reversals` joined on `CreditID`. (Tier 2 — main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals) |
| 63 | CashoutFeeExludingRedeem | DECIMAL | YES | Cashout fee for non-redeem cashouts. `CASE WHEN ActionTypeID = 30 AND IsRedeem = 0 THEN Commission ELSE 0 END`. The misspelling "Exluding" is preserved from production. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 64 | TransferCoinFee | DECIMAL | YES | Transfer-to-coin fee bucket (eToroCryptoWallet path). `CASE WHEN ActionTypeID = 30 AND IsRedeem = 1 THEN Commission ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 65 | DormantFee | DECIMAL | YES | Dormant account fee. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 30 THEN -1 * Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 66 | ShareLendingFeeEtoroShare | DECIMAL | YES | eToro's share of share-lending fee. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 119 THEN Amount ELSE 0 END`. NOTE: identical expression to `ShareLendingFeeUserShare` — the view does not split eToro vs user share at this layer. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 67 | ShareLendingFeeUserShare | DECIMAL | YES | User's share of share-lending fee. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 119 THEN Amount ELSE 0 END`. NOTE: identical expression to `ShareLendingFeeEtoroShare` (see §2.3 gotchas). (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 68 | ShareLendingFeeBrokerShare | DECIMAL | YES | Broker's share of share-lending fee. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 119 THEN Amount / ROUND(0.425, 1) - 2 * Amount ELSE 0 END`. With `ROUND(0.425, 1) = 0.4`, simplifies to `0.5 * Amount`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 69 | ShareLendingGrossAmount | DECIMAL | YES | Gross share-lending amount (before split). `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 119 THEN 2 * Amount + Amount / ROUND(0.425, 1) - 2 * Amount ELSE 0 END`. Simplifies to `2.5 * Amount`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 70 | CashoutAdjustment | DECIMAL | YES | Cashout adjustment bucket. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID IN (41, 51) THEN Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 71 | NewCopyAmount | DECIMAL | YES | Amount flowing INTO a new copy-trade (ActionTypeID=17). `CASE WHEN ActionTypeID = 17 THEN -1 * Amount ELSE 0 END`. Sign-flipped (negative on the copier's books). (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 72 | StopCopyAmount | DECIMAL | YES | Amount flowing OUT of a stop-copy event (ActionTypeID=18). `CASE WHEN ActionTypeID = 18 THEN Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 73 | AddToCopyAmount | DECIMAL | YES | Amount added to an existing copy-trade (ActionTypeID=15). `CASE WHEN ActionTypeID = 15 THEN -1 * Amount ELSE 0 END`. Sign-flipped. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 74 | RemoveFromCopyAmount | DECIMAL | YES | Amount removed from a copy-trade (ActionTypeID=16). `CASE WHEN ActionTypeID = 16 THEN Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 75 | CryptoToPosition | DECIMAL | YES | Crypto-to-position transfer amount. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 134 THEN Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 76 | BonusCompensation | DECIMAL | YES | Bonus compensation amount (ActionTypeID=9). `CASE WHEN ActionTypeID = 9 THEN Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 77 | PnLAdjustment | DECIMAL | YES | P&L adjustment bucket. `CASE WHEN ActionTypeID = 36 AND CompensationReasonID = 22 THEN Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 78 | InvestedAmountIn | DECIMAL | YES | Money flowing INTO investments (opens). `CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN Amount ELSE 0 END`. The position-open family — manual / copy / social-trade / fund-investment opens. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 79 | InvestedAmountOut | DECIMAL | YES | Money flowing OUT of investments (closes). `CASE WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN Amount ELSE 0 END`. Position-close family. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 80 | VolumeOpen | DECIMAL | YES | Open volume (gated to open ActionTypeID family). `CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN VolumeOnOpen ELSE 0 END`. Note: `VolumeOnOpen` is NULL on the passive branch of `v_fact_customeraction_enriched`, so this column is 0 / NULL on fee rows and only populated on actual opens. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 81 | VolumeClose | DECIMAL | YES | Close volume (gated to close ActionTypeID family). `CASE WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN VolumeOnClose ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 82 | TicketFeeOpen | DECIMAL | YES | Ticket-fee charged at OPEN. `CASE WHEN ActionTypeID = 35 AND IsFeeDividend = 4 AND TicketFeeAction = 'Open' THEN -1 * Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 83 | TicketFeeClose | DECIMAL | YES | Ticket-fee charged at CLOSE. `CASE WHEN ActionTypeID = 35 AND IsFeeDividend = 4 AND TicketFeeAction = 'Close' THEN -1 * Amount ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 84 | FullCommissionCloseAdjustment | DECIMAL | YES | Per-unit partial-close adjustment for FullCommission. `CASE WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN (FullCommissionOnClose - FullCommissionByUnits) ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 85 | CommissionCloseAdjustment | DECIMAL | YES | Per-unit partial-close adjustment for Commission. `CASE WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN (CommissionOnClose - CommissionByUnits) ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 86 | FullCommissionTotal | DECIMAL | YES | Unified full-commission column folded from open / close branches. `CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN FullCommission WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN (FullCommissionOnClose - FullCommissionByUnits) ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 87 | CommissionTotal | DECIMAL | YES | Unified commission column folded from open / close branches. `CASE WHEN ActionTypeID IN (1, 2, 3, 39) THEN Commission WHEN ActionTypeID IN (4, 5, 6, 28, 40) THEN (CommissionOnClose - CommissionByUnits) ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 88 | IsActiveTrade | INT | YES | 1 if the row represents an "active trade" event. `CASE WHEN (ActionTypeID = 1 AND COALESCE(IsAirDrop, 0) = 0 AND MirrorID = 0) OR ActionTypeID IN (15, 17) THEN 1 ELSE 0 END`. True for: manual non-airdrop non-copy opens (ActionTypeID=1, IsAirDrop=0, MirrorID=0) OR copy-trade-add (15) OR new copy (17). (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 89 | IsSQF | INT | YES | 1 if the instrument is SQF-eligible (Self-Quantifying Firm). `CASE WHEN di.IsSQF = 1 THEN 1 ELSE 0 END` — derived from the joined `v_dim_instrument_enriched.IsSQF`. (Tier 2 — main.etoro_kpi_prep.v_dim_instrument_enriched) |
| 90 | Is_245_Instrument | INT | YES | 1 if the instrument is classified as a 245 product. `CASE WHEN di.Is_245_Instrument = 1 THEN 1 ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_dim_instrument_enriched) |
| 91 | IsCopyFund | INT | YES | 1 if the row's mirror is a Fund (MirrorTypeID=4). `CASE WHEN dm.MirrorTypeID = 4 THEN 1 ELSE 0 END` — `MirrorTypeID = 4 = 'Fund'` per `Dim_Mirror.MirrorTypeID` enum. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror) |
| 92 | ParentCID | INT | YES | Copy-trade parent customer ID — the CID of the trader being copied. From `dim_mirror.ParentCID`. NULL when the row is not a copy-trade. (Tier 1 — Trade.Mirror) |
| 93 | ParentUserName | STRING | YES | Username of the trader being copied. From `dim_mirror.ParentUserName`. NULL when the row is not a copy-trade. (Tier 1 — Trade.Mirror) |
| 94 | IsOpenFromIBAN | INT | YES | 1 if this position was opened from an IBAN-funded balance. `CASE WHEN ofi.TreeID IS NOT NULL THEN 1 ELSE 0 END` — `ofi` is a DISTINCT `TreeID` set from `bi_output_finance_tables_bi_db_positions_opened_from_iban` joined on `PositionID = TreeID`. (Tier 2 — main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban) |
| 95 | IsClosedToIBAN | INT | YES | 1 if this position was closed back to an IBAN. `CASE WHEN cti.PositionID IS NOT NULL THEN 1 ELSE 0 END` — `cti` is a DISTINCT `PositionID` set from `bi_output_finance_tables_bi_db_positions_closed_to_iban`. (Tier 2 — main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban) |
| 96 | IsRecurring | INT | YES | 1 if the row is part of a recurring-investment plan. 3-branch CASE: (a) `ActionTypeID IN (1,2,3,39,4,5,6,28,40,35) AND rip.PositionID IS NOT NULL` — opens/closes/fees on recurring positions; (b) `ActionTypeID = 36 AND CompensationReasonID IN (117, 118) AND rip.PositionID IS NOT NULL` — admin/spot-adjust comps on recurring positions; (c) `ActionTypeID IN (7, 44) AND ripdep.DepositID IS NOT NULL` — deposits via recurring-investment plan. `rip` / `ripdep` are subqueries on the `recurring_positions` CTE (§2.2). (Tier 2 — main.general.bronze_recurringinvestment_recurringinvestment_planinstances / main.dwh.dim_position / main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 97 | IsC2P | INT | YES | 1 if the position appears in `bronze_etoro_trade_adminpositionlog` with `CompensationReasonID = 134` (crypto-to-position transfer marker). `CASE WHEN apl.PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — main.bi_db.bronze_etoro_trade_adminpositionlog) |
| 98 | UpdateDate | TIMESTAMP | YES | Writer-stamped TIMESTAMP marking when this row was most recently materialized into the Delta table. Sample value: `2026-05-02T09:47:47.159568Z`. `system.access.column_lineage` reports source=NULL → confirms this is a literal / `current_timestamp()` output, not a column projection from the upstream view. Use `MAX(UpdateDate)` per partition as a freshness signal. (Tier 2 — main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics) |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` | Primary (only source per runtime lineage; 97 of 98 columns pass through 1:1) | `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_w_metrics.md` |

### 4.2 Pipeline ASCII Diagram

```
Production: etoro.History.Credit / etoro.Trade.OpenPositionEndOfDay / etoro.History.ClosePositionEndOfDay
            etoro.Billing.Deposit / Withdraw / DepositWithdrawFee
            etoro.Trade.AdminPositionLog
            etoro.RecurringInvestment.PlanInstances
                                  │
                                  ▼ Generic Pipeline (Bronze + DWH staging + BI_DB)
Synapse:    DWH_dbo.Fact_CustomerAction, Dim_Position, Dim_Mirror, Dim_Instrument
            BI_DB_dbo.BI_DB_DepositWithdrawFee, *_Reversals
                                  │
                                  ▼ Generic Pipeline (Gold export → Delta EXTERNAL)
UC:         main.dwh.gold_sql_dp_prod_we_dwh_dbo_{fact_customeraction, dim_position, dim_mirror}
            main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_{bi_db_depositwithdrawfee, *_reversals}
            main.bi_db.bronze_etoro_trade_adminpositionlog
            main.bi_output.bi_output_finance_tables_bi_db_positions_{opened_from_iban, closed_to_iban}
            main.general.bronze_recurringinvestment_recurringinvestment_planinstances
                                  │
                                  ▼ view_definition (enriched)
            main.etoro_kpi_prep.v_fact_customeraction_enriched
            main.etoro_kpi_prep.v_dim_instrument_enriched
                                  │
                                  ▼ view_definition (w_metrics — 10 LEFT JOINs)
            main.etoro_kpi_prep.v_fact_customeraction_w_metrics
                                  │
                                  ▼ JOB 712655402982749 (Delta MERGE / OVERWRITE — no notebook source)
            main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics   ←── this object (EXTERNAL Delta, 9.1B rows)
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=98 runtime=98 mismatches=0` — every one of the 98 UC columns has either an exact 1:1 upstream source match (97 columns → `main.etoro_kpi_prep.v_fact_customeraction_w_metrics`) or a NULL source (1 column = `UpdateDate`, confirming it is writer-stamped). The runtime cache is unambiguous; full per-column detail is in `Tables/de_output_etoro_kpi_fact_customeraction_w_metrics.lineage.md` §Column Lineage.

---

## 5. Common usage / JOINs

### 5.1 Sample queries

```sql
-- Daily revenue mix (uses materialized table — much faster than the view)
SELECT
  date(Occurred)             AS day,
  SUM(CommissionTotal)       AS commission,
  SUM(RollOverFee)           AS rollover,
  SUM(Dividend)              AS dividends_paid,
  SUM(ConversionFeeDeposit + ConversionFeeWithdraw + ConversionFeeReversal) AS fx_fees
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE Occurred >= current_date - INTERVAL 30 DAYS
GROUP BY date(Occurred)
ORDER BY day DESC;
```

```sql
-- Freshness audit: rows materialized in the last 24h, per ActionTypeID
SELECT ActionTypeID, COUNT(*) AS rows_updated_24h, MIN(UpdateDate), MAX(UpdateDate)
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE UpdateDate >= current_timestamp() - INTERVAL 1 DAY
GROUP BY ActionTypeID
ORDER BY rows_updated_24h DESC;
```

### 5.2 Common JOIN partners

Same as the upstream view — see `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_w_metrics.md` §5.2. Most common:

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `m.RealCID = c.RealCID` | Customer demographics / region / KYC for segmentation |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` | `m.ActionTypeID = at.ActionTypeID` | Action labels / categories |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funding_type` | `m.FundingTypeID = ft.FundingTypeID` | Funding-method / wallet path |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensation_reason` | `m.CompensationReasonID = cr.CompensationReasonID` | Comp reason labels |

### 5.3 Gotchas

- **Use this table, not the view, for heavy / long-range queries.** Below ~10 days of data the view's JOIN cost is acceptable. Beyond that, scan this Delta table directly — it's already JOINed.
- **Schema drift will surface as a runtime ERROR**: if the upstream view ever gains or loses a column, the JOB run will fail (schema mismatch on MERGE / INSERT). Re-run `discover_schema.py` for the `de_output` schema and re-build this wiki to detect.
- **`UpdateDate` is per-row, not per-batch**: each materialized row carries its own timestamp. Don't assume rows with the same `UpdateDate` are in the same batch — they may be, but a freshness window query should use `BETWEEN start AND end`, not equality.
- **Login & registration rows are still excluded** (inherited from upstream `WHERE ActionTypeID NOT IN (14, 41)`).
- **`CashoutFeeExludingRedeem` misspelling** is preserved — same as upstream.
- **Revenue columns are non-NULL** (CASE default = 0, inherited from upstream). Safe to `SUM(...)` without `COALESCE`.
- **`ShareLendingFeeEtoroShare` and `ShareLendingFeeUserShare` are identical expressions** — same redundancy as upstream. Treat as one column for now.
- **Materialization lag**: rows can be up to ~24h behind the upstream view (the JOB cadence). For real-time consumers, query the view directly.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| GCID..IsC2P (cols 1-97) | upstream `v_fact_customeraction_w_metrics.md` §3 (1:1 passthrough — descriptions inherited verbatim per GOLDEN-REFERENCE assertion 11) | inherits T1/T2/T3/T5 | (Tier N — origin) |
| UpdateDate (col 98) | writer-stamped TIMESTAMP — `system.access.column_lineage` confirms source=NULL; sample value: `current_timestamp()` output | T2 | (Tier 2 — main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics) |

*Generated: 2026-05-17 | Tiers: 28 T1, 66 T2, 1 T3, 0 T4, 3 T5 | Elements: 98/98 | Source: JOB (1:1 passthrough; source unfetchable, lineage via system.access.column_lineage)*
