# DWH_dbo.Dim_ScreeningStatus

> Lookup table defining the 8 AML/compliance screening outcomes for customer identity checks against sanctions lists, PEP registries, and risk databases (e.g., World-Check). Source is the ScreeningService microservice, not the core etoro Dictionary.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | ScreeningService.Dictionary.ScreeningStatus (ScreeningServiceDB) |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ScreeningStatusID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_ScreeningStatus defines the 8 possible outcomes of a customer identity screening check against AML (Anti-Money Laundering) and compliance databases - including sanctions lists, PEP (Politically Exposed Person) registries, and adverse media risk databases. (Tier 3 - live data inferred from values; no upstream wiki found)

When a customer is onboarded or reviewed, their identity is screened by the ScreeningService (a dedicated compliance microservice, separate from the core etoro platform). The result is stored as a ScreeningStatusID on the customer record. Statuses range from clean (NoMatch=1, no risk identified) through various alert levels (PEP=3, RiskMatch=4, SanctionsMatch=7) to process states (PendingInvestigation=2, Technical=5, MultipleMatch=6).

Notably, this table's source is `ScreeningService.Dictionary.ScreeningStatus` from `ScreeningServiceDB` - not the standard etoro Dictionary database used by most Dim_ tables. The staging table is `DWH_staging.ScreeningService_Dictionary_ScreeningStatus` (naming pattern differs from `etoro_Dictionary_*`). No DWH-specific alias columns (DWHxxx, StatusID) are added by the ETL - this is the simplest ETL transformation pattern in the SP_Dictionaries SP.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.ScreeningService_Dictionary_ScreeningStatus. Source column `ID` is renamed to `ScreeningStatusID` in DWH.

---

## 2. Business Logic

### 2.1 Screening Outcome Classification

**What**: The 8 statuses represent distinct outcomes of the AML/compliance screening workflow.

**Columns Involved**: `ScreeningStatusID`, `Name`

**Status Meanings** (Tier 3 - inferred from names and compliance domain knowledge):
- 0 = Unknown: Default/no screening result available yet
- 1 = NoMatch: Clean result - no match found on any screening list
- 2 = PendingInvestigation: Match found, under compliance review
- 3 = PEP: Politically Exposed Person detected - requires enhanced due diligence
- 4 = RiskMatch: General risk match found on screening database
- 5 = Technical: Technical/processing error during screening
- 6 = MultipleMatch: Multiple potential matches found - requires manual disambiguation
- 7 = SanctionsMatch: Match against official sanctions list - most severe, typically blocks account

**Alert Severity** (inferred):
```
Clean:     NoMatch (1)
Process:   PendingInvestigation (2), MultipleMatch (6), Technical (5)
Alert:     PEP (3), RiskMatch (4)
Critical:  SanctionsMatch (7)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on ScreeningStatusID. With 8 rows, REPLICATE is optimal.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus` is Parquet. Bronze source at `bi_db.bronze_screeningservice_dictionary_screeningstatus` is also available.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve ScreeningStatusID to label | `LEFT JOIN DWH_dbo.Dim_ScreeningStatus ss ON ss.ScreeningStatusID = fact.ScreeningStatusID` |
| Flagged customers (non-clean) | `WHERE ss.ScreeningStatusID NOT IN (0, 1, 5)` |
| Critical matches (sanctions) | `WHERE ss.ScreeningStatusID = 7` |
| PEP customers | `WHERE ss.ScreeningStatusID = 3` |

### 3.3 Gotchas

- **Different source system**: Unlike all other Dim_ tables from SP_Dictionaries (which read etoro.Dictionary.*), this table reads from ScreeningServiceDB. The staging table is `ScreeningService_Dictionary_ScreeningStatus` (not `etoro_Dictionary_*`).
- **ID -> ScreeningStatusID rename**: The production source column is `ID`, renamed to `ScreeningStatusID` in the DWH. No other ETL transformations (no DWHxxx alias, no StatusID).
- **No upstream wiki**: No Dictionary.ScreeningStatus.md exists in DB_Schema/etoro/Wiki. Descriptions are Tier 3 (inferred from names).
- **SanctionsMatch severity**: This is the most compliance-critical status. Customers with ScreeningStatusID=7 are likely blocked from trading and subject to mandatory reporting.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data / name inference | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ScreeningStatusID | int | NO | Primary key for screening outcome. Renamed from production `ID` column by ETL. 0=Unknown, 1=NoMatch, 2=PendingInvestigation, 3=PEP, 4=RiskMatch, 5=Technical, 6=MultipleMatch, 7=SanctionsMatch. (Tier 2 - SP code rename from ID; Tier 3 - live data values) |
| 2 | Name | varchar(255) | NO | Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. (Tier 3 - live data) |
| 3 | UpdateDate | datetime | NO | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ScreeningStatusID | ScreeningService.Dictionary.ScreeningStatus | ID | rename |
| Name | ScreeningService.Dictionary.ScreeningStatus | Name | passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() |

No upstream wiki found. Production source is ScreeningServiceDB (separate from etoro main database).

### 5.2 ETL Pipeline

```
ScreeningService.Dictionary.ScreeningStatus (ScreeningServiceDB)
  -> Generic Pipeline (daily, Override)
  -> Bronze/ScreeningService/Dictionary/ScreeningStatus/
  -> bi_db.bronze_screeningservice_dictionary_screeningstatus (UC Bronze)
  -> DWH_staging.ScreeningService_Dictionary_ScreeningStatus
  -> SP_Dictionaries_DL_To_Synapse
  -> DWH_dbo.Dim_ScreeningStatus
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | ScreeningService.Dictionary.ScreeningStatus | 8 rows (IDs 0-7). AML compliance microservice DB. |
| Bronze UC | bi_db.bronze_screeningservice_dictionary_screeningstatus | Raw Bronze copy |
| Staging | DWH_staging.ScreeningService_Dictionary_ScreeningStatus | DWH staging (naming: ScreeningService_* not etoro_*) |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames ID -> ScreeningStatusID. Adds UpdateDate. No DWHxxx alias or StatusID. |
| Target | DWH_dbo.Dim_ScreeningStatus | 8 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - no foreign key columns.

### 6.2 Referenced By (other objects point to this)

No DWH_dbo views or procedures reference this table in the SSDT repo. Customer fact tables carrying ScreeningStatusID can join for label resolution.

---

## 7. Sample Queries

### 7.1 List all screening statuses
```sql
SELECT
    ScreeningStatusID,
    Name
FROM [DWH_dbo].[Dim_ScreeningStatus]
ORDER BY ScreeningStatusID
```

### 7.2 Customer count by screening outcome
```sql
SELECT
    ss.Name AS ScreeningOutcome,
    COUNT(DISTINCT cs.CustomerID) AS customer_count
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_ScreeningStatus] ss
    ON ss.ScreeningStatusID = cs.ScreeningStatusID
GROUP BY ss.Name
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 7.5/10 (★★★☆☆) | Phases: 7/14 (fast-path)*
*Tiers: 0 T1, 1 T2, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 4/10, Sources: 7/10*
*Note: Quality limited by no upstream wiki - no Dictionary.ScreeningStatus.md in DB_Schema. Values inferred from names.*
*Object: DWH_dbo.Dim_ScreeningStatus | Type: Table | Production Source: ScreeningService.Dictionary.ScreeningStatus*
