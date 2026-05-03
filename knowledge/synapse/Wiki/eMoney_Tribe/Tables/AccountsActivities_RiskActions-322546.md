# eMoney_Tribe.AccountsActivities_RiskActions-322546

> 29.8M-row raw eMoney Tribe table capturing risk action flags applied to account activities on the eMoney (Modulr) card management platform, spanning 2023-12-20 to present. Ingested via generic data lake pipeline; consumed by `SP_eMoney_Reconciliation_ETLs` to build `ETL_AccountsActivities`. No production source wiki available — this is a raw API/XML ingestion table.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | eMoney (Modulr) card management platform — raw data lake ingestion (no SP writer; generic pipeline) |
| **Refresh** | Incremental via generic data lake pipeline; consumed by `SP_eMoney_Reconciliation_ETLs` |
| **Synapse Distribution** | HASH([@Id]) |
| **Synapse Index** | HEAP with 4 NCIs: `ClusteredIndex_AA_322546_Id` ([@Id]), `ClusteredIndex_AA_322546_c2` ([@AccountsActivities_AccountActivity@Id-833937]), `XI_partition_date` (partition_date), `idx_322546_Id` ([@Id]) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table stores risk action decisions from the eMoney (Modulr) card management platform's real-time risk engine. Each row represents the set of risk actions evaluated for a single account activity (transaction). The risk actions are boolean flags indicating whether the risk engine decided to mark the transaction as suspicious, notify the cardholder, change card/account status, or reject the transaction outright.

The table contains ~29.8M rows spanning from 2023-12-20 to 2026-04-26. In practice, the vast majority of rows have all flags set to `0` (no risk action taken). The `MarkTransactionAsSuspicious` flag is triggered on ~0.08% of recent transactions (6,006 out of 7.2M in 2026). `ChangeCardStatusToRisk` is extremely rare (2 rows in 2026). `RejectTransaction` shows zero activations in the 2026 sample.

The table is a child in the `AccountsActivities` hierarchy: it is joined to `AccountsActivities_AccountActivity-833937` via `[@Id]` and consumed by `SP_eMoney_Reconciliation_ETLs` which LEFT JOINs it to build the denormalized `ETL_AccountsActivities` reconciliation table.

Data is ingested from the eMoney data lake as raw API/XML extracts. The `etr_y`, `etr_ym`, `etr_ymd` columns are extraction-time partition keys. Two columns (`ChangeAccountStatusToReceiveOnly`, `ChangeAccountStatusToSpendOnly`) were added to the schema after initial deployment and are NULL/empty in older records.

---

## 2. Business Logic

### 2.1 Risk Action Boolean Flags

**What**: Each risk action column represents a binary decision (0 or 1) from the eMoney platform's real-time risk engine.
**Columns Involved**: `MarkTransactionAsSuspicious`, `NotifyCardholderBySendingTAIsNotification`, `ChangeCardStatusToRisk`, `ChangeAccountStatusToSuspended`, `RejectTransaction`, `ChangeAccountStatusToReceiveOnly`, `ChangeAccountStatusToSpendOnly`
**Rules**:
- `0` = risk action was NOT applied to this transaction
- `1` = risk action WAS applied
- Multiple flags can be set simultaneously for the same transaction
- All columns are stored as `varchar(max)` despite being boolean in nature

### 2.2 Record Identity and Hierarchy

**What**: Each risk action record is linked to its parent account activity via a shared GUID.
**Columns Involved**: `@Id`, `@AccountsActivities_AccountActivity@Id-833937`
**Rules**:
- `@Id` is a GUID that uniquely identifies this risk action record
- `@AccountsActivities_AccountActivity@Id-833937` is the FK to the parent `AccountsActivities_AccountActivity-833937` table
- In the sampled data, `@Id` and the parent FK carry the same GUID value, indicating a 1:1 relationship

### 2.3 Extraction Time Partitioning

**What**: The `etr_*` columns record when the data was extracted from the source system.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- `etr_y` = 4-digit year (e.g., `2023`)
- `etr_ym` = year-month (e.g., `2023-12`)
- `etr_ymd` = full date (e.g., `2023-12-20`)
- These columns may be NULL/empty for some records (observed in 2024+ data)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distributed by HASH on `[@Id]` — optimal for point lookups and joins on `[@Id]`
- HEAP storage (no clustered index) — full scans are unordered
- NCI on `partition_date` enables efficient date-range filtering
- Duplicate NCI on `[@Id]` (`ClusteredIndex_AA_322546_Id` and `idx_322546_Id`) — both serve the same purpose

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many transactions were flagged as suspicious? | `SELECT COUNT(*) FROM ... WHERE MarkTransactionAsSuspicious = '1' AND partition_date >= @start` |
| Which transactions had card status changed to risk? | `SELECT * FROM ... WHERE ChangeCardStatusToRisk = '1' AND partition_date BETWEEN @start AND @end` |
| Daily trend of risk actions | `SELECT partition_date, SUM(CASE WHEN MarkTransactionAsSuspicious='1' THEN 1 ELSE 0 END) FROM ... GROUP BY partition_date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| `eMoney_Tribe.AccountsActivities_AccountActivity-833937` | `ON a.[@Id] = b.[@Id]` | Get full transaction details (amount, currency, holder, etc.) |
| `eMoney_Tribe.AccountsActivities_862157` | Via `AccountActivity-833937` → `862157` on `[@Id]` | Get root activity metadata |
| `eMoney_Tribe.AccountsActivities_SecurityChecks-471048` | `ON a.[@Id] = b.[@Id]` | Combine risk actions with security check results |

### 3.4 Gotchas

- **All columns are varchar(max)**: Risk flag columns store `'0'` and `'1'` as strings, not integers. Use string comparison (`= '1'`) not numeric.
- **NULL vs empty string**: `ChangeAccountStatusToReceiveOnly` and `ChangeAccountStatusToSpendOnly` are empty strings (not NULL) in older rows and `'0'` in newer rows. Filter accordingly.
- **etr_* columns may be NULL**: Extraction partition keys are not always populated — do not rely on them for date filtering. Use `partition_date` instead.
- **29.8M rows**: Always filter by `partition_date` for large scans. Avoid unfiltered `GROUP BY`.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL transform |
| Tier 3 | Grounded in DDL + SP code + live data, no upstream wiki |
| Tier 4 | Inferred from name only (banned in this pipeline) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(40) | YES | GUID primary key identifying this risk action record. Used as the HASH distribution key. Matches the parent AccountActivity record ID in a 1:1 relationship. Indexed by `ClusteredIndex_AA_322546_Id` and `idx_322546_Id`. (Tier 3 — eMoney platform, no upstream wiki) |
| 2 | @AccountsActivities_AccountActivity@Id-833937 | varchar(40) | YES | Foreign key to the parent `AccountsActivities_AccountActivity-833937` table. Links this risk action to its associated account activity transaction. Indexed by `ClusteredIndex_AA_322546_c2`. (Tier 3 — eMoney platform, no upstream wiki) |
| 3 | MarkTransactionAsSuspicious | varchar(max) | YES | Boolean flag (0/1) indicating whether the risk engine marked this transaction as suspicious. In 2026 data: 99.9% are `0`, ~0.08% are `1` (6,006 of 7.2M). Consumed by `SP_eMoney_Reconciliation_ETLs` into `ETL_AccountsActivities`. (Tier 3 — eMoney platform, no upstream wiki) |
| 4 | NotifyCardholderBySendingTAIsNotification | varchar(max) | YES | Boolean flag (0/1) indicating whether the risk engine triggered a Transaction Alert (TAIs) notification to the cardholder for this activity. Consumed by `SP_eMoney_Reconciliation_ETLs` into `ETL_AccountsActivities`. (Tier 3 — eMoney platform, no upstream wiki) |
| 5 | ChangeCardStatusToRisk | varchar(max) | YES | Boolean flag (0/1) indicating whether the risk engine changed the card status to "Risk" for this activity. Extremely rare — only 2 occurrences in 2026 data out of 7.2M rows. Consumed by `SP_eMoney_Reconciliation_ETLs` into `ETL_AccountsActivities`. (Tier 3 — eMoney platform, no upstream wiki) |
| 6 | ChangeAccountStatusToSuspended | varchar(max) | YES | Boolean flag (0/1) indicating whether the risk engine suspended the account in response to this activity. Consumed by `SP_eMoney_Reconciliation_ETLs` into `ETL_AccountsActivities`. (Tier 3 — eMoney platform, no upstream wiki) |
| 7 | RejectTransaction | varchar(max) | YES | Boolean flag (0/1) indicating whether the risk engine rejected this transaction outright. In 2026 data: 100% are `0` (no rejections observed). Consumed by `SP_eMoney_Reconciliation_ETLs` into `ETL_AccountsActivities`. (Tier 3 — eMoney platform, no upstream wiki) |
| 8 | etr_y | varchar(max) | YES | Extraction year partition key from data lake ingestion (e.g., `2023`). May be NULL/empty for some records. (Tier 3 — eMoney data lake pipeline, no upstream wiki) |
| 9 | etr_ym | varchar(max) | YES | Extraction year-month partition key from data lake ingestion (e.g., `2023-12`). May be NULL/empty for some records. (Tier 3 — eMoney data lake pipeline, no upstream wiki) |
| 10 | etr_ymd | varchar(max) | YES | Extraction year-month-day partition key from data lake ingestion (e.g., `2023-12-20`). May be NULL/empty for some records. (Tier 3 — eMoney data lake pipeline, no upstream wiki) |
| 11 | SynapseUpdateDate | datetime | YES | Timestamp of when this record was last loaded or updated in Synapse. Set by the ingestion pipeline at load time. (Tier 3 — Synapse ETL metadata, no upstream wiki) |
| 12 | Created | datetime2(7) | YES | Record creation timestamp from the eMoney platform. Indicates when the risk action evaluation was performed. Used as the incremental load watermark in `SP_eMoney_Reconciliation_ETLs`. Range: 2023-12-20 to present. (Tier 3 — eMoney platform, no upstream wiki) |
| 13 | partition_date | date | YES | Date-level partition key derived from the record creation date. Used for efficient date-range queries. Indexed by `XI_partition_date`. Range: 2023-12-20 to 2026-04-26. (Tier 3 — eMoney data lake pipeline, no upstream wiki) |
| 14 | ChangeAccountStatusToReceiveOnly | varchar(max) | YES | Boolean flag (0/1) indicating whether the risk engine changed the account status to "Receive Only" (can receive funds but cannot spend). Added after initial schema deployment — empty string in older rows, `0` in newer rows. Not currently consumed by `SP_eMoney_Reconciliation_ETLs`. (Tier 3 — eMoney platform, no upstream wiki) |
| 15 | ChangeAccountStatusToSpendOnly | varchar(max) | YES | Boolean flag (0/1) indicating whether the risk engine changed the account status to "Spend Only" (can spend but cannot receive new funds). Added after initial schema deployment — empty string in older rows, `0` in newer rows. Not currently consumed by `SP_eMoney_Reconciliation_ETLs`. (Tier 3 — eMoney platform, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | eMoney (Modulr) platform | @Id | Direct passthrough — GUID from API/XML |
| @AccountsActivities_AccountActivity@Id-833937 | eMoney (Modulr) platform | Parent activity ID | Direct passthrough — FK GUID |
| MarkTransactionAsSuspicious | eMoney (Modulr) risk engine | MarkTransactionAsSuspicious | Direct passthrough — boolean flag |
| NotifyCardholderBySendingTAIsNotification | eMoney (Modulr) risk engine | NotifyCardholderBySendingTAIsNotification | Direct passthrough — boolean flag |
| ChangeCardStatusToRisk | eMoney (Modulr) risk engine | ChangeCardStatusToRisk | Direct passthrough — boolean flag |
| ChangeAccountStatusToSuspended | eMoney (Modulr) risk engine | ChangeAccountStatusToSuspended | Direct passthrough — boolean flag |
| RejectTransaction | eMoney (Modulr) risk engine | RejectTransaction | Direct passthrough — boolean flag |
| etr_y | Data lake pipeline | Extraction year | Partition key from ingestion |
| etr_ym | Data lake pipeline | Extraction year-month | Partition key from ingestion |
| etr_ymd | Data lake pipeline | Extraction year-month-day | Partition key from ingestion |
| SynapseUpdateDate | Synapse ETL | GETDATE() | Set at load time |
| Created | eMoney (Modulr) platform | Created | Direct passthrough — record creation timestamp |
| partition_date | Data lake pipeline | Derived from Created | Date partition key |
| ChangeAccountStatusToReceiveOnly | eMoney (Modulr) risk engine | ChangeAccountStatusToReceiveOnly | Direct passthrough — boolean flag (schema addition) |
| ChangeAccountStatusToSpendOnly | eMoney (Modulr) risk engine | ChangeAccountStatusToSpendOnly | Direct passthrough — boolean flag (schema addition) |

### 5.2 ETL Pipeline

```
eMoney (Modulr) Card Management Platform — Risk Engine API/XML
  |-- Generic Data Lake Pipeline (raw extract) --|
  v
Azure Data Lake (raw files, partitioned by etr_y/etr_ym/etr_ymd)
  |-- Generic Pipeline (lake → Synapse raw) --|
  v
eMoney_Tribe.AccountsActivities_RiskActions-322546 (29.8M rows, HASH [@Id])
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN on [@Id]) --|
  v
#AccountsActivities (temp table, 5 risk flag columns selected)
  |-- INSERT INTO --|
  v
eMoney_dbo.ETL_AccountsActivities (denormalized reconciliation table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @AccountsActivities_AccountActivity@Id-833937 | eMoney_Tribe.AccountsActivities_AccountActivity-833937 | FK to parent account activity record via [@Id] |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Condition | Purpose |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | LEFT JOIN on [@Id] = aaa.[@Id] | Selects 5 risk flag columns into ETL_AccountsActivities |

---

## 7. Sample Queries

### 7.1 Daily Suspicious Transaction Rate

```sql
SELECT
    partition_date,
    COUNT(*) AS total_activities,
    SUM(CASE WHEN MarkTransactionAsSuspicious = '1' THEN 1 ELSE 0 END) AS suspicious_count,
    CAST(SUM(CASE WHEN MarkTransactionAsSuspicious = '1' THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,2)) AS suspicious_pct
FROM [eMoney_Tribe].[AccountsActivities_RiskActions-322546]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.2 Transactions With Any Risk Action Taken

```sql
SELECT r.[@Id], r.partition_date,
    r.MarkTransactionAsSuspicious,
    r.ChangeCardStatusToRisk,
    r.ChangeAccountStatusToSuspended,
    r.RejectTransaction,
    r.ChangeAccountStatusToReceiveOnly,
    r.ChangeAccountStatusToSpendOnly
FROM [eMoney_Tribe].[AccountsActivities_RiskActions-322546] r
WHERE partition_date >= '2026-01-01'
  AND (MarkTransactionAsSuspicious = '1'
    OR ChangeCardStatusToRisk = '1'
    OR ChangeAccountStatusToSuspended = '1'
    OR RejectTransaction = '1'
    OR ChangeAccountStatusToReceiveOnly = '1'
    OR ChangeAccountStatusToSpendOnly = '1');
```

### 7.3 Join Risk Actions With Full Activity Details

```sql
SELECT TOP 100
    act.HolderId, act.AccountId, act.TransactionAmount,
    act.TransactionCurrencyAlpha, act.TransactionCode,
    r.MarkTransactionAsSuspicious, r.ChangeCardStatusToRisk
FROM [eMoney_Tribe].[AccountsActivities_AccountActivity-833937] act
INNER JOIN [eMoney_Tribe].[AccountsActivities_RiskActions-322546] r
    ON act.[@Id] = r.[@Id]
WHERE r.MarkTransactionAsSuspicious = '1'
  AND r.partition_date >= '2026-01-01';
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode). SP header references Freshservice change: https://etoro.freshservice.com/a/changes/20353.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 15 T3, 0 T4, 0 T5 | Elements: 15/15, Logic: 7/10, Lineage: 8/10*
*Object: eMoney_Tribe.AccountsActivities_RiskActions-322546 | Type: Table | Production Source: eMoney (Modulr) platform — raw data lake ingestion*
