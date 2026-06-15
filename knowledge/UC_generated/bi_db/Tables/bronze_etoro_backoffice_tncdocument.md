---
object_fqn: main.bi_db.bronze_etoro_backoffice_tncdocument
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_backoffice_tncdocument
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 12
row_count: null
generated_at: '2026-05-19T12:12:42Z'
upstreams:
- etoro.BackOffice.TncDocument
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md
  source_database: etoro
  source_schema: BackOffice
  source_table: TncDocument
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/TncDocument
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 12
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_tncdocument

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.BackOffice.TncDocument`). 12 of 12 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_backoffice_tncdocument` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 12 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Dec 08 08:15:32 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.TncDocument` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md`.

- Lake path: `Bronze/etoro/BackOffice/TncDocument`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.TncDocument`
- 12 of 12 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DocumentID | INT | YES | Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each T&C document entry. Referenced by BackOffice.ZendeskDocuments (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 1 | RegulationID | INT | YES | The regulatory jurisdiction this document applies to. Maps to Dictionary.Regulation.ID values (1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 6=eToroUS, etc.). Customers are shown the document matching their regulation (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 2 | ManagerID | INT | YES | The back-office manager who uploaded this document. Audit trail reference to BackOffice.Manager.ManagerID (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 3 | DisplayName | STRING | YES | Human-readable name shown to customers in the T&C acceptance UI (e.g., "Terms and Conditions - CySEC") (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 4 | ComputerName | STRING | YES | Hostname of the machine from which the document was uploaded. Used for upload audit trail (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 5 | FileName | STRING | YES | Physical filename/path of the PDF in storage. Format: `{RegulationID}-{timestamp}-{original_name}.pdf`. Used by StorageID to locate the file (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 6 | DateAdded | TIMESTAMP | YES | Timestamp when this document was uploaded/registered. Earliest records from 2015-05-03 (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 7 | StorageID | INT | YES | Reference to the external storage system record (blob store or file share). Used with FileName to retrieve the actual PDF (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 8 | TncDocTypeID | INT | YES | FK to Dictionary.TncDocType. Classifies the document type. Default=1 (main Terms & Conditions). Other values may represent product-specific or jurisdictional addenda (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 9 | Enabled | BOOLEAN | YES | 1=Document is active and visible to customers. 0=Document is suppressed/hidden without deletion. Can be toggled independently of IsActive (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 10 | IsActive | BOOLEAN | YES | 1=Document is the current valid version. 0=Document has been superseded by a newer version (set by TncDocumentUpdateIsActive). Used with Enabled to determine if document is served to customers (Tier 1 — inherited from etoro.BackOffice.TncDocument). |
| 11 | CountryID | INT | YES | FK to Dictionary.Country. If non-NULL, this document applies only to customers in the specified country within the regulation. NULL=applies to all countries in the regulation. Enables country-specific T&C overrides (Tier 1 — inherited from etoro.BackOffice.TncDocument). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.TncDocument` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.TncDocument
        │
        ▼
main.bi_db.bronze_etoro_backoffice_tncdocument   ←── this object
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
| DocumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| RegulationID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| DisplayName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| ComputerName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| FileName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| DateAdded | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| StorageID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| TncDocTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| Enabled | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| IsActive | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |
| CountryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.TncDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.TncDocument) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 12 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 12/12 | Source: bronze_tier1_inheritance*
