---
object: main.etoro_kpi_prep.v_fact_customeraction_enriched
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 79
row_count: null
generated_at: 2026-05-17T17:30:00Z
upstreams:
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
  - main.dwh.dim_position
writer:
  kind: view_definition
  path: null
  source_code_snapshot: "_discovery/source_code/v_fact_customeraction_enriched.sql"
tier_breakdown:
  tier1_columns: 38
  tier2_columns: 24
  tier3_columns: 5
  tier4_columns: 0
  tier5_columns: 12
  unverified_columns: 0
---

# v_fact_customeraction_enriched

> Enrichment view over `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` that UNION-ALLs two branches (a passive-action branch for fee/edit/airdrop rows and an active-action branch for everything else) so every row carries the position-derived **OpenDateID / CloseDateID** and **VolumeOnOpen / VolumeOnClose** that `Fact_CustomerAction` doesn't carry natively. Same per-event grain as the upstream fact, plus 2 cast columns + 2 union-literal columns + 1 CASE column (`TicketFeeAction`) and 6 COALESCE columns that prefer position-derived values when the row is position-bound. Refreshes immediately with `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (view definition, no materialization).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_fact_customeraction_enriched` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a (view) |
| **Writer** | `view_definition` |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **JOIN upstream** | `main.dwh.dim_position` (twice — UNION branches) |
| **Downstream consumers** | `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` |
| **Generated** | 2026-05-17 |
| **Created** | Thu Mar 26 15:35:18 UTC 2026 |

---

## 1. What it is

`v_fact_customeraction_enriched` is a **per-event** view (same grain as `Fact_CustomerAction`) that **enriches every action row with the position-side facts** that the gold mirror does not carry by itself. The view is `UNION ALL` of two CTEs — `passive_actions_enriched` (rows where `ActionTypeID = 35` OR `ActionTypeID = 36 AND CompensationReasonID IN (56,117,118)` OR `ActionTypeID = 32` OR `ActionTypeID = 19`) and `active_actions` (the complement) — to apply slightly different position-derivation rules per branch.

What it adds vs the upstream Fact:

- **`OpenDateID` / `CloseDateID`**: replicated from `dim_position` (cast to `INT`). The upstream Fact has them indirectly via the position FK; this view materializes them so downstream analytics (and `v_fact_customeraction_w_metrics`) can filter `CloseDateID = 0` etc. without a join.
- **`VolumeOnOpen` / `VolumeOnClose`**: position-volume snapshot, NULL for passive branch (fees/airdrops/edits don't have a meaningful volume), computed on active branch from `dim_position.InitialUnits * InitForexRate * InitConversionRate` (open) and `dim_position.VolumeOnClose` (close). Down-prevents double-counting when aggregating volume from passive fee rows that share a `PositionID` with a real trade.
- **`TicketFeeAction`** (`'Open' | 'Close' | NULL`): CASE over `Description` to pre-classify `IsFeeDividend=4` rows ahead of `v_fact_customeraction_w_metrics`'s ticket-fee branching.
- **6 COALESCE columns** (`InstrumentID`, `Leverage`, `IsSettled`, `IsAirDrop`, `SettlementTypeID`, `IsBuy`): prefer the value from `dim_position` when available, falling back to the Fact's own column. Lets non-trade rows carry the position-side instrument metadata when the row references a position (e.g., overnight fees on a held position).
- **2 CASE rewrites** of `PositionID` and `MirrorID`: handle the `ActionTypeID = 36, CompensationReasonID IN (117,118)` case where `Fact_CustomerAction.PositionID` is replaced by a `TRY_CAST(REVERSE(SUBSTRING(...)))` parse of the position id encoded inside the `Description` string; and `MirrorID` is zeroed when the row's `Occurred` is after the most-recent `ActionTypeID=19` snapshot for that position.

The view is a **pure SQL `view_definition` writer** — no notebook, no SP, no scheduling. Refreshes are implicit on every query.

---

## 2. Transform Logic

### 2.1 Two-branch UNION ALL: passive vs active

**What**: Splits rows by `ActionTypeID` to apply different position-join semantics per branch, then UNIONs them back.
**Inputs**: `fca.ActionTypeID`, `fca.CompensationReasonID`
**Output**: branch routing (no output column)
**Rules**:
- **Passive branch** (`ActionTypeID IN (35, 32, 19)` OR `(ActionTypeID = 36 AND CompensationReasonID IN (56, 117, 118))`) — overnight/weekend fees, stop-loss edits, airdrops, and certain compensation events. Uses a special `dim_position` JOIN predicate (see §2.4) and sets `VolumeOnOpen`/`VolumeOnClose` to `CAST(NULL AS DECIMAL(38,6))` to prevent double-counting volume on fee rows.
- **Active branch** (NOT the passive predicate) — all other actions (opens, closes, deposits, withdrawals, logins, registrations, etc.). Plain `fca.PositionID = dp.PositionID` JOIN. `VolumeOnOpen` is computed as `CAST(ROUND(dp.InitialUnits * dp.InitForexRate * dp.InitConversionRate) AS DECIMAL(38,6))`; `VolumeOnClose` is `CAST(dp.VolumeOnClose AS DECIMAL(38,6))`.

### 2.2 COALESCE-from-position columns (6 cols)

**What**: Prefer the position-side value, fall back to the Fact's value.
**Inputs**: `dp.{Col}`, `fca.{Col}` for `Col IN (InstrumentID, Leverage, IsSettled, IsAirDrop, SettlementTypeID, IsBuy)`.
**Output**: same column names — overwritten with the COALESCE expression.
**Rules**:
- Only meaningful when the action row references a real position (i.e., the LEFT JOIN to `dim_position` matched).
- For non-position rows (login, deposit, registration) `dp.*` is NULL so the COALESCE collapses to `fca.{Col}`.
- `Leverage` from `dim_position` is the position's stored leverage; from `fca` it's whatever the action-level snapshot carried (usually identical for closes, sometimes different for opens captured pre-position-write).

### 2.3 `PositionID` CASE — encoded-in-Description parse

**What**: For compensation rows that reference a position via the `Description` text (the `ActionTypeID = 36, CompensationReasonID IN (117, 118)` family — AdminFee / SpotAdjustFee), parse the `PositionID` out of the `Description` string instead of trusting `fca.PositionID`.
**Inputs**: `fca.ActionTypeID`, `fca.CompensationReasonID`, `fca.Description`.
**Output**: `PositionID BIGINT`.
**Rules**:
- `CASE WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (117, 118) THEN TRY_CAST(REVERSE(SUBSTRING(REVERSE(fca.Description), 1, CHARINDEX(' ', REVERSE(fca.Description)) - 1)) AS BIGINT) ELSE fca.PositionID END`.
- `TRY_CAST` returns NULL when the description doesn't have a trailing space + numeric token. Downstream code should defensively handle NULL `PositionID` for these comp rows.
- The same CASE is used as the JOIN key for `dim_position dp` in the passive branch.

### 2.4 `MirrorID` CASE — zero-out post-mirror-close

**What**: When the action `Occurred` AFTER the position's most-recent mirror-close event (`ActionTypeID = 19`), force `MirrorID = 0` to reflect that the row is no longer a copy-trade.
**Inputs**: `fca.Occurred`, `dm.Occurred` (subquery max Occurred where ActionTypeID=19 per PositionID), `dp.MirrorID`, `fca.MirrorID`.
**Output**: `MirrorID INT`.
**Rules**:
- `CASE WHEN fca.Occurred > dm.Occurred THEN 0 ELSE COALESCE(dp.MirrorID, fca.MirrorID) END`.
- Only applies to the passive branch (the dm subquery is only joined there).
- Resolves the "ex-copy" case where a position was originally opened as a copy-trade but the mirror was later removed.

### 2.5 `TicketFeeAction` CASE — pre-classify ticket fees

**What**: Pre-classify `IsFeeDividend = 4` rows (ticket fees) by direction — Open vs Close — using the Description text.
**Inputs**: `fca.Description`.
**Output**: `TicketFeeAction STRING` — `'Open' | 'Close' | NULL`.
**Rules**:
- `CASE WHEN fca.Description = 'OpenTotalFees' THEN 'Open' WHEN fca.Description = 'CloseTotalFees' THEN 'Close' ELSE NULL END`.
- Only meaningful when `ActionTypeID = 35 AND IsFeeDividend = 4`. NULL for everything else (including non-ticket fees).
- Consumed by `v_fact_customeraction_w_metrics` to split ticket fees into `TicketFeeOpen` / `TicketFeeClose` revenue columns.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | DECIMAL | YES | Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert) |
| 2 | GCID | INT | YES | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 3 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | DemoCID | INT | YES | Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 5 | Occurred | TIMESTAMP | YES | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 6 | IPNumber | LONG | YES | IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login) |
| 7 | IsReal | INT | YES | Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 8 | ActionTypeID | INT | YES | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from `CreditTypeID` & branch router in loader + positional feeds. (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) |
| 9 | PlatformTypeID | INT | YES | Legacy platform discriminator (`0` default; `99` STS-heavy logins sampled 202601+). (Tier 3 — ETL-assigned) |
| 10 | InstrumentID | INT | YES | FK to `Trade.Instrument`. Financial instrument being traded when row is instrument-bearing. In this view: `COALESCE(dp.InstrumentID, fca.InstrumentID)` — prefers the position-derived instrument for position-bound action rows, falls back to the Fact's column otherwise. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 11 | Amount | DECIMAL | YES | Position / ledger amount discipline per branch (cash change on opens; fee/deposit sizing on ledger rows — see lineage). Must be ≥ 0 on trade opens historically. (Tier 1 — Trade.PositionTbl / History.Credit) |
| 12 | Leverage | INT | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement posture. In this view: `COALESCE(dp.Leverage, fca.Leverage)` — prefers the position's stored leverage when the row references a position, falls back to the Fact's snapshot otherwise. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 13 | NetProfit | DECIMAL | YES | Realized PnL. 0 when open; populated on closes in position currency. (Tier 1 — Trade.PositionTbl) |
| 14 | Commission | DECIMAL | YES | Open commission in dollars (`/100` cents conversion on ingest per `Dim_Position` lineage notes). (Tier 1 — Trade.PositionTbl) |
| 15 | PositionID | LONG | YES | Surrogate bigint from `Internal.GetPositionID_Bigint` domain; unique trade position key. In this view, **overridden via CASE** for compensation rows that encode the position id inside `Description`: when `ActionTypeID = 36 AND CompensationReasonID IN (117, 118)`, parses the trailing token off `REVERSE(SUBSTRING(REVERSE(Description), 1, CHARINDEX(' ', REVERSE(Description)) - 1))` via `TRY_CAST(... AS BIGINT)` (NULL on parse failure); otherwise passes through `fca.PositionID`. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction) |
| 16 | CampaignID | INT | YES | Marketing campaign identifier — 0 if not campaign-bound. References `Dim_Campaign`. (Tier 5 — domain expert) |
| 17 | BonusTypeID | INT | YES | Bonus classifier on bonus credit rows (`ActionTypeID=9`). 0 elsewhere. References `Dim_BonusType`. (Tier 5 — domain expert) |
| 18 | FundingTypeID | INT | YES | Ledger funding / wallet channel identifier (deposits & cash-outs). Nullable upstream coerced with `ISNULL(...,0)` sentinel row `0` (`Dim_FundingType.md`). Value 27 pairs with redeem flag derivation on cash-outs. References `Dim_FundingType`. (Tier 1 — History.Credit) |
| 19 | LoginID | INT | YES | Billing login session key (`Billing.Login` lineage). 0 off-login. (Tier 1 — Billing.Login) |
| 20 | MirrorID | INT | YES | FK to `Trade.Mirror` (`0`/NULL ⇒ manual trading; >0 ⇒ copy-trade child). In this view (passive branch only), **overridden via CASE** to 0 when the row's `Occurred` is AFTER the most-recent `ActionTypeID=19` (Mirror Removed) snapshot for the same position; otherwise `COALESCE(dp.MirrorID, fca.MirrorID)`. Resolves the "ex-copy" case. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 21 | WithdrawID | INT | YES | Withdrawal request identifier for cash-out credits; 0 when absent. (Tier 1 — History.Credit) |
| 22 | DurationInSeconds | INT | YES | Login session dwell seconds (NULL outside login cashier events). (Tier 1 — Billing.Login) |
| 23 | PostID | STRING | YES | Social GUID for deprecated social action types (21–26) — stale per historical wiki audits. NULL otherwise. (Tier 1 — Social platform) |
| 24 | CaseID | INT | YES | CRM case (`ActionTypeID=31`). 0 default. (Tier 1 — CRM) |
| 25 | UpdateDate | TIMESTAMP | YES | Last successful fact loader write (`GETDATE()`/`GETUTCDATE()` parity in ops). (Tier 2 — SP_Fact_CustomerAction) |
| 26 | DateID | INT | YES | `Occurred` → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 27 | TimeID | INT | YES | Hour bucket `DATEPART(HOUR,Occurred)`. (Tier 2 — SP_Fact_CustomerAction) |
| 28 | StatusID | INT | YES | Row vitality flag (1 almost always; rare NULL cohort). (Tier 3 — ETL-assigned) |
| 29 | PreviousOccurred | TIMESTAMP | YES | Deprecated / unreliable historical column — analysts should ignore. (Tier 5 — domain expert) |
| 30 | CompensationReasonID | INT | YES | `BackOffice.CompensationReason` code on comps & some opens for airdrops. (Tier 1 — History.Credit, updated wiki 2025-12) |
| 31 | WithdrawPaymentID | INT | YES | Payment-processing key for withdrawals; used to collapse duplicate WithdrawProcessing tuples per historical ETL memo. (Tier 1 — History.Credit) |
| 32 | CommissionOnClose | DECIMAL | YES | Close commission dollars — reopen-adjust net-of-original per `Dim_Position` wiki. `CommissionOnCloseOrig` preserves untouched close fee. (Tier 1 — Trade.PositionTbl) |
| 33 | IsPlug | BOOLEAN | YES | Deprecated placeholder (`NULL`). (Tier 5 — domain expert) |
| 34 | DepositID | INT | YES | Deposit transaction reference on inbound money rows (`NULL` off-deposit actions). (Tier 1 — History.Credit) |
| 35 | PostRootID | STRING | YES | Deprecated social threading key. NULL off-social. (Tier 1 — Social platform) |
| 36 | FullCommission | DECIMAL | YES | Gross commission inclusive of hidden spread uplift at open (`/100` ingestion note). (Tier 1 — Trade.PositionTbl) |
| 37 | FullCommissionOnClose | DECIMAL | YES | Gross commission on exit — symmetrical reopen-adjust story to `CommissionOnClose`. (Tier 1 — Trade.PositionTbl) |
| 38 | RedeemID | INT | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 39 | RedeemStatus | INT | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 40 | SessionID | LONG | YES | STS session BIGINT for opens/logins (`NULL` off those branches). (Tier 1 — STS) |
| 41 | IsRedeem | INT | YES | **Dual-semantics redeem flag.** (A) **Ledger / Crypto-wallet Path:** Loader CASE documented in `Dim_FundingType.md §2.3` (`CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`) tagging eToroCryptoWallet (`FundingTypeID=27`) cash-outs (`ActionTypeID = 8` slice 100% FundingType 27 whenever `IsRedeem=1` for `DateID ≥ 20260101`). Revenue TVF `Function_Revenue_TransferCoinFee` filters `Fact_CustomerAction` with `ActionTypeID = 30 AND IsRedeem = 1` — interpret as transfer-to-coin / fiat-wallet → on-chain custody (not shorthand for bank cash-out). (B) **CFD Billing.Redeem Path:** Positional closes (`ActionTypeID ∈ {4,5,6,…}`) can emit `IsRedeem=1` alongside `RedeemID`/`RedeemStatus` (Billing.Redeem integration per `Trade.PositionTbl`) — orthogonal to transfercoin semantics. (Tier 2 — SP_Fact_CustomerAction) |
| 42 | RegulationIDOnOpen | INT | YES | Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to `etoro_History_BackOfficeCustomer` (customer regulation history). `ISNULL(..., 0)` when no regulation match found. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 43 | PlatformID | INT | YES | Product/platform identifier — badly named, references `Dim_Product.ProductID`; resolve Product/Platform/SubPlatform columns via JOIN (`ActionTypeID` 14 / 41 focus). (Tier 5 — domain expert) |
| 44 | ReopenForPositionID | LONG | YES | When position reopened: erroneous prior `PositionID`. NULL if virgin cycle. (Tier 1 — Trade.PositionTbl) |
| 45 | IsReOpen | INT | YES | 1=this position was reopened from `ReopenForPositionID`. `CASE WHEN ReopenForPositionID IS NOT NULL THEN 1 ELSE 0` default. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 46 | CommissionOnCloseOrig | DECIMAL | YES | `CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0` — preserves naive close commission before netting. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 47 | FullCommissionOnCloseOrig | DECIMAL | YES | `CASE WHEN ReopenForPositionID IS NOT NULL THEN FullCommissionOnClose ELSE 0` (default zeros). (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 48 | OriginalPositionID | LONG | YES | Source position BEFORE partial-split chains. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 49 | IsPartialCloseParent | INT | YES | Marks parent row around partial-close split (subject to `SP_Fact_CustomerAction_IsParitalCloseParent` post-job). Analyst filtering nuance persists from `Dim_Position` guidance. (Tier 5 — domain expert, SP_Fact_CustomerAction_IsParitalCloseParent) |
| 50 | IsPartialCloseChild | INT | YES | Marks remainder leg after partial close — filter guidance identical to `Dim_Position`: avoid dropping CLOSE child rows blindly. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 51 | InitialUnits | DECIMAL | YES | Opening unit count denominator for partial proration ladders. (Tier 1 — Trade.PositionTbl) |
| 52 | PaymentStatusID | INT | YES | Payment pipeline status IDs on inbound/outbound monies — join `Dim_PaymentStatus`. (Tier 5 — domain expert) |
| 53 | IsDiscounted | INT | YES | 1=commission discount applied at open (legacy bit widening). (Tier 1 — Trade.PositionTbl) |
| 54 | IsSettled | INT | YES | 1 = real asset, 0 = CFD asset. In this view: `COALESCE(dp.IsSettled, fca.IsSettled)` — prefers position-derived value for position-bound rows. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 55 | CommissionByUnits | DECIMAL | YES | Prorated commission for partial close. Formula: `(AmountInUnitsDecimal / InitialUnits) * Commission`. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 56 | FullCommissionByUnits | DECIMAL | YES | Prorated full commission for partial close. Same proration formula as `CommissionByUnits` applied to `FullCommission`. (Tier 1 — Trade.Position) |
| 57 | IsFTD | INT | YES | First-Time Deposit tagging on qualifying deposit/action rows (NULL elsewhere). Derived during credit classification & snapshot merges. (Tier 2 — SP_Fact_CustomerAction) |
| 58 | CountryIDByIP | INT | YES | Geo-IP-derived country surrogate — join `Dim_Country`. (Tier 5 — domain expert) |
| 59 | IsAnonymousIP | INT | YES | Anonymous / proxy heuristic flag STS path. NULL off relevant rows. (Tier 1 — IP geolocation service) |
| 60 | ProxyType | STRING | YES | Proxy taxonomy (`DCH`, `VPN`, `TOR`, etc.) from STS classifications. NULL if direct. (Tier 1 — STS) |
| 61 | IsFeeDividend | INT | YES | Fee subclass for `ActionTypeID=35` (1 nightly/weekend fee, 2 dividend, 3 SDRT, 4 ticket aggregates) encoded off `Description` heuristics (DSM-1463). NULL off-fee rows. (Tier 2 — SP_Fact_CustomerAction) |
| 62 | IsAirDrop | INT | YES | JOIN to `etoro_Trade_PositionAirdropLog` path per `Dim_Position` — 1 denotes airdrop-sourced crypto open. In this view: `COALESCE(dp.IsAirDrop, fca.IsAirDrop)` — prefers position-derived flag. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 63 | DividendID | INT | YES | Dividend event pointer for dividend-driven fee deductions. NULL off-dividend. (Tier 1 — Trade.Positions/dividends lineage) |
| 64 | MoveMoneyReasonID | INT | YES | `Dictionary.MoveMoneyReason` code on internal sweeps (5/6/recurring enums per prior audits). References dictionary dimension. (Tier 1 — History.Credit) |
| 65 | SettlementTypeID | INT | YES | `Dictionary.SettlementTypes` modern encoding (`0 CFD`, `1 REAL`, `2 TRS`, `3 CMT`, `4 REAL_FUTURES`, `5 MARGIN_TRADE`). Supersedes naïve `IsSettled` reads. In this view: `COALESCE(dp.SettlementTypeID, fca.SettlementTypeID)`. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 66 | etr_y | STRING | YES | Year partition value injected by the gold/spaceship pipeline. Equals `YEAR(etr_ts)`. Used as Delta partition key in UC. (Pipeline-injected metadata; not present in Synapse source DDL.) (Tier 2 — gold/spaceship pipeline) |
| 67 | etr_ym | STRING | YES | Year-month partition value (`YYYY-MM`) injected by the gold/spaceship pipeline. Used as Delta partition key for month-level pruning in UC. (Tier 2 — gold/spaceship pipeline) |
| 68 | etr_ymd | STRING | YES | Year-month-day partition value (`YYYY-MM-DD`) injected by the gold/spaceship pipeline. Used as Delta partition key for day-level pruning in UC. (Tier 2 — gold/spaceship pipeline) |
| 69 | DLTOpen | INT | YES | Distributed-ledger telemetry captured at OPEN (Prod addition 2024-06-02 per dim wiki). NULL historical. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 70 | DLTClose | INT | YES | Ledger telemetry captured at CLOSE mirroring `DLTOpen`. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 71 | OpenMarkupByUnits | DECIMAL | YES | Prorated open markup `OpenMarkup * AmountInUnitsDecimal / InitialUnits` for partial closes. (Tier 1 — Trade.Position) |
| 72 | Description | STRING | YES | Operational narrative pulled from Credits / fees ("Over night fee", ticket fee tokens, Payments deposit processor strings). (Tier 1 — History.Credit) |
| 73 | IsBuy | BOOLEAN | YES | `1` Long, `0` Short; NULL ⇒ non-trade row sentinel. In this view: `COALESCE(dp.IsBuy, fca.IsBuy)` — prefers position-derived direction. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction / main.dwh.dim_position) |
| 74 | CreditID | LONG | YES | Direct pointer to `History.Credit.CreditID` lineage for reversible audits. Added 2025 loader wave. (Tier 1 — History.Credit) |
| 75 | OpenDateID | INT | YES | Position open date as `YYYYMMDD` int. In this view, derived by casting `dp.OpenDateID` to `INT` (the position-side replicates the date for both UNION branches). 0 / NULL when the row does not reference a position. (Tier 2 — main.dwh.dim_position) |
| 76 | CloseDateID | INT | YES | Position close date as `YYYYMMDD` int. 0 = still open. In this view, derived by casting `dp.CloseDateID` to `INT`. Key filter for open vs closed. (Tier 2 — main.dwh.dim_position) |
| 77 | VolumeOnOpen | DECIMAL | YES | Position open volume snapshot. **Branch-dependent**: in the passive branch (fees / edits / airdrops / certain comps) the column is `CAST(NULL AS DECIMAL(38,6))` to prevent aggregation duplication; in the active branch (everything else) it is `CAST(ROUND(dp.InitialUnits * dp.InitForexRate * dp.InitConversionRate) AS DECIMAL(38,6))` — original volume in account currency, pre-partial-close. Always join via position to avoid double-counting volume across fee rows. (Tier 2 — main.dwh.dim_position) |
| 78 | VolumeOnClose | DECIMAL | YES | Position close volume snapshot. **Branch-dependent**: NULL in passive branch (same anti-duplication rationale); `CAST(dp.VolumeOnClose AS DECIMAL(38,6))` in active branch. (Tier 2 — main.dwh.dim_position) |
| 79 | TicketFeeAction | STRING | YES | Pre-classifier for ticket fees (`ActionTypeID = 35 AND IsFeeDividend = 4`): `'Open'` when `Description = 'OpenTotalFees'`, `'Close'` when `Description = 'CloseTotalFees'`, NULL otherwise. Consumed by `v_fact_customeraction_w_metrics` to split into `TicketFeeOpen` / `TicketFeeClose` revenue columns. (Tier 2 — main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction) |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM, both UNION branches) | `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md` |
| `main.dwh.dim_position` | LEFT JOIN (both UNION branches; passive branch uses Description-parse JOIN key) | `(no UC wiki — Synapse-equivalent Dim_Position.md is the source of truth)` |

### 4.2 Pipeline ASCII Diagram

```
Production: etoro.History.Credit / etoro.Trade.OpenPositionEndOfDay / etoro.History.ClosePositionEndOfDay
            etoro.Billing.Login / STS feeds / etoro.Customer.CustomerStatic
                                  │
                                  ▼ Generic Pipeline (Bronze + DWH staging)
Synapse:    DWH_dbo.Fact_CustomerAction                      ── documented at knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md
            DWH_dbo.Dim_Position                             ── documented at knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md
                                  │
                                  ▼ Generic Pipeline (Gold export → Delta EXTERNAL)
UC:         main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
            main.dwh.dim_position
                                  │
                                  ▼ view_definition (this object)
            main.etoro_kpi_prep.v_fact_customeraction_enriched   ←── this object
                                  │
                                  ▼ view_definition
            main.etoro_kpi_prep.v_fact_customeraction_w_metrics   (downstream — fee KPIs)
                                  │
                                  ▼ notebook (de_output writer)
            main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics   (final materialized table)
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=79 runtime=79 mismatches=11` — all 11 mismatches are on COALESCE / CASE / multi-source columns where the parser captured a single source but the runtime correctly tracks BOTH sources. See `_discovery/column_lineage/v_fact_customeraction_enriched.json` and the `## Cross-check` section in `v_fact_customeraction_enriched.lineage.md` for the per-column detail.

---

## 5. Common usage / JOINs

### 5.1 Sample queries

```sql
SELECT ActionTypeID, COUNT(*) AS row_cnt, SUM(VolumeOnOpen) AS gross_vol_open
FROM main.etoro_kpi_prep.v_fact_customeraction_enriched
WHERE etr_ymd BETWEEN '2026-04-01' AND '2026-04-30'
  AND ActionTypeID IN (1, 2, 3, 39)
GROUP BY ActionTypeID
ORDER BY ActionTypeID;
```

```sql
SELECT PositionID, MAX(OpenDateID) AS open_d, MAX(CloseDateID) AS close_d
FROM main.etoro_kpi_prep.v_fact_customeraction_enriched
WHERE etr_y = '2026' AND PositionID = :pos_id
GROUP BY PositionID;
```

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.dim_customer_masked` | `a.RealCID = c.RealCID` | Customer attributes (KYC, country, segments) |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` | `a.ActionTypeID = at.ActionTypeID` | Action name / category labels |
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | `a.InstrumentID = di.InstrumentID` | Instrument FX / SQF / 245 attributes (used by `v_fact_customeraction_w_metrics`) |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `a.MirrorID = dm.MirrorID` | Copy-trade parent (Mirror.ParentCID/ParentUserName) |

### 5.3 Gotchas

- **`HistoryID` is NOT a primary key** — duplicates are routine in this table family. Use `CreditID` for unique identification of credit-sourced rows, otherwise use composite keys.
- **`VolumeOnOpen` / `VolumeOnClose` are NULL on the passive branch** (fees, stop edits, airdrops, comps) — this is intentional and prevents double-counting volume on fee rows. Always filter on actionable `ActionTypeID` values when summing volumes.
- **`PositionID` on `ActionTypeID = 36, CompensationReasonID IN (117, 118)`** rows is **parsed from `Description`** via TRY_CAST — can be NULL when the description doesn't match the expected pattern. Defensive code should null-handle.
- **`MirrorID` zero-out on the passive branch** is *not* applied to the active branch — be aware when comparing copy-trade behavior across action types.
- **COALESCE columns** (`InstrumentID`, `Leverage`, `IsSettled`, `IsAirDrop`, `SettlementTypeID`, `IsBuy`) can differ from `Fact_CustomerAction`'s values for the same `HistoryID` when the row references a position — this is by design (position-side is more authoritative for position-bound rows).
- **No predicate pushdown to `dim_position`** — the JOIN is on `PositionID`, which is high-cardinality. Filter on `etr_y`/`etr_ym`/`etr_ymd` for partition pruning on the upstream Fact.
- **View materialization**: this is a `view_definition`, not a table — every query re-executes the full transform. For repeated heavy use, consider materialization on a downstream layer (e.g., `v_fact_customeraction_w_metrics` is itself a view; the materialized version is `de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`).

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| HistoryID | upstream wiki Fact_CustomerAction.md (passthrough) | T5 inherit | (Tier 5 — domain expert) |
| GCID..ActionTypeID..many | upstream wiki Fact_CustomerAction.md (passthrough) | T1/T2/T3/T5 inherit | (Tier N — origin) |
| InstrumentID | view DDL §2.2 (COALESCE) | T2 | [uc_view_ddl] |
| Leverage | view DDL §2.2 (COALESCE) | T2 | [uc_view_ddl] |
| PositionID | view DDL §2.3 (Description-parse CASE) | T2 | [uc_view_ddl] |
| MirrorID | view DDL §2.4 (post-mirror-close zero-out CASE) | T2 | [uc_view_ddl] |
| IsSettled / IsAirDrop / SettlementTypeID / IsBuy | view DDL §2.2 (COALESCE) | T2 | [uc_view_ddl] |
| OpenDateID / CloseDateID | view DDL (CAST dp.{col} AS INT) | T2 | [uc_view_ddl] |
| VolumeOnOpen / VolumeOnClose | view DDL §2.1 (branch-dependent NULL vs dp computation) | T2 | [uc_view_ddl] |
| TicketFeeAction | view DDL §2.5 (Description CASE) | T2 | [uc_view_ddl] |
| etr_y / etr_ym / etr_ymd | upstream gold-mirror partition metadata (preserved through view) | T2 | (Tier 2 — gold/spaceship pipeline) |

*Generated: 2026-05-17 | Tiers: 38 T1, 24 T2, 5 T3, 0 T4, 12 T5 | Elements: 79/79 | Source: view_definition*
