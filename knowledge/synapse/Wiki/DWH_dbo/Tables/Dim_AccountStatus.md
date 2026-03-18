# DWH_dbo.Dim_AccountStatus

> Lookup table defining the two possible open/closed states of an eToro trading account.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.AccountStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus |
| **UC Format** | parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

Dim_AccountStatus is a two-value lookup table that defines whether an eToro trading account is open (active) or closed (permanently deactivated). Every customer account in the DWH references this table to determine its operational state. The table contains only three rows: a DWH-specific placeholder (ID=0, N/A) added for safe fact-table JOINs, plus the two production values (ID=1 Open, ID=2 Closed).

The data originates from etoro.Dictionary.AccountStatus on the production eToro SQL Server (etoroDB-REAL). The Generic Pipeline exports it daily to the data lake at Bronze/etoro/Dictionary/AccountStatus/, where it lands in DWH_staging.etoro_Dictionary_AccountStatus. SP_Dictionaries_DL_To_Synapse then runs a TRUNCATE + INSERT to fully reload this table, appending a hardcoded ID=0 placeholder row. See upstream wiki: Dictionary/Tables/Dictionary.AccountStatus.md.

The table is reloaded daily. Because it is a TRUNCATE + INSERT (full reload), all rows are overwritten on every run. UpdateDate and InsertDate reflect the ETL run timestamp (GETDATE()), not the original production change date.

---

## 2. Business Logic

### 2.1 Account Open/Close Lifecycle

**What**: Binary account state controlling all platform access for an eToro customer.

**Columns Involved**: `AccountStatusID`, `AccountStatusName`

**Rules**:
- An account is either fully active (Open, ID=1) or fully deactivated (Closed, ID=2) - no intermediate state at this level
- Granular restriction states (blocked, pending verification, deposit blocked) are managed by Dim_PlayerStatus, not Dim_AccountStatus
- AccountStatusID=2 (Closed) is a terminal state - accounts do not transition back to Open
- This lookup resolves the AccountStatusID stored on customer dimension tables into a human-readable status name

**Diagram**:
```
Account Created --> [1: Open] --> (trade, deposit, withdraw, copy)
                        |
                   Account Closure
                        |
                        v
                   [2: Closed] --> (no activity, positions liquidated)
                   (terminal)
```

### 2.2 DWH Placeholder Row (ID=0)

**What**: A DWH-only N/A sentinel row added to prevent NULL gaps in fact-table JOINs.

**Columns Involved**: `AccountStatusID`, `AccountStatusName`

**Rules**:
- ID=0 (AccountStatusName="N/A") does not exist in production Dictionary.AccountStatus
- It is inserted by SP_Dictionaries_DL_To_Synapse as a second INSERT block after the main TRUNCATE + INSERT
- StatusID is hardcoded to 1 for this row, same as all other rows
- When a fact table has AccountStatusID=0 or NULL, joining to Dim_AccountStatus on ID=0 yields "N/A" rather than a NULL break

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, Dim_AccountStatus is REPLICATE + HEAP. REPLICATE copies the full table to every distribution node - appropriate for very small lookup tables (3 rows). This means JOINs on AccountStatusID incur no shuffle overhead regardless of the join partner's distribution key. HEAP (no clustered index) is acceptable at 3 rows; reads are always full-table scans, which is trivially cheap.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands at Gold/sql_dp_prod_we/DWH_dbo/Dim_AccountStatus/ as parquet. No partitioning is needed for a 3-row lookup table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve account status ID to name | JOIN Dim_AccountStatus ON AccountStatusID |
| Filter to active customers only | WHERE AccountStatusID = 1 (or JOIN and filter on AccountStatusName = 'Open') |
| List all valid status codes | SELECT * FROM Dim_AccountStatus WHERE AccountStatusID > 0 (exclude DWH placeholder) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON d.AccountStatusID = das.AccountStatusID | Resolve customer account status to name |
| DWH_dbo.CustomerStatic | ON cs.AccountStatusID = das.AccountStatusID | Resolve static customer account status |

### 3.4 Gotchas

- **ID=0 is DWH-only**: The N/A placeholder (ID=0) does not exist in production. Exclude it (`WHERE AccountStatusID > 0`) when building lists of valid status values.
- **Only 3 rows total**: Aggregations or GROUP BY on this table produce at most 3 groups.
- **StatusID is meaningless**: Always equals 1. Do not use it for any filtering or analysis.
- **UpdateDate/InsertDate are ETL timestamps**: They reflect when SP_Dictionaries_DL_To_Synapse ran, not when account statuses changed in production.
- **Underlying enum is binary**: Production only ever has Open=1 and Closed=2. Any AccountStatusID outside this range in fact tables indicates a data quality issue.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|---------|
| 4 stars | Tier 1 | (Tier 1 - upstream wiki, source) | Description copied verbatim from upstream production wiki |
| 3 stars | Tier 2 | (Tier 2 - SP code, source) | Derived from Synapse ETL SP code |
| 2 stars | Tier 3 | (Tier 3 - live data) | Inferred from live data sampling |
| 1 star | Tier 4 | [UNVERIFIED] (Tier 4 - inferred) | Name-based inference only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountStatusID | int | NO | Primary key identifying the account state. 1=Open (active account, full platform access), 2=Closed (deactivated, no activity permitted). DWH note: type is int vs tinyint in production; DWH adds ID=0 (N/A placeholder) for safe JOINs from fact tables. (Tier 1 - upstream wiki, Dictionary.AccountStatus) |
| 2 | AccountStatusName | varchar(50) | YES | Human-readable label for the account state. DWH values: "N/A" (ID=0, DWH placeholder), "Open" (ID=1), "Closed" (ID=2). Used in reporting to display account operational state. (Tier 1 - upstream wiki, Dictionary.AccountStatus) |
| 3 | StatusID | int | YES | DWH internal operational flag. Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows including the ID=0 placeholder. No analytical value; present on all SP_Dictionaries-loaded tables as a generic active/inactive marker. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp - set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect the production change date. All rows share the same timestamp per ETL run. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | InsertDate | datetime | YES | ETL load timestamp - set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Identical to UpdateDate because this is a full-reload (TRUNCATE + INSERT) pattern - there is no concept of "original insert date". (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AccountStatusID | etoro.Dictionary.AccountStatus | AccountStatusID | None (passthrough) |
| AccountStatusName | etoro.Dictionary.AccountStatus | AccountStatusName | None (passthrough) |
| StatusID | — | — | ETL-computed: hardcoded to 1 |
| UpdateDate | — | — | ETL-computed: GETDATE() |
| InsertDate | — | — | ETL-computed: GETDATE() |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.AccountStatus.md

### 5.2 ETL Pipeline

```
etoro.Dictionary.AccountStatus (etoroDB-REAL)
  -> Generic Pipeline (daily, Override/full load)
  -> Bronze/etoro/Dictionary/AccountStatus/ (parquet)
  -> DWH_staging.etoro_Dictionary_AccountStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_AccountStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.AccountStatus | Production eToro SQL Server (etoroDB-REAL). Static reference data - 2 rows (Open, Closed). |
| Lake | Bronze/etoro/Dictionary/AccountStatus/ | Daily full export via Generic Pipeline (Override strategy, 1440 min). |
| Staging | DWH_staging.etoro_Dictionary_AccountStatus | Raw import from lake. Column structure mirrors production. |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. StatusID hardcoded to 1. Dates set to GETDATE(). Adds ID=0 N/A placeholder row. |
| Target | DWH_dbo.Dim_AccountStatus | 3-row REPLICATE HEAP lookup. Daily refresh. |

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing references. It is a leaf-level lookup table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | AccountStatusID | Resolves customer account status in the main customer dimension |
| DWH_dbo.CustomerStatic | AccountStatusID | Resolves static account status for each customer record |

---

## 7. Sample Queries

### 7.1 List all valid account statuses (excluding DWH placeholder)
```sql
SELECT AccountStatusID,
       AccountStatusName
FROM   [DWH_dbo].[Dim_AccountStatus]
WHERE  AccountStatusID > 0
ORDER BY AccountStatusID;
```

### 7.2 Resolve account status name for a customer
```sql
SELECT cs.CID,
       das.AccountStatusName,
       cs.UpdateDate AS StatusLastUpdated
FROM   [DWH_dbo].[CustomerStatic] cs
JOIN   [DWH_dbo].[Dim_AccountStatus] das
       ON cs.AccountStatusID = das.AccountStatusID
WHERE  cs.CID = @CID;
```

### 7.3 Count customers by account status
```sql
SELECT das.AccountStatusName,
       COUNT(*) AS CustomerCount
FROM   [DWH_dbo].[Dim_Customer] dc
JOIN   [DWH_dbo].[Dim_AccountStatus] das
       ON dc.AccountStatusID = das.AccountStatusID
WHERE  das.AccountStatusID > 0   -- exclude DWH placeholder
GROUP BY das.AccountStatusName
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dim_AccountStatus is a simple two-value lookup whose meaning is fully captured by the upstream production wiki (Dictionary.AccountStatus.md) and ETL code.

---

*Generated: 2026-03-18 | Quality: 8.1/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_AccountStatus | Type: Table | Production Source: etoro/Dictionary/AccountStatus*
