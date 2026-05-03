# eMoney_Tribe.AccountsSnapshots_BankAccounts-795870

> 1.52B-row raw Tribe platform landing table storing bank account association records from eToro Money account snapshots, spanning 2023-12-20 to 2026-04-26. Loaded via Tribe API data pipeline. Production source is the Tribe platform's AccountsSnapshots BankAccounts entity. Used downstream by SP_eMoney_Reconciliation_ETLs as a bridge to link account snapshots to bank account data.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | Tribe Platform API (BankAccounts entity under AccountsSnapshots) |
| **Refresh** | Continuous via Tribe data pipeline |
| **Synapse Distribution** | HASH([@Id]) |
| **Synapse Index** | CLUSTERED INDEX ([@Id] ASC), NCI on partition_date |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a raw data landing zone for the eToro Money (eMoney) Tribe platform's **BankAccounts** entity, nested under **AccountsSnapshots**. It captures the association between account snapshot records and their related bank account information.

The table contains approximately **1.52 billion rows** spanning from **2023-12-20 to 2026-04-26**, partitioned by `partition_date`. Each row represents a bank-account-level record within an account snapshot, identified by a UUID (`@Id`).

The table naming convention follows the Tribe platform pattern: `{EntityGroup}_{SubEntity}-{NumericId}`. The numeric suffix `795870` is the Tribe-internal entity identifier.

In practice, this table functions as a **bridge/link table** — it contains no bank account business attributes itself (those reside in related Tribe tables like `AccountsSnapshots_BankAccount-393561`). It is consumed by `SP_eMoney_Reconciliation_ETLs` which LEFT JOINs it to `AccountsSnapshots_AccountSnapshot-956050` to identify which account snapshots have associated bank accounts, then further joins to `AccountsSnapshots_BankAccount-393561` for the actual bank account detail columns.

The `etr_y`, `etr_ym`, and `etr_ymd` columns are ETL date-partitioning fields that are mostly empty in practice — only a small fraction of early records (around 2023-12 / 2024-01) have values populated.

---

## 2. Business Logic

### 2.1 Bridge/Link Role

**What**: This table serves as a bridge connecting account snapshots to bank account details.
**Columns Involved**: `@Id`, `@AccountsSnapshots_AccountSnapshot@Id-956050`
**Rules**:
- `@Id` and `@AccountsSnapshots_AccountSnapshot@Id-956050` are always identical (100% match observed in live data), indicating a 1:1 relationship between this bridge record and its parent account snapshot
- The table itself carries no bank account attributes — those are in sibling Tribe tables joined via `@Id`

### 2.2 ETL Date Partition Fields

**What**: The `etr_y/etr_ym/etr_ymd` columns are Tribe-standard ETL date partition fields.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- These fields are largely empty (empty string, not NULL) for the majority of records
- When populated, they contain year (`2024`), year-month (`2024-01`), and year-month-day (`2024-01-01`) string representations
- Only early data (around Dec 2023 / Jan 2024) shows populated values; subsequent data has these fields empty

### 2.3 Partition Strategy

**What**: The table is partitioned by `partition_date` for efficient date-range queries.
**Columns Involved**: `partition_date`, `Created`
**Rules**:
- `partition_date` aligns with the date portion of `Created`
- A non-clustered index on `partition_date` supports date-range filtering

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `[@Id]` — efficient for point lookups and joins on the UUID primary key
- **Clustered Index**: `[@Id] ASC` — supports fast lookups and JOIN operations
- **NCI**: `partition_date ASC` — supports date-range scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many bank account associations exist for a date range? | `SELECT COUNT_BIG(1) FROM [eMoney_Tribe].[AccountsSnapshots_BankAccounts-795870] WHERE partition_date BETWEEN @start AND @end` |
| Join to full snapshot data | JOIN on `[@Id]` to `AccountsSnapshots_AccountSnapshot-956050`, then to `AccountsSnapshots_BankAccount-393561` for detail columns |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050 | ON a.[@Id] = b.[@Id] | Parent account snapshot record |
| eMoney_Tribe.AccountsSnapshots_BankAccount-393561 | ON a.[@Id] = c.[@Id] (via SP chain) | Bank account detail attributes |
| eMoney_Tribe.AccountsSnapshots-509416 | ON a.[@Id] = d.[@Id] | Root snapshot file-level metadata |

### 3.4 Gotchas

- **1.52B rows** — this is a very large table. Always filter by `partition_date` to avoid full scans
- `etr_y/etr_ym/etr_ymd` are **mostly empty strings** (not NULL) — do not rely on them for date filtering; use `partition_date` or `Created` instead
- `@Id` and `@AccountsSnapshots_AccountSnapshot@Id-956050` are always identical in practice — the parent FK column is redundant but maintained by the Tribe schema convention
- Column names contain special characters (`@`, `-`) requiring bracket quoting in all SQL: `[@Id]`, `[@AccountsSnapshots_AccountSnapshot@Id-956050]`

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DDL, live data, and SP usage context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(255) | YES | UUID primary key identifying this bank accounts bridge record within an account snapshot. Hash-distributed and clustered index key. Always matches the parent snapshot ID. Used as the JOIN key in SP_eMoney_Reconciliation_ETLs to link snapshots to bank account details. (Tier 3 — Tribe Platform API, no upstream wiki) |
| 2 | @AccountsSnapshots_AccountSnapshot@Id-956050 | varchar(max) | YES | Foreign key referencing the parent AccountsSnapshots_AccountSnapshot-956050 record. In practice, this value is always identical to @Id, establishing a 1:1 relationship between this bridge record and its parent account snapshot. Tribe platform naming convention encodes the parent entity and its numeric ID in the column name. (Tier 3 — Tribe Platform API, no upstream wiki) |
| 3 | etr_y | varchar(max) | YES | ETL year partition field from the Tribe data pipeline. Contains a 4-digit year string (e.g., '2024') when populated, but is empty string (not NULL) for the vast majority of records. Only early data (Dec 2023 / Jan 2024) has values. (Tier 3 — Tribe Platform API, no upstream wiki) |
| 4 | etr_ym | varchar(max) | YES | ETL year-month partition field from the Tribe data pipeline. Contains a 'YYYY-MM' string (e.g., '2024-01') when populated, but is empty string for most records. (Tier 3 — Tribe Platform API, no upstream wiki) |
| 5 | etr_ymd | varchar(max) | YES | ETL year-month-day partition field from the Tribe data pipeline. Contains a 'YYYY-MM-DD' string (e.g., '2024-01-01') when populated, but is empty string for most records. (Tier 3 — Tribe Platform API, no upstream wiki) |
| 6 | SynapseUpdateDate | datetime | YES | Timestamp indicating when the row was last updated in Synapse by the data pipeline. System-generated metadata column, not sourced from the Tribe API. (Tier 3 — Synapse ETL infrastructure, no upstream wiki) |
| 7 | Created | datetime2(7) | YES | Timestamp of when the record was created in the Tribe platform. Used by SP_eMoney_Reconciliation_ETLs for incremental load filtering (WHERE @Created >= @AccountSnapshot_DATE). High-precision datetime2(7) reflecting Tribe API precision. (Tier 3 — Tribe Platform API, no upstream wiki) |
| 8 | partition_date | date | YES | Date partition key for the table, aligned with the date portion of Created. Indexed (NCI) to support efficient date-range scans on this 1.52B-row table. (Tier 3 — Tribe Platform API / Synapse ETL, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | Tribe Platform API | BankAccounts.@Id | Passthrough |
| @AccountsSnapshots_AccountSnapshot@Id-956050 | Tribe Platform API | Parent entity FK | Passthrough |
| etr_y | Tribe Platform API | etr_y | Passthrough (ETL partition) |
| etr_ym | Tribe Platform API | etr_ym | Passthrough (ETL partition) |
| etr_ymd | Tribe Platform API | etr_ymd | Passthrough (ETL partition) |
| SynapseUpdateDate | Synapse ETL | N/A | System-generated |
| Created | Tribe Platform API | Created | Passthrough |
| partition_date | Tribe Platform API / ETL | Created (date part) | Date extraction |

### 5.2 ETL Pipeline

```
Tribe Platform API (eMoney BankAccounts entity)
  |-- Tribe data pipeline (API-to-Lake export) ---|
  v
Azure Data Lake (raw Tribe snapshots)
  |-- Generic Pipeline (Lake-to-Synapse load) ---|
  v
eMoney_Tribe.AccountsSnapshots_BankAccounts-795870 (1.52B rows, HASH @Id)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN on @Id) ---|
  v
eMoney_dbo.ETL_AccountSnapshot (reconciliation target)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @AccountsSnapshots_AccountSnapshot@Id-956050 | eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050 | Parent account snapshot record (1:1 via @Id) |

### 6.2 Referenced By (other objects point to this)

| Element | Referencing Object | Description |
|---|---|---|
| @Id | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | LEFT JOIN to identify snapshots with bank account associations |
| @Id | eMoney_Tribe.AccountsSnapshots_BankAccount-393561 | Child bank account detail records (via SP join chain) |

---

## 7. Sample Queries

### 7.1 Count Bank Account Associations by Date

```sql
SELECT partition_date, COUNT_BIG(1) AS record_count
FROM [eMoney_Tribe].[AccountsSnapshots_BankAccounts-795870]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.2 Join to Full Account Snapshot with Bank Account Details

```sql
SELECT
    snap.AccountId,
    snap.HolderId,
    snap.AvailableBalance,
    bank.BankAccountIban,
    bank.BankAccountStatus
FROM [eMoney_Tribe].[AccountsSnapshots_AccountSnapshot-956050] snap
INNER JOIN [eMoney_Tribe].[AccountsSnapshots_BankAccounts-795870] bridge
    ON bridge.[@Id] = snap.[@Id]
LEFT JOIN [eMoney_Tribe].[AccountsSnapshots_BankAccount-393561] bank
    ON bank.[@Id] = bridge.[@Id]
WHERE snap.[@Created] >= '2026-04-01';
```

### 7.3 Check ETL Partition Field Population Rate

```sql
SELECT
    CASE WHEN etr_ymd = '' OR etr_ymd IS NULL THEN 'Empty' ELSE 'Populated' END AS etr_status,
    COUNT_BIG(1) AS cnt
FROM [eMoney_Tribe].[AccountsSnapshots_BankAccounts-795870]
WHERE partition_date >= '2026-01-01'
GROUP BY CASE WHEN etr_ymd = '' OR etr_ymd IS NULL THEN 'Empty' ELSE 'Populated' END;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this raw Tribe landing table.

---

*Generated: 2026-04-30 | Quality: 6/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 8 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 6/10, Lineage: 6/10*
*Object: eMoney_Tribe.AccountsSnapshots_BankAccounts-795870 | Type: Table | Production Source: Tribe Platform API (dormant/no upstream wiki)*
