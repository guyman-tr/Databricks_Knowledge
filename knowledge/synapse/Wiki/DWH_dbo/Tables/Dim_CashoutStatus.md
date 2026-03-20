# DWH_dbo.Dim_CashoutStatus

> Partial dimension defining 4 active withdrawal (cashout) lifecycle states in the DWH - a truncated subset of the 17-state production dictionary, missing terminal, review, and reversal states not currently in the DWH staging pipeline.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Dictionary.CashoutStatus` |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CashoutStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CashoutStatus` is the DWH dimension for withdrawal request lifecycle states. In production, `Dictionary.CashoutStatus` defines 17 distinct states spanning the full cashout pipeline - from initial submission through compliance review, billing processing, provider settlement, and potential reversal. The DWH version contains only 5 rows: the 4 core workflow states (Pending, InProcess, Processed, Canceled) plus an ID=0 N/A placeholder.

The production `IsFinishedWithoutMoneyTransfer` (terminal vs. no-money states) and `IsFinalStatus` (terminal/non-terminal flag) columns are **not loaded into DWH**. DWH instead adds `DWHCashoutStatusID` (a redundant surrogate equal to `CashoutStatusID`) and `StatusID` (hardcoded to 1). This means analysts using `Dim_CashoutStatus` in DWH JOINs will fail to resolve statuses such as Rejected (7), Reversed (16), Under Review (15), or SentToProvider (10) - those IDs will return NULL.

Data flows from `etoro.Dictionary.CashoutStatus` via the Generic Pipeline (daily Override to Bronze `general.bronze_etoro_dictionary_cashoutstatus`), through `DWH_staging.etoro_Dictionary_CashoutStatus`, and into DWH via `SP_Dictionaries_DL_To_Synapse`. The ID=0 N/A placeholder row is inserted separately after the main load using `@ddate` (midnight timestamp). See upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutStatus.md`.

---

## 2. Business Logic

### 2.1 DWH vs. Production State Coverage

**What**: The DWH dimension covers only 4 of 17 production cashout states, creating JOIN nulls for less common statuses.

**Columns Involved**: `CashoutStatusID`, `Name`

**Rules**:
- **Loaded (IDs 1-4)**: Pending, InProcess, Processed, Canceled - the main workflow states
- **ID=0 (N/A)**: DWH-only placeholder added by SP_Dictionaries; not in production
- **Missing (IDs 5-17)**: Partially Processed (5), Payment Sent (6), Rejected (7), RejectedByProvider (8), PendingByProvider (9), SentToProvider (10), SentToBilling (11), ReceivedByBilling (12), Failed (13), Pending Review (14), Under Review (15), Reversed (16), Partially Reversed (17)

**Diagram**:
```
DWH Coverage:
  [x] 0: N/A (placeholder)
  [x] 1: Pending
  [x] 2: InProcess
  [x] 3: Processed
  [x] 4: Canceled
  [ ] 5-17: Not in DWH (JOIN returns NULL)

Production Full Lifecycle (not in DWH):
  5: Partially Processed -> 6: Payment Sent
  7: Rejected (final, no money moved)
  8-12: Provider/Billing processing chain
  13: Failed -> 14: Pending Review -> 15: Under Review
  16: Reversed -> 17: Partially Reversed
```

### 2.2 DWH-Added Columns

**What**: SP_Dictionaries adds two columns not in the production source.

**Columns Involved**: `DWHCashoutStatusID`, `StatusID`

**Rules**:
- `DWHCashoutStatusID` = `CashoutStatusID` (identical value, redundant surrogate pattern used across SP_Dictionaries tables)
- `StatusID` = 1 hardcoded (active record flag; all loaded rows are active)
- `UpdateDate` and `InsertDate` = GETDATE() for rows from staging; @ddate (midnight) for ID=0 placeholder

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `CashoutStatusID`. With 5 rows, this is zero-cost to JOIN on any compute node.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Parquet at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus`. 5 rows, daily Override. No partitioning needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode a CashoutStatusID to its name | `LEFT JOIN DWH_dbo.Dim_CashoutStatus ON CashoutStatusID` |
| Find in-progress withdrawals | `WHERE CashoutStatusID = 2` (InProcess only) |
| Find completed withdrawals | `WHERE CashoutStatusID = 3` (Processed only in DWH) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_Cashout_State (planned) | ON CashoutStatusID | Decode status for each cashout event |
| DWH_dbo.Fact_BillingWithdraw (planned) | ON CashoutStatusID | Decode withdrawal status |

### 3.4 Gotchas

- **CRITICAL - Missing States**: DWH only has 5 of 17 production statuses. Use `LEFT JOIN`, never `INNER JOIN`. Fact rows with CashoutStatusID 5-17 will return NULL for Name. For full status resolution, check the upstream production wiki or hard-code status names.
- **IsFinalStatus and IsFinishedWithoutMoneyTransfer are DROPPED**: These analytically valuable flags (distinguishing terminal vs. intermediate states, and no-money-moved rejections) are not in DWH. Cannot be derived from DWH alone.
- **ID=0 is a DWH-only placeholder** - use `ISNULL(Name, 'Unknown')` for robustness when no status assigned.
- **DWHCashoutStatusID = CashoutStatusID** - these are always identical; DWHCashoutStatusID adds no value for analysts.
- **ETL freshness alert**: As of 2026-03-11, this table's UpdateDate is 7 days before the last session. Investigate SP_Dictionaries_DL_To_Synapse execution logs if data seems stale.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|---------|
| **** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Verbatim from upstream production wiki |
| *** | Tier 2 | `(Tier 2 - SP code, ...)` | Confirmed from Synapse ETL SP code |
| ** | Tier 3 | `(Tier 3 - live data)` | Observed from MCP live data sampling |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CashoutStatusID | int | NO | Primary key. DWH values: 0=N/A (placeholder), 1=Pending, 2=InProcess, 3=Processed, 4=Canceled. Note: production has 17 states (IDs 5-17 missing from DWH). Stored in withdrawal request records and updated as requests progress. (Tier 1 - upstream wiki, Dictionary.CashoutStatus) |
| 2 | Name | varchar(50) | NO | Human-readable status label. Values: "N/A", "Pending", "InProcess", "Processed", "Canceled". UNIQUE at production level (not enforced in DWH DDL). Used in reports and monitoring. (Tier 1 - upstream wiki, Dictionary.CashoutStatus) |
| 3 | DWHCashoutStatusID | int | YES | DWH surrogate - always equal to CashoutStatusID. Set by SP_Dictionaries as `[CashoutStatusID] as [DWHCashoutStatusID]`. No analytical value; redundant pattern used for consistency across DWH dictionary tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Active record indicator, hardcoded to 1 for all rows (including ID=0 placeholder). Mirrors the StatusID=1 convention used across SP_Dictionaries-loaded tables. Not sourced from production Dictionary.CashoutStatus. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() for rows loaded from staging (IDs 1-4); @ddate (midnight, CAST(GETDATE() AS DATE)) for the ID=0 N/A placeholder. Not a business change date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL insert timestamp. GETDATE() for staging rows; @ddate (midnight) for the ID=0 placeholder. Same value as UpdateDate (full reload on each run). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CashoutStatusID | etoro.Dictionary.CashoutStatus | CashoutStatusID | Passthrough |
| Name | etoro.Dictionary.CashoutStatus | Name | Passthrough |
| DWHCashoutStatusID | etoro.Dictionary.CashoutStatus | CashoutStatusID | Rename + same value |
| StatusID | (ETL-computed) | - | Hardcoded 1 |
| UpdateDate | (ETL-computed) | - | GETDATE() at load |
| InsertDate | (ETL-computed) | - | GETDATE() at load |

Dropped production columns not loaded into DWH: `IsFinishedWithoutMoneyTransfer`, `IsFinalStatus`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.CashoutStatus (17 rows in production)
  -> Generic Pipeline (daily Override, Bronze: general.bronze_etoro_dictionary_cashoutstatus)
  -> DWH_staging.etoro_Dictionary_CashoutStatus (4 rows - IDs 1-4 only)
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, then INSERT ID=0 placeholder)
  -> DWH_dbo.Dim_CashoutStatus (5 rows: 0-4)
  -> Generic Pipeline (daily Override, Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CashoutStatus | Production 17-state lifecycle table |
| Lake | Bronze/etoro/Dictionary/CashoutStatus/ | Daily Override, but staging has only IDs 1-4 |
| Staging | DWH_staging.etoro_Dictionary_CashoutStatus | 4 rows: Pending, InProcess, Processed, Canceled |
| ETL | SP_Dictionaries_DL_To_Synapse (lines 397-413, 1663-1678) | TRUNCATE + INSERT from staging + INSERT ID=0 placeholder |
| Target | DWH_dbo.Dim_CashoutStatus | 5 rows: IDs 0-4 |

---

## 6. Relationships

### 6.1 References To (this object points to)

This table has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Cashout_State (planned) | CashoutStatusID | Cashout pipeline event table - JOIN for status name |
| DWH_dbo.Fact_BillingWithdraw (planned) | CashoutStatusID | Withdrawal fact - JOIN for status name |
| Production: Billing cashout tables | CashoutStatusID | Tracks withdrawal status in production pipeline |

Note: No DWH_dbo SPs or Views currently JOIN this table (SSDT grep returned no matches).

---

## 7. Sample Queries

### 7.1 List all DWH cashout statuses
```sql
SELECT  CashoutStatusID,
        Name
FROM    [DWH_dbo].[Dim_CashoutStatus]
ORDER BY CashoutStatusID;
```

### 7.2 Decode status with NULL-safe JOIN (handles missing statuses)
```sql
SELECT  f.CashoutID,
        f.CID,
        ISNULL(s.Name, 'Status ' + CAST(f.CashoutStatusID AS varchar)) AS StatusName
FROM    [DWH_dbo].[Fact_Cashout_State] f
LEFT JOIN [DWH_dbo].[Dim_CashoutStatus] s
        ON f.CashoutStatusID = s.CashoutStatusID;
```

### 7.3 Count cashouts by available status labels
```sql
SELECT  ISNULL(s.Name, 'Unknown (' + CAST(f.CashoutStatusID AS varchar) + ')') AS Status,
        COUNT(*) AS CashoutCount
FROM    [DWH_dbo].[Fact_Cashout_State] f
LEFT JOIN [DWH_dbo].[Dim_CashoutStatus] s
        ON f.CashoutStatusID = s.CashoutStatusID
GROUP BY ISNULL(s.Name, 'Unknown (' + CAST(f.CashoutStatusID AS varchar) + ')')
ORDER BY CashoutCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream wiki (Dictionary.CashoutStatus, quality 8.6/10) and SP_Dictionaries_DL_To_Synapse ETL analysis.

---

*Generated: 2026-03-19 | Quality: 8.7/10 (★★★★☆) | Phases: 7/14 (Simple-Dict Fast-Path)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_CashoutStatus | Type: Table | Production Source: etoro.Dictionary.CashoutStatus*
