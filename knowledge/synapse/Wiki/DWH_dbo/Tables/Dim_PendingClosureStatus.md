# DWH_dbo.Dim_PendingClosureStatus

> Lookup table defining the three account closure workflow states -- No, Suggested for Closure, and Approved for Closure -- used to gate the account closure approval pipeline in DWH customer and snapshot tables.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PendingClosureStatus |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PendingClosureStatusID ASC) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PendingClosureStatus is a 3-row dictionary that defines the account closure approval workflow states. When a customer account is flagged for closure (due to regulatory action, fraud, inactivity, or customer request), it moves through a two-step approval process: first suggested (ID=2), then approved (ID=3). ID=1 (No) is the default active state for all customers. This two-step process ensures that account closures -- high-impact, irreversible operations -- require supervisor or compliance officer approval before being finalized.

The data originates from `etoro.Dictionary.PendingClosureStatus` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override/full-load strategy) to `Bronze/etoro/Dictionary/PendingClosureStatus/` in the data lake, with UC Bronze table `general.bronze_etoro_dictionary_pendingclosurestatus`.

Loaded by `SP_Dictionaries_DL_To_Synapse` via a TRUNCATE + INSERT pattern from `DWH_staging.etoro_Dictionary_PendingClosureStatus`. Refreshes daily. As of 2026-03-19 the most recent `UpdateDate` is 2026-03-11 -- 8 days stale, consistent with the schema-wide ETL freshness issue noted in prior batches.

---

## 2. Business Logic

### 2.1 Account Closure Approval Workflow

**What**: Account closure follows a mandatory two-step approval flow before an account is closed.

**Columns Involved**: `PendingClosureStatusID`, `PendingClosureStatusName`

**Rules**:
- **ID=1 (No)** -- Account is not pending closure. Normal active state. Default for all customer accounts.
- **ID=2 (Suggested for Closure)** -- An operator or automated process has flagged the account for closure. Awaiting supervisor or compliance approval.
- **ID=3 (Approved for Closure)** -- Closure approved by a supervisor. Account will close in the next processing cycle. Effectively irreversible without manual intervention.
- Valid transitions: 1->2 (suggest), 2->3 (approve), 2->1 (reject suggestion), 3->1 (cancel approved closure).
- No ID=0 placeholder in this table -- fact table JOINs must use LEFT JOIN or ISNULL guard to handle NULL values.
- `BackOffice.AccountPendingClosureStatusChange` is the production procedure managing state transitions.

**Diagram**:
```
Account Closure Workflow
  1 = No (active)
      |
      v (suggest)
  2 = Suggested for Closure
      |         |
      v         v (reject -> back to 1)
  3 = Approved for Closure
      |
      v
  Account Closed (external action)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `PendingClosureStatusID`. With only 3 rows, REPLICATE is optimal -- every compute node holds a full copy, making JOIN operations zero-shuffle-cost. Always join on `PendingClosureStatusID` as the integer key.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus`. With 3 rows, no partitioning or Z-ORDER is needed. Full scan is trivial.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What does a PendingClosureStatusID mean? | JOIN Dim_PendingClosureStatus ON PendingClosureStatusID for the label |
| How many customers are pending/approved for closure? | JOIN Dim_Customer, filter PendingClosureStatusID IN (2, 3) |
| Distribution of customers by closure state | GROUP BY with Dim_PendingClosureStatus for readable labels |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PendingClosureStatusID = dpcs.PendingClosureStatusID | Resolve closure state label per customer |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PendingClosureStatusID = dpcs.PendingClosureStatusID | Closure state in daily snapshot reports |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsc.PendingClosureStatusID = dpcs.PendingClosureStatusID | Year-end closed-account snapshots |

### 3.4 Gotchas

- **No ID=0 sentinel**: Unlike most DWH Dim_ tables, there is no ID=0 placeholder row. Always use LEFT JOIN when the fact table may have NULL or zero PendingClosureStatusID values.
- **Only 3 rows**: Pure enum lookup. Never filter by date range -- always load the full table.
- **ETL freshness**: `UpdateDate` reflects the last ETL run time (GETDATE() on reload), not when the production data was last modified. May be 7+ days stale during periods of ETL disruption.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PendingClosureStatus) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PendingClosureStatusID | tinyint | YES | Primary key identifying the closure workflow state. 1=No (not pending -- default for all active accounts), 2=Suggested for Closure (flagged, awaiting approval), 3=Approved for Closure (approved, will close next cycle). FK target in Dim_Customer and Fact_SnapshotCustomer. Managed by BackOffice.AccountPendingClosureStatusChange on the production platform. (Tier 1 - upstream wiki, Dictionary.PendingClosureStatus) |
| 2 | PendingClosureStatusName | varchar(50) | YES | Human-readable label for the closure state ('No', 'Suggested for Closure', 'Approved for Closure'). Displayed in BackOffice customer cards, closure reports, and regulatory compliance screens. (Tier 1 - upstream wiki, Dictionary.PendingClosureStatus) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PendingClosureStatusID | etoro.Dictionary.PendingClosureStatus | PendingClosureStatusID | passthrough |
| PendingClosureStatusName | etoro.Dictionary.PendingClosureStatus | PendingClosureStatusName | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on each reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PendingClosureStatus.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PendingClosureStatus
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PendingClosureStatus/
  -> DWH_staging.etoro_Dictionary_PendingClosureStatus
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_PendingClosureStatus
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PendingClosureStatus | Production closure workflow state dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/PendingClosureStatus/ | Daily full export via Generic Pipeline (Override strategy, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PendingClosureStatus | Raw staging import -- minimal transform |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; UpdateDate overridden to GETDATE() |
| Target | DWH_dbo.Dim_PendingClosureStatus | 3-row enum lookup, REPLICATE distributed |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PendingClosureStatusID | Customer-level closure workflow state; resolved via JOIN on this table |
| DWH_dbo.Fact_SnapshotCustomer | PendingClosureStatusID | Daily customer snapshot closure state |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PendingClosureStatusID | Year-end closed-account snapshot closure state |

---

## 7. Sample Queries

### 7.1 List all closure workflow states

```sql
SELECT PendingClosureStatusID,
       PendingClosureStatusName
FROM   [DWH_dbo].[Dim_PendingClosureStatus]
ORDER BY PendingClosureStatusID;
```

### 7.2 Find customers pending or approved for closure

```sql
SELECT  dc.CID,
        dpcs.PendingClosureStatusName
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PendingClosureStatus] dpcs
        ON dc.PendingClosureStatusID = dpcs.PendingClosureStatusID
WHERE   dc.PendingClosureStatusID IN (2, 3);
```

### 7.3 Count customers by closure state in latest daily snapshot

```sql
SELECT  ISNULL(dpcs.PendingClosureStatusName, 'Unknown') AS ClosureState,
        COUNT(*)                                          AS CustomerCount
FROM    [DWH_dbo].[Fact_SnapshotCustomer] fsc
LEFT JOIN [DWH_dbo].[Dim_PendingClosureStatus] dpcs
        ON fsc.PendingClosureStatusID = dpcs.PendingClosureStatusID
WHERE   fsc.DateID = (SELECT MAX(DateID) FROM [DWH_dbo].[Fact_SnapshotCustomer])
GROUP BY dpcs.PendingClosureStatusName
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PendingClosureStatus | Type: Table | Production Source: etoro.Dictionary.PendingClosureStatus*
