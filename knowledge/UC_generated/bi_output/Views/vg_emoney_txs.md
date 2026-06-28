---
object_fqn: main.bi_output.vg_emoney_txs
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_emoney_txs
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 10
row_count: null
generated_at: '2026-06-19T14:36:04Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_txs.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_txs.sql
concept_count: 0
formula_count: 10
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 8
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_emoney_txs

> View in `main.bi_output`. 0 business concept(s) in §2; 10 of 10 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_txs` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 10 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Tue Dec 09 20:03:43 UTC 2025 |

---

## 1. Business Meaning

`vg_emoney_txs` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md`.

Of its 10 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 8 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | CID | INT | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. Passthrough via eMoney_Dim_Account snapshot. (Tier 1 — Customer.CustomerStatic) |
| 1 | GCID | INT | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. Passthrough via eMoney_Dim_Account snapshot (Step 01). (Tier 1 — dbo.FiatAccount) |
| 2 | TxStatusModificationDate | TIMESTAMP | YES | Date portion of TxStatusModificationTime. DWH-derived: CAST(TransactionOccured AS DATE). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 3 | TxAmountInUSD | DECIMAL | YES | Approximate USD equivalent of HolderAmount at TxLocalDate. ROUND(HolderAmount × (Ask+Bid)/2, 2) using DWH_dbo.Fact_CurrencyPriceWithSplit mid-rate. NULL for DKK (no matching instrument). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 4 | TransactionID | INT | YES | Surrogate key for the fiat transaction from FiatDwhDB.dbo.FiatTransactions.Id. Each transaction appears exactly once in this table (latest status only). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 5 | IsTxSettled | INT | YES | 1 if the current transaction status is Settled (TxStatusID=2), else 0. ETL CASE expression. KEY DIFFERENCE from eMoney_Fact_Transaction_Status (which has FiatTransactionStatusRunningID at this position instead). 98.3% of transactions are Settled. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 6 | TxType | STRING | YES | Transaction type display name for TxTypeID, resolved from External_FiatDwhDB_Dictionary_TransactionTypes.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 7 | TxTypeID | INT | YES | Transaction type identifier. 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat (15=CryptoToFiat via dictionary). Passthrough from FiatTransactions.TransactionTypeId. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 8 | HolderCurrencyISO | STRING | YES | ISO 4217 numeric currency code for the holder's balance currency (e.g., 826=GBP, 978=EUR, 208=DKK). Passthrough from FiatTransactionsStatuses.HolderCurrency (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 9 | LocalCurrencyISO | STRING | YES | ISO 4217 numeric currency code for the local transaction currency (e.g., the merchant's currency for card transactions). Passthrough from FiatTransactionsStatuses.TransactionCurrency. (Tier 2 — SP_eMoney_DimFact_Transaction) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | Primary | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
        │
        ▼
main.bi_output.vg_emoney_txs   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=10 runtime=10 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` (wiki: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md`)

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

*Generated: 2026-06-19 | Concepts: 0 | Formulas: 10 | Tiers: 2 T1, 8 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 10/10 | Source: view_definition*
