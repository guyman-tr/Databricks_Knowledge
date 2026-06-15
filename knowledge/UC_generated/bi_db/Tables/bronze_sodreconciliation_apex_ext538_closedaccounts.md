---
object_fqn: main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 9
row_count: null
generated_at: '2026-05-19T12:13:01Z'
upstreams:
- Sodreconciliation.apex.EXT538_ClosedAccounts
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md
  source_database: Sodreconciliation
  source_schema: apex
  source_table: EXT538_ClosedAccounts
  source_repo: DB_Schema
  datalake_path: Bronze/Sodreconciliation/apex/EXT538_ClosedAccounts
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_sodreconciliation_apex_ext538_closedaccounts

> Bronze ingest in `main.bi_db` (1:1 passthrough of `Sodreconciliation.apex.EXT538_ClosedAccounts`). 9 of 9 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 9 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Jun 19 10:13:47 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `Sodreconciliation.apex.EXT538_ClosedAccounts` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md`.

- Lake path: `Bronze/Sodreconciliation/apex/EXT538_ClosedAccounts`
- Copy strategy: `Override`
- Source database: `Sodreconciliation` (`DB_Schema`)
- Source schema/table: `apex.EXT538_ClosedAccounts`
- 9 of 9 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | STRING | YES | Primary key. Auto-generated sequential GUID for each row (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |
| 1 | SodFileId | STRING | YES | FK to apex.SodFiles. Links this row to the specific EXT538 file import. CASCADE DELETE (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |
| 2 | AccountNumber | STRING | YES | Apex customer account number. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |
| 3 | AccountName | STRING | YES | Account holder name. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |
| 4 | RestrictReasonCode | STRING | YES | Restriction reason code indicating why the account was closed (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |
| 5 | OfficeCurrency | STRING | YES | Currency code for the office/account (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |
| 6 | MarketValue | DECIMAL | YES | Remaining market value of securities in the closed account (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |
| 7 | CashBalance | DECIMAL | YES | Remaining cash balance in the closed account (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |
| 8 | TotalEquity | DECIMAL | YES | Total equity remaining (MarketValue + CashBalance) (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `Sodreconciliation.apex.EXT538_ClosedAccounts` | Primary | `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` |

### 4.2 Pipeline ASCII Diagram

```
Sodreconciliation.apex.EXT538_ClosedAccounts
        │
        ▼
main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |
| SodFileId | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |
| AccountNumber | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |
| AccountName | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |
| RestrictReasonCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |
| OfficeCurrency | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |
| MarketValue | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |
| CashBalance | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |
| TotalEquity | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT538_ClosedAccounts.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT538_ClosedAccounts) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 9 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 9/9 | Source: bronze_tier1_inheritance*
