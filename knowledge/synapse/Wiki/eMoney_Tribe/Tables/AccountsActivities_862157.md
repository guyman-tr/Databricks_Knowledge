# eMoney_Tribe.AccountsActivities_862157

> 29.8M-row Treezor XML envelope table storing raw account-activity document metadata from the eToro Money platform, spanning 2021-09-05 to 2026-04-26. Serves as the parent container joined to child detail tables (`AccountsActivities_AccountActivity-833937`, `RiskActions-322546`, `SecurityChecks-471048`) by `SP_eMoney_Reconciliation_ETLs` to build `ETL_AccountsActivities`. Production source: Treezor API XML file exports.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | Treezor API XML exports via Generic Pipeline; consumed by `SP_eMoney_Reconciliation_ETLs` |
| **Refresh** | Incremental — SP loads new rows based on `MAX(Created)` from downstream `ETL_AccountsActivities` |
| **Synapse Distribution** | HASH ( [@Id] ) |
| **Synapse Index** | HEAP + 3 NCIs: `ClusteredIndex_AA_862157_Id` on [@Id], `XI_partition_date` on partition_date, `idx_862157_created` on [@Created] |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`AccountsActivities_862157` is a raw Treezor XML envelope table in the eMoney Tribe schema. Each row represents one XML file ingested from the Treezor banking-as-a-service API, containing account activity data for eToro Money customers. The numeric suffix `862157` is a Treezor webhook/file entity identifier.

The table holds ~29.8M rows spanning from September 2021 to April 2026. It functions purely as a parent/container table — the actual account activity fields (transaction amounts, codes, merchant info, etc.) reside in sibling child tables joined on `@Id`. The stored procedure `SP_eMoney_Reconciliation_ETLs` (authored by eMoney & Wallet Data Analytics Team, Ofir Ovadia, 2022-11-16) reads this table as the anchor in a multi-table JOIN to produce the reconciled `ETL_AccountsActivities` fact table in `eMoney_dbo`.

The incremental load pattern uses `MAX(Created)` from the target `ETL_AccountsActivities` to determine the extraction window, deletes existing rows from that date onward, and re-inserts the joined result.

---

## 2. Business Logic

### 2.1 Parent-Child XML Document Model

**What**: Each XML file from Treezor is decomposed into a parent envelope row (this table) and multiple child rows in sibling tables, all linked by `@Id`.
**Columns Involved**: `@Id`, `@FileName`, `@Created`
**Rules**:
- `@Id` is a UUID (varchar(40)) uniquely identifying each XML document
- `@FileName` follows the pattern `accounts-activities-{version}-{entityId}-{accountId}-{YYYYMMDD}-SubFile-{N}.xml`
- Child tables: `AccountsActivities_AccountActivity-833937` (detail), `AccountsActivities_RiskActions-322546` (risk), `AccountsActivities_SecurityChecks-471048` (security)

### 2.2 ETL Partition Keys

**What**: Three partition columns exist but are nearly entirely NULL (~99.8% NULL rate).
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- These columns are populated by the Generic Pipeline for year/month/day partitioning
- Only ~73K rows out of 29.8M have non-NULL values, suggesting the partition scheme was added late or applies to a small subset
- Not used by `SP_eMoney_Reconciliation_ETLs`

### 2.3 Incremental Load Boundary

**What**: The SP uses `@Created` to filter new rows during incremental loads.
**Columns Involved**: `@Created`, `partition_date`
**Rules**:
- `WHERE aa.[@Created] >= @AccountActivities_DATE` filters rows newer than the last successful load
- `partition_date` mirrors the date portion of `@Created` and is indexed for efficient partition pruning

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distributed by HASH on `[@Id]` (varchar(40) UUID). This aligns with the JOIN pattern in `SP_eMoney_Reconciliation_ETLs`, which joins child tables on `[@Id]` — all co-located on the same distribution. The table is a HEAP (no clustered columnstore) with three nonclustered indexes on `[@Id]`, `partition_date`, and `[@Created]`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Count documents by date | `SELECT partition_date, COUNT(*) FROM eMoney_Tribe.AccountsActivities_862157 GROUP BY partition_date` — uses NCI on partition_date |
| Find a specific XML document | `SELECT * FROM eMoney_Tribe.AccountsActivities_862157 WHERE [@Id] = '...'` — uses HASH distribution + NCI |
| Check recent ingestion | `SELECT TOP 10 * FROM eMoney_Tribe.AccountsActivities_862157 ORDER BY [@Created] DESC` — uses NCI on @Created |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| `eMoney_Tribe.[AccountsActivities_AccountActivity-833937]` | `ON aa.[@Id] = aaa.[@Id]` | Get transaction detail fields (amounts, codes, merchant) |
| `eMoney_Tribe.[AccountsActivities_RiskActions-322546]` | `ON aar.[@Id] = aa.[@Id]` | Get risk action flags |
| `eMoney_Tribe.[AccountsActivities_SecurityChecks-471048]` | `ON aas.[@Id] = aa.[@Id]` | Get security check results |

### 3.4 Gotchas

- **Do not query this table alone for business data** — it is only the envelope. Join to the child tables for actual activity fields.
- **`etr_y`, `etr_ym`, `etr_ymd` are ~99.8% NULL** — do not use these for filtering; use `partition_date` or `@Created` instead.
- **`Created` column is ~41.6% NULL** — this is distinct from `@Created` (which is always populated). The `Created` column appears to be an alternate timestamp that was not backfilled for older rows.
- **HEAP table** — no columnstore compression. Full scans on 29.8M rows will be slower than columnstore equivalents.
- **`@FileName` is varchar(max)** — avoid SELECT * in large scans; explicitly list needed columns.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DDL, data sampling, and SP context — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | @Created | datetime2(7) | YES | Treezor XML document creation timestamp. Used by SP_eMoney_Reconciliation_ETLs as the incremental load boundary (`WHERE aa.[@Created] >= @AccountActivities_DATE`). Always populated (0% NULL). Indexed via `idx_862157_created`. (Tier 3 — Treezor XML export, no upstream wiki) |
| 2 | @Id | varchar(40) | YES | UUID uniquely identifying each Treezor XML document. Distribution key (HASH) and primary JOIN key to all child tables (`AccountsActivities_AccountActivity-833937`, `RiskActions-322546`, `SecurityChecks-471048`). Always populated (0% NULL). Indexed via `ClusteredIndex_AA_862157_Id`. (Tier 3 — Treezor XML export, no upstream wiki) |
| 3 | @FileName | varchar(max) | YES | Source XML file name from Treezor. Pattern: `accounts-activities-{version}-{entityId}-{accountId}-{YYYYMMDD}-SubFile-{N}.xml`. Always populated (0% NULL). Not used by SP_eMoney_Reconciliation_ETLs. (Tier 3 — Treezor XML export, no upstream wiki) |
| 4 | etr_y | varchar(max) | YES | Generic Pipeline ETL partition key for year. ~99.8% NULL (only ~73K of 29.8M rows populated). Not used by SP_eMoney_Reconciliation_ETLs. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 5 | etr_ym | varchar(max) | YES | Generic Pipeline ETL partition key for year-month. ~99.8% NULL (only ~73K of 29.8M rows populated). Not used by SP_eMoney_Reconciliation_ETLs. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 6 | etr_ymd | varchar(max) | YES | Generic Pipeline ETL partition key for year-month-day. ~99.8% NULL (only ~73K of 29.8M rows populated). Not used by SP_eMoney_Reconciliation_ETLs. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 7 | SynapseUpdateDate | datetime | YES | Timestamp when the row was loaded or last updated in Synapse by the Generic Pipeline. Always populated (0% NULL). (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 8 | partition_date | date | YES | Date-level partition key derived from the XML document date. Always populated (0% NULL). Indexed via `XI_partition_date`. Corresponds to the date component of `@Created`. (Tier 3 — Generic Pipeline metadata, no upstream wiki) |
| 9 | Created | datetime2(7) | YES | Alternate creation timestamp. ~41.6% NULL — appears unpopulated for older rows (pre-backfill or schema change). Distinct from `@Created` which is always populated. (Tier 3 — Treezor XML export, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Created | Treezor XML export | @Created | Passthrough |
| @Id | Treezor XML export | @Id | Passthrough |
| @FileName | Treezor XML export | @FileName | Passthrough |
| etr_y | Generic Pipeline | etr_y | ETL partition metadata |
| etr_ym | Generic Pipeline | etr_ym | ETL partition metadata |
| etr_ymd | Generic Pipeline | etr_ymd | ETL partition metadata |
| SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | ETL ingestion timestamp |
| partition_date | Generic Pipeline | partition_date | ETL partition metadata |
| Created | Treezor XML export | Created | Passthrough |

### 5.2 ETL Pipeline

```
Treezor API (banking-as-a-service)
  |-- XML file export (accounts-activities-*.xml) ---|
  v
Generic Pipeline (Bronze export, XML parsing)
  |-- Decompose XML into parent + child tables ---|
  v
eMoney_Tribe.AccountsActivities_862157 (29.8M rows, parent envelope)
  + eMoney_Tribe.AccountsActivities_AccountActivity-833937 (child detail)
  + eMoney_Tribe.AccountsActivities_RiskActions-322546 (child risk)
  + eMoney_Tribe.AccountsActivities_SecurityChecks-471048 (child security)
  |-- SP_eMoney_Reconciliation_ETLs (JOIN on @Id, incremental) ---|
  v
eMoney_dbo.ETL_AccountsActivities (reconciled fact)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_Tribe.AccountsActivities_AccountActivity-833937 | JOIN key — child detail table |
| @Id | eMoney_Tribe.AccountsActivities_RiskActions-322546 | JOIN key — child risk-actions table |
| @Id | eMoney_Tribe.AccountsActivities_SecurityChecks-471048 | JOIN key — child security-checks table |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| @Id, @Created | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Writer SP — reads as parent envelope for ETL_AccountsActivities |
| (all columns) | eMoney_Tribe_tmp.AccountsActivities_862157_tmp | Temporary staging copy of this table |

---

## 7. Sample Queries

### 7.1 Daily Document Ingestion Volume

```sql
SELECT partition_date, COUNT(*) AS doc_count
FROM [eMoney_Tribe].[AccountsActivities_862157]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.2 Join to Child Detail for Full Account Activity

```sql
SELECT TOP 100
    aa.[@Created],
    aa.[@FileName],
    aaa.[WorkDate],
    aaa.[HolderId],
    aaa.[AccountId],
    aaa.[TransactionCode],
    aaa.[TransactionAmount],
    aaa.[TransactionCurrencyAlpha]
FROM [eMoney_Tribe].[AccountsActivities_862157] aa
INNER JOIN [eMoney_Tribe].[AccountsActivities_AccountActivity-833937] aaa
    ON aa.[@Id] = aaa.[@Id]
WHERE aa.partition_date >= '2026-04-01'
ORDER BY aa.[@Created] DESC;
```

### 7.3 Check etr Partition Key Population

```sql
SELECT
    SUM(CASE WHEN etr_y IS NOT NULL THEN 1 ELSE 0 END) AS etr_populated,
    SUM(CASE WHEN etr_y IS NULL THEN 1 ELSE 0 END) AS etr_null,
    COUNT(*) AS total
FROM [eMoney_Tribe].[AccountsActivities_862157];
```

---

## 8. Atlassian Knowledge Sources

- Freshservice Change Request #20353 — referenced in SP_eMoney_Reconciliation_ETLs header (migration of eToro Money eMoney Reconciliation Tables to Synapse)

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 9 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 6/10, Lineage: 7/10*
*Object: eMoney_Tribe.AccountsActivities_862157 | Type: Table | Production Source: Treezor XML exports (dormant upstream — no wiki)*
