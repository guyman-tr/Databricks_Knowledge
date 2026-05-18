---
object_fqn: main.billing.bronze_etoro_backoffice_customerdocument
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_backoffice_customerdocument
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 21
row_count: null
generated_at: '2026-05-18T10:58:23Z'
upstreams:
- etoro.BackOffice.CustomerDocument
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md
  source_database: etoro
  source_schema: BackOffice
  source_table: CustomerDocument
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/CustomerDocument
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 16
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 5
  unverified_columns: 0
---

# bronze_etoro_backoffice_customerdocument

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.BackOffice.CustomerDocument`). 16 of 21 columns inherited from Tier 1 source wiki; 5 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_backoffice_customerdocument` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 21 |
| **Generated** | 2026-05-18 |
| **Created** | Fri May 08 04:21:09 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.CustomerDocument` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md`.

- Lake path: `Bronze/etoro/BackOffice/CustomerDocument`
- Copy strategy: `Append`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.CustomerDocument`
- 16 of 21 columns inherited; 5 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DocumentID | INT | YES | Auto-generated unique document identifier. NC PK; the UNIQUE CLUSTERED index is on (CID, DocumentID) for customer-partitioned range scans. Referenced by BackOffice.CustomerDocumentToDocumentType, BackOffice.DocumentVendors, BackOffice.DocumentAuthenticationReasons, BackOffice.ZendeskDocuments. 13.4M issued (current max), 8.78M active (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 1 | CID | INT | YES | Customer account ID - FK to Customer.CustomerStatic. The primary account the document belongs to. Combined with DocumentID as the unique clustered key (Idx_BackOffice_CustomerDocument_CID) for efficient per-customer document range scans. Note: GCID is used for cross-account person lookups (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 2 | ManagerID | INT | YES | The BackOffice staff member who uploaded or processed this document. 0 = automated system upload (customer self-uploaded via portal or API). Non-zero = manual upload by a BackOffice agent (e.g., from fax, email, or Zendesk attachment). FK to BackOffice.Manager (no constraint) (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 3 | DisplayName | STRING | YES | The original filename as shown to BackOffice staff and in the document management UI. Preserves the customer's original file name (e.g., "passport_scan.jpg", "utility_bill.pdf"). May differ from FileName if the storage layer renamed the file (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 4 | ComputerName | STRING | YES | Legacy field: the name of the computer/workstation from which the document was uploaded. Populated when BackOffice staff uploaded documents from named workstations in older versions of the BackOffice system. In modern automated uploads this may be the hostname of the application server. Not used in current queries (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 5 | FileName | STRING | YES | The stored/persisted filename in the document management system. May differ from DisplayName if the storage layer applies naming conventions on upload. Used internally for file retrieval (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 6 | DateAdded | TIMESTAMP | YES | Timestamp when the document was first uploaded/created in the system. Range from 2009-10-29 (platform launch) to today. Used in GetAllUserDocuments for date filtering (@minDateAdded parameter). Has composite index: (Comment, DateAdded, CID, StorageID) INCLUDE DocumentID for audit queries (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 7 | Accounting | BOOLEAN | YES | Flag intended to link a document to accounting processes. Default 0 and currently 0 for ALL 8.78M rows - this appears to be a planned feature that was never activated in production (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 8 | Obsolete | BOOLEAN | YES | Soft-delete flag: 1 = document has been superseded, found to be fraudulent, or otherwise invalidated. Set by BackOffice.CustomerDocumentObsoleteSign procedure. Only 249 of 8.78M documents are obsolete. GetAllUserDocuments returns the Obsolete flag so the UI can visually differentiate invalid documents (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 9 | Comment | STRING | YES | Optional BackOffice agent comment attached to the document at upload time. Returned by GetAllUserDocuments procedure. Has composite index (Comment, DateAdded, CID, StorageID) enabling comment-based audit searches (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 10 | DocumentSizeActionTypeID | INT | YES | Status of the document's compressed/thumbnail version in the processing pipeline. FK to Dictionary.DocumentSizeActionType. Values: 0="reduced size ready" (thumbnail generated - 99.9999% of docs), 1="no reduced size available" (compression not applicable), 2="not processed yet" (default on insert - processing pipeline pending). Default=2 then updated to 0/1 by processing job (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 11 | StorageID | INT | YES | External document storage system reference key. Points to the actual file blob in the document storage service (CDN/blob storage). 99.9999% populated. NULL for 10 very old records (2009 era before storage system integration). The GetAllUserDocuments procedure filters WHERE StorageID IS NOT NULL, confirming NULL records are excluded from normal operations (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 12 | SuggestedDocumentTypeID | INT | YES | AI vendor's (Au10tix/Onfido) predicted document type classification. FK to Dictionary.DocumentType. Values: 1=Proof of Address, 2=Proof of Identity, 3=Credit Card, 4=Authorization Form, 5=Corporate doc (and more). Set by the automated document classification pipeline on upload. BackOffice agents confirm or override this via CustomerDocumentToDocumentType. 99.99% populated (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 13 | SessionID | STRING | YES | Upload session identifier from the customer's document submission session. Correlates multiple documents uploaded in the same session (e.g., POI + POA submitted together in one KYC flow). Returned by GetAllUserDocuments for session-level tracing (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 14 | SuggestedDocumentSubTypeID | INT | YES | AI vendor's suggested document sub-classification (e.g., subtype of Proof of Identity: Passport vs Driver's License vs National ID). Added by Onfido integration (COMOP-2473, 2021). Returned by GetAllUserDocuments (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 15 | GCID | INT | YES | Group Customer ID - the person-level identifier that spans all of a customer's accounts across regulatory jurisdictions. Links this document to ALL of the customer's eToro accounts (eToro UK CID, eToro CySEC CID, etc.). 100% populated (8.78M/8.78M). Primary search key in GetAllUserDocuments (WHERE cc.GCID = @gcid). Has dedicated ix_CustomerDocuments_GCID index for fast person-level document retrieval (Tier 1 — inherited from etoro.BackOffice.CustomerDocument). |
| 16 | AiCheckID | INT | YES | Source: etoro.BackOffice.CustomerDocument.AiCheckID. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 17 | AiReasoning | STRING | YES | Source: etoro.BackOffice.CustomerDocument.AiReasoning. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 18 | etr_y | INT | YES | Source: etoro.BackOffice.CustomerDocument.etr_y. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 19 | etr_ym | STRING | YES | Source: etoro.BackOffice.CustomerDocument.etr_ym. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 20 | etr_ymd | DATE | YES | Source: etoro.BackOffice.CustomerDocument.etr_ymd. No upstream wiki cached as of 2026-05-18 (Tier 5 — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.CustomerDocument` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.CustomerDocument
        │
        ▼
main.billing.bronze_etoro_backoffice_customerdocument   ←── this object
        │
        ▼
main.bi_output.bi_output_opshighcashoutclientsemail
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
| DocumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| DisplayName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| ComputerName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| FileName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| DateAdded | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| Accounting | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| Obsolete | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| Comment | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| DocumentSizeActionTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| StorageID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| SuggestedDocumentTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| SessionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| SuggestedDocumentSubTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| GCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocument) |
| AiCheckID | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` but column `AiCheckID` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| AiReasoning | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` but column `AiReasoning` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_y | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` but column `etr_y` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` but column `etr_ym` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocument.md` but column `etr_ymd` not present in source wiki | 5 | (Tier 5 — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 16 T1, 0 T2, 0 T3, 0 T4, 5 T5, 0 U | Elements: 21/21 | Source: bronze_tier1_inheritance*
