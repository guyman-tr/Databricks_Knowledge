---
object_fqn: main.etoro_kpi_prep.v_fact_customeraction_enriched
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_fact_customeraction_enriched
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 79
row_count: null
generated_at: '2026-05-19T12:26:24Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
- main.dwh.dim_position
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_enriched.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_enriched.sql
concept_count: 2
formula_count: 79
tier_breakdown:
  tier1_columns: 35
  tier2_columns: 30
  tier3_columns: 4
  tier4_columns: 0
  tier5_columns: 10
  tier_null_columns: 0
  unverified_columns: 0
---

# v_fact_customeraction_enriched

> View in `main.etoro_kpi_prep`. 2 business concept(s) in §2; 65 of 79 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_fact_customeraction_enriched` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 79 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | 3 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Thu Mar 26 15:35:18 UTC 2026 |

---

## 1. Business Meaning

`v_fact_customeraction_enriched` is a view in `main.etoro_kpi_prep` that composes 2 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 79 columns: 35 inherit byte-for-byte from upstream wikis (Tier 1), 30 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Filter on scope `passive_actions_enriched`: `ActionTypeID = 19`
**What**: `WHERE` clause at the top of scope `passive_actions_enriched` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `ActionTypeID`
**Rules**:
- `ActionTypeID = 19`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_enriched.sql` L58

### 2.2 Filter on scope `active_actions`: `ActionTypeID = 35`; `ActionTypeID = 36`
**What**: `WHERE` clause at the top of scope `active_actions` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `ActionTypeID`, `ActionTypeID`
**Rules**:
- `ActionTypeID = 35`
- `ActionTypeID = 36`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_fact_customeraction_enriched.sql` L88

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
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `passive_actions_enriched` applies `ActionTypeID = 19` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `active_actions` applies `ActionTypeID = 35`; `ActionTypeID = 36` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | DECIMAL | YES | Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert) |
| 1 | GCID | INT | YES | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | INT | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 3 | DemoCID | INT | YES | Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 4 | Occurred | TIMESTAMP | YES | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 5 | IPNumber | LONG | YES | IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login) |
| 6 | IsReal | INT | YES | Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 7 | ActionTypeID | INT | YES | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds. (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) |
| 8 | PlatformTypeID | INT | YES | Legacy platform discriminator (`0` default; `99` STS-heavy logins sampled 202601+). (Tier 3 — ETL-assigned) |
| 9 | InstrumentID | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(InstrumentID, InstrumentID)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 10 | Amount | DECIMAL | YES | Position / ledger amount discipline per branch (cash change on opens; fee/deposit sizing on ledger rows — see lineage). Must be ≥0 on trade opens historically. (Tier 1 — Trade.PositionTbl / History.Credit) |
| 11 | Leverage | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(Leverage, Leverage)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 12 | NetProfit | DECIMAL | YES | Realized PnL. 0 when open; populated on closes in position currency. (Tier 1 — Trade.PositionTbl) |
| 13 | Commission | DECIMAL | YES | Open commission in dollars (`/100` cents conversion on ingest per `Dim_Position` lineage notes). (Tier 1 — Trade.PositionTbl) |
| 14 | PositionID | LONG | YES | Position identifier from the source trading system. NOT a primary key of this table — defaults to 0 for non-position events, and the same PositionID appears in both open and close rows. |
| 15 | CampaignID | INT | YES | Marketing campaign identifier — 0 if not campaign-bound. References `Dim_Campaign`. (Tier 5 — domain expert) |
| 16 | BonusTypeID | INT | YES | Bonus classifier on bonus credit rows (`ActionTypeID=9`). 0 elsewhere. References `Dim_BonusType`. (Tier 5 — domain expert) |
| 17 | FundingTypeID | INT | YES | Ledger funding / wallet channel identifier (deposits & cash-outs). Nullable upstream coerced with `ISNULL(...,0)` sentinel row **`0`** (`Dim_FundingType.md`). **Value 27 pairs with redeem flag derivation on cash-outs.** References `Dim_FundingType`. (Tier 1 — History.Credit) |
| 18 | LoginID | INT | YES | Billing login session key (`Billing.Login` lineage). 0 off-login. (Tier 1 — Billing.Login) |
| 19 | MirrorID | INT | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN Occurred > dm.Occurred THEN 0 ELSE COALESCE(MirrorID, MirrorID) END`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 20 | WithdrawID | INT | YES | Withdrawal request identifier for cash-out credits; 0 when absent. (Tier 1 — History.Credit) |
| 21 | DurationInSeconds | INT | YES | Login session dwell seconds (NULL outside login cashier events). (Tier 1 — Billing.Login) |
| 22 | PostID | STRING | YES | Social GUID for deprecated social action types (**21‑26**) — stale per historical wiki audits. NULL otherwise. (Tier 1 — Social platform) |
| 23 | CaseID | INT | YES | CRM case (`ActionTypeID=31`). 0 default. (Tier 1 — CRM) |
| 24 | UpdateDate | TIMESTAMP | YES | Last successful fact loader write (`GETDATE()`/`GETUTCDATE()` parity in ops). (Tier 2 — SP_Fact_CustomerAction) |
| 25 | DateID | INT | YES | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 26 | TimeID | INT | YES | Hour bucket `DATEPART(HOUR,Occurred)`. (Tier 2 — SP_Fact_CustomerAction) |
| 27 | StatusID | INT | YES | Row vitality flag (**1** almost always; rare NULL cohort). (Tier 3 — ETL-assigned) |
| 28 | PreviousOccurred | TIMESTAMP | YES | Deprecated / unreliable historical column — analysts should ignore. (Tier 5 — domain expert) |
| 29 | CompensationReasonID | INT | YES | `BackOffice.CompensationReason` code on comps & some opens for airdrops. (Tier 1 — History.Credit, updated wiki 2025-12) |
| 30 | WithdrawPaymentID | INT | YES | Payment-processing key for withdrawals; used to collapse duplicate WithdrawProcessing tuples per historical ETL memo. (Tier 1 — History.Credit) |
| 31 | CommissionOnClose | DECIMAL | YES | Close commission dollars — reopen-adjust net-of-original per `Dim_Position` wiki. **`CommissionOnCloseOrig` preserves untouched close fee.** (Tier 1 — Trade.PositionTbl) |
| 32 | IsPlug | BOOLEAN | YES | Deprecated placeholder (`NULL`). (Tier 5 — domain expert) |
| 33 | DepositID | INT | YES | Deposit transaction reference on inbound money rows (`NULL` off-deposit actions). (Tier 1 — History.Credit) |
| 34 | PostRootID | STRING | YES | Deprecated social threading key. NULL off-social. (Tier 1 — Social platform) |
| 35 | FullCommission | DECIMAL | YES | Gross commission inclusive of hidden spread uplift at open (`/100` ingestion note). (Tier 1 — Trade.PositionTbl) |
| 36 | FullCommissionOnClose | DECIMAL | YES | Gross commission on exit — symmetrical reopen-adjust story to `CommissionOnClose`. (Tier 1 — Trade.PositionTbl) |
| 37 | RedeemID | INT | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 38 | RedeemStatus | INT | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 39 | SessionID | LONG | YES | STS session BIGINT for opens/logins (`NULL` off those branches). (Tier 1 — STS) |
| 40 | IsRedeem | INT | YES | **Dual-semantics redeem flag.** (A) **Ledger / Crypto-wallet Path:** Loader CASE documented in **`Dim_FundingType.md` §2.3 (`CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`)** tagging **eToroCryptoWallet (`FundingTypeID=27`) cash-outs** (`ActionTypeID = 8` sample slice **100 % FundingType 27 whenever `IsRedeem=1`** for `DateID≥20260101`). Revenue TVF **`Function_Revenue_TransferCoinFee`** filters **`Fact_CustomerAction` with `ActionTypeID = 30` AND `IsRedeem = 1`** — interpret as **transfer-to-coin / fiat-wallet → on-chain custody** (**not** shorthand for bank cash-out). (B) **CFD Billing.Redeem Path:** Positional closes (`ActionTypeID∈{4,5,6,…}`) can emit **`IsRedeem=1` alongside `RedeemID`/`RedeemStatus`** (Billing.Redeem integration per `Trade.PositionTbl`) — orthogonal to transfercoin semantics. CLOSE-branch **`CASE` text unavailable** (`sys.sql_modules.definition` **NULL** for `SP_Fact_CustomerAction` on this Synapse warehouse). **Do not equate blindly to non-existent `Dim_Position.IsRedeem` column.** (Tier 2 — SP_Fact_CustomerAction) |
| 41 | RegulationIDOnOpen | INT | YES | Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 42 | PlatformID | INT | YES | Product/platform identifier — badly named, references `Dim_Product.ProductID`; resolve Product/Platform/SubPlatform columns via JOIN (`ActionTypeID` **14**/ **41** focus). (Tier 5 — domain expert) |
| 43 | ReopenForPositionID | LONG | YES | When position reopened: erroneous prior **`PositionID`**. NULL if virgin cycle. (Tier 1 — Trade.PositionTbl) |
| 44 | IsReOpen | INT | YES | 1=this position was reopened from `ReopenForPositionID`. CASE WHEN **`ReopenForPositionID`** NOT NULL ⇒1 else0 default. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 45 | CommissionOnCloseOrig | DECIMAL | YES | **`CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0`** — preserves naive close commission before netting. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 46 | FullCommissionOnCloseOrig | DECIMAL | YES | **`CASE WHEN ReopenForPositionID IS NOT NULL THEN FullCommissionOnClose ELSE 0`** (default zeros). (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 47 | OriginalPositionID | LONG | YES | Source position BEFORE partial-split chains. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 48 | IsPartialCloseParent | INT | YES | Marks parent row around partial-close split (subject to **`SP_Fact_CustomerAction_IsParitalCloseParent`** post-job). Analyst filtering nuance persists from `Dim_Position` guidance. (Tier 5 — domain expert, SP_Fact_CustomerAction_IsParitalCloseParent) |
| 49 | IsPartialCloseChild | INT | YES | Marks remainder leg after partial close — filter guidance identical to **`Dim_Position`**: avoid dropping CLOSE child rows blindly. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 50 | InitialUnits | DECIMAL | YES | Opening unit count denominator for partial proration ladders. (Tier 1 — Trade.PositionTbl) |
| 51 | PaymentStatusID | INT | YES | Payment pipeline status IDs on inbound/outbound monies — join `Dim_PaymentStatus`. (Tier 5 — domain expert) |
| 52 | IsDiscounted | INT | YES | 1=commission discount applied at open (legacy bit widening). (Tier 1 — Trade.PositionTbl) |
| 53 | IsSettled | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(IsSettled, IsSettled)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 54 | CommissionByUnits | DECIMAL | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 55 | FullCommissionByUnits | DECIMAL | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 56 | IsFTD | INT | YES | First-Time Deposit tagging on qualifying deposit/action rows (NULL elsewhere). Derived during credit classification & snapshot merges. (Tier 2 — SP_Fact_CustomerAction) |
| 57 | CountryIDByIP | INT | YES | Geo-IP-derived country surrogate — join **`Dim_Country`**. (Tier 5 — domain expert) |
| 58 | IsAnonymousIP | INT | YES | Anonymous / proxy heuristic flag STS path. NULL off relevant rows. (Tier 1 — IP geolocation service) |
| 59 | ProxyType | STRING | YES | Proxy taxonomy (`DCH`, `VPN`, `TOR`, etc.) from STS classifications. NULL if direct. (Tier 1 — STS) |
| 60 | IsFeeDividend | INT | YES | Fee subclass for **`ActionTypeID=35`** (1 nightly/weekend fee, 2 dividend, 3 SDRT, 4 ticket aggregates) encoded off **`Description`** heuristics (DSM‑1463). NULL off-fee rows. (Tier 2 — SP_Fact_CustomerAction) |
| 61 | IsAirDrop | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(IsAirDrop, IsAirDrop)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 62 | DividendID | INT | YES | Dividend event pointer for dividend-driven fee deductions. NULL off-dividend. (Tier 1 — Trade.Positions/dividends lineage) |
| 63 | MoveMoneyReasonID | INT | YES | NULL in all archive branches; natively populated only in History.ActiveCredit. Do not join from this view. (Tier 1 - History.Credit.md) |
| 64 | SettlementTypeID | INT | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(SettlementTypeID, SettlementTypeID)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 65 | etr_y | STRING | YES | Computed in source (transform kind not classified). Formula: `etr_y, etr_ym, etr_ymd, DLTOpen, DLTClose, OpenMarkupByUnits, Description`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 66 | etr_ym | STRING | YES | Computed in source (transform kind not classified). Formula: `etr_y, etr_ym, etr_ymd, DLTOpen, DLTClose, OpenMarkupByUnits, Description`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 67 | etr_ymd | STRING | YES | Computed in source (transform kind not classified). Formula: `etr_y, etr_ym, etr_ymd, DLTOpen, DLTClose, OpenMarkupByUnits, Description`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 68 | DLTOpen | INT | YES | Distributed-ledger telemetry captured at OPEN (Prod addition 2024‑06‑02 per dim wiki). NULL historical. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 69 | DLTClose | INT | YES | Ledger telemetry captured at CLOSE mirroring **`DLTOpen`**. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 70 | OpenMarkupByUnits | DECIMAL | YES | Prorated open markup **`OpenMarkup * AmountInUnitsDecimal / InitialUnits`** for partial closes. (Tier 1 — Trade.Position) |
| 71 | Description | STRING | YES | Operational narrative pulled from Credits / fees ("Over night fee", ticket fee tokens, Payments deposit processor strings). (Tier 1 — History.Credit) |
| 72 | IsBuy | BOOLEAN | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(IsBuy, IsBuy)`. (Tier 2 — from `main.dwh.dim_position`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |
| 73 | CreditID | LONG | YES | Direct pointer to **`History.Credit.CreditID`** lineage for reversible audits. Added 2025 loader wave. (Tier 1 — History.Credit) |
| 74 | OpenDateID | INT | YES | Arithmetic combination of upstream columns. Formula: `-- Replicated Date IDs CAST(OpenDateID AS INT)`. (Tier 2 — from `main.dwh.dim_position`) |
| 75 | CloseDateID | INT | YES | Cast of upstream column. Formula: `CAST(CloseDateID AS INT)`. (Tier 2 — from `main.dwh.dim_position`) |
| 76 | VolumeOnOpen | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `-- Volume set to NULL for Passive Actions to prevent aggregation duplication CAST(NULL AS DECIMAL(38,6))`. (Tier 2 — computed in source) |
| 77 | VolumeOnClose | DECIMAL | YES | Cast of upstream column. Formula: `CAST(NULL AS DECIMAL(38,6))`. (Tier 2 — computed in source) |
| 78 | TicketFeeAction | STRING | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN Description = 'OpenTotalFees' THEN 'Open' WHEN Description = 'CloseTotalFees' THEN 'Close' ELSE NULL END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.dim_position` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
main.dwh.dim_position
        │
        ▼
main.etoro_kpi_prep.v_fact_customeraction_enriched   ←── this object
        │
        ▼
main.bi_output_stg.etoro_kpi_prep_stg_factcustomeraction_w_metrics
main.etoro_kpi_prep.v_fact_customeraction_w_metrics
main.etoro_kpi_prep_stg.v_fact_customeraction_w_metrics
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=79 runtime=79 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 0/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output_stg.etoro_kpi_prep_stg_factcustomeraction_w_metrics`
- `main.etoro_kpi_prep.v_fact_customeraction_w_metrics`
- `main.etoro_kpi_prep_stg.v_fact_customeraction_w_metrics`

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 79 | Tiers: 35 T1, 30 T2, 4 T3, 0 T4, 10 T5, 0 TN, 0 U | Elements: 79/79 | Source: view_definition*
