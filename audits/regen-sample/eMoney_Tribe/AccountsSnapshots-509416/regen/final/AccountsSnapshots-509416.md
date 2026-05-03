# eMoney_Tribe.AccountsSnapshots-509416

> 1.5B-row raw XML landing table storing eMoney Tribe account snapshot file metadata, ingested via the Generic Pipeline from Tribe XML exports since 2022-04-11 to present. Serves as the join root for `SP_eMoney_Reconciliation_ETLs` (Reconciliation Table 05 — Account Snapshot), linking sub-tables by `@Id`. Production source is Tribe XML file ingestion (no documented upstream database).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | Tribe XML file ingestion (eMoney data pipeline). Consumed by `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` |
| **Refresh** | Incremental — Generic Pipeline loads new XML files; SP reads incrementally via `MAX(@Created)` watermark |
| **Synapse Distribution** | HASH(`@Id`) |
| **Synapse Index** | Clustered Index on `@Id` ASC; NCI on `partition_date` ASC; NCI on `@Created` ASC |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`AccountsSnapshots-509416` is a raw XML landing table in the `eMoney_Tribe` schema, part of the eToro Money (eMoney) Tribe data pipeline. It stores file-level metadata for account snapshot XML exports received from the Tribe card-issuing platform. The table contains ~1.5 billion rows spanning from 2022-04-11 to 2026-04-26.

Each row represents a single XML sub-file record, identified by a unique GUID (`@Id`). The `@FileName` column captures the source XML file path (e.g., `accounts-snapshots-11-{AccountID}-{Date}-SubFile-{N}.xml`). The table also carries ETL partition columns (`etr_y`, `etr_ym`, `etr_ymd`) which appear consistently NULL in sampled data, and a `partition_date` column used for physical data organization.

This table is consumed by `SP_eMoney_Reconciliation_ETLs` (Reconciliation Table 05 — Account Snapshot), where it serves as the join root. The SP joins `AccountsSnapshots-509416` on `@Id` with sub-tables `AccountsSnapshots_AccountSnapshot-956050` (account detail), `AccountsSnapshots_BankAccounts-795870` (bank accounts list), and `AccountsSnapshots_BankAccount-393561` (bank account detail) to assemble the full account snapshot record, which is then loaded into `eMoney_dbo.ETL_AccountSnapshot`.

---

## 2. Business Logic

### 2.1 XML File Ingestion Pattern

**What**: Each row corresponds to a sub-file within a daily Tribe XML export batch.
**Columns Involved**: `@Id`, `@FileName`, `@Created`, `partition_date`
**Rules**:
- `@Id` is a GUID uniquely identifying each XML sub-file record across all ingestion batches.
- `@FileName` follows the pattern `accounts-snapshots-{version}-{AccountID}-{Date}-SubFile-{N}.xml`, encoding the source account and date.
- `@Created` and `Created` may differ: `@Created` reflects the XML record timestamp from the source; `Created` can be set to the Synapse load timestamp on historical backfills.

### 2.2 Join Root for Account Snapshot ETL

**What**: This table provides the join key (`@Id`) used to link all related account snapshot sub-tables.
**Columns Involved**: `@Id`, `@FileName`
**Rules**:
- `SP_eMoney_Reconciliation_ETLs` uses `@Id` as the primary join key across four sub-tables.
- Only `@FileName` and `@Id` are consumed from this table by the SP; all business columns come from the sub-tables.
- The SP applies an incremental watermark: `WHERE aa.[@Created] >= @AccountSnapshot_DATE`.

### 2.3 Unused Partition Columns

**What**: The `etr_y`, `etr_ym`, `etr_ymd` columns appear to be ETL partitioning placeholders.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- All three columns are NULL across all sampled rows.
- These columns are likely remnants of an earlier partitioning scheme or reserved for future use.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `@Id` (GUID). Optimal for equi-joins on `@Id` with sub-tables (`AccountsSnapshots_AccountSnapshot-956050`, etc.) which share the same distribution key.
- **Clustered Index**: `@Id` ASC — efficient for point lookups and JOIN operations.
- **NCI on `partition_date`**: Supports date-range filtering.
- **NCI on `@Created`**: Supports incremental load queries using the `MAX(@Created)` watermark pattern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many XML files were ingested on a given date? | `SELECT partition_date, COUNT(*) FROM [eMoney_Tribe].[AccountsSnapshots-509416] WHERE partition_date = '2024-01-15' GROUP BY partition_date` |
| Which accounts had snapshots on a specific date? | Join with `AccountsSnapshots_AccountSnapshot-956050` on `@Id` and filter by `partition_date` |
| Check ingestion lag | `SELECT TOP 100 [@Created], SynapseUpdateDate, DATEDIFF(HOUR, [@Created], SynapseUpdateDate) AS lag_hours FROM [eMoney_Tribe].[AccountsSnapshots-509416] WHERE partition_date >= '2026-04-01'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050` | `ON aa.[@Id] = aaa.[@Id]` | Account detail (balances, status, holder) |
| `eMoney_Tribe.AccountsSnapshots_BankAccounts-795870` | `ON aar.[@Id] = aaa.[@Id]` | Bank accounts list |
| `eMoney_Tribe.AccountsSnapshots_BankAccount-393561` | `ON aas.[@Id] = aar.[@Id]` | Individual bank account detail |

### 3.4 Gotchas

- **1.5B rows** — never run unfiltered `COUNT(*)` or `GROUP BY`. Always filter by `partition_date` or `@Created`.
- **`etr_y`, `etr_ym`, `etr_ymd` are all NULL** — do not use these columns for filtering or partitioning.
- **`@Created` vs `Created`** — these two columns may have different values. `@Created` is the XML source timestamp; `Created` may reflect a backfill/reload date (observed: many rows have `Created = 2023-12-20` while `@Created` varies).
- **Column names contain `@` prefix** — must be escaped with brackets in SQL: `[@Id]`, `[@Created]`, `[@FileName]`.
- **The table itself carries no business data** — all account details come from the sub-tables via JOIN on `@Id`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | No upstream wiki; grounded in DDL, SP code, and live data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Created | datetime2(7) | YES | XML record creation timestamp from the Tribe source file. Used as the incremental watermark by `SP_eMoney_Reconciliation_ETLs` (`WHERE aa.[@Created] >= @AccountSnapshot_DATE`). May differ from `Created` on backfilled rows. (Tier 3 — no upstream wiki, grounded in DDL + SP code) |
| 2 | @Id | varchar(255) | YES | Unique GUID identifier for each XML sub-file record. Distribution key and clustered index. Used as the primary join key to link with sub-tables `AccountsSnapshots_AccountSnapshot-956050`, `AccountsSnapshots_BankAccounts-795870`, and `AccountsSnapshots_BankAccount-393561`. (Tier 3 — no upstream wiki, grounded in DDL + SP code) |
| 3 | @FileName | varchar(max) | YES | Source XML file name from the Tribe export. Follows the pattern `accounts-snapshots-{version}-{AccountID}-{Date}-SubFile-{N}.xml`. Referenced in `SP_eMoney_Reconciliation_ETLs` as the `FileName` column in the Card Snapshot ETL. (Tier 3 — no upstream wiki, grounded in DDL + SP code) |
| 4 | etr_y | varchar(max) | YES | ETL year partition key. Appears consistently NULL across all sampled rows. Likely a reserved or deprecated partitioning column from the Generic Pipeline. (Tier 3 — no upstream wiki, grounded in DDL + live data sample) |
| 5 | etr_ym | varchar(max) | YES | ETL year-month partition key. Appears consistently NULL across all sampled rows. Likely a reserved or deprecated partitioning column from the Generic Pipeline. (Tier 3 — no upstream wiki, grounded in DDL + live data sample) |
| 6 | etr_ymd | varchar(max) | YES | ETL year-month-day partition key. Appears consistently NULL across all sampled rows. Likely a reserved or deprecated partitioning column from the Generic Pipeline. (Tier 3 — no upstream wiki, grounded in DDL + live data sample) |
| 7 | SynapseUpdateDate | datetime | YES | Timestamp of when the row was loaded or last updated in Synapse by the Generic Pipeline. Observed lag of 2–5 hours from `@Created`. (Tier 3 — no upstream wiki, grounded in DDL + live data sample) |
| 8 | partition_date | date | YES | Date-level partition key derived from the record date. Matches the date component of `@Created`. Indexed (NCI) for efficient date-range queries. (Tier 3 — no upstream wiki, grounded in DDL + live data sample) |
| 9 | Created | datetime2(7) | YES | Record creation timestamp. On historical/backfilled rows, this may be set to the Synapse load date rather than the original XML timestamp (observed: many rows show `Created = 2023-12-20` regardless of `@Created` value). For recent data, typically matches `@Created`. (Tier 3 — no upstream wiki, grounded in DDL + live data sample) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| @Created | Tribe XML file | @Created | Passthrough |
| @Id | Tribe XML file | @Id | Passthrough |
| @FileName | Tribe XML file | @FileName | Passthrough |
| etr_y | Generic Pipeline | etr_y | Partition key (unused) |
| etr_ym | Generic Pipeline | etr_ym | Partition key (unused) |
| etr_ymd | Generic Pipeline | etr_ymd | Partition key (unused) |
| SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Load timestamp |
| partition_date | Generic Pipeline | partition_date | Derived date partition |
| Created | Tribe XML file / Generic Pipeline | Created | Record timestamp |

### 5.2 ETL Pipeline

```
Tribe Card-Issuing Platform (eMoney XML exports)
  |-- XML files: accounts-snapshots-{version}-{AccountID}-{Date}-SubFile-{N}.xml
  v
Generic Pipeline (Tribe XML ingestion → Synapse landing)
  v
eMoney_Tribe.AccountsSnapshots-509416 (1.5B rows, raw landing)
  |-- JOIN on @Id with sub-tables ---|
  v
#AccountsSnapshots (temp table in SP_eMoney_Reconciliation_ETLs)
  |-- JOIN with AccountsSnapshots_BankAccount-393561 ---|
  v
#Final (temp table)
  |-- INSERT INTO (incremental, DISTINCT) ---|
  v
eMoney_dbo.ETL_AccountSnapshot (reconciliation output)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No outbound FKs. Raw landing table with no dimensional joins. |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| @Id | `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` | Reader — uses `@Id` as join key with sub-tables to build Account Snapshot ETL |
| @Id | `eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050` | Sub-table joined on `@Id` for account detail |
| @Id | `eMoney_Tribe.AccountsSnapshots_BankAccounts-795870` | Sub-table joined on `@Id` for bank accounts list |
| — | `DE_dbo.NewSBUpdateStatsBigTables` | Statistics maintenance only |

---

## 7. Sample Queries

### 7.1 Daily Ingestion Volume (Date-Filtered)

```sql
SELECT partition_date, COUNT(*) AS record_count
FROM [eMoney_Tribe].[AccountsSnapshots-509416]
WHERE partition_date >= '2026-04-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.2 Check Ingestion Lag Between Source and Synapse Load

```sql
SELECT TOP 50
    [@Created] AS source_timestamp,
    SynapseUpdateDate AS synapse_load,
    DATEDIFF(MINUTE, [@Created], SynapseUpdateDate) AS lag_minutes
FROM [eMoney_Tribe].[AccountsSnapshots-509416]
WHERE partition_date = '2026-04-25'
ORDER BY [@Created] DESC;
```

### 7.3 Join With Sub-Tables for Full Account Snapshot

```sql
SELECT TOP 10
    aa.[@FileName],
    aaa.AccountId,
    aaa.HolderId,
    aaa.AvailableBalance,
    aaa.AccountStatus,
    aaa.[@Created] AS snapshot_created
FROM [eMoney_Tribe].[AccountsSnapshots-509416] aa
JOIN [eMoney_Tribe].[AccountsSnapshots_AccountSnapshot-956050] aaa ON aa.[@Id] = aaa.[@Id]
WHERE aa.partition_date >= '2026-04-01';
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 9 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 6/10, Lineage: 7/10*
*Object: eMoney_Tribe.AccountsSnapshots-509416 | Type: Table | Production Source: Tribe XML ingestion (dormant — no upstream wiki)*
