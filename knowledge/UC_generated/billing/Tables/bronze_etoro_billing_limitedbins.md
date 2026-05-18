---
object_fqn: main.billing.bronze_etoro_billing_limitedbins
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_limitedbins
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 1
row_count: null
generated_at: '2026-05-18T10:58:36Z'
upstreams:
- etoro.Billing.LimitedBins
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.LimitedBins.md
  source_database: etoro
  source_schema: Billing
  source_table: LimitedBins
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/LimitedBins
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_limitedbins

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.LimitedBins`). 1 of 1 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_limitedbins` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 1 |
| **Generated** | 2026-05-18 |
| **Created** | Sun Mar 29 12:18:19 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.LimitedBins` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.LimitedBins.md`.

- Lake path: `Bronze/etoro/Billing/LimitedBins`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.LimitedBins`
- 1 of 1 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Bin | INT | YES | Credit/debit card BIN (Bank Identification Number) - the first 6 digits of the card number identifying the issuing bank and card program. Serves as both the primary key and the sole data element. Cards whose BIN matches an entry here are treated as "limited" in the deposit flow and may face deposit restrictions (Tier 1 — inherited from etoro.Billing.LimitedBins). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.LimitedBins` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.LimitedBins.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.LimitedBins
        │
        ▼
main.billing.bronze_etoro_billing_limitedbins   ←── this object
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
| Bin | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.LimitedBins.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.LimitedBins) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 1 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 1/1 | Source: bronze_tier1_inheritance*
