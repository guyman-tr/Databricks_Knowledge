---
object_fqn: main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 12
row_count: null
generated_at: '2026-05-19T12:12:51Z'
upstreams:
- FiatDwhDB.dbo.FiatCardInstances
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md
  source_database: FiatDwhDB
  source_schema: dbo
  source_table: FiatCardInstances
  source_repo: BankingDBs
  datalake_path: Bronze/FiatDwhDB/dbo/FiatCardInstances
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_fiatdwhdb_dbo_fiatcardinstances

> Bronze ingest in `main.bi_db` (1:1 passthrough of `FiatDwhDB.dbo.FiatCardInstances`). 9 of 12 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 12 |
| **Generated** | 2026-05-19 |
| **Created** | Wed May 15 13:56:03 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `FiatDwhDB.dbo.FiatCardInstances` (`BankingDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md`.

- Lake path: `Bronze/FiatDwhDB/dbo/FiatCardInstances`
- Copy strategy: `Append`
- Source database: `FiatDwhDB` (`BankingDBs`)
- Source schema/table: `dbo.FiatCardInstances`
- 9 of 12 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | LONG | YES | Auto-incrementing surrogate PK. Referenced by FiatCardStatuses.CardInstanceId (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 1 | CardId | LONG | YES | Implicit FK to dbo.FiatCards.Id. The logical card this instance belongs to. No explicit FK constraint in DDL (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 2 | MaskedPAN | STRING | YES | Masked card number showing only last digits. Dynamic data masking protects the full PAN (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 3 | IsVirtual | BOOLEAN | YES | Whether this is a virtual (digital wallet) card: 1=virtual, 0=physical plastic card (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 4 | Created | TIMESTAMP | YES | UTC timestamp when this instance was recorded (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 5 | CorrelationId | STRING | YES | Links this instance creation to the triggering business operation for distributed tracing (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 6 | Name | STRING | YES | Cardholder name printed on the card. Masked for PII protection (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 7 | CardExpirationDate | TIMESTAMP | YES | Expiration date of this card instance. NULL for instances where expiration is not yet set (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 8 | CardInstanceGuid | STRING | YES | External-facing GUID for this card instance. Used in API interactions. Nullable for legacy instances created before this field was added (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances). |
| 9 | etr_y | INT | YES | Source: FiatDwhDB.dbo.FiatCardInstances.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 10 | etr_ym | STRING | YES | Source: FiatDwhDB.dbo.FiatCardInstances.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 11 | etr_ymd | DATE | YES | Source: FiatDwhDB.dbo.FiatCardInstances.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `FiatDwhDB.dbo.FiatCardInstances` | Primary | `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` |

### 4.2 Pipeline ASCII Diagram

```
FiatDwhDB.dbo.FiatCardInstances
        │
        ▼
main.bi_db.bronze_fiatdwhdb_dbo_fiatcardinstances   ←── this object
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
| Id | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| CardId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| MaskedPAN | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| IsVirtual | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| Created | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| CorrelationId | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| Name | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| CardExpirationDate | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| CardInstanceGuid | upstream wiki `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` (bronze passthrough) | 1 | (Tier 1 — inherited from FiatDwhDB.dbo.FiatCardInstances) |
| etr_y | would inherit from `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatCardInstances.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 9 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 12/12 | Source: bronze_tier1_inheritance*
