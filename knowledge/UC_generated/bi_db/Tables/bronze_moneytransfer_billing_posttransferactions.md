---
object_fqn: main.bi_db.bronze_moneytransfer_billing_posttransferactions
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_moneytransfer_billing_posttransferactions
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-19T12:12:59Z'
upstreams:
- MoneyTransfer.Billing.PostTransferActions
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md
  source_database: MoneyTransfer
  source_schema: Billing
  source_table: PostTransferActions
  source_repo: PaymentsDBs
  datalake_path: Bronze/MoneyTransfer/Billing/PostTransferActions
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_moneytransfer_billing_posttransferactions

> Bronze ingest in `main.bi_db` (1:1 passthrough of `MoneyTransfer.Billing.PostTransferActions`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_moneytransfer_billing_posttransferactions` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Aug 20 14:14:03 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `MoneyTransfer.Billing.PostTransferActions` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md`.

- Lake path: `Bronze/MoneyTransfer/Billing/PostTransferActions`
- Copy strategy: `Override`
- Source database: `MoneyTransfer` (`PaymentsDBs`)
- Source schema/table: `Billing.PostTransferActions`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PostTransferActionID | INT | YES | Auto-incrementing primary key (NONCLUSTERED). Unique identifier for each post-transfer action. Current values in the ~2.59M range (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions). |
| 1 | TransferID | INT | YES | Foreign key to `Billing.Transfers.TransferID` (implicit, no constraint). Links this action to its parent transfer. Set by `CreatePostTransfer`. Every action must be associated with an existing transfer (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions). |
| 2 | ReferenceID | STRING | YES | Business reference GUID for this action. Indexed (IX_Billing_PostTransferActions) for lookup performance. Used as the primary lookup key by `GetPostTransfer`, `UpdatePostTransferPayload`, and `UpdatePostTransferStatus`. May correspond to the parent transfer's ReferenceID or be action-specific (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions). |
| 3 | Payload | STRING | YES | Masked (Dynamic Data Masking: default()) JSON or structured data containing the action's operational details. Contains PII. Set by `CreatePostTransfer` and can be updated by `UpdatePostTransferPayload`. The content depends on the action type and may include funding instrument details, provider responses, or processing metadata (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions). |
| 4 | FundingTypeID | INT | YES | Type of funding instrument associated with this action. No lookup table in this database. Sample data consistently shows value 33 (matching the DestinationFundingTypeID pattern in Billing.Transfers), suggesting most post-transfer actions relate to destination-side processing (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions). |
| 5 | PostTransferStatusID | INT | YES | Lifecycle status of this post-transfer action. Implicit reference to Dictionary.PostTransferStatus (currently empty). Observed values: 1 (initial/in-progress), 2 (completed). Set by `CreatePostTransfer`, updated by `UpdatePostTransferStatus`. See [Post Transfer Status](../../_glossary.md#post-transfer-status) (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions). |
| 6 | CreateDate | TIMESTAMP | YES | UTC timestamp of action creation. Set automatically via DEFAULT constraint. No modification timestamp exists - status changes are tracked only by value, not by when they occurred (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions). |
| 7 | PostTransferActionTypeID | INT | YES | Type classification for the post-transfer action. Defaults to 1 via constraint DF_PostTransferActions_PostTransferActionTypeID. All observed data shows value 1, suggesting only one action type is currently in use. No lookup table exists in this database. Set by `CreatePostTransfer` (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `MoneyTransfer.Billing.PostTransferActions` | Primary | `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` |

### 4.2 Pipeline ASCII Diagram

```
MoneyTransfer.Billing.PostTransferActions
        │
        ▼
main.bi_db.bronze_moneytransfer_billing_posttransferactions   ←── this object
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
| PostTransferActionID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions) |
| TransferID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions) |
| ReferenceID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions) |
| Payload | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions) |
| FundingTypeID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions) |
| PostTransferStatusID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions) |
| PostTransferActionTypeID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.PostTransferActions) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
