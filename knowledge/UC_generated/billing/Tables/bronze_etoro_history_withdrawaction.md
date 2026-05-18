---
object_fqn: main.billing.bronze_etoro_history_withdrawaction
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_history_withdrawaction
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 23
row_count: null
generated_at: '2026-05-18T10:58:41Z'
upstreams:
- etoro.History.WithdrawAction
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md
  source_database: etoro
  source_schema: History
  source_table: WithdrawAction
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/WithdrawAction
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 20
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 3
  unverified_columns: 0
---

# bronze_etoro_history_withdrawaction

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.History.WithdrawAction`). 20 of 23 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_history_withdrawaction` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 23 |
| **Generated** | 2026-05-18 |
| **Created** | Wed May 29 04:16:54 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.WithdrawAction` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md`.

- Lake path: `Bronze/etoro/History/WithdrawAction`
- Copy strategy: `Append`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.WithdrawAction`
- 20 of 23 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawActionID | INT | YES | Auto-incrementing surrogate PK. IDENTITY NOT FOR REPLICATION. Sequential within each withdrawal's action history. NONCLUSTERED PK on HISTORY filegroup (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 1 | WithdrawID | INT | YES | The withdrawal request this action belongs to. FK to Billing.Withdraw(WithdrawID). Multiple rows per WithdrawID form the complete lifecycle. Included in the NC index on ModificationDate for efficient joins (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 2 | CashoutStatusID | INT | YES | The cashout status recorded at this action. FK to Dictionary.CashoutStatus. See Section 2.2 for full value map. Leading indicator of which lifecycle stage this row captures (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 3 | ManagerID | INT | YES | Back-office manager who performed this action. FK to BackOffice.Manager. NULL = no manager involved (fully automated). 0 = automated system action. > 0 = specific manager's action (approve, reject, set commission) (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 4 | Commission | DECIMAL | YES | Commission amount captured at this action step. Defaults to 0. Set by BackOffice.WithdrawRequestSetCommission when a manager assigns a commission to the withdrawal (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 5 | Approved | BOOLEAN | YES | Whether this action represents an approval decision: 1=approved, 0=not approved. Approved=1 with ManagerID=0 indicates automated approval. Used with BackOffice.WithdrawRequestApprove (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 6 | ModificationDate | TIMESTAMP | YES | UTC timestamp when this action was recorded. Leading column of NC index IDX_HistoryWithdrawAction_ModificationDate - supports time-range queries for reconciliation and reporting (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 7 | Comment | STRING | YES | Human-readable description of this action. Common values: "Initiated by user request", "Automation - Manual Approval". Set by the calling procedure or manager note (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 8 | SessionID | LONG | YES | Customer session identifier at the time of the withdrawal action. NULL for automated/system actions. Provides traceability back to the specific user session (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 9 | CashoutReasonID | INT | YES | Reason category for this cashout action. Default value 16 = "Requested by User" (95.8% of rows). Larger values (12, 18, 19) indicate system-generated or special-case reasons (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 10 | ClientPersonalID | STRING | YES | Customer personal identification document reference captured at withdrawal time (e.g., for KYC compliance). Added in 2019 (ticket 10864). Typically NULL for automated flows (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 11 | FundingID | INT | YES | References the funding method (payment instrument) used for this withdrawal. Links to the customer's stored payment method record (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 12 | FundingTypeID | INT | YES | Type of funding/payment method: 1=bank transfer, 2=credit card, 33=crypto/stock redemption (inferred from data). Determines the payment processing pathway (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 13 | Amount | DECIMAL | YES | Withdrawal amount in the withdrawal's currency at time of this action. May differ from the original request amount for partial/reversed withdrawals (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 14 | CurrencyID | INT | YES | Currency of the withdrawal amount. 1=USD in dominant records. References Dictionary/currency lookup (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 15 | Fee | DECIMAL | YES | Withdrawal fee charged at time of this action. 0 = fee-free withdrawal (e.g., automatic stock/crypto redemption). Common value: $5 for bank wire withdrawals (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 16 | AccountCurrencyID | INT | YES | Customer account currency at time of action. 1=USD, 2=other currency (observed in data). Used for currency conversion when account currency differs from withdrawal currency (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 17 | ExTransactionID | STRING | YES | External payment provider transaction reference number. Populated for auto-processed withdrawals (e.g., crypto/stock redemptions via FundingTypeID=33). NULL for manual/bank wire flows pending external processing (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 18 | WithdrawTypeID | INT | YES | Type classification of the withdrawal: 0=unclassified, 1=automatic/direct (e.g., stock redemption). NULL for certain flow types. Application-defined enum (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 19 | FlowID | INT | YES | Processing flow identifier: 0=legacy/unset, 2=automatic stock/crypto redemption flow. NULL for older records or manual processes. Determines which processing pipeline handles the withdrawal (Tier 1 — inherited from etoro.History.WithdrawAction). |
| 20 | etr_y | INT | YES | Source: etoro.History.WithdrawAction.etr_y. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 21 | etr_ym | STRING | YES | Source: etoro.History.WithdrawAction.etr_ym. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 22 | etr_ymd | DATE | YES | Source: etoro.History.WithdrawAction.etr_ymd. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.WithdrawAction` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.WithdrawAction
        │
        ▼
main.billing.bronze_etoro_history_withdrawaction   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| WithdrawActionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| WithdrawID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| CashoutStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| Commission | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| Approved | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| Comment | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| SessionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| CashoutReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| ClientPersonalID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| FundingTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| Fee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| AccountCurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| ExTransactionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| WithdrawTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| FlowID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.WithdrawAction) |
| etr_y | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` but column `etr_y` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` but column `etr_ym` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md` but column `etr_ymd` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 20 T1, 0 T2, 0 T3, 0 T4, 3 T5, 0 U | Elements: 23/23 | Source: bronze_tier1_inheritance*
