# BI_DB_dbo.BI_DB_RejectedDocuments

> Incrementally maintained history (2.12M rows, 2022-07-01 to present) of rejected KYC document submissions, sourced from BackOffice.CustomerDocument via external table — one row per rejection event with standardized reason, internal agent comment, and customer demographics. Two columns (Manager, CustomerName) are ghost columns: present in DDL but always NULL.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BackOffice.CustomerDocument (via External_BackOffice_CustomerDocument) + Dictionary.DocumentRejectReason + DWH_dbo dimensions |
| **Refresh** | Daily — SP_RejectedDocuments @Date; DELETE WHERE RejectionDate=@Date then INSERT (incrementally accumulating since 2022-07-01) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_RejectedDocuments` is an accumulating log of every KYC document rejection event on the eToro platform since 2022-07-01. Each row captures one document rejection — a case where a customer submitted a document (Proof of Identity or Proof of Address) that a verification agent rejected, along with the standardized reason and optional free-text comment.

The table is refreshed via daily incremental upsert: the day's rejections are deleted and re-inserted (allowing corrections to propagate). Historical rejections (before @Date) are retained indefinitely. There is no purge mechanism.

As of 2026-04-13: 2,122,132 rejection events. **POA (Proof of Address) issues dominate** at 52% of rejections: "POA - Proof of address cannot be accepted" (27.7%), "POA - Missing address details" (11.5%), "POA - Older than 3 months" (11.4%). Duplicate submissions account for 10.6%. POI (Proof of Identity) issues comprise ~20% of rejections.

**CRITICAL — Two ghost columns**: `Manager` and `CustomerName` appear in the DDL but are never populated by the SP. Both are always NULL in live data. Do not reference them for analysis. See §2.4.

**CRITICAL — Column name with space**: Column 6 is named `[Classification comment]` with a literal space. Must always be referenced with square brackets in SQL: `[[Classification comment]]`.

---

## 2. Business Logic

### 2.1 Daily Incremental Pattern (DELETE + INSERT by RejectionDate)

**What**: The SP processes one day at a time, replacing that day's data with a fresh load from the source.
**Columns Involved**: RejectionDate, all columns
**Rules**:
- `DELETE FROM BI_DB_RejectedDocuments WHERE RejectionDate = @Date` — removes any prior data for that day
- `INSERT ... WHERE RejectionDate = @Date` — reloads from BackOffice.CustomerDocument
- Historical days (before @Date) are not touched — they accumulate indefinitely
- This pattern allows late-arriving corrections (a rejection entered in BackOffice after the original SP run will be picked up if the SP is re-run for that date, but corrections in prior days require manual rerun)

### 2.2 External Table Refresh First

**What**: Before the main INSERT, the SP calls a helper SP to refresh the external table source.
**Columns Involved**: All
**Rules**:
- `EXEC SP_Create_External_etoro_backoffice_customerdocument` is called at the start of SP_RejectedDocuments
- This external table refresh pulls the latest BackOffice.CustomerDocument data from the lake
- If this helper SP fails, the main SP will use stale external table data

### 2.3 FirstDepositDate from Fact_BillingDeposit

**What**: The FTD date is not taken from Dim_Customer.FirstDepositDate but from a LEFT JOIN to Fact_BillingDeposit.
**Columns Involved**: FirstDepositDate
**Rules**:
- `LEFT JOIN DWH_dbo.Fact_BillingDeposit ON CID = CID` — retrieves the minimum billing date as FTD date
- `MIN(BillingDate) per CID` — captures the true first billing event
- Non-depositors: NULL (not the sentinel '1900-01-01' used in other BI_DB tables)
- Note: using Fact_BillingDeposit directly may give slightly different FTD dates than Dim_Customer.FirstDepositDate for edge cases

### 2.4 Ghost Columns: Manager and CustomerName

**What**: Two columns exist in the DDL but are never populated.
**Columns Involved**: `Manager`, `CustomerName`
**Rules**:
- `Manager` — Dim_Manager is LEFT JOINed in the SP query (presumably to get the account manager name) but is NOT listed in the INSERT column list. The column receives no value and is always NULL.
- `CustomerName` — Similarly, customer name is not included in the INSERT. Always NULL.
- Live data confirms: all Manager = NULL, all CustomerName = NULL (verified in Phase 2 sampling)
- These columns cannot be removed from the DDL without an ALTER TABLE — they are legacy/abandoned schema additions

### 2.5 Rejection Reason Taxonomy

**What**: Rejections follow a standardized taxonomy of reason strings.
**Columns Involved**: `RejectionReason`
**Rules**:
- Prefix indicates document type: 'POA -' = Proof of Address, 'POI -' = Proof of Identity, 'POI+POA -' = both
- Top reasons by volume:
  - 'POA - Proof of address cannot be accepted' (27.7%)
  - 'POA - Missing address details' (11.5%)
  - 'POA - Older than 3 months' (11.4%)
  - 'Duplicate' (10.6%) — document already submitted/processed
  - 'POI - Cannot be accepted' (5.0%)
  - 'Other' (4.9%) — catch-all
- Sourced from Dictionary.DocumentRejectReason → standardized, not free-text

---

## 3. Query Advisory

### 3.1 Distribution & Index

ROUND_ROBIN HEAP. No distribution optimization. At 2.1M rows, point-lookups without index will do full scans. For CID-based lookups in interactive analysis, consider temp tables. Date-bounded queries using RejectionDate are the most efficient access pattern.

### 3.2 Classification Comment Quoting

Column 6 has a space in its name: `[Classification comment]`. In Synapse SQL, reference it as:
```sql
SELECT [[Classification comment]] FROM [BI_DB_dbo].[BI_DB_RejectedDocuments]
```
Note the double square brackets — the outer pair is the column delimiter, the inner pair is the literal column name. This is a non-standard column name.

### 3.3 Ghost Columns — Never Reference for Analysis

`Manager` and `CustomerName` are always NULL. Do not use them in reports, aggregations, or joins. They exist as legacy DDL artifacts. If account manager information is needed, join to Dim_Manager via Dim_Customer.AccountManagerID.

### 3.4 FirstDepositDate Nulls vs. Sentinel

Unlike other BI_DB tables that use '1900-01-01' as a sentinel for non-depositors, this table uses NULL for customers with no deposit. Filter with `WHERE FirstDepositDate IS NOT NULL` to restrict to depositors.

### 3.5 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Rejection trend by month | `GROUP BY YEAR(RejectionDate)*100+MONTH(RejectionDate), RejectionReason ORDER BY 1` |
| Top rejection reasons | `GROUP BY RejectionReason ORDER BY COUNT(*) DESC` |
| Rejection volume by country | `GROUP BY Country ORDER BY COUNT(*) DESC` |
| Agent internal notes for a rejection | `SELECT [[Classification comment]] WHERE DocumentID = X` |
| Customers with multiple rejections | `GROUP BY CID HAVING COUNT(*) > 1 ORDER BY COUNT(*) DESC` |
| POI vs. POA split | `GROUP BY CASE WHEN RejectionReason LIKE 'POA%' THEN 'POA' WHEN RejectionReason LIKE 'POI%' THEN 'POI' ELSE 'Other' END` |

---

## 4. Elements

| # | Column | Type | Nullable | Confidence | Tier | Description |
|---|--------|------|----------|------------|------|-------------|
| 1 | CID | int | YES | CODE-BACKED | T1 | eToro customer ID. One customer can have multiple rejection rows (one per rejection event). |
| 2 | DocumentID | int | YES | CODE-BACKED | T2 | Unique document submission ID from BackOffice.CustomerDocument. Primary join key to source. |
| 3 | UploadDate | date | YES | CODE-BACKED | T2 | Date the customer uploaded/submitted the document. May predate RejectionDate by days. |
| 4 | RejectionDate | datetime | YES | CODE-BACKED | T2 | Date and time the document was rejected by a verification agent. Partition key for incremental upsert. |
| 5 | RejectionReason | varchar(100) | YES | CODE-BACKED | T2 | Standardized rejection reason from Dictionary.DocumentRejectReason. Prefix 'POA -' = Proof of Address, 'POI -' = Proof of Identity. Top value: 'POA - Proof of address cannot be accepted' (27.7%). |
| 6 | [Classification comment] | varchar(2000) | YES | CODE-BACKED | T2 | Free-text internal agent note attached to the rejection. Contains unstructured detail beyond the reason code (e.g., specific issues noted by verifier). Column name contains a SPACE — must use square brackets in SQL: [[Classification comment]]. |
| 7 | Manager | nvarchar(100) | YES | GHOST COLUMN | T4 | ALWAYS NULL — ghost column. Dim_Manager is LEFT JOINed in the SP but Manager is not in the INSERT column list. Do not use. |
| 8 | VerificationLevelID | int | YES | CODE-BACKED | T1 | KYC verification tier ID at the time of the SP run (not necessarily at time of rejection). From Dim_Customer. |
| 9 | Country | varchar(100) | YES | CODE-BACKED | T1 | Customer country name from Dim_Country. |
| 10 | Region | varchar(100) | YES | CODE-BACKED | T1 | Marketing region label from Dim_Country. |
| 11 | FirstDepositDate | datetime | YES | CODE-BACKED | T2 | First Time Deposit date from Fact_BillingDeposit (MIN billing date per CID). NULL for non-depositors (no '1900-01-01' sentinel here). |
| 12 | PlayerStatus | varchar(100) | YES | CODE-BACKED | T1 | Customer account status from Dim_PlayerStatus (current status at run time, not at rejection time). |
| 13 | Language | varchar(100) | YES | CODE-BACKED | T1 | Customer language from Dim_Language (preferred/interface language). |
| 14 | CustomerName | nvarchar(100) | YES | GHOST COLUMN | T4 | ALWAYS NULL — ghost column. Not in the INSERT column list. Do not use. |
| 15 | UpdateDate | datetime | YES | CODE-BACKED | T2 | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 5. Lineage

See `BI_DB_RejectedDocuments.lineage.md` for full source chain.

### ETL Pipeline Summary

```
BackOffice.CustomerDocument + DocumentToDocumentType + Dictionary.DocumentRejectReason
  └── SP_Create_External_etoro_backoffice_customerdocument (external table refresh, called first)
        └── External_BackOffice_CustomerDocument (lake bridge)

DWH_dbo.Dim_Customer + Dim_Country + Dim_PlayerStatus + Dim_Language → demographics
DWH_dbo.Fact_BillingDeposit → FirstDepositDate (LEFT JOIN, MIN billing date)
DWH_dbo.Dim_Manager → LEFT JOIN (NOT used in INSERT — Manager ghost column)

  └── SP_RejectedDocuments (@Date) — DELETE @Date + INSERT @Date (incremental)
        v
BI_DB_dbo.BI_DB_RejectedDocuments (2.12M rows, 2022-07-01→2026-04-13, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### Produced By
| SP | Schedule | Priority | Pattern |
|----|----------|----------|---------|
| SP_RejectedDocuments | Daily | P20 (third wave) | DELETE WHERE RejectionDate=@Date + INSERT (incremental, accumulating since 2022-07-01) |

### External Dependency
- `SP_Create_External_etoro_backoffice_customerdocument` — called at SP start to refresh external table before main data load

---

## 7. Tier Legend

| Tier | Meaning |
|------|---------|
| T1 | Verbatim from upstream wiki (DWH_dbo Dim* docs) |
| T2 | ETL-computed — traced to SP code |
| T4 | Ghost column — confirmed NULL in live data, not populated by SP |

---

*Documented 2026-04-22 — Batch 33 | SP: SP_RejectedDocuments | Quality target: 8.5+*
