---
object_fqn: main.billing.bronze_etoro_backoffice_customerrisk
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_backoffice_customerrisk
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 7
row_count: null
generated_at: '2026-05-18T10:58:24Z'
upstreams:
- etoro.BackOffice.CustomerRisk
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md
  source_database: etoro
  source_schema: BackOffice
  source_table: CustomerRisk
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/CustomerRisk
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_customerrisk

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.BackOffice.CustomerRisk`). 7 of 7 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_backoffice_customerrisk` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 7 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Mar 19 13:15:14 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.CustomerRisk` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md`.

- Lake path: `Bronze/etoro/BackOffice/CustomerRisk`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.CustomerRisk`
- 7 of 7 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Group Customer ID - person-level identifier spanning all accounts across regulatory jurisdictions. Part of composite PK. A customer can have multiple risk flags (different RiskStatusIDs for same GCID). See BackOffice.CustomerDocument for GCID description (Tier 1 — inherited from etoro.BackOffice.CustomerRisk). |
| 1 | RiskStatusID | INT | YES | The specific risk alert type. Part of composite PK. FK to Dictionary.RiskStatus. 90 defined types (0=None, 1=Normal, 2-90=specific risk flags). Active types include: velocity checks (2,3,38-42,61,66,68,74,88), country/geo conflicts (6,7,8,17,28,32,72,87), fraud indicators (12,31,37,42,63,64,69,73,89,90), document quality (30,43,45,46,48-50,62,71), affiliate abuse (10,11,60), AML/behavior (26,29,70,82,83). Inactive types (IsActive=false) represent deprecated risk categories (Tier 1 — inherited from etoro.BackOffice.CustomerRisk). |
| 2 | Occurred | TIMESTAMP | YES | Timestamp when the risk event originally occurred. Defaults to current UTC time on INSERT. Historical rows with '1900-01-01' indicate legacy imports where the original event time was unknown (Tier 1 — inherited from etoro.BackOffice.CustomerRisk). |
| 3 | ModifiedDate | TIMESTAMP | YES | Timestamp of the last status change or update to this risk flag. Always reflects the most recent modification. Used for risk queue ordering and SLA tracking (Tier 1 — inherited from etoro.BackOffice.CustomerRisk). |
| 4 | Remark | STRING | YES | Free-text note by the Risk agent explaining the risk situation, investigation findings, or resolution rationale. Optional - may be NULL for automatically-generated flags before agent review (Tier 1 — inherited from etoro.BackOffice.CustomerRisk). |
| 5 | RiskEventStatusID | INT | YES | Current lifecycle status of the risk flag. FK to Dictionary.RiskEventStatus. Values: 1=On (active, requires attention), 2=InProcess (under investigation), 3=Off (resolved/cleared, dictionary IsActive=false). 1.37M rows are On, 97K are InProcess or Off (Tier 1 — inherited from etoro.BackOffice.CustomerRisk). |
| 6 | ManagerID | INT | YES | BackOffice Risk agent who last modified this flag. NULL for system-generated flags not yet reviewed. FK to BackOffice.Manager (no constraint) (Tier 1 — inherited from etoro.BackOffice.CustomerRisk). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.CustomerRisk` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.CustomerRisk
        │
        ▼
main.billing.bronze_etoro_backoffice_customerrisk   ←── this object
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
| GCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerRisk) |
| RiskStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerRisk) |
| Occurred | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerRisk) |
| ModifiedDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerRisk) |
| Remark | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerRisk) |
| RiskEventStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerRisk) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerRisk.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerRisk) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 7 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 7/7 | Source: bronze_tier1_inheritance*
