---
object_fqn: main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 3
row_count: null
generated_at: '2026-05-18T10:58:42Z'
upstreams:
- MoneyBusDB.Dictionary.TransactionStatusReasons
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md
  source_database: MoneyBusDB
  source_schema: Dictionary
  source_table: TransactionStatusReasons
  source_repo: PaymentsDBs
  datalake_path: Bronze/MoneyBusDB/Dictionary/TransactionStatusReasons
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_moneybusdb_dictionary_transactionstatusreasons

> Bronze ingest in `main.billing` (1:1 passthrough of `MoneyBusDB.Dictionary.TransactionStatusReasons`). 3 of 3 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 3 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Mar 24 11:37:52 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `MoneyBusDB.Dictionary.TransactionStatusReasons` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md`.

- Lake path: `Bronze/MoneyBusDB/Dictionary/TransactionStatusReasons`
- Copy strategy: `Override`
- Source database: `MoneyBusDB` (`PaymentsDBs`)
- Source schema/table: `Dictionary.TransactionStatusReasons`
- 3 of 3 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Primary key identifying each transaction status reason. Explicitly assigned (not IDENTITY). Referenced as StatusReasonID in MoneyBus.Transactions and MoneyBus.TransactionsTable_New (UDT). Values: 1=Created, 2=Success, 3=Held, 4=Credited, 5=Debited, 6=HoldDecline, 7=CreditDecline, 8=DebitDecline, 9=ValidateDecline, 10=Technical, 11=DebitInitiated, 12=HoldInitiated, 13=CreditInitiated, 14=HoldCanceled, 15=ReconciliationAborted. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason) for full business definitions (Tier 1 — inherited from MoneyBusDB.Dictionary.TransactionStatusReasons). |
| 1 | Name | STRING | YES | Human-readable label for the status reason. Descriptive names follow a consistent pattern: {Step}{Outcome} (e.g., HoldInitiated, CreditDecline). Consumed by TransactionStatusReasonsGet for application-level caching and display (Tier 1 — inherited from MoneyBusDB.Dictionary.TransactionStatusReasons). |
| 2 | TransactionStatusID | INT | YES | Parent status that this reason belongs to. Implicit FK to Dictionary.TransactionStatuses.ID. Maps each granular reason to its top-level outcome category: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. Critical for determining recoverability - reasons mapping to InProcess are retryable, others are terminal. See [Transaction Status](../../_glossary.md#transaction-status) (Tier 1 — inherited from MoneyBusDB.Dictionary.TransactionStatusReasons). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `MoneyBusDB.Dictionary.TransactionStatusReasons` | Primary | `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md` |

### 4.2 Pipeline ASCII Diagram

```
MoneyBusDB.Dictionary.TransactionStatusReasons
        │
        ▼
main.billing.bronze_moneybusdb_dictionary_transactionstatusreasons   ←── this object
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
| ID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.Dictionary.TransactionStatusReasons) |
| Name | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.Dictionary.TransactionStatusReasons) |
| TransactionStatusID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.TransactionStatusReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.Dictionary.TransactionStatusReasons) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 3 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 3/3 | Source: bronze_tier1_inheritance*
