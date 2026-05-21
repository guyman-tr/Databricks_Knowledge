---
object_fqn: main.etoro_kpi_prep.v_fact_customeraction_w_metrics
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_fact_customeraction_w_metrics
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 97
row_count: null
generated_at: '2026-05-19T12:04:40Z'
upstreams:
- main.etoro_kpi_prep.v_fact_customeraction_enriched
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.etoro_kpi_prep.v_fact_customeraction_enriched
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
- main.etoro_kpi_prep.v_dim_instrument_enriched
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
- main.general.bronze_recurringinvestment_recurringinvestment_planinstances
- main.dwh.dim_position
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
- main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban
- main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql
concept_count: 10
formula_count: 97
tier_breakdown:
  tier1_columns: 25
  tier2_columns: 68
  tier3_columns: 1
  tier4_columns: 0
  tier5_columns: 3
  tier_null_columns: 0
  unverified_columns: 0
---

# v_fact_customeraction_w_metrics

> View in `main.etoro_kpi_prep`. 10 business concept(s) in §2; 93 of 97 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_fact_customeraction_w_metrics` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 97 |
| **Concepts** | 10 (see §2) |
| **Downstream consumers** | 3 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sun Apr 19 11:23:40 UTC 2026 |

---

## 1. Business Meaning

`v_fact_customeraction_w_metrics` is a view in `main.etoro_kpi_prep` that composes 8 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.etoro_kpi_prep.v_fact_customeraction_enriched` → this object. Canonical upstream documentation: `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_enriched.md`. Additional upstreams: 10 object(s), listed in §5 Lineage.

Of its 97 columns: 25 inherit byte-for-byte from upstream wikis (Tier 1), 68 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsActiveTrade` discriminator: `actiontypeid = 35`, `isfeedividend = 1`, `actiontypeid = 35` → set to 1 else 0
**What**: Computed flag on `IsActiveTrade` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsActiveTrade`
**Rules**:
- `actiontypeid = 35`
- `isfeedividend = 1`
- `actiontypeid = 35`
- `isfeedividend = 2`
- `actiontypeid = 35`
- `isfeedividend = 3`
- `actiontypeid = 36`
- `CompensationReasonID = 117`
- `actiontypeid = 36`
- `CompensationReasonID = 118`
- `actiontypeid IN (7, 44)`
- `actiontypeid IN (8, 45)`
- `actiontypeid = 30`
- `isredeem = 0`
- `actiontypeid = 30`
- `isredeem = 1`
- `actiontypeid = 36`
- `CompensationReasonID = 30`
- `actiontypeid = 36`
- `CompensationReasonID = 119`
- `actiontypeid = 36`
- `CompensationReasonID = 119`
- `actiontypeid = 36`
- `CompensationReasonID = 119`
- `actiontypeid = 36`
- `CompensationReasonID = 119`
- `actiontypeid = 36`
- `CompensationReasonID IN (41, 51)`
- `actiontypeid = 17`
- `actiontypeid = 18`
- `actiontypeid = 15`
- `actiontypeid = 16`
- `actiontypeid = 36`
- `CompensationReasonID = 134`
- `actiontypeid = 9`
- `actiontypeid = 36`
- `CompensationReasonID = 22`
- `actiontypeid IN (1, 2, 3, 39)`
- `actiontypeid IN (4, 5, 6, 28, 40)`
- `actiontypeid IN (1, 2, 3, 39)`
- `actiontypeid IN (4, 5, 6, 28, 40)`
- `actiontypeid = 35`
- `IsFeeDividend = 4`
- `ticketfeeaction = '    '`
- `actiontypeid = 35`
- `IsFeeDividend = 4`
- `ticketfeeaction = '     '`
- `actiontypeid IN (4, 5, 6, 28, 40)`
- `actiontypeid IN (4, 5, 6, 28, 40)`
- `actiontypeid IN (1, 2, 3, 39)`
- `actiontypeid IN (4, 5, 6, 28, 40)`
- `actiontypeid IN (1, 2, 3, 39)`
- `actiontypeid IN (4, 5, 6, 28, 40)`
- `actiontypeid = 1`
- `mirrorid = 0`
- `actiontypeid IN (15, 17)`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` etoro_kpi_prep.sql L71-L104
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_Reversals`, `main.etoro_kpi_prep.v_fact_customeraction_enriched`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`

### 2.2 `IsSQF` discriminator: `IsSQF = 1` → set to 1 else 0
**What**: Computed flag on `IsSQF` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsSQF`
**Rules**:
- `IsSQF = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` etoro_kpi_prep.sql L105-L105
**Source(s)**: `main.etoro_kpi_prep.v_dim_instrument_enriched`

### 2.3 `Is_245_Instrument` discriminator: `Is_245_Instrument = 1` → set to 1 else 0
**What**: Computed flag on `Is_245_Instrument` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `Is_245_Instrument`
**Rules**:
- `Is_245_Instrument = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` etoro_kpi_prep.sql L106-L106
**Source(s)**: `main.etoro_kpi_prep.v_dim_instrument_enriched`

### 2.4 `IsCopyFund` discriminator: `mirrortypeid = 4` (Fund per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsCopyFund` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCopyFund`
**Rules**:
- `mirrortypeid = 4` (Fund per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` etoro_kpi_prep.sql L107-L107
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`

### 2.5 `IsOpenFromIBAN` computed flag
**What**: Computed flag on `IsOpenFromIBAN` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsOpenFromIBAN`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` etoro_kpi_prep.sql L110-L110

### 2.6 `IsClosedToIBAN` computed flag
**What**: Computed flag on `IsClosedToIBAN` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsClosedToIBAN`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` etoro_kpi_prep.sql L111-L111

### 2.7 `IsRecurring` discriminator: `actiontypeid IN (1,2,3,39,4,5,6,28,40,35)`, `actiontypeid = 36`, `CompensationReasonID IN (117,118)` → set to 1 else 0
**What**: Computed flag on `IsRecurring` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsRecurring`
**Rules**:
- `actiontypeid IN (1,2,3,39,4,5,6,28,40,35)`
- `actiontypeid = 36`
- `CompensationReasonID IN (117,118)`
- `actiontypeid IN (7,44)`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` etoro_kpi_prep.sql L112-L115

### 2.8 `IsC2P` computed flag
**What**: Computed flag on `IsC2P` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsC2P`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` etoro_kpi_prep.sql L116-L116

### 2.9 Dim lookup via alias `di` → `v_dim_instrument_enriched`
**What**: `JOIN` to dimension `v_dim_instrument_enriched` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fca.InstrumentID = di.InstrumentID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` L118
**Source(s)**: `main.etoro_kpi_prep.v_dim_instrument_enriched`

### 2.10 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_mirror`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_mirror` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fca.MirrorID = dm.MirrorID`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_w_metrics.sql` L126
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Filter on discriminator flags | Use `IsActiveTrade = 1`-style filters on the precomputed flag columns (`IsActiveTrade`, `IsC2P`, `IsClosedToIBAN`, `IsCopyFund`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`v_dim_instrument_enriched`, `gold_sql_dp_prod_we_dwh_dbo_dim_mirror`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | `fca.InstrumentID = di.InstrumentID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | `fca.MirrorID = dm.MirrorID` | Lookup via alias `dm` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 1 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Occurred | TIMESTAMP | YES | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 3 | ActionTypeID | INT | YES | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds. (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) |
| 4 | PlatformTypeID | INT | YES | Legacy platform discriminator (`0` default; `99` STS-heavy logins sampled 202601+). (Tier 3 — ETL-assigned) |
| 5 | InstrumentID | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(InstrumentID, InstrumentID)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 6 | Amount | DECIMAL | YES | Position / ledger amount discipline per branch (cash change on opens; fee/deposit sizing on ledger rows — see lineage). Must be ≥0 on trade opens historically. (Tier 1 — Trade.PositionTbl / History.Credit) |
| 7 | Leverage | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(Leverage, Leverage)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 8 | NetProfit | DECIMAL | YES | Realized PnL. 0 when open; populated on closes in position currency. (Tier 1 — Trade.PositionTbl) |
| 9 | Commission | DECIMAL | YES | Open commission in dollars (`/100` cents conversion on ingest per `Dim_Position` lineage notes). (Tier 1 — Trade.PositionTbl) |
| 10 | PositionID | LONG | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN ActionTypeID = 36 AND CompensationReasonID IN (117, 118) THEN TRY_CAST(REVERSE(SUBSTRING(REVERSE(Description), 1, CHARINDEX(' ', REVERSE(Description)) - 1)) AS BI…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 11 | FundingTypeID | INT | YES | Ledger funding / wallet channel identifier (deposits & cash-outs). Nullable upstream coerced with `ISNULL(...,0)` sentinel row **`0`** (`Dim_FundingType.md`). **Value 27 pairs with redeem flag derivation on cash-outs.** References `Dim_FundingType`. (Tier 1 — History.Credit) |
| 12 | MirrorID | INT | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN Occurred > dm.Occurred THEN 0 ELSE COALESCE(MirrorID, MirrorID) END`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 13 | WithdrawID | INT | YES | Withdrawal request identifier for cash-out credits; 0 when absent. (Tier 1 — History.Credit) |
| 14 | DateID | INT | YES | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 15 | CompensationReasonID | INT | YES | `BackOffice.CompensationReason` code on comps & some opens for airdrops. (Tier 1 — History.Credit, updated wiki 2025-12) |
| 16 | WithdrawPaymentID | INT | YES | Payment-processing key for withdrawals; used to collapse duplicate WithdrawProcessing tuples per historical ETL memo. (Tier 1 — History.Credit) |
| 17 | CommissionOnClose | DECIMAL | YES | Close commission dollars — reopen-adjust net-of-original per `Dim_Position` wiki. **`CommissionOnCloseOrig` preserves untouched close fee.** (Tier 1 — Trade.PositionTbl) |
| 18 | DepositID | INT | YES | Deposit transaction reference on inbound money rows (`NULL` off-deposit actions). (Tier 1 — History.Credit) |
| 19 | FullCommission | DECIMAL | YES | Gross commission inclusive of hidden spread uplift at open (`/100` ingestion note). (Tier 1 — Trade.PositionTbl) |
| 20 | FullCommissionOnClose | DECIMAL | YES | Gross commission on exit — symmetrical reopen-adjust story to `CommissionOnClose`. (Tier 1 — Trade.PositionTbl) |
| 21 | RedeemID | INT | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 22 | RedeemStatus | INT | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 23 | IsRedeem | INT | YES | **Dual-semantics redeem flag.** (A) **Ledger / Crypto-wallet Path:** Loader CASE documented in **`Dim_FundingType.md` §2.3 (`CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`)** tagging **eToroCryptoWallet (`FundingTypeID=27`) cash-outs** (`ActionTypeID = 8` sample slice **100 % FundingType 27 whenever `IsRedeem=1`** for `DateID≥20260101`). Revenue TVF **`Function_Revenue_TransferCoinFee`** filters **`Fact_CustomerAction` with `ActionTypeID = 30` AND `IsRedeem = 1`** — interpret as **transfer-to-coin / fiat-wallet → on-chain custody** (**not** shorthand for bank cash-out). (B) **CFD Billing.Redeem Path:** Positional closes (`ActionTypeID∈{4,5,6,…}`) can emit **`IsRedeem=1` alongside `RedeemID`/`RedeemStatus`** (Billing.Redeem integration per `Trade.PositionTbl`) — orthogonal to transfercoin semantics. CLOSE-branch **`CASE` text unavailable** (`sys.sql_modules.definition` **NULL** for `SP_Fact_CustomerAction` on this Synapse warehouse). **Do not equate blindly to non-existent `Dim_Position.IsRedeem` column.** (Tier 2 — SP_Fact_CustomerAction) |
| 24 | ReopenForPositionID | LONG | YES | When position reopened: erroneous prior **`PositionID`**. NULL if virgin cycle. (Tier 1 — Trade.PositionTbl) |
| 25 | IsReOpen | INT | YES | 1=this position was reopened from `ReopenForPositionID`. CASE WHEN **`ReopenForPositionID`** NOT NULL ⇒1 else0 default. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 26 | CommissionOnCloseOrig | DECIMAL | YES | **`CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0`** — preserves naive close commission before netting. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 27 | FullCommissionOnCloseOrig | DECIMAL | YES | **`CASE WHEN ReopenForPositionID IS NOT NULL THEN FullCommissionOnClose ELSE 0`** (default zeros). (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 28 | OriginalPositionID | LONG | YES | Source position BEFORE partial-split chains. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 29 | IsPartialCloseParent | INT | YES | Marks parent row around partial-close split (subject to **`SP_Fact_CustomerAction_IsParitalCloseParent`** post-job). Analyst filtering nuance persists from `Dim_Position` guidance. (Tier 5 — domain expert, SP_Fact_CustomerAction_IsParitalCloseParent) |
| 30 | IsPartialCloseChild | INT | YES | Marks remainder leg after partial close — filter guidance identical to **`Dim_Position`**: avoid dropping CLOSE child rows blindly. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 31 | PaymentStatusID | INT | YES | Payment pipeline status IDs on inbound/outbound monies — join `Dim_PaymentStatus`. (Tier 5 — domain expert) |
| 32 | IsDiscounted | INT | YES | 1=commission discount applied at open (legacy bit widening). (Tier 1 — Trade.PositionTbl) |
| 33 | IsSettled | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(IsSettled, IsSettled)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 34 | CommissionByUnits | DECIMAL | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 35 | FullCommissionByUnits | DECIMAL | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 36 | IsFTD | INT | YES | First-Time Deposit tagging on qualifying deposit/action rows (NULL elsewhere). Derived during credit classification & snapshot merges. (Tier 2 — SP_Fact_CustomerAction) |
| 37 | IsFeeDividend | INT | YES | Fee subclass for **`ActionTypeID=35`** (1 nightly/weekend fee, 2 dividend, 3 SDRT, 4 ticket aggregates) encoded off **`Description`** heuristics (DSM‑1463). NULL off-fee rows. (Tier 2 — SP_Fact_CustomerAction) |
| 38 | IsAirDrop | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(IsAirDrop, IsAirDrop)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 39 | DividendID | INT | YES | Dividend event pointer for dividend-driven fee deductions. NULL off-dividend. (Tier 1 — Trade.Positions/dividends lineage) |
| 40 | MoveMoneyReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `DividendID, MoveMoneyReasonID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 41 | SettlementTypeID | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(SettlementTypeID, SettlementTypeID)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 42 | etr_y | STRING | YES | Computed in source (transform kind not classified). Formula: `etr_y, etr_ym, etr_ymd, DLTOpen, DLTClose, OpenMarkupByUnits, Description`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 43 | etr_ym | STRING | YES | Computed in source (transform kind not classified). Formula: `etr_y, etr_ym, etr_ymd, DLTOpen, DLTClose, OpenMarkupByUnits, Description`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 44 | etr_ymd | STRING | YES | Computed in source (transform kind not classified). Formula: `etr_y, etr_ym, etr_ymd, DLTOpen, DLTClose, OpenMarkupByUnits, Description`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 45 | DLTOpen | INT | YES | Distributed-ledger telemetry captured at OPEN (Prod addition 2024‑06‑02 per dim wiki). NULL historical. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 46 | DLTClose | INT | YES | Ledger telemetry captured at CLOSE mirroring **`DLTOpen`**. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 47 | OpenMarkupByUnits | DECIMAL | YES | Prorated open markup **`OpenMarkup * AmountInUnitsDecimal / InitialUnits`** for partial closes. (Tier 1 — Trade.Position) |
| 48 | Description | STRING | YES | Operational narrative pulled from Credits / fees ("Over night fee", ticket fee tokens, Payments deposit processor strings). (Tier 1 — History.Credit) |
| 49 | IsBuy | BOOLEAN | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(IsBuy, IsBuy)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 50 | CreditID | LONG | YES | Direct pointer to **`History.Credit.CreditID`** lineage for reversible audits. Added 2025 loader wave. (Tier 1 — History.Credit) |
| 51 | OpenDateID | INT | YES | Arithmetic combination of upstream columns. Formula: `-- Replicated Date IDs CAST(OpenDateID AS INT)`. (Tier 2 — from `main.dwh.dim_position`) |
| 52 | CloseDateID | INT | YES | Cast of upstream column. Formula: `CAST(CloseDateID AS INT)`. (Tier 2 — from `main.dwh.dim_position`) |
| 53 | TicketFeeAction | STRING | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN Description = 'OpenTotalFees' THEN 'Open' WHEN Description = 'CloseTotalFees' THEN 'Close' ELSE NULL END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 54 | RollOverFee | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 35 and isfeedividend = 1 then -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 55 | Dividend | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 35 and isfeedividend = 2 then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 56 | SDRT | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 35 and isfeedividend = 3 then -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 57 | AdminFee | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 117 then -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 58 | SpotAdjustFee | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 118 then -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 59 | ConversionFeeDeposit | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (7, 44) and DepositID is not null then PIPsCalculation else 0 end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`) |
| 60 | ConversionFeeWithdraw | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (8, 45) and WithdrawPaymentID is not null then PIPsCalculation else 0 end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`) |
| 61 | ConversionFeeReversal | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when depositid is not null then -1 * PIPsCalculation else 0 end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_Reversals`) |
| 62 | CashoutFeeExludingRedeem | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 30 and isredeem = 0 then Commission else 0 end`. (Tier 2 — computed in source) |
| 63 | TransferCoinFee | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 30 and isredeem = 1 then Commission else 0 end`. (Tier 2 — computed in source) |
| 64 | DormantFee | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 30 then -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 65 | ShareLendingFeeEtoroShare | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 119 then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 66 | ShareLendingFeeUserShare | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 119 then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 67 | ShareLendingFeeBrokerShare | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 119 then Amount / round(0.425, 1) - 2 * (Amount) else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 68 | ShareLendingGrossAmount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 119 then 2 * Amount + Amount / round(0.425, 1) - 2 * (Amount) else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 69 | CashoutAdjustment | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID in (41, 51) then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 70 | NewCopyAmount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 17 then -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 71 | StopCopyAmount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 18 then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 72 | AddToCopyAmount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 15 then -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 73 | RemoveFromCopyAmount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 16 then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 74 | CryptoToPosition | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 134 then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 75 | BonusCompensation | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 9 then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 76 | PnLAdjustment | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 36 and CompensationReasonID = 22 then Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 77 | InvestedAmountIn | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (1, 2, 3, 39) THEN Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 78 | InvestedAmountOut | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (4, 5, 6, 28, 40) THEN Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 79 | VolumeOpen | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (1, 2, 3, 39) THEN VolumeOnOpen else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 80 | VolumeClose | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (4, 5, 6, 28, 40) THEN VolumeOnClose else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 81 | TicketFeeOpen | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 35 and IsFeeDividend = 4 and ticketfeeaction = 'Open' THEN -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 82 | TicketFeeClose | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid = 35 and IsFeeDividend = 4 and ticketfeeaction = 'Close' THEN -1 * Amount else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 83 | FullCommissionCloseAdjustment | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (4, 5, 6, 28, 40) then (FullCommissionOnClose - FullCommissionByUnits) else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 84 | CommissionCloseAdjustment | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (4, 5, 6, 28, 40) then (CommissionOnClose - CommissionByUnits) else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 85 | FullCommissionTotal | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (1, 2, 3, 39) then FullCommission when actiontypeid IN (4, 5, 6, 28, 40) then (FullCommissionOnClose - FullCommissionByUnits) else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 86 | CommissionTotal | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `case when actiontypeid IN (1, 2, 3, 39) then Commission when actiontypeid IN (4, 5, 6, 28, 40) then (CommissionOnClose - CommissionByUnits) else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 87 | IsActiveTrade | INT | NO | `IsActiveTrade` discriminator: `actiontypeid = 35`, `isfeedividend = 1`, `actiontypeid = 35` → set to 1 else 0. Formula: `case when (actiontypeid = 1 and coalesce(IsAirDrop, 0) = 0 and mirrorid = 0) or actiontypeid in (15, 17) then 1 else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_fact_customeraction_enriched`) |
| 88 | IsSQF | INT | NO | `IsSQF` discriminator: `IsSQF = 1` → set to 1 else 0. Formula: `case when IsSQF = 1 then 1 else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_dim_instrument_enriched`) |
| 89 | Is_245_Instrument | INT | NO | `Is_245_Instrument` discriminator: `Is_245_Instrument = 1` → set to 1 else 0. Formula: `case when Is_245_Instrument = 1 then 1 else 0 end`. (Tier 2 — from `main.etoro_kpi_prep.v_dim_instrument_enriched`) |
| 90 | IsCopyFund | INT | NO | `IsCopyFund` discriminator: `mirrortypeid = 4` (Fund per upstream wiki) → set to 1 else 0. Formula: `case when mirrortypeid = 4 then 1 else 0 end`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 91 | ParentCID | INT | YES | Direct passthrough from upstream. Formula: `ParentCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 92 | ParentUserName | STRING | YES | Direct passthrough from upstream. Formula: `ParentUserName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`) |
| 93 | IsOpenFromIBAN | INT | NO | `IsOpenFromIBAN` computed flag. Formula: `case when ofi.TreeID is not null then 1 else 0 end`. (Tier 2 — computed in source) |
| 94 | IsClosedToIBAN | INT | NO | `IsClosedToIBAN` computed flag. Formula: `case when cti.positionid is not null then 1 else 0 end`. (Tier 2 — computed in source) |
| 95 | IsRecurring | INT | NO | `IsRecurring` discriminator: `actiontypeid IN (1,2,3,39,4,5,6,28,40,35)`, `actiontypeid = 36`, `CompensationReasonID IN (117,118)` → set to 1 else 0. Formula: `case when actiontypeid IN (1,2,3,39,4,5,6,28,40,35) and rip.positionid is not null then 1 when actiontypeid = 36 and CompensationReasonID IN (117,118) and rip.positionid is not null then 1 …`. (Tier 2 — computed in source) |
| 96 | IsC2P | INT | NO | `IsC2P` computed flag. Formula: `case when apl.positionid is not null then 1 else 0 end`. (Tier 2 — computed in source) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.etoro_kpi_prep.v_fact_customeraction_enriched` | Primary | `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_enriched.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.etoro_kpi_prep.v_fact_customeraction_enriched` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee_Reversals.md` |
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi_prep/Views/v_dim_instrument_enriched.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` | JOIN/UNION | `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.PlanInstances.md` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DepositWithdrawFee.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban.md` |
| `main.bi_db.bronze_etoro_trade_adminpositionlog` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md` |

### 5.2 Pipeline ASCII Diagram

```
main.etoro_kpi_prep.v_fact_customeraction_enriched
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee / main.etoro_kpi_prep.v_fact_customeraction_enriched
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
... (8 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_fact_customeraction_w_metrics   ←── this object
        │
        ▼
main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
main.de_output_stg.de_output_etoro_kpi_fact_customeraction_w_metrics
main.etoro_kpi_prep.v_ddr_revenues
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=97 runtime=97 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.etoro_kpi_prep.v_fact_customeraction_enriched` (wiki: `knowledge/UC_generated/etoro_kpi_prep/Views/v_fact_customeraction_enriched.md`)
- **JOIN/UNION upstreams**: 10 additional object(s)
- **Wiki coverage**: 8/10 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`
- `main.de_output_stg.de_output_etoro_kpi_fact_customeraction_w_metrics`
- `main.etoro_kpi_prep.v_ddr_revenues`

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 10 | Formulas: 97 | Tiers: 25 T1, 68 T2, 1 T3, 0 T4, 3 T5, 0 TN, 0 U | Elements: 97/97 | Source: view_definition*
