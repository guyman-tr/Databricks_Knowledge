---
object_fqn: main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 3
row_count: null
generated_at: '2026-05-18T10:58:45Z'
upstreams:
- MoneyBusDB.Dictionary.WithdrawStatusReasons
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md
  source_database: MoneyBusDB
  source_schema: Dictionary
  source_table: WithdrawStatusReasons
  source_repo: PaymentsDBs
  datalake_path: Bronze/MoneyBusDB/Dictionary/WithdrawStatusReasons
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

# bronze_moneybusdb_dictionary_withdrawstatusreasons

> Bronze ingest in `main.billing` (1:1 passthrough of `MoneyBusDB.Dictionary.WithdrawStatusReasons`). 3 of 3 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 3 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Mar 24 11:40:08 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `MoneyBusDB.Dictionary.WithdrawStatusReasons` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md`.

- Lake path: `Bronze/MoneyBusDB/Dictionary/WithdrawStatusReasons`
- Copy strategy: `Override`
- Source database: `MoneyBusDB` (`PaymentsDBs`)
- Source schema/table: `Dictionary.WithdrawStatusReasons`
- 3 of 3 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | INT | YES | Primary key identifying each withdrawal status reason. Explicitly assigned (not IDENTITY). Referenced as StatusReasonID in MoneyBus.Withdrawals. Values: 1=Created, 2=Success, 3=HoldInitiated, 4=HoldApproved, 5=HoldDeclined, 6=AuthorizeInitiated, 7=AuthorizeApproved, 8=AuthorizeDeclined, 9=PayoutInitiated, 10=PayoutApproved, 11=PayoutDeclined, 12=AbortInitiated, 13=AbortCompleted, 14=AbortFailed, 15=RiskManualReview. See [Withdraw Status Reason](../../_glossary.md#withdraw-status-reason) for full business definitions (Tier 1 — inherited from MoneyBusDB.Dictionary.WithdrawStatusReasons). |
| 1 | Name | STRING | YES | Human-readable label for the status reason. Names follow {Step}{Outcome} pattern (e.g., HoldApproved, PayoutDeclined, AbortCompleted). Read by Dictionary.WithdrawStatusReasonGet for application caching (Tier 1 — inherited from MoneyBusDB.Dictionary.WithdrawStatusReasons). |
| 2 | WithdrawStatusID | INT | YES | Parent status that this reason belongs to. Implicit FK to Dictionary.WithdrawStatuses.ID. Maps each granular reason to its top-level outcome: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. Encodes recoverability: reasons mapping to InProcess can still progress, others are terminal. See [Withdraw Status](../../_glossary.md#withdraw-status) (Tier 1 — inherited from MoneyBusDB.Dictionary.WithdrawStatusReasons). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `MoneyBusDB.Dictionary.WithdrawStatusReasons` | Primary | `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md` |

### 4.2 Pipeline ASCII Diagram

```
MoneyBusDB.Dictionary.WithdrawStatusReasons
        │
        ▼
main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons   ←── this object
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
| ID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.Dictionary.WithdrawStatusReasons) |
| Name | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.Dictionary.WithdrawStatusReasons) |
| WithdrawStatusID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyBusDB.Dictionary.WithdrawStatusReasons) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 3 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 3/3 | Source: bronze_tier1_inheritance*
