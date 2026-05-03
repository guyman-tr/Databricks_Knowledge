# eMoney_Tribe.CardsSnapshots-890718

> 86.4M-row raw data landing table storing XML file metadata for eToro Money card snapshot ingestion, spanning 2021-09-05 to 2026-04-26. Serves as a JOIN hub linking card snapshot sub-tables (`CardsSnapshots_CardSnapshot-140457`, `CardsSnapshots_Accounts-350640`, `CardsSnapshots_Account-513255`) via the `@Id` GUID. Consumed by `SP_eMoney_Reconciliation_ETLs` to populate `eMoney_dbo.ETL_CardSnapshot`. Production source: unknown (data lake XML ingestion, no upstream wiki).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | Unknown — data lake XML file ingestion (Tribe raw data pipeline) |
| **Refresh** | Incremental — `SP_eMoney_Reconciliation_ETLs` filters on `MAX(Created)` from `ETL_CardSnapshot` |
| **Synapse Distribution** | HASH(`@Id`) |
| **Synapse Index** | Clustered Index on `@Id` ASC; NCI on `partition_date` ASC |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`CardsSnapshots-890718` is a raw data landing table in the `eMoney_Tribe` schema that receives XML file metadata from the eToro Money card snapshot data pipeline. Each row represents one XML sub-file ingested from the data lake, identified by a GUID (`@Id`) and carrying the source file path (`@FileName`).

The table contains 86.4M rows spanning from September 2021 to April 2026. It does not store card business data itself — instead, it serves as a **JOIN hub** in `SP_eMoney_Reconciliation_ETLs`, linking the card snapshot sub-tables (`CardsSnapshots_CardSnapshot-140457`, `CardsSnapshots_Accounts-350640`, `CardsSnapshots_Account-513255`, `CardsSnapshots_BankAccounts-83854`, `CardsSnapshots_BankAccount-341626`) via the shared `@Id` GUID to assemble the complete card snapshot record for insertion into `eMoney_dbo.ETL_CardSnapshot`.

The ETR partition columns (`etr_y`, `etr_ym`, `etr_ymd`) are ~99.5% empty across sampled rows, indicating they are not actively used for partitioning in this table.

---

## 2. Business Logic

### 2.1 JOIN Hub Role

**What**: This table provides the `@Id` linkage key and `@FileName` metadata for assembling card snapshot records.
**Columns Involved**: `@Id`, `@FileName`
**Rules**:
- `@Id` is used as the INNER JOIN key with `CardsSnapshots_CardSnapshot-140457` (via temp table `#CardsSnapshots_140457`)
- `@FileName` is selected as `[FileName]` in the intermediate `#CardsSnapshots1` temp table but is ultimately replaced with `NULL` in the final INSERT into `ETL_CardSnapshot` (as of the 2025-12-21 change by Inessa to avoid duplicates)
- The SP filters on `@Created >= @CardSnapshot_DATE` where `@CardSnapshot_DATE = MAX(Created)` from `ETL_CardSnapshot`

### 2.2 ETR Partition Columns (Inactive)

**What**: Standard ETR (eToro Raw) partition columns present but largely unpopulated.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- ~99.5% of rows have empty string values for all three columns
- These columns are not referenced in any SP logic
- Likely vestigial from the generic data lake ingestion framework

### 2.3 Temporal Columns

**What**: Multiple timestamp columns track file creation, record creation, and Synapse ingestion.
**Columns Involved**: `@Created`, `Created`, `SynapseUpdateDate`, `partition_date`
**Rules**:
- `@Created` and `Created` carry near-identical timestamps (sub-second difference); `@Created` has microsecond precision from XML metadata, `Created` is the rounded Synapse copy
- `partition_date` is the date portion of `@Created`, used for the NCI index
- `SynapseUpdateDate` tracks when the row was loaded into Synapse

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `@Id` — efficient for JOIN operations with other `eMoney_Tribe` tables that share the same distribution key
- **Clustered Index**: `@Id` ASC — supports point lookups and JOIN operations
- **NCI**: `partition_date` ASC — supports date-range filtering

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Find files ingested on a specific date | `WHERE partition_date = '2024-01-15'` (uses NCI) |
| Count records per day | `SELECT partition_date, COUNT(*) FROM ... GROUP BY partition_date WHERE partition_date >= '2026-01-01'` |
| Look up a specific file by GUID | `WHERE [@Id] = 'guid-value'` (uses clustered index) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| `eMoney_Tribe.CardsSnapshots_CardSnapshot-140457` | `ON aa.[@Id] = ab.[@Id]` | Link to card snapshot detail data |
| `eMoney_Tribe.CardsSnapshots_Accounts-350640` | `ON ac.[@Id] = ab.[@Id]` | Link to account association data |
| `eMoney_Tribe.CardsSnapshots_Account-513255` | `ON ad.[@Id] = ac.[@Id]` | Link to account detail data |

### 3.4 Gotchas

- **`@FileName` is no longer used in the final output**: As of 2025-12-21, the SP inserts `NULL` for `FileName` in `ETL_CardSnapshot` to avoid duplicate handling issues, making this column useful only for data lake traceability
- **`etr_y` / `etr_ym` / `etr_ymd` are ~99.5% empty**: Do not rely on these for filtering or partitioning
- **Column names contain `@` prefix**: Use square brackets when querying — `SELECT [@Id], [@Created], [@FileName]`
- **`@Created` vs `Created`**: These are near-identical but `@Created` has higher precision (datetime2(7) from XML) while `Created` is a separate datetime2(7) column — use `partition_date` for date-range queries instead

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DDL, naming, data sample, and SP usage — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | XML file creation timestamp from the data lake ingestion pipeline. Used as the incremental load filter in `SP_eMoney_Reconciliation_ETLs` (`WHERE @Created >= @CardSnapshot_DATE`). Microsecond precision. (Tier 3 — DDL + SP_eMoney_Reconciliation_ETLs usage) |
| 2 | @Id | varchar(255) | YES | GUID identifier assigned during XML file ingestion. Distribution key and clustered index. Serves as the primary JOIN key linking this table to all other `CardsSnapshots_*` sub-tables in `SP_eMoney_Reconciliation_ETLs`. (Tier 3 — DDL + SP_eMoney_Reconciliation_ETLs usage) |
| 3 | @FileName | varchar(max) | YES | Full path of the source XML sub-file from the data lake (e.g., `cards-snapshots-11-15967860899208-10079563-YYYYMMDD-SubFile-NNNNN.xml`). Originally passed through to `ETL_CardSnapshot` as `[FileName]` but replaced with NULL as of 2025-12-21 to avoid duplicate handling issues. (Tier 3 — DDL + SP_eMoney_Reconciliation_ETLs usage) |
| 4 | etr_y | varchar(max) | YES | ETR (eToro Raw) year partition column from the generic data lake ingestion framework. ~99.5% empty across sampled rows. Not referenced by any SP logic. (Tier 3 — DDL + data sample) |
| 5 | etr_ym | varchar(max) | YES | ETR (eToro Raw) year-month partition column from the generic data lake ingestion framework. ~99.5% empty across sampled rows. Not referenced by any SP logic. (Tier 3 — DDL + data sample) |
| 6 | etr_ymd | varchar(max) | YES | ETR (eToro Raw) year-month-day partition column from the generic data lake ingestion framework. ~99.5% empty across sampled rows. Not referenced by any SP logic. (Tier 3 — DDL + data sample) |
| 7 | SynapseUpdateDate | datetime | YES | Timestamp recording when the row was loaded or last updated in Synapse. Standard metadata column across eMoney_Tribe tables. (Tier 3 — DDL + data sample) |
| 8 | Created | datetime2(7) | YES | Record creation timestamp. Near-identical to `@Created` (sub-second difference). Represents the Synapse-side copy of the ingestion timestamp. (Tier 3 — DDL + data sample) |
| 9 | partition_date | date | YES | Date portion derived from the ingestion timestamp, used for the non-clustered index (`XI_partition_date`). Matches the date component of `@Created`. Enables efficient date-range filtering. (Tier 3 — DDL + data sample) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Created | Data Lake XML | @Created | Passthrough from XML file metadata |
| @Id | Data Lake XML | @Id | GUID from XML ingestion |
| @FileName | Data Lake XML | @FileName | Source file path from data lake |
| etr_y | Data Lake ETR | etr_y | ETR partition — mostly empty |
| etr_ym | Data Lake ETR | etr_ym | ETR partition — mostly empty |
| etr_ymd | Data Lake ETR | etr_ymd | ETR partition — mostly empty |
| SynapseUpdateDate | Synapse | N/A | Synapse ingestion timestamp |
| Created | Data Lake XML | @Created | Near-copy of @Created |
| partition_date | Data Lake XML | @Created | Date portion of @Created |

### 5.2 ETL Pipeline

```
Data Lake (XML files: cards-snapshots-*.xml)
  |-- Generic Pipeline (Tribe raw data export) ---|
  v
eMoney_Tribe.CardsSnapshots-890718 (86.4M rows, JOIN hub)
  |-- SP_eMoney_Reconciliation_ETLs --------------|
  |   INNER JOIN CardsSnapshots_CardSnapshot-140457 (card details)
  |   LEFT JOIN  CardsSnapshots_Accounts-350640 (account linkage)
  |   LEFT JOIN  CardsSnapshots_Account-513255 (account details)
  |   LEFT JOIN  CardsSnapshots_BankAccounts-83854 (bank linkage)
  |   LEFT JOIN  CardsSnapshots_BankAccount-341626 (bank details)
  v
eMoney_dbo.ETL_CardSnapshot (final reconciliation table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @Id | CardsSnapshots_CardSnapshot-140457 | INNER JOIN on @Id for card detail data |
| @Id | CardsSnapshots_Accounts-350640 | LEFT JOIN on @Id for account association |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| @Id | SP_eMoney_Reconciliation_ETLs | Writer SP uses this table as JOIN hub for card snapshot assembly |

---

## 7. Sample Queries

### 7.1 Count Records by Partition Date (Recent)

```sql
SELECT partition_date, COUNT(*) AS record_count
FROM [eMoney_Tribe].[CardsSnapshots-890718]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.2 Inspect Source Files for a Specific Date

```sql
SELECT [@Id], [@FileName], [@Created], [Created], [SynapseUpdateDate]
FROM [eMoney_Tribe].[CardsSnapshots-890718]
WHERE partition_date = '2024-02-11'
ORDER BY [@Created];
```

### 7.3 Check ETR Partition Column Population

```sql
SELECT TOP 100 [@Id], [etr_y], [etr_ym], [etr_ymd]
FROM [eMoney_Tribe].[CardsSnapshots-890718]
WHERE [etr_y] IS NOT NULL AND [etr_y] <> '';
```

---

## 8. Atlassian Knowledge Sources

- **Freshservice Change #20353**: Referenced in `SP_eMoney_Reconciliation_ETLs` header — eToro Money eMoney Reconciliation Tables migration to Synapse (2022-11-16).

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 9 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 3/10, Lineage: complete*
*Object: eMoney_Tribe.CardsSnapshots-890718 | Type: Table | Production Source: Unknown (data lake XML ingestion)*
