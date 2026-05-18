---
object_fqn: main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 16
row_count: null
generated_at: '2026-05-18T10:58:24Z'
upstreams:
- etoro.BackOffice.CustomerDocumentToDocumentType
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md
  source_database: etoro
  source_schema: BackOffice
  source_table: CustomerDocumentToDocumentType
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/BackOffice/CustomerDocumentToDocumentType
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 16
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_backoffice_customerdocumenttodocumenttype

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.BackOffice.CustomerDocumentToDocumentType`). 16 of 16 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 16 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Mar 19 13:15:30 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.BackOffice.CustomerDocumentToDocumentType` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md`.

- Lake path: `Bronze/etoro/BackOffice/CustomerDocumentToDocumentType`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `BackOffice.CustomerDocumentToDocumentType`
- 16 of 16 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DocumentToDocumentTypeID | INT | YES | Auto-generated unique classification record ID. NOT FOR REPLICATION. Clustered PK. Referenced by BackOffice.CustomerTranslationDetails (via DocumentToDocumentTypeID) (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 1 | DocumentID | INT | YES | The document being classified. FK (WITH CHECK) to BackOffice.CustomerDocument(DocumentID). Multiple rows per DocumentID are allowed (re-classification history). Part of the UNIQUE constraint (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 2 | DocumentTypeID | INT | YES | The formal document type assigned by the BackOffice agent or automation. FK (WITH CHECK) to Dictionary.DocumentType. Key values: 1=Proof of Address (7.5%), 2=Proof of Identity (59.8%), 3=Credit Card (1.0%), 6=Not Accepted - rejected (3.3%), 12=W-8BEN Form (7.7%), 14=W9 (18.1%), 15=Selfie, 17=VideoIdent, 18=SelfieLiveliness, 22=SSN Card. MaxAgeInMonths in Dictionary.DocumentType defines validity period (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 3 | IssueDate | TIMESTAMP | YES | The date the document was issued (e.g., passport issue date). NULL for document types where issue date is not relevant (most POI records use ExpiryDate instead). For POA, IssueDate is when the utility bill/bank statement was issued. Part of the UNIQUE constraint to allow re-classification with different dates (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 4 | ExpiryDate | TIMESTAMP | YES | The date after which this document classification is considered expired and must be re-submitted. Critical for passport expiry (POI), POA staleness (36 months), W-8BEN/W9 renewals. GetExpiredIdentityDocuments queries this field. Some rows have ExpiryDate=2034 as a sentinel "no expiry" value. Part of UNIQUE constraint (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 5 | FundingID | INT | YES | Links this classification to a specific payment/funding record when the document is associated with a credit card or payment method verification (e.g., credit card copy). FK (WITH CHECK) to Billing.Funding(FundingID). NULL for 99% of rows - only populated for DocumentTypeID=3 (Credit Card) cases. Part of UNIQUE constraint. Filtered NC index for fast FundingID lookups (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 6 | ManagerID | INT | YES | BackOffice agent who performed this classification. 0=Au10tix automated classification system. Non-zero=manual BackOffice agent (FK semantics to BackOffice.Manager, no constraint). NULL for 1 row only (data anomaly) (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 7 | Comment | STRING | YES | Agent's note or automation message for this classification. Common values: "" (empty, BackOffice agent with no note), "Authenticate by au10tix" (automated), specific rejection explanation text. Max 1024 chars (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 8 | RejectReasonID | INT | YES | Rejection reason when DocumentTypeID=6 (Not Accepted). Implicit FK to Dictionary.DocumentRejectReason. NULL for 96.7% of rows (approved/pending classifications). Top values: 15=POA cannot be accepted (34,289), 4=POI Expired (4,205), 38=SSN not acceptable (1,618), 14=POA missing address (1,090). See Section 2.2 for full reason list (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 9 | RejectEmailSent | BOOLEAN | YES | Whether the rejection notification email was sent to the customer. 1=sent, 0=not sent, NULL=not applicable (non-rejection classification). NULL for 96.9% of rows. Used with DocumentRejectReasonToNotificationType to determine email template (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 10 | Translated | INT | YES | Flag indicating whether a translation was provided for this document (for non-English documents requiring translation). 1=translated. NULL for 99.9% of rows - rarely used. Updated via CustomerDocumentTypeUpdateTranslatedStatus procedure (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 11 | DocumentClassificationID | INT | YES | Sub-classification refining the DocumentTypeID. FK (WITH CHECK) to Dictionary.DocumentClassification. Examples under DocumentTypeID=2 (POI): 1=Passport, 2=ID, 3=Driving License, 4=Electoral Card, 46=Residence Permit. Under DocumentTypeID=1 (POA): 6=Utility Bill, 7=Bank Statement, 40=Driving License POA. NULL for older rows that predate this field. 73 classification values in total (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 12 | SignedDate | TIMESTAMP | YES | Date the document was signed. Relevant for DocumentTypeID=4 (Authorization Form) and DocumentTypeID=9 (Client Forms). NULL for most rows (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 13 | Occurred | TIMESTAMP | YES | UTC timestamp when this classification record was created. Default GETUTCDATE(). NULL for rows created before this column was added (pre-2020). Latest value extends to 2034 in some rows - these appear to be sentinel values (not actual classification dates) (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 14 | SideID | INT | YES | Which side(s) of the physical document were submitted. FK (WITH CHECK) to Dictionary.DocumentSide. Values: 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. NULL for 40.3% of rows (pre-dates this field or not applicable for single-sided documents). Part of UNIQUE constraint (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |
| 15 | VisaTypeID | INT | YES | US work/student visa type for visa documents (DocumentClassificationID=65 "US Visa"). FK (WITH CHECK) to Dictionary.VisaType. Values: 1=E1, 2=E2, 3=E3, 4=F1, 5=G4, 6=H1B, 7=L1, 8=O1, 9=TN1, 10=TN2. NULL for 99.9% of rows. Added 2022-05-10 per COMOP-4557 to support US eToro customers with non-citizen work visas as POI (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.BackOffice.CustomerDocumentToDocumentType` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.BackOffice.CustomerDocumentToDocumentType
        │
        ▼
main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype   ←── this object
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
| DocumentToDocumentTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| DocumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| DocumentTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| IssueDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| ExpiryDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| Comment | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| RejectReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| RejectEmailSent | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| Translated | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| DocumentClassificationID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| SignedDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| Occurred | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| SideID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |
| VisaTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.BackOffice.CustomerDocumentToDocumentType) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 16 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 16/16 | Source: bronze_tier1_inheritance*
