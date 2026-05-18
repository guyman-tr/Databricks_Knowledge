---
object_fqn: main.billing.bronze_etoro_backoffice_compensationreason
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_backoffice_compensationreason
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 8
row_count: null
generated_at: '2026-05-18T10:58:21Z'
upstreams:
- etoro.BackOffice.CompensationReason
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md
  source_database: etoro
  source_schema: BackOffice
  source_table: CompensationReason
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/CompensationReason
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_compensationreason

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.BackOffice.CompensationReason`). 8 of 8 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_backoffice_compensationreason` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 8 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Jul 07 04:15:18 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.CompensationReason` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md`.

- Lake path: `Bronze/etoro/BackOffice/CompensationReason`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.CompensationReason`
- 8 of 8 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CompensationReasonID | INT | YES | Auto-generated unique identifier. PK referenced by compensation transaction tables. Used as ParentID for child types in the hierarchy. 136 active rows (IDs not sequential - some were deleted) (Tier 1 — inherited from etoro.BackOffice.CompensationReason). |
| 1 | ParentID | INT | YES | Self-referential FK to CompensationReasonID. NULL = root/department category (9 root nodes: 1, 4, 9, 10, 16, 23, 35, 45, 48). Non-NULL = specific compensation type. FK_BCPR_BCPR enforces valid reference. BCPR_NAME index on Name column (Tier 1 — inherited from etoro.BackOffice.CompensationReason). |
| 2 | Name | STRING | YES | Internal classification name used by BackOffice staff. Descriptive operational names like "Foreclosure (taking all money)", "Hedge Abuser", "Position Airdrop". Has BCPR_NAME index for fast name lookup (Tier 1 — inherited from etoro.BackOffice.CompensationReason). |
| 3 | DisplayName | STRING | YES | Customer-facing label shown in account statement. Decouples internal classification from customer visibility. NULL for 3 types (ID 46, 47, 57) - these may display as empty in statements. Multiple types share "Adjustment", "Promotion", "eToro compensation" as generic labels (Tier 1 — inherited from etoro.BackOffice.CompensationReason). |
| 4 | IsShownInHistory | BOOLEAN | YES | Whether this compensation type appears in the customer's transaction history/statement. 0=hidden from customer view (technical ops, non-cash instrument adjustments). Default 1 (shown). Used by reporting layer to filter customer-visible transactions. Types with 0: Test-Internal, ReopenOperation, Position Airdrop, Stock Split, Spinoff, Stock Dividend, Exchange, Merger, Name Change, Warrants, Rights offer, Staking, REORG Security (Tier 1 — inherited from etoro.BackOffice.CompensationReason). |
| 5 | IsCashflowForGain | BOOLEAN | YES | Whether this compensation represents actual cash flowing in/out of the account, relevant for gain/loss calculations and regulatory capital reporting. 0=non-cash event (instrument adjustments, position reopens, airdrops). Default 1. Critical for financial reporting - non-cash corporate actions (splits, mergers) must be 0 (Tier 1 — inherited from etoro.BackOffice.CompensationReason). |
| 6 | IsTaxable | BOOLEAN | YES | Whether this compensation is a taxable event that must be reported on tax statements (1099 forms, etc.). 0=non-taxable (instrument adjustments like stock splits, mergers, spinoffs that don't trigger tax obligations). Default 1. Drives tax reporting system - every IsTaxable=1 transaction may appear on the customer's annual tax document (Tier 1 — inherited from etoro.BackOffice.CompensationReason). |
| 7 | IsActive | BOOLEAN | YES | Whether this type is still in active use. 0=deprecated (ID 3=Technical Problems under R&D, ID 26=Satisfaction Bonus under Accounting/Ops). Default 1. Inactive types should not be assigned to new compensations (Tier 1 — inherited from etoro.BackOffice.CompensationReason). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.CompensationReason` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.CompensationReason
        │
        ▼
main.billing.bronze_etoro_backoffice_compensationreason   ←── this object
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
| CompensationReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CompensationReason) |
| ParentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CompensationReason) |
| Name | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CompensationReason) |
| DisplayName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CompensationReason) |
| IsShownInHistory | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CompensationReason) |
| IsCashflowForGain | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CompensationReason) |
| IsTaxable | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CompensationReason) |
| IsActive | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CompensationReason) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 8 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 8/8 | Source: bronze_tier1_inheritance*
