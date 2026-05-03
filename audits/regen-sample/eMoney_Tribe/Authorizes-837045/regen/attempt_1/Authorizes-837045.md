# eMoney_Tribe.Authorizes-837045

> 3.77M-row raw Tribe data lake landing table storing XML ingestion header records for eToro Money card authorization events, spanning 2021-09-05 to present. Serves as the parent/header table joined via `@Id` to child tables (Authorizes_Authorize-312243, Authorizes_RiskActions-796100, Authorizes_SecurityChecks-30662) in SP_eMoney_Reconciliation_ETLs to populate ETL_Authorize. Actively refreshed daily via Generic Pipeline.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | Tribe Data Lake (XML files) → Generic Pipeline → Synapse |
| **Refresh** | Daily incremental via Generic Pipeline; consumed by SP_eMoney_Reconciliation_ETLs |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP + NCI on `@Id`, `partition_date`, `@Created` |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table is a **raw data lake landing table** within the eMoney Tribe schema. It stores header-level metadata for XML files containing card authorization events exported from the Tribe payment card processing platform.

Each row represents one ingested XML file (or sub-file) identified by a UUID (`@Id`) and tagged with a creation timestamp (`@Created`) and the source file path (`@FileName`). The table itself holds no business transaction data — it acts as a **parent/header record** that links to child tables containing the actual authorization details:

- **Authorizes_Authorize-312243** — detailed authorization transaction fields (amounts, merchant, response codes)
- **Authorizes_RiskActions-796100** — risk-related flags (suspicious marking, card status changes)
- **Authorizes_SecurityChecks-30662** — security verification fields (PIN, CVV2, 3DS, chip data)

The SP `SP_eMoney_Reconciliation_ETLs` (Reconciliation Table 03) joins this table with its children on `@Id` and inserts the denormalized result into `eMoney_dbo.ETL_Authorize`, using `@Created` as the incremental watermark.

The table contains 3,772,924 rows spanning 2021-09-05 to 2026-04-26. The `etr_y`/`etr_ym`/`etr_ymd` columns are Generic Pipeline temporal partition markers and are 99.8% NULL.

---

## 2. Business Logic

### 2.1 Parent-Child XML Structure

**What**: Each row is a parent header record for a set of authorization XML sub-files. The `@Id` UUID links this header to child records across three sibling tables.
**Columns Involved**: `@Id`, `@Created`, `@FileName`
**Rules**:
- `@Id` is a UUID (varchar(40)) that uniquely identifies each ingested XML record
- Child tables join on `@Id` to form the complete authorization event
- `@FileName` encodes the source XML path including date and sub-file number (e.g., `authorizes-11-15967860899208-10079563-20230711-SubFile-957.xml`)

### 2.2 Incremental Load Pattern

**What**: SP_eMoney_Reconciliation_ETLs uses `@Created` as an incremental watermark to process only new records.
**Columns Involved**: `@Created`
**Rules**:
- The SP reads `MAX(Created)` from the target `ETL_Authorize` table to determine the load boundary
- Only rows with `@Created >= @Authorize_DATE` are processed
- The target `ETL_Authorize` is delete-and-reinsert from the watermark date forward

### 2.3 Partition Markers (Mostly Unused)

**What**: The `etr_y`, `etr_ym`, `etr_ymd` columns are Generic Pipeline temporal partition markers.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- These columns are 99.8% NULL across the dataset
- They appear to be optional partition metadata from the data lake export layer
- `partition_date` is the actual date-level partition key used for indexing

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution — full copy on every compute node; efficient for JOINs with any distribution
- **HEAP** storage (no clustered index) — no inherent row ordering
- Three NCIs: on `@Id` (primary JOIN key), `partition_date` (date filtering), `@Created` (incremental load filtering)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many authorization files were ingested on a given date? | `SELECT COUNT(*) FROM [eMoney_Tribe].[Authorizes-837045] WHERE partition_date = '2026-04-01'` |
| Get all authorization headers for a specific @Id | `SELECT * FROM [eMoney_Tribe].[Authorizes-837045] WHERE [@Id] = '<uuid>'` |
| Check ingestion freshness | `SELECT MAX(partition_date), MAX(SynapseUpdateDate) FROM [eMoney_Tribe].[Authorizes-837045]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.Authorizes_Authorize-312243 | `ON a.[@Id] = b.[@Id]` | Get detailed authorization transaction data |
| eMoney_Tribe.Authorizes_RiskActions-796100 | `ON a.[@Id] = c.[@Id]` | Get risk action flags |
| eMoney_Tribe.Authorizes_SecurityChecks-30662 | `ON a.[@Id] = d.[@Id]` | Get security verification details |

### 3.4 Gotchas

- **Do not query this table alone for business insights** — it contains only header metadata. JOIN to `Authorizes_Authorize-312243` for transaction details.
- **`@FileName` is no longer used in the ETL** — SP_eMoney_Reconciliation_ETLs replaces it with NULL when inserting into ETL_Authorize (commented out at line 452).
- **`etr_y`/`etr_ym`/`etr_ymd` are 99.8% NULL** — do not use for filtering; use `partition_date` instead.
- **`Created` vs `@Created`** — `Created` is ~11% NULL in recent data and is distinct from `@Created`. The SP uses `@Created` as the watermark, not `Created`.
- **Column names with `@` prefix** require square-bracket quoting in SQL: `[@Created]`, `[@Id]`, `[@FileName]`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic with named source table |
| Tier 3 | Grounded in DDL + live data + SP code but no upstream wiki available |
| Tier 4 | Inferred from column name only (banned in this pipeline) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | Record creation timestamp from the Tribe XML ingestion. Used as the incremental load watermark in SP_eMoney_Reconciliation_ETLs (`WHERE aa.[@Created] >= @Authorize_DATE`). Range: 2021-09-05 to present. (Tier 3 — no upstream wiki; grounded in DDL + SP incremental load pattern) |
| 2 | @Id | varchar(40) | YES | Unique identifier (UUID) for each ingested XML record. Primary JOIN key linking this parent header to child tables Authorizes_Authorize-312243, Authorizes_RiskActions-796100, and Authorizes_SecurityChecks-30662. Indexed (ClusteredIndex_Authorizes_837045). (Tier 3 — no upstream wiki; grounded in DDL + SP JOIN pattern at line 542) |
| 3 | @FileName | varchar(max) | YES | Source XML file path/name from the Tribe data lake ingestion. Format: `authorizes-11-{accountId}-{subId}-{YYYYMMDD}-SubFile-{N}.xml`. Originally selected in the ETL but now replaced with NULL in SP_eMoney_Reconciliation_ETLs (line 453). (Tier 3 — no upstream wiki; grounded in DDL + SP code + live data file path pattern) |
| 4 | etr_y | varchar(max) | YES | Year partition marker from the Generic Pipeline data lake export. 99.8% NULL across the dataset. Not used in any downstream ETL logic. (Tier 3 — no upstream wiki; grounded in DDL column name pattern `etr_` + NULL prevalence in live data) |
| 5 | etr_ym | varchar(max) | YES | Year-month partition marker from the Generic Pipeline data lake export. 99.8% NULL across the dataset. Not used in any downstream ETL logic. (Tier 3 — no upstream wiki; grounded in DDL column name pattern `etr_` + NULL prevalence in live data) |
| 6 | etr_ymd | varchar(max) | YES | Year-month-day partition marker from the Generic Pipeline data lake export. 99.8% NULL across the dataset. Not used in any downstream ETL logic. (Tier 3 — no upstream wiki; grounded in DDL column name pattern `etr_` + NULL prevalence in live data) |
| 7 | SynapseUpdateDate | datetime | YES | Timestamp of the last Synapse data refresh/ingestion for this row. Set by the Generic Pipeline at load time. Latest value: 2026-04-26 06:33:40, confirming active daily refresh. (Tier 3 — no upstream wiki; standard DWH housekeeping column, grounded in DDL + live data) |
| 8 | partition_date | date | YES | Date-level partition key derived from the record creation date. Indexed (XI_partition_date) for efficient date-range filtering. Aligns with `@Created` date component. (Tier 3 — no upstream wiki; grounded in DDL index + live data alignment with @Created) |
| 9 | Created | datetime2(7) | YES | Alternate creation timestamp. ~11% NULL in recent data (364,581 of 3,174,513 rows since 2023). Distinct from `@Created`; may represent a business-level event timestamp vs. the ingestion timestamp in `@Created`. Not used as the incremental watermark in the SP. (Tier 3 — no upstream wiki; grounded in DDL + NULL analysis in live data + SP logic showing @Created is the watermark) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Created | Tribe XML (card authorizations) | Created attribute | Ingested as-is |
| @Id | Tribe XML (card authorizations) | Id attribute | Ingested as-is (UUID) |
| @FileName | Tribe XML (card authorizations) | File metadata | Ingested as-is |
| etr_y | Generic Pipeline | — | Year partition marker (mostly NULL) |
| etr_ym | Generic Pipeline | — | Year-month partition marker (mostly NULL) |
| etr_ymd | Generic Pipeline | — | Year-month-day partition marker (mostly NULL) |
| SynapseUpdateDate | Generic Pipeline | — | Set at ingestion time |
| partition_date | Generic Pipeline | — | Derived from @Created date |
| Created | Tribe XML (card authorizations) | Created element | Ingested as-is |

### 5.2 ETL Pipeline

```
Tribe Card Processing Platform (Authorization Events)
  |-- XML export (daily, sub-files) ---|
  v
Data Lake (XML files: authorizes-11-{acct}-{sub}-{date}-SubFile-{N}.xml)
  |-- Generic Pipeline (Bronze export) ---|
  v
eMoney_Tribe.Authorizes-837045 (3.77M rows, parent/header)
  |                                                        |
  |-- INNER JOIN @Id --> Authorizes_Authorize-312243       |
  |-- LEFT JOIN @Id  --> Authorizes_RiskActions-796100     |
  |-- LEFT JOIN @Id  --> Authorizes_SecurityChecks-30662   |
  |                                                        |
  |-- SP_eMoney_Reconciliation_ETLs (Recon Table 03) -----|
  v
eMoney_dbo.ETL_Authorize (denormalized output)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| — | — | No outbound foreign keys; raw landing table |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_Tribe.Authorizes_Authorize-312243 | Child table: detailed authorization transaction fields |
| @Id | eMoney_Tribe.Authorizes_RiskActions-796100 | Child table: risk action flags |
| @Id | eMoney_Tribe.Authorizes_SecurityChecks-30662 | Child table: security verification fields |
| @Id, @Created | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Consumer SP: reads this table to build ETL_Authorize |

---

## 7. Sample Queries

### 7.1 Daily Ingestion Volume

```sql
SELECT
    partition_date,
    COUNT(*) AS file_count
FROM [eMoney_Tribe].[Authorizes-837045]
WHERE partition_date >= '2026-04-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.2 Full Authorization Record (Denormalized)

```sql
SELECT
    aa.[@Created],
    aa.[@Id],
    aa.[@FileName],
    aaa.*
FROM [eMoney_Tribe].[Authorizes-837045] aa
INNER JOIN [eMoney_Tribe].[Authorizes_Authorize-312243] aaa ON aa.[@Id] = aaa.[@Id]
WHERE aa.partition_date = '2026-04-25';
```

### 7.3 Check for NULL Created vs @Created Discrepancy

```sql
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN Created IS NULL THEN 1 ELSE 0 END) AS created_null,
    SUM(CASE WHEN [@Created] IS NULL THEN 1 ELSE 0 END) AS at_created_null
FROM [eMoney_Tribe].[Authorizes-837045]
WHERE partition_date >= '2026-01-01';
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this Tribe raw landing table.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 9 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 6/10, Lineage: 7/10*
*Object: eMoney_Tribe.Authorizes-837045 | Type: Table | Production Source: Tribe Data Lake (XML) → Generic Pipeline*
