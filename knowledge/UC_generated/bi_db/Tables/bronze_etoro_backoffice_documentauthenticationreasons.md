---
object_fqn: main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 3
row_count: null
generated_at: '2026-05-19T12:12:41Z'
upstreams:
- etoro.BackOffice.DocumentAuthenticationReasons
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md
  source_database: etoro
  source_schema: BackOffice
  source_table: DocumentAuthenticationReasons
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/DocumentAuthenticationReasons
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_documentauthenticationreasons

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.BackOffice.DocumentAuthenticationReasons`). 3 of 3 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 3 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Jul 31 17:14:43 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.DocumentAuthenticationReasons` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md`.

- Lake path: `Bronze/etoro/BackOffice/DocumentAuthenticationReasons`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.DocumentAuthenticationReasons`
- 3 of 3 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DocumentID | INT | YES | The KYC document being authenticated. Implicit FK to BackOffice.CustomerDocument(DocumentID) - no declared FK constraint. CLUSTERED INDEX leading key - physical storage order is by DocumentID for efficient document-level lookups. Part of NC PK. 886,923 distinct values (Tier 1 — inherited from etoro.BackOffice.DocumentAuthenticationReasons). |
| 1 | ReasonID | INT | YES | Authentication outcome reason code. FK (WITH CHECK) to Dictionary.AuthenticationReason(ReasonID). 107 possible values (0-107 with gaps): 0=Ok (document passed), 1=Expired Document, 3=Name Mismatch, 4=Forged Document, 5=Multipage Document Do Not Match, 6=Not Authentic, 10=Document Type Not Accepted By Etoro, 32=Face Was Not Detected, 34=Address Mismatch, 40=Document Issue Date Not Present, 46=Match (face match check for selfie), 47=Faces Do Not Match, 48=Indecisive, 52=Forged Selfie, 53=Missing Address Details, 80-84=Not Authentic subtypes, 85-90=Bad Quality subtypes, 101=Not Authentic - Inconsistent POA, 103=Fake Webcam, 105=Liveliness Not Detected, 106=Spoofing. Part of NC PK (Tier 1 — inherited from etoro.BackOffice.DocumentAuthenticationReasons). |
| 2 | TypeID | INT | YES | The verification type under which this reason was generated. FK (WITH CHECK) to Dictionary.DocumentAutheticationType(TypeID). Values: 1=POI (81.1%), 2=POA (17.7%), 3=Selfie (0.5%), 4=SelfieLiveliness (0.6%), 5=SelfieMotion (0.06%). Note: "DocumentAutheticationType" has a typo in the dictionary table name (Authe_tic_ation). Default in SetDocumentAuthenticationReasons: 1 (POI). Part of NC PK (Tier 1 — inherited from etoro.BackOffice.DocumentAuthenticationReasons). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.DocumentAuthenticationReasons` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.DocumentAuthenticationReasons
        │
        ▼
main.bi_db.bronze_etoro_backoffice_documentauthenticationreasons   ←── this object
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
| DocumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.DocumentAuthenticationReasons) |
| ReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.DocumentAuthenticationReasons) |
| TypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.DocumentAuthenticationReasons) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 3 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 3/3 | Source: bronze_tier1_inheritance*
