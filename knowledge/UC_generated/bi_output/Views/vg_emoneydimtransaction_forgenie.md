---
object_fqn: main.bi_output.vg_emoneydimtransaction_forgenie
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_emoneydimtransaction_forgenie
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 13
row_count: null
generated_at: '2026-05-19T15:02:00Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoneydimtransaction_forgenie.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoneydimtransaction_forgenie.sql
concept_count: 0
formula_count: 13
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 11
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_emoneydimtransaction_forgenie

> View in `main.bi_output`. 0 business concept(s) in §2; 13 of 13 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoneydimtransaction_forgenie` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 13 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu May 14 10:30:08 UTC 2026 |

---

## 1. Business Meaning

`vg_emoneydimtransaction_forgenie` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md`.

Of its 13 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 11 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

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
| 1 | CID | INT | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. Passthrough via eMoney_Dim_Account snapshot. (Tier 1 — Customer.CustomerStatic) |
| 1 | GCID | INT | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. Passthrough via eMoney_Dim_Account snapshot (Step 01). (Tier 1 — dbo.FiatAccount) |
| 2 | TxTypeID | INT | YES | Transaction type identifier. 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat (15=CryptoToFiat via dictionary). Passthrough from FiatTransactions.TransactionTypeId. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 3 | TxType | STRING | YES | Transaction type display name for TxTypeID, resolved from External_FiatDwhDB_Dictionary_TransactionTypes.Name. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 4 | TxTypeDescription | STRING | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN TxTypeID IN (1, 2, 3, 4, 13) THEN TxType \|\| ' - eToro Debit Card Transaction' WHEN TxType = 'Payment' THEN 'Payment - IBAN to External (Outgoing Payment)' …`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction`) |
| 5 | USDAmountApprox | DECIMAL | YES | Approximate USD equivalent of HolderAmount at TxLocalDate. ROUND(HolderAmount × (Ask+Bid)/2, 2) using DWH_dbo.Fact_CurrencyPriceWithSplit mid-rate. NULL for DKK (no matching instrument). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 6 | HolderAmount | DECIMAL | YES | Amount debited/credited to the holder's balance in HolderCurrency. Negative = debit (MoneyOut); positive = credit (MoneyIn). Passthrough from FiatTransactionsStatuses.HolderAmount (latest event, RNDesc=1). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 7 | HolderCurrencyDesc | STRING | YES | Currency display name for HolderCurrencyISO, resolved via eMoney_Currency_Mapping_ISO.CurrencyAlphaThreeCode from the instrument mapping COALESCE(buy-side, sell-side). (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 8 | MerchantID | INT | YES | Merchant identifier from FiatTransactions.MerchantId. Populated for card POS and online transactions; NULL for bank transfers and internal transactions. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 9 | TxStatusModificationTime | TIMESTAMP | YES | Timestamp of the latest status change event (FiatTransactionsStatuses.TransactionOccured, RNDesc=1 by TransactionOccured DESC). The de facto "last updated" timestamp for this transaction's state. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 10 | TxLabel | STRING | YES | Free-text label from FiatTransactions.Label. Contains merchant names, IBAN references, or internal notes depending on transaction type. May contain PII. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 11 | MoneyMoveDirection | STRING | YES | Direction of money flow based on HolderAmount: HolderAmount < 0 = MoneyOut; HolderAmount > 0 = MoneyIn; HolderAmount = 0 = Error. ETL CASE in Step 04. (Tier 2 — SP_eMoney_DimFact_Transaction) |
| 12 | USDRateApprox | DECIMAL | YES | USD mid-rate used for USDAmountApprox. ROUND((Ask+Bid)/2, 2) from DWH_dbo.Fact_CurrencyPriceWithSplit at TxLocalDate. NULL for DKK transactions. (Tier 2 — SP_eMoney_DimFact_Transaction) |

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
main.bi_output.vg_emoneydimtransaction_forgenie   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=13 runtime=13 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 13 | Tiers: 2 T1, 11 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 13/13 | Source: view_definition*
