---
object_fqn: main.bi_output.vg_emoney_panel_firstdates_em1
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_emoney_panel_firstdates_em1
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 44
row_count: null
generated_at: '2026-06-19T14:36:03Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_panel_firstdates_em1.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_panel_firstdates_em1.sql
concept_count: 0
formula_count: 44
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 42
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_emoney_panel_firstdates_em1

> View in `main.bi_output`. 0 business concept(s) in §2; 44 of 44 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_panel_firstdates_em1` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 44 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Thu Jan 01 09:45:29 UTC 2026 |

---

## 1. Business Meaning

`vg_emoney_panel_firstdates_em1` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Panel_FirstDates.md`.

Of its 44 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 42 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

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
| 1 | CID | INT | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 1 | GCID | INT | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |
| 2 | emoney_fmi_date | TIMESTAMP | YES | Date of the account's first settled money-in transaction (TxTypeID IN [5,7], TxStatusID=2, HolderAmount≠0). Derived from TxStatusModificationDate of ROW_NUMBER=1 (ASC by TxStatusModificationTime). NULL for 36.7% of accounts that have never funded. Earliest value: 2020-11-10 (UK launch). (Tier 2 — eMoney_Dim_Transaction) |
| 3 | emoney_fmi_source | STRING | YES | Origin classification of the first money-in: `'TP'` (TxTypeID=5, TransferReceived — internal eToro transfer) or `'External'` (TxTypeID=7, PaymentReceived — bank/external). As of 2026-04-12: TP=672,868 (52.3%), External=613,743 (47.7%). NULL when FMI_Date is NULL. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 4 | Seniority_FMI | INT | YES | Months elapsed between FMI_Date and the SP run date. DATEDIFF(MONTH, FMI_Date, @Date). NULL when FMI_Date is NULL. Computed at INSERT time — recalculate DATEDIFF directly for real-time values. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 5 | emoney_fmo_date | TIMESTAMP | YES | Date of the account's first settled money-out transaction (TxTypeID IN [1,2,3,4,6,8,13], TxStatusID=2, HolderAmount≠0). Derived from TxStatusModificationDate of ROW_NUMBER=1 (ASC by TxStatusModificationTime). NULL for 38.9% of accounts that have never sent. (Tier 2 — eMoney_Dim_Transaction) |
| 6 | emoney_fmo_target | STRING | YES | Destination classification of the first money-out: `'TP'` (TxTypeID=6 — internal Transfer to eToro user) or `'External'` (all other OUT types — bank, card, DD). As of 2026-04-12: TP=700,796 (56.4%), External=541,443 (43.6%). NULL when FMO_Date is NULL. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 7 | emoney_fmo_mop | STRING | YES | Method of payment for the first money-out: `'Card'` (TxTypeID IN [1,2,3,4]), `'IBAN'` (TxTypeID IN [6,8]), `'DirectDebit'` (TxTypeID=13). As of 2026-04-12: IBAN=1,235,319 (99.4% of FMO accounts), Card=6,908 (0.6%), DirectDebit=12 (<0.01%). NULL when FMO_Date is NULL. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 8 | Seniority_FMO | INT | YES | Months elapsed between FMO_Date and the SP run date. DATEDIFF(MONTH, FMO_Date, @Date). NULL when FMO_Date is NULL. Computed at INSERT time. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 9 | emoney_last_settled_tx_date | TIMESTAMP | YES | Date of the account's most recent settled transaction across all types (TxStatusID=2, HolderAmount≠0). MAX(TxStatusModificationDate). Used as a recency signal; compare to GETDATE() for churn analysis. NULL if no settled transactions. (Tier 2 — eMoney_Dim_Transaction) |
| 10 | Seniority_LastTXDate | INT | YES | Months elapsed between LastSettledTXDate and the SP run date. DATEDIFF(MONTH, LastSettledTXDate, @Date). Accounts with Seniority_LastTXDate ≤ 3 are typically considered active. Computed at INSERT time. (Tier 2 — SP_eMoney_Panel_FirstDates) |
| 11 | emoney_first_settled_tx_date | TIMESTAMP | YES | Date of the account's first settled IBAN-rail transaction (TxTypeID IN [5,6,7,8]). MIN(TxStatusModificationDate) for IBAN types. NULL if no IBAN activity. (Tier 2 — eMoney_Dim_Transaction) |
| 12 | emoney_last_settled_tx_date_iban | TIMESTAMP | YES | Date of the account's most recent settled IBAN-rail transaction (TxTypeID IN [5,6,7,8]). MAX(TxStatusModificationDate) for IBAN types. NULL if no IBAN activity. (Tier 2 — eMoney_Dim_Transaction) |
| 13 | emoney_1st_action_date | TIMESTAMP | YES | Date of the account's 1st settled transaction (all types, ranked ASC by TxStatusModificationTime). MAX(CASE WHEN RowNumASC=1 THEN TxStatusModificationDate END). NULL if no settled tx. (Tier 2 — eMoney_Dim_Transaction) |
| 14 | emoney_1st_action_type | STRING | YES | TxType name of the 1st settled transaction. MAX(CASE WHEN RowNumASC=1 THEN TxType END). Values: CardPayment, Transfer, PaymentReceived, etc. NULL if no settled tx. (Tier 2 — eMoney_Dim_Transaction) |
| 15 | emoney_1st_action_amount_usd | DECIMAL | YES | Approximate USD value of the 1st settled transaction. MAX(CASE WHEN RowNumASC=1 THEN USDAmountApprox END). ROUND(HolderAmount × mid-rate, 2). NULL for DKK and if no settled tx. (Tier 2 — eMoney_Dim_Transaction) |
| 16 | emoney_2nd_action_date | TIMESTAMP | YES | Date of the account's 2nd settled transaction (all types, ranked ASC). NULL if fewer than 2 settled tx. Same derivation as 1stActionDate with RowNumASC=2. (Tier 2 — eMoney_Dim_Transaction) |
| 17 | emoney_2nd_action_type | STRING | YES | TxType name of the 2nd settled transaction. NULL if fewer than 2. (Tier 2 — eMoney_Dim_Transaction) |
| 18 | emoney_2nd_action_amount_usd | DECIMAL | YES | USD approximate amount of the 2nd settled transaction. NULL if fewer than 2. (Tier 2 — eMoney_Dim_Transaction) |
| 19 | emoney_3rd_action_date | TIMESTAMP | YES | Date of the 3rd settled transaction (all types, ranked ASC). NULL if fewer than 3. (Tier 2 — eMoney_Dim_Transaction) |
| 20 | emoney_3rd_action_type | STRING | YES | TxType name of the 3rd settled transaction. NULL if fewer than 3. (Tier 2 — eMoney_Dim_Transaction) |
| 21 | emoney_3rd_action_amount_usd | DECIMAL | YES | USD approximate amount of the 3rd settled transaction. NULL if fewer than 3. (Tier 2 — eMoney_Dim_Transaction) |
| 22 | emoney_4th_action_date | TIMESTAMP | YES | Date of the 4th settled transaction (all types, ranked ASC). NULL if fewer than 4. (Tier 2 — eMoney_Dim_Transaction) |
| 23 | emoney_4th_action_type | STRING | YES | TxType name of the 4th settled transaction. NULL if fewer than 4. (Tier 2 — eMoney_Dim_Transaction) |
| 24 | emoney_4th_action_amount_usd | DECIMAL | YES | USD approximate amount of the 4th settled transaction. NULL if fewer than 4. (Tier 2 — eMoney_Dim_Transaction) |
| 25 | emoney_5th_action_date | TIMESTAMP | YES | Date of the 5th settled transaction (all types, ranked ASC). NULL if fewer than 5. (Tier 2 — eMoney_Dim_Transaction) |
| 26 | emoney_5th_action_type | STRING | YES | TxType name of the 5th settled transaction. NULL if fewer than 5. (Tier 2 — eMoney_Dim_Transaction) |
| 27 | emoney_5th_action_amount_usd | DECIMAL | YES | USD approximate amount of the 5th settled transaction. NULL if fewer than 5. (Tier 2 — eMoney_Dim_Transaction) |
| 28 | emoney_card_activation_date | TIMESTAMP | YES | Timestamp when the card reached activated status. CASE WHEN CardStatusID=1 THEN CardStatusTime ELSE NULL END, sourced from eMoney_Dim_Account. NULL for 98.7% of accounts with no activated card. (Tier 2 — eMoney_Dim_Account) |
| 29 | emoney_card_1st_action_date | TIMESTAMP | YES | Date of the account's 1st settled card-rail transaction (TxTypeID IN [1,2,3,4]), ranked ASC. NULL for 98.7% of accounts with no card activity. (Tier 2 — eMoney_Dim_Transaction) |
| 30 | emoney_card_1st_action_type | STRING | YES | TxType name of the 1st settled card transaction. Values: CardPayment, ContactlessPayment, CardCashWithdrawal, CardRefund. NULL if no card activity. (Tier 2 — eMoney_Dim_Transaction) |
| 31 | emoney_card_1st_action_amount_usd | DECIMAL | YES | USD approximate amount of the 1st settled card transaction. NULL if no card activity. (Tier 2 — eMoney_Dim_Transaction) |
| 32 | emoney_card_2nd_action_date | TIMESTAMP | YES | Date of the 2nd settled card transaction. NULL if fewer than 2 card tx. Same derivation as Card1st with RowNumASC=2. (Tier 2 — eMoney_Dim_Transaction) |
| 33 | emoney_card_2nd_action_type | STRING | YES | TxType of the 2nd settled card transaction. NULL if fewer than 2 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 34 | emoney_card_2nd_action_amount_usd | DECIMAL | YES | USD amount of the 2nd settled card transaction. NULL if fewer than 2 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 35 | emoney_card_3rd_action_date | TIMESTAMP | YES | Date of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 36 | emoney_card_3rd_action_type | STRING | YES | TxType of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 37 | emoney_card_3rd_action_amount_usd | DECIMAL | YES | USD amount of the 3rd settled card transaction. NULL if fewer than 3 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 38 | emoney_card_4th_action_date | TIMESTAMP | YES | Date of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 39 | emoney_card_4th_action_type | STRING | YES | TxType of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 40 | emoney_card_4th_action_amount_usd | DECIMAL | YES | USD amount of the 4th settled card transaction. NULL if fewer than 4 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 41 | emoney_card_5th_action_date | TIMESTAMP | YES | Date of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 42 | emoney_card_5th_action_type | STRING | YES | TxType of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 — eMoney_Dim_Transaction) |
| 43 | emoney_card_5th_action_amount_usd | DECIMAL | YES | USD amount of the 5th settled card transaction. NULL if fewer than 5 card tx. (Tier 2 — eMoney_Dim_Transaction) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` | Primary | `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Panel_FirstDates.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
        │
        ▼
main.bi_output.vg_emoney_panel_firstdates_em1   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=44 runtime=44 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates` (wiki: `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Panel_FirstDates.md`)

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

*Generated: 2026-06-19 | Concepts: 0 | Formulas: 44 | Tiers: 2 T1, 42 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 44/44 | Source: view_definition*
