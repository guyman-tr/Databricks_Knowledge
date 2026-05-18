---
object_fqn: main.billing.bronze_recurringmanager_dictionary_frequency
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_recurringmanager_dictionary_frequency
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 2
row_count: null
generated_at: '2026-05-18T10:58:47Z'
upstreams:
- RecurringManager.Dictionary.Frequency
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.Frequency.md
  source_database: RecurringManager
  source_schema: Dictionary
  source_table: Frequency
  source_repo: PaymentsDBs
  datalake_path: Bronze/RecurringManager/Dictionary/Frequency
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

# bronze_recurringmanager_dictionary_frequency

> Bronze ingest in `main.billing` (1:1 passthrough of `RecurringManager.Dictionary.Frequency`). 2 of 2 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_recurringmanager_dictionary_frequency` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | Account admins |
| **Row count** | n/a |
| **Column count** | 2 |
| **Generated** | 2026-05-18 |
| **Created** | Sat Dec 17 14:00:59 UTC 2022 |

---

## 1. What it is

Bronze ingest table populated from production source `RecurringManager.Dictionary.Frequency` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.Frequency.md`.

- Lake path: `Bronze/RecurringManager/Dictionary/Frequency`
- Copy strategy: `Override`
- Source database: `RecurringManager` (`PaymentsDBs`)
- Source schema/table: `Dictionary.Frequency`
- 2 of 2 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FrequencyID | INT | YES | Primary key identifying the frequency. 1=Weekly, 2=BiWeekly, 3=Monthly. Drives the scheduler's next-execution-date calculation. See [Frequency](../../_glossary.md#frequency) for full definitions. (Dictionary.Frequency) (Tier 1 — inherited from RecurringManager.Dictionary.Frequency). |
| 1 | Name | STRING | YES | Human-readable label for the frequency. Values: "Weekly", "BiWeekly", "Monthly" (Tier 1 — inherited from RecurringManager.Dictionary.Frequency). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `RecurringManager.Dictionary.Frequency` | Primary | `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.Frequency.md` |

### 4.2 Pipeline ASCII Diagram

```
RecurringManager.Dictionary.Frequency
        │
        ▼
main.billing.bronze_recurringmanager_dictionary_frequency   ←── this object
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
| FrequencyID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.Frequency.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Dictionary.Frequency) |
| Name | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/RecurringManager/Wiki/Dictionary/Tables/Dictionary.Frequency.md` (bronze passthrough) | 1 | (Tier 1 — inherited from RecurringManager.Dictionary.Frequency) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 2 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 2/2 | Source: bronze_tier1_inheritance*
