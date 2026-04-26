# BI_DB_dbo.BI_DB_Document_Vendors

> 992.7K-row KYC document verification analytics table tracking vendor classification outcomes for identity and selfie documents submitted in the last 4 months (~333K distinct CIDs, Dec 2025–Apr 2026). Populated by `SP_Document_Vendors` via daily TRUNCATE+INSERT, sourcing from BackOffice document External tables and enriched with `Dim_Customer`/`Dim_Regulation`/`Dim_Country`. Covers 3 verification vendors (Onfido 63.7%, Sumsub 36.3%, Au10tix <0.1%) with complex outcome classification logic.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BackOffice document External tables via `SP_Document_Vendors` — `External_etoro_BackOffice_CustomerDocument`, `CustomerDocumentToDocumentType`, `DocumentVendors`, `DocumentAuthenticationReasons` + DWH dimensions |
| **Refresh** | SB_Daily, daily TRUNCATE+INSERT (4-month rolling window) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Pavlina Masoura (2022-10-03) |

---

## 1. Business Meaning

This table is a KYC (Know Your Customer) document verification analytics dashboard for the compliance team. Each row represents one document submission event, capturing how the verification vendor (Onfido, Sumsub, or Au10tix) classified the document and what the final disposition was after potential human review.

**Purpose**: Track auto-acceptance/rejection rates by vendor, identify slow vendor responses, measure manual review volumes, and analyze override patterns across document types (POI, POA, Selfie).

**Population**: Documents submitted in the last 4 months where DocumentTypeID IN (1,2,15,6,18,23) — Proof of Identity, Proof of Address, Selfie, SelfieLiveliness, and Selfie Motion documents. Only valid customers (IsValidCustomer=1) are included after enrichment.

**Key semantics**:
- **TRUNCATE+INSERT** — the entire table is rebuilt daily; no historical accumulation
- **OriginalOutcome** = what the vendor initially decided (Accepted/Rejected/Manual Review/Slow response)
- **FinalOutcome** = final disposition after human intervention (Auto-Accepted/Auto-Rejected/Manually Accepted/Manually Rejected/Slow response from vendor)
- **Overriden** = 1 when a human manager reviewed the document (ManagerID != 0 and not NULL)
- Documents with multiple classification events are handled separately: first event vs last event determines original vs final outcome
- Three separate code paths exist: POI/POA via Onfido/Sumsub, Selfie via Au10tix, SelfieLiveliness/Selfie Motion via Onfido

---

## 2. Business Logic

### 2.1 Document Classification Pipeline

**What**: Documents flow through vendors and may be reclassified by human reviewers.
**Columns Involved**: Classification, SuggestedDocumentType, ClassifiedBy, Overriden, OriginalOutcome, FinalOutcome
**Rules**:
- Single-event documents (#1countdocumentid): First/last event are the same
- Multi-event documents (#MoreThan1countdocumentid): First event = original vendor decision, last event = final after review
- ClassifiedBy = 'System' indicates automated vendor decision; any other value = human reviewer name
- Overriden = 1 when ManagerID is non-zero (human intervened)

### 2.2 POI/POA Outcome Logic (Onfido/Sumsub)

**What**: Complex CASE logic determines outcomes for Proof of Identity and Proof of Address.
**Columns Involved**: OriginalOutcome, FinalOutcome, Classification, Vendor
**Rules**:
- Auto-Accepted: Classification matches expected type AND ClassifiedBy = 'System'
- Auto-Rejected: Classification = 'Not Accepted' AND ClassifiedBy = 'System'
- Manually Accepted/Rejected: ClassifiedBy is a person name
- Slow response from vendor: First event was by non-System AND last event is by System (vendor was slow)
- Manually Accepted as Other (NEW outcome): Final classification differs from both expected and 'Not Accepted'

### 2.3 Selfie Verification (Au10tix/Onfido)

**What**: Selfie/Liveness verification has different logic per vendor.
**Columns Involved**: DocumentTypeCategory, reasonList, FinalOutcome
**Rules**:
- Au10tix handles 'Selfie' documents; Onfido handles 'SelfieLiveliness' and 'Selfie Motion'
- reasonList contains comma-separated authentication reasons (Match, Faces Do Not Match, Face Was Not Detected, Forged Selfie, etc.)
- reasonList = 'Match' → Accepted; Forged/Not Detected → Rejected; Indecisive → Manual Review
- Onfido selfie has a cross-check: if a selfie is Accepted but the same CID+Date has a POI in Manual Review, the selfie FinalOutcome is overridden to Manual Review

### 2.4 Document Type Category Mapping

**What**: Normalizes document classification into 5 standard categories.
**Columns Involved**: DocumentTypeCategory
**Rules**:
- Proof of Identity (DocumentTypeID 1)
- Proof of address (DocumentTypeID 2)
- Selfie (DocumentTypeID 6)
- SelfieLiveliness (DocumentTypeID 15)
- Selfie Motion (DocumentTypeID 23, added 2024-03-27)
- Falls through Classification first, then SuggestedDocumentType

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no distribution or index optimization. Table is small (~1M rows). Full scans are acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Auto-acceptance rate by vendor | `SELECT Vendor, SUM(CASE WHEN FinalOutcome='Auto-Accepted' THEN 1 END)*100.0/COUNT(*) FROM ... GROUP BY Vendor` |
| Manual review volume by document type | `SELECT DocumentTypeCategory, COUNT(*) WHERE FinalOutcome LIKE 'Manual%' GROUP BY DocumentTypeCategory` |
| Override rate | `SELECT SUM(Overriden)*100.0/COUNT(*) FROM ...` |
| Slow vendor response trends | `SELECT CAST(DateAdded AS DATE), COUNT(*) WHERE FinalOutcome='Slow response from vendor' GROUP BY CAST(DateAdded AS DATE)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |

### 3.4 Gotchas

- **IDENTITY column ID**: System-generated, not meaningful for business logic — do not use for joins
- **varchar(max) everywhere**: Most text columns are varchar(max) — watch for performance on string operations
- **TRUNCATE+INSERT**: No history — only the last 4 months of data exist at any time
- **Empty FinalOutcome**: 252 rows have blank (not NULL) FinalOutcome — edge cases not covered by CASE logic
- **reasonList format**: Comma-separated with inconsistent trailing commas (e.g., 'Match,' vs 'Match')
- **Vendor Au10tix nearly extinct**: Only 206 rows — legacy vendor, mostly replaced by Onfido for selfies
- **Overriden typo**: Column name has a typo (should be "Overridden") — preserved from DDL

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki documentation |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / propagation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | System-generated identity column (IDENTITY(1,1)). Auto-incremented row identifier, not meaningful for business logic. (Tier 2 — DDL IDENTITY) |
| 2 | CID | int | YES | eToro customer ID (Real CID). From External_BackOffice_CustomerDocument. Filtered to IsValidCustomer=1 via Dim_Customer. (Tier 2 — SP_Document_Vendors, via External_BackOffice_CustomerDocument) |
| 3 | DocumentID | bigint | YES | Unique document submission identifier from BackOffice.CustomerDocument. Multiple rows may share a DocumentID when a document has multiple classification events. (Tier 2 — SP_Document_Vendors, via External_BackOffice_CustomerDocument) |
| 4 | Classification | varchar(max) | YES | Final document type classification name from Dictionary.DocumentType. Values: 'Proof of Identity', 'Proof of address', 'Not Accepted', 'SelfieLiveliness', 'Selfie', 'Selfie Motion'. NULL when pending review. (Tier 2 — SP_Document_Vendors, via External_Dictionary_DocumentType) |
| 5 | SuggestedDocumentType | varchar(max) | YES | Originally suggested document type name from Dictionary.DocumentType, based on what the customer uploaded. May differ from Classification when vendor reclassifies. (Tier 2 — SP_Document_Vendors, via External_Dictionary_DocumentType) |
| 6 | ClassificationDate | datetime | YES | Timestamp when the document was classified (Occurred from CustomerDocumentToDocumentType). Multiple events per document — this is the last event's date (RNLast=1) in the final output. (Tier 2 — SP_Document_Vendors, via External_BackOffice_CustomerDocumentToDocumentType) |
| 7 | ClassifiedBy | varchar(max) | YES | Who classified the document: 'System' for automated vendor decisions, or manager full name (FirstName + LastName from Dim_Manager) for human reviews. (Tier 2 — SP_Document_Vendors) |
| 8 | Comment | varchar(max) | YES | Free-text comment from the document record in BackOffice.CustomerDocument. (Tier 2 — SP_Document_Vendors, via External_BackOffice_CustomerDocument) |
| 9 | DateAdded | datetime | YES | Date when the document was originally uploaded by the customer. CAST to DATE from CustomerDocument.DateAdded. Used as the rolling window filter (last 4 months). (Tier 2 — SP_Document_Vendors, via External_BackOffice_CustomerDocument) |
| 10 | ExpiryDate | datetime | YES | Document expiry date from CustomerDocumentToDocumentType. Applicable to identity documents with expiration. (Tier 2 — SP_Document_Vendors, via External_BackOffice_CustomerDocumentToDocumentType) |
| 11 | reasonList | varchar(max) | YES | Comma-separated list of authentication reasons from DocumentAuthenticationReasons + Dictionary.AuthenticationReason. Values include: Match, Faces Do Not Match, Face Was Not Detected, Forged Selfie, Indecisive, Unrecognized Document, Only Backside Document, Over Match. (Tier 2 — SP_Document_Vendors) |
| 12 | RejectReasonName | varchar(max) | YES | Rejection reason name from Dictionary.DocumentRejectReason. NULL when document was not rejected. (Tier 2 — SP_Document_Vendors, via External_Dictionary_DocumentRejectReason) |
| 13 | Overriden | int | YES | Human override flag: 1 if a manager reviewed the document (ManagerID != 0 and not NULL), 0 if automated system decision. Column name has typo (should be "Overridden"). (Tier 2 — SP_Document_Vendors) |
| 14 | Regulation | varchar(max) | YES | Customer's regulation name from Dim_Regulation (e.g., CySEC, FCA, ASIC). Joined via Dim_Customer.RegulationID. (Tier 2 — SP_Document_Vendors, via Dim_Regulation.Name) |
| 15 | Country | varchar(max) | YES | Customer's country name from Dim_Country. Joined via Dim_Customer.CountryID. (Tier 2 — SP_Document_Vendors, via Dim_Country.Name) |
| 16 | DocumentTypeCategory | varchar(max) | YES | Normalized document category: 'Proof of Identity', 'Proof of address', 'Selfie', 'SelfieLiveliness', 'Selfie Motion'. Derived from Classification first, falls through to SuggestedDocumentType if Classification doesn't match. (Tier 2 — SP_Document_Vendors) |
| 17 | OriginalOutcome | varchar(max) | YES | Original vendor verdict before human review. Values: 'Accepted', 'Rejected', 'Manual Review', 'Slow response from vendor', 'Manual Review (pending)'. Complex vendor-specific CASE logic. (Tier 2 — SP_Document_Vendors) |
| 18 | FinalOutcome | varchar(max) | YES | Final disposition after human review. Values: 'Auto-Accepted', 'Auto-Rejected', 'Manually Accepted', 'Manually Rejected', 'Slow response from vendor', 'Manually Accepted as Other (NEW outcome)', 'NULL(Pending manual Review)', 'Manual Review (pending)'. (Tier 2 — SP_Document_Vendors) |
| 19 | Vendor | varchar(max) | YES | Verification vendor name: 'Onfido' (63.7%), 'Sumsub' (36.3%), 'Au10tix' (<0.1%). From External_BackOffice_DocumentVendors. (Tier 2 — SP_Document_Vendors, via External_BackOffice_DocumentVendors) |
| 20 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_Document_Vendors (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID | External_BackOffice_CustomerDocument | CID | Direct |
| DocumentID | External_BackOffice_CustomerDocument | DocumentID | Direct |
| Classification | External_Dictionary_DocumentType | Name | JOIN via DocumentTypeID |
| Vendor | External_BackOffice_DocumentVendors | Vendor | Direct |
| OriginalOutcome | Computed | Multiple | Complex vendor-specific CASE |
| FinalOutcome | Computed | Multiple | Complex vendor-specific CASE |
| Regulation | Dim_Regulation | Name | JOIN via Dim_Customer |
| Country | Dim_Country | Name | JOIN via Dim_Customer |

### 5.2 ETL Pipeline

```
etoro.BackOffice.CustomerDocument (document records)
etoro.BackOffice.CustomerDocumentToDocumentType (classification events)
etoro.BackOffice.DocumentVendors (vendor assignments)
etoro.Dictionary.DocumentType (type names)
etoro.Dictionary.DocumentRejectReason (reject reasons)
etoro.BackOffice.DocumentAuthenticationReasons (auth reasons)
  |-- via External tables → Generic Pipeline → lake --|
  v
BI_DB_dbo.External_etoro_* (6 external tables)
DWH_dbo.Dim_Manager (classifier names)
DWH_dbo.Dim_Customer + Dim_Regulation + Dim_Country (enrichment)
  |
  |-- SP_Document_Vendors (daily TRUNCATE+INSERT) --|
  |   #details (base join, 4-month window)          |
  |   #One + #MoreThanOne (single/multi event)      |
  |   #authentix (Au10tix selfies)                   |
  |   #onfido1 (Onfido selfie/liveness)              |
  |   #union1 (merge all vendor paths)               |
  |   #det1 (enrich with customer dims)              |
  v
BI_DB_dbo.BI_DB_Document_Vendors (992.7K rows)
  |
  (UC: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Vendor Auto-Acceptance Rate

```sql
SELECT Vendor,
    COUNT(*) AS total_docs,
    SUM(CASE WHEN FinalOutcome = 'Auto-Accepted' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS auto_accept_pct,
    SUM(CASE WHEN FinalOutcome = 'Auto-Rejected' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS auto_reject_pct,
    SUM(CASE WHEN FinalOutcome LIKE 'Manual%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS manual_pct
FROM [BI_DB_dbo].[BI_DB_Document_Vendors]
GROUP BY Vendor
```

### 7.2 Override Analysis by Document Type

```sql
SELECT DocumentTypeCategory,
    SUM(Overriden) AS overridden_count,
    COUNT(*) AS total,
    SUM(Overriden) * 100.0 / COUNT(*) AS override_pct
FROM [BI_DB_dbo].[BI_DB_Document_Vendors]
GROUP BY DocumentTypeCategory
ORDER BY override_pct DESC
```

### 7.3 Slow Vendor Response by Regulation

```sql
SELECT Regulation, Vendor, COUNT(*) AS slow_responses
FROM [BI_DB_dbo].[BI_DB_Document_Vendors]
WHERE FinalOutcome = 'Slow response from vendor'
GROUP BY Regulation, Vendor
ORDER BY slow_responses DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 18 T2, 0 T3, 0 T4, 1 T5 | Elements: 20/20, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Document_Vendors | Type: Table | Production Source: SP_Document_Vendors (External tables + DWH enrichment)*
