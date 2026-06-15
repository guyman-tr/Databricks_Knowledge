---
object_fqn: main.etoro_kpi.ddr_mimo_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.ddr_mimo_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 24
row_count: null
generated_at: '2026-05-19T15:20:37Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
- main.bi_output.bi_output_vg_date
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_mimo_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ddr_mimo_v.sql
concept_count: 0
formula_count: 24
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 21
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# ddr_mimo_v

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 24 of 24 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_mimo_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 24 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Sun May 03 14:03:00 UTC 2026 |

---

## 1. Business Meaning

`ddr_mimo_v` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 24 columns: 3 inherit byte-for-byte from upstream wikis (Tier 1), 21 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

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
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Ledger business date partition key duplicated from `@date`. `CAST(CONVERT(varchar(8),@date,112) AS int)` seeded into `#depositsTP`/`#cashoutTP`, carried through UNION. DELETE partition uses same `@dateID`. **AllPlatforms transforms:** `#globalMIMO` passes sibling `DateID`; MoneyFarm uses `CAST(FORMAT(gf.FirstDepositDate,'yyyyMMdd') AS int)` from **`#moneyfarmFTDs`**. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 1 | Date | TIMESTAMP | YES | Calendar counterpart to `DateID`; **`INSERT`** uses `@date AS [Date]` for **`#final` rows**; **`MoneyFarm`** uses `CAST(gf.FirstDepositDate AS date)`. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 2 | WeekNumberYear | INT | YES | Direct passthrough from upstream. Formula: `WeekNumberYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | CalendarYearMonth | STRING | YES | Direct passthrough from upstream. Formula: `CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | CalendarQuarter | INT | YES | Direct passthrough from upstream. Formula: `CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 5 | CalendarYear | INT | YES | Direct passthrough from upstream. Formula: `CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 6 | RealCID | STRING | YES | Global Real Customer Identifier on the ledger row (`fca.RealCID`). (Tier 1 — Customer.CustomerStatic) |
| 7 | MIMOAction | STRING | YES | Stable label `'Deposit'` or `'Withdraw'` from UNION halves. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 8 | OrigIdentifier | STRING | YES | **Trading Platform (verbatim Element #5 `BI_DB_DDR_Fact_MIMO_Trading_Platform.md`):** Literal discriminator `'DepositID'` vs `'WithdrawPaymentID'` aligning `TransactionID` grain. **eMoney (verbatim Element #5 `BI_DB_DDR_Fact_MIMO_eMoney_Platform.md`):** Source ID type label — Always `'TransactionID'` for all eMoney transactions. **Options (verbatim Element #5 `BI_DB_DDR_Fact_MIMO_Options_Platform.md`):** Hardcoded `'ApexTxID'` in source facts (coerced Transactions may null out). **MoneyFarm (SP literals):** `'DepositID'` inside `#moneyfarmFTDs`. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 9 | TransactionID | INT | YES | `DepositID` for deposits (`ActionTypeID` 7/44) OR `WithdrawPaymentID` for withdraw rows (`ActionTypeID` 8/45). ROW_NUMBER dedupe trims duplicate `(MIMOAction, TransactionID)` pairs (`BI_DB_DDR_Fact_MIMO_Trading_Platform` lineage baseline). **AllPlatforms transforms:** `CAST(f.TransactionID AS varchar(50))` persisted into `INT` from `#final`; `UPDATE #final SET TransactionID=NULL WHERE MIMOPlatform='Options'`; Options **`INSERT`** uses literal `0 AS TransactionID`; MoneyFarm literals `0` with outer **`isnull(TransactionID,-1)`** guard. **Not all platforms joinable naïvely.** (Tier 2 — Fact_CustomerAction) |
| 10 | AmountUSD | DECIMAL | YES | `fca.Amount` from `Fact_CustomerAction WHERE ActionTypeID IN (7,44)` (deposits) or `IN (8,45)` (withdrawals) at `@dateID`. **AllPlatforms:** passthrough **`#final`** (see sibling facts); **`MoneyFarm`** uses `gf.FirstDepositAmount` (**`#moneyfarmFTDs`**). **eMoney negatives** retained from sibling negatives for withdrawals (**see **`BI_DB_DDR_Fact_MIMO_eMoney_Platform.md §2.5`**)**. (Tier 2 — Fact_CustomerAction) |
| 11 | AmountOrigCurrency | DECIMAL | YES | Deposit: `fbd.Amount`. Withdraw: `COALESCE(bddwf.Amount, ROUND( ROUND(fbw.Amount_WithdrawToFunding,6) / NULLIF(ROUND(fbw.ExchangeRate,6),0), 6))` with joins defined in `#cashoutTP`. **MoneyFarm sentinel `-1`** (no original-ccy fidelity in synthetic FTD stitch). Options equals USD per sibling fact. **(Tier 2 — Fact_BillingDeposit / Fact_BillingWithdraw)** |
| 12 | FundingTypeID | INT | YES | Deposit: `fbd.FundingTypeID`. Withdraw: `fbw.FundingTypeID_Funding`. Type of funding instrument powering the payout leg. Deposit description reference: Fact_BillingDeposit column #17 semantics. Withdraw description reference: `FundingTypeID_Funding` semantics in `Fact_BillingWithdraw`. **`MoneyFarm` sentinel `-1`**. **`Options`** generally `0`. **Tier attribution preserved from TP wiki mix.** **(Tier 2 — Fact_BillingDeposit / Billing.Funding)** |
| 13 | CurrencyID | INT | YES | Deposit: `fbd.CurrencyID` — “Currency of the deposit amount…” (Billing upstream). Withdraw: `fbw.ProcessCurrencyID` — “Currency used for the actual payment processing…” (Billing.WithdrawToFunding upstream). Same column merges both semantics via SP branch. **`MoneyFarm` literal `3`**. **`Options`** **`1`** (USD). **(Tier 1 — upstream wiki, Billing.Deposit / Billing.WithdrawToFunding)** |
| 14 | Currency | STRING | YES | Ticker symbol (`dc.Abbreviation`) joined on `CurrencyID`/`ProcessCurrencyID`. `"USD","EUR"` forex; equities/crypto codes per dictionary. Passthrough from `Dim_Currency`. **`MoneyFarm` literal `'GBP'`**. **(Tier 1 — Dictionary.Currency)** |
| 15 | IsPlatformFTD | INT | YES | **`IsFTD` relay from sibling facts surfaced as **`IsPlatformFTD` in **`#final` (`m.IsFTD AS IsPlatformFTD`) with `INSERT ISNULL(IsPlatformFTD,0)`.** Recoveries per SP blocks **JOIN `Dim_Customer` / `eMoney_Fact_Transaction_Status` when `DateID>=20250901`.** Interpret per-platform using sibling docs (**`TradingPlatform`** vs **`eMoney`** **`FTDPlatformID` expectations** vs **`MoneyFarm` synthetic **`1`**). **(Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms)** |
| 16 | IsInternalTransfer | INT | YES | `CASE WHEN FundingTypeID = 33 THEN 1 ELSE 0` (deposit branch on `fbd.FundingTypeID`; withdraw branch on `fbw.FundingTypeID_Funding`). Mirrors IBAN/quick-transfer interplay described in changelog. **`INSERT ISNULL`; Options inherits `bddfmop.IsInternalTransfer`; MoneyFarm literal `0`.** **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |
| 17 | IsRedeem | INT | YES | **Transfer-to-coin / transfercoin flag on Money-Out.** Withdraw leg reads `fca.IsRedeem` with `WHERE fca.ActionTypeID IN (8,45)`. Deposit UNION hard-codes literal `0` after `#depositsTP` seeded `NULL`. INSERT applies `ISNULL(IsRedeem,0)`. Interpret `1` as customer movement from TP fiat wallet into on-chain/crypto custody—not “redeem to bank.” Cross-surface: revenue TVF **`Function_Revenue_TransferCoinFee`** documents `Fact_CustomerAction` rows **`ActionTypeID = 30` AND `IsRedeem = 1`** for TransferCoinFee commissions tied to transfercoin redemption. (Tier 2 — Fact_CustomerAction) |
| 18 | IsTradeFromIBAN | INT | YES | Deposit: `CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0`; Withdraw: `CASE WHEN fca.ActionTypeID = 45 THEN 1 ELSE 0`. Flags sweep-style IBAN internal deposit/withdraw events. **AllPlatforms mapping:** **`f.IsIBANTrade` from **`#final`** (`tm.IsIBANTrade` ∪ `im.IsTradeFromIBAN`) with **`INSERT ISNULL(f.IsIBANTrade,0)` targeting column `IsTradeFromIBAN`.** **Options / MoneyFarm literal `0`.** **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |
| 19 | MIMOPlatform | STRING | YES | **ETL literals** `'TradingPlatform'`, `'eMoney'`, `'Options'`, `'MoneyFarm'` (see §2.1). Jan‑2026 sample distribution on single day partition enumerated in §1. **(Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms)** |
| 20 | IsGlobalFTD | INT | YES | **Primary path (#final INSERT):** `CASE WHEN f.RealCID IS NOT NULL THEN 1 ELSE 0` after `LEFT JOIN #globalFTDs f` on **`m.MIMOAction='Deposit' AND m.RealCID=f.RealCID AND m.IsFTD=1 AND m.FTDPlatformID=f.FTDPlatformID`** where **`f` originates from **`BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0)`** ( **`#globalFTDs`** ). **MoneyFarm synthetic rows forced `1`.** **`INSERT ISNULL` + recovery UPDATE overlays.** **`Options`** second INSERT **`SELECT bddfmop.IsGlobalFTD` (no `#globalFTDs` JOIN in that block). Interpret per **`Function_MIMO_First_Deposit_All_Platforms` §1 business meaning**: date‑routed spine across IBAN / TP extracts with **`REMOVE_BAD_FTDS`** handling. **(Tier 2 — Function_MIMO_First_Deposit_All_Platforms / SP_DDR_Fact_Fact_MIMO_AllPlatforms)** |
| 21 | IsCryptoToFiat | INT | YES | Explicit literal `0` — reserved column (C2F captured on other DDR MIMO siblings). `INSERT SELECT … , 0 AS IsCryptoToFiat`. **PLUS `UPDATE`** sets **`1`** for **`FundingTypeID=27` TP deposits `DateID>=20250701` (see §2.5). **eMoney** uses **`TxTypeID=14`** per sibling (**`BI_DB_ddr…eMoney`**). **`Options`/MoneyFarm forced `0` on insert.** **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |
| 22 | IsRecurring | INT | YES | `1=deposit is part of a recurring schedule (OUTER APPLY on Billing.RecurringDeposit). 0=one-time deposit.` carries only on deposit UNION; `'Withdraw'` half injects literal `0`. Final `INSERT` uses `ISNULL(t.IsRecurring,0)`. **`Options`/MoneyFarm insert literal `0`.** **eMoney sibling remains placeholder zeros.** **(Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)** |
| 23 | IsIBANQuickTransfer | INT | YES | Internal transfer discriminator `CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0` on both halves (SP changelog `20250611`). **AllPlatforms** `INSERT` applies `ISNULL`; **Options** / **MoneyFarm** literals `0`. **eMoney** wiring caveat: sibling fact still hard‑codes **`0`** — enrichment may occur only downstream — cross‑check **`BI_DB_DDR_Fact_MIMO_eMoney_Platform.md` §3.4**. **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |
| `main.bi_output.bi_output_vg_date` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
main.bi_output.bi_output_vg_date
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
        │
        ▼
main.etoro_kpi.ddr_mimo_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=24 runtime=24 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 24 | Tiers: 3 T1, 21 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 24/24 | Source: view_definition*
