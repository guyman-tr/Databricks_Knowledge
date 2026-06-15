---
object_fqn: main.bi_output.vg_emoney_openbankingdeposit
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_emoney_openbankingdeposit
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 6
row_count: null
generated_at: '2026-05-19T15:01:58Z'
upstreams:
- main.bi_db.bronze_moneytransfer_billing_transfers
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_openbankingdeposit.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_openbankingdeposit.sql
concept_count: 2
formula_count: 6
tier_breakdown:
  tier1_columns: 4
  tier2_columns: 2
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_emoney_openbankingdeposit

> View in `main.bi_output`. 2 business concept(s) in §2; 6 of 6 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_openbankingdeposit` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 6 |
| **Concepts** | 2 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jan 19 13:16:47 UTC 2026 |

---

## 1. Business Meaning

`vg_emoney_openbankingdeposit` is a view in `main.bi_output` that composes 2 CASE-based classifier flag(s) computed from upstream IDs.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.bronze_moneytransfer_billing_transfers` → this object. Canonical upstream documentation: `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md`.

Of its 6 columns: 4 inherit byte-for-byte from upstream wikis (Tier 1), 2 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `OpenBankingDeposit_Attempt_Status` discriminator: `TransferStatusID = 10` (Received per upstream wiki) → set to '       ' else '                 '
**What**: Computed flag on `OpenBankingDeposit_Attempt_Status` set to `'       '` when the predicates below hold, else `'                 '`.
**Columns Involved**: `OpenBankingDeposit_Attempt_Status`
**Rules**:
- `TransferStatusID = 10` (Received per upstream wiki)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_openbankingdeposit.sql` bi_output.sql L11-L15
**Source(s)**: `main.bi_db.bronze_moneytransfer_billing_transfers`

### 2.2 `OpenBankingDeposit_Provider` computed flag
**What**: Computed flag on `OpenBankingDeposit_Provider` set to `'    '` when the predicates below hold, else `'     '`.
**Columns Involved**: `OpenBankingDeposit_Provider`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/vg_emoney_openbankingdeposit.sql` bi_output.sql L17-L21
**Source(s)**: `main.bi_db.bronze_moneytransfer_billing_transfers`

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
| Filter on discriminator flags | Use `OpenBankingDeposit_Attempt_Status = 1`-style filters on the precomputed flag columns (`OpenBankingDeposit_Attempt_Status`, `OpenBankingDeposit_Provider`) instead of recomputing the underlying CASE predicates downstream. |

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
| 1 | CID | INT | YES | Customer identifier - the user who initiated or owns the transfer. Used for customer-scoped queries: `GetTransfersByCID`, `GetDepotIdOfLastSuccessfulTransferByCid`, `GetLastSuccessTransferDataByCid`. Indexed for performance (IX_Billing_Transfers_CID). References an external customer system (Tier 1 — inherited from main.bi_db.bronze_moneytransfer_billing_transfers). |
| 1 | OpenBankingDeposit_Attempt_ID | INT | YES | Auto-incrementing unique identifier for each transfer. NONCLUSTERED PK. Used as a secondary lookup key and in range-based monitoring queries (`GetLastTransfersStatusesInPercentage` scans by TransferID ranges). Current values in the ~4.88M range. (renamed from `TransferID`) (Tier 1 — inherited from main.bi_db.bronze_moneytransfer_billing_transfers). |
| 2 | OpenBankingDeposit_Attempt_Status | STRING | NO | `OpenBankingDeposit_Attempt_Status` discriminator: `TransferStatusID = 10` (Received per upstream wiki) → set to '       ' else '                 '. Formula: `case when TransferStatusID = 10 then 'Success' else 'Pending_or_Failed' end`. (Tier 2 — from `main.bi_db.bronze_moneytransfer_billing_transfers`) |
| 3 | OpenBankingDeposit_Provider | STRING | NO | `OpenBankingDeposit_Provider` computed flag. Formula: `case when left(ExReferenceID, 2) = 'TZ' then 'Volt' when left(ExReferenceID, 2) = 'TK' then 'Tink' else 'Other' end as OpenBank…`. (Tier 2 — from `main.bi_db.bronze_moneytransfer_billing_transfers`) |
| 4 | OpenBankingDeposit_Attempt_USDAmount | DECIMAL | YES | Transfer amount in the currency specified by CurrencyID. Set at creation time and not modified afterward. Observed range in sample: 50 to 10,000. Stored as SQL Server `money` type (4 decimal places). (renamed from `Amount`) (Tier 1 — inherited from main.bi_db.bronze_moneytransfer_billing_transfers). |
| 5 | OpenBankingDeposit_Attempt_Date | TIMESTAMP | YES | UTC timestamp of the most recent modification. Initialized to GETUTCDATE() on INSERT, then auto-updated by trigger `TR_Transfers_ModificationDate` on every UPDATE operation. The gap between CreateDate and ModificationDate indicates processing duration. (renamed from `ModificationDate`) (Tier 1 — inherited from main.bi_db.bronze_moneytransfer_billing_transfers). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.bronze_moneytransfer_billing_transfers` | Primary | `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.bronze_moneytransfer_billing_transfers
        │
        ▼
main.bi_output.vg_emoney_openbankingdeposit   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=6 runtime=6 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.bronze_moneytransfer_billing_transfers` (wiki: `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md`)

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

*Generated: 2026-05-19 | Concepts: 2 | Formulas: 6 | Tiers: 4 T1, 2 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 6/6 | Source: view_definition*
