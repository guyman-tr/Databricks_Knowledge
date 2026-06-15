# DWH_dbo.Dim_AccountStatus

> Lookup dimension defining the two operational states of an eToro trading account: Open (active) and Closed (deactivated). Sourced daily from etoro.Dictionary.AccountStatus via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.AccountStatus |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_AccountStatus is a two-row reference table defining whether an eToro trading account is Open (active) or Closed (deactivated). It is the DWH version of the production Dictionary.AccountStatus table. Every customer account in the platform references this dimension via the AccountStatusID field (stored in Dim_Customer and Customer.CustomerStatic).

Source: etoro.Dictionary.AccountStatus on etoroDB-REAL. The production table is exported daily to the data lake at Bronze/etoro/Dictionary/AccountStatus/ and staged into DWH_staging.etoro_Dictionary_AccountStatus. SP_Dictionaries_DL_To_Synapse loads from that staging table.

The ETL is a full TRUNCATE + INSERT pattern (Override strategy). StatusID is hardcoded to 1 (active row indicator per the DWH ETL convention). UpdateDate and InsertDate are both set to GETDATE() at load time. An ID=0 placeholder row ('N/A') is inserted after the main load for fact table JOIN safety.

---

## 2. Business Logic

### 2.1 Account Open/Close State

**What**: Binary account state distinguishing active accounts that can trade from permanently deactivated accounts.

**Columns Involved**: `AccountStatusID`, `AccountStatusName`

**Rules**:
- 1=Open: account is active, customer can log in, trade, deposit, withdraw, copy traders
- 2=Closed: account permanently deactivated, positions liquidated, no further activity permitted
- AccountStatus=Closed is terminal -- accounts do not transition back to Open
- Granular restriction states (blocked, pending verification, etc.) are managed by Dim_PlayerStatus, not this table
- AccountStatusID=0 (N/A) is a DWH placeholder for NULL-safe JOINs in fact tables

**Diagram**:
```
New Account ──► [1: Open] ──► (trade, deposit, withdraw, copy)
                    |
                Account Closure Request
                    |
                    v
               [2: Closed] (terminal, all positions liquidated)

[0: N/A] - DWH placeholder only, not a real account state
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a HEAP index. REPLICATE is the correct choice for a 3-row lookup table -- every distribution node holds a local copy, eliminating data movement on JOINs. HEAP is appropriate for a table this small with no range queries. Always use REPLICATE dimensions in JOINs on fact tables for optimal Synapse performance.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is a tiny reference table (3 rows). No partitioning needed. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All active (open) customer accounts | JOIN Dim_Customer ON AccountStatusID, filter AccountStatusID = 1 |
| Closed account count by period | JOIN with fact tables on CID, filter AccountStatusID = 2 |
| Resolve status ID to name | JOIN Dim_AccountStatus ON AccountStatusID = 1 or 2 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.AccountStatusID = Dim_AccountStatus.AccountStatusID | Resolve account status for each customer |

### 3.4 Gotchas

- **Only 2 meaningful values**: AccountStatusID 1 (Open) and 2 (Closed). AccountStatusID=0 is a DWH placeholder for NULL-safe JOINs and does not represent a real account state.
- **Not the same as PlayerStatus**: For compliance/trading restrictions (blocked, pending verification, etc.), join to Dim_PlayerStatus. AccountStatus is a coarser binary active/closed signal.
- **HEAP + REPLICATE**: Do not add a clustered index -- the table is too small to benefit.
- **StatusID is always 1**: This column carries no meaningful information -- it is hardcoded by ETL convention, not from the production source.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.AccountStatus) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountStatusID | int | NOT NULL | Primary key identifying the account state. 1=Open (active account, full platform access), 2=Closed (deactivated, no activity permitted), 0=N/A (DWH placeholder for NULL-safe JOINs). Referenced by Dim_Customer.AccountStatusID. (Tier 1 - upstream wiki, Dictionary.AccountStatus) |
| 2 | AccountStatusName | varchar(50) | YES | Human-readable label for the account state: 'Open', 'Closed', or 'N/A'. Used in reporting to display account state. Sourced directly from Dictionary.AccountStatus.AccountStatusName. (Tier 1 - upstream wiki, Dictionary.AccountStatus) |
| 3 | StatusID | int | YES | ETL-internal active-row indicator. Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows (including the ID=0 placeholder). Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production value changed -- use for ETL freshness monitoring only. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | InsertDate | datetime | YES | ETL load timestamp for when the row was (re-)inserted. Set to GETDATE() on every reload by SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| AccountStatusID | etoro.Dictionary.AccountStatus | AccountStatusID | Passthrough |
| AccountStatusName | etoro.Dictionary.AccountStatus | AccountStatusName | Passthrough |
| StatusID | - | - | ETL-computed: hardcoded to 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |
| InsertDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.AccountStatus -> Generic Pipeline (daily, Override) -> Bronze/etoro/Dictionary/AccountStatus/ -> DWH_staging.etoro_Dictionary_AccountStatus -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_AccountStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.AccountStatus | 2-row production lookup (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/AccountStatus/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_AccountStatus | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; StatusID hardcoded=1; UpdateDate/InsertDate=GETDATE(); ID=0 placeholder added |
| Target | DWH_dbo.Dim_AccountStatus | 3 rows (ID=0/1/2) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountStatusID | etoro.Dictionary.AccountStatus | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | AccountStatusID | Customer account status lookup (primary consumer in DWH) |

---

## 7. Sample Queries

### 7.1 List all account statuses

```sql
SELECT AccountStatusID, AccountStatusName
FROM [DWH_dbo].[Dim_AccountStatus]
ORDER BY AccountStatusID
-- Returns: 0=N/A, 1=Open, 2=Closed
```

### 7.2 Count customers by account status

```sql
SELECT
    das.AccountStatusName,
    COUNT(*) AS CustomerCount
FROM [DWH_dbo].[Dim_Customer] dc
JOIN [DWH_dbo].[Dim_AccountStatus] das
    ON dc.AccountStatusID = das.AccountStatusID
GROUP BY das.AccountStatusName
ORDER BY CustomerCount DESC
```

### 7.3 ETL freshness check

```sql
SELECT AccountStatusID, AccountStatusName, UpdateDate
FROM [DWH_dbo].[Dim_AccountStatus]
ORDER BY AccountStatusID
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 7.6/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_AccountStatus | Type: Table | Production Source: etoro.Dictionary.AccountStatus*
