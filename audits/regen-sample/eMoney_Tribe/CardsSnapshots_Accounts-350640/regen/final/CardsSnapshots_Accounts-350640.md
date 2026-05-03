# eMoney_Tribe.CardsSnapshots_Accounts-350640

> 86.2M-row raw Tribe data ingestion table storing account-level linkage records from the eToro Money card snapshot hierarchy. Sourced daily from `FiatDwhDB.Tribe` on `prod-banking` via Generic Pipeline (Append). Data spans 2023-12-20 to present. Serves as a structural JOIN bridge in `SP_eMoney_Reconciliation_ETLs` linking `CardsSnapshots_CardSnapshot-140457` to `CardsSnapshots_Account-513255`.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640 (prod-banking) |
| **Refresh** | Daily (Append, 1440 min) via Generic Pipeline |
| **Synapse Distribution** | HASH([@Id]) |
| **Synapse Index** | CLUSTERED INDEX ([@Id] ASC), NCI on partition_date, NCI on @Id |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export |

---

## 1. Business Meaning

`CardsSnapshots_Accounts-350640` is a raw ingestion table in the `eMoney_Tribe` schema, part of the eToro Money card snapshot data hierarchy. It contains 86.2 million rows spanning from December 2023 to present.

This table acts as a **structural bridge** between the card-level snapshot table (`CardsSnapshots_CardSnapshot-140457`) and the account-level detail table (`CardsSnapshots_Account-513255`). It does not carry business-payload columns itself; its primary purpose is to provide the `@Id` join key that links card snapshots to their associated account records.

The data originates from the Tribe payments platform (FiatDwhDB on `prod-banking`) and is ingested daily via the Generic Pipeline using an Append copy strategy. The ETL procedure `SP_eMoney_Reconciliation_ETLs` consumes this table by LEFT JOINing it to assemble the full card snapshot reconciliation view that populates `ETL_CardSnapshot`.

The `etr_y`, `etr_ym`, and `etr_ymd` columns are ETL-generated partition fields added by the Generic Pipeline framework. Some rows have empty strings in these fields (observed in sampling), indicating records ingested before the partition scheme was fully applied or records with missing work dates.

---

## 2. Business Logic

### 2.1 JOIN Bridge Role

**What**: This table exists solely to relay the `@Id` key between the card snapshot and account entities in the Tribe data model.
**Columns Involved**: `@Id`, `@CardsSnapshots_CardSnapshot@Id-140457`
**Rules**:
- `@Id` is the primary key shared across all tables in the CardsSnapshots hierarchy
- `@CardsSnapshots_CardSnapshot@Id-140457` is a foreign key reference back to the parent `CardsSnapshots_CardSnapshot-140457` table
- In `SP_eMoney_Reconciliation_ETLs`, this table is LEFT JOINed: `LEFT JOIN CardsSnapshots_Accounts-350640 ac ON ac.[@Id] = ab.[@Id]`, then `LEFT JOIN CardsSnapshots_Account-513255 ad ON ad.[@Id] = ac.[@Id]`

### 2.2 ETL Date Partitioning

**What**: The Generic Pipeline adds date-decomposed partition columns for incremental processing.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`, `partition_date`
**Rules**:
- `etr_y` = year string (e.g. "2023")
- `etr_ym` = year-month string (e.g. "2023-12")
- `etr_ymd` = full date string (e.g. "2023-12-20")
- `partition_date` = date type partition key
- Some rows have empty strings for `etr_y`/`etr_ym`/`etr_ymd` (observed in sample data from 2024-06 and 2024-08), indicating records ingested without complete metadata

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `[@Id]` — queries filtering or joining on `@Id` benefit from data locality
- **Clustered Index**: On `[@Id]` — efficient for point lookups and range scans on the primary key
- **NCI on `partition_date`**: Use for date-range filtered queries to avoid full table scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many account records exist for a date range? | `SELECT COUNT(*) FROM [eMoney_Tribe].[CardsSnapshots_Accounts-350640] WHERE partition_date BETWEEN @start AND @end` |
| Find account linkage for a specific card snapshot | `SELECT * FROM [eMoney_Tribe].[CardsSnapshots_Accounts-350640] WHERE [@Id] = '<uuid>'` |
| Check data freshness | `SELECT MAX(partition_date), MAX(SynapseUpdateDate) FROM [eMoney_Tribe].[CardsSnapshots_Accounts-350640]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| `eMoney_Tribe.CardsSnapshots_CardSnapshot-140457` | `ON CardSnapshot.[@Id] = Accounts.[@Id]` | Link to card-level snapshot details |
| `eMoney_Tribe.CardsSnapshots_Account-513255` | `ON Account.[@Id] = Accounts.[@Id]` | Resolve account-level detail columns (AccountId, AccountStatus, balances) |
| `eMoney_Tribe.CardsSnapshots-890718` | `ON Snapshots.[@Id] = Accounts.[@Id]` | Access file-level metadata |

### 3.4 Gotchas

- **86M+ rows**: This is a large table. Always use `partition_date` or `@Id` filters. Never run unfiltered `GROUP BY` or `COUNT(DISTINCT)`.
- **Empty ETL columns**: Some rows have empty strings (`''`) in `etr_y`, `etr_ym`, `etr_ymd` — filter on `partition_date` (date type) instead for reliable date filtering.
- **`@` prefixed column names**: Column names with `@` require bracket quoting in all queries: `[@Id]`, `[@CardsSnapshots_CardSnapshot@Id-140457]`.
- **varchar(max) columns**: Most columns are `varchar(max)`, preventing them from being used in indexes or efficient JOINs beyond `@Id`.
- **No direct business payload**: This table carries no business data (no amounts, statuses, or customer attributes). It is purely a relational bridge.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DDL, SP usage context, and live data sampling |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(255) | YES | Unique identifier (UUID) for the card snapshot record. Serves as the HASH distribution key and clustered index. Used as the primary JOIN key across all CardsSnapshots hierarchy tables in SP_eMoney_Reconciliation_ETLs. (Tier 3 — no upstream wiki; grounded in DDL + SP JOIN pattern) |
| 2 | @CardsSnapshots_CardSnapshot@Id-140457 | varchar(max) | YES | Foreign key reference to the parent CardsSnapshots_CardSnapshot-140457 table. In sampled data, this value is identical to @Id, indicating a 1:1 relationship between the account linkage record and its parent card snapshot. (Tier 3 — no upstream wiki; grounded in DDL naming convention + live data sampling) |
| 3 | etr_y | varchar(max) | YES | ETL partition column representing the year component of the record date (e.g. "2023"). Added by the Generic Pipeline framework. May contain empty strings for some records. (Tier 3 — no upstream wiki; grounded in DDL + Generic Pipeline convention + live data sampling) |
| 4 | etr_ym | varchar(max) | YES | ETL partition column representing the year-month component of the record date (e.g. "2023-12"). Added by the Generic Pipeline framework. May contain empty strings for some records. (Tier 3 — no upstream wiki; grounded in DDL + Generic Pipeline convention + live data sampling) |
| 5 | etr_ymd | varchar(max) | YES | ETL partition column representing the full date of the record (e.g. "2023-12-20"). Added by the Generic Pipeline framework. May contain empty strings for some records. (Tier 3 — no upstream wiki; grounded in DDL + Generic Pipeline convention + live data sampling) |
| 6 | SynapseUpdateDate | datetime | YES | Timestamp indicating when the row was last synchronized to Synapse by the Generic Pipeline. (Tier 3 — no upstream wiki; grounded in DDL + standard Generic Pipeline metadata column) |
| 7 | Created | datetime2(7) | YES | Timestamp indicating when the source record was created in the Tribe platform. Used by SP_eMoney_Reconciliation_ETLs as the incremental watermark for the card snapshot ETL process. (Tier 3 — no upstream wiki; grounded in DDL + SP incremental load pattern) |
| 8 | partition_date | date | YES | Date partition key used for incremental data loading and efficient querying. Has a dedicated nonclustered index (XI_partition_date). (Tier 3 — no upstream wiki; grounded in DDL index definition + Generic Pipeline convention) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | FiatDwhDB.Tribe | @Id | Passthrough |
| @CardsSnapshots_CardSnapshot@Id-140457 | FiatDwhDB.Tribe | @CardsSnapshots_CardSnapshot@Id-140457 | Passthrough |
| etr_y | Generic Pipeline | — | ETL-generated year partition |
| etr_ym | Generic Pipeline | — | ETL-generated year-month partition |
| etr_ymd | Generic Pipeline | — | ETL-generated full date partition |
| SynapseUpdateDate | Generic Pipeline | — | Synapse sync timestamp |
| Created | FiatDwhDB.Tribe | Created | Passthrough |
| partition_date | Generic Pipeline | — | Date partition key |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.CardsSnapshots_Accounts-350640 (prod-banking)
  |-- Generic Pipeline (Bronze, Append, daily, parquet) --|
  v
Bronze/FiatDwhDB/Tribe/CardsSnapshots_Accounts-350640/ (Data Lake)
  |-- Generic Pipeline (Synapse load) --|
  v
eMoney_Tribe.CardsSnapshots_Accounts-350640 (86.2M rows, Synapse)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN bridge) --|
  v
eMoney_dbo.ETL_CardSnapshot (reconciliation output)
  |-- Generic Pipeline (Bronze export) --|
  v
emoney.bronze_fiatdwhdb_tribe_cardssnapshots_accounts-350640 (UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_Tribe.CardsSnapshots_CardSnapshot-140457 | Shared key — links to parent card snapshot record |
| @CardsSnapshots_CardSnapshot@Id-140457 | eMoney_Tribe.CardsSnapshots_CardSnapshot-140457 | FK reference to parent card snapshot |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_Tribe.CardsSnapshots_Account-513255 | Account detail table joins through this bridge on @Id |
| — | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | Reads this table as LEFT JOIN bridge to assemble ETL_CardSnapshot |

---

## 7. Sample Queries

### 7.1 Check Data Volume by Month

```sql
SELECT
    partition_date,
    COUNT(*) AS row_count
FROM [eMoney_Tribe].[CardsSnapshots_Accounts-350640]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date DESC
```

### 7.2 Verify Account Linkage for a Specific Card Snapshot

```sql
SELECT
    ac.[@Id],
    ac.[@CardsSnapshots_CardSnapshot@Id-140457],
    ac.Created,
    ad.AccountId,
    ad.AccountStatus,
    ad.AvailableBalance
FROM [eMoney_Tribe].[CardsSnapshots_Accounts-350640] ac
LEFT JOIN [eMoney_Tribe].[CardsSnapshots_Account-513255] ad ON ad.[@Id] = ac.[@Id]
WHERE ac.[@Id] = '<uuid>'
```

### 7.3 Check Data Freshness and Empty Partition Fields

```sql
SELECT
    MAX(partition_date) AS latest_partition,
    MAX(SynapseUpdateDate) AS latest_sync,
    SUM(CASE WHEN etr_ymd = '' OR etr_ymd IS NULL THEN 1 ELSE 0 END) AS empty_etr_count,
    COUNT(*) AS total_rows
FROM [eMoney_Tribe].[CardsSnapshots_Accounts-350640]
WHERE partition_date >= '2026-04-01'
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this raw Tribe ingestion table.

---

*Generated: 2026-04-30 | Quality: 6.5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 8 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 6/10, Lineage: 7/10*
*Object: eMoney_Tribe.CardsSnapshots_Accounts-350640 | Type: Table | Production Source: FiatDwhDB.Tribe (prod-banking)*
