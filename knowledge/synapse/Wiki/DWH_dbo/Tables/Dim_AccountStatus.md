# DWH_dbo.Dim_AccountStatus

> Lookup table defining the open/closed states of an eToro trading account in the Synapse DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.AccountStatus |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, truncate-and-reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dim_AccountStatus is a two-value lookup table that defines whether an eToro trading account is open (active) or closed. Every customer record in the DWH references this table to determine the account's operational state. A third placeholder row (ID=0, "N/A") exists for fact table JOINs where the status is unknown or not applicable.

The production source is `etoro.Dictionary.AccountStatus` on the etoroDB-REAL server. Data flows through the Generic Pipeline (daily, parquet, Override strategy) into the data lake at `Bronze/etoro/Dictionary/AccountStatus/`, then into the `DWH_staging.etoro_Dictionary_AccountStatus` staging table, and finally into this table via SP_Dictionaries_DL_To_Synapse.

SP_Dictionaries_DL_To_Synapse runs daily as part of the DWH morning process. It TRUNCATEs the table and reloads all rows from staging, hardcoding StatusID=1 and setting UpdateDate/InsertDate to GETDATE(). After the main INSERT, a second INSERT adds the ID=0 "N/A" placeholder row. Full production documentation: see upstream wiki `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountStatus.md`.

---

## 2. Business Logic

### 2.1 Account Open/Close Lifecycle

**What**: Binary account state controlling all platform access.

**Columns Involved**: `AccountStatusID`, `AccountStatusName`

**Rules**:
- An account is either fully active (Open) or fully deactivated (Closed) — there is no intermediate state at this level
- The granular restriction states (blocked, pending verification, deposit blocked, etc.) are managed by Dim_PlayerStatus, not Dim_AccountStatus
- When an account transitions to Closed (2), all positions must be liquidated and pending withdrawals processed before the state change is finalized
- AccountStatus=Closed is a terminal state — accounts do not transition back to Open
- ID=0 "N/A" is a DWH placeholder for fact table LEFT JOINs — it does not represent a real account state

**Diagram**:
```
Account Created ──► [1: Open] ──► (trade, deposit, withdraw, copy)
                        │
                    Account Closure
                        │
                        ▼
                   [2: Closed] ──► (no activity, positions liquidated)
                   (terminal)

[0: N/A] ──► DWH placeholder for unmatched JOINs
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a HEAP storage. As a replicated table with only 3 rows, it is cached on every compute node — JOINs are always local and extremely fast. No distribution key alignment is needed.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count customers by account status | JOIN Dim_Customer or Fact_SnapshotCustomer on AccountStatusID, GROUP BY AccountStatusName |
| Filter to active accounts only | WHERE AccountStatusID = 1 |
| Filter to closed accounts | WHERE AccountStatusID = 2 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.AccountStatusID = Dim_AccountStatus.AccountStatusID | Resolve account status for customer records |
| DWH_dbo.Fact_SnapshotCustomer | ON Fact_SnapshotCustomer.AccountStatusID = Dim_AccountStatus.AccountStatusID | Resolve account status in daily customer snapshots |

### 3.4 Gotchas

- AccountStatusID=0 ("N/A") is a DWH-only placeholder. It does not exist in production. Exclude it when counting real statuses.
- StatusID column is always 1 — it is an ETL metadata flag, not a business column. Do not confuse with AccountStatusID.
- This table has only 3 rows. If you need granular account restriction states, use Dim_PlayerStatus instead.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★★ (4) | Tier 1 | Upstream wiki verbatim — expert-reviewed production documentation |
| ★★★ (3) | Tier 2 | Synapse SP code — verified from ETL procedure logic |
| ★★ (2) | Tier 3 | Live data sampling — observed from actual Synapse data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountStatusID | int | NO | Primary key identifying the account state. 1=Open (active account, full platform access), 2=Closed (deactivated, no activity permitted). Referenced by Customer.CustomerStatic.AccountStatusID and Hedge.AccountStatus tables. DWH note: widened from tinyint to int; includes ID=0 "N/A" placeholder row for fact table JOINs. (Tier 1 — upstream wiki, Dictionary.AccountStatus) |
| 2 | AccountStatusName | varchar(50) | YES | Human-readable label for the account state. Used in BackOffice reporting procedures (e.g., BackOffice.GetBlockedCustomers, BackOffice.GetClosedAccountsByLastChangeDate) to display account state in administrative UI. DWH note: column renamed from AccountStatusName in production (same name, no change). (Tier 1 — upstream wiki, Dictionary.AccountStatus) |
| 3 | StatusID | int | YES | ETL metadata: hardcoded to 1 by SP_Dictionaries_DL_To_Synapse. Always equals 1 for all rows. Not a business column — do not use for filtering or reporting. (Tier 2 — Synapse SP code, SP_Dictionaries_DL_To_Synapse) |
| 4 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last refreshed by the ETL pipeline. Set to GETDATE() on every SP_Dictionaries run. Reflects ETL execution time, not when the status was created or modified in production. (Tier 2 — Synapse SP code, SP_Dictionaries_DL_To_Synapse) |
| 5 | InsertDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() on every SP_Dictionaries run. Because the table is truncated daily, this always equals UpdateDate. (Tier 2 — Synapse SP code, SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AccountStatusID | Dictionary.AccountStatus | AccountStatusID | None (passthrough) |
| AccountStatusName | Dictionary.AccountStatus | AccountStatusName | None (passthrough) |
| StatusID | — | — | Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse |
| UpdateDate | — | — | GETDATE() by SP_Dictionaries_DL_To_Synapse |
| InsertDate | — | — | GETDATE() by SP_Dictionaries_DL_To_Synapse |

Full production documentation: see upstream wiki `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountStatus.md` (source configured in dwh-semantic-doc-config.json).

### 5.2 ETL Pipeline

```
etoro.Dictionary.AccountStatus → Generic Pipeline (daily, parquet) → DWH_staging.etoro_Dictionary_AccountStatus → SP_Dictionaries_DL_To_Synapse → DWH_dbo.Dim_AccountStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.AccountStatus | Production lookup table on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/AccountStatus/ | Daily parquet export via Generic Pipeline (Override) |
| Staging | DWH_staging.etoro_Dictionary_AccountStatus | Raw import into Synapse staging schema |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; adds StatusID=1, GETDATE() timestamps, and ID=0 placeholder |
| Target | DWH_dbo.Dim_AccountStatus | Final DWH dimension table |

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | AccountStatusID | Stores the account status for each customer — the primary DWH consumer of this lookup |
| DWH_dbo.Fact_SnapshotCustomer | AccountStatusID | Daily customer snapshot references account status |

---

## 7. Sample Queries

### 7.1 List all account statuses
```sql
SELECT  AccountStatusID,
        AccountStatusName
FROM    [DWH_dbo].[Dim_AccountStatus]
WHERE   AccountStatusID > 0
ORDER BY AccountStatusID;
```

### 7.2 Count customers by account status
```sql
SELECT  das.AccountStatusName,
        COUNT(*) AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_AccountStatus] das
        ON dc.AccountStatusID = das.AccountStatusID
WHERE   das.AccountStatusID > 0
GROUP BY das.AccountStatusName
ORDER BY CustomerCount DESC;
```

### 7.3 Find recently closed accounts
```sql
SELECT  dc.CID,
        dc.UserName,
        das.AccountStatusName
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_AccountStatus] das
        ON dc.AccountStatusID = das.AccountStatusID
WHERE   dc.AccountStatusID = 2
ORDER BY dc.CID DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a foundational 3-row lookup table whose meaning is self-evident from its data and upstream wiki.

---

*Generated: 2026-03-18 | Quality: 8.2/10 (★★★★☆) | Phases: 7/14*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_AccountStatus | Type: Table | Production Source: etoro/Dictionary/AccountStatus*
