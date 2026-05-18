---
object: main.etoro_kpi_prep.v_fact_customeraction_w_metrics
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 97
row_count: null
generated_at: 2026-05-17T18:00:00Z
upstreams:
  - main.etoro_kpi_prep.v_fact_customeraction_enriched
  - main.etoro_kpi_prep.v_dim_instrument_enriched
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
  - main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban
  - main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
  - main.bi_db.bronze_etoro_trade_adminpositionlog
  - main.general.bronze_recurringinvestment_recurringinvestment_planinstances
  - main.dwh.dim_position
writer:
  kind: view_definition
  path: null
  source_code_snapshot: "_discovery/source_code/v_fact_customeraction_w_metrics.sql"
tier_breakdown:
  tier1_columns: 30
  tier2_columns: 53
  tier3_columns: 4
  tier4_columns: 0
  tier5_columns: 10
  unverified_columns: 0
---

# v_fact_customeraction_w_metrics

> Pre-aggregation **revenue & flow metrics** view over `main.etoro_kpi_prep.v_fact_customeraction_enriched`: keeps the same per-event grain, drops 2 columns of the enriched view (`HistoryID`, `DemoCID`, `IPNumber`, `IsReal`, `CampaignID`, `BonusTypeID`, `LoginID`, `DurationInSeconds`, `PostID`, `CaseID`, `UpdateDate`, `TimeID`, `StatusID`, `PreviousOccurred`, `IsPlug`, `PostRootID`, `SessionID`, `RegulationIDOnOpen`, `PlatformID`, `InitialUnits`, `CountryIDByIP`, `IsAnonymousIP`, `ProxyType`, `VolumeOnOpen`, `VolumeOnClose`), filters `ActionTypeID NOT IN (14, 41)` (no logins or registrations), and **adds 43 computed columns**: 20+ revenue-bucket CASE columns (`RollOverFee`, `Dividend`, `SDRT`, `AdminFee`, `SpotAdjustFee`, `ConversionFee*`, `CashoutFeeExludingRedeem`, `TransferCoinFee`, `DormantFee`, `ShareLending*`, `CashoutAdjustment`, `*CopyAmount`, `CryptoToPosition`, `BonusCompensation`, `PnLAdjustment`, `InvestedAmount*`, `Volume*`, `TicketFee*`), commission-total rebuilds (`FullCommissionTotal`, `CommissionTotal`, `*CloseAdjustment`), 6 flag CASE columns (`IsActiveTrade`, `IsSQF`, `Is_245_Instrument`, `IsCopyFund`, `IsOpenFromIBAN`, `IsClosedToIBAN`, `IsRecurring`, `IsC2P`), and 2 JOIN-passthroughs (`ParentCID`, `ParentUserName` from `dim_mirror`). The view excludes logins/registrations entirely (`ActionTypeID NOT IN (14, 41)`).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a (view) |
| **Writer** | `view_definition` |
| **Primary upstream** | `main.etoro_kpi_prep.v_fact_customeraction_enriched` |
| **JOIN upstreams (10)** | `v_dim_instrument_enriched`, `bi_db_depositwithdrawfee` (×2 aliases dwfd / dwfw), `bi_db_depositwithdrawfee_reversals`, `dim_mirror`, `positions_opened_from_iban`, `positions_closed_to_iban`, `recurring_positions` (CTE), `bronze_etoro_trade_adminpositionlog` |
| **Downstream consumers** | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` (materialized writer) |
| **Generated** | 2026-05-17 |
| **Created** | Sun Apr 19 11:23:40 UTC 2026 |

---

## 1. What it is

`v_fact_customeraction_w_metrics` sits one layer above `v_fact_customeraction_enriched`, on the same row grain (one row per customer action event, minus logins and registrations). Its job is to **explode each action into the set of revenue / fee / flow buckets** that downstream MIMO and revenue dashboards consume — instead of joining `Fact_CustomerAction` against 20+ TVFs (the Synapse pattern), every revenue type is materialized inline as a CASE column with a `0` default, so downstream queries are just `SUM(RollOverFee)`, `SUM(Dividend)`, etc. with no further joins.

What it adds vs `v_fact_customeraction_enriched`:

- **27 fee/revenue CASE columns** (most resolve to `0` when their predicate doesn't match) — one per logical revenue type (overnight, dividend, SDRT, admin, spot adjustment, deposit-conversion, withdraw-conversion, deposit-conversion-reversal, cashout excl. redeem, transfercoin, dormant, share-lending eToro/User/Broker/Gross, cashout adjustment, new/stop/add/remove copy amounts, crypto-to-position, bonus compensation, P&L adjustment, invested-amount in/out, volume open/close, ticket-fee open/close).
- **4 reconstructed commission columns** (`FullCommissionCloseAdjustment`, `CommissionCloseAdjustment`, `FullCommissionTotal`, `CommissionTotal`) — fold the open-vs-close commission decision into one signed column.
- **3 instrument-attribute flags** (`IsSQF`, `Is_245_Instrument`, `IsCopyFund`) — via JOINs to `v_dim_instrument_enriched` (for SQF / 245) and `dim_mirror` (for copy-fund classification).
- **2 copy-trade parent passthroughs** (`ParentCID`, `ParentUserName`) — from `dim_mirror`.
- **4 "is-X" route flags** (`IsActiveTrade`, `IsOpenFromIBAN`, `IsClosedToIBAN`, `IsRecurring`, `IsC2P`) — combine `enriched.ActionTypeID` predicates with key-presence checks against the IBAN, recurring-investment, and admin-position-log JOINs.
- **The `recurring_positions` CTE** — distinct `(PositionID, DepositID)` from `bronze_recurringinvestment_recurringinvestment_planinstances` LEFT JOINed to `dim_position` on `OrderID`, used as the IBAN-like attribute table for `IsRecurring`.

What it drops vs `v_fact_customeraction_enriched`:

- All login/registration-only columns: `DurationInSeconds`, `PostID`, `CaseID`, `SessionID`, `IsAnonymousIP`, `ProxyType`, `CountryIDByIP`, `IPNumber`, `LoginID` (some are present on this view but the rows are filtered out by `ActionTypeID NOT IN (14, 41)`).
- Deprecated columns: `IsPlug`, `PreviousOccurred`, `PostRootID`, `BonusTypeID`, `CampaignID`, `PlatformID`, `RegulationIDOnOpen`.
- Quality columns: `HistoryID` (non-unique anyway), `DemoCID` (always 0), `IsReal` (always 1), `StatusID`, `UpdateDate`, `TimeID`, `InitialUnits`.
- `VolumeOnOpen` / `VolumeOnClose` are **reused** through CASE columns `VolumeOpen` / `VolumeClose` rather than carried through directly.

Pure SQL `view_definition` writer — no scheduling. Refreshes on every query, with the cost dominated by the 10 LEFT JOINs.

---

## 2. Transform Logic

### 2.1 `WHERE ActionTypeID NOT IN (14, 41)` — login/registration cut

**What**: Removes login (14) and registration (41) rows from the output.
**Why**: This view powers revenue/flow analytics — logins and registrations don't generate revenue and have NULL position economics, so they only inflate row counts. They remain available in the upstream `v_fact_customeraction_enriched` for engagement analytics.
**Side effect**: ~20% row drop versus the upstream view (logins are 68B+ rows in `Fact_CustomerAction` per the upstream wiki §2.1 distribution table).

### 2.2 The `recurring_positions` CTE

**What**: Builds a `(PositionID, DepositID)` lookup for "is this position part of a recurring investment plan?"
**Inputs**: `main.general.bronze_recurringinvestment_recurringinvestment_planinstances rpi` LEFT JOIN `main.dwh.dim_position dp` ON `rpi.OrderID = dp.OrderID`.
**Output**: distinct rows of `(dp.PositionID, rpi.DepositID)`. Either column can be NULL — the WHERE-clauses on the downstream JOIN use `WHERE PositionID IS NOT NULL` / `WHERE DepositID IS NOT NULL` to filter.
**Consumed by**: the `IsRecurring` CASE column (via two LEFT JOINs `rip` and `ripdep`).

### 2.3 The revenue-bucket CASE family (~27 columns)

**Pattern**: every revenue / fee bucket follows the same shape:
```sql
CASE WHEN <predicate> THEN <amount-expression> ELSE 0 END AS <Bucket>
```
- **Predicate**: a combination of `ActionTypeID`, sometimes `IsFeeDividend`, sometimes `CompensationReasonID`, sometimes a JOIN-existence check (`NOT dwfd.DepositID IS NULL`).
- **Amount expression**: either `fca.Amount` (or `-1 * fca.Amount` for sign-flipping), or the joined fee/PIPs amount (`dwfd.PIPsCalculation`), or the Commission column.
- **ELSE 0**: every revenue column is **always non-NULL** — rows that don't match the predicate contribute 0. This makes downstream `SUM(BucketName)` aggregations trivially safe.

The full bucket → predicate → amount mapping is in §3 (Elements table). The buckets fall into 7 logical groups: **fees (rollover/dividend/SDRT/ticket)**, **comp-driven amounts (admin/spot/dormant/cashout-adj/crypto-to-pos/PnL-adj)**, **conversion-fees (deposit/withdraw/reversal — from depositwithdrawfee joins)**, **cashout fees (excl. redeem / transfercoin — split by `IsRedeem`)**, **share lending (eToro/user/broker/gross)**, **copy-trade amounts (new/stop/add/remove)**, **invested-amounts & volumes (open/close by ActionTypeID family)**.

Group-specific gotchas:

- **`ShareLendingFeeEtoroShare` and `ShareLendingFeeUserShare` use the SAME expression** (`fca.Amount` when `actiontypeid=36 AND CompensationReasonID=119`) — the view doesn't actually split eToro share vs user share at this layer. Treat as redundant for now; downstream should split if needed.
- **`ShareLendingFeeBrokerShare` arithmetic**: `fca.Amount / ROUND(0.425, 1) - 2 * fca.Amount` — that `ROUND(0.425, 1)` evaluates to `0.4` (no decimals), so the formula reduces to `fca.Amount / 0.4 - 2 * fca.Amount = 2.5 * fca.Amount - 2 * fca.Amount = 0.5 * fca.Amount`. The convoluted form preserves a parameterization that other revenue TVFs use. If `ROUND(0.425, 1)` ever changes, the broker-share economics shift.
- **`ShareLendingGrossAmount`**: `2 * fca.Amount + (Amount / ROUND(0.425, 1) - 2 * Amount)` simplifies to `Amount / 0.4 = 2.5 * Amount`. Documented for completeness.

### 2.4 The commission-rebuild family (4 columns)

**`FullCommissionTotal` / `CommissionTotal`**: chooses between the open-side and close-side commission column based on `ActionTypeID`:
- `ActionTypeID IN (1, 2, 3, 39)` → use `FullCommission` / `Commission` (open).
- `ActionTypeID IN (4, 5, 6, 28, 40)` → use `FullCommissionOnClose - FullCommissionByUnits` / `CommissionOnClose - CommissionByUnits` (close, net of per-unit partial-close proration).
- Else → 0.

**`FullCommissionCloseAdjustment` / `CommissionCloseAdjustment`**: just the second CASE branch, isolated as its own column, used to net partial-close adjustments separately.

### 2.5 The instrument / mirror flag CASEs

**`IsSQF`**: `CASE WHEN di.IsSQF = 1 THEN 1 ELSE 0 END` — single-equality predicate against the joined instrument's SQF flag (`v_dim_instrument_enriched`). The CASE is a defensive null-handler — without it `NULL = 1 → NULL`, which would propagate to consumers.
**`Is_245_Instrument`**: same shape, against `di.Is_245_Instrument`.
**`IsCopyFund`**: `CASE WHEN dm.mirrortypeid = 4 THEN 1 ELSE 0 END` — `mirrortypeid = 4` is "Fund" per `Dim_Mirror.MirrorTypeID` enum.

### 2.6 The IBAN / recurring / C2P existence-flag CASEs

**`IsOpenFromIBAN`**: `CASE WHEN NOT ofi.TreeID IS NULL THEN 1 ELSE 0 END` — `ofi` is `SELECT DISTINCT TreeID FROM main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` joined on `fca.PositionID = ofi.TreeID`. 1 if this position was opened from an IBAN-funded balance.
**`IsClosedToIBAN`**: same shape against `cti` (closed-to-iban). 1 if position was closed back to an IBAN.
**`IsRecurring`**: 3-branch CASE — (1) `ActionTypeID IN (1,2,3,39,4,5,6,28,40,35) AND rip.positionid IS NOT NULL` → 1 (positions in the recurring-investment set, on open/close/fee actions); (2) `ActionTypeID = 36 AND CompensationReasonID IN (117,118) AND rip.positionid IS NOT NULL` → 1 (admin/spot-adjust comps on recurring positions); (3) `ActionTypeID IN (7,44) AND ripdep.depositid IS NOT NULL` → 1 (deposits via recurring-investment plan); else 0.
**`IsC2P`**: `CASE WHEN apl.positionid IS NOT NULL THEN 1 ELSE 0 END` — `apl` is `SELECT DISTINCT positionid FROM main.bi_db.bronze_etoro_trade_adminpositionlog WHERE CompensationReasonID = 134`. 1 if the position appears in the admin-position-log with comp reason 134 (= crypto-to-position transfer flag).

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
| 88 | IsActiveTrade | INT | NO | 1 if the row represents an "active trade" event. `CASE WHEN (ActionTypeID = 1 AND COALESCE(IsAirDrop, 0) = 0 AND MirrorID = 0) OR ActionTypeID IN (15, 17) THEN 1 ELSE 0 END`. True for: manual non-airdrop non-copy opens (ActionTypeID=1, IsAirDrop=0, MirrorID=0) OR copy-trade-add (15) OR new copy (17). (Tier 2 — main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 89 | IsSQF | INT | NO | 1 if the instrument is SQF-eligible (Self-Quantifying Firm). `CASE WHEN di.IsSQF = 1 THEN 1 ELSE 0 END` — derived from the joined `v_dim_instrument_enriched.IsSQF`. (Tier 2 — main.etoro_kpi_prep.v_dim_instrument_enriched) |
| 90 | Is_245_Instrument | INT | NO | 1 if the instrument is classified as a 245 product. `CASE WHEN di.Is_245_Instrument = 1 THEN 1 ELSE 0 END`. (Tier 2 — main.etoro_kpi_prep.v_dim_instrument_enriched) |
| 91 | IsCopyFund | INT | NO | 1 if the row's mirror is a Fund (MirrorTypeID=4). `CASE WHEN dm.MirrorTypeID = 4 THEN 1 ELSE 0 END` — `MirrorTypeID = 4 = 'Fund'` per `Dim_Mirror.MirrorTypeID` enum. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror) |
| 92 | ParentCID | INT | YES | Copy-trade parent customer ID — the CID of the trader being copied. From `dim_mirror.ParentCID`. NULL when the row is not a copy-trade. (Tier 1 — Trade.Mirror) |
| 93 | ParentUserName | STRING | YES | Username of the trader being copied. From `dim_mirror.ParentUserName`. NULL when the row is not a copy-trade. (Tier 1 — Trade.Mirror) |
| 94 | IsOpenFromIBAN | INT | NO | 1 if this position was opened from an IBAN-funded balance. `CASE WHEN ofi.TreeID IS NOT NULL THEN 1 ELSE 0 END` — `ofi` is a DISTINCT `TreeID` set from `bi_output_finance_tables_bi_db_positions_opened_from_iban` joined on `PositionID = TreeID`. (Tier 2 — main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban) |
| 95 | IsClosedToIBAN | INT | NO | 1 if this position was closed back to an IBAN. `CASE WHEN cti.PositionID IS NOT NULL THEN 1 ELSE 0 END` — `cti` is a DISTINCT `PositionID` set from `bi_output_finance_tables_bi_db_positions_closed_to_iban`. (Tier 2 — main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban) |
| 96 | IsRecurring | INT | NO | 1 if the row is part of a recurring-investment plan. 3-branch CASE: (a) `ActionTypeID IN (1,2,3,39,4,5,6,28,40,35) AND rip.PositionID IS NOT NULL` — opens/closes/fees on recurring positions; (b) `ActionTypeID = 36 AND CompensationReasonID IN (117, 118) AND rip.PositionID IS NOT NULL` — admin/spot-adjust comps on recurring positions; (c) `ActionTypeID IN (7, 44) AND ripdep.DepositID IS NOT NULL` — deposits via recurring-investment plan. `rip` / `ripdep` are subqueries on the `recurring_positions` CTE (§2.2). (Tier 2 — main.general.bronze_recurringinvestment_recurringinvestment_planinstances / main.dwh.dim_position / main.etoro_kpi_prep.v_fact_customeraction_enriched) |
| 97 | IsC2P | INT | NO | 1 if the position appears in `bronze_etoro_trade_adminpositionlog` with `CompensationReasonID = 134` (crypto-to-position transfer marker). `CASE WHEN apl.PositionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — main.bi_db.bronze_etoro_trade_adminpositionlog) |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.etoro_kpi_prep.v_fact_customeraction_enriched` | Primary (FROM) | `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_enriched.md` |
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | LEFT JOIN (`di` on `InstrumentID`) — IsSQF / Is_245_Instrument source | `(no UC wiki — schema_card lists as in-scope; pending wiki)` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | LEFT JOIN (`dwfd` on `DepositID`; `dwfw` on `WithdrawPaymentID` AND `TransactionType='Withdraw'`) — ConversionFeeDeposit / ConversionFeeWithdraw source | `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DepositWithdrawFee.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | LEFT JOIN (`dwfdr` on `CreditID`) — ConversionFeeReversal source | `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DepositWithdrawFee_Reversals.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | LEFT JOIN (`dm` on `MirrorID`) — IsCopyFund / ParentCID / ParentUserName source | `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Mirror.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` | LEFT JOIN subquery (`ofi` distinct `TreeID`) — IsOpenFromIBAN source | `(no wiki found)` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` | LEFT JOIN subquery (`cti` distinct `PositionID`) — IsClosedToIBAN source | `(no wiki found)` |
| `main.bi_db.bronze_etoro_trade_adminpositionlog` | LEFT JOIN subquery (`apl` distinct `positionid` WHERE `CompensationReasonID = 134`) — IsC2P source | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` |
| `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` | INSIDE `recurring_positions` CTE — LEFT JOIN to `dim_position` on `OrderID`. Feeds `rip` and `ripdep` subqueries → `IsRecurring` source | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.PlanInstances.md` |
| `main.dwh.dim_position` | INSIDE `recurring_positions` CTE only (via `OrderID`) | `(no UC wiki)` |

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
            (positions_opened_from_iban / positions_closed_to_iban — DE finance outputs)
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
                                  ▼ view_definition (this object — 10 LEFT JOINs)
            main.etoro_kpi_prep.v_fact_customeraction_w_metrics   ←── this object
                                  │
                                  ▼ notebook / job writer (materialization)
            main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=97 runtime=97 mismatches=41` — all 41 mismatches are on CASE / join_enriched columns where the parser captured the CASE expression in the SQL text but `system.access.column_lineage` correctly tracks all input columns through the joins (e.g., the parser sees `RollOverFee` as deriving from "v_fact_customeraction_enriched" while UC's lineage table breaks that into the underlying `actiontypeid`, `isfeedividend`, `amount`). None are wrong; the parser just summarizes at a coarser granularity. Full per-column detail in `v_fact_customeraction_w_metrics.lineage.md` §"Cross-check".

---

## 5. Common usage / JOINs

### 5.1 Sample queries

```sql
-- Monthly revenue mix per region
SELECT
  c.Region,
  m.etr_ym,
  SUM(m.FullCommissionTotal) AS total_commission,
  SUM(m.RollOverFee)         AS rollover,
  SUM(m.Dividend)            AS dividends_paid,
  SUM(m.SDRT)                AS sdrt,
  SUM(m.ConversionFeeDeposit + m.ConversionFeeWithdraw + m.ConversionFeeReversal) AS fx_fees,
  SUM(m.CashoutFeeExludingRedeem + m.TransferCoinFee)                              AS cashout_fees,
  SUM(m.ShareLendingFeeEtoroShare)                                                 AS share_lending_etoro
FROM main.etoro_kpi_prep.v_fact_customeraction_w_metrics m
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
  ON m.RealCID = c.RealCID
WHERE m.etr_ym BETWEEN '2026-01' AND '2026-04'
GROUP BY c.Region, m.etr_ym
ORDER BY c.Region, m.etr_ym;
```

```sql
-- Recurring-investment customers vs one-off depositors
SELECT
  m.etr_y,
  COUNT(DISTINCT CASE WHEN m.IsRecurring = 1 THEN m.RealCID END) AS recurring_customers,
  COUNT(DISTINCT CASE WHEN m.IsRecurring = 0 AND m.ActionTypeID IN (7,44) THEN m.RealCID END) AS oneoff_depositors
FROM main.etoro_kpi_prep.v_fact_customeraction_w_metrics m
WHERE m.ActionTypeID IN (7, 44)
GROUP BY m.etr_y
ORDER BY m.etr_y;
```

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `m.RealCID = c.RealCID` | Customer demographics / region / KYC for segmentation |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` | `m.ActionTypeID = at.ActionTypeID` | Action labels / categories |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funding_type` | `m.FundingTypeID = ft.FundingTypeID` | Funding-method / wallet path |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensation_reason` | `m.CompensationReasonID = cr.CompensationReasonID` | Comp reason labels (admin / spot-adj / dormant etc.) |

### 5.3 Gotchas

- **Login & registration rows are excluded** (`ActionTypeID NOT IN (14, 41)`). If you need them, query `v_fact_customeraction_enriched` directly.
- **All revenue columns are non-NULL** (CASE default = 0). Safe to `SUM(...)` without `COALESCE`. But `Amount`, `Commission`, `FullCommission` retain their upstream nullability.
- **`ShareLendingFeeEtoroShare` and `ShareLendingFeeUserShare` are identical expressions** (`fca.Amount` when `actiontypeid=36 AND CompensationReasonID=119`) — this view does NOT split eToro vs user share. If your downstream needs the split, do it manually using the share-lending broker formula.
- **`ShareLendingFeeBrokerShare` ROUND-trick**: `Amount / ROUND(0.425, 1) - 2 * Amount = 0.5 * Amount` (since `ROUND(0.425, 1) = 0.4`). The formula is parameterized for a `0.425` broker split, but the rounding collapses it. Validate before extrapolating to other splits.
- **`CashoutFeeExludingRedeem` misspelling** is **preserved from production** — do not "fix" it in queries; the column name is `CashoutFeeExludingRedeem`.
- **No predicate pushdown on `BI_DB_DepositWithdrawFee` joins** — both `dwfd` and `dwfw` are full LEFT JOINs without partition filters. Heavy queries should filter on `m.etr_ymd` BEFORE the joins fire (e.g., via a CTE).
- **`IsRecurring` depends on the `recurring_positions` CTE** — which DEPENDS on `bronze_recurringinvestment_recurringinvestment_planinstances` having `OrderID`-matching rows in `dim_position`. If a recurring plan's `OrderID` doesn't resolve, `IsRecurring` will be 0 even when the customer is in fact on a plan.
- **`IsCopyFund` only catches mirror-type 4 (Fund)** — does NOT catch mirror-type 2 (regular copy-trade) or mirror-type 3 (Social Index). Use `MirrorID > 0` AND `dim_mirror.MirrorTypeID IN (2, 4)` for "any copy-trade or fund" semantics.
- **View materialization downstream**: heavy users of this view should hit `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` (the materialized table writer) instead — that table flattens this view's 10 LEFT JOINs into a single Delta scan.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| GCID..CreditID (cols 1-51) | upstream `v_fact_customeraction_enriched.md` (passthrough) | inherits T1/T2/T3/T5 | (Tier N — origin) |
| OpenDateID / CloseDateID / TicketFeeAction | upstream `v_fact_customeraction_enriched.md` (passthrough — already T2 there) | T2 inherit | (Tier 2 — main.dwh.dim_position) |
| RollOverFee..InvestedAmountOut, VolumeOpen..CommissionTotal (cols 55-87) | view DDL §2.3 / §2.4 (revenue bucket / commission rebuild CASEs) | T2 | [uc_view_ddl] |
| IsActiveTrade (col 88) | view DDL §2.3 (multi-predicate CASE) | T2 | [uc_view_ddl] |
| IsSQF / Is_245_Instrument | view DDL §2.5 (instrument-attribute CASEs against v_dim_instrument_enriched) | T2 | [uc_view_ddl] |
| IsCopyFund | view DDL §2.5 (CASE on dim_mirror.MirrorTypeID = 4) | T2 | [uc_view_ddl] |
| ParentCID / ParentUserName | upstream `Dim_Mirror.md` (join_enriched passthrough) | T1 inherit | (Tier 1 — Trade.Mirror) |
| IsOpenFromIBAN / IsClosedToIBAN | view DDL §2.6 (existence CASE on IBAN subqueries) | T2 | [uc_view_ddl] |
| IsRecurring | view DDL §2.6 + §2.2 (CTE-driven existence CASE) | T2 | [uc_view_ddl] |
| IsC2P | view DDL §2.6 (existence CASE on AdminPositionLog) | T2 | [uc_view_ddl] |

*Generated: 2026-05-17 | Tiers: 30 T1, 53 T2, 4 T3, 0 T4, 10 T5 | Elements: 97/97 | Source: view_definition*
