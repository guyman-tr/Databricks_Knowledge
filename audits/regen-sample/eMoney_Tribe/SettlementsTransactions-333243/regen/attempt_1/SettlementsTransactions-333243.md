# eMoney_Tribe.SettlementsTransactions-333243

> 2.9M-row raw Tribe XML header table storing settlement transaction file metadata from the eToro Money card issuer (Tribe Payments) since September 2021. Each row represents one XML sub-file ingested via the Generic Pipeline. This table serves as the parent/header record joined to child tables (`SettlementsTransactions_SettlementTransaction-637239`, `RiskActions-236807`, `SecurityChecks-426253`) via `@Id` in `SP_eMoney_Reconciliation_ETLs`, which compiles data into `eMoney_dbo.ETL_SettlementsTransactions`.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | Tribe Payments API — settlement transaction XML exports ingested via Generic Pipeline |
| **Refresh** | Incremental daily — Generic Pipeline loads new XML files; SP_eMoney_Reconciliation_ETLs reads incrementally via `@Created >= MAX(Created)` |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP with 3 NCIs: `ClusteredIndex_ST_333243` on `@Id`, `XI_partition_date` on `partition_date`, `idx_333243_created` on `@Created` |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table is the **header/parent record** for Tribe Payments settlement transaction data within the eToro Money (eMoney) reconciliation pipeline. It contains 2,946,011 rows spanning from 2021-09-05 to 2026-04-25.

Each row corresponds to one XML sub-file from the Tribe Payments settlements export (e.g., `settlements-transactions-11-15967860899208-10079563-20220510-SubFile-688.xml`). The file naming convention encodes the Tribe program ID (`15967860899208`), merchant ID (`10079563`), date, and sub-file sequence number.

The table itself holds only metadata — the `@Id` (GUID) column is the join key to child tables that contain the actual transaction details:
- `SettlementsTransactions_SettlementTransaction-637239` — transaction amounts, currencies, merchant details, settlement amounts
- `SettlementsTransactions_RiskActions-236807` — risk action flags (suspicious marking, card status changes)
- `SettlementsTransactions_SecurityChecks-426253` — security verification flags (PIN, 3DS, CVV2, chip data)

`SP_eMoney_Reconciliation_ETLs` (authored by eMoney & Wallet Data Analytics Team, Ofir Ovadia, 2022-11-16) reads from this table and its children to compile `eMoney_dbo.ETL_SettlementsTransactions`.

The `etr_y`, `etr_ym`, `etr_ymd` columns are legacy ETL partition fields that are ~100% NULL (only 6,065 of 2,946,011 rows populated). The `Created` column duplicates `@Created` but is only populated for records loaded since approximately January 2024.

---

## 2. Business Logic

### 2.1 Parent-Child XML Structure

**What**: Each settlement transaction XML export is split into a parent record (this table) and multiple child records in sibling tables, all linked by `@Id`.
**Columns Involved**: `@Id`, `@FileName`, `@Created`
**Rules**:
- `@Id` is a GUID unique per XML sub-file, used as the universal join key across all `SettlementsTransactions_*` child tables
- `@FileName` contains the full XML file name encoding program ID, merchant ID, date, and sub-file number
- `@Created` is the file-level creation timestamp from the Tribe API

### 2.2 Incremental Load Pattern

**What**: The SP uses an incremental watermark pattern based on `@Created` to load only new records.
**Columns Involved**: `@Created`, `Created`
**Rules**:
- `SP_eMoney_Reconciliation_ETLs` computes `@SettlementsTransactions_DATE = MAX(Created) FROM ETL_SettlementsTransactions`
- Deletes records from ETL target where `Created >= @SettlementsTransactions_DATE` (idempotent re-load)
- Reads from this table using `WHERE [@Created] >= @SettlementsTransactions_DATE`
- The `Created` column in the ETL target is set as `aaa.[@Created]` from the child table, not from this header

### 2.3 Legacy Partition Columns

**What**: Three varchar partition columns exist but are effectively unused.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- 99.8% NULL (2,939,946 of 2,946,011 rows)
- Likely intended for year/year-month/year-month-day partitioning but never populated for most records
- Not referenced by any SP or view in the codebase

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution — full copy on every compute node. Suitable for this 2.9M-row table that is joined frequently in the reconciliation SP.
- **HEAP** storage (no clustered index) — rows not physically ordered.
- Three non-clustered indexes: on `@Id` (join key), `partition_date` (date filtering), and `@Created` (incremental load).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many settlement files were loaded on a given date? | `SELECT partition_date, COUNT(*) FROM [eMoney_Tribe].[SettlementsTransactions-333243] WHERE partition_date = '2024-01-15' GROUP BY partition_date` |
| Get full settlement transaction details | JOIN to `SettlementsTransactions_SettlementTransaction-637239` ON `@Id` — this header table has only metadata |
| Check latest data load | `SELECT MAX([@Created]) FROM [eMoney_Tribe].[SettlementsTransactions-333243]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| SettlementsTransactions_SettlementTransaction-637239 | `ON aa.[@Id] = aaa.[@Id]` | Transaction details (amounts, currencies, merchant info) |
| SettlementsTransactions_RiskActions-236807 | `ON aar.[@Id] = aaa.[@Id]` | Risk action flags |
| SettlementsTransactions_SecurityChecks-426253 | `ON aas.[@Id] = aaa.[@Id]` | Security verification flags |

### 3.4 Gotchas

- **`etr_y`, `etr_ym`, `etr_ymd` are ~100% NULL** — do not use these for date filtering; use `partition_date` or `@Created` instead.
- **`Created` vs `@Created`** — `Created` is NULL for ~26% of records (pre-2024 loads). Always use `@Created` for complete date coverage.
- **This table is a header only** — it contains no transaction amounts, currencies, or merchant data. Always JOIN to the child tables for actual settlement data.
- **Column names with `@` prefix** require square-bracket quoting: `[@Created]`, `[@Id]`, `[@FileName]`.
- **Table name contains a hyphen** — always quote: `[SettlementsTransactions-333243]`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Grounded in DDL + SP code but no upstream wiki available |
| Tier 4 | Inferred from name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | File-level creation timestamp from the Tribe Payments API. Used as the incremental load watermark in SP_eMoney_Reconciliation_ETLs (`WHERE [@Created] >= @SettlementsTransactions_DATE`). Indexed via `idx_333243_created`. Range: 2021-09-05 to 2026-04-25. (Tier 3 — Tribe Payments API, no upstream wiki) |
| 2 | @Id | varchar(40) | YES | Unique GUID record identifier from the Tribe Payments API. Primary join key to all child tables (`SettlementsTransactions_SettlementTransaction-637239`, `RiskActions-236807`, `SecurityChecks-426253`). Indexed via `ClusteredIndex_ST_333243`. (Tier 3 — Tribe Payments API, no upstream wiki) |
| 3 | @FileName | varchar(max) | YES | Source XML file name from the Tribe settlements export. Encodes program ID, merchant ID, date, and sub-file sequence number (e.g., `settlements-transactions-11-15967860899208-10079563-20220510-SubFile-688.xml`). Always populated (0% NULL). (Tier 3 — Tribe Payments API, no upstream wiki) |
| 4 | etr_y | varchar(max) | YES | Legacy ETL year partition column. Intended for year-level partitioning but effectively unused — 99.8% NULL (2,939,946 of 2,946,011 rows). Not referenced by any SP or view. (Tier 3 — Generic Pipeline ETL, no upstream wiki) |
| 5 | etr_ym | varchar(max) | YES | Legacy ETL year-month partition column. Intended for year-month partitioning but effectively unused — 99.8% NULL. Not referenced by any SP or view. (Tier 3 — Generic Pipeline ETL, no upstream wiki) |
| 6 | etr_ymd | varchar(max) | YES | Legacy ETL year-month-day partition column. Intended for year-month-day partitioning but effectively unused — 99.8% NULL. Not referenced by any SP or view. (Tier 3 — Generic Pipeline ETL, no upstream wiki) |
| 7 | SynapseUpdateDate | datetime | YES | Timestamp of the last Synapse data load for this record. Always populated (0% NULL). Uniform value of `2023-12-24 16:13:17.613` for older records suggests a bulk historical reload occurred on that date; newer records carry their individual load timestamps. (Tier 3 — Generic Pipeline ETL, no upstream wiki) |
| 8 | partition_date | date | YES | Date-only partition key derived from `@Created`. Indexed via `XI_partition_date`. Used for efficient date-range filtering. Range: 2021-09-05 to 2026-04-25. (Tier 3 — Generic Pipeline ETL, no upstream wiki) |
| 9 | Created | datetime2(7) | YES | Copy of `@Created` populated only for records loaded since approximately January 2024. NULL for ~26% of rows (770,930 of 2,946,011). For older records, use `@Created` instead. (Tier 3 — Generic Pipeline ETL, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Created | Tribe Payments API | @Created | Passthrough (XML file metadata) |
| @Id | Tribe Payments API | @Id | Passthrough (XML file metadata, GUID) |
| @FileName | Tribe Payments API | @FileName | Passthrough (XML file name) |
| etr_y | Generic Pipeline | — | ETL-generated partition column (mostly NULL) |
| etr_ym | Generic Pipeline | — | ETL-generated partition column (mostly NULL) |
| etr_ymd | Generic Pipeline | — | ETL-generated partition column (mostly NULL) |
| SynapseUpdateDate | Generic Pipeline | — | ETL housekeeping timestamp |
| partition_date | Generic Pipeline | @Created | Date-only extraction from @Created |
| Created | Generic Pipeline | @Created | Copy of @Created (newer records only) |

### 5.2 ETL Pipeline

```
Tribe Payments API (settlement transaction XML exports)
  |-- Generic Pipeline (Bronze XML ingestion) ---|
  v
eMoney_Tribe.SettlementsTransactions-333243 (2.9M rows, header/parent)
  |
  |-- INNER JOIN SettlementsTransactions_SettlementTransaction-637239 (child: txn details)
  |-- LEFT JOIN  SettlementsTransactions_RiskActions-236807 (child: risk flags)
  |-- LEFT JOIN  SettlementsTransactions_SecurityChecks-426253 (child: security checks)
  |
  |-- SP_eMoney_Reconciliation_ETLs (incremental, @Created watermark) ---|
  v
eMoney_dbo.ETL_SettlementsTransactions (compiled reconciliation table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No outbound FK references. This is a raw ingestion header table. |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| @Id | eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239 | Child table with transaction details, joined via INNER JOIN on @Id |
| @Id | eMoney_Tribe.SettlementsTransactions_RiskActions-236807 | Child table with risk action flags, joined via LEFT JOIN on @Id |
| @Id | eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253 | Child table with security check flags, joined via LEFT JOIN on @Id |
| @Created | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Used as incremental load watermark filter |

---

## 7. Sample Queries

### 7.1 Daily File Ingestion Volume

```sql
SELECT
    partition_date,
    COUNT(*) AS file_count
FROM [eMoney_Tribe].[SettlementsTransactions-333243]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.2 Full Settlement Transaction Details (Join to Children)

```sql
SELECT
    aa.[@Created],
    aa.[@FileName],
    aaa.[TransactionAmount],
    aaa.[TransactionCurrencyAlpha],
    aaa.[MerchantName],
    aaa.[SettlementAmount],
    aaa.[SettlementCurrencyAlpha],
    aar.[MarkTransactionAsSuspicious],
    aas.[ThreeDomainSecure]
FROM [eMoney_Tribe].[SettlementsTransactions-333243] aa
INNER JOIN [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239] aaa ON aa.[@Id] = aaa.[@Id]
LEFT JOIN [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807] aar ON aar.[@Id] = aaa.[@Id]
LEFT JOIN [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253] aas ON aas.[@Id] = aaa.[@Id]
WHERE aa.partition_date >= '2026-04-01';
```

### 7.3 Check Latest Load Timestamp

```sql
SELECT
    MAX([@Created]) AS latest_created,
    MAX([SynapseUpdateDate]) AS latest_synapse_update,
    COUNT(*) AS total_rows
FROM [eMoney_Tribe].[SettlementsTransactions-333243];
```

---

## 8. Atlassian Knowledge Sources

- **Freshservice Change #20353**: Referenced in SP_eMoney_Reconciliation_ETLs header — eToro Money eMoney Reconciliation Tables migration to Synapse (2022-11-16).
- No Jira or Confluence sources identified for this specific Tribe raw data table.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 9 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 7/10, Lineage: 7/10*
*Object: eMoney_Tribe.SettlementsTransactions-333243 | Type: Table | Production Source: Tribe Payments API (external, no upstream wiki)*
