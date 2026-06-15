---
object_fqn: main.etoro_kpi_prep.v_mimo_emoneyplatform
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_mimo_emoneyplatform
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 21
row_count: null
generated_at: '2026-05-19T12:04:41Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql
concept_count: 15
formula_count: 21
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 21
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_mimo_emoneyplatform

> View in `main.etoro_kpi_prep`. 15 business concept(s) in §2; 21 of 21 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_mimo_emoneyplatform` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 21 |
| **Concepts** | 15 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Mar 24 12:40:28 UTC 2026 |

---

## 1. Business Meaning

`v_mimo_emoneyplatform` is a view in `main.etoro_kpi_prep` that composes a UNION ALL with sign-flipped amount legs (deposit/withdraw composition), 8 CASE-based classifier flag(s) computed from upstream IDs, 2 JOIN-enriched dimension lookup(s), plus 1 additional concept(s) (see §2).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md`. Additional upstreams: 2 object(s), listed in §5 Lineage.

Of its 21 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 21 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `FundingTypeID` discriminator: `TxTypeID IN (5)` (TransferReceived per upstream wiki) → set to 33 else 0
**What**: Computed flag on `FundingTypeID` set to `33` when the predicates below hold, else `0`.
**Columns Involved**: `FundingTypeID`
**Rules**:
- `TxTypeID IN (5)` (TransferReceived per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` etoro_kpi_prep.sql L33-L33
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`

### 2.2 `IsFTD` computed flag
**What**: Computed flag on `IsFTD` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsFTD`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` etoro_kpi_prep.sql L36-L36
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.3 `IsInternalTransfer` discriminator: `TxTypeID IN (5)` (TransferReceived per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsInternalTransfer` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsInternalTransfer`
**Rules**:
- `TxTypeID IN (5)` (TransferReceived per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` etoro_kpi_prep.sql L37-L37
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`

### 2.4 `IsTradeFromIBAN` discriminator: `TxStatusModificationDateID >= 20240403`, `TxTypeID = 5` → set to 1 else 0
**What**: Computed flag on `IsTradeFromIBAN` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsTradeFromIBAN`
**Rules**:
- `TxStatusModificationDateID >= 20240403`
- `TxTypeID = 5`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` etoro_kpi_prep.sql L40-L46

### 2.5 `IsCryptoToFiat` discriminator: `TxTypeID IN (14)` (CryptoToFiat per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsCryptoToFiat` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsCryptoToFiat`
**Rules**:
- `TxTypeID IN (14)` (CryptoToFiat per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` etoro_kpi_prep.sql L47-L47
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`

### 2.6 `FundingTypeID` discriminator: `TxTypeID IN (6)` (Transfer per upstream wiki) → set to 33 else 0
**What**: Computed flag on `FundingTypeID` set to `33` when the predicates below hold, else `0`.
**Columns Involved**: `FundingTypeID`
**Rules**:
- `TxTypeID IN (6)` (Transfer per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` etoro_kpi_prep.sql L67-L67
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`

### 2.7 `IsInternalTransfer` discriminator: `TxTypeID IN (6)` (Transfer per upstream wiki) → set to 1 else 0
**What**: Computed flag on `IsInternalTransfer` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsInternalTransfer`
**Rules**:
- `TxTypeID IN (6)` (Transfer per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` etoro_kpi_prep.sql L71-L71
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`

### 2.8 `IsTradeFromIBAN` discriminator: `TxStatusModificationDateID >= 20240403`, `TxTypeID = 6` → set to 1 else 0
**What**: Computed flag on `IsTradeFromIBAN` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsTradeFromIBAN`
**Rules**:
- `TxStatusModificationDateID >= 20240403`
- `TxTypeID = 6`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` etoro_kpi_prep.sql L74-L80

### 2.9 Sign-flip leg `cashout_iban` (multiplies `AmountUSD`, `AmountOrigCurrency` by -1)
**What**: This subselect contributes the negative-sign leg of a UNION ALL composition — amount columns are multiplied by -1 so the downstream rollup nets to (deposit - withdraw).
**Columns Involved**: `AmountUSD`, `AmountOrigCurrency`
**Rules**:
- `-1 * mfts.USDAmountApprox` (sign-flip on amount)
- `-1 * mfts.LocalAmount` (sign-flip on amount)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` L65,L66
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`

### 2.10 Dim lookup via alias `dc1` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.FTDTransactionID = mfts.SourceCugTransactionID     AND dc1.FTDPlatformID = 3`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` L16
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.11 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_currency`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_currency` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `mfts.HolderCurrencyISO = dc.Abbreviation`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` L49,L83
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`

### 2.12 Filter on scope `ftd_iban`: `TxStatusID = 2`
**What**: `WHERE` clause at the top of scope `ftd_iban` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `TxStatusID`
**Rules**:
- `TxStatusID = 2`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` L19

### 2.13 Filter on scope `deposits_iban`: `TxStatusID = 2`
**What**: `WHERE` clause at the top of scope `deposits_iban` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `TxStatusID`
**Rules**:
- `TxStatusID = 2`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` L53

### 2.14 Filter on scope `cashout_iban`: `TxStatusID = 2`
**What**: `WHERE` clause at the top of scope `cashout_iban` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `TxStatusID`
**Rules**:
- `TxStatusID = 2`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` L85

### 2.15 Filter on scope `mimo_iban_deduped`: `RN = 1`
**What**: `WHERE` clause at the top of scope `mimo_iban_deduped` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `RN`
**Rules**:
- `RN = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_mimo_emoneyplatform.sql` L99

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
| Filter on discriminator flags | Use `FundingTypeID = 1`-style filters on the precomputed flag columns (`FundingTypeID`, `IsCryptoToFiat`, `IsFTD`, `IsInternalTransfer`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_dwh_dbo_dim_currency`). |
| Sum amounts directly for net flow | Amount columns are already sign-flipped per leg — summing them yields net flow (deposits - withdraws). No need to subset by MIMOAction unless you want gross flow. |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `dc1.FTDTransactionID = mfts.SourceCugTransactionID     AND dc1.FTDPlatformID = 3` | Lookup via alias `dc1` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | `mfts.HolderCurrencyISO = dc.Abbreviation` | Lookup via alias `dc` |

### 3.4 Gotchas

- Scope `ftd_iban` applies `TxStatusID = 2` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `deposits_iban` applies `TxStatusID = 2` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `cashout_iban` applies `TxStatusID = 2` unconditionally — rows failing these predicates are NOT in this view's output.
- Scope `mimo_iban_deduped` applies `RN = 1` unconditionally — rows failing these predicates are NOT in this view's output.
- Sign flip in scope(s) `cashout_iban` means summing amount columns nets to (deposit - withdraw). Multiply by -1 again if you want gross withdraw amounts.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Direct passthrough from upstream. Formula: `TxStatusModificationDateID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 1 | Date | DATE | YES | Cast of upstream column. Formula: `CAST(TxStatusModificationDate AS DATE)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 2 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `CID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 3 | MIMOAction | STRING | NO | Literal constant set in this object. Formula: `'Deposit'`. (Tier 2 — literal) |
| 4 | OrigIdentifier | STRING | NO | Literal constant set in this object. Formula: `'TransactionID'`. (Tier 2 — literal) |
| 5 | TransactionID | INT | NO | COALESCE / null-replacement of upstream values. Formula: `COALESCE(TransactionID, -1)`. (Tier 2 — computed in source) |
| 6 | ReferenceNumber | STRING | NO | COALESCE / null-replacement of upstream values. Formula: `COALESCE(ReferenceNumber, '-1')`. (Tier 2 — computed in source) |
| 7 | AmountUSD | DECIMAL | YES | COALESCE / null-replacement of upstream values. Formula: `COALESCE(USDAmountApprox, USDAmountApprox)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 8 | AmountOrigCurrency | DECIMAL | YES | Direct passthrough from upstream. Formula: `LocalAmount`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 9 | FundingTypeID | INT | NO | `FundingTypeID` discriminator: `TxTypeID IN (5)` (TransferReceived per upstream wiki) → set to 33 else 0. Formula: `CASE WHEN TxTypeID IN (5) THEN 33 ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 10 | CurrencyID | INT | YES | Direct passthrough from upstream. Formula: `CurrencyID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`) |
| 11 | Currency | STRING | YES | Direct passthrough from upstream. Formula: `HolderCurrencyDesc`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 12 | IsFTD | INT | NO | `IsFTD` computed flag. Formula: `CASE WHEN TransactionID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 13 | IsInternalTransfer | INT | NO | `IsInternalTransfer` discriminator: `TxTypeID IN (5)` (TransferReceived per upstream wiki) → set to 1 else 0. Formula: `CASE WHEN TxTypeID IN (5) THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 14 | IsRedeem | INT | NO | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 15 | TxTypeID | INT | YES | Transaction type identifier. 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat (15=CryptoToFiat via dictionary). Passthrough from FiatTransactions.TransactionTypeId. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 16 | IsTradeFromIBAN | INT | NO | `IsTradeFromIBAN` discriminator: `TxStatusModificationDateID >= 20240403`, `TxTypeID = 5` → set to 1 else 0. Formula: `CASE WHEN LEFT(ReferenceNumber, 1) != 'P' AND TxStatusModificationDateID >= 20240403 AND TxTypeID = 5 THEN 1 ELSE 0 END`. (Tier 2 — computed in source) |
| 17 | IsCryptoToFiat | INT | NO | `IsCryptoToFiat` discriminator: `TxTypeID IN (14)` (CryptoToFiat per upstream wiki) → set to 1 else 0. Formula: `CASE WHEN TxTypeID IN (14) THEN 1 ELSE 0 END`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`) |
| 18 | IsRecurring | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 19 | IsIBANQuickTransfer | INT | NO | Literal constant set in this object. Formula: `0`. (Tier 2 — literal) |
| 20 | UpdateDate | TIMESTAMP | NO | Literal constant set in this object. Formula: `CURRENT_TIMESTAMP()`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | Primary | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency
        │
        ▼
main.etoro_kpi_prep.v_mimo_emoneyplatform   ←── this object
        │
        ▼
main.etoro_kpi_prep.v_mimo_allplatforms
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=21 runtime=21 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` (wiki: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md`)
- **JOIN/UNION upstreams**: 2 additional object(s)
- **Wiki coverage**: 2/2 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.etoro_kpi_prep.v_mimo_allplatforms`

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

*Generated: 2026-05-19 | Concepts: 15 | Formulas: 21 | Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 21/21 | Source: view_definition*
