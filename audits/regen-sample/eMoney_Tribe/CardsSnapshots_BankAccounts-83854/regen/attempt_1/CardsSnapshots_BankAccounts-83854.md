# eMoney_Tribe.CardsSnapshots_BankAccounts-83854

> 86.4M-row raw Tribe data feed table acting as a bridge/collection node in the card snapshot hierarchy, linking card snapshots to individual bank account records. Spans 2023-12-20 to 2026-04-26. Ingested daily via Generic Pipeline (Append strategy) from FiatDwhDB.Tribe on prod-banking. Consumed by SP_eMoney_Reconciliation_ETLs to build ETL_CardSnapshot.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 (prod-banking) — consumed by SP_eMoney_Reconciliation_ETLs |
| **Refresh** | Daily incremental Append via Generic Pipeline (every 1440 min) |
| **Synapse Distribution** | HASH ([@Id]) |
| **Synapse Index** | CLUSTERED INDEX ([@Id] ASC) |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

This table is part of the eToro Money (eMoney) Tribe raw data layer. It serves as an intermediate collection/bridge node in the card snapshot hierarchy:

```
CardsSnapshots-890718 (root snapshot)
  -> CardsSnapshots_Account-513255 (account level)
    -> CardsSnapshots_BankAccounts-83854 (bank accounts collection -- THIS TABLE)
      -> CardsSnapshots_BankAccount-341626 (individual bank account details)
```

Each row represents a bank accounts collection record linked to a card snapshot account via the parent table `CardsSnapshots_Account-513255`. The table contains 86.4M rows spanning from 2023-12-20 to 2026-04-26.

Data originates from the Tribe card issuer/processor platform (prod-banking server, FiatDwhDB database) and is ingested daily via the Generic Pipeline with Append strategy. The stored procedure `SP_eMoney_Reconciliation_ETLs` reads from this table using a LEFT JOIN on `@Id` to connect the card snapshot chain to individual bank account records in `CardsSnapshots_BankAccount-341626`, ultimately building the `eMoney_dbo.ETL_CardSnapshot` reconciliation table.

In sampled data, `@Id` and `@CardsSnapshots_Account@Id-513255` are always identical, indicating a 1:1 relationship between this collection node and its parent account record. The `etr_y`, `etr_ym`, `etr_ymd` columns are ETL partition markers that were populated for early data (2023-12) but are empty strings for 2024+ records, suggesting a pipeline or schema change.

---

## 2. Business Logic

### 2.1 Bridge Table Pattern

**What**: This table acts as a structural bridge in the Tribe JSON-to-relational mapping, connecting account-level snapshots to individual bank account detail records.
**Columns Involved**: `@Id`, `@CardsSnapshots_Account@Id-513255`
**Rules**:
- `@Id` is the primary identifier for the bank accounts collection
- `@CardsSnapshots_Account@Id-513255` is the FK to the parent `CardsSnapshots_Account-513255` table
- In all sampled data, `@Id` = `@CardsSnapshots_Account@Id-513255` (1:1 relationship)
- The child table `CardsSnapshots_BankAccount-341626` references this table via `@CardsSnapshots_BankAccounts@Id-83854`

### 2.2 ETL Partition Markers

**What**: Date decomposition columns populated by the Generic Pipeline during ingestion.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- `etr_y` = year (e.g. "2023"), `etr_ym` = year-month (e.g. "2023-12"), `etr_ymd` = year-month-day (e.g. "2023-12-20")
- Populated for 2023-12 data but empty strings for 2024+ records
- Not consumed by any downstream SP; used for pipeline partitioning only

### 2.3 SP Reconciliation Consumption

**What**: SP_eMoney_Reconciliation_ETLs reads this table to bridge card snapshot data to bank account details.
**Columns Involved**: `@Id`
**Rules**:
- LEFT JOINed on `ae.[@Id] = ad.[@Id]` (from the card snapshot chain)
- Then `CardsSnapshots_BankAccount-341626` is LEFT JOINed on `af.[@CardsSnapshots_BankAccounts@Id-83854] = ae.[@Id]`
- Only `@Id` is used from this table; it serves purely as a join bridge

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH on `@Id` — co-located with the card snapshot chain JOINs
- **Clustered Index**: `@Id` ASC — optimized for PK lookups and JOIN operations
- **NCI**: `XI_partition_date` on `partition_date` — for date-filtered queries

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Bank accounts for a specific snapshot | Filter on `@Id` (uses clustered index + distribution key) |
| Recent records by date | Filter on `partition_date >= 'YYYY-MM-DD'` (uses NCI) |
| Full card snapshot with bank accounts | JOIN through the hierarchy: CardsSnapshots-890718 -> Account-513255 -> this table -> BankAccount-341626 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| CardsSnapshots_Account-513255 | `@CardsSnapshots_Account@Id-513255 = [@Id]` | Parent account linkage |
| CardsSnapshots_BankAccount-341626 | `[@CardsSnapshots_BankAccounts@Id-83854] = [@Id]` | Child bank account details |
| SP_eMoney_Reconciliation_ETLs (#Final) | `ae.[@Id] = ad.[@Id]` | Reconciliation pipeline bridge |

### 3.4 Gotchas

- **86.4M rows**: Large table — always filter on `partition_date` or `@Id` to avoid full scans
- **Column naming**: `@` prefix and numeric suffixes (e.g. `-83854`, `-513255`) are Tribe platform conventions for JSON-to-relational mapping; they are NOT decorators
- **etr_* columns inconsistency**: Populated for 2023-12 data only; empty strings (not NULL) for 2024+ records
- **1:1 relationship**: Despite being a "collection" table, `@Id` = `@CardsSnapshots_Account@Id-513255` in all data, suggesting each account has exactly one bank accounts collection
- **All varchar types**: `@Id` is varchar(255), `@CardsSnapshots_Account@Id-513255` is varchar(max) — no GUID type enforcement at the storage layer despite containing GUIDs

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from DDL, data samples, and SP context — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(255) | YES | PK. Referenced by BankAccount-341626. Distribution key and clustered index. Contains GUIDs (e.g. "6381bdf9-108b-4554-b8a2-bd94f1ad2fad"). In sampled data, always equals @CardsSnapshots_Account@Id-513255. (Tier 1 — Tribe.CardsSnapshots_BankAccounts-83854) |
| 2 | @CardsSnapshots_Account@Id-513255 | varchar(max) | YES | Foreign key to the parent table CardsSnapshots_Account-513255. Links this bank accounts collection record to its parent account-level snapshot. Contains GUIDs identical to @Id in all sampled data. The production schema uses @CardsSnapshots@Id-890718 (FK to root) instead; this Synapse-specific column points to the intermediate Account-513255 level. (Tier 3 — no matching production column; Synapse-specific FK) |
| 3 | etr_y | varchar(max) | YES | ETL partition year marker populated by the Generic Pipeline during ingestion (e.g. "2023"). Populated for 2023-12 data, empty string for 2024+ records. Not consumed by downstream SPs. (Tier 3 — Generic Pipeline) |
| 4 | etr_ym | varchar(max) | YES | ETL partition year-month marker populated by the Generic Pipeline during ingestion (e.g. "2023-12"). Populated for 2023-12 data, empty string for 2024+ records. Not consumed by downstream SPs. (Tier 3 — Generic Pipeline) |
| 5 | etr_ymd | varchar(max) | YES | ETL partition year-month-day marker populated by the Generic Pipeline during ingestion (e.g. "2023-12-20"). Populated for 2023-12 data, empty string for 2024+ records. Not consumed by downstream SPs. (Tier 3 — Generic Pipeline) |
| 6 | SynapseUpdateDate | datetime | YES | Timestamp when the record was last updated/ingested into Synapse by the Generic Pipeline. (Tier 3 — Generic Pipeline) |
| 7 | Created | datetime2(7) | YES | Source timestamp. Used by SP_eMoney_Reconciliation_ETLs as part of the incremental load watermark (MAX(Created)) in the card snapshot reconciliation pipeline. (Tier 1 — Tribe.CardsSnapshots_BankAccounts-83854) |
| 8 | partition_date | date | YES | Partition date for the record, derived from the ingestion date. Indexed (XI_partition_date NCI) for efficient date-range queries. (Tier 3 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 | @Id | Passthrough |
| @CardsSnapshots_Account@Id-513255 | (Synapse-specific) | N/A | Synapse FK to Account-513255; production has @CardsSnapshots@Id-890718 instead |
| etr_y | Generic Pipeline | etr_y | Pipeline partition marker |
| etr_ym | Generic Pipeline | etr_ym | Pipeline partition marker |
| etr_ymd | Generic Pipeline | etr_ymd | Pipeline partition marker |
| SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Ingestion timestamp |
| Created | FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 | Created | Passthrough |
| partition_date | Generic Pipeline | partition_date | Derived partition date |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 (prod-banking)
  |-- Generic Pipeline (Append, daily, parquet) ---|
  v
eMoney_Tribe.CardsSnapshots_BankAccounts-83854 (86.4M rows, raw bridge table)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN on @Id) ---|
  v
#Final temp table (enriched with BankAccount-341626 columns)
  |-- INSERT INTO ---|
  v
eMoney_dbo.ETL_CardSnapshot (reconciliation output)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_cardssnapshots_bankaccounts-83854 (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @CardsSnapshots_Account@Id-513255 | eMoney_Tribe.CardsSnapshots_Account-513255 | FK to parent account-level snapshot |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_Tribe.CardsSnapshots_BankAccount-341626 | Child table joins via @CardsSnapshots_BankAccounts@Id-83854 |
| @Id | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | SP reads this table as a JOIN bridge to BankAccount-341626 |
| (DDL clone) | eMoney_Tribe_tmp.CardsSnapshots_BankAccounts-83854_tmp | Temp staging table with identical schema |

---

## 7. Sample Queries

### 7.1 Recent Records by Partition Date

```sql
SELECT TOP 100
    [@Id],
    [@CardsSnapshots_Account@Id-513255],
    etr_y, etr_ym, etr_ymd,
    SynapseUpdateDate,
    Created,
    partition_date
FROM [eMoney_Tribe].[CardsSnapshots_BankAccounts-83854]
WHERE partition_date >= '2026-04-01'
ORDER BY Created DESC
```

### 7.2 Join to Child Bank Account Details

```sql
SELECT TOP 50
    ba.[@Id],
    ba.[@CardsSnapshots_Account@Id-513255],
    bd.BankAccountNumber,
    bd.BankAccountIban,
    bd.BankAccountBic,
    bd.BankAccountStatus
FROM [eMoney_Tribe].[CardsSnapshots_BankAccounts-83854] ba
INNER JOIN [eMoney_Tribe].[CardsSnapshots_BankAccount-341626] bd
    ON bd.[@CardsSnapshots_BankAccounts@Id-83854] = ba.[@Id]
WHERE ba.partition_date >= '2026-04-01'
ORDER BY ba.Created DESC
```

### 7.3 Verify 1:1 Relationship Between @Id and Parent FK

```sql
SELECT COUNT(*) AS total,
       SUM(CASE WHEN [@Id] = [@CardsSnapshots_Account@Id-513255] THEN 1 ELSE 0 END) AS matching,
       SUM(CASE WHEN [@Id] <> [@CardsSnapshots_Account@Id-513255] THEN 1 ELSE 0 END) AS mismatched
FROM [eMoney_Tribe].[CardsSnapshots_BankAccounts-83854]
WHERE partition_date >= '2026-04-01'
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this raw Tribe ingestion table. The SP header references Freshservice change request #20353.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 11/14*
*Tiers: 2 T1, 0 T2, 6 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 3/10, Lineage: complete*
*Object: eMoney_Tribe.CardsSnapshots_BankAccounts-83854 | Type: Table | Production Source: FiatDwhDB.Tribe.CardsSnapshots_BankAccounts-83854 (prod-banking)*
