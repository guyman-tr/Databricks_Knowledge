# DWH_dbo.Dim_DocumentStatus

> Small dictionary (7 rows) mapping integer IDs to KYC document review status names in the eToro identity verification pipeline.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.DocumentStatus |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full TRUNCATE+INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DocumentStatusID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_DocumentStatus` is a 7-row reference dictionary for KYC (Know Your Customer) document review states in the eToro identity verification pipeline. It classifies the review lifecycle of customer-uploaded identity documents: from initial upload (New Upload) through manual review (Reviewed) to final decision (Accepted/Rejected) and specific document-type approvals (POIApproved = Proof of Identity, POAApproved = Proof of Address).

The source is `etoro.Dictionary.DocumentStatus`. Both columns are passthroughs from the staging table; only UpdateDate is ETL-computed. The ETL is a full TRUNCATE-and-INSERT daily reload.

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentStatus.md`.

---

## 2. Business Logic

### 2.1 KYC Document Review States

**What**: Seven states track the full review lifecycle of a customer's identity verification documents.

**Columns Involved**: `DocumentStatusID`, `DocumentStatusName`

**Rules**:
- ID=0 (None): No document uploaded or status not applicable
- ID=1 (New Upload): Document just uploaded by customer - awaiting review
- ID=2 (Reviewed): Document has been reviewed but no final decision yet
- ID=3 (Accepted): Document accepted as valid
- ID=4 (Rejected): Document rejected (invalid, expired, wrong type)
- ID=5 (POIApproved): Proof of Identity document specifically approved (passport, national ID, driver's license)
- ID=6 (POAApproved): Proof of Address document specifically approved (utility bill, bank statement)

**Diagram**:
```
Customer uploads document
  -> ID=1 (New Upload)
  -> ID=2 (Reviewed)         [optionally, after manual review begins]
  -> ID=3 (Accepted)         [generic approval]
     OR ID=4 (Rejected)      [failed verification]
     OR ID=5 (POIApproved)   [identity document specifically approved]
     OR ID=6 (POAApproved)   [address document specifically approved]
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE is correct for 7 rows. CLUSTERED INDEX on DocumentStatusID is appropriate for point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (7 rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode document status in KYC facts | `JOIN DWH_dbo.Dim_DocumentStatus d ON f.DocumentStatusID = d.DocumentStatusID` |
| Filter verified documents | `WHERE DocumentStatusID IN (3, 5, 6)` (Accepted, POI, POA approved) |
| Count rejected documents | `WHERE DocumentStatusID = 4` |

### 3.3 Gotchas

- ID=0 (None) is a real row (not a typical NULL placeholder name). Filter with `WHERE DocumentStatusID > 0` for documents that have an actual status.
- POIApproved (ID=5) and POAApproved (ID=6) are SEPARATE from Accepted (ID=3). A document may be POI-approved without being generically Accepted. Check both when filtering for "approved documents".

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DocumentStatusID | int | NO | Primary key identifying the document review state. 1=Uploaded, 2=PendingReview, 3=Approved, 4=Declined, 5=Expired. (Tier 1 — Dictionary.DocumentStatus) |
| 2 | DocumentStatusName | varchar(50) | NO | Human-readable status label. Used in compliance review UI, customer communications, and regulatory reporting. (Tier 1 — Dictionary.DocumentStatus) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each daily full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DocumentStatusID | etoro.Dictionary.DocumentStatus | DocumentStatusID | passthrough |
| DocumentStatusName | etoro.Dictionary.DocumentStatus | DocumentStatusName | passthrough |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

Upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentStatus.md`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.DocumentStatus
  -> [Generic Pipeline]
  -> DWH_staging.etoro_Dictionary_DocumentStatus (HEAP, ROUND_ROBIN)
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, GETDATE() for UpdateDate)
  -> DWH_dbo.Dim_DocumentStatus (7 rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.DocumentStatus | 7-row KYC document status lookup in production etoro database. |
| Staging | DWH_staging.etoro_Dictionary_DocumentStatus | Raw staging. Same 2-column structure. |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Both columns passthrough. Injects GETDATE() for UpdateDate. |
| Target | DWH_dbo.Dim_DocumentStatus | Final DWH dimension (7 rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| - | - | No outbound foreign key references. Self-contained lookup. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| KYC/compliance fact tables | DocumentStatusID | Document review fact tables reference this table to decode document review state. [UNVERIFIED - no SP grep match; inferred from naming convention] |

---

## 7. Sample Queries

### 7.1 List all document statuses
```sql
SELECT DocumentStatusID, DocumentStatusName, UpdateDate
FROM [DWH_dbo].[Dim_DocumentStatus]
ORDER BY DocumentStatusID;
```

### 7.2 Accepted documents in KYC fact
```sql
SELECT f.*, d.DocumentStatusName
FROM [DWH_dbo].[Fact_KYC_Documents] f
JOIN [DWH_dbo].[Dim_DocumentStatus] d ON f.DocumentStatusID = d.DocumentStatusID
WHERE d.DocumentStatusID IN (3, 5, 6);
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [Verification Document Acceptance Criteria](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/11649744991/Verification+Document+Acceptance+Criteria) | Confluence | EU_KYC guidelines and POA/POI acceptance rules—regulatory framing for document verification states and review outcomes. |
| [KYC Verification Procedures](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/897876000/KYC+Verification+Procedures) | Confluence | Operational procedures for KYC verification (incl. defining other documents and risk handling)—how document checks tie to customer status. |
| [Electronic Verification (EV) Process in eToro](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/11649712268/Electronic+Verification+EV+Process+in+eToro) | Confluence | EV levels and deposit limits before documents are submitted/verified—context for “pending review” vs “verified” style statuses. |

Upstream production wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DocumentStatus.md`.

---

*Generated: 2026-03-19 | Quality: 7.0/10 (3 stars) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 3/10, Sources: 8/10*
*Object: DWH_dbo.Dim_DocumentStatus | Type: Table | Production Source: etoro.Dictionary.DocumentStatus*
