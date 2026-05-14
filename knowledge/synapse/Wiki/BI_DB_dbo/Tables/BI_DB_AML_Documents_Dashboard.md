# BI_DB_dbo.BI_DB_AML_Documents_Dashboard

> 71K-row AML (Anti-Money Laundering) document classification dashboard tracking KYC documents reviewed by a specific team of 23 AML analysts. Each row represents one document-to-type classification event, enriched with customer demographics, regulation, club tier, and document metadata. Full TRUNCATE-INSERT daily.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.BackOffice.CustomerDocumentToDocumentType` via external tables + `DWH_dbo.Dim_Customer` enrichment |
| **Refresh** | Daily — TRUNCATE + INSERT (full rebuild) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_AML_Documents_Dashboard` is a compliance-focused reporting table that consolidates KYC/AML document classification activity for a specific group of 23 AML team members. It combines document classification events from production BackOffice tables with customer demographic data from Dim_Customer, creating a flat denormalized view for compliance dashboards.

The table answers: "Which documents were classified by AML team members, what were the outcomes, and what is the customer profile behind each document?" It tracks document types (Proof of Income, Proof of Identity, Proof of MOP, etc.), classification statuses (New Upload, Accepted, Rejected, Reviewed, etc.), reject reasons, and the analyst who performed the review.

Data is sourced from 6 external tables pointing to production `etoro.BackOffice.*` and `etoro.Dictionary.*`, enriched with customer data from `DWH_dbo.Dim_Customer` and its lookup dimensions (Dim_Regulation, Dim_PlayerLevel, Dim_PlayerStatus, Dim_Country). The SP runs daily via SB_Daily (Priority 20), performing a full TRUNCATE + INSERT — the entire table is rebuilt each day. Currently 71,677 rows.

**PII notice**: Contains BirthDate, Gender, Country, CID, ClassificationComment, and Comment — PII-adjacent fields requiring access controls.

---

## 2. Business Logic

### 2.1 AML Team Filter

**What**: Only document classifications performed by a hardcoded list of 23 AML team members are included.

**Columns Involved**: `ClassifiedBy`

**Rules**:
- SP JOINs `Dim_Manager` and filters with `IN ('Ana Paula Maier', 'Deborah Yojay', 'Eden Shalkoff', 'Gillian Chua', ...)` — 23 names total
- The filter is on `dm.FirstName + ' ' + dm.LastName`, not on ManagerID
- Adding or removing AML team members requires an SP code change

### 2.2 Document Classification Workflow

**What**: Each row represents a document classification event — when an AML analyst reviewed a customer-uploaded document and assigned a type/status.

**Columns Involved**: `DocumentAdded`, `DocumentType`, `DocumentStatus`, `ClassificationOccured`, `RejectReason`, `SuggestedDocumentType`

**Rules**:
- `DocumentAdded` = when the customer uploaded the document
- `ClassificationOccured` = when the AML analyst classified it (NULL if not yet classified)
- `DocumentStatus` distribution: New Upload (41%), Accepted (32%), POIApproved (11%), Rejected (7%), Reviewed (7%)
- `RejectReason` is populated only for rejected documents
- `SuggestedDocumentType` = system's auto-suggestion; `DocumentType` = analyst's final classification

### 2.3 Customer Enrichment

**What**: Each document record is enriched with the customer's current profile from Dim_Customer.

**Columns Involved**: `RegisteredReal`, `FirstDepositDate`, `FirstDepositAmount`, `VerificationLevelID`, `IsValidCustomer`, `IsDepositor`, `BirthDate`, `Gender`, `Regulation`, `PlayerStatus`, `Club`, `Country`

**Rules**:
- All customer fields are LEFT JOINed — NULL if Dim_Customer has no match for the CID
- Regulation, PlayerStatus, Club, Country are name-resolved (varchar, not IDs) via dimension JOINs
- VerificationLevelID is the raw integer (0=unverified, 1=partial, 2=intermediate, 3=fully verified)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a HEAP (no index). With 71K rows, full table scans are fast. No distribution key optimization needed — filter on CID, DocumentStatus, or DocumentType for targeted queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Documents reviewed by a specific analyst | `WHERE ClassifiedBy = 'Name'` |
| Rejection rate by document type | `GROUP BY DocumentType` with `CASE WHEN DocumentStatus = 'Rejected'` |
| Unverified customers with pending documents | `WHERE VerificationLevelID < 3 AND DocumentStatus = 'New Upload'` |
| AML review turnaround time | `DATEDIFF(day, DocumentAdded, ClassificationOccured)` |
| Documents by regulation | `GROUP BY Regulation` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in the flat table |
| DWH_dbo.Dim_Date | ON CONVERT(int, CONVERT(varchar, DocumentAdded, 112)) = DateID | Calendar attributes for document upload date |

### 3.4 Gotchas

- **HEAP / no index**: No clustered index. Filter performance relies on full scan — acceptable for 71K rows.
- **Hardcoded analyst list**: The 23-name filter is in SP code. If an analyst joins or leaves the AML team, the SP must be updated. Names are matched as `FirstName + ' ' + LastName`.
- **DocumentStatus comes from BackOffice_Customer, not CustomerDocument**: The status is the customer's overall document status, not per-document status. This means all documents for a customer show the same DocumentStatus.
- **ClassificationOccured is misspelled**: The column name has a typo ("Occured" instead of "Occurred"). Use `ClassificationOccured` exactly.
- **Full rebuild daily**: TRUNCATE + INSERT. No historical tracking — if a document's status changes, only the latest state is captured.
- **PII data**: BirthDate, Gender, ClassificationComment, and Comment may contain sensitive customer information.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 — Upstream wiki verbatim | `(Tier 1 — source)` |
| ★★★☆☆ | Tier 2 — Synapse SP code | `(Tier 2 — source)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID (Real account). From Dim_Customer.RealCID via External_etoro_BackOffice_CustomerDocument.CID. JOINs to Dim_Customer. (Tier 2 — SP_AML_Documents_Dashboard) |
| 2 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 3 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 4 | FirstDepositAmount | money | YES | Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer) |
| 5 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. (Tier 1 — BackOffice.Customer) |
| 6 | IsValidCustomer | int | YES | DWH-computed: 1 when not Internal (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) |
| 7 | IsDepositor | int | YES | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. (Tier 2 — SP_Dim_Customer) |
| 8 | BirthDate | datetime | YES | Customer date of birth. Used in KYC age verification. PII field. (Tier 1 — Customer.CustomerStatic) |
| 9 | Gender | varchar(500) | YES | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only in Dim_Customer. Stored as varchar(500) here (over-sized). (Tier 1 — Customer.CustomerStatic) |
| 10 | Regulation | varchar(500) | YES | Short code for the regulation. Values match production Dictionary.Regulation.Name. Join-enriched via Dim_Customer.RegulationID → Dim_Regulation.Name. (Tier 1 — Dictionary.Regulation, join-enriched) |
| 11 | PlayerStatus | varchar(500) | YES | Human-readable restriction state label. 16 values: Normal, Blocked, Pending Verification, etc. Join-enriched via Dim_Customer.PlayerStatusID → Dim_PlayerStatus.Name. (Tier 1 — Dictionary.PlayerStatus, join-enriched) |
| 12 | Club | varchar(500) | YES | eToro Club loyalty tier. Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal. Join-enriched via Dim_Customer.PlayerLevelID → Dim_PlayerLevel.Name. (Tier 1 — Dictionary.PlayerLevel, join-enriched) |
| 13 | Country | varchar(500) | YES | Customer country of residence. Join-enriched via Dim_Customer.CountryID → Dim_Country.Name. (Tier 2 — SP_AML_Documents_Dashboard, join-enriched via Dim_Country) |
| 14 | DocumentAdded | datetime | YES | Date/time the customer uploaded the document. From External_etoro_BackOffice_CustomerDocument.DateAdded. (Tier 2 — BackOffice.CustomerDocument) |
| 15 | DocumentStatus | varchar(500) | YES | Customer's overall document verification status. 8 values: New Upload (41%), Accepted (32%), POIApproved (11%), Rejected (7%), Reviewed (7%), POAApproved (1%), None (<1%). From External_etoro_Dictionary_DocumentStatus.DocumentStatusName via BackOffice_Customer.DocumentStatusID. (Tier 2 — Dictionary.DocumentStatus, join-enriched) |
| 16 | ClassificationComment | nvarchar(4000) | YES | Free-text comment entered by the AML analyst during document classification. May contain PII (client financial details, document descriptions). From External_etoro_BackOffice_CustomerDocumentToDocumentType.Comment. (Tier 2 — BackOffice.CustomerDocumentToDocumentType) |
| 17 | DocumentType | varchar(500) | YES | Type assigned by the AML analyst. 17 values: Proof of Income (47%), Proof of Identity (16%), Proof of MOP (11%), Proof of address (10%), Not Accepted (9%), Credit Card (4%), Client Forms (2%), and 10 others. From External_etoro_Dictionary_DocumentType.Name via dt.DocumentTypeID. (Tier 2 — Dictionary.DocumentType, join-enriched) |
| 18 | RejectReason | varchar(500) | YES | Reason for document rejection. NULL when document is not rejected. From External_etoro_Dictionary_DocumentRejectReason.RejectReasonName via dt.RejectReasonID. (Tier 2 — Dictionary.DocumentRejectReason, join-enriched) |
| 19 | ClassifiedBy | varchar(500) | YES | Full name of the AML team member who classified the document. `dm.FirstName + ' ' + dm.LastName` from Dim_Manager. Filtered to 23 hardcoded names in SP. (Tier 2 — SP_AML_Documents_Dashboard, ETL-computed) |
| 20 | ClassificationOccured | datetime | YES | Date/time when the AML analyst performed the classification. From External_etoro_BackOffice_CustomerDocumentToDocumentType.Occurred. Note: column name has typo ("Occured"). (Tier 2 — BackOffice.CustomerDocumentToDocumentType) |
| 21 | SuggestedDocumentType | varchar(500) | YES | System-suggested document type before analyst review. From External_etoro_Dictionary_DocumentType.Name via CustomerDocument.SuggestedDocumentTypeID. May differ from final DocumentType. (Tier 2 — Dictionary.DocumentType, join-enriched) |
| 22 | Comment | nvarchar(4000) | YES | Upload comment from the customer document record. Distinct from ClassificationComment (which is the analyst's note). From External_etoro_BackOffice_CustomerDocument.Comment. May contain PII. (Tier 2 — BackOffice.CustomerDocument) |
| 23 | UpdateDate | datetime | YES | ETL execution timestamp — GETDATE() during SP execution. All rows share the same value (TRUNCATE-INSERT). (Tier 2 — SP_AML_Documents_Dashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Dim_Customer ← Customer.CustomerStatic | RealCID | rename |
| RegisteredReal | Dim_Customer ← Customer.CustomerStatic | Registered → RegisteredReal | passthrough |
| FirstDepositDate | Dim_Customer (ETL-computed) | FirstDepositDate | passthrough |
| FirstDepositAmount | Dim_Customer (ETL-computed) | FirstDepositAmount | passthrough |
| VerificationLevelID | Dim_Customer ← BackOffice.Customer | VerificationLevelID | passthrough |
| IsValidCustomer | Dim_Customer (ETL-computed) | IsValidCustomer | passthrough |
| IsDepositor | Dim_Customer (ETL-computed) | IsDepositor | passthrough |
| BirthDate | Dim_Customer ← Customer.CustomerStatic | BirthDate | passthrough |
| Gender | Dim_Customer ← Customer.CustomerStatic | Gender | passthrough |
| Regulation | Dim_Regulation ← Dictionary.Regulation | Name | join-enriched |
| PlayerStatus | Dim_PlayerStatus ← Dictionary.PlayerStatus | Name | join-enriched |
| Club | Dim_PlayerLevel ← Dictionary.PlayerLevel | Name | join-enriched |
| Country | Dim_Country ← Dictionary.Country | Name | join-enriched |
| DocumentAdded | BackOffice.CustomerDocument | DateAdded | rename |
| DocumentStatus | Dictionary.DocumentStatus | DocumentStatusName | join-enriched |
| ClassificationComment | BackOffice.CustomerDocumentToDocumentType | Comment | rename |
| DocumentType | Dictionary.DocumentType | Name | join-enriched |
| RejectReason | Dictionary.DocumentRejectReason | RejectReasonName | join-enriched |
| ClassifiedBy | Dim_Manager | FirstName + LastName | ETL-computed (concat) |
| ClassificationOccured | BackOffice.CustomerDocumentToDocumentType | Occurred | rename |
| SuggestedDocumentType | Dictionary.DocumentType | Name | join-enriched (2nd instance) |
| Comment | BackOffice.CustomerDocument | Comment | passthrough |
| UpdateDate | — | — | ETL-computed (GETDATE()) |

Full upstream documentation:
- [Dim_Customer](../../../DWH_dbo/Tables/Dim_Customer.md)
- [Dim_Regulation](../../../DWH_dbo/Tables/Dim_Regulation.md)
- [Dim_PlayerLevel](../../../DWH_dbo/Tables/Dim_PlayerLevel.md)
- [Dim_PlayerStatus](../../../DWH_dbo/Tables/Dim_PlayerStatus.md)

### 5.2 ETL Pipeline

```
etoro.BackOffice.CustomerDocumentToDocumentType (production)
    │
    └─ External tables in BI_DB_dbo (6 external tables, lake-read)
        │
        └─ SP_AML_Documents_Dashboard (no parameters)
            ├─ CTAS #gen: JOIN External tables + Dim_Manager (filtered to 23 AML names)
            ├─ CTAS #final: JOIN #gen + Dim_Customer + Dim_Regulation + Dim_PlayerLevel + Dim_PlayerStatus + Dim_Country
            ├─ TRUNCATE TABLE target
            └─ INSERT → BI_DB_dbo.BI_DB_AML_Documents_Dashboard (71K rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.BackOffice.CustomerDocumentToDocumentType | Document classification events |
| Source | etoro.BackOffice.CustomerDocument | Document upload metadata |
| Source | etoro.BackOffice.Customer | Customer document status |
| Lookup | etoro.Dictionary.DocumentStatus/Type/RejectReason | Classification dimension lookups |
| Enrichment | DWH_dbo.Dim_Customer + Dim_* dimensions | Customer demographics and resolved names |
| ETL | SP_AML_Documents_Dashboard | 2-step CTAS + TRUNCATE-INSERT, daily |
| Target | BI_DB_dbo.BI_DB_AML_Documents_Dashboard | 71K rows, full rebuild daily |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer demographics via RealCID |
| Regulation | DWH_dbo.Dim_Regulation | Already resolved to name; FK from Dim_Customer.RegulationID |
| Club | DWH_dbo.Dim_PlayerLevel | Already resolved to name; FK from Dim_Customer.PlayerLevelID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Already resolved to name; FK from Dim_Customer.PlayerStatusID |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in the SSDT repo. Used for AML compliance dashboards and document review analytics.

---

## 7. Sample Queries

### 7.1 Document classification summary by analyst

```sql
SELECT
    ClassifiedBy,
    COUNT(*) AS TotalClassified,
    SUM(CASE WHEN DocumentStatus = 'Accepted' THEN 1 ELSE 0 END) AS Accepted,
    SUM(CASE WHEN DocumentStatus = 'Rejected' THEN 1 ELSE 0 END) AS Rejected
FROM [BI_DB_dbo].[BI_DB_AML_Documents_Dashboard]
GROUP BY ClassifiedBy
ORDER BY TotalClassified DESC;
```

### 7.2 Average review turnaround time by document type

```sql
SELECT
    DocumentType,
    COUNT(*) AS DocCount,
    AVG(DATEDIFF(day, DocumentAdded, ClassificationOccured)) AS AvgDaysToClassify
FROM [BI_DB_dbo].[BI_DB_AML_Documents_Dashboard]
WHERE ClassificationOccured IS NOT NULL
GROUP BY DocumentType
ORDER BY AvgDaysToClassify DESC;
```

### 7.3 Rejection reasons for Proof of Income documents

```sql
SELECT
    RejectReason,
    COUNT(*) AS RejectionCount,
    Regulation
FROM [BI_DB_dbo].[BI_DB_AML_Documents_Dashboard]
WHERE DocumentStatus = 'Rejected'
  AND DocumentType = 'Proof of Income'
  AND RejectReason IS NOT NULL
GROUP BY RejectReason, Regulation
ORDER BY RejectionCount DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Requesting and defining documents for AML cases](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/12336693302/Requesting+and+defining+documents+for+AML+cases) | Confluence | AML document classification categories: Proof of Income, Proof of MOP, Proof of address with specific sub-types |
| [AML request for extra documents](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/11960811890/AML+request+for+extra+documents) | Confluence | AML workflow for requesting additional documents from customers during compliance review |
| [Know Your Customer (KYC) - system document](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/12613517351/Know+Your+Customer+KYC+-+system+document) | Confluence | KYC as a component of AML program — document verification, subsystem integration |

---

*Generated: 2026-03-28 | Quality: 9.0/10 (★★★★★) | Phases: 14/14*
*Tiers: 7 T1, 16 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 10/10*
*Object: BI_DB_dbo.BI_DB_AML_Documents_Dashboard | Type: Table | Production Source: etoro.BackOffice.CustomerDocumentToDocumentType*
