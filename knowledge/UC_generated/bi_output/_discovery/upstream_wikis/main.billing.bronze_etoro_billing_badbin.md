---
object_fqn: main.billing.bronze_etoro_billing_badbin
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_badbin
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 3
row_count: null
generated_at: '2026-05-18T10:58:28Z'
upstreams:
- etoro.Billing.BadBin
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md
  source_database: etoro
  source_schema: Billing
  source_table: BadBin
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/BadBin
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

# bronze_etoro_billing_badbin

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.BadBin`). 3 of 3 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_badbin` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 3 |
| **Generated** | 2026-05-18 |
| **Created** | Sun Mar 29 12:18:08 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.BadBin` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md`.

- Lake path: `Bronze/etoro/Billing/BadBin`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.BadBin`
- 3 of 3 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | BinFrom | INT | YES | Start of the blocked BIN range (inclusive). Part of the composite PK. For single-BIN blocks, equals BinTo. Represents the first 6 or 8 digits of the card number (Tier 1 — inherited from etoro.Billing.BadBin). |
| 1 | BinTo | INT | YES | End of the blocked BIN range (inclusive). Part of the composite PK. For single-BIN blocks, equals BinFrom. Any card whose BIN prefix falls in [BinFrom, BinTo] is considered blocked (Tier 1 — inherited from etoro.Billing.BadBin). |
| 2 | BlockReasonID | INT | YES | Optional block reason code. NULL = blocked without a specific coded reason (the overwhelming majority of rows). Non-NULL values reference a reason catalog (only BlockReasonID=1 observed in live data, applied to 2 rows at BIN 40380600-40380601). No FK constraint defined (Tier 1 — inherited from etoro.Billing.BadBin). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.BadBin` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.BadBin
        │
        ▼
main.billing.bronze_etoro_billing_badbin   ←── this object
        │
        ▼
main.bi_output.vg_fullbincodelist
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
| BinFrom | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.BadBin) |
| BinTo | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.BadBin) |
| BlockReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.BadBin.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.BadBin) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 3 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 3/3 | Source: bronze_tier1_inheritance*
