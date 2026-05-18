---
object_fqn: main.billing.bronze_etoro_backoffice_documentvendors
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_backoffice_documentvendors
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 2
row_count: null
generated_at: '2026-05-18T10:58:25Z'
upstreams:
- etoro.BackOffice.DocumentVendors
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md
  source_database: etoro
  source_schema: BackOffice
  source_table: DocumentVendors
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/DocumentVendors
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_documentvendors

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.BackOffice.DocumentVendors`). 2 of 2 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_backoffice_documentvendors` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 2 |
| **Generated** | 2026-05-18 |
| **Created** | Fri Jul 14 07:25:20 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.DocumentVendors` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md`.

- Lake path: `Bronze/etoro/BackOffice/DocumentVendors`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.DocumentVendors`
- 2 of 2 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DocumentID | INT | YES | The KYC document that was processed. FK (WITH CHECK) to BackOffice.CustomerDocument(DocumentID). Leading key of NC PK. 893,779 distinct values. Deletions cascade from DeleteUserDocument (Tier 1 — inherited from etoro.BackOffice.DocumentVendors). |
| 1 | Vendor | STRING | YES | The verification vendor name or code. Part of NC PK. Free-text, no FK constraint. Known values: "100" (legacy), "Onfido", "Sumsub", "Au10tix", "IDnow". Max 1024 chars - generous allocation for potentially long vendor identifiers or JSON-encoded metadata (Tier 1 — inherited from etoro.BackOffice.DocumentVendors). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.DocumentVendors` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.DocumentVendors
        │
        ▼
main.billing.bronze_etoro_backoffice_documentvendors   ←── this object
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
| DocumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.DocumentVendors) |
| Vendor | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentVendors.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.DocumentVendors) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 2 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 2/2 | Source: bronze_tier1_inheritance*
