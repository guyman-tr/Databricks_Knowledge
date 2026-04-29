# BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments

> 21,119-row daily log of professional customer application document submissions (SuggestedDocumentTypeID=21) from November 2021 to present, tracking 15,381 distinct customers with their MiFID categorization status, club tier, regulation, and account manager -- sourced from External_etoro_BackOffice_CustomerDocument joined to Fact_SnapshotCustomer dimension lookups via SP_ProfessionalCustomersDocuments.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_etoro_BackOffice_CustomerDocument (BackOffice.CustomerDocument, SuggestedDocumentTypeID=21) + DWH_dbo.Fact_SnapshotCustomer + 4 dim lookups via SP_ProfessionalCustomersDocuments |
| **Refresh** | Daily (DELETE+INSERT by DateID) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_ProfessionalCustomersDocuments` tracks document submissions for MiFID II professional customer applications. Each row represents a single document (DocumentID) submitted by a customer (CID) on a specific date, enriched with the customer's current snapshot state: MiFID categorization (ProfessionalStatus), eToro Club tier (ClubTier), regulatory entity (Regulation), and assigned account manager (AM).

The ETL runs daily via `SP_ProfessionalCustomersDocuments`. For each run date (@Date):
1. Selects documents from `External_etoro_BackOffice_CustomerDocument` where SuggestedDocumentTypeID = 21 (professional customer application) and DateAdded = @Date
2. JOINs to `Fact_SnapshotCustomer` to get the customer's current-state row (via DateRangeID filtering), then resolves 4 dimension lookups: Dim_Manager (AM name), Dim_PlayerLevel (ClubTier), Dim_MifidCategorization (ProfessionalStatus), Dim_Regulation (Regulation)

21,119 rows covering 15,381 distinct customers. ProfessionalStatus distribution: Retail 77%, Retail Pending 16%, Pending 6%, Elective Professional 1%, Professional <1%. This shows most document submitters are Retail or Retail Pending -- they are applying for Professional status, not yet approved.

Regulation breakdown: BVI 49%, CySEC 24%, FCA 13%, ASIC & GAML 5%, FSA Seychelles 4%, FinCEN+FINRA 2%.

---

## 2. Business Logic

### 2.1 Document Type Filter (SuggestedDocumentTypeID = 21)

**What**: The SP filters BackOffice.CustomerDocument to only capture documents specifically related to professional customer applications.

**Columns Involved**: `DocumentID`

**Rules**:
- SuggestedDocumentTypeID = 21 is the document type for professional customer application submissions
- Only documents added on the exact @Date are captured (DateAdded >= @Date AND < @Date+1 day)
- Each document gets its own row, so a customer submitting 2 documents on the same day generates 2 rows

### 2.2 Current-State Snapshot Join

**What**: The SP joins to Fact_SnapshotCustomer's current row to capture the customer's state AT the time of document submission, not their eventual state.

**Columns Involved**: `CID`, `AccountManagerID`, `ClubTier`, `ProfessionalStatus`, `Regulation`

**Rules**:
- DateRangeID is filtered via Dim_Range: FromDateID <= @DateID AND ToDateID >= @DateID
- This means ClubTier, ProfessionalStatus, and Regulation reflect the customer's status on the submission date
- A customer's ProfessionalStatus = 'Retail' at submission time means they were still Retail when they submitted the application

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **HASH(CID)** distribution -- efficient for JOINs on CID to other customer-level tables
- **Clustered Index on Date** -- filter by Date for efficient daily lookups

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily document submission volume | `SELECT Date, COUNT(*) FROM ... GROUP BY Date` |
| Documents by regulation | `GROUP BY Regulation` |
| Customers who submitted but are still Retail | `WHERE ProfessionalStatus = 'Retail'` |
| Document-to-approval conversion | JOIN to BI_DB_ProfessionalCustomers on CID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer demographics |
| BI_DB_dbo.BI_DB_ProfessionalCustomers | CID = RealCID | Track if applicant was approved |
| BI_DB_dbo.BI_DB_ProfessionalCustomersPending | CID = RealCID | Cross-reference with pending applications |

### 3.4 Gotchas

- **CID, not RealCID**: This table uses `CID` as the column name (aliased from Fact_SnapshotCustomer.RealCID). It IS the RealCID value.
- **ProfessionalStatus reflects submission-time state**: Most submitters show 'Retail' because they haven't been approved yet when they submit documents.
- **DocumentID is the grain**: One row per document, not per customer. A customer can have multiple documents on the same date.
- **No document content**: The table tracks document IDs only, not the document type details or content.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Submission date of the professional customer application document. Passthrough of the SP @Date input parameter. (Tier 2 — SP_ProfessionalCustomersDocuments) |
| 2 | DateID | int | YES | Integer representation of Date in YYYYMMDD format. Used for daily DELETE+INSERT partitioning. (Tier 2 — SP_ProfessionalCustomersDocuments) |
| 3 | DocumentID | int | NO | BackOffice document identifier for the professional customer application submission. Filtered to SuggestedDocumentTypeID=21 only. Source: External_etoro_BackOffice_CustomerDocument. (Tier 2 — SP_ProfessionalCustomersDocuments) |
| 4 | CID | int | YES | Customer ID (aliased from Fact_SnapshotCustomer.RealCID). Platform-internal primary key assigned at registration. (Tier 1 — Customer.CustomerStatic) |
| 5 | AccountManagerID | int | YES | FK to Dim_Manager.ManagerID. The account manager assigned to this customer at document submission time. Source: Fact_SnapshotCustomer.AccountManagerID passthrough. (Tier 2 — SP_ProfessionalCustomersDocuments) |
| 6 | AM | varchar(101) | NO | Account manager full name (FirstName + ' ' + LastName from Dim_Manager). Derived concatenation, not a passthrough. (Tier 2 — SP_ProfessionalCustomersDocuments) |
| 7 | ClubTier | varchar(50) | NO | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID. (Tier 1 — Dictionary.PlayerLevel) |
| 8 | ProfessionalStatus | varchar(50) | NO | MiFID II client categorization name. 0=None, 1=Retail, 2=Professional, 3=Elective professional, 4=Retail Pending, 5=Pending. Passthrough from Dim_MifidCategorization.Name via Fact_SnapshotCustomer.MifidCategorizationID. (Tier 2 — SP_ProfessionalCustomersDocuments, Dim_MifidCategorization) |
| 9 | Regulation | varchar(50) | YES | Regulatory entity name governing this customer: CySEC, FCA, BVI, ASIC & GAML, FSA Seychelles, FinCEN+FINRA, FSRA, eToroUS, MAS. Passthrough from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. (Tier 2 — SP_ProfessionalCustomersDocuments, Dim_Regulation) |
| 10 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline (GETDATE()). (Tier 2 — SP_ProfessionalCustomersDocuments) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | ETL | @Date | SP input parameter |
| DateID | ETL | @DateID | CAST(CONVERT(CHAR(8),@Date,112) AS INT) |
| DocumentID | BackOffice.CustomerDocument | DocumentID | Passthrough (SuggestedDocumentTypeID=21 filter) |
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Alias rename |
| AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | Passthrough |
| AM | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation |
| ClubTier | DWH_dbo.Dim_PlayerLevel | Name | Dim lookup passthrough |
| ProfessionalStatus | DWH_dbo.Dim_MifidCategorization | Name | Dim lookup passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim lookup passthrough |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
etoro.BackOffice.CustomerDocument (production)
  |-- Generic Pipeline (Bronze export)
  v
BI_DB_dbo.External_etoro_BackOffice_CustomerDocument (SuggestedDocumentTypeID=21, DateAdded=@Date)
  |-- JOIN Fact_SnapshotCustomer fsc ON fsc.RealCID = doc.CID (current state row)
  |-- JOIN Dim_Range dr1 ON fsc.DateRangeID (FromDateID<=@DateID AND ToDateID>=@DateID)
  |-- JOIN Dim_Manager dm1 ON fsc.AccountManagerID = dm1.ManagerID
  |-- JOIN Dim_PlayerLevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
  |-- JOIN Dim_MifidCategorization mif ON fsc.MifidCategorizationID
  |-- JOIN Dim_Regulation dr ON fsc.RegulationID = dr.ID
  v
SP_ProfessionalCustomersDocuments @Date (daily DELETE+INSERT)
  v
BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments (21,119 rows, HASH(CID))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension via RealCID |
| AccountManagerID | DWH_dbo.Dim_Manager | Account manager dimension |
| ClubTier | DWH_dbo.Dim_PlayerLevel | Club tier lookup (Name) |
| ProfessionalStatus | DWH_dbo.Dim_MifidCategorization | MiFID categorization lookup (Name) |
| Regulation | DWH_dbo.Dim_Regulation | Regulation entity lookup (Name) |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Daily Document Submission Trend

```sql
SELECT Date, COUNT(*) AS docs_submitted, COUNT(DISTINCT CID) AS unique_applicants
FROM BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments
GROUP BY Date
ORDER BY Date DESC
```

### 7.2 Submission-to-Approval Conversion Rate

```sql
SELECT d.Regulation,
       COUNT(DISTINCT d.CID) AS applicants,
       COUNT(DISTINCT p.RealCID) AS approved,
       CAST(COUNT(DISTINCT p.RealCID) AS FLOAT) / NULLIF(COUNT(DISTINCT d.CID), 0) AS conversion_rate
FROM BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments d
LEFT JOIN BI_DB_dbo.BI_DB_ProfessionalCustomers p
  ON d.CID = p.RealCID
GROUP BY d.Regulation
ORDER BY applicants DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 8 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 7/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments | Type: Table | Production Source: External_etoro_BackOffice_CustomerDocument via SP_ProfessionalCustomersDocuments*
